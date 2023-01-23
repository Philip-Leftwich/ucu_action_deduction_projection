# Packages =====
suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(shinycssloaders)
  library(shinydashboardPlus)

})

# functions import ======
source("functions.R")

# User interface =====


## UI =====
ui <- 
  
  shiny::tagList( 
    includeCSS(path = "style/style.css"),
  
  dashboardPage(
  skin = "purple",
  dashboardHeader(title = "UCU strike deductions"),
  dashboardSidebar(disable = FALSE,
                   numericInput("gross_salary", "Enter Gross Salary at 1 FTE (pre-tax or pension deductions) - capped at grade point 51", 42155, min = 10000, max = 65578),
                   numericInput("tax_code", "Enter the first four numbers of your Tax code (1257 is the most common)", 1257, min = 1257, max = 1500),
                   sliderInput("fte", "FTE (Part-time workers may be greater impacted by strike days)", min = 0.2, max = 1, step = 0.2, value = 1),
                   sliderInput("days_of_action", "Days of action per month (likely max at 9 days)", min = 0, max = 18, step = 1, value = 1),
                   selectInput("student_loan", "Student Loan", choices = c("none", "Plan 1", "Plan 2")),
                   checkboxInput("fighting_fund", "Fighting Fund application", value = FALSE, width = NULL),
                   actionButton("reset", "Reset")),
  dashboardBody(
    p("This app is designed to help calculate take home pay with deductions from Industrial Action. 
    \nInformation on pension deductions, Tax, NI and student loans is taken from ", 
      a("The Salary Calculator", href = "https://www.thesalarycalculator.co.uk/salary.php"), 
      ". \nDetails on ", a("the HE single pay spine can be found here", href = "https://www.ucu.org.uk/he_singlepayspine"),
      " . \nInformation correct as of January 2023. Originally inspired by", a("this blog post by sarahcjoss", href = "https://medium.com/@sarahcjoss/the-net-cost-of-striking-8493018ead3f")),
    tabsetPanel(
    tabPanel("Take home pay", 
             plotOutput("linebox",height = "700px") %>% withSpinner(color="#0dc5c1"), 
          p("")),
    
)
)
),

tags$footer(
  tags$div(
    class = "footer_container", 
    
    includeHTML(path = "style/footer.html")
  )
)
)
  




# server =====

server <- function(input, output, session) {
  # reset values
  observeEvent(input$reset, {
    updateNumericInput(session, "gross_salary", value = 42155)
    updateNumericInput(session, "tax_code", value = 1257)
    updateSliderInput(session, "days_of_action", value = 1)
    updateSliderInput(session, "fte", value = 1)
    updateCheckboxInput(session, "student_loan", value="none")
    updateCheckboxInput(session, "fighting_fund", value=FALSE)
   
  })
    data <- reactive({
    input$rerun
      
      take_home <- take_home_pay(input$gross_salary, 
                                 input$student_loan, 
                                 input$tax_code,
                                 fte = input$fte)
      monthly_take_home <- take_home/12
      
      
      strike_take_home <-  strike_impact(days_of_action = input$days_of_action, 
                                                     gross_salary = input$gross_salary, 
                                                     student_loan = input$student_loan,
                                                     tax_code = input$tax_code,
                                                     fte = input$fte)
      
     
      strike_loss <- take_home-strike_take_home
      
      strike_pay <- (take_home/12) - strike_loss
      
      ucu_top_up <- fighting_fund(fighting_fund = input$fighting_fund,
                                  days_of_action = input$days_of_action,
                                  gross_salary = input$gross_salary)
      
      strike_pay_funded <- strike_pay + ucu_top_up
      
      # strike pay can never exceed normal salary when applying for the fighting fund
    
      ucu_top_up <- if_else(strike_pay_funded > monthly_take_home, (monthly_take_home-strike_pay), ucu_top_up) 
      
      
      tibble(monthly_take_home, strike_pay) %>% 
        pivot_longer(everything(), 
                     names_to = "condition", 
                     values_to = "pay") %>% 
        mutate(condition = case_when(condition == "strike_pay" ~ "Strike pay:\n ",
                                     condition == "monthly_take_home" ~ "Normal pay:\n ")) %>% 
        mutate(fund = if_else(condition == "Strike pay:\n ", ucu_top_up, 0)) %>% 
        pivot_longer(pay:fund, 
                     names_to = "condition2", 
                     values_to = "pay") %>% 
        mutate(label = scales::label_dollar(prefix = "\U00A3",
                                          accuracy = 2,
                                          suffix = "",
                                          big.mark = ",",
                                          decimal.mark = "."
        )(pay)) %>% 
        mutate(label2 = paste(condition, label))
      
  })

 
 # Line plot
    
    observe({
      data()
      output$linebox <- renderPlot({
        plot_pay(data())
      })
    })
    

  
  
} 
 

shinyApp(ui, server)
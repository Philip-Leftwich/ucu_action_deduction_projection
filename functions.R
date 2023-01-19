
library(tidyverse)
library(scales)


# Based on UK tax and NI with current UCU pension contribution of 9.8%. Correct as of 18th January 2023
#======================================

#Set default conditions
take_home_pay <- function(gross_salary, student_loan = "none", tax_code = 1275, fte = 1){

  # fte full-time-equivalent
gross_salary <- gross_salary*fte

#9.8% pension contribution        
pension_deduction <- gross_salary*0.098

# turn tax code into tax contributions
taxable_income <- gross_salary - pension_deduction - (tax_code*10)

something <- gross_salary-pension_deduction

#Plan 1 and 2 student loan deduction
student_loan_deduction <- case_when(student_loan == "Plan 2" ~ (something - 27295)*0.09,
                                    student_loan == "Plan 1" ~ (something - 20195)*0.09,
                                    student_loan == "none" ~ 0,
                                    TRUE ~ 0)
# Graded NI contributions
NI <- 52*if_else(
  (something/52) <= 967, 
  (((something/52)-242)*.12),
  (724.99 * .12)+(((something/52)-967)*0.02)
  ) 
  
# Basic and Higehr rate tax
tax <- if_else(taxable_income <= 37700, 
               taxable_income*0.2,
               ((taxable_income-37700)*0.4) + (37700*0.2))


take_home <- gross_salary-pension_deduction-NI-tax-student_loan_deduction

return(take_home)

}




#####

# Strike deductions ===

strike_impact <- function(days_of_action, gross_salary, student_loan = FALSE, tax_code = 1275,fte = 1){
  

strike_day <- gross_salary/(365*fte)

gross_salary <- gross_salary*fte

gross_salary <- gross_salary -(strike_day*days_of_action)

pension_deduction <- gross_salary*0.098

taxable_income <- gross_salary - pension_deduction - (tax_code*10)

something <- gross_salary-pension_deduction

#Plan 1 and 2 student loan deduction
student_loan_deduction <- case_when(student_loan == "Plan 2" ~ (something - 27295)*0.09,
                                    student_loan == "Plan 1" ~ (something - 20195)*0.09,
                                    student_loan == "none" ~ 0,
                                    TRUE ~ 0)


NI <- 52*if_else(
  (something/52) <= 967, 
  (((something/52)-242)*.12),
  (724.99 * .12)+(((something/52)-967)*0.02)
)  


tax <- if_else(taxable_income <= 37700, 
               taxable_income*0.2,
               ((taxable_income-37700)*0.4) + (37700*0.2))



take_home <- gross_salary-pension_deduction-NI-tax-student_loan_deduction

return(take_home)

}


#==================

# fighting fund

fighting_fund <- function(gross_salary, days_of_action, fighting_fund = TRUE){

fighting_fund_days <- if_else(fighting_fund == TRUE,
                              days_of_action-1,
                              0)

fighting_fund_daily_amount <- if_else(gross_salary <= 30000,
                                      75,
                                      50)



fighting_fund <- case_when(fighting_fund_days <=11 & fighting_fund_days > 0 ~ fighting_fund_days*fighting_fund_daily_amount,
                           fighting_fund_days > 11 ~ 11*fighting_fund_daily_amount,
                           fighting_fund_days < 1 ~ 0)
}


#===============



plot_pay <- function(data){
  data %>% 
      ggplot(aes(x=condition, 
                 y = pay, 
                 fill = condition))+
      geom_col(aes(alpha = condition2))+
    geom_text(colour = "white",
              hjust = 1, nudge_y = -100,
              size = 8, fontface = "bold",
      aes(x = condition,
               y = pay,
               label = if_else(condition2=="pay", label2, "")))+
    geom_text(colour = "white",
              size = 6, fontface = "bold",
              vjust = 10,
      #        hjust = 1,
              position = position_stack(vjust = 0.2),
              aes(x = condition,
                  y = pay,
                  label = if_else(condition2=="fund" & pay > 100, label, "")))+
    coord_flip()+
    scale_fill_manual(values = c("#3c1b5e", "#d24894"))+
    scale_y_continuous(limits=c(0, max(data$pay) * 1.1))+
    scale_alpha_manual(values = c(0.6,1))+
    theme_void()+
    theme(legend.position = "none"
         )

  
}


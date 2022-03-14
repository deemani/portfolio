#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
library(tidyverse)
library(treemapify)
library(reactable)
library(shiny)
library(shinythemes)

### read in data
loc_reg_szn <- read.csv("nba_shots_loc_summary.csv")

player_names <- loc_reg_szn %>% 
    select(player_name) %>% 
    distinct(player_name) %>% 
    pull(player_name)

# create vector of season years for menu drop down
season_names <- loc_reg_szn %>% 
    select(szn) %>% 
    distinct(szn) %>% 
    pull(szn)

## 2nd attempt, functional and pretty. ready to deploy
ui <- fluidPage(
    
    theme = shinytheme("sandstone"),
    
    titlePanel("NBA Shot Profiles by Player 2008 - 2018"),
    
    sidebarLayout(
        
        sidebarPanel(
            selectInput("player", "Player Name", choices = player_names),
            selectInput("season", "Season", choices = season_names),
            actionButton("submit", "Submit!")
        ),
        
        mainPanel(
            tabsetPanel(
                tabPanel("Shot Distribution", plotOutput("player_tree"),
                         "", reactableOutput("two_three_table")),
                tabPanel("Table", reactableOutput("player_table"))
            )
        )
    )
)

server <- function(input, output, session) {
    selected <- eventReactive(input$submit, {loc_reg_szn %>% filter(player_name == input$player & szn == input$season)})
    
    output$two_three_table <- renderReactable(
        reactable(selected() %>% 
                      select(shot_type, total) %>% 
                      group_by(shot_type) %>% 
                      summarise(tot_shots = sum(total)) %>%
                      ungroup() %>% 
                      mutate(freq = round((tot_shots/sum(tot_shots)*100),2)) %>% 
                      rename(`Shot Type` = shot_type, `Total Shots Attempted` = tot_shots, `Frequency %` = freq),
                  defaultSorted = list(`Frequency %` = "desc")
        ),
    )
    
    output$player_table <- renderReactable(
        reactable(selected() %>% 
                      select(shot_zone_basic, shot_zone_area, shoot_pct, total) %>% 
                      rename(`Zone` = shot_zone_basic, `Direction` = shot_zone_area, `Shooting %` = shoot_pct, `Total Shots Attempted` = total),
                  defaultPageSize = 5,
                  defaultSorted = list(`Total Shots Attempted` = "desc")
        )
    )
    
    output$player_tree <- renderPlot({
        selected() %>% 
            ggplot(aes(area = total, fill = shoot_pct, label = shot_zone_area, subgroup = shot_zone_basic)) +
            geom_treemap() +
            geom_treemap_subgroup_text(place = "bottom", grow = TRUE,
                                       colour = "black", alpha = 0.5,
                                       fontface = "italic", family = "mono") +
            geom_treemap_subgroup_border(colour = "black", size = 3) +
            geom_treemap_text(colour = "black",
                              place = "center",
                              size = 15) +
            scale_fill_gradient2(name = "Shooting %", limits = c(0, 100), breaks = c(20, 30, 40, 50, 60, 70), low = "steelblue4", mid = "snow2", high = "tomato4", midpoint = 45) +
            facet_grid(~ shot_type) +
            ggtitle(paste(input$player, "'s", input$season, "Shot Distribution & Shooting %")) +
            theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 16))
    })
}
shinyApp(ui, server)
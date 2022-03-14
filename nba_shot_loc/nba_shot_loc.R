library(tidyverse)
library(treemapify)
library(reactable)
library(shiny)
library(shinythemes)

### read in data
nba_shot_loc <- as_tibble(read_csv("nba_shots.csv"))

# fixing datatype
nba_shot_loc <- nba_shot_loc %>% 
  mutate(game_id = as.factor(game_id),
         game_event_id = as.factor(game_event_id),
         player_id = as.factor(player_id),
         player_name = as.factor(player_name),
         team_id = as.factor(team_id),
         action_type = as.factor(action_type),
         shot_type = as.factor(shot_type),
         shot_zone_basic = as.factor(shot_zone_basic),
         shot_zone_area = as.factor(shot_zone_area),
         shot_zone_range = as.factor(shot_zone_range),
         shot_dist_ft = as.factor(shot_dist_ft),
         shot_made_flag = as.factor(shot_made_flag),
         game_date = as.Date(as.character(game_date), "%Y%m%d"),
         home_team = as.factor(home_team),
         away_team = as.factor(away_team),
         season_type = as.factor(season_type)
  )



# create new table of just reg season records, drop first column
loc_reg_szn <- nba_shot_loc %>%
  filter(season_type == "Regular Season") %>% 
  select(-`X1`)

# create table of just player names
# will drop player names for aggregation and rely on distinct player_id field to group by
# in case any players have same names
# will use this table later to add names back in
loc_reg_szn_players <- nba_shot_loc %>% 
  filter(season_type == "Regular Season") %>% 
  distinct(player_id, player_name)

#  aggregate
loc_reg_szn <- loc_reg_szn %>% 
  # nba seasons, typially run across 2 years from Oct - April, with exceptions for shortened seasons
  # season is encoded in gameid with last 2 digits of start year for season being the 4th and 5th digits
  mutate(szn = as.numeric(substr(game_id, 4, 5)) + 2000) %>%  # extract them to create new field with regular season start year
  group_by(player_id, shot_zone_basic, shot_zone_area, shot_type, shot_made_flag, szn) %>% 
  summarise(ct = n()) %>% # count how many makes and misses
  ungroup() %>% 
  group_by(player_id, shot_zone_basic, shot_zone_area, shot_type, szn) %>% # drop shot_made_flag from aggregation
  mutate(total = sum(ct), # total shots from group of shot_zone_basic, shot_zone_area, shot_type
         shoot_pct = round((ct/total)*100, 2)) %>% # calculate shooting %
  filter(shot_made_flag != 0) %>% # drop missed shot %
  ungroup() %>% 
  arrange(desc(szn, shot_zone_basic, shoot_pct))

# add player names back in
loc_reg_szn <- loc_reg_szn %>% 
  left_join(loc_reg_szn_players) %>% # join on player name season
  filter(szn != "2019") # dropping COVID season

# write summary csv file to make it simpler for shiny to load and process
write.csv(loc_reg_szn, "~/Documents/Data/GitHub/working/nba_shot_loc/nba_shot_locations/nba_shots_loc_summary.csv")

### App
# create vector of player names for menu drop down
loc_reg_szn <- read.csv(nba_shots_loc_summary)

player_names <- loc_reg_szn %>% 
  select(player_name) %>% 
  distinct(player_name) %>% 
  pull(player_name)

# create vector of season years for menu drop down
season_names <- loc_reg_szn %>% 
  select(szn) %>% 
  distinct(szn) %>% 
  pull(szn)

## first attempt - functional but ugly

# ui <- fluidPage(
#   theme = shinytheme("cerulean"),
#   fluidRow(
#     column(4, style='padding:3px;',
#            selectInput("player", "Player Name", choices = player_names)),
#     column(4, 
#            selectInput("season", "Season", choices = season_names)),
#     column(1, style='padding:4px;',
#            actionButton("submit", "Submit!"))
#   ),
#   fluidRow(
#     column(4, style='padding:3px;',
#            reactableOutput("two_three_table")),
#     column(8, style='padding:3px;',
#            reactableOutput("player_table"))
#   ),
#   fluidRow(
#     plotOutput("player_tree", width = "100%", height = "600px")
#   )
#   
# )
# 
# server <- function(input, output, session) {
#   selected <- eventReactive(input$submit, {loc_reg_szn %>% filter(player_name == input$player & szn == input$season)})
#   
#   output$two_three_table <- renderReactable(
#     reactable(selected() %>% 
#                 select(shot_type, total) %>% 
#                 group_by(shot_type) %>% 
#                 rename(`FG Type` = shot_type) %>% 
#                 summarise(`Total Shots` = sum(total)),
#               defaultSorted = list(`Total Shots` = "desc")
#     ),
#   )
#   
#   output$player_table <- renderReactable(
#     reactable(selected() %>% 
#                 select(shot_zone_basic, shot_zone_area, shoot_pct, total) %>% 
#                 rename(`Zone` = shot_zone_basic, `Direction` = shot_zone_area, `Shooting %` = shoot_pct, `Total Shots` = total),
#               defaultPageSize = 5,
#               defaultSorted = list(`Total Shots` = "desc")
#               )
#   )
#   
#   output$player_tree <- renderPlot({
#     selected() %>% 
#       ggplot(aes(area = total, fill = shoot_pct, label = shot_zone_area, subgroup = shot_zone_basic)) +
#       geom_treemap() +
#       geom_treemap_subgroup_text(place = "bottom", grow = TRUE,
#                                  colour = "black",
#                                  fontface = "italic", family = "mono") +
#       geom_treemap_subgroup_border(colour = "black", size = 3) +
#       geom_treemap_text(colour = "black",
#                         place = "center",
#                         size = 15) +
#       scale_fill_gradient2(name = "Shooting %", limits = c(0, 100), breaks = c(20, 30, 40, 50, 60, 70), low = "steelblue4", mid = "snow2", high = "tomato4", midpoint = 45) +
#       facet_grid(~ shot_type) +
#       ggtitle("Shot Position Distribution & Shooting %")
#   })
# }
# 
# shinyApp(ui, server)

## 2nd attempt, functional and pretty. ready to deploy
ui <- fluidPage(
  
  theme = shinytheme("sandstone"),
  
  titlePanel("NBA Shot Profiles by Player 2012 - 2018"),
  
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

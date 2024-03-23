import pandas as pd
import soccerdata as sd

# import match data
fbref = sd.FBref(leagues="Big 5 European Leagues Combined", seasons=[2018,2019,2020,2021,2022])
schedule = fbref.read_schedule()

# select the columns
schedule = schedule[['date', 'home_team', 'home_xg', 'score', 'away_team', 'away_xg']]

# check if there are NAs and if they specific to a certain league
distinct_leagues = schedule[schedule['score'].isna()].index.get_level_values('league').unique()
print(distinct_leagues)

# NAs are restricted to 'FRA-Ligue 1' 2022 season so will drop
schedule = schedule.dropna(subset=['score'])

# split the score column into home and away goals
schedule['home_goals'] = schedule['score'].str[0].astype(int)
schedule['away_goals'] = schedule['score'].str[2].astype(int)

# add league and season indicies as a column
schedule['league'] = schedule.index.get_level_values('league')
schedule['season'] = schedule.index.get_level_values('season')

# create df of home results and rename fields
home_game_results = schedule[['league', 'season', 'date', 'home_team', 'home_goals', 'home_xg', 'away_team', 'away_goals', 'away_xg']]
home_game_results = home_game_results.rename(columns={'home_team': 'team', 'home_goals': 'goals_for', 'home_xg': 'xG', 
                                                      'away_team': 'team_against', 'away_goals': 'goals_against', 'away_xg': 'xGA'})

# created df of away results and rename fields
away_game_results = schedule[['league', 'season', 'date', 'away_team', 'away_goals', 'away_xg', 'home_team', 'home_goals', 'home_xg']]
away_game_results = away_game_results.rename(columns={'away_team': 'team', 'away_goals': 'goals_for', 'away_xg': 'xG',
                                                      'home_team':'team_against', 'home_goals': 'goals_against', 'home_xg': 'xGA'})

# concat both to create a df of all game results with team and team against columns
game_results = pd.concat([home_game_results, away_game_results], ignore_index=True)

# cumulative sum of goals and xG for and against by team and season order by date in ascending order
game_results_ordered = game_results.sort_values(by=['team', 'date'])
columns_to_csum = ['goals_for', 'goals_against', 'xG', 'xGA']
for column in columns_to_csum:
    game_results_ordered[f'{column}_season_csum'] = game_results_ordered.groupby(['team', 'season'])[column].cumsum()

# write to csv for import to Tableau
game_results_ordered.to_csv('soccer_dashboard/game_results.csv', index=False)

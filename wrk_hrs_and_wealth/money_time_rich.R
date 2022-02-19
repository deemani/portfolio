###
# Topic: Analyzing the relationship between change in prosperity of nation (gdp per capita) vs. productivity (working hours)

# Data Sources:
# https://ourworldindata.org/working-hours

###

## Packages
library(tidyverse)
library(reshape2)
library(ggrepel)
library(gganimate)
library(patchwork)
library(plotly)
library(gifski)
library(useful)


## Importing data
setwd('~/Documents/Data/GitHub/working/money_time_rich')

# read csvs as tibble
data <- as_tibble(read.csv('gdppercapita_vs_annual-hours_worked.csv'))

## Cleaninig up tables
# remove incomplete data

# some columns have very long names and need to copy & paste to rename
colnames(data)

data_cc <- data %>% 
  select(-Continent) %>% # remove because continent is only populated for first record of each nation so na.omit would drop alot of records, will add back in
  na.omit() %>% 
  rename(name = Entity,
         abbrev = Code,
         year = Year,
         ann_hours_worked = Average.annual.hours.worked.by.persons.engaged..avh...PWT.9.1..2019..,
         gdp_per_cap = GDP.per.capita..PPP..constant.2017.international...,
         pop_est = Population..historical.estimates.) %>% 
  mutate(hours_worked_day = ann_hours_worked/(50*5), # create column to view hours worked on daily basis
         hours_worked_wk = ann_hours_worked/50) # create column to view hours worked on weekly basis

summary(data_cc)

# creating table of country names and continents to add back in
cont_info <- data %>% 
  rename(name = Entity,
         abbrev = Code,
         continent = Continent) %>% 
  select(name, abbrev, continent) %>% 
  na_if("") %>% # multiple rows exist for each country but continent field is empty for most. convert empty values to NAs
  na.omit()

# join continent info back to complete data
data_cc <- data_cc %>% 
  inner_join(cont_info, by = c("abbrev" = "abbrev")) %>% 
  rename(name = name.x) %>% 
  select(-name.y)

# examine data frame
summary(data_cc)
summary(data_cc$name)
# not all nations have 28 years of data. some key nations will be excluded if we analyze from 1990-2017
# expanding criteria to last 20 years should make for better analysis. 1997 - 2017

# examine changes in 20 years
# calculate 20 year differnce and create new table
diff_20y <- data_cc %>% 
  filter(year %in% c(1997, 2017)) %>% 
  select(abbrev, name, year, continent, ann_hours_worked, gdp_per_cap, pop_est, hours_worked_day, hours_worked_wk) %>% # reorganzing order to put continent with name
  melt(id = c("abbrev", "name", "year", "continent")) %>% # collapse data into narrow format with 2 variables columns (name of variable, value) to prepare to mutate
  dcast(abbrev + name + continent + variable ~ year) %>% # expand data to create 2 new columns of 1997 and 2017 data for mutation
  mutate(diff = `2017` - `1997`) %>% # mutate to find 20 year diff
  na.omit() # remove countries without 1997 or 2017 data

# drop individual year columns and expand data back to columns with individual values
diff_20y <- diff_20y %>% 
  select(-`1997`, -`2017`) %>% # drop individual year info
  dcast(abbrev + name + continent ~ variable) %>% # expand df again back to format with individual columns for variable differences
  rename(ann_hours_worked_diff = ann_hours_worked, # renaming to reflect that each column is for differences over 20 years
         gdp_per_cap_diff = gdp_per_cap,
         pop_est_diff = pop_est,
         hours_worked_day_diff = hours_worked_day,
         hours_worked_wk_diff = hours_worked_wk)

# comparing change in gdp per cap in terms of raw numbers is not useful for this analysis
# generally, the world has gotten richer so we can expect increases for every nation
# more interesting to see how much richer each country has gotten relative to where they were 20 years ago

# pull out 1997 gdp per cap data alone
data_2017 <- data_cc %>% 
  filter(year == 1997) %>% 
  select(name, abbrev, gdp_per_cap)

# add it to diff_20y df and calculate the percent change over 20 year period
diff_20y <- diff_20y %>% 
  inner_join(data_2017, by = c("abbrev" = "abbrev")) %>% 
  mutate(gdp_cap_diff_pct = (gdp_per_cap_diff/gdp_per_cap)*100) %>% 
  select(-name.y, -gdp_per_cap)


# plot the differnce over the last 20 years in hours worked vs percent gdp per capita growth
diff_20y_pct <- diff_20y %>% 
  ggplot(aes(x = hours_worked_wk_diff, y = gdp_cap_diff_pct, label = abbrev, group = continent)) +
  geom_point(aes(color = continent)) +
  geom_text_repel(aes(label = abbrev)) +
  ggtitle("Growth in GDP per Capita (%) vs. Weekly Hours Worked (1997 - 2017)") +
  xlab ("Change in Weekly Hours Worked") +
  ylab ("Growth in GDP per Capita (%)") +
  scale_color_discrete("Continents")

# interesting takeaway:
# - Generally, all countries have seen GDP per capita rise
# - South/East Asian and Eastern European countries have gotten exponentially richer while increasing hours
# - Western world has seen a small reducation in hours 
# - South America paradox? Some countries (Argentina, Chile, Uruguay) have decreased working hours while some (Colombia, Peru) have increased working hours_worked
#   - Yet both groups had relatively similar rise in GDP per capita growth

# compare this chart to difference over the last 20 years in hours worked vs raw gdp per capita growth ($)
diff_20y_raw <- diff_20y %>% 
  ggplot(aes(x = hours_worked_wk_diff, y = gdp_per_cap_diff, label = abbrev, group = continent)) +
  geom_point(aes(color = continent)) +
  geom_text_repel(aes(label = abbrev)) +
  ggtitle("Growth in GDP per Capita ($) vs. Weekly Hours Worked (1997 - 2017)") +
  xlab ("Change in Weekly Hours Worked") +
  ylab ("Growth in GDP per Capita ($)") +
  scale_color_discrete("Continents")

diff_20y_raw + diff_20y_pct

# Perspective is important here:
# - If you look at the raw gdp plot, it seems like South/East Asian countries increased working hours but saw less gdp per capita growth than other countries
# - The raw gdp plot shows rich countries (Singapore + Korea + Ireland + Luxembourg) reduced working hours and saw biggest gains in GDP per capita
# This is skewed. Gives false impression whereas percent GDP plot shows results of countries that were central  to globalization.

## Clustering
# Can we run clustering algoritham to form common groups?
# using K-Means clustering method

# strip out categorical data
# data remains in alphabetical order
diff_20y_k <- diff_20y %>% 
  select(hours_worked_wk_diff, gdp_cap_diff_pct)

# determine how many centers to use
# using Hartigan's rule to see but may not stick with output
diffCenters <- FitKMeans(diff_20y_k, max.clusters = 20, nstart = 10, seed = 7923)
PlotHartigan(diffCenters)
# test says ~8 is optimal. skeptical so many would be useful. start with 4 and see.

# run clustering
set.seed(7923) # set random seed
diffK3 <- kmeans(x = diff_20y_k, centers = 3)
diffK4 <- kmeans(x = diff_20y_k, centers = 4)
diffK5 <- kmeans(x = diff_20y_k, centers = 5)
diffK6 <- kmeans(x = diff_20y_k, centers = 6)
diffK7 <- kmeans(x = diff_20y_k, centers = 7)
diffK8 <- kmeans(x = diff_20y_k, centers = 8)

# use clusters  for color categories and replot
# commented out other code that was not used after deciding to use 4 centers

# # 3 centers
# diff_20y_K3 <- diff_20y %>% 
#   mutate(cluster = as.factor(diffK3$cluster))
# 
# diff_20y_K3 %>% 
#   ggplot(aes(x = hours_worked_wk_diff, y = gdp_cap_diff_pct, label = abbrev, group = cluster)) +
#   geom_point(aes(color = cluster)) +
#   geom_text_repel(aes(label = abbrev)) +
#   ggtitle("Growth in GDP per Capita (%) vs. Weekly Hours Worked (1997 - 2017)") +
#   xlab ("Weekly Hours Worked") +
#   ylab ("Growth in GDP per Capita (%)") +
#   scale_color_discrete("Cluster Groups")

# 4 centers
diff_20y_K4 <- diff_20y %>% 
  mutate(cluster = as.factor(diffK4$cluster))

diff_20y_K4 %>% 
  ggplot(aes(x = hours_worked_wk_diff, y = gdp_cap_diff_pct, label = abbrev, group = cluster)) +
  geom_point(aes(color = cluster)) +
  geom_text_repel(aes(label = abbrev)) +
  ggtitle("Clustering of Growth in GDP per Capita (%) vs. Weekly Hours Worked (1997 - 2017)") +
  xlab ("Change in Weekly Hours Worked") +
  ylab ("Growth in GDP per Capita (%)") +
  scale_color_discrete("Cluster Groups")

# # 5 centers
# diff_20y_K5 <- diff_20y %>% 
#   mutate(cluster = as.factor(diffK5$cluster))
# 
# diff_20y_K5 %>% 
#   ggplot(aes(x = hours_worked_wk_diff, y = gdp_cap_diff_pct, label = abbrev, group = cluster)) +
#   geom_point(aes(color = cluster)) +
#   geom_text_repel(aes(label = abbrev)) +
#   ggtitle("Growth in GDP per Capita (%) vs. Weekly Hours Worked (1997 - 2017)") +
#   xlab ("Weekly Hours Worked") +
#   ylab ("Growth in GDP per Capita (%)") +
#   scale_color_discrete("Cluster Groups")
# 
# # 6 centers
# diff_20y_K6 <- diff_20y %>% 
#   mutate(cluster = as.factor(diffK6$cluster))
# 
# diff_20y_K6 %>% 
#   ggplot(aes(x = hours_worked_wk_diff, y = gdp_cap_diff_pct, label = abbrev, group = cluster)) +
#   geom_point(aes(color = cluster)) +
#   geom_text_repel(aes(label = abbrev)) +
#   ggtitle("Growth in GDP per Capita (%) vs. Weekly Hours Worked (1997 - 2017)") +
#   xlab ("Weekly Hours Worked") +
#   ylab ("Growth in GDP per Capita (%)") +
#   scale_color_discrete("Cluster Groups")
# 
# 
# # 7 centers
# diff_20y_K7 <- diff_20y %>% 
#   mutate(cluster = as.factor(diffK7$cluster))
# 
# diff_20y_K7 %>% 
#   ggplot(aes(x = hours_worked_wk_diff, y = gdp_cap_diff_pct, label = abbrev, group = cluster)) +
#   geom_point(aes(color = cluster)) +
#   geom_text_repel(aes(label = abbrev)) +
#   ggtitle("Growth in GDP per Capita (%) vs. Weekly Hours Worked (1997 - 2017)") +
#   xlab ("Weekly Hours Worked") +
#   ylab ("Growth in GDP per Capita (%)") +
#   scale_color_discrete("Cluster Groups")
# 
# # 8 centers
# diff_20y_K8 <- diff_20y %>% 
#   mutate(cluster = as.factor(diffK8$cluster))
# 
# diff_20y_K8 %>% 
#   ggplot(aes(x = hours_worked_wk_diff, y = gdp_cap_diff_pct, label = abbrev, group = cluster)) +
#   geom_point(aes(color = cluster)) +
#   geom_text_repel(aes(label = abbrev)) +
#   ggtitle("Growth in GDP per Capita (%) vs. Weekly Hours Worked (1997 - 2017)") +
#   xlab ("Weekly Hours Worked") +
#   ylab ("Growth in GDP per Capita (%)") +
#   scale_color_discrete("Cluster Groups")

# Summary of Clustering:
# - Despite Hartigan's rule analysis pointing to 8 clusters, it seems 4 clusters works best because it shows clear/distinct groups that provide useful analysis
# - 4 Clusters:
#   - 1. East Asian Economic Giants
#     - Consists of Myanmar + China. Both have very high working hours (Myanmar working hours remained very high over 20 years) and have reach exponential GDP per capita growth
#     - Myanmar isn't  a economic "giant" like China. Gains are largely product of country oepning after years of miltary dictatorship and expansion of manufacturing.
#   - 2. Rich Work-Life Adjusters & New Middle Incomers
#     - Consists of global rich countries that reduced work hours and countries that have recently become middle income
#     - Rich countries like South Korea/Ireland/Malta/Singapore shifted to hubs of white-collar jobs (particularly finance) this reducing working hours while increasing GDP per capita
#       - S Korea went from one of countries with the most working hours per week (1997)  to more in line with 40 hour work week (2017)
#     - Other nations like Russia, Turkey, Phillipines preiovusly considered outside the middle income group have comfortably shifted into MI with massive economic changes
#       - Russia increased Western trade with fall of Soviet Union. Turkey shifted to manufacturing. Phillipines shifted to healthcare.
#   - 3. Diverse Economic Developers
#     - Consists of SE Asian nations and Eastern European countries that have undertaken more conventional manufacturing jobs and lower-level IT work
#     - Slight spread in change in weekly hours worked. Vietnam drop ~2.5 hours while Cambodia increased 5 hours.
#   - 4. Steady (already rich) countries
#     - Countries would typically be associated with the OECD/developed economies
#     - Lack of growth in GDP per capita and work hours because lack of potential for business advtanages
#       - Workforces expect better work-life balances and pay thus being less attractive than other groups to firms looking to take advantage
#     - While group doesnt't have higher GDP per capita growth more than ~50% some countries lag pretty far behind:
#       - Italy and Greece both had <10% growth in GDP per capita and both underwent economic turmoil in 2010s





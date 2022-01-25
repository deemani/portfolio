###
# Topic: Does change in urbanization correlate to changes in happiness in different countries?
# Hypothesis: Countries that urbanized more over the last 10 years are more likely to report increased happiness
# 
# Data Sources:
# - Urbanization data: https://ourworldindata.org/
# - Happiness data: https://worldhappiness.report/ed/2020/


###

## Packages
library(tidyverse)
library(reshape2)
library(ggrepel)
library(gganimate)
library(patchwork)
library(plotly)
library(gifski)


## World Happiness survery
# start with happines survery, set working dir
setwd('~/Documents/Data/GitHub/working/world_happiness_urban')

# import world happiness survey file
happy_data  <- read_csv('world-happiness-report.csv')

# fix column names
happy_data <- happy_data %>% 
  rename(name = `Country name`,
         happy_rating = `Life Ladder`,
         gdp_per_cap_log = `Log GDP per capita`,
         social_support = `Social support`,
         healthy_life_exp = `Healthy life expectancy at birth`,
         free_life_choices = `Freedom to make life choices`,
         generosity = `Generosity`,
         corruption = `Perceptions of corruption`,
         pos_affect = `Positive affect`,
         neg_affct = `Negative affect`)

# explore data for 2020
happy_data %>% 
  select(name, year, happy_rating) %>% 
  filter(year == '2020') %>% 
  arrange(desc(happy_rating))


## World Urban Population data

# import world urban pop data
urban_data <- as_tibble(read.csv('world_urban_pop.csv'))

# renove X prefix from year columns
colnames(urban_data) <- gsub("X", "", colnames(urban_data))

# remove unecessary columns
urban_data <- urban_data %>% 
  select(-Indicator.Name, -Indicator.Code) %>% 
  rename(name = Country.Name,
         abbrev = Country.Code)

urban_data

# melt urban_data from wide to narrow
# alter from multi to single year column
urban_data_melt <- melt(urban_data, id.vars = c("name", "abbrev"))

# rename new column
urban_data_melt <- urban_data_melt %>% 
  rename(year = variable,
         pct_urban = value) %>% 
  as_tibble()

# overview of new table
summary(urban_data_melt)

## Combine happy and urban data into one table
summary(happy_data)
summary(urban_data_melt)

# need fix year columns to match data types
happy_data$year <- as.factor(happy_data$year)

# join
data <- urban_data_melt %>% 
  inner_join(happy_data) %>% 
  select(name, abbrev, year, pct_urban, happy_rating) %>% 
  arrange(year)

data

# not all countries will have data or have incomplete data
# want to focus on including major countries with mostly complete data
data %>% 
  count(year)

# consistent data between 2010 - 2019

# eyeballing, some countries names did not match before join so need to fix
# going to alter urban_data to match happy_data
urban_data_melt %>% 
  anti_join(happy_data, by = "name") %>% 
  filter(year == '2019') %>% 
  print(n = 150)

# handful of major countries with complete happiness data
# most are summary regions or smaller nations w/o complete happiness data

# manual fixes: urban_name > happy_name
# Cote d'Ivoire  > Ivory Coast
# Congo, Dem. Rep. > Congo (Kinshasa)	
# Congo, Rep. > Congo (Brazzaville)
# Hong Kong SAR, China   > Hong Kong S.A.R. of China	
# Kyrgyz Republic   > Kyrgyzstan	
# Korea, Rep. > South Korea
# Russian Federation  > Russia
# Slovak Republic > Slovakia
# Eswatini > Swaziland
# Syrian Arab Repoublic > Syria

levels(urban_data_melt$name)[levels(urban_data_melt$name)=="Cote d'Ivoire"] <- "Ivory Coast"
levels(urban_data_melt$name)[levels(urban_data_melt$name)=="Congo, Dem. Rep."] <- "Congo (Kinshasa)"
levels(urban_data_melt$name)[levels(urban_data_melt$name)=="Congo, Rep."] <- "Congo (Brazzaville)"
levels(urban_data_melt$name)[levels(urban_data_melt$name)=="Hong Kong SAR, China"] <- "Hong Kong S.A.R. of China"
levels(urban_data_melt$name)[levels(urban_data_melt$name)=="Kyrgyz Republic"] <- "Kyrgyzstan"
levels(urban_data_melt$name)[levels(urban_data_melt$name)=="Korea, Rep."] <- "South Korea"
levels(urban_data_melt$name)[levels(urban_data_melt$name)=="Russian Federation"] <- "Russia"
levels(urban_data_melt$name)[levels(urban_data_melt$name)=="Slovak Republic"] <- "Slovakia"
levels(urban_data_melt$name)[levels(urban_data_melt$name)=="Eswatini"] <- "Swaziland"
levels(urban_data_melt$name)[levels(urban_data_melt$name)=="Syrian Arab Republic"] <- "Syria"


# some names with ", %", remove anything after ","
urban_data_melt$name <- gsub("\\,.*", "", as.character(urban_data_melt$name))

# checking for more cleaning
summary(data)

# NAs in pct_urban col?
data %>% 
  filter(is.na(pct_urban))

# Kosovo does not have pct_urban data?
data <- data %>% 
  filter(!is.na(pct_urban))

# all good, join
data <- urban_data_melt %>% 
  inner_join(happy_data) %>% 
  select(name, abbrev, year, pct_urban, happy_rating) %>% 
  arrange(year)


# complete data only available for 2010-2019
complete_data <- data %>% 
  filter(!year %in% c("2005", "2006", "2007", "2008", "2009", "2020"))

summary(complete_data$year)

# 10 year change
# create df of 2010 data
complete_data10 <- complete_data %>% 
  filter(year == "2010") %>% 
  select(name, abbrev, pct_urban_2010 = pct_urban, happy_rating_2010 = happy_rating)

complete_data19 <- complete_data %>% 
  filter(year == "2019") %>% 
  select(name, abbrev, pct_urban_2019 = pct_urban, happy_rating_2019 = happy_rating)

# join tables, calculate 10 year change
data_10y_delta <- complete_data19 %>% 
  left_join(complete_data10) %>%
  mutate(urban_delta = pct_urban_2019 - pct_urban_2010,
         happy_delta = happy_rating_2019 - happy_rating_2010) %>% 
  filter(!is.na(urban_delta) & !is.na(happy_delta)) %>% 
  select(name, abbrev, urban_delta, happy_delta) %>% 
  arrange((happy_delta))

# plot and fit trend line
data_10y_delta %>% 
  ggplot(aes(x = happy_delta, y = urban_delta, label = abbrev)) +
  geom_point() +
  geom_text_repel(aes(label = abbrev)) +
  geom_smooth(method = 'lm') +
  ggtitle(label = "Change in Happiness vs % of Population Urbanized over 10 years (2010 - 2019)") +
  xlab("Change in Happiness Rating over 10 years") +
  ylab("Change in % of Population Urbanized over 10 years") 

### no discernable trend of increased happiness with increased urbanization
### most countries have positive urbanization rates due to increase in globalization/tech development
  ### but there is a wide spread in happiness rating after that
### a few outliers of countries that had spikes in urbanization and happiness but...
  ### equal amount of outliers of countries that had decreases in urbanization and increase in happiness
  ### as well as a number of nations that saw decreases in happiness despite urban growth

### A few interesting topics to further explore
### - China got more urbanized and happier
### - India got more urbanized and less happy
### - How does the West look?
    
## China - compare urbanization and happiness data
china_urban <- data %>% 
  filter(name == "China" & !year %in% c("2005", "2006", "2007", "2008", "2009")) %>% 
  ggplot(aes(x = year, y = pct_urban)) +
  geom_point(color = "red") +
  ggtitle("China's Change in Urbanization 2010 - 2020") +
  xlab("Year") +
  ylab("Percent of Population Urbanized")

china_happy <- data %>% 
  filter(name == "China" & !year %in% c("2005", "2006", "2007", "2008", "2009")) %>% 
  ggplot(aes(x = year, y = happy_rating)) +
  geom_point(color = "red") +
  ggtitle("China's Change in Happiness Rating 2010 - 2020") +
  xlab("Year") +
  ylab("Happiness Rating")

# plot next to each other for comparison
china_urban + china_happy

### China is the main success story for urbanization and happiness for the 2010s
### possibility of state skewing happiness numbers?
  ### while a valid concern it is unlikely in this case...
  ### chinese citizens saw their income + life expectancy + global status rise in the 2010s
  ### all are key indicators for happiness in world happiness reports

## India - compare urbanization and happiness data
india_urban <- data %>% 
  filter(name == "India" & !year %in% c("2005", "2006", "2007", "2008", "2009")) %>% 
  ggplot(aes(x = year, y = pct_urban)) +
  geom_point(color = "dodgerblue") +
  ggtitle("India's Change in Urbanization 2010 - 2020") +
  xlab("Year") +
  ylab("Percent of Population Urbanized")

india_happy <- data %>% 
  filter(name == "India" & !year %in% c("2005", "2006", "2007", "2008", "2009")) %>% 
  ggplot(aes(x = year, y = happy_rating)) +
  geom_point(color = "dodgerblue") +
  ggtitle("India's Change in Happiness Rating 2010 - 2020") +
  xlab("Year") +
  ylab("Happiness Rating")

# plot next to each other for comparison
india_urban + india_happy

### India saw an increase in urbaniation but saw a severe decrease in happiness


# show China & India's change over time with animated graph
data %>%
  filter(name %in% c("China","India") & !year %in% c("2005", "2006", "2007", "2008", "2009", "2020")) %>% 
  mutate(year = as.integer(as.character(year))) %>% 
  ggplot(aes(x = pct_urban, y = happy_rating, color = name)) +
  geom_point(aes(color = name), pch = 18, size = 5) +
  transition_states(year, 1, 1) + # indicates variable to use to progress graph
  shadow_mark(size = 3, colour = c('darkred','darkblue')) +
  labs(title = "China & India's Urbanization and Happines Rating: {closest_state}")


### Comparison of China & India?
### two most populous nations in the world that saw large scale urbanzation but with very different results on happiness
### causes?
  ### China's urban population went from below 50% to well above 60%, signalling a cultural shift from a mainly rural nation to urban
    ### India's urban population, despite growing by 4%, still sits well below 40%. potentially causing a cultural rift.
  ### another difference is China's urbanization has been driven by the state which has eased the transition with subsidies
    ### India's growth largely stems from rise in tech jobs from American companies looking to lower costs


## How has the West changed?
west_urban <- data %>% 
  filter(name %in% c("United States","Canada", "United Kingdom","France","Germany") & !year %in% c("2005", "2006", "2007", "2008", "2009")) %>% 
  ggplot(aes(x = year, y = pct_urban, color = name, group = name)) +
  geom_point() +
  geom_line() +
  ggtitle("West's Change in Urbanization 2010 - 2019") +
  xlab("Year") +
  ylab("% of Population Urbanized")

west_happy <- data %>% 
  filter(name %in% c("United States","Canada", "United Kingdom","France","Germany") & !year %in% c("2005", "2006", "2007", "2008", "2009")) %>% 
  ggplot(aes(x = year, y = happy_rating, color = name, group = name)) +
  geom_point() +
  geom_line() +
  ggtitle("West's Change in Happiness Rating 2010 - 2019") +
  xlab("Year") +
  ylab("Happiness Rating")

west_urban + west_happy

### West saw general increase in urbanization but movements were far smaller than non-West
  ### makes sense given Western countries were already pretty urbanized
### Some Western nations gained ALOT more than others nd point to increasing cultural shifts in those nations
  ### Big movers:
    ### - UK: despite being highly urbanized already, more ~3% rise in urbanization, possibly contributing to Brexit vote
    ### - France: ~3% rise in urbanization like UK and had massive geopolitical/cultural event in  2017 Prez Election 
    ### - USA: smaller gain than UK  & France (~1.5%) but also had political/cultural event in 2016 Prez Election
    ### All 3 nations (UK, France, USA) saw massive electoral disruptions (Brexit, Marcon winning/rise of Le Pen, Trump) possibly signalling connection to rapid urbanization
  ### Non-movers:
    ### - Canada: very little movement on urbanzation
    ### - Germany: for the group, low urbanization and did not see a massive gain
    ### Unlike the other 3 western nations, Canada & Germany did not see big electoral disruptions and instead saw maintenance of established politics
### Western nation's happiness, generally, saw minor fluctuations but largely stayed the same
  ### Some nations saw Happiness Rating change by ~.5 but majority rebounded to relatively stable levels
  ### Only two nations saw movement without reboounding:
    ### - Canada: dropped by ~.5 and ended the decade there
    ### - Germany: gained by ~.5 and ended the decade there
    ### Hard to identify reasoning without more data but interesting that both nations report similar urbanization but very different Happiness Rating

# How does it look if we had China?
west_china_urban <- data %>% 
  filter(name %in% c("United States","Canada", "United Kingdom","France","Germany", "China") & !year %in% c("2005", "2006", "2007", "2008", "2009")) %>% 
  ggplot(aes(x = year, y = pct_urban, color = name, group = name)) +
  geom_point() +
  geom_line() +
  ggtitle("West & China's Change in Urbanization 2010 - 2020") +
  xlab("Year") +
  ylab("Percent of Population Urbanized")

west_china_happy <- data %>% 
  filter(name %in% c("United States","Canada", "United Kingdom","France","Germany", "China") & !year %in% c("2005", "2006", "2007", "2008", "2009")) %>% 
  ggplot(aes(x = year, y = happy_rating, color = name, group = name)) +
  geom_point() +
  geom_line() +
  ggtitle("West & China's Change in Happiness Rating 2010 - 2020") +
  xlab("Year") +
  ylab("Happiness Rating")

west_china_urban + west_china_happy

happy_data %>% 
  filter(name %in% c("United States","Canada", "United Kingdom","France","Germany") & !year %in% c("2005", "2006", "2007", "2008", "2009")) %>% 
  arrange(happy_rating)

### China's gains in urbanization and happiness put West's minor movement in perspective but...
  ### When plotted together it is evident that there is more ground between China and the West than one may expect
  ### China's happiness rating is on the way but has not reached 6.0 and no Western nation has dropped below 6.3 since report started in 2005
  ### Nonetheless, China has massive potential urbanize further and continue gains in wealth & life expectancy whereas West may have reach ceiling and now faces political turmoil 







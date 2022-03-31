options(java.parameters = "-Xmx64g")
library(tidyverse)
library(ggplot2)
library(readxl)
library(RJDBC)
library(RColorBrewer)
library(wesanderson)
library(formattable)
theme_set(theme_classic())

###### fucntions ######
### round up/down to nearest value for the axes limits
round_any <- function(x, accuracy, func){func(x/ accuracy) * accuracy}

######### Get Redshift creds (local R) #########
driver <-
  JDBC(
    "com.amazon.redshift.jdbc41.Driver",
    "~/.redshiftTools/redshift-driver.jar",
    identifier.quote = "`"
  )
my_aws_creds <-
  read.csv(
    "~/Documents/Projects/DS/redshift_creds.csv",
    header = TRUE,
    stringsAsFactors = FALSE
  )
url <-
  paste0(
    "jdbc:redshift://localhost:5439/redshiftdb?user=",
    my_aws_creds$user,
    "&password=",
    my_aws_creds$password
  )
conn <- dbConnect(driver, url)

dbGetQuery(conn, "SELECT DISTINCT brand_title FROM prez.scv_vmb LIMIT 10;")


#### get data

typical_iplayer<- dbGetQuery(conn, "SELECT * FROM central_insights_sandbox.vb_typical_ipl_viewers ;")
ukraine_iplayer<-dbGetQuery(conn, "SELECT * FROM central_insights_sandbox.vb_ukraine_ipl_demo_summary ;")


### iPlayer all age/gender
plot_data<-typical_iplayer %>%
  group_by(age_range, gender) %>%
  summarise(users=sum(users)) %>% 
  filter(age_range !='Unknown')

perc_labs<-plot_data %>%ungroup() %>%group_by(age_range)%>%mutate(perc = round(100*users/sum(users),0))
age_perc_labs<-plot_data %>%ungroup() %>%group_by(age_range)%>%summarise(users = sum(users)) %>%mutate(perc = round(100*users/sum(users),0))

age_perc_labs<-perc_labs%>%
  select(age_range,gender) %>%
  left_join(age_perc_labs, by= 'age_range')%>%
  replace(is.na(.),0)

max_value<- plot_data %>%summarise(total = sum(users)/1000000) %>%select(total)%>%max() %>%round_any(5, func = ceiling)
max_value


ggplot(data = plot_data ,
       aes(x = age_range,y = users/1000000, group = gender, fill = gender)) +
  geom_col(inherit.aes = TRUE,
           position = "stack",
           show.legend = TRUE)+
  #scale_y_continuous(limits = c(0, max_value*1.1), breaks = seq(0, max_value*1.1, by = 1))+
  xlab("Age Range") +
  ylab("Users (millions)") +
  labs(title = paste0('Age & gender distribution of iPlayer users \n(2022-02-25 to 2022-03-03 excl 2022-03-01)'))+
  geom_text(aes(label=paste0(perc_labs$perc ,"%")),
            position=position_stack(vjust = 0.5),
            colour="black")+
  geom_label(data = age_perc_labs,
             aes(label=paste0(age_perc_labs$perc ,"%")),
             y = max_value,
             colour="black",
             fill = "white")+
  scale_fill_manual(name = "Gender",values=wes_palette(n=3, name="GrandBudapest1"))+
  theme(legend.position = "bottom")


### iPlayer UKRAINE age/gender
plot_data<-ukraine_iplayer %>%
  group_by(age_range, gender) %>%
  summarise(users=sum(users))%>% 
  filter(age_range !='Unknown')

perc_labs<-plot_data %>%ungroup() %>%group_by(age_range)%>%mutate(perc = round(100*users/sum(users),0))
age_perc_labs<-plot_data %>%ungroup() %>%group_by(age_range)%>%summarise(users = sum(users)) %>%mutate(perc = round(100*users/sum(users),0))

age_perc_labs<-perc_labs%>%
  select(age_range,gender) %>%
  left_join(age_perc_labs, by= 'age_range')%>%
  replace(is.na(.),0)

max_value<- plot_data %>%summarise(total = sum(users)/1000) %>%select(total)%>%max() %>%round_any(10, func = ceiling)
max_value


ggplot(data = plot_data,
       aes(x = age_range,y = users/1000, group = gender, fill = gender)) +
  geom_col(inherit.aes = TRUE,
           position = "stack",
           show.legend = TRUE)+
  scale_y_continuous(limits = c(0, max_value*1.1), breaks = seq(0, max_value*1.1, by = 10))+
  xlab("Age Range") +
  ylab("Users (000s)") +
  labs(title = paste0('Age & gender distribution of iPlayer Ukraine content users \n(2022-02-25 to 2022-03-03 excl 2022-03-01)'))+
  geom_text(aes(label=paste0(perc_labs$perc ,"%")),
            position=position_stack(vjust = 0.5),
            colour="black")+
  geom_label(data = age_perc_labs,
             aes(label=paste0(age_perc_labs$perc ,"%")),
             y = max_value,
             colour="black",
             fill = "white")+
  scale_fill_manual(name = "Gender",values=wes_palette(n=3, name="GrandBudapest1"))+
  theme(legend.position = "bottom")


### gender split and comparison
gender_split <-
  typical_iplayer %>%
  group_by(gender) %>%
  summarise(users = sum(users)) %>%
  mutate(perc = round(100 * users / sum(users), 0)) %>%
  mutate(category = 'all') %>%
  rbind(
    ukraine_iplayer %>%
      group_by(gender) %>%
      summarise(users = sum(users)) %>%
      mutate(perc = round(100 * users / sum(users), 0)) %>%
      mutate(category = 'ukraine')
  )
gender_split
ggplot(data = gender_split,
       aes(x = category,y = perc,  fill = gender)) +
  geom_col(inherit.aes = TRUE,
           position = "stack",
           show.legend = TRUE)+ 
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, by = 25))+
  xlab("iPlayer Users") +
  ylab("Percentage") +
  labs(title = paste0('Gender distribution of typical iPlayer users vs Ukraine users\n(2022-02-25 to 2022-03-03 excl 2022-03-01) '))+
  geom_text(aes(label=paste0(perc ,"%")),
            position=position_stack(vjust = 0.5),
            colour="black")+
  scale_fill_manual(name = "Gender",values=wes_palette(n=3, name="GrandBudapest1"))+
  theme(legend.position = "bottom")


### age split and comparison
age_split <-
  typical_iplayer %>%
  group_by(age_range) %>%
  summarise(users = sum(users)) %>%
  mutate(perc = round(100 * users / sum(users), 0)) %>%
  mutate(category = 'all') %>%
  rbind(
    ukraine_iplayer %>%
      group_by(age_range) %>%
      summarise(users = sum(users)) %>%
      mutate(perc = round(100 * users / sum(users), 0)) %>%
      mutate(category = 'ukraine')
  ) %>%filter(age_range !='Unknown')
age_split
ggplot(data = age_split,
       aes(x = category,y = perc,  fill = age_range)) +
  geom_col(inherit.aes = TRUE,
           position = "stack",
           show.legend = TRUE)+ 
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, by = 25))+
  xlab("iPlayer Users") +
  ylab("Percentage") +
  labs(title = paste0('Age distribution of typical iPlayer users vs Ukraine users \n (2022-02-25 to 2022-03-03 excl 2022-03-01) '))+
  geom_text(aes(label=paste0(perc ,"%")),
            position=position_stack(vjust = 0.5),
            colour="black")+
  scale_fill_manual(name = "Age Range",values=wes_palette(n=5, name="Darjeeling1"))+
  theme(legend.position = "bottom")


########################################################################
### acorn split for just iplayer
acorn_split <-
  typical_iplayer %>%
  group_by(acorn_cat) %>%
  summarise(users = sum(users)) %>%
  #filter(acorn_cat !='Unknown') %>% 
  mutate(perc = round(100 * users / sum(users), 0))
acorn_split

max_value<- acorn_split %>%summarise(users= users/1000000)%>%select(users)%>%max()%>%round_any(5, func = ceiling)
max_value

ggplot(data = acorn_split,
       aes(x = users/1000000,y = acorn_cat,  fill = acorn_cat)) +
  geom_col(inherit.aes = TRUE,
           position = "stack",
           show.legend = TRUE)+ 
  scale_x_continuous(limits = c(0, max_value), breaks = seq(0, max_value, by = 1)
  )+
  scale_y_discrete(limits = rev)+
  xlab("iPlayer Users") +
  ylab("Acorn Category") +
  labs(title = paste0('Acorn distribution of typical iPlayer users \n (2022-02-25 to 2022-03-03 excl 2022-03-01) '))+
  geom_text(aes(label=paste0(perc ,"%")),
            hjust = -0.5,
            colour="black")+
  scale_fill_brewer(name = "Acorn Category",palette = "Set1")+
  theme(legend.position = "bottom")

### acorn split and comparison
acorn_split <-
  typical_iplayer %>%
  group_by(acorn_cat) %>%
  summarise(users = sum(users)) %>%
  mutate(perc = round(100 * users / sum(users), 0)) %>%
  mutate(category = 'all') %>%
  rbind(
    ukraine_iplayer %>%
      group_by(acorn_cat) %>%
      summarise(users = sum(users)) %>%
      mutate(perc = round(100 * users / sum(users), 0)) %>%
      mutate(category = 'ukraine')
  ) %>%filter(acorn_cat !='Unknown')
acorn_split
ggplot(data = acorn_split,
       aes(x = category,y = perc,  fill = acorn_cat)) +
  geom_col(inherit.aes = TRUE,
           position = "stack",
           show.legend = TRUE)+ 
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, by = 25))+
  xlab("iPlayer Users") +
  ylab("Percentage") +
  labs(title = paste0('Acorn distribution of typical iPlayer users vs Ukraine users \n (2022-02-25 to 2022-03-03 excl 2022-03-01) '))+
  geom_text(aes(label=paste0(perc ,"%")),
            position=position_stack(vjust = 0.5),
            colour="black")+
  scale_fill_brewer(name = "Acorn Category",palette = "Set1")+
  theme(legend.position = "bottom")

### freq split and comparison
### there's an issue with frequency with some days so pull this in separately
freq_split <-
  dbGetQuery(
    conn,
    "SELECT DISTINCT frequency_group_aggregated,
                count(distinct hashed_id) as users,
                'all'                     as category
FROM dataforce_insights.df_journey_to_playback
WHERE dt >= '20220225'
  AND dt <= '20220227'
  AND age_range NOT IN ('13-15', 'Under 13')
GROUP BY 1

UNION
SELECT DISTINCT frequency_group_aggregated,
                count(distinct hashed_id) as users,
                'ukraine'                 as category
FROM dataforce_insights.df_journey_to_playback
WHERE dt >= '20220225'
  AND dt <= '20220227'
  AND age_range NOT IN ('13-15', 'Under 13')
  AND click_container ILIKE '%ukraine%'
GROUP BY 1;"
  ) %>%
  group_by(category) %>%
  mutate(perc = round(100 * users / sum(users), 0)) %>%
  arrange(category, frequency_group_aggregated)

freq_split%>%group_by(category) %>% summarise(sum = sum(users))

freq_split$frequency_group_aggregated<- factor(freq_split$frequency_group_aggregated, 
                                                  levels=c('new','reacquired','infrequent','weekly'))

ggplot(data = freq_split,
       aes(x = category,y = perc,  fill = frequency_group_aggregated)) +
  geom_col(inherit.aes = TRUE,
           position = "stack",
           show.legend = TRUE)+ 
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, by = 25))+
  xlab("iPlayer Users") +
  ylab("Percentage") +
  labs(title = paste0('Frequency distribution of all iPlayer users \n  vs Ukraine users (2022-02-25 to 2022-02-27) '))+
  geom_text(aes(label=paste0(perc ,"%")),
            position=position_stack(vjust = 0.5),
            colour="black")+
  scale_fill_brewer(name = "Frequency Group",palette = "Set2")+
  theme(legend.position = "bottom")



### general things
typical_iplayer %>%summarise(users = sum(users))

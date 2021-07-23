################
#### Test Kevin rdo velo nW
################

# Check if the packages that we need are installed
want = c("dplyr",
         "tidyr",
         "googlesheets4",
         "ggplot2",
         "readxl", 
         "ggpol",
         "forcats",
         "stringr",
         "rmarkdown",
         "stats", 
         "tidyverse",
         "zoo",
         "foreign",
         "survey",
         "gtsummary",
         "kableExtra",
         "writexl",
         "cowplot",
         "gridExtra")

have = want %in% rownames(installed.packages())

# Install the packages that we miss
if ( any(!have) ) { install.packages( want[!have] ) }

# Load the packages
junk <- lapply(want, library, character.only = T)

# Remove the objects we created
rm(have, want, junk)


##############################################################################
#######################################
#############
## Import nW scenario
#############
#######################################
##############################################################################

negaWatt.data <- read.csv("C:/Users/Kevin JEAN/Desktop/Recherche/velo_sante/code_kevin/scenar_nW.csv", sep=";",
                          dec = ",")
head(negaWatt.data)
summary(negaWatt.data)

negaWatt.data <- negaWatt.data %>%
  na.omit() %>%
  rename("Type" = "km.hab.an")  %>%
  mutate(Type = ifelse(Type == "Marche", "Walking",
                       ifelse(Type == "Velo", "Total_Cycling", "Share_Ebike" ))) %>%
  pivot_longer(!Type,
               names_to = "Year",
               values_to = "value") %>%
  pivot_wider(id_cols = Year, 
              names_from = Type,
              values_from = value) %>%
  mutate(Ebike = Total_Cycling * Share_Ebike,
         Normal_bike = Total_Cycling * (1 - Share_Ebike)) %>%
  pivot_longer(!Year,
               names_to = "Type",
               values_to = "value") %>%
  filter(Type != "Share_Ebike")

negaWatt.data$Year = as.numeric(substr(negaWatt.data$Year,2,5))


p1 = negaWatt.data %>% 
  ggplot() +  
  geom_line(aes(x = Year, y = value, group = Type, color = Type), size = 1)+
  ylab("") +
  xlab("") +
  labs(title = "nÃ©gaWatt scenario", subtitle = "In km/inhab/year") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 16),
        plot.subtitle = element_text(colour = "#595a5c", size = 12),
        legend.title = element_blank(),
        legend.text = element_text( size = 10),
        legend.position="top",
        axis.text=element_text(size=10),
        axis.text.x = element_text(angle = 60, vjust = 0.5, hjust=1))+
  ylim(0, 1250)



##############################################################################
#######################################
#############
## demography & mortality
#############
#######################################
##############################################################################
temp <-  tempfile()

dataURL <- "https://www.insee.fr/fr/statistiques/fichier/2530035/projpop0550_SP19.xls"
download.file(dataURL, destfile=temp, mode='wb')

Pop.proj <- readxl::read_excel(temp, skip = 4, col_names = TRUE)


dataURL <- "https://www.insee.fr/fr/statistiques/fichier/2530048/projpop0550_SD01.xls"
download.file(dataURL, destfile=temp, mode='wb')
Mortality.rate <- readxl::read_excel(temp, skip = 4, col_names = TRUE)

unlink(temp)

Pop.proj = Pop.proj %>% 
  na.omit() %>% 
  mutate(sexe = ifelse(SEXE == "1", "Male", "Female")) %>% 
  rename( "age" = starts_with("AGE")) %>% 
  mutate(across(.cols = c(everything(), - sexe),  as.numeric),
         age = ifelse(is.na(age)== T, 106, age)) %>% 
  select(-SEXE) %>% 
  pivot_longer(!c(age, sexe), names_to = "year", values_to = "Pop") 

Mortality.rate = Mortality.rate %>% 
  na.omit() %>% 
  mutate(sexe = ifelse(SEXE == "1", "Male", "Female")) %>% 
  rename( "age" = starts_with("AGE")) %>% 
  mutate(across(.cols = c(everything(), - sexe),  as.numeric),
         age = ifelse(is.na(age)== T, 106, age)) %>% 
  select(-SEXE) %>% 
  pivot_longer(!c(age, sexe), names_to = "year", values_to = "Deaths") %>% 
  na.omit()

Pop.proj = Pop.proj %>% 
  merge(Mortality.rate, by = c("age", "sexe", "year")) %>% 
  mutate(Mortality.rate = Deaths/Pop) %>% 
  mutate(age_grp.FACTOR = cut( age, breaks = seq(0,150, by = 5), include.lowest = T, right = F),
         age_grp = as.character(age_grp.FACTOR), 
         age_grp = gsub("\\[|\\]|\\(|\\)", "", age_grp),
         age_grp = gsub(",", "-", age_grp),
         post = sub(".*-","",age_grp),
         age_grp = sub("-.*", "", age_grp),
         age_grp = paste0(age_grp,"-", as.numeric(post)-1),
         order = as.numeric(substr(age_grp,1,regexpr("-",age_grp)-1))) 



#recalculate for both sexs
Pop.proj.both = Pop.proj %>% filter(sexe == "Male") ; dim(Pop.proj.both)
Pop.proj.both$sexe = "Both"
Pop.proj.both$Pop = Pop.proj.both$Deaths = Pop.proj.both$Mortality.rate = 0
head(Pop.proj.both)
Pop.proj.both$Pop = Pop.proj$Pop[Pop.proj$sexe=="Male"] + Pop.proj$Pop[Pop.proj$sexe=="Female"]
Pop.proj.both$Deaths = Pop.proj$Deaths[Pop.proj$sexe=="Male"] + Pop.proj$Deaths[Pop.proj$sexe=="Female"]
Pop.proj.both$Mortality.rate = Pop.proj.both$Deaths / Pop.proj.both$Pop
Pop.proj.both$Mortality.rate[Pop.proj.both$Mortality.rate>1] = 1
str(Pop.proj.both)




#   add a variable with the proportion of the pop
### 
head(Pop.proj.both)
pop_tot = Pop.proj.both %>% group_by(year) %>% 
  summarize(pop_tot_y = sum(Pop))
plot(pop_tot$year, pop_tot$pop_tot_y)


head(pop_tot)
mm = match(Pop.proj.both$year, pop_tot$year); length(mm)
Pop.proj.both$P_tot_year =  pop_tot$pop_tot_y[mm]
Pop.proj.both$p_prop = Pop.proj.both$Pop/ Pop.proj.both$P_tot_year

yy = 2020
sum(Pop.proj.both$p_prop[Pop.proj.both$year == yy])



############################################################################################################
####################################
#### Now combine Pop.proj.both with negaWatt scenar
head(negaWatt.data)
head(Pop.proj.both)
dim(Pop.proj.both)

nW_walk = negaWatt.data %>%  filter(Type=="Walking")
nW_cycle = negaWatt.data %>%  filter(Type=="Total_Cycling")



# walking/cycling is expressed in km/an/hab; need to translate into min/week
walk_Ref_volume <- 168
walk_speed <- 4.8
RR_walk = 0.89

cycle_Ref_volume <- 100
cycle_speed <- 14
RR_cycle = 0.90

nW_walk$minutes = (60*nW_walk$value /walk_speed) / (365.25/7)
nW_cycle$minutes = (60*nW_cycle$value /cycle_speed) / (365.25/7)

############################################################################################################
##### first hypothesis : assume homogeneous use of walking / cycling
Pophomo = Pop.proj.both[Pop.proj.both$year>2019,];dim(Pophomo)

Pophomo$S0_walk = nW_walk$minutes[nW_walk$Year==2020]
Pophomo$S0_cycle = nW_cycle$minutes[nW_cycle$Year==2020]

mm_walk = match(Pophomo$year, nW_walk$Year); length(mm_walk)
Pophomo$S1_walk = nW_walk$minutes[mm_walk]

mm_cycle = match(Pophomo$year, nW_cycle$Year); length(mm_cycle)
Pophomo$S1_cycle = nW_cycle$minutes[mm_cycle]


Pophomo$S0_walk_prev = (1-RR_walk)*(Pophomo$S0_walk/walk_Ref_volume)*Pophomo$Mortality.rate*Pophomo$Pop
Pophomo$S1_walk_prev = (1-RR_walk)*(Pophomo$S1_walk/walk_Ref_volume)*Pophomo$Mortality.rate*Pophomo$Pop  
Pophomo$N_prev_walk = Pophomo$S1_walk_prev - Pophomo$S0_walk_prev

Pophomo$S0_cycle_prev = (1-RR_cycle)*(Pophomo$S0_cycle/cycle_Ref_volume)*Pophomo$Mortality.rate*Pophomo$Pop
Pophomo$S1_cycle_prev = (1-RR_cycle)*(Pophomo$S1_cycle/cycle_Ref_volume)*Pophomo$Mortality.rate*Pophomo$Pop  
Pophomo$N_prev_cycle = Pophomo$S1_cycle_prev - Pophomo$S0_cycle_prev
Pophomo$N_prev_tot = Pophomo$N_prev_cycle + Pophomo$N_prev_walk
head(Pophomo)

Pophomo_all_age = Pophomo
# restrict to 20-90
dim(Pophomo)
Pophomo <- Pophomo %>% filter(age>19 & age<75);dim(Pophomo)

#Total number btw 2020 - 2050
nb_cum_year_age_cycle = sum(Pophomo$N_prev_cycle); nb_cum_year_age_cycle # 577 000, très sensible à la borne sup de l'âge
nb_cum_year_age_walk = sum(Pophomo$N_prev_walk); nb_cum_year_age_walk # 31 000 


# impact per year
death_prev_cycle_year = Pophomo %>% group_by(year) %>% 
  summarize(death_prev_year = sum(N_prev_cycle))
death_prev_cycle_year$Type = "Cycle"
death_prev_walk_year = Pophomo %>% group_by(year) %>% 
  summarize(death_prev_year = sum(N_prev_walk))
death_prev_walk_year$Type = "Walk"

death_prev = rbind(death_prev_cycle_year, death_prev_walk_year)
death_prev$Type = factor(death_prev$Type )
death_prev$year = as.numeric(death_prev$year)

summary(death_prev)
s = ggplot(data=death_prev, aes(x = year, y = death_prev_year, fill=Type)) +
  geom_bar(stat = "identity")

plot(s)
ggsave("impact_by_year_max_age_75.png", width = 9, height = 7, dpi = 300, units = "in")


impact_tot_per_age_max = NULL
for (age_max in 75:90){
  Pophomo <- Pophomo_all_age %>% filter(age>19 & age<age_max)
  nb_cum_year = sum(Pophomo$N_prev_tot)
  impact_tot_per_age_max = c(impact_tot_per_age_max, nb_cum_year)
}
age_max = 75:90
tab_impact_age = data.frame(age_max, impact_tot_per_age_max)

s = ggplot(data=tab_impact_age, aes(x = age_max, y = impact_tot_per_age_max)) +
  geom_bar(stat = "identity") + ggtitle("Total impact as a function of max. age")
plot(s)
ggsave("impact_per_max_age.png", width = 9, height = 7, dpi = 300, units = "in")

# impact per age and year
yy = 2040
tempy = Pophomo %>% filter(year == yy);dim(tempy)
plot(tempy$age, tempy$N_prev_tot, type = "l", col= "blue")

yy = 2030
tempy = Pophomo %>% filter(year == yy);dim(tempy)
lines(tempy$age, tempy$N_prev_tot, type = "l", col= "black")

yy = 2049
tempy = Pophomo %>% filter(year == yy);dim(tempy)
lines(tempy$age, tempy$N_prev_tot, type = "l", col= "red")




##############################
#life_expectancy
head(Pophomo_all_age)
str(Pophomo_all_age)
Pophomo = Pophomo_all_age
range(Pophomo$age)

# cap mortality 
Pophomo$Mortality.rate[Pophomo$Mortality.rate>1] = 1
Pophomo$Mortality.rate[Pophomo$age==106] = 1
range(Pophomo$Mortality.rate)


life_expectancy = function(data, yy){
  tmp = data %>%  filter(year == yy)
  tmp = tmp[order(tmp$age),]
  tmp$Mortality.rate.S1 = (tmp$Deaths - tmp$N_prev_tot)/tmp$Pop
  
  prop_alive_S0 = c(1, cumprod((1 - tmp$Mortality.rate) ))
  deaths_S0 <- -diff(prop_alive_S0)
  life_exp_S0 = sum(deaths_S0 * 0:(max(tmp$age)-1) ) 
  
  prop_alive_S1 = c(1, cumprod((1 - tmp$Mortality.rate.S1) ))
  deaths_S1 <- -diff(prop_alive_S1)
  life_exp_S1 = sum(deaths_S1 * 0:(max(tmp$age)-1) ) 
  
  diff_exp = life_exp_S1 - life_exp_S0
  
  return(data.frame("life_exp_S0" = life_exp_S0, "life_exp_S1"=life_exp_S1, "difference"=diff_exp))
}

life_expectancy(Pophomo, 2020)
life_expectancy(Pophomo, 2030)
life_expectancy(Pophomo, 2040)
life_expectancy(Pophomo, 2049)


Pophomo75 <- Pophomo %>% filter(age>19 & age<75);dim(Pophomo75)
life_expectancy(Pophomo, 2040)
life_expectancy(Pophomo75, 2040)



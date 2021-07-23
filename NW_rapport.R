
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
         age = ifelse(is.na(age)== T, 105, age)) %>% 
  select(-SEXE) %>% 
  pivot_longer(!c(age, sexe), names_to = "year", values_to = "Pop") 

Mortality.rate = Mortality.rate %>% 
  na.omit() %>% 
  mutate(sexe = ifelse(SEXE == "1", "Male", "Female")) %>% 
  rename( "age" = starts_with("AGE")) %>% 
  mutate(across(.cols = c(everything(), - sexe),  as.numeric),
         age = ifelse(is.na(age)== T, 105, age)) %>% 
  select(-SEXE) %>% 
  pivot_longer(!c(age, sexe), names_to = "year", values_to = "Deaths") %>% 
  na.omit()

Pop.proj = Pop.proj %>% 
  merge(Mortality.rate, by = c("age", "sexe", "year"))%>% 
  group_by(age, year) %>% 
  summarise(Deaths = sum(Deaths),
            Pop = sum(Pop)) %>% 
  mutate(Mortality.rate = Deaths/Pop) %>% 
  mutate(age_grp.FACTOR = cut( age, breaks = seq(0,150, by = 5), include.lowest = T, right = F),
         age_grp = as.character(age_grp.FACTOR), 
         age_grp = gsub("\\[|\\]|\\(|\\)", "", age_grp),
         age_grp = gsub(",", "-", age_grp),
         post = sub(".*-","",age_grp),
         age_grp = sub("-.*", "", age_grp),
         age_grp = paste0(age_grp,"-", as.numeric(post)-1),
         order = as.numeric(substr(age_grp,1,regexpr("-",age_grp)-1))) 


Data.Denmark = read.csv("Data_Denmark.csv", sep = ";") %>%
  mutate(age_grp = paste0(minRespAgeCorrect,"-", maxRespAgeCorrect)) %>%
  select(c(Period, RespSex, N:age_grp)) %>%
  pivot_longer(!c(Period, RespSex, N,age_grp),
               names_to = "type",
               values_to = "value") %>%
  mutate(type = ifelse(type == "WalkLen_pers_day", "Walking", "Total_Cycling"),
         Sexe = ifelse(RespSex == 1, "Male", "Female"),
         value = as.numeric(gsub(pattern = ",", ".", value))) %>%
  select(-RespSex) %>% 
  filter(age_grp != "10-14")

Data.Denmark.distribution = Data.Denmark %>% 
  filter(Period == 2) %>% 
  group_by(type, Period, age_grp) %>%
  summarise(value = sum(value)) %>% 
  group_by(type) %>% 
   mutate(freq = value/sum(value)) 

Data.Denmark.distribution %>% 
  group_by(type) %>% 
  summarise(sum(freq))

p1 = Data.Denmark.distribution %>%
  filter(type != "Walking" & Period == 2) %>%
  ggplot() + geom_bar(aes(x = age_grp, y = freq), stat = "identity", alpha = 0.9)+
  ylab("") +
  xlab("") +
  labs(title = "Vélo") +
  theme(legend.title = element_blank(),
        legend.position = "top")+
  scale_fill_manual(values = c("#E7B800", "#00AFBB"),
                    labels = c("Femmes", "Hommes")) +
  scale_y_continuous(limits = c(0,0.15), expand = c(0, 0),
                     labels  = function(x) paste0(x*100, "%"),name="")+ 
  theme(legend.position="none")
p1

p2 = Data.Denmark.distribution %>%
  filter(type == "Walking" & Period == 2) %>%
  ggplot() + geom_bar(aes(x = age_grp, y = freq), stat = "identity", alpha = 0.9)+
  ylab("") +
  xlab("") +
  labs(title = "Marche") +
  theme(legend.title = element_blank(),
        legend.position = "top")+
  scale_fill_manual(values = c("#E7B800", "#00AFBB"),
                    labels = c("Femmes", "Hommes")) +
  scale_y_continuous(limits = c(0,0.15), expand = c(0, 0),
                     labels  = function(x) paste0(x*100, "%"),name="")+ 
  theme(legend.position="none")
p2

Scenario.Full.Den = Data.Denmark.distribution %>% 
  filter(Period == 2) %>%
  select(age_grp, type, freq) %>%
  group_by(age_grp, type, freq) %>%
  slice(rep(1:n(), each = 42))%>%
  mutate(Year = row_number(),
         Year = 2008 - 1 + Year) %>%
  merge(negaWatt.data,
        by.x = c("Year", "type"),
        by.y = c("Year", "Type")) 


All.data.Full.Den = Pop.proj %>% 
  mutate(age_grp.FACTOR = cut( age, breaks = seq(0,150, by = 5), include.lowest = T, right = F),
         age_grp = as.character(age_grp.FACTOR), 
         age_grp = gsub("\\[|\\]|\\(|\\)", "", age_grp),
         age_grp = gsub(",", "-", age_grp),
         post = sub(".*-","",age_grp),
         age_grp = sub("-.*", "", age_grp),
         age_grp = paste0(age_grp,"-", as.numeric(post)-1),
         order = as.numeric(substr(age_grp,1,regexpr("-",age_grp)-1))) %>%
  merge(Scenario.Full.Den,
        by.x = c( "age_grp", "year"),
        by.y = c( "age_grp", "Year")) %>% 
    group_by(year, type, age_grp, freq) %>% 
  summarise(Pop = sum(Pop),
            Mortality.rate = mean(Mortality.rate)) %>% 
  group_by(year, type) %>% 
  mutate(N_freq = Pop/sum(Pop),
         freq_per_year = N_freq * freq)




All.data.Full.Den %>% 
  group_by(year, type) %>% 
  summarise(sum(N_freq))

%>% 
  group_by( age_grp, year, type, Adjusted.distri ) %>% 
   %>% 
  select( age_grp, year, Mortality.rate, Pop, type, Adjusted.distri) %>% 
  group_by(type, age_grp) %>% 
  mutate(type = ifelse(type == "Total_Cycling", "cycling", "walking"),
         volume = ifelse(type == "cycling",
                         ((Adjusted.distri/14)*60)/(365.25/7),
                         ((Adjusted.distri/4.8)*60)/(365.25/7)))

%>% 
  group_by(type) %>% 
  



%>% 
  mutate(volume = volume/Pop,
         RR = ifelse(type == "cycling", 0.9,0.89),
         MR = Mortality.rate * 100000,
         Ratio_cycling = ifelse(type == "cycling", volume/100, volume/169), ## verifier la bounderie sup
         Reduction_mortality_rate = (1-RR)*Ratio_cycling*100,
         Volume.const = first(volume))


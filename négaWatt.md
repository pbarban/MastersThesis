The négaWatt scenario
================

<details>

<summary>Packages</summary>

<p>

``` r
# Check if the packages that we need are installed
want = c("dplyr",
         "tidyr",
         "googlesheets4",
         "ggplot2")

have = want %in% rownames(installed.packages())

# Install the packages that we miss
if ( any(!have) ) { install.packages( want[!have] ) }

# Load the packages
junk <- lapply(want, library, character.only = T)

# Remove the objects we
```

</details>

# Description

Developed by the négaWatt Association, the “négaWatt 2017-2050” scénario
describes a potential pathway describing the technical features for
France to reach net carbon neutrality by 2050 while using only renewable
energy sources.

In its method and in its philosophy, the scenario develops a systemic
vision of the energy transition which involves more or less significant
changes in conditions of use, supply, transmission and production of
energy, and therefore changes sensitive to all consumption and
production activities in all sectors: housing, tertiary sector,
transport, industry, agriculture and food.

Based on national surveys, all trips made in France could be classified
into 25 categories and sub-categories, according to the type of trip
(commuting, occasional leisure, professional, etc.), its length, and its
space (from central Paris to rural areas). In each of them, the negaWatt
scenario makes evolve in a differentiated way the travelers x km
traveled, as well as their distribution among ten or so modes of
transport (1).

In the tranportaion sector, the scenario glimpses a society where active
mobility, such as walkig and cycling, become the majority of short
trips, especialy in urban areas(1).

## Data

|                    | 2010 | 2020 | 2030 | 2040 | 2050 | 2008-2050 |
| :----------------- | :--- | :--- | :--- | :--- | :--- | :-------- |
| Vélo Mds de voy.km | 6    | 7    | 16   | 30   | 32   | 473%      |
| voy.km/hab         | 90   | 105  | 237  | 420  | 443  | 393%      |

From 2018 to 2050, the scenario describes an increase in the distance
per cycling trip per person by 393%.

### Visualization

<details>

<summary>Codes</summary>

<p>

``` r
#négaWatt


negaWatt.data <- read.csv("new_nw.csv", sep = ";") %>%
  mutate(Type = ifelse(Type == "Marche", "Walking","Total_Cycling")) %>% 
  pivot_longer(!Type, names_to = "Year",
               values_to = "value")%>%
  na.omit() %>% 
  mutate(Year = as.numeric(gsub("X", "", Year)),
         value = as.numeric(value)) %>% 
  filter(Year <= 2050 & Year >= 2015)

saveRDS(negaWatt.data, "negaWatt.data.rds")

p1 = negaWatt.data %>% 
ggplot() +  
  geom_line(aes(x = Year, y = value, group = Type, color = Type), size = 1)+
  ylab("") +
  xlab("") +
  labs(title = "négaWatt scenario", subtitle = "In km/inhab/year") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 16),
        plot.subtitle = element_text(colour = "#595a5c", size = 12),
        legend.title = element_blank(),
        legend.text = element_text( size = 10),
        legend.position="top",
        axis.text=element_text(size=10),
        axis.text.x = element_text(angle = 60, vjust = 0.5, hjust=1))+
  ylim(0, 1250)
```

</details>

<img src="négaWatt_files/figure-gfm/unnamed-chunk-3-1.png" style="display: block; margin: auto;" />

# reference

<div id="refs" class="references">

<div id="ref-negawattSyntheseScenarionegawatt201720502017">

1\. negaWatt, A. synthese\_scenario-negawatt\_2017-2050.pdf. (2017).

</div>

</div>

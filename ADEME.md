ADEME
================

<details>

<summary>Packages</summary>

<p>

``` r
want = c("googlesheets4",
         "purrr",
         "dplyr",
         "tidyr",
         "zoo",
         "ggplot2")

have = want %in% rownames(installed.packages())

# Install the packages that we miss
if ( any(!have) ) { install.packages( want[!have] ) }

# Load the packages
junk <- lapply(want, library, character.only = T)

# Remove the objects we created
rm(have, want, junk)
```

</details>

# Introduction

<details>

<summary>Codes</summary>

<p>

``` r
ADEME.data <- read_sheet("https://docs.google.com/spreadsheets/d/1LFHU66VoZtDFF2OI2Wr4-bmw_x1UQHhn9gp_TtnNkWE/edit?usp=sharing") %>%
  mutate_all(as.character)

names(ADEME.data)<-gsub("\\.","",names(ADEME.data))

p2 <- ADEME.data %>%
  select(Type, Scenario, Distances7:Distances9)%>% 
  filter(Type != "Type")  %>% 
  set_names(slice(.,1)) %>%
  slice(-1) %>% 
  pivot_longer(cols = "2015":"2050", names_to = "time", values_to = "Km_jr_hab")%>% 
  rename("Type"= "Year") %>% 
  mutate(time = as.numeric(time),
         Km_jr_hab = as.numeric(Km_jr_hab),
    diff = lead(time) - time,
    diff = ifelse(diff < 0 , 1, diff)) %>% 
    group_by(Type, Scenario, time) %>%
  slice(rep(1:n(),each = diff)) %>% 
  mutate(year =  1:n() +time -1) %>% 
     group_by(Type, Scenario, time) %>% 
   mutate(Km_jr_hab = ifelse(time != year, NA, Km_jr_hab)) %>% 
  filter(year <= 2050  ) %>% 
    group_by(Type, Scenario) %>% 
  mutate(test = na.approx(Km_jr_hab),
         Name = paste(Scenario, Type)) %>% 
   ggplot() +  
  geom_line(aes(x = year, y = test * 362.5 , group = Name, color = Name), size = 1)+
  ylab("") +
  xlab("") +
  labs(title = "ADEME scenarios", subtitle = "In km/inhab/year") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 16),
        plot.subtitle = element_text(colour = "#595a5c", size = 12),
        legend.title = element_blank(),
        legend.text = element_text( size = 10),
        legend.position="top",
        axis.text=element_text(size=10),
        axis.text.x = element_text(angle = 60, vjust = 0.5, hjust=1)) +
  ylim(0, 1250)
```

</details>

From the ADEME’s documentation (1). The agency and its experts

The *Agence de l’Environnement et de la Maitrise de l’Energie* (ADEME)
is the french agency of the ecological transition. In short, they
participate in the establishment of public policies in the environment,
energy, and sustainable development domain.

ADEME has launched a prospective project for the next two years.
Compared to the previous project entitled *Visions de l’ADEME*, the new
scenarios have greatly evolved with both an awareness of the climate
emergency and new ambitions to be maintained in the long term (carbon
neutrality in 2050) but also with the emergence of broader ecological
issues (material, soils, etc.).

The main new features of the project are:

  - The realization of several French transition scenarios (national +
    footprint) that all aim to reach carbon neutrality, but in
    contrasting fashion, with an assessment of resources (materials,
    biomass, soil in particular) and including a territorial component;
  - A multi-criteria comparison (in particular technico-economic and
    environmental) of scenarios, conditions of realization and their
    consequences;
  - A retrospective, an inventory and trajectories up to at least 2050;
  - Dialogue with external stakeholders on the consistency of all the
    scenarios envisaged and enrichment of working hypotheses;
  - A descriptive strategic foresight on a few key sectors in the French
    context.

# Visualization

<img src="ADEME_files/figure-gfm/unnamed-chunk-3-1.png" style="display: block; margin: auto;" />

# reference

<div id="refs" class="references">

<div id="ref-ademeProjetenergiesressourcesademedecembre2020Pdf2020">

1\. ADEME. projet-energies-ressources-ademe-decembre-2020.pdf.

</div>

</div>

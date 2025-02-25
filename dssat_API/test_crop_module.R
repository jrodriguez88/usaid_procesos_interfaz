### Test Crop module - DSSAT - API - Aclimate,  EDACaP
# Author: Rodriguez-Espinoza J.
# https://github.com/jrodriguez88/
# 2022

# DSSAT Version 4.8
# Crops tested : c("rice", "maize", "barley", "sorghum", "wheat", "bean", "fababean", "teff")

##Settings:
# Number of Climate Scenaries: 99 ( max allow by DSSAT x file)
# 11 Planting dates (30 days - 1 sim/3 days) ..first planting date = 15 days after first day forecast (climate scenaries)
# 1 Soil - DSSAT ID
# irri <- F  --  Rainfed mode
# fert_in <- NULL - No fertilization

library(profvis)
library(bench)
library(tictoc)

library(foreach)
library(parallel)
library(doParallel)
library(dplyr)
library(tidyr)
library(tibble)
library(purrr)
library(readr)
library(lubridate)
library(stringr)
library(magrittr)
library(data.table)

##Conect geoserver
library(raster)
#library(furrr)
options(warn = 1)



tictoc::tic()


### Wheat
id <- "5a7e2e6a57d7f316c8bc514a_59b024a0b74a4a10f487eaa6_5b3edfe7b16a0d2edc1107e4_1XXX"
crop <- "wheat"
cultivar <- c("AW0071","Yecora_Rojo")
soil <- "IB00000001"
  #irri <- T
#fert <-  "fertapp"#  TRUE = auto, FALSE = not fertilized  
source("00_run_dssat_aclimate.R")

tictoc::toc()


### Barley
id <- "5a7e2e6a57d7f316c8bc514a_59b024a0b74a4a10f487eaa6_5b3edfe7b16a0d2edc1107e4_2"
crop <- "barley"
cultivar <- c( "IB0030", "Maris Badger")
soil <- "IB00000001"
irri <- T
fert <-  "auto"
source("00_run_dssat_aclimate.R")

### Maize
id <- "5a7e2e6a57d7f316c8bc514a_59b024a0b74a4a10f487eaa6_5b3edfe7b16a0d2edc1107e4_3"
crop <- "maize"
cultivar <- c( "990002", "MEDIUM SEASON")
soil <- "IB00000001"
source("00_run_dssat_aclimate.R")

### Sorghum
id <- "5a7e2e6a57d7f316c8bc514a_59b024a0b74a4a10f487eaa6_5b3edfe7b16a0d2edc1107e4_4"
crop <- "sorghum"
cultivar <- c( "990004", "W.AFRICAN")
soil <- "IB00000001"
source("00_run_dssat_aclimate.R")

### Rice
id <- "5a7e2e6a57d7f316c8bc514a_59b024a0b74a4a10f487eaa6_5b3edfe7b16a0d2edc1107e4_5"
crop <- "rice"
cultivar <- c( "IB0115",  "IR 64*")
soil <- "IB00000001"
source("00_run_dssat_aclimate.R")

### Beans
id <- "5a7e2e6a57d7f316c8bc514a_59b024a0b74a4a10f487eaa6_5b3edfe7b16a0d2edc1107e4_6"
crop <- "bean"
cultivar <- c( "990005", "Meso Amer. Hab.1")
soil <- "IB00000001"
source("00_run_dssat_aclimate.R")

### Faba Beans
id <- "5a7e2e6a57d7f316c8bc514a_59b024a0b74a4a10f487eaa6_5b3edfe7b16a0d2edc1107e4_7"
crop <- "fababean"
cultivar <- c( "CORD01", "ALAME LD170 1.2g")
soil <- "IB00000001"
source("00_run_dssat_aclimate.R")

### Teff
id <- "5a7e2e6a57d7f316c8bc514a_59b024a0b74a4a10f487eaa6_5b3edfe7b16a0d2edc1107e4_8"
crop <- "teff"
cultivar <- c("IB0304", "Wajera (local)")
soil <- "IB00000001"
source("00_run_dssat_aclimate.R")

tictoc::toc()

#> tictoc::toc()
#556.36 sec elapsed


run_crop_dssat <- function(id, path, crop, cultivar, soil){
  
  wd_p <- paste0(getwd(), "/")
  if(str_detect(wd_p, pattern = path, negate = T)) {setwd(path)}
  

  #id <- id
  #crop <- crop
  #cultivar <- cultivar
  #soil <- soil
  
  options(warn = 1)
  
  
  #Set crop
  #crop <- "wheat"
  #crop <- "barley"
  #cultivar <- c("AW0071","Yecora_Rojo")
  #cultivar <- c( "IB0030", "Maris Badger")
  #soil <- "IB00000001"
  #id <- "5a7e2e6a57d7f316c8bc514a_59b024a0b74a4a10f487eaa6_5b3edfe7b16a0d2edc1107e4_1"
  #id <- paste(crop, cultivar[2], soil, irri, fert, sep = "_") %>% str_remove('\\*')
  #site <- map_chr(str_split(id, "_"), 1)
  #cultivar <- map_chr(str_split(id, "_"), 2)
  #soil <- map_chr(str_split(id, "_"), 3)
  
  
  # Set working directory
  #script_dir <- dirname(sys.frame(1)$ofile)
  #setwd(paste0(script_dir, "/"))
  
  # Folders
  dir_scripts <- "dssat_scripts/"
  dir_outputs <- "outputs/" ; dir.create(dir_outputs)
  
  # Set up run paths
  dir_inputs_climate <- "inputs/climate/"
  dir_inputs_setup <- "inputs/setups/"
  dir_inputs_soil <- "inputs/soils/"
  dir_inputs_cultivar <- "inputs/cultivars/"
  
  # Source oryza-aclimate functions
  walk(list.files(dir_scripts, pattern = ".R$", full.names = T), ~ source(.x))
  
  # ISO code / codigo iso de cada configuracion --- define el nombre del archivo de salida
  ## Location vars/ data / resampling scenaries / planting dates
  location <- load_coordinates(dir_inputs_setup)
  climate_scenaries <- load_all_climate(dir_inputs_climate)[-100]
  
  planting_details <- read_csv(paste0(dir_inputs_setup, "planting_details.csv"), show_col_types = F) %>%
    dplyr::select(name, all_of(crop)) %>%  pivot_wider(names_from = name, values_from = all_of(crop))
  
  # Definir fecha inicial de simulacion/  
  #En este caso la define automaticamente de la fecha inicial de los escenarios climaticos
  initial_date  <- climate_scenaries[[1]]$date[[1]] + days(15)
  
  input_dates <- make_sim_dates(initial_date, planting_before = 15, number_days = 10, freq_sim = 3)
  sim_number <- length(input_dates$start_date)  # It depends of planting window form forecast
  
  ## Parallel computing 
  ncores <- detectCores()-2
  if(ncores > sim_number){ncores <- sim_number}
  #plan(multisession, workers = ncores)
  
  
  ### RUN DSSAT
  #select_day <- sim_ini_day
  lat <- location$lat
  long <- location$long
  elev <- location$elev
  
  ## Crea las configuraciones  para simular 45 dias 
  dir_run <- map(1:sim_number, ~make_dir_run(dir_outputs, .x))
  
  # copy default inputs
  map(dir_run, ~copy_inputs(dir_inputs_setup, dir_inputs_soil, dir_inputs_cultivar, crop, .x))
  
  
  # write DSSAT Batch file 
  id_name <- "CIAT0001"    ### ID for new workflow
  batch_filename <- paste0(dir_run, "/", "DSSBatch.v48")
  xfile <- crop_name_setup(id_name, crop)[["ext"]]
  treatments_number <- length(climate_scenaries)    # number of escenaries
  
  map(batch_filename, ~write_batch_aclimate(crop, xfile, treatments_number, .x))
  
  #CR <- read_lines(list.files(dir_inputs_setup, full.names = T, recursive = T, pattern = "*.CUL")) 
  
  
  ## Write Xfile - Set management params
  
  wth_station <- paste0("CIAT", sprintf("%.4d", 1:treatments_number))
  
  
  irri <- ifelse(planting_details$IRR == "YES", T, F)
  fert_in <- get_fertilizer(crop, planting_details, dir_inputs_setup, lat, long)
  
  X_param <- dir_run %>% unlist() %>% enframe(name = NULL, value = "path") %>%
    mutate(id_name = id_name,
           crop = crop, 
           cultivar = list(cultivar),
           soil = soil, 
           wth_station = list(wth_station),
           planting_details = list(planting_details), 
           irri = irri,
           fert_in = list(fert_in),
           start_date = input_dates$start_date,
           planting_date= input_dates$planting_date,
           emergence_date = -99, 
           treatments_number = treatments_number)
  
  
  pmap(X_param, write_exp_dssat)
  
  
  #tictoc::tic()
  
  
  registerDoParallel(ncores)
  sim_data  <- foreach(
    i = dir_run, 
    .export=c('crop', 'execute_dssat', 'write_wth_file', 'wth_station', 'climate_scenaries', 'lat', 'long', 'read_summary', 'read_wth_out', 'crop_name_setup'),
    .packages=c('dplyr', 'stringr', 'readr', 'lubridate', 'purrr', 'data.table')) %dopar% {
      map2(climate_scenaries, wth_station, ~write_wth_file(.x, i, .y, lat, long))
      execute_dssat(i, crop) 
      list(summary = read_summary(i) , weather = read_wth_out(i))
      
    }
  
  closeAllConnections()
  
  #tictoc::toc()
  
  
  outputs_df1 <- map2(.x = map(sim_data, "summary"),
                      .y = input_dates$planting_date, 
                      function(x,y){
                        map(c('yield_0', 'd_dry', 'prec_acu', 'bio_acu'), 
                            ~extract_summary_aclimate(x, .x)) %>% 
                          bind_rows() %>% 
                          tidy_descriptive(., crop, soil, cultivar[2], y, y)}) %>% 
    compact %>% bind_rows()
  
  outputs_df2 <- map2(.x = map(sim_data, "weather"),
                      .y = input_dates$planting_date, 
                      function(x,y){
                        map(c('t_max_acu', 't_min_acu'), 
                            ~extract_summary_aclimate(x, .x)) %>% 
                          bind_rows() %>% 
                          tidy_descriptive(., crop, soil, cultivar[2], y, y)}) %>% 
    compact %>% bind_rows()
  
  
  #execute_dssat(dir_run[[3]])
  
  write_csv(bind_rows(outputs_df1, outputs_df2), paste0("outputs/", id, ".csv"))
  
  #tictoc::toc()
  
  message(paste0("Successful Simulation \n Crop: ", 
                 crop, " - Cultivar: ", cultivar[2], "\n Soil: ", soil, 
                 "\n Irrigation: ", planting_details$IRR, "\n Fertilization: ", planting_details$FERT ))
  
  #dir_oryza = "oryza_API/"
  #list.files(dir_oryza, pattern = ".EXE$", full.names = T) 
  
  
  map(dir_run, ~unlink(.x, recursive=TRUE))
  
  
  setwd(wd_p)
  
}

run_crop_dssat(id = "5a7e2e6a57d7f316c8bc514a_59b024a0b74a4a10f487eaa6_5b3edfe7b16a0d2edc1107e4_TEST",
               path = "dssat_API/",
               crop = "wheat",
               cultivar = c("AW0071","Yecora_Rojo"),
               soil = "IB00000001")


run_crop_dssat(id, path, crop, cultivar, soil)




map(.x = c("5a7e2e6a57d7f316c8bc514a_59b024a0b74a4a10f487eaa6_5b3edfe7b16a0d2edc1107e4_TEST1", 
                 "5a7e2e6a57d7f316c8bc514a_59b024a0b74a4a10f487eaa6_5b3edfe7b16a0d2edc1107e4_TEST2"), 
    ~run_crop_dssat(id = .x,
                   path = "dssat_API/",
                   crop = "wheat",
                   cultivar = c("AW0071","Yecora_Rojo"),
                   soil = "IB00000001"))



  map2(c("barley", "sorghum"), list(c( "IB0030", "Maris Badger"), c( "990004", "W.AFRICAN")), 
       ~run_crop_dssat(id = "5a7e2e6a57d7f316c8bc514a_59b024a0b74a4a10f487eaa6_5b3edfe7b16a0d2edc1107e4_4", 
                       path = "dssat_API/", crop = "wheat", cultivar = c("AW0071","Yecora_Rojo"),  soil = "IB00000001"))

### Workflow Profile - 
#profvis({
#  crop <- "wheat"
#  cultivar <- c("AW0071","Yecora_Rojo")
#  soil <- "IB00000001"
#  source("00_run_dssat_aclimate.R")}
#)


### Test analysis

library(ggplot2)
library(plotly)

sim_data_acr <- list.files("outputs/", full.names = T) %>% map(read_csv) %>%
  bind_rows() %>% rename(crop = weather_station)


sim_data %>% 
  ggplot() +
  geom_line(aes(x = start, avg )) +
  geom_line(aes(start, conf_lower), color = "red") +
  geom_line(aes(start, conf_upper), color = "lightgreen")+
  facet_grid(measure ~crop, scales = "free") +
  theme_bw() +
  labs(
    x = "Date",
    y = NULL, 
  )




plot_ly(
    data = sim_data %>% filter(measure =="yield_0"),
    x = ~factor(start),
    color = ~ crop,
    type="box",
    lowerfence = ~ min,
    q1 = ~ quar_1,
    median = ~ median,
    q3 = ~ quar_3,
    upperfence = ~ max) %>%
    layout(
      yaxis = list(exponentformat = "SI",type="log",title = "Yield - kg/ha"),
      xaxis = list(title = "Date"),
      boxmode = "group")






#####

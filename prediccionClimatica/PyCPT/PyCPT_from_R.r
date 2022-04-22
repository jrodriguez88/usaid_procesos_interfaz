#install.packages('rjson') #Install rjson
library("jsonlite")

setwd(dir_inputs_nextgen) #json files location
inputsPyCPT <- read_json("Structure ConfigurationPyCpt.json")
inputsPyCPT

region <- "ETHIOPIA"

spatial_predictors <- paste(inputsPyCPT$spatial_predictors, collapse = " ")
spatial_predictors <- gsub(" ", ",", spatial_predictors)
spatial_predictors

spatial_predictands <- paste(inputsPyCPT$spatial_predictands, collapse = " ")
spatial_predictands <- gsub(" ", ",", spatial_predictands)
spatial_predictands

models <- paste(inputsPyCPT$models, collapse = " ")
models <- gsub(" ", ",", models)
models <- gsub("_", "-", models)
models

obs <- inputsPyCPT$obs
station <- inputsPyCPT$station
mos <- inputsPyCPT$mos
predictand <- inputsPyCPT$predictand
predictor <- inputsPyCPT$predictors

mons <- paste(inputsPyCPT$mons, collapse = " ")
mons <- gsub(" ", ",", mons)
mons

tgtii <- paste(inputsPyCPT$tgtii, collapse = " ")
tgtii <- gsub(" ", ",", tgtii)
tgtii

tgtff <- paste(inputsPyCPT$tgtff, collapse = " ")
tgtff <- gsub(" ", ",", tgtff)
tgtff

tgts <- paste(inputsPyCPT$tgts, collapse = " ")
tgts <- gsub(" ", ",", tgts)
tgts

tini <- inputsPyCPT$tini
tend <- inputsPyCPT$tend

xmodes_min <- inputsPyCPT$xmodes_min
xmodes_max <- inputsPyCPT$xmodes_max
ymodes_min <- inputsPyCPT$ymodes_min
ymodes_max <- inputsPyCPT$ymodes_max
ccamodes_min <- inputsPyCPT$ccamodes_min
ccamodes_max <- inputsPyCPT$ccamodes_max
force_download <- inputsPyCPT$force_download
single_models <- inputsPyCPT$single_models
forecast_anomaly <- inputsPyCPT$forecast_anomaly
forecast_spi <- inputsPyCPT$forecast_spi
confidence_level <- inputsPyCPT$confidence_level
ind_exec <- inputsPyCPT$ind_exec

setwd("/forecast/PyCPT/iri-pycpt/")
system(paste("python run_main.py", region, spatial_predictors, spatial_predictands, 
             models, obs, station, mos, predictand, predictor, mons, tgtii, 
             tgtff, tgts, tini, tend, xmodes_min, xmodes_max, ymodes_min, 
             ymodes_max, ccamodes_min, ccamodes_max, force_download, 
             single_models, forecast_anomaly, forecast_spi, confidence_level, 
             ind_exec))

#file.copy(paste0("/forecast/PyCPT/iri-pycpt/", currentCountry, "/output"), dirNextGen)
#datadir <- dirNextGen
#setwd(datadir)
#datadir <- paste0(dirCurrent, "output/")#"/forecast/PyCPT/iri-pycpt/ETHIOPIA/output"
datadir <- "/forecast/PyCPT/iri-pycpt/ETHIOPIA/output/"
setwd(datadir)
dir.create(file.path(datadir,"nc_files"))

models=as.character(inputsPyCPT$models)
MOS = mos
PREDICTAND = predictand
PREDICTOR = predictor
monf = 'Apr'	# Initialization month 
tgts = as.character(inputsPyCPT$tgts)
mons = as.character(inputsPyCPT$mons)

fyr=2022	# Forecast year

for (seas in tgts)
{
  #seas=tgts[1]
	#### translate all  output data to netcdf
	for (i in 1:length(models)) {
	  #probablistics forecast
	  ctl_input = paste0(datadir,models[i],"_",PREDICTAND,PREDICTOR,"_CCAFCST_P_",seas,"_",monf,fyr,".ctl")
	  nc_output = paste0(datadir,"nc_files/",models[i],"_",PREDICTAND,PREDICTOR,"_CCAFCST_P_",seas,"_",monf,fyr,".nc")
	  system(paste0("cdo -f nc import_binary ", ctl_input, " ", nc_output))
	  #Deterministic forecast
	  ctl_input2 = paste0(datadir,models[i],"_",PREDICTAND,PREDICTOR,"_CCAFCST_mu_",seas,"_",monf,fyr,".ctl")
	  nc_output2 = paste0(datadir,"nc_files/",models[i],"_",PREDICTAND,PREDICTOR,"_CCAFCST_mu_",seas,"_",monf,fyr,".nc")
	  system(paste0("cdo -f nc import_binary ", ctl_input2, " ", nc_output2))
	  
	}

	system(paste0("cdo --no_history -ensmean  nc_files/*_CCAFCST_P_*.nc NextGEN_",PREDICTAND,PREDICTOR,"_",MOS,"FCST_P_",seas,"_",monf,fyr,".nc"))
	system(paste0("ncrename -v a,Below_Normal -v b,Normal -v c,Above_Normal  NextGEN_",PREDICTAND,PREDICTOR,"_",MOS,"FCST_P_",seas,"_",monf,fyr,".nc"))
	system(paste0("cdo --no_history -ensmean  nc_files/*_CCAFCST_mu_*.nc NextGEN_",PREDICTAND,PREDICTOR,"_",MOS,"FCST_mu_",seas,"_",monf,fyr,".nc"))
	system(paste0("rm -rf ",datadir,"nc_files/*.nc"))
}

nextGenFileName_prob <- paste0("NextGEN_",PREDICTAND,PREDICTOR,"_",MOS,"FCST_P_",tgts,"_",monf,fyr,".nc")
nextGenFileName_det <- paste0("NextGEN_",PREDICTAND,PREDICTOR,"_",MOS,"FCST_mu_",tgts,"_",monf,fyr,".nc")

library(raster)
library(rgdal)
library(ncdf4) #Must be installed on the image

stacksBySeason <- list()
for(i in 1:length(nextGenFileName_prob)){
  dataNextGenAbove = raster(paste0(datadir, "/", nextGenFileName_prob[i]), varname="Above_Normal")
  dataNextGenBelow = raster(paste0(datadir, "/", nextGenFileName_prob[i]), varname="Below_Normal")
  dataNextGenNormal = raster(paste0(datadir, "/", nextGenFileName_prob[i]), varname="Normal")

  stacksBySeason [[i]] = stack(dataNextGenBelow, dataNextGenNormal, dataNextGenAbove)
}
monthsNumber <- list("Jan-Mar"=2, "Feb-Apr"=3, "Mar-May"=4, "Apr-Jun"=5, "May-Jul"=6, "Jun-Aug"=7, "Jul-Sep"=8, "Aug-Oct"=9, "Sep-Nov"=10, "Oct-Dec"=11, "Nov-Jan"=12, "Dec-Feb"=1)
stations_coords <- read.table("/forecast/workdir/ETHIOPIA/inputs/prediccionClimatica/NextGenPycptData/Ethiopia/stations_coords.csv", head=TRUE, sep=",")
coords <- data.frame(stations_coords$lon, stations_coords$lat)
names (coords)[1:2] =c("lon", "lat")

list_Prob_Forec = list()

for( i in 1: length(stacksBySeason)){

  stacksBySeasonCurrent = stack(stacksBySeason[[i]])
  P_forecast_1= extract(stacksBySeasonCurrent, coords)

  P_forecast_final = data.frame(rep(fyr, nrow(coords)), rep(as.numeric(monthsNumber[tgts[i]]), nrow(coords)),stations_coords[,1],P_forecast_1) ##ciclo
  names(P_forecast_final)[1:6]=c("year", "month", "id", "below", "normal", "above")

  list_Prob_Forec [[i]] = P_forecast_final 
}

list_Prob_Forec_new = lapply(list_Prob_Forec, rbind)#list_Prob_Forec [[1]]

list_Prob_Forec_new = as.data.frame(list_Prob_Forec[[1]])

for (i in 2:length(list_Prob_Forec)){

list_Prob_Forec_new = rbind(list_Prob_Forec_new, as.data.frame(list_Prob_Forec[[i]]))

}
write.table(list_Prob_Forec_new, "/forecast/workdir/ETHIOPIA/outputs/prediccionClimatica/probForecast/probabilities.csv", row.names=FALSE, sep=",")


#head(P_forecast_final)



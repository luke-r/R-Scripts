#best run from an independent ide as opposed to native R env. 
#loc Should be the location of the R-Services Library for the instance of SQL Server. 
#packages has the list of packages to be installed. 

loc <- "C:/Program Files/Microsoft SQL Server/INSTANCENAME/R_SERVICES/library"
  
ipak <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg)) 
    install.packages(new.pkg, dependencies = TRUE, lib = loc)
  sapply(pkg, require, character.only = TRUE)
}

packages <- c(
	"ggplot2"
	,"plyr"
	,"reshape2"
	,"RColorBrewer"
	,"scales"
	,"grid"
	,"zoo"
	,"assertthat"
	,"BH"
	,"bitops"
	,"caTools"
	,"chron"
	,"colorspace"
	,"data.table"
	,"DataCombine"
	,"DBI"
	,"dichromat"
	,"dplyr"
	,"evaluate"
	,"jsonlite"
	,"RODBC"
	,"rvest"
	,"stringi"
	,"stringr"
	,"xml2"
)

ipak(packages)

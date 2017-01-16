library(RODBC)
##################################################################################
#User Defined Parameters
rcsv_server = "servername"
rcsv_temptablename = "##temptablename"
rcsv_filename = "C:/filepath/filename.csv"

##################################################################################
odbcCloseAll()

csvr_con <- odbcDriverConnect(paste0('driver={SQL SERVER};server=',rcsv_server,';database=tempdb;trusted_connection=true;'))

read_csv <- as.data.frame(
  read.csv(
    paste0(
      rcsv_filename
    )
  )
  ,stringsASFactors=FALSE
)
sqlSave(
  csvr_con,read_csv,tablename=rcsv_temptablename,append = TRUE 
)

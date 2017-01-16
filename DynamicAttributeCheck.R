#Example of Vectors/Loops to eliminate repetitive code. Line chart. 
library(RODBC)
library(ggplot2)
library(zoo)
library(ISOweek)

options(scipen = 999)
odbcCloseAll()

time_input <- "Month"        #Options: "Week","Month","Year"
data_output <- "Single"     #Options: "Single","Layered"
db_1 <- "dbname"
schema_1 <- "schemaname"
table_1 <- "tablename"
con_1 <- odbcDriverConnect(paste0('driver={SQL SERVER};server=servername;database=',db_1,';trusted_connection=true;'))
con_2 <- odbcDriverConnect(paste0('driver={SQL SERVER};server=servername;database=tempdb;trusted_connection=true;'))

sql_1 <- paste0("SELECT 
	               ROW_NUMBER() OVER (ORDER BY Column_id ASC) AS 'Row'
                ,Schema_Name(obj.Schema_ID) AS 'Schema'
                ,Object_Name(obj.Object_id) 'Object'
                ,col.NAME 'ColumnName'
                ,col.Column_id
                ,typ.NAME 'DataType'
                ,col.Max_length 'length Of Datatype'
                ,CASE 
                WHEN col.is_nullable = 0
                THEN 'NOT NULL'
                ELSE 'NULL'
                END 'constraint'
                FROM sys.all_columns col
                INNER JOIN sys.all_objects obj ON col.Object_id = obj.object_id
                INNER JOIN sys.types typ ON col.system_type_id = typ.system_type_id
                WHERE Schema_Name(obj.Schema_ID) = '",schema_1,"'
                AND Object_Name(obj.Object_id) = '",table_1,"'
                AND typ.NAME !='sysname'
                ORDER BY obj.Object_id,col.Column_id"
)

df_sys <- as.data.frame(sqlQuery(con_1,sql_1),stringsAsFactors = FALSE)

for (i in df_sys$Row) {
 ifelse(i == 1
        ,df_sys$ColumnNameCode <- paste0("AVG(CASE WHEN [P].",df_sys$ColumnName," IS NULL THEN 0.0000 ELSE 1.0000 END)")
        ,df_sys$ColumnNameCode <- paste0("+AVG(CASE WHEN [P].",df_sys$ColumnName," IS NULL THEN 0.0000 ELSE 1.0000 END)")
        )
}
ColumnNameCode <- paste(df_sys$ColumnNameCode,collapse = " ")

if(time_input == "Week") {
  date_grouping_X3 <- c(" CAST(YEAR([P].[RowInsertDate]) AS integer) AS [Year]
	,CAST(DATEPART(ww,[P].[RowInsertDate]) AS integer) AS [Week] "," YEAR([P].[RowInsertDate])
	,DATEPART(ww,[P].[RowInsertDate]) "," AND [2.1].[Week] = DATEPART(ww,[P].[RowInsertDate]) ")
}
if(time_input == "Year") {
  date_grouping_X3 <- c("CAST(YEAR([P].[RowInsertDate]) AS integer) AS [Year]","YEAR([P].[RowInsertDate])","")  
}
if(time_input == "Month") {
  date_grouping_X3 <- c(" CAST(YEAR([P].[RowInsertDate]) AS integer) AS [Year]
		,CAST(MONTH([P].[RowInsertDate]) AS integer) AS [Month]"," YEAR([P].[RowInsertDate])
		,MONTH([P].[RowInsertDate])"," AND [2.1].[Month] = MONTH([P].[RowInsertDate])")
}

sql_2 <- paste0(
  "SELECT ",date_grouping_X3[1]," 
  ,[2.1].[DataCompleteness]
  FROM ",db_1,".",schema_1,".",table_1," AS [P] 
  LEFT JOIN (
    SELECT((
      0 ",ColumnNameCode,")/",length(df_sys$Row),") AS [DataCompleteness],",date_grouping_X3[1]," 
    FROM ",db_1,".",schema_1,".",table_1," AS [P]
    GROUP BY ",date_grouping_X3[2]," 
  ) AS [2.1] ON [2.1].[Year] = YEAR([P].[RowInsertDate])",date_grouping_X3[3],
  "WHERE YEAR([P].[RowInsertDate]) IS NOT NULL 
  GROUP BY ",date_grouping_X3[2],",[2.1].[DataCompleteness] 
  ORDER BY ",date_grouping_X3[2]
)
sql_2_a <- gsub("[\n]", "", sql_2) ## <------ This could be stacked w/ sql_2_b
sql_2_b <- gsub("[\t]", "", sql_2_a)
df_pac <- as.data.frame(sqlQuery(con_1,sql_2_b),stringsAsFactors = FALSE)

if (data_output == "Layered") {
  sqlSave(con_2,df_pac,tablename = "##Cthulhu",append = TRUE)
  sql_layered_xml_cols_raw <- "
    STUFF((SELECT distinct ',' + QUOTENAME(c.[YEAR]) 
		FROM #Cthulhu c
    FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)') 
    ,1,1,'')"
  sql_layered_xml_cols_clean <- gsub("[\n]","",gsub("[\t]","",sql_layered_xml_cols_raw))
  sql_layered_qry <- paste0("SELECT ChosenAttribute, ",sql_layered_xml_cols_clean," from 
				(
					select ChosenAttribute
						, [YEAR]
						, DataCompleteness
					from #Cthulhu
			   ) x
				pivot 
				(
					 max(DataCompleteness)
					for [YEAR] in (",sql_layered_xml_cols_clean,")
				) p ")
  sql_layered_qry_clean <- gsub("[\n]","",gsub("[\t]","",sql_layered_qry))
}

if (time_input == "Week") {
  df_pac$ComboDate <- paste(df_pac$Year,df_pac$Week,sep = "-")
  df_pac$WeekMod <- ifelse(nchar(df_pac$Week)==1,paste0("0",df_pac$Week),df_pac$Week)
  df_pac$ComboDate2 <- paste0(df_pac$Year,"-W",df_pac$WeekMod,"-1")
  df_pac$ModDate <- ISOweek2date(df_pac$ComboDate2)
  df_pac$DataRollMean <- rollmean(df_pac$DataCompleteness,10,fill = NA)
}
if (time_input == "Year") {
  df_pac$ComboDate <- paste0(df_pac$Year)
  df_pac$ModDate <- as.Date(df_pac$ComboDate,format = "%Y")
  df_pac$DataROllMean <- NULL
}
if (time_input == "Month") {
  df_pac$ComboDate <- paste(df_pac$Year,df_pac$Month,"01",sep = "-")
  df_pac$ModDate <- as.Date(df_pac$ComboDate,format = "%Y-%m-%d")
  df_pac$DataRollMean <- rollmean(df_pac$DataCompleteness,6,fill = NA)
}

ggplot(data = df_pac,aes(x = ModDate)) +
  scale_y_continuous(limits = c(0.35,0.6)) +
  scale_x_date(date_breaks = "6 months") +
  geom_line(y = df_pac$DataCompleteness,group = 1) +
  if ( time_input != "Year" ) {geom_line(y = df_pac$DataRollMean,group = 1,color = "Red")}

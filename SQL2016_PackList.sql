USE [AdventureWorks2014];
GO

CREATE Procedure [dev].[R_Package_List] AS

EXECUTE sp_execute_external_script  @language=N'R'  
     ,@script = N'str(OutputDataSet);  
     packagematrix <- installed.packages();  
     NameOnly <- packagematrix[,1];  
     OutputDataSet <- as.data.frame(NameOnly);'  
     ,@input_data_1 = N'SELECT 1 as col'  
     WITH RESULT SETS ((PackageName nvarchar(250) ))   


GO



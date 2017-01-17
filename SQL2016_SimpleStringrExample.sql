#It's important to note that the Rvar OutputDataSet, is case sensitive, like any other Rvar. 
#OutputDataSet is the object which is pushed out to result. @input_data_1 comes in, ..._name is the name used within the R instance. 
#Results cols must match R OutputDataSet cols. No. must be equal. 

USE [AdventureWorks2014]
GO

CREATE PROCEDURE [dev].[R_Example_BP_StringrLen] AS


   execute sp_execute_external_script    
      @language = N'R'    
    , @script = N' 
	library(stringr)
	BPEC <- as.data.frame(BPEC);    
	BPEC$len <- str_length(BPEC$customer_company_name)
                         OutputDataSet <- as.data.frame(BPEC);'    
    , @input_data_1 = N' SELECT TOP 100 customer_company_name FROM AdventureWorks2014.dbo.BPEnergyCompany'  
	, @input_data_1_name = N'BPEC'
    WITH RESULT SETS (([customercompanyname] nvarchar(250) NOT NULL , [len] nvarchar(250) NOT NULL));    


GO



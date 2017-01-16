USE [AdventureWorks2014];
GO

CREATE Procedure [dev].[R_Package_Location] AS

EXECUTE sp_execute_external_script  @language = N'R'
, @script = N'OutputDataSet <- data.frame(.libPaths());'
WITH RESULT SETS (([DefaultLibraryName] VARCHAR(MAX) NOT NULL));

GO

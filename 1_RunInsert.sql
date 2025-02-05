/*
   Comparing Regular INSERT vs. INSERT with TABLOCK Hint

   INSERT INTO TargetTable (column)
   SELECT * FROM SourceTable

   VS

   INSERT INTO TargetTable WITH (TABLOCK) (column)
   SELECT * FROM SourceTable

   ** Performance Differences
   ** Trade-offs
   ** Best Case Scenarios
*/

--------------------------------------------------------
-- PERFORM INSERT WITHOUT HINT ON A HEAP TABLE
--------------------------------------------------------

USE [DBATEST]
GO

-- SOURCE TABLE: dbo.t1
SELECT COUNT(*) AS t1_COUNT FROM dbo.t1;

-- TARGET TABLE: dbo.t2
SELECT COUNT(*) AS t2_COUNT FROM dbo.t2;

-- Enable performance statistics
SET STATISTICS TIME, IO ON;
SET NOCOUNT ON;

-- Ensure a clean state for logging analysis
CHECKPOINT;

SELECT name, recovery_model_desc 
FROM sys.databases WHERE name = 'DBATEST';



--------------------------------------------------------
-- INSERT WITHOUT TABLOCK HINT
--------------------------------------------------------

INSERT INTO dbo.t2 (id, a, b)
SELECT * FROM dbo.t1;

--------------------------------------------------------
-- VERIFY IF MINIMAL LOGGING OCCURRED
--------------------------------------------------------

/*
   ** Check the Transaction Log for Insert Behavior **
   ** 'LOP_INSERT_ROWS'  = Number of insert records tracked in T-Log
   ** 'LOP_FORMAT_PAGE'  = Number of pages formatted for this operation
*/

SELECT Operation, COUNT(*) AS Count
FROM sys.fn_dblog(NULL, NULL) 
WHERE Operation IN (N'LOP_INSERT_ROWS', 'LOP_FORMAT_PAGE')
GROUP BY Operation
ORDER BY COUNT(*) DESC;

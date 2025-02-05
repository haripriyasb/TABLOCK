/*
   PERFORM INSERT WITH TABLOCK HINT ON A HEAP TABLE
   ------------------------------------------------
   Reset and recreate the same environment to perform 
   an INSERT using (TABLOCK) hint.
*/

USE [DBATEST]
GO

SET STATISTICS TIME, IO ON;
SET NOCOUNT ON;

--------------------------------------------------------
-- RESET ENVIRONMENT
--------------------------------------------------------

TRUNCATE TABLE dbo.t2;  -- Target table reset

CHECKPOINT;  -- Ensure log is cleared

--------------------------------------------------------
-- VERIFY ENVIRONMENT RESET
--------------------------------------------------------

/*
   Verify that no insert operations are currently logged.
   'LOP_INSERT_ROWS' should be zero before the test.
*/

SELECT Operation, COUNT(*) AS Count
FROM sys.fn_dblog(NULL, NULL) 
WHERE Operation IN (N'LOP_INSERT_ROWS', 'LOP_FORMAT_PAGE')
GROUP BY Operation 
ORDER BY COUNT(*) DESC;

-- VERIFY ROW COUNTS
SELECT COUNT(*) AS t1_COUNT FROM dbo.t1;
SELECT COUNT(*) AS t2_COUNT FROM dbo.t2;

/*
--------------------------------------------------------
-- CHECK MINIMAL LOGGING REQUIREMENTS
https://learn.microsoft.com/en-us/sql/t-sql/statements/insert-transact-sql?view=sql-server-ver16#using-insert-intoselect-to-bulk-import-data-with-minimal-logging-and-parallelism
--------------------------------------------------------
*/

-- 1. Table must be a Heap (No Indexes)
SELECT * FROM sys.indexes WHERE OBJECT_ID = OBJECT_ID('dbo.t2');

-- 2. Table should not be part of replication
SELECT * FROM sys.tables 
WHERE is_replicated = 1 AND OBJECT_ID = OBJECT_ID('dbo.t2');

-- 3. Database should be in SIMPLE or BULK_LOGGED recovery model
SELECT name, recovery_model_desc 
FROM sys.databases WHERE name = 'DBATEST';

--------------------------------------------------------
-- PERFORM INSERT WITH TABLOCK HINT
--------------------------------------------------------

INSERT INTO dbo.t2 WITH (TABLOCK) (id, a, b)
SELECT * FROM dbo.t1;

--------------------------------------------------------
-- VERIFY MINIMALLY LOGGED INSERT
--------------------------------------------------------

/*
   ** Check Transaction Log for Minimal Logging **
   'LOP_INSERT_ROWS'  = Number of insert records tracked in T-Log 
   'LOP_FORMAT_PAGE'  = Number of pages formatted for this operation
*/

SELECT Operation, COUNT(*) AS Count
FROM sys.fn_dblog(NULL, NULL) 
WHERE Operation IN (N'LOP_INSERT_ROWS', 'LOP_FORMAT_PAGE')
GROUP BY Operation 
ORDER BY COUNT(*) DESC;

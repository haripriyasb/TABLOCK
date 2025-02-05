/*
   PERFORM INSERT WITH TABLOCK HINT ON TABLE WITH:
   a. CLUSTERED INDEX
   b. NON-CLUSTERED INDEX
   c. COLUMNSTORE INDEX

   RESET AND CREATE THE SAME ENVIRONMENT
*/

USE DBATEST
GO

SET STATISTICS TIME, IO ON;
SET NOCOUNT ON;

--------------------------------------------------------
-- RESET ENVIRONMENT
--------------------------------------------------------

TRUNCATE TABLE dbo.t2;
CHECKPOINT;

--------------------------------------------------------
-- VERIFY ENVIRONMENT RESET
--------------------------------------------------------

/*
   Ensure no insert operations are currently logged.
   'LOP_INSERT_ROWS' should be zero before the test.
*/

SELECT Operation, COUNT(*) AS Count
FROM sys.fn_dblog(NULL, NULL) 
WHERE Operation IN (N'LOP_INSERT_ROWS', 'LOP_FORMAT_PAGE')
GROUP BY Operation 
ORDER BY COUNT(*) DESC;

--------------------------------------------------------
-- VERIFY DATABASE RECOVERY MODEL
--------------------------------------------------------

SELECT name, recovery_model_desc 
FROM sys.databases WHERE name = 'DBATEST';

--------------------------------------------------------
-- TEST 1: INSERT WITH CLUSTERED INDEX
--------------------------------------------------------

-- Create a Clustered Index
CREATE CLUSTERED INDEX CI_ID ON dbo.t2(id);

-- VERIFY ROW COUNTS
SELECT COUNT(*) AS t1_COUNT FROM dbo.t1;
SELECT COUNT(*) AS t2_COUNT FROM dbo.t2;

-- Note: Clustered Index DISABLES Parallel INSERTS
INSERT INTO dbo.t2 WITH (TABLOCK) (id, a, b)
SELECT * FROM dbo.t1;

-- Verify Transaction Log Entries
SELECT Operation, COUNT(*) AS Count
FROM sys.fn_dblog(NULL, NULL) 
WHERE Operation IN (N'LOP_INSERT_ROWS', 'LOP_FORMAT_PAGE')
GROUP BY Operation 
ORDER BY COUNT(*) DESC;



-- VERIFY ROW COUNTS
SELECT COUNT(*) AS t1_COUNT FROM dbo.t1;
SELECT COUNT(*) AS t2_COUNT FROM dbo.t2;

CHECKPOINT;

--Non-heap target table
INSERT INTO dbo.t2 WITH (TABLOCK) (id, a, b)
SELECT * FROM dbo.t1;


--------------------------------------------------------
-- TEST 2: INSERT WITH NON-CLUSTERED INDEX
--------------------------------------------------------

-- Drop Clustered Index and Reset Table
DROP INDEX CI_ID ON dbo.t2;
TRUNCATE TABLE dbo.t2;
CHECKPOINT;

-- Create Non-Clustered Index
CREATE NONCLUSTERED INDEX NCI_a ON dbo.t2(a);

-- VERIFY ROW COUNTS
SELECT COUNT(*) AS t1_COUNT FROM dbo.t1;
SELECT COUNT(*) AS t2_COUNT FROM dbo.t2;

-- Perform Insert
INSERT INTO dbo.t2 WITH (TABLOCK) (id, a, b)
SELECT * FROM dbo.t1;

-- Verify Transaction Log Entries
SELECT Operation, COUNT(*) AS Count
FROM sys.fn_dblog(NULL, NULL) 
WHERE Operation IN (N'LOP_INSERT_ROWS', 'LOP_FORMAT_PAGE')
GROUP BY Operation 
ORDER BY COUNT(*) DESC;

--------------------------------------------------------
-- TEST 3: INSERT WITH COLUMNSTORE CLUSTERED INDEX
--------------------------------------------------------

-- Drop Non-Clustered Index and Reset Table
DROP INDEX NCI_a ON dbo.t2;
TRUNCATE TABLE dbo.t2;
CHECKPOINT;

-- Create Clustered Columnstore Index
CREATE CLUSTERED COLUMNSTORE INDEX CCI ON dbo.t2;

-- VERIFY ROW COUNTS
SELECT COUNT(*) AS t1_COUNT FROM dbo.t1;
SELECT COUNT(*) AS t2_COUNT FROM dbo.t2;

-- Perform Insert
INSERT INTO dbo.t2 WITH (TABLOCK) (id, a, b)
SELECT * FROM dbo.t1;

-- Verify Transaction Log Entries
SELECT Operation, COUNT(*) AS Count
FROM sys.fn_dblog(NULL, NULL) 
WHERE Operation IN (N'LOP_INSERT_ROWS', 'LOP_FORMAT_PAGE')
GROUP BY Operation 
ORDER BY COUNT(*) DESC;

-- Cleanup: Drop Columnstore Index
DROP INDEX CCI ON dbo.t2;

--------------------------------------------------------
-- SUMMARY:
-- - COLUMNSTORE CLUSTERED INDEX: Minimal logging in both empty and non-empty tables.
-- - ROWSTORE CLUSTERED/NON-CLUSTERED INDEX: Insert runtime is slower in non-empty tables.
--------------------------------------------------------

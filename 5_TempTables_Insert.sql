/*
   INSERTING INTO TEMP TABLES WITH AND WITHOUT TABLOCK HINT
*/

USE DBATEST;
GO

SET STATISTICS TIME, IO ON;
SET NOCOUNT ON;

--------------------------------------------------------
-- RESET CHECKPOINT
--------------------------------------------------------

CHECKPOINT;

--------------------------------------------------------
-- CREATE TEMP TABLE #t2 (Same structure as dbo.t1)
--------------------------------------------------------

DROP TABLE IF EXISTS #t2;
GO

CREATE TABLE #t2 (
	[id] BIGINT NULL,
	[a] VARCHAR(32) NULL,
	[b] VARCHAR(32) NULL
);
GO

--------------------------------------------------------
-- VERIFY TABLE ROW COUNTS BEFORE INSERT
--------------------------------------------------------

/* SOURCE TABLE (Regular user table) */
SELECT COUNT(*) AS t1_COUNT FROM dbo.t1;

/* TARGET TABLE (Temp table) */
SELECT COUNT(*) AS t2_COUNT FROM #t2;

--------------------------------------------------------
-- TEST 1: INSERT WITHOUT TABLOCK HINT
--------------------------------------------------------

CHECKPOINT;

INSERT INTO #t2 (id, a, b) 
SELECT * FROM dbo.t1;

/* CHECK LOGGED OPERATIONS */
SELECT Operation, COUNT(*) AS Count
FROM sys.fn_dblog(NULL, NULL) 
WHERE Operation IN (N'LOP_INSERT_ROWS', 'LOP_FORMAT_PAGE')
GROUP BY Operation 
ORDER BY COUNT(*) DESC;

--------------------------------------------------------
-- RESET TEMP TABLE AND LOG
--------------------------------------------------------

TRUNCATE TABLE #t2;

/* VERIFY TABLE IS EMPTY */
SELECT COUNT(*) AS t2_COUNT FROM #t2;

/* RESET LOG */
CHECKPOINT;

--------------------------------------------------------
-- TEST 2: INSERT WITH TABLOCK HINT
--------------------------------------------------------

INSERT INTO #t2 WITH (TABLOCK) (id, a, b) 
SELECT * FROM dbo.t1;

/* CHECK LOGGED OPERATIONS */
SELECT Operation, COUNT(*) AS Count
FROM sys.fn_dblog(NULL, NULL) 
WHERE Operation IN (N'LOP_INSERT_ROWS', 'LOP_FORMAT_PAGE')
GROUP BY Operation 
ORDER BY COUNT(*) DESC;

--------------------------------------------------------
-- TAKEAWAY:
--   INSERT INTO TEMP TABLES WITH TABLOCK HINT ENABLES PARALLELISM,
--   RESULTING IN A FASTER EXECUTION TIME.
--   APPLIES TO GLOBAL TEMP TABLES TOO
--------------------------------------------------------

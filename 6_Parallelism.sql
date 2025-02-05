/*
    WHEN PARALLELISM GETS ENABLED FOR TABLOCK HINT
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
-- TEST 1: SMALL DATASET (NO PARALLELISM EXPECTED)
--------------------------------------------------------

DROP TABLE IF EXISTS dbo.t1;
GO

--CHECK COST THRESHOLD FOR PARALLELISM
EXECUTE sp_configure 'cost threshold for parallelism'
GO

-- CREATE AND POPULATE t1 WITH 10,000 ROWS
SELECT 
    t1.k AS id,
    'a_' + CAST(t1.k AS VARCHAR) AS a,
    'b_' + CAST(t1.k / 2 AS VARCHAR) AS b
INTO dbo.t1
FROM (
    SELECT ROW_NUMBER() OVER (ORDER BY a.object_id) AS k
    FROM sys.all_columns, sys.all_columns a
) t1
WHERE t1.k < 10001;

-- RESET TARGET TABLE
TRUNCATE TABLE dbo.t2;

-- VERIFY ROW COUNTS
SELECT COUNT(*) AS t1_COUNT FROM dbo.t1;
SELECT COUNT(*) AS t2_COUNT FROM dbo.t2;

-- INSERT WITH TABLOCK (EXPECTED SERIAL EXECUTION)
INSERT INTO dbo.t2 WITH (TABLOCK) (id, a, b) 
SELECT * FROM dbo.t1;

--------------------------------------------------------
-- TEST 2: LARGER DATASET (STILL SERIAL)
--------------------------------------------------------

DROP TABLE IF EXISTS dbo.t1;
GO

-- CREATE AND POPULATE t1 WITH 98,949 ROWS
SELECT 
    t1.k AS id,
    'a_' + CAST(t1.k AS VARCHAR) AS a,
    'b_' + CAST(t1.k / 2 AS VARCHAR) AS b
INTO dbo.t1
FROM (
    SELECT ROW_NUMBER() OVER (ORDER BY a.object_id) AS k
    FROM sys.all_columns, sys.all_columns a
) t1
WHERE t1.k < 98949;

-- RESET TARGET TABLE
TRUNCATE TABLE dbo.t2;

-- VERIFY ROW COUNTS
SELECT COUNT(*) AS t1_COUNT FROM dbo.t1;
SELECT COUNT(*) AS t2_COUNT FROM dbo.t2;

-- INSERT WITH TABLOCK (EXPECTED SERIAL EXECUTION)
INSERT INTO dbo.t2 WITH (TABLOCK) (id, a, b) 
SELECT * FROM dbo.t1;

--------------------------------------------------------
-- TEST 3: PARALLELISM ENABLED WHEN THRESHOLD IS REACHED
--------------------------------------------------------

DROP TABLE IF EXISTS dbo.t1;
GO

-- CREATE AND POPULATE t1 WITH 98,950 ROWS
SELECT 
    t1.k AS id,
    'a_' + CAST(t1.k AS VARCHAR) AS a,
    'b_' + CAST(t1.k / 2 AS VARCHAR) AS b
INTO dbo.t1
FROM (
    SELECT ROW_NUMBER() OVER (ORDER BY a.object_id) AS k
    FROM sys.all_columns, sys.all_columns a
) t1
WHERE t1.k < 98950;

-- RESET TARGET TABLE
TRUNCATE TABLE dbo.t2;

-- VERIFY ROW COUNTS
SELECT COUNT(*) AS t1_COUNT FROM dbo.t1;
SELECT COUNT(*) AS t2_COUNT FROM dbo.t2;

-- INSERT WITH TABLOCK (EXPECTED PARALLEL EXECUTION)
INSERT INTO dbo.t2 WITH (TABLOCK) (id, a, b) 
SELECT * FROM dbo.t1;

--------------------------------------------------------
-- TEST 4: REGULAR INSERT (STAYS SERIAL DESPITE HIGH SUBTREE COST)
--------------------------------------------------------

INSERT INTO dbo.t2 (id, a, b) 
SELECT * FROM dbo.t1;

--------------------------------------------------------
-- TAKEAWAY:
-- - PARALLELISM IS ENABLED FOR TABLOCK HINT ONLY WHEN THE SUBTREE COST
--   EXCEEDS THE COST THRESHOLD OF PARALLELISM (CTP).
--------------------------------------------------------

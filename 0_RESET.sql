
USE [DBATEST]
GO

CHECKPOINT

--SHRINK LOGFILE
DBCC SHRINKFILE (N'DBATEST_log' , 1)
GO

--LOGSPACE INFO FOR DBATEST
DECLARE @LogSpace TABLE (
	DatabaseName VARCHAR(255)
	,[Log Size (MB)] FLOAT
	,[Log Space Used (%)] FLOAT
	,[Status] INT
	)
INSERT INTO @LogSpace
EXECUTE ('dbcc sqlperf(''LogSpace'')')
SELECT *
FROM @LogSpace
WHERE DatabaseName = 'DBATEST'

IF OBJECT_ID('dbo.t2', 'U') IS NOT NULL
--AND OBJECT_ID('dbo.t1', 'U') IS NOT NULL
--TRUNCATE TABLE dbo.t1;
TRUNCATE TABLE dbo.t2;

/*
GET SOURCE TABLE dbo.t1 SETUP. 
THIS SCRIPT CREATES TABLE dbo.t1 AND INSERTS 1 MILLION RECORDS FROM sys.columns
https://dba.stackexchange.com/questions/130392/generate-and-insert-1-million-rows-into-simple-table 
*/

USE DBATEST
GO
DROP TABLE IF EXISTS dbo.t1
GO

SELECT t1.k AS id
	,'a_' + cast(t1.k AS VARCHAR) AS a
	,'b_' + cast(t1.k / 2 AS VARCHAR) AS b
INTO t1
FROM (
	SELECT ROW_NUMBER() OVER (
			ORDER BY a.object_id
			) AS k
	FROM sys.all_columns
		,sys.all_columns a
	) t1
WHERE t1.k < 1000001 --Modify record count insertion as needed

/*
THIS SCRIPT CREATES TARGET TABLE t2, SAME STRUCTURE AS t1.
*/
USE DBATEST
GO
DROP TABLE IF EXISTS dbo.t2
GO
CREATE TABLE [dbo].[t2](
	[id] [bigint] NULL,
	[a] [varchar](32) NULL,
	[b] [varchar](32) NULL
) ON [PRIMARY]
GO

ALTER DATABASE DBATEST SET RECOVERY SIMPLE;

CHECKPOINT

--SHRINK LOGFILE
DBCC SHRINKFILE (N'DBATEST_log' , 1)
GO

CHECKPOINT

--SHRINK LOGFILE
DBCC SHRINKFILE (N'DBATEST_log' , 1)
GO

DECLARE @LogSpace TABLE (
	DatabaseName VARCHAR(255)
	,[Log Size (MB)] FLOAT
	,[Log Space Used (%)] FLOAT
	,[Status] INT
	)
INSERT INTO @LogSpace
EXECUTE ('dbcc sqlperf(''LogSpace'')')
SELECT *
FROM @LogSpace
WHERE DatabaseName = 'DBATEST'
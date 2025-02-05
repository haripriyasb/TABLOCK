

/*
Test Locks in Regular Insert 
vs.
Insert with TABLOCK Hint
*/

USE DBATEST;
GO

DROP TABLE IF EXISTS dbo.TestLock;
GO

CREATE TABLE dbo.TestLock (
    id INT IDENTITY(1,1) PRIMARY KEY,
    data VARCHAR(100)
);
GO


-- Load table with initial data
INSERT INTO dbo.TestLock (data)
SELECT TOP 2000 'TestData'
FROM master.dbo.spt_values;
GO


--Verify existing locks
SELECT request_session_id
	,resource_type, resource_subtype
	,resource_description
	,request_type
	,request_mode
	,request_status
FROM sys.dm_tran_locks
WHERE request_session_id IN (66)


--Insert data without hint and do not commit
BEGIN TRAN;
INSERT INTO dbo.TestLock (data)
SELECT TOP 2000 'TestData'
FROM master.dbo.spt_values;
GO


--Check acquired locks 
SELECT request_session_id
	,resource_type, resource_subtype
	,resource_description
	,request_type
	,request_mode
	,request_status
FROM sys.dm_tran_locks
WHERE request_session_id = @@SPID



ROLLBACK



--Insert data with hint and do not commit
BEGIN TRAN;
INSERT INTO dbo.TestLock WITH (TABLOCK) (data)
SELECT TOP 10000 'TestData'
FROM master.dbo.spt_values;
GO


--Check acquired locks 
SELECT request_session_id
	,resource_type, resource_subtype
	,resource_description
	,request_type
	,request_mode
	,request_status
FROM sys.dm_tran_locks
WHERE request_session_id IN (69)


ROLLBACK


/*
TAKEAWAY

REGULAR INSERT
** Row-level (RID or KEY) or page-level (PAG) locks.
** Granular locking, allowing other transactions to access different parts of the table.
** May escalate to table level lock, if lock escalation threshold is reached.

INSERT WITH TABLOCK HINT
** Table-level lock (TAB)
** Blocks other queries
** No lock escalation

*/

# Load Data Faster into SQL Server Tables with TABLOCK

Demo scripts and slides from my session **Load Data Faster into SQL Server Tables**, focused on the `TABLOCK` table hint.

`INSERT ... SELECT` with `WITH (TABLOCK)` can be minimally logged and can run in parallel, which makes large loads much faster. It also takes a table-level lock, so it isn't right for every workload. These demos measure the difference and show when the hint helps and when it doesn't.

## What the demo shows

- A regular `INSERT ... SELECT` compared with `INSERT WITH (TABLOCK)` on a heap table (time, I/O and log usage)
- How the recovery model (Simple vs Full) affects minimal logging
- How clustered, nonclustered and columnstore indexes change the results
- `TABLOCK` with temp tables
- When parallel inserts kick in
- The locking difference between a regular insert and a `TABLOCK` insert

## Requirements

- SQL Server 2016 or later on a test instance
- A test database named `DBATEST`

## Run the demo

| Step | Script | What it does |
|---|---|---|
| 0 | `0_RESET.sql` | Checkpoints and shrinks the log so each test starts clean |
| 1 | `1_RunInsert_WithoutHint.sql` | Baseline insert without the hint |
| 2 | `2_WithHint_HeapTable.sql` | Insert with `TABLOCK` into a heap |
| 3 | `3_WithHint_FullRecoveryModel.sql` | Same test under the Full recovery model |
| 4 | `4_WithHint_Indexes.sql` | Tests clustered, nonclustered and columnstore indexes |
| 5 | `5_TempTables_Insert.sql` | Temp table inserts with and without `TABLOCK` |
| 6 | `6_Parallelism.sql` | Shows when the insert runs in parallel |
| 7 | `7_TestLocks.sql` | Compares the locks taken by each approach |

Run `0_RESET.sql` between tests for comparable numbers.

## When not to use TABLOCK

It blocks other writers for the duration of the load. Avoid it when concurrency matters or on busy, highly volatile tables.

## Files

- `*.sql`: demo scripts, run in numbered order
- `Load Data Faster.pptx`: session slides
- An expanded version of this session, which adds `SELECT INTO` and dbatools, is in [LoadDataFaster](https://github.com/haripriyasb/LoadDataFaster)

## Learn more

- Blog: [INSERT with TABLOCK hint](https://gohigh.substack.com/p/insert-with-tablock-hint-faster)
- [Prerequisites for minimal logging in bulk import (Microsoft Learn)](https://learn.microsoft.com/en-us/sql/relational-databases/import-export/prerequisites-for-minimal-logging-in-bulk-import)

> These scripts change the recovery model and shrink the log file. Run them only on a test instance.

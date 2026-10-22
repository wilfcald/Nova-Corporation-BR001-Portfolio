-- =============================================================================
-- NOVA CORPORATION | BR001 — EXECUTIVE PERFORMANCE REVIEW
-- 02 | SOURCE RECONCILIATION
-- =============================================================================
--
-- DOCUMENT CONTROL
--   Project          : Nova Corporation | BR001
--   Workflow stage   : Reconciliation
--   Script           : 02_source_reconciliation.sql
--   Database         : nova_analytics_warehouse.db (SQLite)
--   Access           : READ ONLY
--   Analysis scope   : H1 2025 vs. H1 2026
--   Master DQ record : Nova_BR001_Data_Quality_Workbook.xlsx
--
-- PURPOSE
--   Compare released warehouse sources with expected delivery controls.
--
-- CONTROL PRINCIPLE
--   A reconciliation PASS applies only to the specific control; it does not certify data quality.
--
-- TRACEABILITY & GOVERNANCE
--   1. SQL produces reproducible technical evidence; it does not approve findings.
--   2. Record applicable DQ IDs, findings, outcomes and decisions in the Excel
--      master workbook; do not treat comments or query outputs as final sign-off.
--   3. Keep source tables unchanged; no cleaning or remediation in these scripts.
--   4. Execute each SELECT/PRAGMA section independently in its numbered order.
--   5. Reconciliation/extraction validation and DQ approval are separate gates.
--
-- RELATED WORKFLOW
--   01 Discovery -> 02 Reconciliation -> 03 Extraction -> 04 Validation
--   -> Data Quality investigation -> Clarification -> Remediation decisions
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. REQUIRED SOURCE OBJECTS
-- Confirm that all business tables required for BR001 exist.
-- -----------------------------------------------------------------------------

SELECT name AS table_name
FROM sqlite_master
WHERE type = 'table'
  AND name IN (
      'fact_sales',
      'dim_customer',
      'dim_product',
      'dim_channel',
      'dim_region',
      'dim_date',
      'fact_sales_targets'
  )
ORDER BY name;
-- -----------------------------------------------------------------------------
-- 2. SOURCE ROW COUNT RECONCILIATION
-- Compare released warehouse populations against expected
-- delivery controls.
-- -----------------------------------------------------------------------------

SELECT
    'fact_sales' AS table_name,
    23530 AS expected_row_count,
    COUNT(*) AS actual_row_count,
    COUNT(*) - 23530 AS difference,
    CASE
        WHEN COUNT(*) = 23530 THEN 'PASS'
        ELSE 'REVIEW'
    END AS reconciliation_status
FROM fact_sales

UNION ALL

SELECT
    'dim_customer',
    2500,
    COUNT(*),
    COUNT(*) - 2500,
    CASE
        WHEN COUNT(*) = 2500 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM dim_customer

UNION ALL

SELECT
    'dim_product',
    180,
    COUNT(*),
    COUNT(*) - 180,
    CASE
        WHEN COUNT(*) = 180 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM dim_product

UNION ALL

SELECT
    'dim_channel',
    5,
    COUNT(*),
    COUNT(*) - 5,
    CASE
        WHEN COUNT(*) = 5 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM dim_channel

UNION ALL

SELECT
    'dim_region',
    8,
    COUNT(*),
    COUNT(*) - 8,
    CASE
        WHEN COUNT(*) = 8 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM dim_region

UNION ALL

SELECT
    'dim_date',
    546,
    COUNT(*),
    COUNT(*) - 546,
    CASE
        WHEN COUNT(*) = 546 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM dim_date

UNION ALL

SELECT
    'fact_sales_targets',
    60,
    COUNT(*),
    COUNT(*) - 60,
    CASE
        WHEN COUNT(*) = 60 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM fact_sales_targets;
-- -----------------------------------------------------------------------------
-- 3. SOURCE SCHEMA RECONCILIATION
-- Compare actual column counts with expected table structures.
-- -----------------------------------------------------------------------------

SELECT
    'fact_sales' AS table_name,
    18 AS expected_column_count,
    COUNT(*) AS actual_column_count,
    COUNT(*) - 18 AS difference,
    CASE
        WHEN COUNT(*) = 18 THEN 'PASS'
        ELSE 'REVIEW'
    END AS reconciliation_status
FROM pragma_table_info('fact_sales')

UNION ALL

SELECT
    'dim_customer',
    8,
    COUNT(*),
    COUNT(*) - 8,
    CASE
        WHEN COUNT(*) = 8 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM pragma_table_info('dim_customer')

UNION ALL

SELECT
    'dim_product',
    9,
    COUNT(*),
    COUNT(*) - 9,
    CASE
        WHEN COUNT(*) = 9 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM pragma_table_info('dim_product')

UNION ALL

SELECT
    'dim_channel',
    4,
    COUNT(*),
    COUNT(*) - 4,
    CASE
        WHEN COUNT(*) = 4 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM pragma_table_info('dim_channel')

UNION ALL

SELECT
    'dim_region',
    5,
    COUNT(*),
    COUNT(*) - 5,
    CASE
        WHEN COUNT(*) = 5 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM pragma_table_info('dim_region')

UNION ALL

SELECT
    'dim_date',
    12,
    COUNT(*),
    COUNT(*) - 12,
    CASE
        WHEN COUNT(*) = 12 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM pragma_table_info('dim_date')

UNION ALL

SELECT
    'fact_sales_targets',
    6,
    COUNT(*),
    COUNT(*) - 6,
    CASE
        WHEN COUNT(*) = 6 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM pragma_table_info('fact_sales_targets');
-- -----------------------------------------------------------------------------
-- 4. SALES SOURCE DATE COVERAGE
-- -----------------------------------------------------------------------------

SELECT
    MIN(order_date) AS earliest_order_date,
    MAX(order_date) AS latest_order_date,
    COUNT(*) AS total_sales_rows
FROM fact_sales;
-- -----------------------------------------------------------------------------
-- 5. BR001 PERIOD COVERAGE
-- Confirm population availability for both comparison periods.
-- -----------------------------------------------------------------------------

SELECT
    CASE
        WHEN order_date BETWEEN '2025-01-01' AND '2025-06-30'
            THEN 'H1 2025'
        WHEN order_date BETWEEN '2026-01-01' AND '2026-06-30'
            THEN 'H1 2026'
    END AS analysis_period,
    COUNT(*) AS row_count,
    COUNT(DISTINCT order_id) AS distinct_order_count
FROM fact_sales
WHERE
       order_date BETWEEN '2025-01-01' AND '2025-06-30'
    OR order_date BETWEEN '2026-01-01' AND '2026-06-30'
GROUP BY analysis_period
ORDER BY analysis_period;
-- -----------------------------------------------------------------------------
-- 6. SALES TARGET PERIOD COVERAGE
-- -----------------------------------------------------------------------------

SELECT
    MIN(target_month) AS earliest_target_month,
    MAX(target_month) AS latest_target_month,
    COUNT(DISTINCT target_month) AS distinct_target_months,
    COUNT(*) AS total_target_rows
FROM fact_sales_targets;
-- -----------------------------------------------------------------------------
-- 7. SALES TARGET MONTHLY COVERAGE
-- -----------------------------------------------------------------------------

SELECT
    target_month,
    COUNT(*) AS target_row_count,
    COUNT(DISTINCT channel_id) AS distinct_channels
FROM fact_sales_targets
GROUP BY target_month
ORDER BY target_month;
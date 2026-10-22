-- =============================================================================
-- NOVA CORPORATION | BR001 — EXECUTIVE PERFORMANCE REVIEW
-- 04 | EXTRACTION VALIDATION
-- =============================================================================
--
-- DOCUMENT CONTROL
--   Project          : Nova Corporation | BR001
--   Workflow stage   : Validation
--   Script           : 04_extraction_validation.sql
--   Database         : nova_analytics_warehouse.db (SQLite)
--   Access           : READ ONLY
--   Analysis scope   : H1 2025 vs. H1 2026
--   Master DQ record : Nova_BR001_Data_Quality_Workbook.xlsx
--
-- PURPOSE
--   Verify analytical scope, row counts, date boundaries and financial measure preservation.
--
-- CONTROL PRINCIPLE
--   DQ009 orphan-key checks are supplementary technical evidence, not a substitute for the master DQ register.
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
-- 1. SOURCE POPULATION BY ANALYSIS PERIOD
-- -----------------------------------------------------------------------------

SELECT
    CASE
        WHEN order_date BETWEEN '2025-01-01' AND '2025-06-30'
            THEN 'H1 2025'
        WHEN order_date BETWEEN '2026-01-01' AND '2026-06-30'
            THEN 'H1 2026'
    END AS analysis_period,
    COUNT(*) AS source_row_count
FROM fact_sales
WHERE
       order_date BETWEEN '2025-01-01' AND '2025-06-30'
    OR order_date BETWEEN '2026-01-01' AND '2026-06-30'
GROUP BY analysis_period
ORDER BY analysis_period;
-- -----------------------------------------------------------------------------
-- 2. EXPECTED BR001 SOURCE POPULATION
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS expected_br001_row_count
FROM fact_sales
WHERE
       order_date BETWEEN '2025-01-01' AND '2025-06-30'
    OR order_date BETWEEN '2026-01-01' AND '2026-06-30';
-- -----------------------------------------------------------------------------
-- 3. JOINED EXTRACTION ROW COUNT
-- Confirm that dimensional enrichment does not multiply or
-- remove source rows.
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS extracted_row_count
FROM fact_sales

LEFT JOIN dim_customer
    ON fact_sales.customer_id = dim_customer.customer_id

LEFT JOIN dim_product
    ON fact_sales.product_id = dim_product.product_id

LEFT JOIN dim_channel
    ON fact_sales.channel_id = dim_channel.channel_id

LEFT JOIN dim_region
    ON fact_sales.region_id = dim_region.region_id

LEFT JOIN dim_date
    ON fact_sales.order_date = dim_date.full_date

WHERE
       fact_sales.order_date BETWEEN '2025-01-01' AND '2025-06-30'
    OR fact_sales.order_date BETWEEN '2026-01-01' AND '2026-06-30';
-- -----------------------------------------------------------------------------
-- 4. EXTRACTION DATE RANGE
-- -----------------------------------------------------------------------------

SELECT
    MIN(order_date) AS earliest_extracted_date,
    MAX(order_date) AS latest_extracted_date
FROM fact_sales
WHERE
       order_date BETWEEN '2025-01-01' AND '2025-06-30'
    OR order_date BETWEEN '2026-01-01' AND '2026-06-30';
-- -----------------------------------------------------------------------------
-- 5. SOURCE FINANCIAL CONTROL TOTALS
-- -----------------------------------------------------------------------------

SELECT
    ROUND(SUM(gross_revenue), 2) AS source_gross_revenue,
    ROUND(SUM(discount_amount), 2) AS source_discount_amount,
    ROUND(SUM(net_revenue), 2) AS source_net_revenue,
    ROUND(SUM(total_cost), 2) AS source_total_cost,
    ROUND(SUM(gross_profit), 2) AS source_gross_profit
FROM fact_sales
WHERE
       order_date BETWEEN '2025-01-01' AND '2025-06-30'
    OR order_date BETWEEN '2026-01-01' AND '2026-06-30';
-- -----------------------------------------------------------------------------
-- 6. EXTRACTED FINANCIAL CONTROL TOTALS
-- Confirm that dimensional joins preserve source measures.
-- -----------------------------------------------------------------------------

SELECT
    ROUND(SUM(fact_sales.gross_revenue), 2)
        AS extracted_gross_revenue,
    ROUND(SUM(fact_sales.discount_amount), 2)
        AS extracted_discount_amount,
    ROUND(SUM(fact_sales.net_revenue), 2)
        AS extracted_net_revenue,
    ROUND(SUM(fact_sales.total_cost), 2)
        AS extracted_total_cost,
    ROUND(SUM(fact_sales.gross_profit), 2)
        AS extracted_gross_profit
FROM fact_sales

LEFT JOIN dim_customer
    ON fact_sales.customer_id = dim_customer.customer_id

LEFT JOIN dim_product
    ON fact_sales.product_id = dim_product.product_id

LEFT JOIN dim_channel
    ON fact_sales.channel_id = dim_channel.channel_id

LEFT JOIN dim_region
    ON fact_sales.region_id = dim_region.region_id

LEFT JOIN dim_date
    ON fact_sales.order_date = dim_date.full_date

WHERE
       fact_sales.order_date BETWEEN '2025-01-01' AND '2025-06-30'
    OR fact_sales.order_date BETWEEN '2026-01-01' AND '2026-06-30';
-- =============================================================================
-- 7. DQ009 - REFERENTIAL INTEGRITY VALIDATION
-- Workbook reference: DQ009 (master status and findings live in Excel).
-- Supplementary warehouse-level Data Quality control.
-- Checks orphan foreign keys in the BR001 analytical scope.
-- =============================================================================
-- Customer reference
SELECT
    COUNT(*) AS orphan_customer_rows
FROM fact_sales AS f
LEFT JOIN dim_customer AS c
    ON f.customer_id = c.customer_id
WHERE (
        f.order_date BETWEEN '2025-01-01' AND '2025-06-30'
        OR
        f.order_date BETWEEN '2026-01-01' AND '2026-06-30'
      )
  AND f.customer_id IS NOT NULL
  AND c.customer_id IS NULL;
-- Product reference
SELECT
    COUNT(*) AS orphan_product_rows
FROM fact_sales AS f
LEFT JOIN dim_product AS p
    ON f.product_id = p.product_id
WHERE (
        f.order_date BETWEEN '2025-01-01' AND '2025-06-30'
        OR f.order_date BETWEEN '2026-01-01' AND '2026-06-30'
      )
  AND f.product_id IS NOT NULL
  AND p.product_id IS NULL;
-- Channel reference
SELECT
    COUNT(*) AS orphan_channel_rows
FROM fact_sales AS f
LEFT JOIN dim_channel AS c
    ON f.channel_id = c.channel_id
WHERE (
        f.order_date BETWEEN '2025-01-01' AND '2025-06-30'
        OR f.order_date BETWEEN '2026-01-01' AND '2026-06-30'
      )
  AND f.channel_id IS NOT NULL
  AND c.channel_id IS NULL;
-- Region reference
SELECT
    COUNT(*) AS orphan_region_rows
FROM fact_sales AS f
LEFT JOIN dim_region AS r
    ON f.region_id = r.region_id
WHERE (
        f.order_date BETWEEN '2025-01-01' AND '2025-06-30'
        OR f.order_date BETWEEN '2026-01-01' AND '2026-06-30'
      )
  AND f.region_id IS NOT NULL
  AND r.region_id IS NULL;
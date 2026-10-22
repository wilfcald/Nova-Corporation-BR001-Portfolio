-- =============================================================================
-- NOVA CORPORATION | BR001 — EXECUTIVE PERFORMANCE REVIEW
-- 01 | SOURCE DISCOVERY
-- =============================================================================
--
-- DOCUMENT CONTROL
--   Project          : Nova Corporation | BR001
--   Workflow stage   : Discovery
--   Script           : 01_source_discovery.sql
--   Database         : nova_analytics_warehouse.db (SQLite)
--   Access           : READ ONLY
--   Analysis scope   : H1 2025 vs. H1 2026
--   Master DQ record : Nova_BR001_Data_Quality_Workbook.xlsx
--
-- PURPOSE
--   Identify source objects, schemas, sample records, relationships and date coverage.
--
-- CONTROL PRINCIPLE
--   Warehouse inventory and source understanding; not a Data Quality PASS.
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
-- 1. AVAILABLE WAREHOUSE TABLES
-- Identify the tables available in the analytical warehouse.
-- -----------------------------------------------------------------------------

SELECT name AS table_name
FROM sqlite_master
WHERE type = 'table'
ORDER BY name;
-- -----------------------------------------------------------------------------
-- 2. FACT SALES - SAMPLE
-- Inspect the primary transactional fact table.
-- Expected grain: one product line within one customer order.
-- -----------------------------------------------------------------------------

SELECT *
FROM fact_sales
LIMIT 10;
-- -----------------------------------------------------------------------------
-- 3. FACT SALES - SCHEMA
-- Review columns and SQLite-declared data types.
-- -----------------------------------------------------------------------------

PRAGMA table_info(fact_sales);
-- -----------------------------------------------------------------------------
-- 4. CUSTOMER DIMENSION
-- Inspect customer attributes and validate the expected
-- relationship to fact_sales.
-- -----------------------------------------------------------------------------

SELECT *
FROM dim_customer
LIMIT 10;

PRAGMA table_info(dim_customer);

SELECT
    fact_sales.customer_id,
    dim_customer.customer_name,
    dim_customer.customer_segment
FROM fact_sales
INNER JOIN dim_customer
    ON fact_sales.customer_id = dim_customer.customer_id
LIMIT 10;
-- -----------------------------------------------------------------------------
-- 5. PRODUCT DIMENSION
-- -----------------------------------------------------------------------------

SELECT *
FROM dim_product
LIMIT 10;

PRAGMA table_info(dim_product);

SELECT
    fact_sales.product_id,
    dim_product.product_name,
    dim_product.category
FROM fact_sales
INNER JOIN dim_product
    ON fact_sales.product_id = dim_product.product_id
LIMIT 10;
-- -----------------------------------------------------------------------------
-- 6. CHANNEL DIMENSION
-- -----------------------------------------------------------------------------

SELECT *
FROM dim_channel
LIMIT 10;

PRAGMA table_info(dim_channel);

SELECT
    fact_sales.channel_id,
    dim_channel.channel_name,
    dim_channel.channel_group
FROM fact_sales
INNER JOIN dim_channel
    ON fact_sales.channel_id = dim_channel.channel_id
LIMIT 10;
-- -----------------------------------------------------------------------------
-- 7. REGION DIMENSION
-- -----------------------------------------------------------------------------

SELECT *
FROM dim_region
LIMIT 10;

PRAGMA table_info(dim_region);

SELECT
    fact_sales.region_id,
    dim_region.country,
    dim_region.region_name,
    dim_region.market_tier
FROM fact_sales
INNER JOIN dim_region
    ON fact_sales.region_id = dim_region.region_id
LIMIT 10;
-- -----------------------------------------------------------------------------
-- 8. DATE DIMENSION
-- Validate the relationship between transaction dates and
-- the enterprise calendar dimension.
-- -----------------------------------------------------------------------------

SELECT *
FROM dim_date
LIMIT 10;

PRAGMA table_info(dim_date);

SELECT
    fact_sales.order_date,
    dim_date.year,
    dim_date.quarter,
    dim_date.month_name,
    dim_date.half_year
FROM fact_sales
INNER JOIN dim_date
    ON fact_sales.order_date = dim_date.full_date
LIMIT 10;
-- -----------------------------------------------------------------------------
-- 9. SALES TARGETS
-- Inspect the target fact table and recognize its different
-- grain from transactional sales.
-- -----------------------------------------------------------------------------

SELECT *
FROM fact_sales_targets
LIMIT 10;

PRAGMA table_info(fact_sales_targets);

SELECT
    fact_sales_targets.target_month,
    fact_sales_targets.channel_id,
    dim_channel.channel_name,
    fact_sales_targets.net_revenue_target,
    fact_sales_targets.gross_profit_target
FROM fact_sales_targets
INNER JOIN dim_channel
    ON fact_sales_targets.channel_id = dim_channel.channel_id
LIMIT 10;
-- -----------------------------------------------------------------------------
-- 10. SOURCE DATE COVERAGE
-- Establish the observed sales date boundaries.
-- -----------------------------------------------------------------------------

SELECT
    MIN(order_date) AS earliest_order_date,
    MAX(order_date) AS latest_order_date
FROM fact_sales;
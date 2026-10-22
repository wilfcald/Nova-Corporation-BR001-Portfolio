

/*
================================================================
NOVA CORPORATION | BR001
DATA QUALITY — ORDER & SALES LINE INTEGRITY
================================================================

PROJECT INFORMATION
----------------------------------------------------------------
Business Request : BR001 — Executive Performance Review
Phase            : Data Quality Investigation
Script           : BR001_DQ_Order_Integrity.sql
Database         : nova_analytics_warehouse.db
Source Table     : fact_sales
Execution Mode   : READ ONLY

MASTER DOCUMENTATION
----------------------------------------------------------------
Master Register  : Nova_BR001_Data_Quality_Workbook.xlsx
Related Records  : CL-001 / CL-004 / DQ005

PURPOSE
----------------------------------------------------------------
Investigate order identifier consistency, duplicated sales-line
identifiers, and potential business-key limitations.

Determine the population and financial exposure associated
with the identified anomalies.

METHODOLOGY
----------------------------------------------------------------
01. Establish the source population baseline.
02. Evaluate order identifier consistency.
03. Quantify financial exposure.
04. Identify duplicated sales-line identifiers.
05. Inspect affected source records.
06. Review available source metadata.
07. Evaluate order identifier reuse across years.
08. Assess potential identifier scopes.
09. Compare candidate composite order keys.

GOVERNANCE
----------------------------------------------------------------
- The source warehouse must remain unchanged.
- All queries are investigative and read-only.
- Technical findings must be reconciled with the master workbook.
- A detected anomaly does not automatically justify remediation.
- Candidate business keys are hypotheses, not approved rules.
- Clarification decisions must be documented before remediation.

IMPORTANT NOTES
----------------------------------------------------------------
- COUNT(DISTINCT column) excludes NULL values in SQLite.
- Financial exposure represents recorded amounts associated
  with affected records, not confirmed financial losses.
- Source metadata queries require the corresponding catalog
  tables to exist in the connected database.

================================================================
*/


-- ==============================================================
-- 01 | DATASET BASELINE
-- ==============================================================
-- Objective:
-- Establish the source population and identifier counts.
--
-- Source:
-- fact_sales
--
-- Master reference:
-- CL-001 / CL-004 / DQ005
-- ==============================================================

SELECT
    COUNT(*) AS total_sales_lines,
    COUNT(DISTINCT order_id) AS distinct_order_ids,
    COUNT(DISTINCT sales_line_id) AS distinct_sales_line_ids
FROM fact_sales;


-- ==============================================================
-- 02 | ORDER IDENTIFIER CONSISTENCY
-- ==============================================================
-- Evidence ID : CL001-SQL-01
-- Reference   : CL-001
--
-- Objective:
-- Quantify order identifiers associated with multiple
-- customers and/or multiple transaction dates.
--
-- Interpretation:
-- Conflicting identifiers require investigation before
-- determining whether they represent data-quality defects
-- or legitimate business-key behavior.
-- ==============================================================

WITH order_profile AS (
    SELECT
        order_id,
        COUNT(*) AS sales_lines,
        COUNT(DISTINCT customer_id) AS distinct_customers,
        COUNT(DISTINCT order_date) AS distinct_dates
    FROM fact_sales
    WHERE order_id IS NOT NULL
    GROUP BY order_id
)
SELECT
    COUNT(*) AS total_order_ids,

    SUM(
        CASE
            WHEN distinct_customers > 1
            THEN 1 ELSE 0
        END
    ) AS order_ids_multiple_customers,

    SUM(
        CASE
            WHEN distinct_dates > 1
            THEN 1 ELSE 0
        END
    ) AS order_ids_multiple_dates,

    SUM(
        CASE
            WHEN distinct_customers > 1
              OR distinct_dates > 1
            THEN 1 ELSE 0
        END
    ) AS order_ids_any_conflict,

    SUM(
        CASE
            WHEN distinct_customers > 1
             AND distinct_dates > 1
            THEN 1 ELSE 0
        END
    ) AS order_ids_both_conflicts

FROM order_profile;


-- ==============================================================
-- 03 | FINANCIAL EXPOSURE OF ORDER CONFLICTS
-- ==============================================================
-- Evidence ID : CL001-SQL-02
-- Reference   : CL-001
--
-- Objective:
-- Quantify the number of affected sales lines and the
-- recorded financial measures associated with conflicting
-- order identifiers.
--
-- Interpretation:
-- These amounts represent exposure within the affected
-- population, not confirmed financial losses.
-- ==============================================================

WITH conflicting_orders AS (
    SELECT
        order_id
    FROM fact_sales
    WHERE order_id IS NOT NULL
    GROUP BY order_id
    HAVING COUNT(DISTINCT customer_id) > 1
        OR COUNT(DISTINCT order_date) > 1
)
SELECT
    COUNT(*) AS affected_sales_lines,
    ROUND(SUM(net_revenue), 2) AS recorded_net_revenue,
    ROUND(SUM(gross_profit), 2) AS recorded_gross_profit
FROM fact_sales
WHERE order_id IN (
    SELECT order_id
    FROM conflicting_orders
);


-- ==============================================================
-- 04 | DUPLICATED SALES LINE IDENTIFIERS
-- ==============================================================
-- Evidence ID : CL004-SQL-01
-- Reference   : CL-004 / DQ005
--
-- Objective:
-- Identify sales_line_id values appearing more than once
-- in the source fact table.
--
-- Interpretation:
-- Repeated identifiers require record-level investigation
-- before classifying them as technical duplicates or
-- conflicting transactions.
-- ==============================================================

SELECT
    sales_line_id,
    COUNT(*) AS occurrence_count
FROM fact_sales
GROUP BY sales_line_id
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC, sales_line_id;


-- ==============================================================
-- 05 | DUPLICATED IDENTIFIER DETAILS
-- ==============================================================
-- Evidence ID : CL004-SQL-02
-- Reference   : CL-004 / DQ005
--
-- Objective:
-- Retrieve complete source records associated with
-- repeated sales_line_id values.
--
-- Investigation:
-- Compare transaction identifiers, customer information,
-- dates, commercial measures, and transaction attributes.
--
-- Governance:
-- No records are deleted or modified during investigation.
-- ==============================================================

SELECT *
FROM fact_sales
WHERE sales_line_id IN (
    SELECT sales_line_id
    FROM fact_sales
    GROUP BY sales_line_id
    HAVING COUNT(*) > 1
)
ORDER BY sales_line_id, order_id;


-- ==============================================================
-- 06 | SOURCE METADATA REVIEW
-- ==============================================================
-- Evidence ID : CL001-SQL-03
-- Reference   : CL-001
--
-- Objective:
-- Review available documentation describing fact_sales,
-- order_id, and sales_line_id.
--
-- Prerequisite:
-- The connected database must contain warehouse_catalog
-- and column_catalog.
--
-- Limitation:
-- If these objects are unavailable, metadata must be
-- obtained from the official Data Catalog or IRDS.
-- ==============================================================

SELECT *
FROM warehouse_catalog
WHERE object_name = 'fact_sales';


SELECT *
FROM column_catalog
WHERE object_name = 'fact_sales'
  AND column_name IN ('order_id', 'sales_line_id');


-- ==============================================================
-- 07 | ORDER IDENTIFIER REUSE ACROSS YEARS
-- ==============================================================
-- Evidence ID : CL001-SQL-04
-- Reference   : CL-001
--
-- Objective:
-- Determine whether order identifiers are reused across
-- reporting years.
--
-- Investigation:
-- Distinguish conflicts occurring across multiple years
-- from conflicts occurring within a single year.
--
-- Interpretation:
-- Cross-year reuse is a potential explanation for some
-- inconsistencies, but does not establish a valid key.
-- ==============================================================

WITH order_year_profile AS (
    SELECT
        order_id,
        COUNT(*) AS sales_lines,
        COUNT(DISTINCT strftime('%Y', order_date))
            AS distinct_years,
        COUNT(DISTINCT customer_id)
            AS distinct_customers,
        COUNT(DISTINCT order_date)
            AS distinct_dates
    FROM fact_sales
    WHERE order_id IS NOT NULL
    GROUP BY order_id
)
SELECT
    COUNT(*) AS total_order_ids,

    SUM(
        CASE
            WHEN distinct_years > 1
            THEN 1 ELSE 0
        END
    ) AS ids_across_multiple_years,

    SUM(
        CASE
            WHEN distinct_years > 1
             AND (
                 distinct_customers > 1
                 OR distinct_dates > 1
             )
            THEN 1 ELSE 0
        END
    ) AS conflicting_ids_across_years,

    SUM(
        CASE
            WHEN distinct_years = 1
             AND (
                 distinct_customers > 1
                 OR distinct_dates > 1
             )
            THEN 1 ELSE 0
        END
    ) AS conflicting_ids_within_one_year

FROM order_year_profile;


-- ==============================================================
-- 08 | ORDER IDENTIFIER SCOPE ASSESSMENT
-- ==============================================================
-- Evidence ID : CL001-SQL-05
-- Reference   : CL-001
--
-- Objective:
-- Evaluate whether order identifiers remain consistent
-- across customer, date, channel, and region attributes.
--
-- Method:
-- Profile distinct attribute values associated with each
-- non-null order_id.
--
-- Interpretation:
-- The results support business-key investigation.
-- They do not establish approved order semantics.
-- ==============================================================

WITH scope_profile AS (
    SELECT
        order_id,
        COUNT(*) AS sales_lines,
        COUNT(DISTINCT customer_id) AS customers,
        COUNT(DISTINCT order_date) AS dates,
        COUNT(DISTINCT channel_id) AS channels,
        COUNT(DISTINCT region_id) AS regions,
        COUNT(DISTINCT product_id) AS products
    FROM fact_sales
    WHERE order_id IS NOT NULL
    GROUP BY order_id
)
SELECT
    COUNT(*) AS total_order_ids,

    SUM(
        CASE WHEN customers > 1
        THEN 1 ELSE 0 END
    ) AS multiple_customers,

    SUM(
        CASE WHEN dates > 1
        THEN 1 ELSE 0 END
    ) AS multiple_dates,

    SUM(
        CASE WHEN channels > 1
        THEN 1 ELSE 0 END
    ) AS multiple_channels,

    SUM(
        CASE WHEN regions > 1
        THEN 1 ELSE 0 END
    ) AS multiple_regions,

    SUM(
        CASE WHEN products > 1
        THEN 1 ELSE 0 END
    ) AS multiple_products,

    SUM(
        CASE
            WHEN customers = 1
             AND dates = 1
             AND channels = 1
             AND regions = 1
            THEN 1 ELSE 0
        END
    ) AS fully_consistent_order_ids

FROM scope_profile;


-- ==============================================================
-- 09 | COMPOSITE ORDER KEY CANDIDATE ASSESSMENT
-- ==============================================================
-- Evidence ID : CL001-SQL-06
-- Reference   : CL-001
--
-- Objective:
-- Compare potential composite order identifier scopes
-- against customer and date consistency.
--
-- Candidate keys:
-- 01. order_id
-- 02. order_id + channel_id
-- 03. order_id + region_id
-- 04. order_id + channel_id + region_id
--
-- Evaluation:
-- Number of groups, conflicting groups, affected sales
-- lines, and percentage of conflicting groups.
--
-- Governance:
-- A lower conflict rate does not prove business validity.
-- Final key definitions require authoritative clarification.
-- ==============================================================

WITH candidate_groups AS (

    SELECT
        'order_id' AS candidate_key,
        order_id AS key_value,
        customer_id,
        order_date
    FROM fact_sales
    WHERE order_id IS NOT NULL

    UNION ALL

    SELECT
        'order_id + channel_id',
        order_id || '|' || COALESCE(channel_id, '<NULL>'),
        customer_id,
        order_date
    FROM fact_sales
    WHERE order_id IS NOT NULL

    UNION ALL

    SELECT
        'order_id + region_id',
        order_id || '|' || COALESCE(region_id, '<NULL>'),
        customer_id,
        order_date
    FROM fact_sales
    WHERE order_id IS NOT NULL

    UNION ALL

    SELECT
        'order_id + channel_id + region_id',
        order_id || '|' ||
            COALESCE(channel_id, '<NULL>') || '|' ||
            COALESCE(region_id, '<NULL>'),
        customer_id,
        order_date
    FROM fact_sales
    WHERE order_id IS NOT NULL

),
group_profile AS (
    SELECT
        candidate_key,
        key_value,
        COUNT(*) AS sales_lines,
        COUNT(DISTINCT customer_id) AS distinct_customers,
        COUNT(DISTINCT order_date) AS distinct_dates
    FROM candidate_groups
    GROUP BY candidate_key, key_value
)
SELECT
    candidate_key,
    COUNT(*) AS candidate_groups,

    SUM(
        CASE
            WHEN distinct_customers > 1
              OR distinct_dates > 1
            THEN 1 ELSE 0
        END
    ) AS conflicting_groups,

    SUM(
        CASE
            WHEN distinct_customers > 1
              OR distinct_dates > 1
            THEN sales_lines ELSE 0
        END
    ) AS affected_sales_lines,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN distinct_customers > 1
                  OR distinct_dates > 1
                THEN 1 ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS conflict_rate_pct

FROM group_profile
GROUP BY candidate_key
ORDER BY conflicting_groups DESC;




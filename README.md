# Nova Corporation | BR001 — Data Quality & Revalidation

**Corporate Data Analytics Simulation | SQL · Python · Excel · SQLite**

## Project Overview

Nova Corporation is a fictional omnichannel retail company. This project uses synthetic business data to demonstrate a structured, auditable data analytics workflow, from source extraction through data quality investigation, controlled cleaning, and post-cleaning revalidation.

The purpose of this repository is to demonstrate the technical process, documented business clarifications, data quality controls, and validation evidence produced before downstream business analysis.

**Project scope:** Source Discovery → Source Reconciliation → Data Extraction → Data Quality Investigation → Controlled Data Cleaning → Data Revalidation.

## Technical Workflow

| Stage | Activities | Evidence |
|---|---|---|
| Source Discovery | Inspect source tables, schemas, relationships, and available data | `03_sql/01_source_discovery.sql` |
| Source Reconciliation | Compare source structures and assess data consistency | `03_sql/02_source_reconciliation.sql` |
| Data Extraction | Build the analytical extract from the SQLite warehouse | `03_sql/03_br001_extraction.sql` |
| Extraction Validation | Validate the extracted population and source reconciliation | `03_sql/04_extraction_validation.sql` |
| Data Quality Investigation | Investigate data quality issues, including record identity, missing references, numeric validity, and order integrity | `05_analysis/python/data_quality/` |
| Controlled Data Cleaning | Apply documented treatments based on approved business clarifications | `05_analysis/python/cleaning/BR001_Data_Cleaning.ipynb` |
| Data Revalidation | Reassess the cleaned dataset and document validation outcomes | `05_analysis/python/cleaning/BR001_Data_Revalidation.ipynb` |

## Data Quality & Validation

The project includes 17 data quality controls (DQ001–DQ017), documented investigations, business clarification requests and responses, and controlled cleaning treatments (CR-001–CR-007).

The analytical dataset preserves 23,530 source records and introduces controlled eligibility and attribution fields to support downstream analysis without silently removing source records.

The validated reporting populations include:

- **21,342 certified sales lines**
- **22,417 provisional-inclusive sales lines**

These populations are not additive. Order-level KPIs remain restricted because unresolved order identity conflicts prevent reliable distinct-order calculations.

Data quality exceptions and unresolved limitations are documented rather than concealed.

## Featured Excel Deliverable

**Nova BR001 — Data Quality Workbook (Revalidated)**

[View or download the Data Quality Workbook](05_analysis/excel/Nova_BR001_Data_Quality_Workbook_Revalidated.xlsx)

This workbook is the primary documentation deliverable for the project's data quality and revalidation work. It complements the executable SQL and Python evidence by providing a structured record of investigations, controls, findings, and validation outcomes.

## Technical Evidence

**SQL**

[Source Discovery](03_sql/01_source_discovery.sql) · [Source Reconciliation](03_sql/02_source_reconciliation.sql) · [Data Extraction](03_sql/03_br001_extraction.sql) · [Extraction Validation](03_sql/04_extraction_validation.sql)

**Python / Jupyter**

[Data Quality Investigation](05_analysis/python/data_quality/BR001_Data_Quality_Investigation.ipynb) · [Outlier Review](05_analysis/python/data_quality/BR001_DQ013_Outlier_Review.ipynb) · [Controlled Cleaning](05_analysis/python/cleaning/BR001_Data_Cleaning.ipynb) · [Data Revalidation](05_analysis/python/cleaning/BR001_Data_Revalidation.ipynb)

**Business Documentation**

[Requirements and Business Clarifications](01_inbox/01_Official_Documents/)

## Tools

- SQL and SQLite — source inspection, extraction, and reconciliation
- Python and pandas — investigation, controlled cleaning, and revalidation
- Jupyter Notebook — executable analysis and validation evidence
- Microsoft Excel — data quality documentation and audit records
- Git and GitHub — version control and technical portfolio presentation

## Scope and Limitations

This repository presents work completed through the Data Revalidation stage.

Downstream descriptive analysis, diagnostic business analysis, executive recommendations, and Power BI reporting are not presented as completed deliverables.

Nova Corporation is fictional, and the dataset is synthetic. Business clarifications and stakeholder documentation form part of the simulated corporate project environment.

**The objective is to demonstrate a reproducible, transparent, and evidence-based approach to preparing business data for reliable analysis.**


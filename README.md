ر# Modern SQL Data Warehouse Implementation

## Project Overview
This project presents an end-to-end modern Data Warehouse implementation engineered from the ground up using SQL Server (T-SQL). The primary objective is to transform raw, fragmented transactional data from disparate source systems (CRM and ERP) into a clean, structured, and analytics-ready Data Warehouse[cite: 1, 5].

The architecture strict adherence to industry best practices, implementing a multi-layered Medallion Architecture alongside Dimensional Modeling (Star Schema) to support enterprise-level Business Intelligence (BI) and reporting requirements[cite: 1, 2, 3, 5].

---

## Architectural Design: Medallion Framework

The data pipeline transitions through three distinct logical layers to ensure data integrity, traceability, and optimal query performance[cite: 1, 2, 3, 5]:

### 1. Bronze Layer (Raw Staging)
* Objective: Ingests raw data directly from source systems without modifying the underlying schema or record contents[cite: 1].
* Characteristics: Preserves historical raw records for lineage auditing and troubleshooting[cite: 1].
* Ingestion Strategy: Automated full-truncation and bulk loading via stored procedures.

### 2. Silver Layer (Cleansing & Standardization)
* Objective: Cleanses, standardizes, and enriches data extracted from the Bronze layer[cite: 1].
* Key Transformations:
  * Trimming whitespaces and handling invalid or missing values.
  * Standardizing data types, date formats, and lookup codes across systems[cite: 1, 5].
  * Structural deduplication and enforcement of data integrity constraints.

### 3. Gold Layer (Business Analytics & Dimensional Modeling)
* Objective: Exposes business-ready data structured for analytical consumption[cite: 2, 3, 5].
* Modeling Approach: Implements a Star Schema composed of Fact and Dimension tables[cite: 2, 3, 5].
* Implementation Strategy: Modeled as database Views over the Silver layer to eliminate storage duplication, increase flexibility, and ensure real-time reporting accuracy[cite: 6].

---

## Technical Specifications & Engineering Standards

### Object Naming Conventions
To maintain maintainability across the warehouse, strict naming rules are applied:
* Case Convention: All database objects are written in snake_case[cite: 1].
* Source Tracking: Bronze and Silver objects maintain system prefixes (e.g., `crm_customer_info`)[cite: 1, 2].
* Dimensional Patterns: Gold entities are prefixed by role (`dim_` for Dimensions, `fact_` for Facts, `agg_` for Aggregations)[cite: 2, 3].
* Technical Columns: System metadata fields carry the `dwh_` prefix (e.g., `dwh_load_date`)[cite: 4].
* Keys: Dimension primary keys utilize surrogate keys with the `_key` suffix[cite: 4].

### Technology Stack
* Database Engine: Microsoft SQL Server / T-SQL
* Environment: SQL Server Management Studio (SSMS)
* Version Control: Git & GitHub[cite: 5]

---

## Repository Structure

```text
sql-data-warehouse-project/
│
├── datasets/             Raw CSV files from CRM and ERP systems
├── docs/                 Project documentation and naming standards
├── scripts/              SQL DDL and DML transformation scripts
│   ├── bronze/           DDL and loading procedures for Bronze layer
│   ├── silver/           Cleansing scripts and Silver procedures
│   └── gold/             Dimensional views for Gold layer
├── tests/                Data quality checks and validation queries
├── LICENSE               MIT License
└── README.md             Project documentation

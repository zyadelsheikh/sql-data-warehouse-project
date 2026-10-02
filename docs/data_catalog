# 📖 Data Catalog — Gold Layer (Analytical Star Schema)

## 📌 Overview
The **Gold Layer** serves as the consumption-ready, business-level data model structured using **Dimensional Modeling (Star Schema)**[cite: 1, 2]. It aggregates, integrates, and transforms cleansed data from the Silver Layer into optimized **Dimension** and **Fact** database views[cite: 1, 2]. 

This catalog details the schemas, surrogate keys, business attributes, and enterprise metrics available for Business Intelligence (BI), ad-hoc querying, and reporting.

---

## 🗂️ Table of Contents
1. [gold.dim_customers](#1-golddim_customers)
2. [gold.dim_products](#2-golddim_products)
3. [gold.fact_sales](#3-goldfact_sales)

---

### 1. `gold.dim_customers`
* **Type:** Dimension View
* **Purpose:** Contains enriched customer master data, consolidating profile attributes, demographics, and geographical details from both CRM and ERP source systems[cite: 1].

| Column Name | Data Type | Key Type | Description | Example / Allowed Values |
| :--- | :--- | :--- | :--- | :--- |
| `customer_key` | `INT` | **Surrogate Primary Key** | Unique integer surrogate key identifying each distinct customer dimension record. | `1001` |
| `customer_id` | `INT` | Business Key | Original primary identifier assigned to the customer in the CRM source system. | `28301` |
| `customer_number` | `NVARCHAR(50)` | Natural Key | Alphanumeric business code used across operations for tracking and reference. | `NAS00028301` |
| `first_name` | `NVARCHAR(50)` | Attribute | Customer's first name. | `John` |
| `last_name` | `NVARCHAR(50)` | Attribute | Customer's last or family name. | `Doe` |
| `country` | `NVARCHAR(50)` | Attribute | Customer's country of residence. | `Australia`, `United States` |
| `marital_status` | `NVARCHAR(50)` | Attribute | Standardized marital status. | `Married`, `Single`, `n/a` |
| `gender` | `NVARCHAR(50)` | Attribute | Standardized gender specification. | `Male`, `Female`, `n/a` |
| `birthdate` | `DATE` | Attribute | Customer's date of birth (`YYYY-MM-DD`). | `1985-04-12` |
| `create_date` | `DATE` | Metadata | System timestamp indicating when the customer account was first established. | `2021-01-15` |

---

### 2. `gold.dim_products`
* **Type:** Dimension View
* **Purpose:** Houses comprehensive master data for all catalog items, incorporating product hierarchies, line classifications, and cost structures[cite: 1].

| Column Name | Data Type | Key Type | Description | Example / Allowed Values |
| :--- | :--- | :--- | :--- | :--- |
| `product_key` | `INT` | **Surrogate Primary Key** | Unique integer surrogate key identifying each product record in the dimension. | `501` |
| `product_id` | `INT` | Business Key | Internal product identifier sourced from the ERP system. | `1204` |
| `product_number` | `NVARCHAR(50)` | Natural Key | Structured SKU/Alphanumeric inventory tracking code. | `BK-M18B-42` |
| `product_name` | `NVARCHAR(50)` | Attribute | Descriptive name of the item (includes variant, size, and color details). | `Mountain-100 Black, 42` |
| `category_id` | `NVARCHAR(50)` | Foreign Attribute | Unique category code linking to high-level product groupings. | `CAT-01` |
| `category` | `NVARCHAR(50)` | Hierarchy L1 | Top-level business categorization of the product. | `Bikes`, `Components`, `Accessories` |
| `subcategory` | `NVARCHAR(50)` | Hierarchy L2 | Granular sub-classification within the primary category. | `Mountain Bikes`, `Road Bikes` |
| `maintenance_required` | `NVARCHAR(50)` | Flag / Attribute | Indicates if the product unit requires routine maintenance servicing. | `Yes`, `No` |
| `cost` | `INT` | Attribute / Metric | Base manufacturing/acquisition cost per unit in standard currency units. | `500` |
| `product_line` | `NVARCHAR(50)` | Attribute | Brand series or target segment line. | `Mountain`, `Road`, `Touring` |
| `start_date` | `DATE` | Effective Date | The official release date when the product became active for commercial sale. | `2020-06-01` |

---

### 3. `gold.fact_sales`
* **Type:** Fact View
* **Purpose:** Captures core business transactional events, recording sales performance metrics, order quantities, and dimensional foreign key references[cite: 1].

| Column Name | Data Type | Key Type | Description | Example / Metric Type |
| :--- | :--- | :--- | :--- | :--- |
| `order_number` | `NVARCHAR(50)` | Degenerate Key | Unique transactional reference number identifying the purchase order. | `SO54496` |
| `product_key` | `INT` | **Foreign Key** | Surrogate key joining to `gold.dim_products.product_key`. | `501` |
| `customer_key` | `INT` | **Foreign Key** | Surrogate key joining to `gold.dim_customers.customer_key`. | `1001` |
| `order_date` | `DATE` | Date Dimension FK | Date when the purchase transaction was placed by the customer. | `2023-10-15` |
| `shipping_date` | `DATE` | Date Dimension FK | Date when the ordered line items were dispatched from fulfillment. | `2023-10-18` |
| `due_date` | `DATE` | Date Dimension FK | Target invoice settlement/payment due date. | `2023-10-27` |
| `sales_amount` | `INT` | Additive Fact | Total gross revenue generated for the order line item (`quantity * price`). | `2500` |
| `quantity` | `INT` | Additive Fact | Total volume of units purchased for the specific line item. | `2` |
| `price` | `INT` | Non-Additive Fact | Unit selling price of the item at the moment of order placement. | `1250` |

---

## 🔗 Entity Relationships Summary (Star Schema)

```text
 ┌──────────────────────┐              ┌──────────────────────┐
 │  gold.dim_customers  │              │  gold.dim_products   │
 ├──────────────────────┤              ├──────────────────────┤
 │ PK  customer_key     │◄───┐    ┌───►│ PK  product_key      │
 │     customer_id      │    │    │    │     product_id       │
 │     country          │    │    │    │     category         │
 └──────────────────────┘    │    │    └──────────────────────┘
                             │    │
                  ┌──────────┴────┴──────────┐
                  │     gold.fact_sales      │
                  ├──────────────────────────┤
                  │     order_number         │
                  │ FK  customer_key         │
                  │ FK  product_key          │
                  │     sales_amount         │
                  │     quantity             │
                  └──────────────────────────┘

# Data Quality Report

This document provides detailed information about data quality, missing values, and potential issues in the output tables created for the Engeto project.

## Primary Table: `t_adam_krejci_project_SQL_primary_final`

### Time Coverage
- **Period:** 2006-2018 (13 years)
- **Complete coverage:** All years present
- **No gaps:** Data available for all 13 consecutive years

### Data Completeness

#### Wages
**Complete data for all industries and years**

**Statistics:**
- **Industries:** 19 sectors
- **Years:** 13 (2006-2018)
- **Expected records (unique combinations):** 247 (19 industries × 13 years)
- **NULL values in `avg_wage`:** 0 (filtered in views)

**Verification query:**
```sql
SELECT 
    COUNT(DISTINCT industry_branch_code) AS industries,
    COUNT(DISTINCT year) AS years,
    MIN(year) AS first_year,
    MAX(year) AS last_year
FROM t_adam_krejci_project_SQL_primary_final;
```

**Note:** Wages are yearly averages.

#### Food Prices
**Complete data for all categories and years**

**Statistics:**
- **Food categories:** 27 categories
- **Years:** 13 (2006-2018)
- **Expected records (unique combinations):** ~325 (27 categories × 13 years)
- **NULL values in `avg_price`:** 0 (filtered in views)

**Verification query:**
```sql
SELECT 
    COUNT(DISTINCT category_code) AS categories,
    COUNT(DISTINCT year) AS years
FROM t_adam_krejci_project_SQL_primary_final;
```

**Note:** Prices are yearly averages aggregated from monthly data.

### Industry Sectors (19 total)

Complete list of industries included in the analysis:
```sql
SELECT DISTINCT 
    industry_branch_code,
    industry_branch_name 
FROM t_adam_krejci_project_SQL_primary_final 
ORDER BY industry_branch_code;
```


### Food Categories (27 total)

**Complete list query:**
```sql
SELECT DISTINCT 
    category_code,
    category_name,
    price_unit
FROM t_adam_krejci_project_SQL_primary_final 
ORDER BY category_code;
```

### Cartesian Product Structure

**Critical Note:** The primary table contains a **Cartesian product** of wages and prices:
```
Total records ≈ 35,000 rows
= 13 years × 19 industries × 30 food categories
```

**This means:**
- Each wage record is duplicated 27 times (once for each food category)
- Each price record is duplicated 19 times (once for each industry)

### NULL Value Filters

Both views (`v_payroll_clean` and `v_price_clean`) filter NULL values before creating the final table:
```sql
WHERE cp.value IS NOT NULL
  AND cp.payroll_year IS NOT NULL
```

**Result:** The primary table contains **0 NULL values** in key columns.

## Secondary Table: `t_adam_krejci_project_SQL_secondary_final`

### Time Coverage
- **Period:** 2006-2018 (13 years)
- **Countries:** 45 European countries
- **Total records:** 585 rows (45 countries × 13 years)

### European Countries Included

The table includes all countries classified as European in the `countries` table:

**Complete list query:**
```sql
SELECT DISTINCT country 
FROM t_adam_krejci_project_SQL_secondary_final 
ORDER BY country;
```

### Data Completeness by Indicator

#### GDP (Gross Domestic Product)
**Mostly complete**

**Missing data:**
- Some microstates may have incomplete GDP data
- Examples: Faroe Islands, Gibraltar, Liechtenstein

**For Czech Republic:** Complete GDP data for all years (2006-2018)

**Verification:**
```sql
SELECT 
    country,
    COUNT(*) AS total_years,
    SUM(CASE WHEN gdp IS NULL THEN 1 ELSE 0 END) AS missing_gdp
FROM t_adam_krejci_project_SQL_secondary_final
WHERE country = 'Czech Republic'
GROUP BY country;
```

#### GINI Coefficient
**Most incomplete indicator**

**Important:** GINI is **NOT measured every year**
- Not a data quality issue, but a measurement frequency limitation
  
**Missing data pattern:**
```sql
SELECT 
    year,
    COUNT(*) AS countries_with_gini,
    COUNT(*) - COUNT(gini) AS countries_missing_gini
FROM t_adam_krejci_project_SQL_secondary_final
GROUP BY year
ORDER BY year;
```

#### Population
**Complete**

**Verification:**
```sql
SELECT 
    COUNT(DISTINCT country) AS total_countries,
    SUM(CASE WHEN population IS NOT NULL THEN 1 ELSE 0 END) AS records_with_population,
    COUNT(*) AS total_records
FROM t_adam_krejci_project_SQL_secondary_final;
```

-- View payroll for Primary Table
CREATE VIEW v_payroll_clean AS 
SELECT
    cp.payroll_year AS year,
    cp.industry_branch_code,
    cpib.name AS industry_branch_name,
    AVG(cp.value) AS avg_wage
FROM czechia_payroll cp
JOIN czechia_payroll_industry_branch cpib
    ON cp.industry_branch_code = cpib.code
WHERE cp.value_type_code = 5958
    AND cp.value IS NOT NULL
    AND cp.payroll_year IS NOT NULL
GROUP BY 
    cp.payroll_year,
    cp.industry_branch_code,
    cpib.name
ORDER BY
    cp.payroll_year, 
    cp.industry_branch_code;

-- View prices for Primary Table
CREATE VIEW v_price_clean AS
WITH price_clean AS (
    SELECT
        cp.value,
        cp.category_code,
        cpc.name AS category_name,
        cpc.price_unit,
        EXTRACT(YEAR FROM cp.date_from) AS year
    FROM czechia_price cp
    JOIN czechia_price_category cpc
        ON cp.category_code = cpc.code
    WHERE cp.value IS NOT NULL
        AND cp.date_from IS NOT NULL
)
SELECT
    year,
    category_code,
    category_name,
    price_unit,
    AVG(value) AS avg_price
FROM price_clean
GROUP BY
    year,
    category_code,
    category_name,
    price_unit
ORDER BY
    year,
    category_code;

-- Primary Table
CREATE TABLE t_adam_krejci_project_SQL_primary_final AS
SELECT
    p.year,
    p.industry_branch_code,
    p.industry_branch_name,
    p.avg_wage,
    c.category_code,
    c.category_name,
    c.price_unit,
    c.avg_price
FROM v_payroll_clean p
JOIN v_price_clean c
    ON p.year = c.year
ORDER BY
    p.year,
    p.industry_branch_code,
    c.category_code;

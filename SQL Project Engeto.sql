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

-- Secondary Table
CREATE TABLE t_adam_krejci_project_SQL_secondary_final AS
WITH european_countries AS (
    SELECT country
    FROM countries
    WHERE continent = 'Europe'
)
SELECT 
    e.country,
    e.year,
    e.gdp,
    e.gini,
    e.population
FROM economies e
JOIN european_countries ec
    ON e.country = ec.country
WHERE e.year BETWEEN 2006 AND 2018
    AND e.country IS NOT NULL
    AND e.year IS NOT NULL
ORDER BY e.country, e.year;

-- Question 1: Wage development by sector
WITH wages AS (
    SELECT DISTINCT
        year,
        industry_branch_code,
        industry_branch_name,
        avg_wage
    FROM t_adam_krejci_project_SQL_primary_final
    ORDER BY
        industry_branch_code,
        year
),
lagged AS (
    SELECT
        industry_branch_code,
        industry_branch_name,
        year,
        avg_wage,
        LAG(avg_wage) OVER (
            PARTITION BY industry_branch_code
            ORDER BY year
        ) AS prev_year_wage
    FROM wages
),
changes AS (
    SELECT
        industry_branch_code,
        industry_branch_name,
        year,
        avg_wage,
        prev_year_wage,
        avg_wage - prev_year_wage AS yoy_change
    FROM lagged
    WHERE prev_year_wage IS NOT NULL
)
SELECT
    industry_branch_name,
    COUNT(*) AS total_years,
    SUM(CASE WHEN yoy_change < 0 THEN 1 ELSE 0 END) AS years_declined,
    SUM(CASE WHEN yoy_change > 0 THEN 1 ELSE 0 END) AS years_increased,
    AVG(yoy_change) AS avg_change
FROM changes
GROUP BY industry_branch_name
ORDER BY years_declined DESC;

-- Question 2: Purchasing power - milk and bread
WITH wage_country AS (
    SELECT
        year,
        AVG(avg_wage) AS avg_wage_country
    FROM t_adam_krejci_project_SQL_primary_final
    WHERE year IN (2006, 2018)
    GROUP BY year
),
prices AS (
    SELECT DISTINCT
        year,
        category_code,
        category_name,
        avg_price
    FROM t_adam_krejci_project_SQL_primary_final
    WHERE year IN (2006, 2018)
      AND category_code IN (111301, 114201)
)
SELECT
    p.year,
    p.category_code,
    p.category_name,
    p.avg_price,
    w.avg_wage_country,
    w.avg_wage_country / p.avg_price AS units_affordable
FROM prices p
JOIN wage_country w USING (year)
ORDER BY p.category_code, p.year;

-- Question 3: Slowest price increases
WITH prices AS (
    SELECT DISTINCT
        year,
        category_code,
        category_name,
        avg_price
    FROM t_adam_krejci_project_SQL_primary_final
),
lagged AS (
    SELECT
        category_code,
        category_name,
        year,
        avg_price,
        LAG(avg_price) OVER (
            PARTITION BY category_code
            ORDER BY year
        ) AS prev_price
    FROM prices
),
yoy AS (
    SELECT
        category_code,
        category_name,
        year,
        avg_price,
        prev_price,
        (avg_price - prev_price) / prev_price * 100 AS yoy_pct_change
    FROM lagged
    WHERE prev_price IS NOT NULL
)
SELECT
    category_code,
    category_name,
    AVG(yoy_pct_change) AS avg_yoy_pct_change
FROM yoy
GROUP BY
    category_code,
    category_name
ORDER BY
    avg_yoy_pct_change ASC;


-- Question 4: Significant difference in prices vs. wages (>10%)
WITH avg_prices AS (
    SELECT
        year,
        AVG(avg_price) AS avg_food_price
    FROM t_adam_krejci_project_SQL_primary_final
    GROUP BY year
),
prices_lag AS (
    SELECT
        year,
        avg_food_price,
        LAG(avg_food_price) OVER (ORDER BY year) AS prev_price
    FROM avg_prices
),
avg_wages AS (
    SELECT
        year,
        AVG(avg_wage) AS avg_wage_country
    FROM t_adam_krejci_project_SQL_primary_final
    GROUP BY year
),
wages_lag AS (
    SELECT
        year,
        avg_wage_country,
        LAG(avg_wage_country) OVER (ORDER BY year) AS prev_wage
    FROM avg_wages
),
joined AS (
    SELECT
        p.year,
        (p.avg_food_price - p.prev_price) / p.prev_price * 100 AS price_yoy,
        (w.avg_wage_country - w.prev_wage) / w.prev_wage * 100 AS wage_yoy
    FROM prices_lag p
    JOIN wages_lag w USING (year)
    WHERE p.prev_price IS NOT NULL
      AND w.prev_wage IS NOT NULL
)
SELECT 
    year,
    price_yoy,
    wage_yoy,
    price_yoy - wage_yoy AS difference,
    CASE 
        WHEN price_yoy - wage_yoy > 10 THEN 'YES - significant price increase'
        ELSE 'NO'
    END AS significant_difference
FROM joined
ORDER BY difference DESC;

-- Question 5a: The impact of GDP
WITH gdp_changes AS (
    SELECT 
        year,
        gdp,
        LAG(gdp) OVER (ORDER BY year) AS prev_gdp,
        LAG(year) OVER (ORDER BY year) AS prev_year
    FROM t_adam_krejci_project_SQL_secondary_final
    WHERE country = 'Czech Republic'
        AND gdp IS NOT NULL
),
wage_changes AS (
    SELECT 
        year,
        AVG(avg_wage) AS avg_wage,
        LAG(AVG(avg_wage)) OVER (ORDER BY year) AS prev_avg_wage,
        LAG(year) OVER (ORDER BY year) AS prev_year
    FROM t_adam_krejci_project_SQL_primary_final
    WHERE avg_wage IS NOT NULL
    GROUP BY year
),
price_changes AS (
    SELECT 
        year,
        AVG(avg_price) AS avg_price,
        LAG(AVG(avg_price)) OVER (ORDER BY year) AS prev_avg_price,
        LAG(year) OVER (ORDER BY year) AS prev_year
    FROM t_adam_krejci_project_SQL_primary_final
    WHERE avg_price IS NOT NULL
    GROUP BY year
),
yoy_data AS (
    SELECT
        g.year,
        (g.gdp - g.prev_gdp) / g.prev_gdp * 100 AS gdp_yoy,
        (w.avg_wage - w.prev_avg_wage) / w.prev_avg_wage * 100 AS wage_yoy,
        (p.avg_price - p.prev_avg_price) / p.prev_avg_price * 100 AS food_yoy
    FROM gdp_changes g
    JOIN wage_changes w 
        ON g.year = w.year 
        AND w.year = w.prev_year + 1
    JOIN price_changes p 
        ON g.year = p.year
        AND p.year = p.prev_year + 1
    WHERE g.year = g.prev_year + 1
        AND g.prev_gdp IS NOT NULL
        AND w.prev_avg_wage IS NOT NULL
        AND p.prev_avg_price IS NOT NULL
)
SELECT
    year,
    gdp_yoy,
    wage_yoy,
    food_yoy,
    LEAD(wage_yoy) OVER (ORDER BY year) AS next_year_wage_yoy,
    LEAD(food_yoy) OVER (ORDER BY year) AS next_year_food_yoy
FROM yoy_data
ORDER BY year;


WITH gdp_changes AS (
    SELECT 
        year,
        gdp,
        LAG(gdp) OVER (ORDER BY year) AS prev_gdp,
        LAG(year) OVER (ORDER BY year) AS prev_year
    FROM t_adam_krejci_project_SQL_secondary_final
    WHERE country = 'Czech Republic'
        AND gdp IS NOT NULL
),
wage_changes AS (
    SELECT 
        year,
        AVG(avg_wage) AS avg_wage,
        LAG(AVG(avg_wage)) OVER (ORDER BY year) AS prev_avg_wage,
        LAG(year) OVER (ORDER BY year) AS prev_year
    FROM t_adam_krejci_project_SQL_primary_final
    WHERE avg_wage IS NOT NULL
    GROUP BY year
),
price_changes AS (
    SELECT 
        year,
        AVG(avg_price) AS avg_price,
        LAG(AVG(avg_price)) OVER (ORDER BY year) AS prev_avg_price,
        LAG(year) OVER (ORDER BY year) AS prev_year
    FROM t_adam_krejci_project_SQL_primary_final
    WHERE avg_price IS NOT NULL
    GROUP BY year
),
yoy_data AS (
    SELECT
        g.year,
        (g.gdp - g.prev_gdp) / g.prev_gdp * 100 AS gdp_yoy,
        (w.avg_wage - w.prev_avg_wage) / w.prev_avg_wage * 100 AS wage_yoy,
        (p.avg_price - p.prev_avg_price) / p.prev_avg_price * 100 AS food_yoy
    FROM gdp_changes g
    JOIN wage_changes w 
        ON g.year = w.year 
        AND w.year = w.prev_year + 1
    JOIN price_changes p 
        ON g.year = p.year
        AND p.year = p.prev_year + 1
    WHERE g.year = g.prev_year + 1
        AND g.prev_gdp IS NOT NULL
        AND w.prev_avg_wage IS NOT NULL
        AND p.prev_avg_price IS NOT NULL
)
SELECT
    year,
    gdp_yoy,
    wage_yoy,
    food_yoy,
    LEAD(wage_yoy) OVER (ORDER BY year) AS next_year_wage_yoy,
    LEAD(food_yoy) OVER (ORDER BY year) AS next_year_food_yoy
FROM yoy_data
ORDER BY year;


-- Question 5b: Correlation GDP vs Wages
WITH gdp_changes AS (
    SELECT 
        year,
        gdp,
        LAG(gdp) OVER (ORDER BY year) AS prev_gdp,
        LAG(year) OVER (ORDER BY year) AS prev_year
    FROM t_adam_krejci_project_SQL_secondary_final
    WHERE country = 'Czech Republic'
        AND gdp IS NOT NULL
),
wage_changes AS (
    SELECT 
        year,
        AVG(avg_wage) AS avg_wage,
        LAG(AVG(avg_wage)) OVER (ORDER BY year) AS prev_avg_wage,
        LAG(year) OVER (ORDER BY year) AS prev_year
    FROM t_adam_krejci_project_SQL_primary_final
    WHERE avg_wage IS NOT NULL
    GROUP BY year
),
price_changes AS (
    SELECT 
        year,
        AVG(avg_price) AS avg_price,
        LAG(AVG(avg_price)) OVER (ORDER BY year) AS prev_avg_price,
        LAG(year) OVER (ORDER BY year) AS prev_year
    FROM t_adam_krejci_project_SQL_primary_final
    WHERE avg_price IS NOT NULL
    GROUP BY year
),
yoy_data AS (
    SELECT
        g.year,
        (g.gdp - g.prev_gdp) / g.prev_gdp * 100 AS gdp_yoy,
        (w.avg_wage - w.prev_avg_wage) / w.prev_avg_wage * 100 AS wage_yoy,
        (p.avg_price - p.prev_avg_price) / p.prev_avg_price * 100 AS food_yoy
    FROM gdp_changes g
    JOIN wage_changes w 
        ON g.year = w.year 
        AND w.year = w.prev_year + 1
    JOIN price_changes p 
        ON g.year = p.year
        AND p.year = p.prev_year + 1
    WHERE g.year = g.prev_year + 1
        AND g.prev_gdp IS NOT NULL
        AND w.prev_avg_wage IS NOT NULL
        AND p.prev_avg_price IS NOT NULL
)
SELECT
    'GDP vs Wages' AS comparison,
    (COUNT(*) * SUM(gdp_yoy * wage_yoy) - SUM(gdp_yoy) * SUM(wage_yoy)) /
    (SQRT(COUNT(*) * SUM(gdp_yoy * gdp_yoy) - SUM(gdp_yoy) * SUM(gdp_yoy)) *
     SQRT(COUNT(*) * SUM(wage_yoy * wage_yoy) - SUM(wage_yoy) * SUM(wage_yoy))) 
    AS correlation_coefficient
FROM yoy_data;


-- Question 5c: Correlation GDP vs Prices
WITH gdp_changes AS (
    SELECT 
        year,
        gdp,
        LAG(gdp) OVER (ORDER BY year) AS prev_gdp,
        LAG(year) OVER (ORDER BY year) AS prev_year
    FROM t_adam_krejci_project_SQL_secondary_final
    WHERE country = 'Czech Republic'
        AND gdp IS NOT NULL
),
wage_changes AS (
    SELECT 
        year,
        AVG(avg_wage) AS avg_wage,
        LAG(AVG(avg_wage)) OVER (ORDER BY year) AS prev_avg_wage,
        LAG(year) OVER (ORDER BY year) AS prev_year
    FROM t_adam_krejci_project_SQL_primary_final
    WHERE avg_wage IS NOT NULL
    GROUP BY year
),
price_changes AS (
    SELECT 
        year,
        AVG(avg_price) AS avg_price,
        LAG(AVG(avg_price)) OVER (ORDER BY year) AS prev_avg_price,
        LAG(year) OVER (ORDER BY year) AS prev_year
    FROM t_adam_krejci_project_SQL_primary_final
    WHERE avg_price IS NOT NULL
    GROUP BY year
),
yoy_data AS (
    SELECT
        g.year,
        (g.gdp - g.prev_gdp) / g.prev_gdp * 100 AS gdp_yoy,
        (w.avg_wage - w.prev_avg_wage) / w.prev_avg_wage * 100 AS wage_yoy,
        (p.avg_price - p.prev_avg_price) / p.prev_avg_price * 100 AS prices_yoy
    FROM gdp_changes g
    JOIN wage_changes w 
        ON g.year = w.year 
        AND w.year = w.prev_year + 1
    JOIN price_changes p 
        ON g.year = p.year
        AND p.year = p.prev_year + 1
    WHERE g.year = g.prev_year + 1
        AND g.prev_gdp IS NOT NULL
        AND w.prev_avg_wage IS NOT NULL
        AND p.prev_avg_price IS NOT NULL
)
SELECT
    'GDP vs Prices' AS comparison,
    (COUNT(*) * SUM(gdp_yoy * prices_yoy) - SUM(gdp_yoy) * SUM(prices_yoy)) /
    (SQRT(COUNT(*) * SUM(gdp_yoy * gdp_yoy) - SUM(gdp_yoy) * SUM(gdp_yoy)) *
     SQRT(COUNT(*) * SUM(prices_yoy * prices_yoy) - SUM(prices_yoy) * SUM(prices_yoy))) 
    AS correlation_coefficient
FROM yoy_data;

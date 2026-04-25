-- Correlation GDP vs Wages
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


-- Correlation GDP vs Prices
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

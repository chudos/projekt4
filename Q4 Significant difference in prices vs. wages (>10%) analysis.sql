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

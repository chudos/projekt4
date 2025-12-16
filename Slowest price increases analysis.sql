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

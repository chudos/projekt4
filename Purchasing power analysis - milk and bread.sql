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

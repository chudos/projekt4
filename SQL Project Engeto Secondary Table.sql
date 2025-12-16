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

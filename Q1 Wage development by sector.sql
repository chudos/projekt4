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

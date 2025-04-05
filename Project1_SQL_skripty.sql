/*
 *  Vytvoření primární tabulky pro SQL z Výzkumných otázek
 */

-- CREATE OR REPLACE TABLE t_petr_oliva_project_SQL_primary_final AS
WITH salary_annual AS 
(
    SELECT
        payroll_year AS year,
        p.industry_branch_code,
        ib.name AS industry_branch,
        ROUND(AVG(p.value), 2) AS avg_salary
    FROM czechia_payroll p
    LEFT JOIN czechia_payroll_industry_branch ib
        ON p.industry_branch_code = ib.code
    WHERE
        p.value_type_code = 5958
        AND p.calculation_code = 200
        AND p.unit_code = 200
    GROUP BY payroll_year, p.industry_branch_code, ib.name
),
prices_annual AS 
(
    SELECT
        EXTRACT(YEAR FROM p.date_from)::int AS year,
        p.category_code,
        cp.name AS category_name,
        ROUND(AVG(p.value::numeric), 2) AS avg_price
    FROM czechia_price p
    JOIN czechia_price_category cp
        ON p.category_code = cp.code
    WHERE p.region_code IS NULL
    GROUP BY EXTRACT(YEAR FROM p.date_from), p.category_code, cp.name
)
SELECT
    c.year,
    c.category_code,
    c.category_name,
    m.industry_branch_code,
    COALESCE(m.industry_branch, 'Celkem ČR') AS industry_branch_name,
    c.avg_price,
    m.avg_salary
FROM prices_annual c
JOIN salary_annual m 
	ON c.year = m.year
ORDER BY c.year, c.category_code, m.industry_branch_code;
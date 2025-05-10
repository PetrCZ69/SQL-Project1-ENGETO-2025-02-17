/*
 *  SQL skript pro odpověď na výzkumnou otázku č. 1 (Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?)
 */

WITH salary_trend AS 
(
    SELECT
        year,
        industry_branch_code,
        industry_branch_name,
        avg_salary,
        LAG(avg_salary) OVER (PARTITION BY industry_branch_code ORDER BY year) AS salary_prev_year
    FROM t_petr_oliva_project_SQL_primary_final
    WHERE industry_branch_code IS NOT NULL -- pro jednotlivá odvětví NE pro celou ČR
),
salary_changes AS 
(
    SELECT
        year,
        industry_branch_code,
        industry_branch_name,
        avg_salary,
        salary_prev_year,
        ROUND((avg_salary - salary_prev_year)::NUMERIC, 2) AS salary_diff, -- výpočet meziročního rozdílu pro pokles průměrných mezd
        CASE 
            WHEN avg_salary < salary_prev_year THEN 1 -- flag pro meziroční pokles na TRUE
            ELSE 0 
        END AS salary_decline_flag
    FROM salary_trend
    WHERE salary_prev_year IS NOT NULL
)
SELECT
    industry_branch_name,
    COUNT(industry_branch_name ) FILTER (WHERE salary_decline_flag = 1) AS years_with_salary_decline,
    MIN(year) FILTER (WHERE salary_decline_flag = 1) AS first_decline_year,
    MAX(year) FILTER (WHERE salary_decline_flag = 1) AS last_decline_year
FROM salary_changes
GROUP BY industry_branch_name
ORDER BY years_with_salary_decline DESC, industry_branch_name
;


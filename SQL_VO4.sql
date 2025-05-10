/*
 * SQL skript pro odpověď na výzkumnou otázku č. 4 (Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně 
 * vyšší než růst mezd (větší než 10 %)?)
*/


WITH national_data AS 
(
    SELECT
        year,
        ROUND((AVG(avg_price))::NUMERIC, 2) AS avg_price,
        ROUND((avg_salary)::NUMERIC, 2) AS avg_salary 	 
    FROM t_petr_oliva_project_SQL_primary_final
	WHERE industry_branch_code IS NULL -- mzdy pro celou ČR
    GROUP BY YEAR , avg_salary
    ORDER BY YEAR DESC
),
growth_calc AS 
(
    SELECT
        year,
        avg_price,
        avg_salary,
        LAG(avg_price) OVER (ORDER BY year) AS prev_price,
        LAG(avg_salary) OVER (ORDER BY year) AS prev_salary
    FROM national_data
),
growth_diff AS (
    SELECT
        year,
        ROUND(((avg_price - prev_price) / NULLIF(prev_price, 0) * 100)::NUMERIC, 2) AS price_growth_pct, -- výpočet % změny pro ceny potravin
        ROUND(((avg_salary - prev_salary) / NULLIF(prev_salary, 0) * 100)::NUMERIC, 2) AS salary_growth_pct, --výpočet % změny pro mzdy
        ROUND((((avg_price - prev_price) / NULLIF(prev_price, 0) * 100) - 
              ((avg_salary - prev_salary) / NULLIF(prev_salary, 0) * 100))::NUMERIC, 2) AS diff_growth_pct --výpočet rozdílu nárůstu cen potravin a mezd v % vyjádření
    FROM growth_calc
    WHERE prev_price IS NOT NULL AND prev_salary IS NOT NULL -- ošetření NULL hodnoty při posunu roku fcí LAG()
)
SELECT *
FROM growth_diff
WHERE diff_growth_pct > 0
ORDER BY year
; 

/*
 *  Vytvoření primární tabulky pro SQL z výzkumných otázek
 */

CREATE TABLE t_petr_oliva_project_SQL_primary_final AS
WITH salary_annual AS 
(
    SELECT
        payroll_year AS year,
        p.industry_branch_code,
        ib.name AS industry_branch,
        ROUND(AVG(p.value::NUMERIC), 2) AS avg_salary
    FROM czechia_payroll p
    LEFT JOIN czechia_payroll_industry_branch ib
        ON p.industry_branch_code = ib.code
    WHERE
        p.value_type_code = 5958 		-- pruměrná hrubá mzda na zaměstnance
        AND p.calculation_code = 200 	-- přepočet na FTE
        AND p.unit_code = 200  			-- mzda vyjádřená v Kč
    GROUP BY payroll_year, p.industry_branch_code, ib.name
),
prices_annual AS 
(
    SELECT 
		EXTRACT(YEAR FROM p.date_from)::int AS year,
        p.category_code,
        cp.name AS category_name,
        cp.price_value,
        cp.price_unit,
        ROUND(AVG(p.value::NUMERIC), 2) AS avg_price
    FROM czechia_price p
    JOIN czechia_price_category cp
        ON p.category_code = cp.code
    WHERE p.region_code IS NULL 		-- vynechání krajů a pouze čísla za celou ČR
    GROUP BY EXTRACT(year FROM p.date_from), p.category_code, cp.name, cp.price_value, cp.price_unit
)
SELECT
    c.year,
    c.category_code,
    c.category_name,
    c.price_value,
    c.price_unit,
    m.industry_branch_code,
    COALESCE(m.industry_branch, 'Celkem odvětví ČR') AS industry_branch_name,
    c.avg_price, 						-- průměrná cena potravin v Kč za jednotku (price_value a price_unit)
    m.avg_salary 						-- průměrná hrubá mzda na zaměstnance v Kč
FROM prices_annual c
INNER JOIN salary_annual m 
	ON c.year = m.year
ORDER BY c.year ASC, c.category_code, m.industry_branch_code
;

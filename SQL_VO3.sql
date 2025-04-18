/*
 * SQL skript pro odpověď na výzkumnou otázku č. 3 (Která kategorie potravin zdražuje nejpomaleji 
 * (je u ní nejnižší percentuální meziroční nárůst))?
*/

WITH price_evolution AS 
(
    SELECT
        year,
        category_code,
        category_name,
        avg_price,
        LAG(avg_price) OVER (PARTITION BY category_code ORDER BY year) AS prev_price -- příprava cen pro výpočet meziročních změn cen potravin
    FROM t_petr_oliva_project_SQL_primary_final
    WHERE industry_branch_code IS NULL 												 -- pouze pro celou ČR
),
yoy_growth_calc AS 
(
    SELECT
        category_code,
        category_name,
        year,
        ROUND(((avg_price - prev_price) / NULLIF(prev_price, 0) * 100)::NUMERIC, 2) AS yoy_growth -- meziroční nárůst ceny pro všechny kategorie potravin a sledované roky
    FROM price_evolution
    WHERE prev_price IS NOT NULL 									-- ošetření prvního roku, který není s čím srovnat
),
average_growth AS 
(
    SELECT
        category_code,
        category_name,
        ROUND((AVG(yoy_growth))::NUMERIC, 2) AS avg_yoy_growth 		-- průměrný růst cen za celé sledované období po kategoriích potravin
    FROM yoy_growth_calc
    GROUP BY category_code, category_name
)
SELECT *
FROM average_growth
ORDER BY avg_yoy_growth ASC 					-- nedávám omezení jen na první položku, která zdražuje nejpomaleji, ať je vidět celý seznam potravin
LIMIT 1
;

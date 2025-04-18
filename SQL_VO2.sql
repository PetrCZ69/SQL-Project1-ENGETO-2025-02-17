/*
 * SQL skript pro odpověď na výzkumnou otázku č. 2 (Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední 
 * srovnatelné období v dostupných datech cen a mezd?
 */

WITH years_range AS 
(
    SELECT DISTINCT year
    FROM t_petr_oliva_project_SQL_primary_final
    WHERE year IN (
    (SELECT MIN (year) FROM t_petr_oliva_project_sql_primary_final) ,   -- filtrace prvního roku v sadě
    (SELECT MAX (year) FROM t_petr_oliva_project_sql_primary_final))	-- filtrace posledního roku v sadě
    ORDER BY YEAR ASC
)
SELECT
    year,
    category_name,
    price_value,
    price_unit,
    ROUND(avg_price::NUMERIC, 2) AS avg_price,
    ROUND(avg_salary::NUMERIC, 0) AS avg_salary,
    ROUND((avg_salary / NULLIF (avg_price, 0))::NUMERIC, 0) AS purchasable_units 	-- počet jednotek, které nakoupím za průměrnou mzdu
FROM t_petr_oliva_project_SQL_primary_final
WHERE
    industry_branch_code IS NULL 													-- vyhodnocuji za celou ČR na za konkrétní odvětví
    AND category_name IN ('Mléko polotučné pasterované', 'Chléb konzumní kmínový')	-- vyhodnocuji pro konkrétní dva druhy potravin
    AND year IN (SELECT YEAR FROM years_range ) 									-- pro první a poslední rok obsažený v podkladových datech
ORDER BY category_name, year
;

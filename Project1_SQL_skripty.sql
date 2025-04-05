/*
 *  Vytvoření primární tabulky pro SQL z Výzkumných otázek
 */

DROP TABLE IF EXISTS t_petr_oliva_project_sql_primary_final -- zrušení tabulky
;

CREATE TABLE t_petr_oliva_project_SQL_primary_final AS
WITH salary_annual AS 
(
    SELECT
        payroll_year AS year,
        p.industry_branch_code,
        ib.name AS industry_branch,
        ROUND(AVG(p.value::numeric), 2) AS avg_salary
    FROM czechia_payroll p
    LEFT JOIN czechia_payroll_industry_branch ib
        ON p.industry_branch_code = ib.code
    WHERE
        p.value_type_code = 5958 -- pruměrná hrubá mzda na zaměstnance
        AND p.calculation_code = 200 -- přepočet na FTE
        AND p.unit_code = 200  -- mzda vyjádřená v Kč
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
        ROUND(AVG(p.value::numeric), 2) AS avg_price
    FROM czechia_price p
    JOIN czechia_price_category cp
        ON p.category_code = cp.code
    WHERE p.region_code IS NULL -- vynechání krajů a pouze čísla za celou ČR
    GROUP BY EXTRACT(YEAR FROM p.date_from), p.category_code, cp.name, cp.price_value, cp.price_unit
)
SELECT
    c.year,
    c.category_code,
    c.category_name,
    c.price_value,
    c.price_unit,
    m.industry_branch_code,
    COALESCE(m.industry_branch, 'Celkem odvětví ČR') AS industry_branch_name,
    c.avg_price, -- průměrná cena potravin v Kč za jednotku (price_value a price_unit)
    m.avg_salary -- průměrná hrubá mzda na zaměstnance v Kč
FROM prices_annual c
INNER JOIN salary_annual m 
	ON c.year = m.year
ORDER BY c.YEAR ASC, c.category_code, m.industry_branch_code
;

SELECT *
FROM t_petr_oliva_project_sql_primary_final tpo
;

/*
 *  Vytvoření sekundární tabulky pro SQL z Výzkumných otázek
 */

DROP TABLE IF EXISTS t_petr_oliva_project_sql_secondary_final -- zrušení tabulky
;

CREATE TABLE t_petr_oliva_project_SQL_secondary_final AS
WITH european_states AS 
(
    SELECT country
    FROM countries
    WHERE continent = 'Europe'
),
years_range AS 
(
    SELECT DISTINCT year
    FROM t_petr_oliva_project_SQL_primary_final
),
economic_data AS 
(
    SELECT
        e.year,
        c.country,
        c.iso3 AS country_code,
        c.continent,
        ROUND(e.gdp::numeric, 2) AS gdp,
        ROUND(e.gini::numeric, 2) AS gini,
        e.population
    FROM economies e
    JOIN countries c ON e.country = c.country
    JOIN european_states es ON es.country = c.country
    WHERE e.year IN (SELECT year FROM years_range)
)
SELECT *
FROM economic_data
ORDER BY country_code, YEAR DESC
;

SELECT *
FROM t_petr_oliva_project_sql_secondary_final tpos
;

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
    WHERE industry_branch_code IS NOT NULL -- pro jednotlivá odvětví ne pro celou ČR
),
salary_changes AS 
(
    SELECT
        year,
        industry_branch_code,
        industry_branch_name,
        avg_salary,
        salary_prev_year,
        ROUND((avg_salary - salary_prev_year)::numeric, 2) AS salary_diff,
        CASE 
            WHEN avg_salary < salary_prev_year THEN 1 
            ELSE 0 
        END AS salary_decline_flag
    FROM salary_trend
    WHERE salary_prev_year IS NOT NULL
)
SELECT
    industry_branch_name,
    COUNT(*) FILTER (WHERE salary_decline_flag = 1) AS years_with_salary_decline,
    MIN(year) FILTER (WHERE salary_decline_flag = 1) AS first_decline_year,
    MAX(year) FILTER (WHERE salary_decline_flag = 1) AS last_decline_year
FROM salary_changes
GROUP BY industry_branch_name
ORDER BY years_with_salary_decline DESC, industry_branch_name
;

/*
 * SQL skript pro odpověď na výzkumnou otázku č. 2 (Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední 
 * srovnatelné období v dostupných datech cen a mezd?
 */

SELECT
    year,
    category_name,
    price_value,
    price_unit,
    ROUND(avg_price::numeric, 2) AS avg_price,
    ROUND(avg_salary::numeric, 0) AS avg_salary,
    ROUND((avg_salary / NULLIF(avg_price, 0))::numeric, 0) AS purchasable_units -- počet jednotek, které nakoupím za průměrnou mzdu
FROM t_petr_oliva_project_SQL_primary_final
WHERE
    industry_branch_code IS NULL -- vyhodnocuji za celou ČR na za konkrétní odvětví
    AND category_name IN ('Mléko polotučné pasterované', 'Chléb konzumní kmínový') -- vyhodnocuji pro dva druhy potravin
    AND year IN (2006, 2018) -- pro první a poslední rok obsažený v podkladové tabulce
ORDER BY category_name, YEAR
;

/*
 * SQL skript pro odpověď na výzkumnou otázku č. 3 (Která kategorie potravin zdražuje nejpomaleji 
 * (je u ní nejnižší percentuální meziroční nárůst))?
*/





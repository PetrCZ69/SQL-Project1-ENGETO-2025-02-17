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
        ROUND(AVG(p.value::NUMERIC), 2) AS avg_salary
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
        ROUND(AVG(p.value::NUMERIC), 2) AS avg_price
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
        ROUND(e.gdp::NUMERIC, 2) AS gdp,
        ROUND(e.gini::NUMERIC, 2) AS gini,
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
        ROUND((avg_salary - salary_prev_year)::NUMERIC, 2) AS salary_diff,
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
    ROUND(avg_price::NUMERIC, 2) AS avg_price,
    ROUND(avg_salary::NUMERIC, 0) AS avg_salary,
    ROUND((avg_salary / NULLIF(avg_price, 0))::NUMERIC, 0) AS purchasable_units -- počet jednotek, které nakoupím za průměrnou mzdu
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

WITH price_evolution AS 
(
    SELECT
        year,
        category_code,
        category_name,
        avg_price,
        LAG(avg_price) OVER (PARTITION BY category_code ORDER BY year) AS prev_price -- příprava cen pro výpočet meziročních změn cen
    FROM t_petr_oliva_project_SQL_primary_final
    WHERE industry_branch_code IS NULL -- pouze pro celou ČR
),
yoy_growth_calc AS 
(
    SELECT
        category_code,
        category_name,
        year,
        ROUND(((avg_price - prev_price) / NULLIF(prev_price, 0) * 100)::NUMERIC, 2) AS yoy_growth -- meziroční nárůst ceny pro všechny kategorie potravin a sledované roky
    FROM price_evolution
    WHERE prev_price IS NOT NULL -- ošetření prvního roku, který není s čím srovnat
),
average_growth AS 
(
    SELECT
        category_code,
        category_name,
        ROUND((AVG(yoy_growth))::NUMERIC, 2) AS avg_yoy_growth -- průměrný růst cen za celé sledované období po kategoriích potravin
    FROM yoy_growth_calc
    GROUP BY category_code, category_name
)
SELECT *
FROM average_growth
ORDER BY avg_yoy_growth ASC -- nedávám omezení na první položku, která zdražuje nejpomaleji, ať je vidět celý seznam potravin
--LIMIT 1
;

/*
 * SQL skript pro odpověď na výzkumnou otázku č. 4 (Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně 
 * vyšší než růst mezd (větší než 10 %)?)
*/

WITH national_data AS 
(
    SELECT
        year,
        ROUND((AVG(avg_price))::NUMERIC, 2) AS avg_price,
        ROUND((AVG(avg_salary))::NUMERIC, 2) AS avg_salary -- jedna hodnota mzdy pro rok, ale kvuli konzistenci takto 
    FROM t_petr_oliva_project_SQL_primary_final
    WHERE industry_branch_code IS NULL -- mzdy pro celou ČR
    GROUP BY year
),
growth_calc AS (
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
              ((avg_salary - prev_salary) / NULLIF(prev_salary, 0) * 100))::NUMERIC, 2) AS diff_growth_pct --výpočet rozdílu nárůstu cen potravin a mezd
    FROM growth_calc
    WHERE prev_price IS NOT NULL AND prev_salary IS NOT NULL -- ošetření nulové ceny pro dělení
)
SELECT *
FROM growth_diff
-- WHERE diff_growth_pct > 10 -- podmínka pro nárůst cen potravin o více než 10% nad nárůst průměrných mezd, neuplatňuji aby byly vidět hodnoty změn pro jednotlivé sledované roky
ORDER BY YEAR
; 

/*
 * SQL skript pro odpověď na výzkumnou otázku č. 5 (Má výška HDP vliv na změny ve mzdách a cenách potravin? 
 * Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném 
 * nebo následujícím roce výraznějším růstem?)
*/

WITH cz_salary_price AS 
(
    SELECT
        year,
        ROUND(AVG(avg_price), 2) AS avg_price,		-- průměrné ceny potravin
        ROUND(AVG(avg_salary), 2) AS avg_salary		-- průměrné mzdy
    FROM t_petr_oliva_project_SQL_primary_final
    WHERE industry_branch_code IS NULL
    GROUP BY year
),
cz_secondary AS 
(
    SELECT *										-- dostupné údaje HDP, GINI a počet obyvatel pro ČR ze sekundární tabulky
    FROM t_petr_oliva_project_SQL_secondary_final
    WHERE country_code = 'CZE'
),
cz_combined AS 
(
    SELECT
        s.year,
        s.gdp,
        sp.avg_salary,
        sp.avg_price
    FROM cz_secondary s
    JOIN cz_salary_price sp ON s.year = sp.YEAR		-- propojení průměrných cen potravin, mezd s HDP v ČR
),
cz_growth_base AS 
(
    SELECT
        year,
        gdp,
        avg_salary,
        avg_price,
        LAG(gdp) OVER (ORDER BY year) AS prev_gdp,
        LAG(avg_salary) OVER (ORDER BY year) AS prev_salary,
        LAG(avg_price) OVER (ORDER BY year) AS prev_price
    FROM cz_combined											-- vytvoření základny pro výpočet meziročního růstu sledovaných veličin
),
cz_growth_current AS 
(
    SELECT
        year,
        ROUND((gdp - prev_gdp) / NULLIF(prev_gdp, 0) * 100, 2) AS gdp_growth_pct,
        ROUND((avg_salary - prev_salary) / NULLIF(prev_salary, 0) * 100, 2) AS salary_growth_pct,
        ROUND((avg_price - prev_price) / NULLIF(prev_price, 0) * 100, 2) AS price_growth_pct,
        ROUND(
            ROUND((avg_salary - prev_salary) / NULLIF(prev_salary, 0) * 100, 2) / 
            NULLIF(ROUND((gdp - prev_gdp) / NULLIF(prev_gdp, 0) * 100, 2), 0), 2
        ) AS salary_vs_gdp_growth,
        ROUND(
            ROUND((avg_price - prev_price) / NULLIF(prev_price, 0) * 100, 2) / 
            NULLIF(ROUND((gdp - prev_gdp) / NULLIF(prev_gdp, 0) * 100, 2), 0), 2
        ) AS price_vs_gdp_growth
    FROM cz_growth_base																-- výpočet veličin a poměrových ukazatelů pro daný rok t
    WHERE prev_gdp IS NOT NULL AND prev_salary IS NOT NULL AND prev_price IS NOT NULL
),
cz_growth_lagged AS 
(
    SELECT
        curr.year AS year,
        ROUND((prev.gdp - prev.prev_gdp) / NULLIF(prev.prev_gdp, 0) * 100, 2) AS gdp_growth_pct_lag,
        ROUND((curr.avg_salary - curr.prev_salary) / NULLIF(curr.prev_salary, 0) * 100, 2) AS salary_growth_pct,
        ROUND((curr.avg_price - curr.prev_price) / NULLIF(curr.prev_price, 0) * 100, 2) AS price_growth_pct,
        ROUND(((curr.avg_salary - curr.prev_salary) / NULLIF(curr.prev_salary, 0) * 100) / 
              NULLIF((prev.gdp - prev.prev_gdp) / NULLIF(prev.prev_gdp, 0) * 100, 0), 2) AS salary_vs_gdp_growth_lag,
        ROUND(((curr.avg_price - curr.prev_price) / NULLIF(curr.prev_price, 0) * 100) / 
              NULLIF((prev.gdp - prev.prev_gdp) / NULLIF(prev.prev_gdp, 0) * 100, 0), 2) AS price_vs_gdp_growth_lag
    FROM cz_growth_base curr
    JOIN cz_growth_base prev ON curr.year = prev.year + 1	-- výpočet veličin a poměrových ukazatelů pro daný rok t + 1
    WHERE prev.prev_gdp IS NOT NULL
)
SELECT
    c.year,												-- posuzovaný rok
  --  c.gdp_growth_pct,									-- % meziroční změna HDP v t
  --  c.salary_growth_pct,								-- % meziroční změna mezd v t
  --  c.price_growth_pct,									-- % meziroční změna cen potravin v t
    c.salary_vs_gdp_growth,								-- poměr růstu mezd k růstu HDP ve stejném roce t
    c.price_vs_gdp_growth,								-- poměr růstu cen potravin k růstu HDP ve stejném roce
  --  l.gdp_growth_pct_lag,								-- % meziroční změna HDP v t - 1
  --  l.salary_growth_pct AS salary_growth_pct_lag,		-- % meziroční změna mezd v t - 1
  --  l.price_growth_pct AS price_growth_pct_lag,			-- % meziroční změna cen potravin v t + 1
    l.salary_vs_gdp_growth_lag,							-- poměr růstu mezd k růstu HDP z předchozího roku t + 1
    l.price_vs_gdp_growth_lag							-- poměr růstu cen potravin k růstu HDP z předchozího roku t + 1
FROM cz_growth_current c
JOIN cz_growth_lagged l ON c.year = l.year				-- výsledný výstup kombinovaně pro porovnání poměrových ukazatelů pro t a t + 1 (následující rok)
ORDER BY c.YEAR
;
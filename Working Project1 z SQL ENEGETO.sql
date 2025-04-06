/*
 * SQL pro porovnání vlivu GDP na meziroční změny cen potravin a mezd, pouze pro ČR, doplněný o poměrové ukazatele a ještě
 * o porovnání GDP, cen potravin a mezd pro stejný rok t a následující rok t+1
 * ufff to byla fuška, ale pro interpretaci odpovědi na otázku bude tento výstup nejlepší :-)
 */

WITH cz_salary_price AS 
(
    SELECT
        year,
        ROUND(AVG(avg_price), 2) AS avg_price,
        ROUND(AVG(avg_salary), 2) AS avg_salary
    FROM t_petr_oliva_project_SQL_primary_final
    WHERE industry_branch_code IS NULL
    GROUP BY year
),
cz_secondary AS 
(
    SELECT *
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
    JOIN cz_salary_price sp ON s.year = sp.year
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
    FROM cz_combined
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
    FROM cz_growth_base
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
    JOIN cz_growth_base prev ON curr.year = prev.year + 1
    WHERE prev.prev_gdp IS NOT NULL
)
SELECT
    c.year,
    c.gdp_growth_pct,
    c.salary_growth_pct,
    c.price_growth_pct,
    c.salary_vs_gdp_growth,
    c.price_vs_gdp_growth,
    l.gdp_growth_pct_lag,
    l.salary_growth_pct AS salary_growth_pct_lag,
    l.price_growth_pct AS price_growth_pct_lag,
    l.salary_vs_gdp_growth_lag,
    l.price_vs_gdp_growth_lag
FROM cz_growth_current c
JOIN cz_growth_lagged l ON c.year = l.year
ORDER BY c.year
; 


/*
 * SQL pro porovnání vlivu GDP na meziroční změny cen potravin a mezd, pouze pro ČR, protože pro ostatní státy Evropy nemám 
 * k dispozici údaje o cenách potravin a mezd
 */

WITH cz_salary_price AS (
    SELECT
        year,
        ROUND(AVG(avg_price), 2) AS avg_price,
        ROUND(AVG(avg_salary), 2) AS avg_salary
    FROM t_petr_oliva_project_SQL_primary_final
    WHERE industry_branch_code IS NULL
    GROUP BY year
),
cz_secondary AS (
    SELECT *
    FROM t_petr_oliva_project_SQL_secondary_final
    WHERE country_code = 'CZE'
),
cz_combined AS (
    SELECT
        s.year,
        s.country,
        s.country_code,
        s.gdp,
        sp.avg_salary,
        sp.avg_price
    FROM cz_secondary s
    JOIN cz_salary_price sp ON s.year = sp.year
),
cz_growth AS (
    SELECT
        year,
        gdp,
        avg_salary,
        avg_price,
        LAG(gdp) OVER (ORDER BY year) AS prev_gdp,
        LAG(avg_salary) OVER (ORDER BY year) AS prev_salary,
        LAG(avg_price) OVER (ORDER BY year) AS prev_price
    FROM cz_combined
),
cz_growth_result AS (
    SELECT
        year,
        ROUND((gdp - prev_gdp) / NULLIF(prev_gdp, 0) * 100, 2) AS gdp_growth_pct,
        ROUND((avg_salary - prev_salary) / NULLIF(prev_salary, 0) * 100, 2) AS salary_growth_pct,
        ROUND((avg_price - prev_price) / NULLIF(prev_price, 0) * 100, 2) AS price_growth_pct
    FROM cz_growth
    WHERE prev_gdp IS NOT NULL AND prev_salary IS NOT NULL AND prev_price IS NOT NULL
)
SELECT *
FROM cz_growth_result
ORDER BY year;

/*
 * SQL pro úkol 5 doplněný o poměrové ukazatele GDP/ceny potravi a GDP/mzdy
 */
WITH cz_salary_price AS (
    SELECT
        year,
        ROUND(AVG(avg_price), 2) AS avg_price,
        ROUND(AVG(avg_salary), 2) AS avg_salary
    FROM t_petr_oliva_project_SQL_primary_final
    WHERE industry_branch_code IS NULL
    GROUP BY year
),
cz_secondary AS (
    SELECT *
    FROM t_petr_oliva_project_SQL_secondary_final
    WHERE country_code = 'CZE'
),
cz_combined AS (
    SELECT
        s.year,
        s.country,
        s.country_code,
        s.gdp,
        sp.avg_salary,
        sp.avg_price
    FROM cz_secondary s
    JOIN cz_salary_price sp ON s.year = sp.year
),
cz_growth AS (
    SELECT
        year,
        gdp,
        avg_salary,
        avg_price,
        LAG(gdp) OVER (ORDER BY year) AS prev_gdp,
        LAG(avg_salary) OVER (ORDER BY year) AS prev_salary,
        LAG(avg_price) OVER (ORDER BY year) AS prev_price
    FROM cz_combined
),
cz_growth_result AS (
    SELECT
        year,
        ROUND((gdp - prev_gdp) / NULLIF(prev_gdp, 0) * 100, 2) AS gdp_growth_pct,
        ROUND((avg_salary - prev_salary) / NULLIF(prev_salary, 0) * 100, 2) AS salary_growth_pct,
        ROUND((avg_price - prev_price) / NULLIF(prev_price, 0) * 100, 2) AS price_growth_pct
    FROM cz_growth
    WHERE prev_gdp IS NOT NULL AND prev_salary IS NOT NULL AND prev_price IS NOT NULL
),
cz_with_ratios AS (
    SELECT
        *,
        ROUND(salary_growth_pct / NULLIF(gdp_growth_pct, 0), 2) AS salary_vs_gdp_growth,
        ROUND(price_growth_pct / NULLIF(gdp_growth_pct, 0), 2) AS price_vs_gdp_growth
    FROM cz_growth_result
)
SELECT *
FROM cz_with_ratios
ORDER BY YEAR
;

/*
 * SQL na porovnání nárůstu průměrné ceny všech potravin a nárůstu průměrné mzdy 
 */

WITH national_data AS (
    SELECT
        year,
        ROUND(AVG(avg_price), 2) AS avg_price,
        ROUND(AVG(avg_salary), 2) AS avg_salary
    FROM t_petr_oliva_project_SQL_primary_final
    WHERE industry_branch_code IS NULL
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
        ROUND((avg_price - prev_price) / NULLIF(prev_price, 0) * 100, 2) AS price_growth_pct,
        ROUND((avg_salary - prev_salary) / NULLIF(prev_salary, 0) * 100, 2) AS salary_growth_pct,
        ROUND(((avg_price - prev_price) / NULLIF(prev_price, 0) * 100) - 
              ((avg_salary - prev_salary) / NULLIF(prev_salary, 0) * 100), 2) AS diff_growth_pct
    FROM growth_calc
    WHERE prev_price IS NOT NULL AND prev_salary IS NOT NULL
)
SELECT *
FROM growth_diff
--WHERE diff_growth_pct > 10
ORDER BY year;



/*
 * SQL na posun roku u cen potravin, pak výpočet meziroční změny prům.ceny, pak zprůměrování každé kategorie potravin za celé období
 * 
 */

WITH price_evolution AS 
(
    SELECT
        year,
        category_code,
        category_name,
        avg_price,
        LAG(avg_price) OVER (PARTITION BY category_code ORDER BY year) AS prev_price
    FROM t_petr_oliva_project_SQL_primary_final
    WHERE industry_branch_code IS NULL -- pouze pro celou ČR
),
yoy_growth_calc AS 
(
    SELECT
        category_code,
        category_name,
        year,
        ROUND(((avg_price - prev_price) / NULLIF(prev_price, 0) * 100)::numeric, 2) AS yoy_growth
    FROM price_evolution
    WHERE prev_price IS NOT NULL
)
    SELECT
        category_code,
        category_name,
        ROUND((AVG(yoy_growth))::numeric, 2) AS avg_yoy_growth
    FROM yoy_growth_calc
    GROUP BY category_code, category_name
    ORDER BY avg_yoy_growth ASC
;

/*
 *  SQL na zprůměrování mezd (industry_branch_code, rok)
 */

SELECT
        payroll_year AS year,
        p.industry_branch_code,
        ib.name AS industry_branch,
        ROUND(AVG(p.value::numeric), 2) AS avg_salary
    FROM czechia_payroll p
    LEFT JOIN czechia_payroll_industry_branch ib
        ON p.industry_branch_code = ib.code
    WHERE
        p.value_type_code = 5958
        AND p.calculation_code = 200
        AND p.unit_code = 200
    GROUP BY payroll_year, p.industry_branch_code, ib.name
    ORDER BY p.payroll_year DESC , p.industry_branch_code
    ;

/*
 *  SQL dotaz na zprůměrování cen potravin (category_code, rok)
 */

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
    WHERE p.region_code IS NULL AND (EXTRACT(YEAR FROM p.date_from)::int) IN ('2018')
    GROUP BY EXTRACT(YEAR FROM p.date_from), p.category_code, cp.name, cp.price_value, cp.price_unit
    ORDER BY YEAR DESC, p.category_code
    ;

/*
 * Zjištění, zda je země v Evropě
 */

SELECT c.country , c.abbreviation, c.continent, c.region_in_world
FROM countries c 
WHERE lower(c.CONTINENT) LIKE '%europe%'


SELECT DISTINCT c.country , e.country , c.abbreviation, c.continent, c.region_in_world
FROM countries c 
JOIN economies e 
 ON lower(c.country) = lower(e.country)
WHERE lower(c.CONTINENT) LIKE '%europe%'
;

/*
 * Ověření, zda jsou hodnoty calculation_code = 200 (přepočtený) pro všechny potřebná časová období
 */

SELECT count(cpay.calculation_code ) ,
	cpay.calculation_code
FROM czechia_payroll cpay
WHERE cpay.calculation_code IN (100, 200) 
	AND cpay.value_type_code = 5958
	AND cpay.industry_branch_code IS NULL
GROUP BY cpay.calculation_code
;

SELECT *
FROM czechia_payroll cpay
WHERE cpay.calculation_code IN (200) 
	AND cpay.value_type_code = 5958
	AND cpay.industry_branch_code IS NULL
ORDER BY cpay.payroll_year DESC , 
	cpay.payroll_quarter DESC 
	
	
/*
 * Ověření, zda jsou v tabulce cen správně strukturovaná data podle region code a zda je průměr přes kraje a ČR shodný
 */


SELECT cpc."name" , avg(cp.value) AS prumer, 
CASE
	WHEN cp.region_code IS NOT NULL THEN 'kraje' 
	ELSE 'ČR'
END AS rozdeleni_hodnot
FROM czechia_price cp 
JOIN czechia_price_category cpc 
	ON cp.category_code = cpc.code
GROUP BY cpc."name" , rozdeleni_hodnot
ORDER BY cpc."name" , rozdeleni_hodnot 

;
	
	
	
/*
 * Oveření konzistentnosti dat základní tabulky cen potravin a jejich číselníků 
 */

SELECT *   
FROM czechia_price cpr
LEFT JOIN czechia_price_category cpc 
	ON cpr.category_code = cpc.code
LEFT JOIN czechia_region cr 
	ON cpr.region_code = cr.code
--GROUP BY cpc.code , cr.code
WHERE cpr.category_code =2000001
ORDER BY cpr.region_code DESC  , cpr.category_code
;

-- výpočet počtu řádků dle categorie potraviny a roku záznamu

SELECT 
	category_code,
	date_part('year', date_from) AS year_of_entry, -- 2017-11-13 01:00:00.000 +0100
	count(value) AS rows_of_category
FROM czechia_price cpr
GROUP BY
	category_code,
	year_of_entry
ORDER BY
	year_of_entry DESC,
	category_code
;

/*
 * Ověření struktury dat s ohledem na roky a kvartály (rozah dostupných období - roků)
 */

SELECT cp.payroll_year ,
	cp.payroll_quarter 
FROM czechia_payroll cp 
GROUP BY cp.payroll_year  , cp.payroll_quarter 
ORDER BY cp.payroll_year  , cp.payroll_quarter 
;

/*
 * Oveření konzistentnosti dat základní tabulky mezd a jejich číselníků (nalezen problém s číselníkem czechia_payroll_unit)
 */

SELECT  cp.value ,
		cp.calculation_code ,
		cp.value_type_code ,
		cpvt."name" ,
		cp.unit_code ,
		cpu."name" ,
		cp.industry_branch_code ,
		cpib."name" ,
		cp.payroll_year ,
		cp.payroll_quarter
FROM czechia_payroll cp 
LEFT JOIN czechia_payroll_unit cpu 
	ON cp.unit_code = cpu.code
LEFT JOIN czechia_payroll_value_type cpvt 
	ON cp.value_type_code = cpvt.code
LEFT JOIN czechia_payroll_industry_branch cpib 
	ON cp.industry_branch_code = cpib.code 
WHERE cp.value_type_code = 5958
--	AND cp.payroll_year IN ('2000')
--	AND cp.payroll_quarter = '1'
	AND cp.industry_branch_code IS NULL 
ORDER BY cp.payroll_year  , cp.payroll_quarter , cp.industry_branch_code , cp.calculation_code
;

/*
 *  Výpočet sumy průměrných mezd po odvětvích v jednotlivých letech
 */

SELECT cp.calculation_code , 
		round(avg(cp.value::numeric), 0) AS avg_salary 
FROM czechia_payroll cp 
WHERE cp.payroll_year IN ('2000')
	AND cp.payroll_quarter = '1'
	AND cp.value_type_code = '5958'
	AND cp.industry_branch_code IS NULL
GROUP BY cp.calculation_code 
;


-- Oprava dat v tabulce číselníku czecia_payroll_unit podle ENGETO discord

UPDATE czechia_payroll_unit SET name = 'Kč' WHERE code = 200;

UPDATE czechia_payroll_unit SET name = 'tis. osob (tis. os.)' WHERE code = 80403;

/*
 *  Selecty do tabulek pro prozkoumání struktutry a obsahu
 */

SELECT*
FROM czechia_payroll_calculation cpc 
;

SELECT *
FROM czechia_payroll_industry_branch cpib 
;

SELECT *
FROM czechia_payroll_unit cpu 
;

SELECT *
FROM czechia_payroll_value_type cpvt 
;

SELECT *
FROM czechia_price cp
ORDER BY cp.date_from desc
;

SELECT *
FROM czechia_price_category cpc 
;

SELECT *
FROM czechia_region cr 
;


SELECT *
FROM czechia_district cd 
;

SELECT *
FROM countries c 
;

SELECT DISTINCT e.country 
FROM economies e 
ORDER BY e.country 
;

SELECT * 
FROM economies e 
WHERE 	
	e.gini IS NOT NULL
	AND e.gdp IS NOT NULL
ORDER BY e.country , e."year" 

SELECT DISTINCT e."year"
FROM economies e 
ORDER BY "year" 
;

;
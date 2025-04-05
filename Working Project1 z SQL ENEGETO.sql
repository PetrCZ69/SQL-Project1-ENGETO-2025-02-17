/*
 *  První varianta na spojení tabulek czechia_price a czechia_payrol
 */

SELECT
	cpc.name AS food_category,
	cp.value AS food_price,
	cpib.name AS industry_branch,
	cpay.value AS avg_wages,
	cp.region_code,
	to_char(cp.date_from, 'DD. Month YYYY') AS date_from, 
	to_char(cp.date_to, 'DD.MM.YY') AS date_to 
FROM czechia_price cp
JOIN czechia_payroll cpay
	ON cpay.payroll_year = date_part('year', cp.date_from)
JOIN czechia_payroll_industry_branch cpib
	ON cpay.industry_branch_code = cpib.code
JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
WHERE cpay.value_type_code = 5958;

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
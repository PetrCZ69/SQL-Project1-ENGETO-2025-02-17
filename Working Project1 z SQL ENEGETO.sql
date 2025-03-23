
SELECT cp.payroll_year ,
	cp.payroll_quarter 
FROM czechia_payroll cp 
GROUP BY cp.payroll_year  , cp.payroll_quarter 
ORDER BY cp.payroll_year  , cp.payroll_quarter 

;

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
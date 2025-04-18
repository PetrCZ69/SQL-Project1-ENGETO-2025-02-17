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
        ROUND(avg_salary, 2) AS avg_salary		    -- průměrné mzdy
    FROM t_petr_oliva_project_SQL_primary_final
    WHERE industry_branch_code IS NULL
    GROUP BY year, avg_salary 
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
    JOIN cz_salary_price sp ON s.year = sp.year		-- propojení průměrných cen potravin, mezd s HDP v ČR
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
    FROM cz_combined									-- vytvoření základny pro výpočet meziročního růstu sledovaných veličin
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
    c.salary_vs_gdp_growth,								-- poměr růstu mezd k růstu HDP ve stejném roce t
    c.price_vs_gdp_growth,								-- poměr růstu cen potravin k růstu HDP ve stejném roce t
    l.salary_vs_gdp_growth_lag,							-- poměr růstu mezd k růstu HDP z předchozího roku t + 1
    l.price_vs_gdp_growth_lag							-- poměr růstu cen potravin k růstu HDP z předchozího roku t + 1
FROM cz_growth_current c								-- spojení ukazatelů za obě období
JOIN cz_growth_lagged l ON c.year = l.year				-- výsledný výstup kombinovaně pro porovnání poměrových ukazatelů pro t a t + 1 (následující rok)
ORDER BY c.year
;
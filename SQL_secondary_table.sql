/*
 *  Vytvoření sekundární tabulky pro SQL z výzkumných otázek
 */

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
ORDER BY country_code, year DESC
;

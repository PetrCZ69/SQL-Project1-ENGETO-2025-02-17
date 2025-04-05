---
# Projekt č.1 z SQL pro certifikaci ENGETO
---

# Zadání projektu
1. na základě průměrných příjmů za určité časové období posoudit dostupnost základních potravin v ČR
2. připravit přehled s parametry HDP (hrubý domácí produkt), GINI koeficient (měření příjmové nebo majetkové nerovnosti v populaci)
a počet obyvatel v Evropských státech ve stejném období jako přehled pro ČR
zdroj dat ČSÚ: https://csu.gov.cz/docs/107508/a7309d97-c5be-4ef4-de2f-d2962e385b93/110079-22dds.htm

# Analýza zadání

Mám k dispozici 3 datové sady

1a. průměrné mzdy a průměrný počet zaměstnaných osob v odvětvích (19 odvětví) v ČR za roky 2000 až 2021 po kvartálech (2021 pouze první 2 kvartály) - 6 880 záznamů
1b. ceník potravin v ČR od ledna 2006 do prosince 2018 (vždy pro měření od - do jako timestamp) - 108 249 záznamů
2. číselníky ČR - kraje a okresy
3. číselníky zemí a ekonomik s parametry jako HDP, GINI index, počet obyvatel, údaje za roky 1960 až 2020

# Analýza podkladových dat (tabulek)
Posouzení vazby hlavních tabulek a číselníků, jejich obsahu (konzistence, NULL hodnoty, období) 

## Tabulka mezd (payroll)
Analýzou tabulek a přiřazením názvů kategorií z číselníků jsem zjistil, že:
- hlavní tabulka czechia_payroll má ve sloupci unit_code přehozené kódy pro jednotku (80403 - Kč a 200 - tis. osob), které by měly odpovídat sloupci číselníku typu value_type_code (316 - Průměrný počet zaměstnaných osob a 5958 Průměrná hrubá mzda na zaměstnance). Na discordu ENGETO jsem našel řešení, jak hodnoty uvést do správného pořadí (přehození kódů v tabulce unit_code), což jsem v lokální databázi Postgres DB data_academy_content dle doporučení provedl.
SQL script, na základě kterého jsem odhalil nesrovnalost (propojení číselníků s hlavní tabulkou mezd) - v pracovním souboru
- řádky s hodnotou value_type_code = 316 nebudeme potřebovat (jen kód 5958) redukce na 3 440 záznamů
- některé řádky industry_branch_code (odvětví) je NULL - celkem 172 záznamů, pro každý rok a Q jsou tam 2 hodnoty (podle číselníku czechia_payroll_calculation vždy jedna hodnota fyzická a jedna přepočítaná), takže to vypadá na sumární průměrnou hodnotu za všechna odvětví
- v číselníku czechia_payroll_calculation jsou požívány kódy 100 = fyzický počet osob (kolik lidí skutečně pracuje) a 200 přepočtený počet osob (FTE kolik odpovídá plným úvazkům např. 2 lidé na poloviční úvazek = 1 přepočtená osoba), pro oba kódy jsou uváděny průměrné hrubé mzdy na zaměstnance pro každý rok, Q a odvětví
---

## Tabulka cen potravin (price)
Analýzou tabulek a přiřazením názvů kategorií z číselníků jsem zjistil, že:
- číselník czechia_price_category obsahuje kategorie potravin obsahuje názvy potravin, množstevní a měrnou jednotku - 27 záznamů
- číselník czechia_region obsahuje názvy krajů v ČR - 14 záznamů, pokud je region_code NULL, pak jde o sumární hodnotu pro danou kategorii potraviny (category_code) za celou ČR (ověřeno)
- hlavní tabulka czechia_price po odfiltrovani NULL hodnot ze sloupce region_code má 101 032 záznamů, tedy 7 217 záznamů se týká pravděpodobně jen celé ČR
- hlavní tabulka czechia_price ve sloupci value neobsahuje hodnotu  NULL

## Tabulky countries, economies
Analýzou tabulek jsem zjistil, že:
- v tabulce countries vyberu evropské země přes continent = Europe
- tabulky countries a economies je možné spojit přes položku country 
- z tabulky použiji sloupce gdp, gini a population, nicméně pro ostatní země v Evropě nemám k dispozici údaje o cenách potravin a mzdách, tyto údaje pouze pro ČR v tabulkách czechia_price a czechia_payrol

---

# Příprava podkladových tabulek pro Výzkumné otázky
Příprava primární a sekundární tabulky tak, aby z nich na základě SQL dotazů bylo možné zodpovědět definované otázky

## Primární tabulka t_petr_oliva_project_SQL_primary_final
Základní datový přehled, který slouží jako výlučný zdroj pro zodpovězení výzkumných otázek 1–4. Obsahuje průměrné roční mzdy a průměrné roční ceny vybraných potravin v České republice, rozdělené podle odvětví a kategorií potravin. 
Zdroje dat:
Mzdy: czechia_payroll + czechia_payroll_industry_branch
Ceny: czechia_price + czechia_price_category
Filtry:
Mzdy 
- value_type_code = 5958 – průměrná hrubá mzda na zaměstnance
- calculation_code = 200 – přepočtený počet zaměstnanců (FTE)
- unit_code = 200 – Kč
Agregace po roce payroll_year (pře kvartály), odvětví včetně industry_branch_code IS NULL (Celkem ČR)

Ceny
- region_code IS NULL – pouze ceny za celou ČR, kraje nejsou nutné
Agregace po roce (EXTRACT(YEAR FROM date_from)) a kategoriích potravin category_code

---

# Výsledky (řešení)

##Výzkumné otázky

1.Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

2.Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

3.Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?

4.Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

5.Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

# Seznam souborů se skripty SQL

- Working Project1 z SQL ENGETO.sql * pracovní soubor se skripty SQL pro analýzu a ověření struktury dat tabulek a číselníků

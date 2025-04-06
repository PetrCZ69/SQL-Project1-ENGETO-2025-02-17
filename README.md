
# Projekt č.1 z SQL 
**Zpracování projektu č.1 z SQL pro certifikaci ENGETO**

---

# Zadání projektu

1. na základě průměrných příjmů za určité časové období posoudit dostupnost základních potravin v ČR
2. připravit přehled s parametry HDP (hrubý domácí produkt), GINI koeficient (měření příjmové nebo majetkové nerovnosti v populaci)
a počet obyvatel v Evropských státech ve stejném období jako přehled pro ČR
[zdroj dat ČSÚ](https://csu.gov.cz/docs/107508/a7309d97-c5be-4ef4-de2f-d2962e385b93/110079-22dds.htm)

---

# Cíl projektu

**Analyzovat ekonomická a sociální data z tabulek o mzdách, cenách potravin a makroekonomických indikátorech. Odpovědět na 5 konkrétních výzkumných otázek pomocí SQL a prezentovat závěry z datové analýzy.**

Použité tabulky:

1. t_petr_oliva_project_SQL_primary_final
2. t_petr_oliva_project_SQL_secondary_final

---

# Analýza zadání
**Mám k dispozici 3 datové sady.**

1. a. průměrné mzdy a průměrný počet zaměstnaných osob v odvětvích (19 odvětví) v ČR za roky 2000 až 2021 po kvartálech (2021 pouze první 2 kvartály) - 6 880 záznamů
1. b. ceník potravin v ČR od ledna 2006 do prosince 2018 (vždy pro měření od - do jako timestamp) - 108 249 záznamů
2. číselníky ČR - kraje a okresy
3. číselníky zemí a ekonomik s parametry jako HDP, GINI index, počet obyvatel, údaje za roky 1960 až 2020

**Tyto datové sady reprezentované tabulkami se statistickými daty za určitá datová období je nutné vhodně agregovat tak, aby poskytly podklad pro zodpovězení výzkumných otázek.** 

---

# Analýza podkladových dat (tabulek)
**Posouzení vazby hlavních tabulek a číselníků, jejich obsahu (konzistence, NULL hodnoty, období).** 

## Tabulka mezd (payroll)
Analýzou tabulek a přiřazením názvů kategorií z číselníků jsem zjistil, že:
- hlavní tabulka czechia_payroll má ve sloupci unit_code přehozené kódy pro jednotku (80403 - Kč a 200 - tis. osob), které by měly odpovídat sloupci číselníku typu value_type_code (316 - Průměrný počet zaměstnaných osob a 5958 Průměrná hrubá mzda na zaměstnance). Na discordu ENGETO jsem našel řešení, jak hodnoty uvést do správného pořadí (přehození kódů v tabulce unit_code), což jsem v lokální databázi Postgres DB data_academy_content dle doporučení provedl.
SQL script, na základě kterého jsem odhalil nesrovnalost (propojení číselníků s hlavní tabulkou mezd) - v pracovním souboru
- řádky s hodnotou value_type_code = 316 nebudeme potřebovat (jen kód 5958) redukce na 3 440 záznamů
- některé řádky industry_branch_code (odvětví) je NULL - celkem 172 záznamů, pro každý rok a Q jsou tam 2 hodnoty (podle číselníku czechia_payroll_calculation vždy jedna hodnota fyzická a jedna přepočítaná), takže to vypadá na sumární průměrnou hodnotu za všechna odvětví
- v číselníku czechia_payroll_calculation jsou požívány kódy 100 = fyzický počet osob (kolik lidí skutečně pracuje) a 200 přepočtený počet osob (FTE kolik odpovídá plným úvazkům např. 2 lidé na poloviční úvazek = 1 přepočtená osoba), pro oba kódy jsou uváděny průměrné hrubé mzdy na zaměstnance pro každý rok, Q a odvětví

## Tabulka cen potravin (price)
Analýzou tabulek a přiřazením názvů kategorií z číselníků jsem zjistil, že:
- číselník czechia_price_category obsahuje kategorie potravin obsahuje názvy potravin, množstevní a měrnou jednotku - 27 záznamů
- číselník czechia_region obsahuje názvy krajů v ČR - 14 záznamů, pokud je region_code NULL, pak jde o sumární hodnotu pro danou kategorii potraviny (category_code) za celou ČR (ověřeno)
- hlavní tabulka czechia_price po odfiltrovani NULL hodnot ze sloupce region_code má 101 032 záznamů, tedy 7 217 záznamů se týká pravděpodobně jen celé ČR
- hlavní tabulka czechia_price ve sloupci value neobsahuje hodnotu NULL

## Tabulky countries, economies
Analýzou tabulek jsem zjistil, že:
- v tabulce countries vyberu evropské země přes continent = Europe
- tabulky countries a economies je možné spojit přes položku country 
- z tabulky použiji sloupce gdp, gini a population, nicméně pro ostatní země v Evropě nemám k dispozici údaje o cenách potravin a mzdách, tyto údaje pouze pro ČR v tabulkách czechia_price a czechia_payrol

---

# Příprava podkladových tabulek pro Výzkumné otázky
**Příprava primární a sekundární tabulky tak, aby z nich na základě SQL dotazů bylo možné zodpovědět definované otázky.**

SQL Skripty jsou uloženy v souboru Project1_SQL_skripty.sql a jsou označeny hlavičkou a logika odkomentována v řádcích, pokud je to potřeba.

## Primární tabulka t_petr_oliva_project_SQL_primary_final
Základní datový přehled, který slouží jako primární zdroj pro zodpovězení výzkumných otázek. Obsahuje průměrné roční mzdy a průměrné roční ceny vybraných potravin v České republice, rozdělené podle odvětví a kategorií potravin. 

**Zdroje dat:**

Mzdy: tabuly czechia_payroll + czechia_payroll_industry_branch

Ceny: taulky czechia_price + czechia_price_category

**Filtry:**

Mzdy 
- value_type_code = 5958 – průměrná hrubá mzda na zaměstnance
- calculation_code = 200 – přepočtený počet zaměstnanců (FTE), podle mého názoru více vypovídající, než použití kódu 100 (fyzický počet zaměstnanců)
- unit_code = 200 – Kč

Agregace po roce payroll_year (přes kvartály) a po odvětvích včetně industry_branch_code IS NULL (Celkem ČR).

Ceny
- region_code IS NULL – pouze ceny za celou ČR, kraje nejsou nutné

Agregace po roce (EXTRACT(YEAR FROM date_from)) a po kategoriích potravin category_code

## Sekundární tabulka t_petr_oliva_project_SQL_secondary_final

Podpůrný datový přehled, který slouží jako sekundární zdroj pro zodpovězení výzkumných otázek. Obsahuje roční GDP, GINI a počet obyvatel pouze pro státy z Evropy.

**Zdroje dat:** tabulky economies a countries

**Filtry:**

Jen evropské státy: continent = 'Europe'

Stejné roky jako v primární tabulce: 2006–2018

---

# Analýza pro jednotlivé výzkumné otázky
**Pro každou otázku zpracuji postup a logiku, jak jsem vyhodnocoval data připravená v podkladových tabulkách (primární a sekundární).**

## Výzkumná otázka č. 1
**Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?**

Pro každé odvětví potřebuji zjistit:
- jak se průměrná roční mzda vyvíjí v čase
- zda mzdy vždy meziročně rostou, nebo v některých letech klesají

Postup:
- vyberu pouze řádky s IS NOT NULL odvětvími, protože industry_branch_code IS NULL = průměrná mzda za celou ČR 
- pro každé odvětví (industry_branch_code) a rok(year) vyhodnocuji avg_salary
- funkce LAG() pro hodnotu mzdy v předchozím roce

Spočítám:
- absolutní rozdíl mezd pro Y a Y-1 jako salary_diff
- nastavím flag pro meziroční pokles mzdy (true/false)

Na základě toho pak pro každé odvětví:
- spočítám počet výskytů, kdy mzda poklesla (flag = true) - years_with_salary_decline
- pokud došlo alespoň k jednomu meziročnímu poklesu, zobrazím počáteční a koncový rok, kdy meziročnímu poklesu došlo - first_decline_year, last_decline_year

## Výzkumná otázka č. 2
**Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?**

Pro první a poslední společný rok (2006 a 2018) potřebuji zjisti pro definované potraviny (Mléko polotučné pasterované a Chléb konzumní kmínový) zjistit kupní sílu průměrné hrubé mzdy v ČR (za všechna odvětví).

Postup:
- vyfiltruji pouze řádky industry_branch_code IS NULL (mzda za celou ČR) a category_name pro chleba a mléko (výběr dvou konkrétních potravin) pro year 2006 a 2018 (první a poslední společný rok)
- vypočítám kupní sílu jako: purchasable_units = avg_salary / avg_price
- seřadím výstup podle názvu potraviny a roku

## Výzkumná otázka č. 3
**Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?**

Potřebuji seřadit kategorie potravin podle nejnižšího průměrného meziročního nárůstu cen (%) na základě výpočtu meziroční změny z avg_price a tyto meziroční změny pak zprůměrovat za celé sledované období pro každou kategorii potravin.

Postup:
- vyfiltruji pouze záznamy za celou ČR - industry_branch_code IS NULL
- přes funkci LAG() spočítám meziroční % změnu ceny yoy_growth = (avg_price - prev_price) / prev_price * 100 pro každou kategorii (category_code) a rok
- spočítám průměrné meziroční tempo změny ceny pro každou kategorii potravin za celé sledované období
- seřadím podle nejnižší hodnoty

## Výzkumná otázka č. 4
**Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?**

Potřebuji zjistit, zda v některém roce byl růst cen výrazně vyšší než růst mezd. „Výrazně“ znamená rozdíl > 10 procentních bodů. Analyzuji na agregované úrovni za celou ČR (průměrná cena všech potravin a průměrná hrubá mzda za celou ČR).

Postup:
- vyberu pouze řádky s industry_branch_code IS NULL (celá ČR)
- spočítám za každý rok avg_price = průměrná roční cena (přes všechny kategorie) avg_salary = průměrná roční mzda
- přes funkci LAG() spočítám meziroční price_growth_pct (% změna průměrné ceny potravin) a salary_growth_pct (% změna průměrné mzdy)
- spočítám rozdíl mezi % meziročními změnami průměrné ceny potravin a mezd diff_growth_pct = price_growth_pct - salary_growth_pct
- seřadím po letech a vyfiltruji na rozdíl větší než 10

## Výzkumná otázka č. 5
**Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?**

Potřebuji zjistit na základě dat pro Českou republiku (CZE) a vzájemně porovnat:
- růst HDP vs. růst mezd a cen ve stejném roce (t)
- růst HDP vs. růst mezd a cen v následujícím roce (t+1)
- spočítám meziroční změny (growth %)
- spočítám poměrové ukazatele, tedy kolik % změny mzdy/ceny připadá na 1 % růstu HDP
- pro výpočet potřebuji primární i sekundární tabulku, počítat budu jen pro ČR, protože pro ostatní státy Evropy nemám k dispozici data pro ceny potravin a mezd

Postup:
- spočítám roční průměrné mzdy a ceny potravin za ČR z primární tabulky
- spojím je s HDP pro ČR ze sekundární tabulky
- přes funkci LAG() spočítám meziroční gdp_growth_pct (% změna HDP), salary_growth_pct (% změna průměrné mzdy) a price_growth_pct (% změna průměrné ceny potravin)
- následně spočítám poměrové ukazatele salary_vs_gdp_growth = salary_growth_pct / gdp_growth_pct (poměr změny růstu mezd k HDP) a price_vs_gdp_growth = price_growth_pct / gdp_growth_pct (poměr změny růstu průměrných cen potravin k HDP)
- pro variantu t+1 spočítám stejné údaje a poměrové ukazatele, ale růst HDP z roku t porovnáme s růstem mezd a cen z roku t+1

Interpretace poměrových ukazatelů:
- pokud salary_vs_gdp_growth > 1, pak mzdy rostly rychleji než HDP
- pokud price_vs_gdp_growth > 1, pak ceny potravin rostly rychleji než HDP
- pokud ukazatel < 1, pak růst ukazatele byl pomalejší než HDP
- pokud ukazatel < 0, pak jeden z ukazatelů klesal, druhý stoupal

---

# Výsledky (řešení)
**Uvedeny interpretace výstupů ze specifických SQL dotazů a formulace odpovědi na výzkumné otázky vč. zdůvodnění, pokud je potřeba.**

## Výzkumné otázky

1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

**Mzdy ve všech odvětvích stále jen nerostou. Jsou odvětví, ve kterých v letech 2006 - 2018 došlo alespoň k jednomu meziročnímu poklesu průměrných hrubých mezd na zaměstnance (16 odvětví) a pouze ve 3 odvětvích nedošlo ve sledovaném období ani k jednomu meziročnímu poklesu (konkrétně v odvětvích Ostatní činnosti, Zdravotní a sociální péče a Zpracovatelský průmysl).**

2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

**V roce 2006, který je prvním sledovaným rokem společným pro průměrné mzdy a ceny potravin, si bylo možné z průměrné hrubé mzdy v ČR na obyvatele (19 536 Kč) kopit 1 212 kg chleba a 1 353 l mléka. Oproti tomu v roce 2018, který je posledním sledovaným rokem si bylo možné z průměrné hrubé mzdy v ČR na obyvatele (32 043 Kč) koupit 1 322 kg chleba a 1 617 l mléka. U obou potravin došlo k nárůstu ceny potravin, ale i mzdy, což v konečném důsledku umožnilo u obou potravin nakoupit v roce 2018 více jednotek než v roce 2006, tedy došlo ke zvýšení kupní síly obyvatelstva ČR.**

3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?

**Ve sledovaném období za léta 2006 až 2018 mezi 27 sledovanými kategoriemi potravin došlo k nejmenšímu nárůstu ceny u položky Cukr krystalový a to -1,92%. Tedy ve výsledku došlo ke zlevnění této položky.**

4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

**V žádném, ze sledovaných let 2006 - 2018 nedošlo k výraznému meziročnímu růstu cen potravin nad růst mezd. Nejvyšší nárůst cen oproti růstu mezd byl v roce 2013 a to o 5,23%.** 

5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

**Odpověď na tuto otázku se bude týkat pouze České republiky, protože pro ostatní státy Evropy nemáme k dispozici data o cenách potravin a mzdách. Pokud porovnáváme růst HDP vůči růstu mezd a cen potravin ve stejném roce t, pak většinou platí, že pokud roste HDP, rostou i mzdy a ceny potravin. Často rostou mzdy dokonce výrazněji, což podporuje hypotézu pozitivní korelace. Nicméně při porovnání růstu HDP vůči růstu mezd a cen potravin v následujícím roce t+1 (zpožděný efekt růstu HDP na růst cen potravin a mezd), pak většinou nelze najít stejný nebo podobný trend jako u předchozího porovnání. Neexistuje konzistentní zpožděný efekt růstu HDP na růst mezd a cen potravin – spíše lze pozorovat šum, statistickou nestabilitu.**

---

# Seznam souborů se skripty SQL

- Working Project1 z SQL ENGETO.sql -> pracovní soubor se skripty SQL pro analýzu a ověření struktury dat tabulek a číselníků, sestavování finálních SQL skriptů
- Project1_SQL_skripty.sql -> soubor se skripty pro vytvoření primární a sekundární tabulky pro výzkumné otázky a pro SQL skripty jednotlivých výzkumných otázek.
---
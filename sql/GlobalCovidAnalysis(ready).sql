/* =========================================================
   GLOBAL COVID ANALYSIS — SQL SCRIPT
   Database: GlobalCovidAnalysis

   Notes:
   - Keywords and function names are uppercase for consistency.
   - "continent IS NOT NULL" is used to restrict to country-level rows and avoid OWID aggregates.
   ========================================================= */

USE [GlobalCovidAnalysis];
GO


/* =========================================================
   SECTION 01 — DATA OVERVIEW & SANITY CHECKS

   Purpose:
   - Validate import quality
   - Separate country rows vs OWID aggregate rows (World/continents/EU/International)
   - Check uniqueness of (location, date) for safe joins
   ========================================================= */

-- 01.1 Row counts (quick health check)
SELECT 'CovidDeaths' AS table_name, COUNT_BIG(*) AS row_count
FROM CovidDeaths;

SELECT 'CovidVaccinations' AS table_name, COUNT_BIG(*) AS row_count
FROM CovidVaccinations;

-- 01.2 Distinct location counts
SELECT 'CovidDeaths' AS table_name, COUNT(DISTINCT location) AS distinct_locations
FROM CovidDeaths;

SELECT 'CovidVaccinations' AS table_name, COUNT(DISTINCT location) AS distinct_locations
FROM CovidVaccinations;

-- 01.3 Country rows vs aggregate rows (OWID)
SELECT
    'CovidDeaths' AS table_name,
    SUM(CASE WHEN continent IS NOT NULL THEN 1 ELSE 0 END) AS country_rows,
    SUM(CASE WHEN continent IS NULL THEN 1 ELSE 0 END) AS aggregate_rows
FROM CovidDeaths;

SELECT
    'CovidVaccinations' AS table_name,
    SUM(CASE WHEN continent IS NOT NULL THEN 1 ELSE 0 END) AS country_rows,
    SUM(CASE WHEN continent IS NULL THEN 1 ELSE 0 END) AS aggregate_rows
FROM CovidVaccinations;

-- 01.4 Which aggregate "locations" exist? (can inflate totals if not filtered)
SELECT TOP (20)
    location,
    COUNT_BIG(*) AS rows_count
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY rows_count DESC, location;

-- 01.5 Duplicate check on (location, date) — Deaths (avoid many-to-many join explosion)
SELECT
    location,
    [date],
    COUNT_BIG(*) AS cnt
FROM CovidDeaths
GROUP BY location, [date]
HAVING COUNT_BIG(*) > 1;

-- 01.6 Duplicate check on (location, date) — Vaccinations
SELECT
    location,
    [date],
    COUNT_BIG(*) AS cnt
FROM CovidVaccinations
GROUP BY location, [date]
HAVING COUNT_BIG(*) > 1;

-- 01.7 Date range checks
SELECT 'CovidDeaths' AS table_name, MIN([date]) AS min_date, MAX([date]) AS max_date
FROM CovidDeaths;

SELECT 'CovidVaccinations' AS table_name, MIN([date]) AS min_date, MAX([date]) AS max_date
FROM CovidVaccinations;

-- 01.8 Missingness check (core fields) — country-level only
SELECT
    SUM(CASE WHEN total_cases  IS NULL THEN 1 ELSE 0 END) AS null_total_cases,
    SUM(CASE WHEN new_cases    IS NULL THEN 1 ELSE 0 END) AS null_new_cases,
    SUM(CASE WHEN total_deaths IS NULL THEN 1 ELSE 0 END) AS null_total_deaths,
    SUM(CASE WHEN new_deaths   IS NULL THEN 1 ELSE 0 END) AS null_new_deaths,
    SUM(CASE WHEN population   IS NULL THEN 1 ELSE 0 END) AS null_population
FROM CovidDeaths
WHERE continent IS NOT NULL;

SELECT
    SUM(CASE WHEN new_vaccinations   IS NULL THEN 1 ELSE 0 END) AS null_new_vaccinations,
    SUM(CASE WHEN total_vaccinations IS NULL THEN 1 ELSE 0 END) AS null_total_vaccinations
FROM CovidVaccinations
WHERE continent IS NOT NULL;

-- 01.9 Data type checks (why CAST/CONVERT/TRY_CONVERT may be needed)
SELECT
    t.name  AS table_name,
    c.name  AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale
FROM sys.columns c
JOIN sys.types ty
    ON c.user_type_id = ty.user_type_id
JOIN sys.tables t
    ON c.object_id = t.object_id
WHERE t.name IN ('CovidDeaths', 'CovidVaccinations')
  AND c.name IN ('total_deaths', 'new_deaths', 'new_vaccinations', 'total_cases', 'new_cases', 'population')
ORDER BY t.name, c.name;

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidDeaths'
ORDER BY ORDINAL_POSITION;

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidVaccinations'
ORDER BY ORDINAL_POSITION;
GO



/* =========================================================
   SECTION 02 — BASE DATASET & STARTING COLUMNS

   Purpose:
   - Create a clean “starter dataset” for analysis.
   - Focus on KPI-driving columns only.
   - Filter to country-level rows (continent IS NOT NULL).
   ========================================================= */

-- 02.1 Quick preview (avoid printing full table)
SELECT TOP (50)
    location,
    [date],
    total_cases,
    new_cases,
    total_deaths,
    population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, [date];

-- 02.2 Core columns (original query preserved logically; formatted consistently)
SELECT
    location,
    [date],
    total_cases,
    new_cases,
    total_deaths,
    population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, [date];
GO



/* =========================================================
   SECTION 03 — TOTAL CASES vs TOTAL DEATHS (DEATH PERCENTAGE)

   Purpose:
   - Compute a CFR-like metric: total_deaths / total_cases * 100
   - Track changes over time for a chosen country.
   ========================================================= */

SELECT
    location,
    [date],
    total_cases,
    total_deaths,
    (total_deaths / total_cases) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%states%'
  AND continent IS NOT NULL
ORDER BY location, [date];
GO



/* =========================================================
   SECTION 04 — TOTAL CASES vs POPULATION (PERCENT POPULATION INFECTED)

   Purpose:
   - Compute: total_cases / population * 100
   - Track infection penetration over time.
   ========================================================= */

SELECT
    location,
    [date],
    population,
    total_cases,
    (total_cases / population) * 100 AS PercentPopulationInfected
FROM CovidDeaths
ORDER BY location, [date];
GO



/* =========================================================
   SECTION 05 — HIGHEST INFECTION RATE (COUNTRY RANKING)

   Purpose:
   - Rank countries by peak reported infection rate relative to population.
   - Uses MAX(total_cases) to summarize each country into a single “peak” row.
   ========================================================= */

SELECT
    location,
    population,
    MAX(total_cases) AS HighestInfectionCount,
    MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;
GO



/* =========================================================
   SECTION 06 — HIGHEST DEATH COUNT (COUNTRY RANKING)

   Purpose:
   - Rank countries by highest reported total deaths.
   - CAST is used because some imports store numeric fields as text.
   ========================================================= */

SELECT
    location,
    MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;
GO



/* =========================================================
   SECTION 07 — CONTINENT BREAKDOWN (HIGHEST DEATH COUNT)

   Purpose:
   - Aggregate deaths at the continent level for high-level comparison.
   - Supports Tableau drill-down (Continent → Country).
   ========================================================= */

SELECT
    continent,
    MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;
GO



/* =========================================================
   SECTION 08 — GLOBAL NUMBERS

   Purpose:
   - Compute global totals (cases, deaths) and global death percentage.
   - Uses country-level rows only (continent IS NOT NULL) to avoid double counting aggregates.
   ========================================================= */

SELECT
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS INT)) AS total_deaths,
    SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY total_cases, total_deaths;
GO



/* =========================================================
   SECTION 09 — TOTAL POPULATION vs VACCINATIONS (JOIN + ROLLING)

   Purpose:
   - Join deaths and vaccinations tables on (location, date).
   - Compute a rolling (cumulative) vaccination DOSE count using a window function.
   - Note: new_vaccinations is doses administered; doses-per-population can exceed 100%.
   ========================================================= */

SELECT
    dea.continent,
    dea.location,
    dea.[date],
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
        PARTITION BY dea.location
        ORDER BY dea.location, dea.[date]
    ) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
   AND dea.[date]   = vac.[date]
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.[date];
GO



/* =========================================================
   SECTION 10 — CTE: POPULATION vs VACCINATIONS (PERCENT VACCINATED)

   Purpose:
   - Wrap the rolling vaccination calculation inside a CTE.
   - Then compute percent vaccinated using the derived rolling column.
   ========================================================= */

-- 10.1 CTE (original output)
WITH PopvsVac (Continent, Location, [Date], Population, New_Vaccinations, RollingPeopleVaccinated) AS
(
    SELECT
        dea.continent,
        dea.location,
        dea.[date],
        dea.population,
        vac.new_vaccinations,
        SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
            PARTITION BY dea.location
            ORDER BY dea.location, dea.[date]
        ) AS RollingPeopleVaccinated
    FROM CovidDeaths dea
    JOIN CovidVaccinations vac
        ON dea.location = vac.location
       AND dea.[date]   = vac.[date]
    WHERE dea.continent IS NOT NULL
)
SELECT
    *,
    (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM PopvsVac;
GO

-- 10.2 CTE filtered to non-null core fields (your added filter version)
WITH PopvsVac (Continent, Location, [Date], Population, New_Vaccinations, RollingPeopleVaccinated) AS
(
    SELECT
        dea.continent,
        dea.location,
        dea.[date],
        dea.population,
        vac.new_vaccinations,
        SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
            PARTITION BY dea.location
            ORDER BY dea.location, dea.[date]
        ) AS RollingPeopleVaccinated
    FROM CovidDeaths dea
    JOIN CovidVaccinations vac
        ON dea.location = vac.location
       AND dea.[date]   = vac.[date]
    WHERE dea.continent IS NOT NULL
)
SELECT
    *,
    (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM PopvsVac
WHERE New_Vaccinations IS NOT NULL
  AND RollingPeopleVaccinated IS NOT NULL
  AND Population IS NOT NULL;
GO



/* =========================================================
   SECTION 11 — TEMP TABLE: PERCENT POPULATION VACCINATED

   Purpose:
   - Store the rolling vaccination results in a temp table.
   - Then compute percent vaccinated from the temp table.
   - Demonstrates temp table workflow and re-runnable scripts.
   ========================================================= */

DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    [Date] DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.[date],
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
        PARTITION BY dea.location
        ORDER BY dea.location, dea.[date]
    ) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
   AND dea.[date]   = vac.[date];

SELECT
    *,
    (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;
GO



/* =========================================================
   SECTION 12 — CREATE OR ALTER VIEW: PERCENT POPULATION VACCINATED

   Purpose:
   - Persist the vaccination rolling calculation as a view.
   - Reuse it later for Tableau visualizations or downstream analysis.
   - Note: ORDER BY is not allowed inside a view definition.
   ========================================================= */

CREATE OR ALTER VIEW PercentPopulationVaccinated AS
SELECT
    dea.continent,
    dea.location,
    dea.[date],
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
        PARTITION BY dea.location
        ORDER BY dea.location, dea.[date]
    ) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
   AND dea.[date]   = vac.[date]
WHERE dea.continent IS NOT NULL;
GO



/* =========================================================
   SECTION 13 — VALIDATE & USE THE VIEW

   Purpose:
   - Validate that the view returns data as expected.
   - Provide ready-to-use outputs for Tableau (trend + latest snapshot).
   ========================================================= */

-- 13.1 Quick preview
SELECT TOP (50)
    *
FROM PercentPopulationVaccinated
ORDER BY location, [date];

-- 13.2 Single-country trend check
SELECT
    continent,
    location,
    [date],
    population,
    new_vaccinations,
    RollingPeopleVaccinated,
    (RollingPeopleVaccinated / NULLIF(population, 0)) * 100 AS PercentPopulationVaccinated
FROM PercentPopulationVaccinated
WHERE location = 'Turkey'
ORDER BY [date];

-- 13.3 Latest snapshot per country
WITH Latest AS
(
    SELECT
        continent,
        location,
        [date],
        population,
        RollingPeopleVaccinated,
        ROW_NUMBER() OVER (PARTITION BY location ORDER BY [date] DESC) AS rn
    FROM PercentPopulationVaccinated
)
SELECT
    continent,
    location,
    [date] AS latest_date,
    population,
    RollingPeopleVaccinated AS total_vaccinations_rolling,
    (RollingPeopleVaccinated / NULLIF(population, 0)) * 100 AS PercentPopulationVaccinated
FROM Latest
WHERE rn = 1
ORDER BY PercentPopulationVaccinated DESC;
GO



/* =========================================================
   SECTION 14 — EXPORT-READY DATASETS (TABLEAU PUBLIC)

   Purpose:
   - Generate CSV-friendly extracts for Tableau Public.
   - Includes global daily KPIs, global totals, and latest country snapshots.
   ========================================================= */

-- 14.1 Global daily KPIs
SELECT
    [date],
    SUM(TRY_CONVERT(FLOAT, new_cases)) AS global_new_cases,
    SUM(TRY_CONVERT(FLOAT, new_deaths)) AS global_new_deaths,
    (SUM(TRY_CONVERT(FLOAT, new_deaths)) / NULLIF(SUM(TRY_CONVERT(FLOAT, new_cases)), 0)) * 100 AS global_death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY [date]
ORDER BY [date];

-- 14.2 Global totals (single-row KPI cards)
SELECT
    SUM(TRY_CONVERT(FLOAT, new_cases)) AS global_total_cases,
    SUM(TRY_CONVERT(FLOAT, new_deaths)) AS global_total_deaths,
    (SUM(TRY_CONVERT(FLOAT, new_deaths)) / NULLIF(SUM(TRY_CONVERT(FLOAT, new_cases)), 0)) * 100 AS global_death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL;

-- 14.3 Latest infection rate by country
WITH LatestCountry AS
(
    SELECT
        location,
        continent,
        [date],
        TRY_CONVERT(FLOAT, total_cases) AS total_cases_num,
        TRY_CONVERT(FLOAT, population) AS population_num,
        ROW_NUMBER() OVER (PARTITION BY location ORDER BY [date] DESC) AS rn
    FROM CovidDeaths
    WHERE continent IS NOT NULL
)
SELECT
    continent,
    location,
    [date] AS latest_date,
    total_cases_num AS total_cases,
    population_num AS population,
    (total_cases_num / NULLIF(population_num, 0)) * 100 AS percent_population_infected
FROM LatestCountry
WHERE rn = 1
ORDER BY percent_population_infected DESC;

-- 14.4 Latest death percentage by country
WITH LatestCountry AS
(
    SELECT
        location,
        continent,
        [date],
        TRY_CONVERT(FLOAT, total_cases) AS total_cases_num,
        TRY_CONVERT(FLOAT, total_deaths) AS total_deaths_num,
        ROW_NUMBER() OVER (PARTITION BY location ORDER BY [date] DESC) AS rn
    FROM CovidDeaths
    WHERE continent IS NOT NULL
)
SELECT
    continent,
    location,
    [date] AS latest_date,
    total_cases_num AS total_cases,
    total_deaths_num AS total_deaths,
    (total_deaths_num / NULLIF(total_cases_num, 0)) * 100 AS death_percentage
FROM LatestCountry
WHERE rn = 1
ORDER BY death_percentage DESC;

-- 14.5 Continent summary (max cumulative deaths)
SELECT
    continent,
    MAX(TRY_CONVERT(FLOAT, total_deaths)) AS total_deaths
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_deaths DESC;

-- 14.6 Latest vaccination snapshot by country (from the view)
WITH LatestVax AS
(
    SELECT
        continent,
        location,
        [date],
        population,
        RollingPeopleVaccinated,
        ROW_NUMBER() OVER (PARTITION BY location ORDER BY [date] DESC) AS rn
    FROM PercentPopulationVaccinated
)
SELECT
    continent,
    location,
    [date] AS latest_date,
    population,
    RollingPeopleVaccinated AS rolling_people_vaccinated,
    (RollingPeopleVaccinated / NULLIF(population, 0)) * 100 AS percent_population_vaccinated
FROM LatestVax
WHERE rn = 1
ORDER BY percent_population_vaccinated DESC;

-- 14.7 Vaccination trend for a single country
SELECT
    [date],
    location,
    population,
    RollingPeopleVaccinated,
    (RollingPeopleVaccinated / NULLIF(population, 0)) * 100 AS percent_population_vaccinated
FROM PercentPopulationVaccinated
WHERE location = 'Albania'
ORDER BY [date];
GO



/* =========================================================
   SECTION 15 — CREATE OR ALTER VIEW: 7-DAY MOVING AVERAGE

   Purpose:
   - Smooth daily volatility using 7-day moving averages.
   - Ideal for trend charts in Tableau.
   ========================================================= */

CREATE OR ALTER VIEW vw_country_daily_7day AS
SELECT
    continent,
    location,
    [date],
    TRY_CONVERT(FLOAT, population) AS population,
    TRY_CONVERT(FLOAT, new_cases)  AS new_cases,
    TRY_CONVERT(FLOAT, new_deaths) AS new_deaths,
    AVG(TRY_CONVERT(FLOAT, new_cases)) OVER (
        PARTITION BY location
        ORDER BY [date]
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS new_cases_7day_avg,
    AVG(TRY_CONVERT(FLOAT, new_deaths)) OVER (
        PARTITION BY location
        ORDER BY [date]
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS new_deaths_7day_avg
FROM CovidDeaths
WHERE continent IS NOT NULL;
GO



/* =========================================================
   SECTION 16 — CREATE OR ALTER VIEW: PER 100K METRICS

   Purpose:
   - Normalize cases and deaths by population (per 100k people).
   - Better cross-country comparisons and maps.
   ========================================================= */

CREATE OR ALTER VIEW vw_country_daily_per100k AS
SELECT
    continent,
    location,
    [date],
    TRY_CONVERT(FLOAT, population) AS population,
    TRY_CONVERT(FLOAT, total_cases)  AS total_cases,
    TRY_CONVERT(FLOAT, total_deaths) AS total_deaths,
    TRY_CONVERT(FLOAT, new_cases)    AS new_cases,
    TRY_CONVERT(FLOAT, new_deaths)   AS new_deaths,
    (TRY_CONVERT(FLOAT, total_cases)  / NULLIF(TRY_CONVERT(FLOAT, population), 0)) * 100000 AS total_cases_per_100k,
    (TRY_CONVERT(FLOAT, total_deaths) / NULLIF(TRY_CONVERT(FLOAT, population), 0)) * 100000 AS total_deaths_per_100k,
    (TRY_CONVERT(FLOAT, new_cases)    / NULLIF(TRY_CONVERT(FLOAT, population), 0)) * 100000 AS new_cases_per_100k,
    (TRY_CONVERT(FLOAT, new_deaths)   / NULLIF(TRY_CONVERT(FLOAT, population), 0)) * 100000 AS new_deaths_per_100k
FROM CovidDeaths
WHERE continent IS NOT NULL;
GO



/* =========================================================
   SECTION 18 — COUNTRY SEGMENTATION (ADJUSTED THRESHOLDS)

   Purpose:
   - Segment countries into categories based on normalized metrics.
   - Uses quartiles (NTILE) and broadens "High/Low" to top/bottom 50% to reduce empty segments.
   ========================================================= */

WITH Latest AS
(
    SELECT
        d.continent,
        d.location,
        d.[date],
        TRY_CONVERT(FLOAT, d.population) AS population,
        TRY_CONVERT(FLOAT, d.total_cases)  AS total_cases,
        TRY_CONVERT(FLOAT, d.total_deaths) AS total_deaths,
        ROW_NUMBER() OVER (PARTITION BY d.location ORDER BY d.[date] DESC) AS rn
    FROM CovidDeaths d
    WHERE d.continent IS NOT NULL
),
Snap AS
(
    SELECT
        continent,
        location,
        [date] AS latest_date,
        population,
        total_cases,
        total_deaths,
        (total_cases  / NULLIF(population, 0)) * 100000 AS total_cases_per_100k,
        (total_deaths / NULLIF(population, 0)) * 100000 AS total_deaths_per_100k
    FROM Latest
    WHERE rn = 1
),
Q AS
(
    SELECT
        *,
        NTILE(4) OVER (ORDER BY total_cases_per_100k  DESC) AS cases_q,
        NTILE(4) OVER (ORDER BY total_deaths_per_100k DESC) AS deaths_q
    FROM Snap
)
SELECT
    continent,
    location,
    latest_date,
    total_cases_per_100k,
    total_deaths_per_100k,
    cases_q,
    deaths_q,
    CASE
        WHEN cases_q IN (1, 2) AND deaths_q IN (1, 2) THEN 'High Cases / High Deaths'
        WHEN cases_q IN (1, 2) AND deaths_q IN (3, 4) THEN 'High Cases / Low Deaths'
        WHEN cases_q IN (3, 4) AND deaths_q IN (1, 2) THEN 'Low Cases / High Deaths'
        WHEN cases_q IN (3, 4) AND deaths_q IN (3, 4) THEN 'Low Cases / Low Deaths'
        ELSE 'Mid Cluster'
    END AS country_segment
FROM Q
ORDER BY country_segment, total_deaths_per_100k DESC;
GO

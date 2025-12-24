# 📘 Data Dictionary — GlobalCovidAnalysis

This project uses two main tables:
- `CovidDeaths`
- `CovidVaccinations`

IMPORTANT PROJECT RULE:
- `continent IS NOT NULL` → country-level rows
- `continent IS NULL` → OWID aggregate rows (World / continents / EU / International)

Import note:
- Some numeric fields may be imported as NVARCHAR from Excel.
- For safe calculations, use `TRY_CONVERT()`, `CAST()`, or `CONVERT()`.

---

## 1) Table: CovidDeaths

Purpose:
- Daily time series for COVID cases, deaths, population, and related indicators by location.

Grain (Row Level):
- 1 row per (location, date)

Core Columns Used in This Project:

| Column         | Expected Type                 | Description                                              | Typical Use |
|---------------|-------------------------------|----------------------------------------------------------|------------|
| location      | NVARCHAR                      | Country name or aggregate group name                      | Join key, grouping, filters |
| continent     | NVARCHAR / NULL               | Continent for countries; NULL for aggregates              | Filter: `continent IS NOT NULL` |
| date          | DATE / DATETIME               | Observation date                                          | Time series, join key |
| population    | NUMERIC / FLOAT               | Population for the location                               | % infected, per-100k normalization |
| total_cases   | NUMERIC / FLOAT               | Cumulative confirmed cases up to date                     | Infection rate, latest snapshots |
| new_cases     | NUMERIC / FLOAT               | New confirmed cases on date                               | Trends, global totals, 7-day avg |
| total_deaths  | NUMERIC / FLOAT (often text)  | Cumulative reported deaths up to date                     | Death %, rankings |
| new_deaths    | NUMERIC / FLOAT (often text)  | New reported deaths on date                               | Trends, global totals, 7-day avg |

Other Columns (May Exist):
- Depending on the dataset version, this table may include many additional fields such as:
  iso_code, reproduction_rate, icu_patients, hosp_patients, median_age,
  aged_65_older, aged_70_older, gdp_per_capita, diabetes_prevalence,
  female_smokers, male_smokers, life_expectancy, human_development_index, etc.
- These are not required for the core KPIs but can be used for extensions.

---

## 2) Table: CovidVaccinations

Purpose:
- Daily vaccination time series by location (countries + aggregates).

Grain (Row Level):
- 1 row per (location, date)

Core Columns Used in This Project:

| Column             | Expected Type                 | Description                                           | Typical Use |
|-------------------|-------------------------------|-------------------------------------------------------|------------|
| location          | NVARCHAR                      | Country name or aggregate group name                  | Join key, grouping |
| continent         | NVARCHAR / NULL               | Continent for countries; NULL for aggregates          | Filtering |
| date              | DATE / DATETIME               | Observation date                                      | Join key, trends |
| new_vaccinations  | NUMERIC / FLOAT (often text)  | New vaccine doses administered on date                | Rolling (cumulative) vaccination |
| total_vaccinations| NUMERIC / FLOAT               | Total doses administered up to date                   | Optional KPI |

Interpretation Note (Very Important):
- `new_vaccinations` is usually DOSE-based, not unique people.
- A rolling cumulative sum of doses may exceed population, so
  (rolling doses / population) * 100 can be greater than 100%.

---

## 3) Join Keys & Relationships

Join Logic:
- Join on:
  - location
  - date

Example (as plain text):
- FROM CovidDeaths dea
  JOIN CovidVaccinations vac
    ON dea.location = vac.location
   AND dea.date = vac.date

Assumption:
- (location, date) is unique in each table (validated via duplicate checks).

---

## 4) Derived Metrics (Created in the Project)

DeathPercentage (CFR-like):
- (total_deaths / total_cases) * 100

PercentPopulationInfected:
- (total_cases / population) * 100

RollingPeopleVaccinated (dose-based rolling sum):
- SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY date)

Per 100k Metrics (Normalized Comparison):
- (total_cases  / population) * 100000
- (total_deaths / population) * 100000
- (new_cases    / population) * 100000
- (new_deaths   / population) * 100000

7-day Moving Averages (Trend Smoothing):
- AVG(new_cases)  OVER (PARTITION BY location ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
- AVG(new_deaths) OVER (PARTITION BY location ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)

---

## 5) Views Created (BI Layer)

| View Name                    | Description                       | Key Outputs |
|-----------------------------|-----------------------------------|------------|
| PercentPopulationVaccinated | Join + rolling vaccinations        | location, date, population, new_vaccinations, RollingPeopleVaccinated |
| vw_country_daily_7day       | Smoothed daily trends (7-day avg)  | new_cases_7day_avg, new_deaths_7day_avg |
| vw_country_daily_per100k    | Normalized metrics per 100k        | total/new cases & deaths per 100k |


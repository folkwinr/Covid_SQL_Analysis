# 📘 Data Dictionary — GlobalCovidAnalysis

This project uses two tables:
- `CovidDeaths`
- `CovidVaccinations`

Notes:
- Most analysis uses **country-level rows only**:
  - `continent IS NOT NULL`
- Many numeric fields may import as text from Excel (NVARCHAR).  
  Use `TRY_CONVERT()` / `CAST()` / `CONVERT()` when needed.

---

## 1) Table: `CovidDeaths`

### Purpose
Daily country + aggregate time series for COVID cases, deaths, population, and related indicators.

### Grain (Row Level)
One row per **(location, date)**.

### Core Columns Used in This Project

| Column | Type (expected) | Description | Typical Use |
|---|---|---|---|
| `location` | NVARCHAR | Country name or aggregate group name (e.g., World) | Join key, filters, grouping |
| `continent` | NVARCHAR / NULL | Continent for countries; NULL for aggregate rows | Country filtering (`IS NOT NULL`) |
| `date` | DATE / DATETIME | Observation date | Time series, join key |
| `population` | NUMERIC / FLOAT | Population of the location | % infected, per-100k metrics |
| `total_cases` | NUMERIC / FLOAT | Cumulative confirmed cases up to date | Infection rate, latest snapshots |
| `new_cases` | NUMERIC / FLOAT | New confirmed cases on date | Global totals, trends, 7-day avg |
| `total_deaths` | NUMERIC / FLOAT (often text on import) | Cumulative reported deaths up to date | Death %, rankings |
| `new_deaths` | NUMERIC / FLOAT (often text on import) | New deaths on date | Global totals, 7-day avg |

### Additional Common Columns (May Exist)
Depending on dataset version, you may also see fields like:
- `iso_code`
- `reproduction_rate`
- `icu_patients`, `hosp_patients`
- `median_age`, `aged_65_older`, `aged_70_older`
- `gdp_per_capita`
- `diabetes_prevalence`
- `female_smokers`, `male_smokers`
- `life_expectancy`
- `human_development_index`
- and other health/system indicators

These were not required for the core portfolio KPIs but can be used for extensions.

---

## 2) Table: `CovidVaccinations`

### Purpose
Daily vaccination time series per location (countries + aggregate rows).

### Grain (Row Level)
One row per **(location, date)**.

### Core Columns Used in This Project

| Column | Type (expected) | Description | Typical Use |
|---|---|---|---|
| `location` | NVARCHAR | Country name or aggregate group name | Join key, grouping |
| `continent` | NVARCHAR / NULL | Continent for countries; NULL for aggregates | Filtering |
| `date` | DATE / DATETIME | Observation date | Join key, trends |
| `new_vaccinations` | NUMERIC / FLOAT (often text on import) | New vaccine doses administered on date | Rolling cumulative vaccination |
| `total_vaccinations` | NUMERIC / FLOAT (often NULL early) | Total doses administered up to date | Optional KPI |

### Important Interpretation Note
- `new_vaccinations` is typically **dose-based**, not unique people.
- A rolling sum of doses can exceed population, producing >100% when divided by population.

---

## 3) Join Keys & Relationships

### Join Logic
We join the two tables on:

- `location`
- `date`

Example:
```sql
FROM CovidDeaths dea
JOIN CovidVaccinations vac
  ON dea.location = vac.location
 AND dea.date = vac.date

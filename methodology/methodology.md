# 🧪 Methodology — Global Covid Analysis (SQL Portfolio Project)

## 1) Data Sources & Scope
We used two tables inside the **GlobalCovidAnalysis** database:
- **CovidDeaths** → cases, deaths, population, continent, date-level time series
- **CovidVaccinations** → vaccination metrics by location and date

**Time granularity:** daily  
**Geography:** global (country-level analysis)

---

## 2) Data Filtering Strategy (Critical Rule)
This dataset contains both **countries** and **OWID aggregate rows** (World, continents, EU, etc.).

To avoid double counting, the project follows this rule:

- `continent IS NOT NULL` → **country-level rows** (main analysis)
- `continent IS NULL` → **aggregate rows** (used only when explicitly needed)

So, most queries start with:

    WHERE continent IS NOT NULL

---

## 3) Data Quality Checks (Sanity Checks)
Before any KPI work, we validated the dataset to ensure reliability:

### 3.1 Row & Coverage Checks
- total row counts for both tables
- number of distinct locations
- country rows vs aggregate rows distribution
- min / max date range (to confirm time-series completeness)

### 3.2 Join Safety Checks
Because we join tables on **(location, date)**, we verified:
- duplicates in (location, date) in **CovidDeaths**
- duplicates in (location, date) in **CovidVaccinations**

Goal:
- avoid many-to-many joins that can inflate results.

### 3.3 Missing Data Checks
We measured NULL counts in key columns:
- deaths table: total_cases, new_cases, total_deaths, new_deaths, population
- vaccination table: new_vaccinations, total_vaccinations

Goal:
- understand where metrics may be missing and why some countries/dates may be excluded.

### 3.4 Data Type Checks
Some numeric fields can import as NVARCHAR (common in Excel imports).
We checked schema and handled this using:
- `CAST`, `CONVERT`, `TRY_CONVERT`

Goal:
- avoid calculation errors and make KPIs consistent.

---

## 4) KPI Definitions (Core Metrics)
We defined consistent KPIs for the project.

### 4.1 Death Percentage (CFR-like)
Formula:

    DeathPercentage = (total_deaths / total_cases) * 100

Use:
- country-level trend over time
- comparison across countries (with caution)

Notes:
- influenced by reporting/testing differences, not “true risk”.

### 4.2 Percent Population Infected
Formula:

    PercentPopulationInfected = (total_cases / population) * 100

Use:
- fair comparison between countries (population-adjusted)
- trend charts and maps

### 4.3 Global Totals (Cases, Deaths, Death %)
We used daily values to build global totals:

- total_cases = SUM(new_cases)
- total_deaths = SUM(new_deaths)
- global_death_percentage = total_deaths / total_cases * 100

We used country rows only to avoid double counting.

---

## 5) Joining Strategy (Deaths + Vaccinations)
We combined both tables with an inner join:

- key: `location`, `date`
- left side: **CovidDeaths** (for population + geography)
- right side: **CovidVaccinations** (for vaccination fields)

Goal:
- create one analysis-ready dataset for vaccination dashboards.

---

## 6) Vaccination Method (Rolling Cumulative)
We created a rolling vaccination measure using a window function:

    RollingPeopleVaccinated =
      SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY date)

Why:
- shows cumulative progress over time
- demonstrates advanced SQL window functions

Important interpretation:
- this is usually dose-based (not unique people),
- so `RollingPeopleVaccinated / population` may exceed **100%**.

---

## 7) Reusable Calculation Patterns
Some calculations require two steps (because aliases cannot be reused in the same SELECT).
We demonstrated two professional approaches:

### 7.1 CTE (Common Table Expression)
- build the rolling vaccination column in the CTE
- calculate percent vaccinated in the outer SELECT

### 7.2 Temp Table
- insert the rolling results into a temp table
- run final calculations on the temp table

Goal:
- show real-world SQL workflow and reusability.

---

## 8) BI-Ready Outputs (Views)
We created **views** as reusable layers for Tableau and future analysis.

### 8.1 PercentPopulationVaccinated
Contains:
- joined dataset
- rolling vaccination count

### 8.2 vw_country_daily_7day
Contains:
- 7-day moving average for new cases and new deaths

Why:
- smooth daily noise
- better line charts

### 8.3 vw_country_daily_per100k
Contains:
- cases/deaths per 100k (total and daily)

Why:
- fair cross-country comparison
- better maps and rankings

---

## 9) Country Segmentation (Quartiles)
We created quartile-based segmentation using:

- `NTILE(4)` on cases per 100k
- `NTILE(4)` on deaths per 100k

Then we labeled segments:
- High Cases / High Deaths
- High Cases / Low Deaths
- Low Cases / High Deaths
- Low Cases / Low Deaths

Why:
- avoids arbitrary thresholds
- creates dashboard-friendly clustering and storytelling

---

## 10) Outputs & Use in Tableau (How to Visualize)
The methodology is designed to produce Tableau-ready datasets for:
- global daily trends
- country rankings
- continent drill-down dashboards
- per-100k maps
- vaccination progress lines
- segmented country clusters

---

## ✅ Summary of Why This Methodology is Strong
- clear country vs aggregate separation (prevents wrong totals)
- join-safety validation (prevents inflated results)
- population-normalized KPIs (fair comparisons)
- rolling vaccination logic (real-world window function skill)
- reusable views (clean BI pipeline)
- segmentation (adds insight + storytelling)


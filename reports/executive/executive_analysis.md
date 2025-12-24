# 🌍 Global Covid Analysis — Executive Summary (B1–B2 English)

## 🎯 Project Goal
This SQL portfolio project explores **global COVID-19 data** to understand:
- how cases and deaths changed over time,
- how countries compare fairly (using population-based rates),
- how vaccination progress looks by country,
- and how to prepare clean outputs for **Tableau dashboards**.

We used two tables:
- **CovidDeaths** *(cases, deaths, population, continent)*
- **CovidVaccinations** *(vaccinations, people vaccinated)*

---

## 🗂️ Data Setup

### ✅ Database
- **GlobalCovidAnalysis**

### ✅ Tables
- **CovidDeaths**
- **CovidVaccinations**

### ✅ Key Rule (Avoid Double Counting)
The dataset includes both **countries** and **OWID aggregate rows** *(World, continents, EU, etc.)*.  
To avoid incorrect totals, we separate them:

- `continent IS NOT NULL` → **country-level rows**
- `continent IS NULL` → **aggregate rows** *(World / continents / EU / International)*

So most analysis queries use:
```sql
WHERE continent IS NOT NULL
```

---

## 🔎 What We Did (Workflow)

### 1) 🧪 Data Quality Checks (Sanity Checks)
Before analysis, we validated the dataset to avoid wrong results:

- ✅ checked row counts in both tables
- ✅ checked distinct location counts
- ✅ split country rows vs aggregate rows
- ✅ checked duplicates in `(location, date)` *(important for safe joins)*
- ✅ checked min/max dates *(time-series coverage)*
- ✅ checked NULLs in important fields
- ✅ checked data types *(some numeric columns may be NVARCHAR after import)*

#### ✅ Why this matters
- prevents join explosions
- avoids double counting
- explains why some results may look empty
- shows a professional workflow in a portfolio

---

### 2) 📊 Core Analysis (Cases, Deaths, Population)

#### ✅ A) Death Percentage (CFR-like)
We calculated:
```text
DeathPercentage = (total_deaths / total_cases) * 100
```

**Purpose:**
- understand how the reported death ratio changes over time *(per country)*

⚠️ **Important note:**
- this is not “true risk” because reporting and testing change over time

---

#### ✅ B) Percent Population Infected
We calculated:
```text
PercentPopulationInfected = (total_cases / population) * 100
```

**Purpose:**
- see how much of the population is reported as infected
- compare countries more fairly than using raw case counts

---

#### ✅ C) Country Rankings
We created ranking outputs such as:
- 🏆 highest infection rate *(peak % infected)*
- 🏆 highest total death count

**Purpose:**
- quickly identify top countries by these measures
- useful for bar charts and tables in Tableau

---

#### ✅ D) Continent Breakdown
We grouped results by continent *(country-level rows only)*.

**Purpose:**
- high-level comparison *(continent vs continent)*
- supports Tableau drill-down: **Continent → Country**

---

#### ✅ E) Global Numbers
We calculated global totals using:
- `SUM(new_cases)`
- `SUM(new_deaths)`
- global death percentage

We used **country-level rows only** to avoid double counting aggregates.

**Purpose:**
- create global KPI cards and global trend charts

---

### 3) 💉 Vaccination Analysis (Join + Rolling Window)

#### ✅ A) Join Tables (Deaths + Vaccinations)
We joined on:
- `location`
- `date`

**Purpose:**
- combine population + vaccination metrics in one output

---

#### ✅ B) Rolling Vaccinations (Window Function)
We created:
```sql
RollingPeopleVaccinated =
SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY date)
```

**Purpose:**
- show cumulative vaccination progress over time per country
- demonstrate window function skill *(important in SQL)*

⚠️ **Important note (why % can exceed 100):**
- `new_vaccinations` is usually **dose-based** *(not people)*
- people may receive multiple doses
- so **rolling doses / population** can be above **100%**

---

### 4) 🧠 CTE + Temp Table (Reusable Calculations)

#### ✅ A) CTE
We used a CTE to calculate % vaccinated using the rolling column.

**Purpose:**
- because you cannot reuse an alias inside the same `SELECT` to create a new calculation

---

#### ✅ B) Temp Table
We repeated the same logic using a temp table.

**Purpose:**
- show practical workflow
- reuse intermediate results
- demonstrate another important SQL skill

---

### 5) 🧱 Views (Reusable Layers for Tableau)
We created views to reuse logic without rewriting queries:

- ✅ **PercentPopulationVaccinated**  
  join + rolling vaccinations *(dose-based)*

- ✅ **vw_country_daily_7day**  
  7-day moving averages for new cases/deaths *(smooth trends)*

- ✅ **vw_country_daily_per100k**  
  normalized metrics per 100k *(fair country comparison)*

**Purpose:**
- build clean “reusable layers” for dashboards
- make Tableau work faster and cleaner

---

### 6) 🧩 Country Segmentation (Quartiles)
We segmented countries using `NTILE(4)` based on:
- cases per 100k
- deaths per 100k

Then we labeled segments like:
- 🔴 High Cases / High Deaths
- 🟠 High Cases / Low Deaths
- 🟡 Low Cases / High Deaths
- 🟢 Low Cases / Low Deaths

**Purpose:**
- add storytelling and clustering for dashboards
- create strong filters and category insights

---

## ✅ Final Outputs (Ready for Tableau)
With this project you can build:

- 🌐 Global daily trend charts *(new cases, new deaths, death %)*
- 🧾 KPI cards *(global totals)*
- 🏅 Country rankings *(infection %, death %, deaths per 100k)*
- 🗺️ Maps *(latest cases per 100k, deaths per 100k)*
- 💉 Vaccination progress trends *(rolling dose-based)*
- 🧭 Continent drill-down dashboards
- 🧩 Country segmentation filters *(quartile clusters)*

---

## 🧰 SQL Skills Demonstrated
- Joins *(location + date)*
- CTEs
- Temp tables
- Window functions *(SUM OVER, ROW_NUMBER, AVG OVER)*
- Aggregations *(SUM, MAX, AVG)*
- Data type handling *(CAST / CONVERT / TRY_CONVERT)*
- Views *(CREATE OR ALTER VIEW)*
- BI-ready outputs *(Tableau-friendly)*

---

## ⚠️ Interpretation Notes (Important)
- **DeathPercentage** is a reported ratio, not “true risk”.
- **RollingPeopleVaccinated** is dose-based → can exceed **100%**.
- Always filter country-level rows with:
```sql
WHERE continent IS NOT NULL
```
- Use **per 100k** metrics to compare countries fairly.

---

## 🚀 Suggested Next Improvements
To expand the project:

- calculate real “% people vaccinated” using `people_vaccinated`
- compare deaths before/after vaccination threshold *(example: 10% vaccinated)*
- add “peak day” insights *(worst day per country)*
- create one final export view for Tableau dashboards

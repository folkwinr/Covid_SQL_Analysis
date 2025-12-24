# 📦 Dataset Overview — Global Covid Analysis (SQL Portfolio Project)

## 1) Dataset Contents (What We Have)
This project uses two tables inside the **GlobalCovidAnalysis** database:

- **CovidDeaths**
  - Daily COVID time-series by location (countries + OWID aggregate groups)
  - Includes: cases, deaths, population, continent info

- **CovidVaccinations**
  - Daily vaccination time-series by location (countries + OWID aggregate groups)
  - Includes: new vaccinations and other vaccine-related metrics

**Grain (data level):**
- One row is expected to represent **one (location, date)** record.

**Time granularity:**
- Daily

**Geographic coverage:**
- Global (many countries + aggregate rows like World/continents/EU)

---

## 2) Key Concept: Countries vs OWID Aggregate Rows
The tables include:
- **Country rows**
- **Aggregate rows** (World, continents, “European Union”, “International”, etc.)

We separate them using:

- `continent IS NOT NULL` → **country-level rows**
- `continent IS NULL` → **aggregate rows**

So most analysis queries use:

    WHERE continent IS NOT NULL

Why this matters:
- If we include aggregate rows in totals, we will **double count**.
- Example: “World” already includes all countries.

---

## 3) Main Columns We Use (Core Fields)

### 3.1 CovidDeaths — Core KPI Fields
These are the main fields used in the project:

- `location`  
  Country name or aggregate group name

- `continent`  
  For countries: continent name  
  For aggregates: usually NULL

- `date`  
  Daily date value

- `total_cases`  
  Cumulative confirmed cases up to that date

- `new_cases`  
  New confirmed cases reported on that date

- `total_deaths`  
  Cumulative reported deaths up to that date  
  ⚠️ May require CAST/TRY_CONVERT depending on import

- `new_deaths`  
  New deaths reported on that date  
  ⚠️ May require CAST/TRY_CONVERT depending on import

- `population`  
  Population size for the location (used for normalization)

---

### 3.2 CovidVaccinations — Core KPI Fields
Key fields we use:

- `location`  
  Same meaning as in CovidDeaths

- `continent`  
  Same logic: countries have continent, aggregates often NULL

- `date`  
  Same daily date

- `new_vaccinations`  
  New vaccine doses administered that day  
  ⚠️ Often dose-based (not “people”) → can exceed 100% when cumulated

- `total_vaccinations` (optional / sometimes used)
  Total doses given up to that date (depends on completeness)

---

## 4) Typical Data Quality Issues (What We Expect)
These datasets are rich but can have common issues:

### 4.1 Missing Values (NULLs)
- early pandemic dates may have missing deaths
- some countries may report vaccinations later (many NULLs before 2021)
- some metrics may be incomplete or inconsistent by country

### 4.2 Data Types After Import (Excel → SQL)
Some numeric columns can import as NVARCHAR:
- `total_deaths`, `new_deaths`, `new_vaccinations` (common issues)

So we often use:
- `CAST(...)`
- `CONVERT(...)`
- `TRY_CONVERT(...)`

### 4.3 Join Risk (Duplicates)
We expect (location, date) to be unique, but we check it.
If duplicates exist, joins can create inflated results (many-to-many join).

That’s why we run duplicate checks on:
- CovidDeaths: (location, date)
- CovidVaccinations: (location, date)

---

## 5) How We Use the Tables Together
We combine both tables by joining on:

- `location`
- `date`

This allows us to build:
- vaccination progress vs population
- rolling vaccination metrics over time
- latest vaccination snapshots per country

---

## 6) What the Dataset Allows Us to Analyze (Examples)
With these two tables we can build:

- **Death Percentage (CFR-like):**
  total_deaths / total_cases

- **Infection Rate:**
  total_cases / population

- **Global Totals:**
  SUM(new_cases), SUM(new_deaths)

- **Vaccination Trend:**
  rolling SUM(new_vaccinations) by country

- **Fair Comparison Metrics:**
  cases/deaths per 100k

- **Segmentation:**
  quartiles based on cases per 100k and deaths per 100k

---

## ✅ Dataset Overview Summary
- Daily global COVID dataset with two tables (Deaths + Vaccinations)
- Includes countries and OWID aggregates → we must filter carefully
- We rely on (location, date) as the key for safe joining
- Many useful KPIs are possible, especially after creating BI-ready views


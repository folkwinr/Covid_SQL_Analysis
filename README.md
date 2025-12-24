# 🌍 Global Covid Analysis (SQL-Based COVID-19 Data Exploration)

A SQL portfolio project that explores global COVID-19 cases, deaths, and vaccinations.  
The output is designed to be **BI-ready** (Tableau-friendly) with reusable **views** and clean KPI logic.

---

## ✨ Project Goals
- Explore **cases vs deaths** and compute a CFR-like metric (**Death %**).
- Compare countries fairly using **population-based metrics** (**%**, **per 100k**).
- Join deaths + vaccinations safely on **(location, date)**.
- Build **rolling vaccination** metrics with window functions.
- Create **reusable views** for dashboards (**Tableau / Power BI / etc.**).
- Add advanced analysis like **7-day moving averages** and **country segmentation (quartiles)**.

---

## 🧰 Tech Stack
- **SQL Server** + **SSMS**
- *(Optional)* **Tableau** for visualization

---

## 📦 Dataset Overview

### Source
This project uses the COVID-19 dataset (commonly known as the OWID COVID dataset) exported into two Excel files and imported into SQL Server:
- `CovidDeaths`
- `CovidVaccinations`

### Database / Tables
- Database: **GlobalCovidAnalysis**
- Tables:
  - **CovidDeaths**
  - **CovidVaccinations**

### Data Size (this project’s files)
> These numbers are from the exact Excel files used in this repo.

| Table | Rows | Columns |
|------|------:|--------:|
| CovidDeaths | **85,171** | **26** |
| CovidVaccinations | **85,171** | **37** |

### Date Range
- **2020-01-01 → 2021-04-30** (both tables)

### Locations
- Distinct locations: **219** (both tables)

### Country Rows vs Aggregate Rows
The dataset contains both **country rows** and **aggregate rows** (World, continents, EU, etc.).  
We separate them using `continent`:

- Country rows (`continent IS NOT NULL`): **81,060**
- Aggregate rows (`continent IS NULL`): **4,111**

### Join Safety (Key Integrity)
Primary join key used in this project: **(location, date)**

- Duplicates in **CovidDeaths** for (location, date): **0**
- Duplicates in **CovidVaccinations** for (location, date): **0**

✅ This means joins are safe from many-to-many “join explosion” problems.

### Missing Values (Important Notes)
Country-level NULL counts (where `continent IS NOT NULL`):

**CovidDeaths**
- total_cases: 2,094 NULL
- new_cases: 2,101 NULL
- total_deaths: 11,591 NULL
- new_deaths: 11,592 NULL
- population: 100 NULL

**CovidVaccinations**
- new_vaccinations: 74,062 NULL
- total_vaccinations: 72,658 NULL

⚠️ Vaccination columns have many NULLs because vaccination reporting starts later and differs by country.

---

## 🔑 Core Rules Used in This Project

### 1) Avoid Double Counting
To avoid mixing countries with “World / continents / EU” rows:

```sql
WHERE continent IS NOT NULL
```

This filter is used in most KPI queries and all BI views.

### 2) Data Type Safety
Some numeric columns may be imported as text from Excel.  
We use:
- `CAST`
- `CONVERT`
- `TRY_CONVERT`

### 3) Divide-by-Zero Safety
For ratios, we use:
- `NULLIF(x, 0)`

---

## 📊 Key Analyses Included

### ✅ Cases / Deaths

#### DeathPercentage (CFR-like)
```text
total_deaths / total_cases * 100
```

#### PercentPopulationInfected
```text
total_cases / population * 100
```

#### Country rankings
- Highest infection rate vs population
- Highest death count

---

### ✅ Global KPIs
Global totals using daily sums:
- `SUM(new_cases)`
- `SUM(new_deaths)`
- global death %

---

### ✅ Vaccinations
- Join **CovidDeaths + CovidVaccinations** on **(location, date)**
- Rolling vaccinations using a window function:

```sql
SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY date)
```

⚠️ **Why vaccination % can exceed 100%**  
`new_vaccinations` is usually dose-based, not “unique people”.  
Multiple doses per person can push the rolling total above population.

---

### ✅ Advanced BI Layers
- 7-day moving average *(smooth trends)*
- Per 100k normalized metrics *(better comparisons)*
- Country segmentation using quartiles *(NTILE(4))*

---

## 🧱 Views Created (BI-Ready)
These views are designed for Tableau dashboards:

- **PercentPopulationVaccinated**
  - join + rolling vaccinations
- **vw_country_daily_7day**
  - 7-day moving averages for new cases and new deaths
- **vw_country_daily_per100k**
  - total/new cases and deaths per 100k population

---

## ▶️ How To Run (Step-by-Step)

### 1) Create Database
```sql
CREATE DATABASE GlobalCovidAnalysis;
```

### 2) Import Excel Files into SQL Server
Import the two Excel files into SQL Server as:
- `CovidDeaths`
- `CovidVaccinations`

Make sure column names match *(location, date, etc.)*.

### 3) Run the SQL Script
Run the project SQL file in order:
- sanity checks
- exploration queries
- joins + rolling calculations
- CTE and temp table examples
- create views

### 4) Validate Views
Example:
```sql
SELECT TOP (50) *
FROM PercentPopulationVaccinated
ORDER BY location, date;
```

---

## 📈 Tableau Notes (If You Use Tableau Public)
Tableau Public cannot connect directly to SQL Server.  
Options:
- Export view outputs to CSV
- Use Tableau Desktop *(if available)*

Recommended views for Tableau:
- **vw_country_daily_7day** *(trend charts)*
- **vw_country_daily_per100k** *(maps + rankings)*
- **PercentPopulationVaccinated** *(vaccination progress)*

---

## 📁 Repo Structure
```text
GlobalCovidAnalysis/
├─ assumptions/
│  └─ assumptions.md
├─ data/
│  ├─ CovidDeaths.xlsx
│  └─ CovidVaccinations.xlsx
├─ data_dictionary/
│  └─ data_dictionary.md
├─ dataset_overview/
│  └─ dataset_overview.md
├─ executive/
│  └─ executive_analysis.md
├─ methodology/
│  └─ methodology.md
├─ requirements/
│  └─ requirements.md
├─ sql/
│  └─ GlobalCovidAnalysis(ready).sql
├─ .gitattributes
└─ README.md

```

---

## ✅ SQL Skills Demonstrated
- Joins
- CTEs
- Temp tables
- Window functions *(SUM OVER, ROW_NUMBER, AVG OVER)*
- Aggregations *(SUM, MAX, AVG)*
- Views *(CREATE OR ALTER VIEW)*
- Data type conversions *(CAST / CONVERT / TRY_CONVERT)*

---

## ⚠️ Disclaimer
This project uses reported public data.  
Metrics like death percentage are not “true risk” and can be affected by reporting rules, testing levels, and delays.

---

## 👤 Author
Created by: FOLKWIN

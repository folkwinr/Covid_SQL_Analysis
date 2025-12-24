# ✅ Assumptions — Global Covid Analysis (SQL Portfolio Project)

## 1) Data Level Assumptions (Grain & Keys)
1. We assume each table represents daily records, so **one row = one (location, date)**.
2. We assume **(location, date)** is the correct join key between:
   - CovidDeaths and CovidVaccinations
3. If duplicates exist for (location, date), we assume they are data issues and must be handled (dedupe, aggregation, or filtering) before building final dashboards.

---

## 2) Country vs Aggregate Rows
4. We assume:
   - `continent IS NOT NULL` → country-level rows (main analysis)
   - `continent IS NULL` → OWID aggregate rows (World, continents, EU, etc.)
5. We assume that including aggregate rows together with countries in totals would cause **double counting**, so:
   
   Most KPIs use:
   
       WHERE continent IS NOT NULL

---

## 3) Metric Meaning Assumptions (Important)
6. **Total values are cumulative**:
   - `total_cases` and `total_deaths` are assumed to be cumulative totals up to that date.
7. **New values are daily increments**:
   - `new_cases` and `new_deaths` are assumed to be daily reported changes.
8. We assume `new_cases` and `new_deaths` can be safely summed across dates to estimate global totals (after filtering to country-level rows).

---

## 4) Interpretation Assumptions (What Our KPIs Represent)
9. **DeathPercentage** (total_deaths / total_cases * 100) is assumed to represent a **reported CFR-like ratio**, not the real death risk.
   - It depends on testing rates, reporting delays, definitions, and undercounting.
10. **PercentPopulationInfected** (total_cases / population * 100) is assumed to represent the share of population with **reported confirmed cases**, not true infections.

---

## 5) Vaccination-Specific Assumptions
11. We assume `new_vaccinations` is usually **dose-based**, not unique people.
    - Therefore, cumulative vaccinations can exceed 100% of population.
12. We assume the rolling vaccination metric:

       RollingPeopleVaccinated = SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY date)

    represents **cumulative doses**, not “people fully vaccinated”.

---

## 6) Population Assumptions
13. We assume `population` is stable for each location (does not change daily).
14. We assume population values are accurate enough for normalization:
    - per 100k metrics
    - percent-based metrics
15. If population is NULL or 0, we assume the metric should be treated as invalid and should be protected using:

    - `NULLIF(population, 0)`

---

## 7) Data Type & Cleaning Assumptions
16. We assume some columns may be stored as text after import (Excel → SQL), so:
    - `CAST`, `CONVERT`, `TRY_CONVERT` are needed for safe calculations.
17. We assume using `TRY_CONVERT` is safer than `CONVERT` when the dataset may contain non-numeric text values.

---

## 8) Time-Series Assumptions
18. We assume date coverage may differ by country (some start later, some stop earlier).
19. We assume reporting can be delayed or revised, so daily values can be noisy.
20. For smoother charts, we assume 7-day moving averages give better trend signals than raw daily values.

---

## 9) Segmentation Assumptions (Quartiles)
21. In segmentation, we assume using **per 100k metrics** is more fair than using raw totals.
22. We assume quartiles (NTILE) give stable categories without choosing arbitrary thresholds.
23. We assume “High” and “Low” depend on how we define quartiles (top 25%, top 50%, etc.) and may need tuning depending on the dataset distribution.

---

## ✅ Assumptions Summary
- Join key is (location, date)
- country rows are filtered using `continent IS NOT NULL`
- core KPIs reflect **reported data**, not perfect truth
- vaccination rolling metric is **dose-based**
- normalization (percent/per100k) assumes population is usable and stable
- moving averages help reduce daily noise

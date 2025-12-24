# ✅ Requirements — GlobalCovidAnalysis (SSMS + Import Troubleshooting)

## 1) System Requirements
- **OS:** Windows 10/11 (recommended)
- **SQL Server:** SQL Server 2019+ (Developer / Express / Standard)
- **SSMS:** SQL Server Management Studio (SSMS) 18/19+
- **Excel:** Microsoft Excel (optional, useful for quick formatting)
- **Input files:** `.xlsx` and/or `.csv`

---

## 2) SQL Server – Excel / CSV Import Issues (SSMS)

### Context
During this project, importing Excel (`.xlsx`) and CSV files into SQL Server using SSMS caused multiple technical blockers.  
This section documents issues using:

**Symptom → Root Cause → Wrong Approach → Solution**

---

## 🔴 Issue 1: Excel Import Provider Error (ACE OLE DB Missing)

### ❗ Symptom
- Error: **“Microsoft.ACE.OLEDB provider is not registered”**
- Excel version cannot be selected
- Import Wizard cannot proceed

### 🧠 Root Cause
SQL Server/SSMS cannot read Excel files directly. It needs:
- **Microsoft Access Database Engine (ACE OLE DB)**

Either:
- the driver is not installed at all, or
- there is a **32-bit vs 64-bit mismatch** (very common)

### ❌ Wrong Approaches
- Reinstalling SQL Server
- Changing Excel versions
- Updating Windows
- Trying random Excel versions inside the wizard

📌 None of these fix a missing provider.

### ✅ Permanent Solution
- Install **Microsoft Access Database Engine 2016 – 32-bit (x86)**

⚠️ **Project Observation (2025):**  
In practice, SSMS Excel imports often worked more reliably with the **32-bit driver**.

---

## 🔴 Issue 2: SSMS “Tasks → Import Data…” Fails (32-bit vs 64-bit Wizard)

### ❗ Symptom
- Import fails when using:  
  `Database > Tasks > Import Data...`
- Same file works using another import path
- Confusing “works here but not there” behavior

### 🧠 Root Cause
On some systems, the SSMS embedded wizard behaves like it is using a different driver pipeline (often related to 32/64-bit provider behavior).  
Meanwhile, the standalone Import/Export wizard from the Start Menu often runs as **64-bit**, which can behave differently (and succeed).

### ❌ Wrong Approaches
- Assuming SSMS is broken and reinstalling everything
- Repeating the same SSMS import steps endlessly
- Renaming/resaving the same file repeatedly without fixing the pipeline

### ✅ Permanent Solution (Project Practice)
Use the standalone wizard:
- Windows Start Menu → **Microsoft SQL Server → Import and Export Data (64-bit)**

📌 In this project, this method produced stable imports.

---

## 🔴 Issue 3: CSV Import Creates Wrong Data Types (Numbers Become NVARCHAR)

### ❗ Symptom
- Numeric columns (example: `total_deaths`, `new_deaths`, `new_vaccinations`) import as **NVARCHAR**
- Aggregations fail:
  - **“Operand data type nvarchar is invalid for sum operator”**
- Calculations return wrong values or NULL

### 🧠 Root Cause
During import, SQL Server guesses column types (type inference).  
If a column contains blanks, mixed formats, or text-like values, it may be imported as **text**.

### ❌ Wrong Approaches
- Importing again and again hoping it fixes itself
- Trying to manually fix everything in the SSMS table designer
- Blaming SQL Server instead of controlling conversion logic

### ✅ Permanent Solution
Handle conversions safely in SQL using:
- `TRY_CONVERT(float, col)`
- `CAST(col AS int)`
- `CONVERT(int, col)`

📌 In portfolio projects, **TRY_CONVERT** is recommended for safer scripts.

---

## 🔴 Issue 4: Excel Sheet/Range Looks Empty During Import

### ❗ Symptom
- Excel file is selected, but the sheet appears empty in the wizard
- Some columns do not appear
- Data exists in Excel, but not in the import preview

### 🧠 Root Cause
Common reasons:
- The file is actually a CSV saved with the wrong expectation
- Wrong sheet/range selected
- Header row not recognized
- Excel formatting issues (cells stored as “Text”, filters, hidden rows)

### ❌ Wrong Approaches
- Randomly selecting different sheets without checking the file
- Re-downloading the dataset repeatedly
- Searching for SQL problems when it’s a file-format issue

### ✅ Permanent Solution
Before import, validate in Excel:
- First row = headers
- Correct sheet name
- File format truly `.xlsx`

If needed:
- Excel → **Save As** → **Excel Workbook (.xlsx)**

---

## 3) Project Software Requirements (Minimum)
- **SQL Server + SSMS** (import + querying)
- **Microsoft Access Database Engine 2016 (x86)** (for Excel import)
- Optional: **Tableau / Power BI** (for visualization)
- Optional: **GitHub account** (for sharing scripts)

---

## ✅ Quick Checklist (Before Import)
- [ ] Database created: `GlobalCovidAnalysis`
- [ ] Tables planned: `CovidDeaths`, `CovidVaccinations`
- [ ] Files are really `.xlsx` (not mistaken `.csv`)
- [ ] ACE OLEDB installed (x86 recommended)
- [ ] If SSMS import fails → use Start Menu Import/Export Wizard (64-bit)
- [ ] After import → confirm numeric columns (some may be NVARCHAR)

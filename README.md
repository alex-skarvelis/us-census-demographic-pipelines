# US Census Demographic Pipelines: Longitudinal Population, Density, and Variance Modeling

---

## Project Overview
This repository contains a target schema reconciliation, non-parametric distribution framework, and multi-dimensional statistical distance model tracking demographic shifts across United States counties. The project handles macro-level US Census data arrays using advanced relational techniques natively inside PostgreSQL.

---

## Core Technical Findings

### 1. Decadal Population Velocity (2000 vs. 2019)
Through exact multi-table calculations and transactional joining constraints, the pipeline isolated three major national population velocity markers:
* **Maximum Volumetric Expansion Vector:** Maricopa County, Arizona (+1,413,265 individuals)
* **Maximum Volumetric Contraction Vector:** Wayne County, Michigan (-311,819 individuals)
* **Nominal National Median Baseline:** Bourbon County, Kentucky (+428 individuals)

### 2. Geospatial Population Density Distribution
Population density was programmatically transformed from native metric measurements into a standardized index of **individuals per square mile** using the exact geographic divisor `2589988.11`: `Density = Population / (Land Area / 2589988.11)`.

Through comparative quartile analysis, the pipeline isolated a dramatic upward shift in top-tier urban concentration alongside a stable national baseline:

| Statistical Metric | 2000 Census Distribution (People / Sq. Mile) | 2019 Census Distribution (People / Sq. Mile) |
| :--- | :--- | :--- |
| **Maximum Density** | New York County, New York (**67,835.80**) | New York County, New York (**71,874.14**) |
| **Third Quartile (75%)** | Rogers County, Oklahoma (**104.56**) | Huron County, Ohio (**118.55**) |
| **Median (50%)** | Penobscot County, Maine (**42.66**) | Bath County, KY / Paulding County, OH (**44.84**) |
| **First Quartile (25%)** | Carroll County, Mississippi (**17.14**) | Hughes County, Oklahoma (**16.51**) |
| **Minimum Density** | Yukon-Koyukuk Area, Alaska (**0.05**) | Yukon-Koyukuk Area, Alaska (**0.04**) |

### 3. Macro Demographic Clustering (National Microcosm Isolation)
By aggregating absolute variance vectors across all demographic classifications, the pipeline isolated the single geographical jurisdiction that most accurately represents a structural microcosm of the United States:
* **Identified Microcosm County:** Pulaski County, Missouri
* **Total Scaled Absolute Variance:** **16.88%** cumulative deviation from the national baseline across all combined racial and geographic density criteria.

---

## Architectural Data Engineering Challenges & System Design

Open-source civic datasets are notoriously uncurated and prone to structural drift. To build a reliable data analytics stream, the following system cleaning strategies were executed natively in the database layer:

### 1. Schema Incompatibility & Key Realignment
* **The Problem:** The historical `us_counties_2000` table utilized a unified geospatial text locator string (`county_name, state_name` under `geo_name`), whereas the modern `us_counties_pop_est` schema isolated geographical identifiers into separate fields (`county_name`, `state_name`). This structural drift completely broke standard `INNER JOIN` operations.
* **The Engineering Fix:** Rather than executing slow, computationally heavy string formatting routines inside processing loops, the target schema was permanently modified. A deterministic, index-mapped text expression was deployed via a `GENERATED ALWAYS AS` text concatenation array, safely aligning the keys without incurring raw insertion runtime overhead.

```sql
ALTER TABLE us_counties_pop_est RENAME TO us_counties_pop_est_2019;

ALTER TABLE us_counties_pop_est_2019
ADD COLUMN geo_name_2019 TEXT
GENERATED ALWAYS AS (county_name || ', ' || state_name) STORED;
```

### 2. Historical Feature Absence & Proxy Boundary Imputation
* **The Problem:** The `us_counties_2000` table lacked explicit geometric land area attributes (`area_land`), and county membership drifted slightly over a 19-year period.
* **The Engineering Fix:** Implemented a proxy data imputation strategy using a scoped `INNER JOIN` intersection. By mapping contemporary 2019 spatial records backward as a historical proxy for 2000 demographic metrics, the pipeline unlocked comparative density analytics while explicitly isolating and dropping records outside the intersecting set. This architectural boundary shortcut was explicitly discussed with the stakeholder and verified as acceptable for macro-level demographic velocity modeling, protecting data density across the intersecting set.

### 3. Non-Parametric Distribution Mapping
* **The Problem:** Volumetric population growth and dense urban hubs (e.g., Manhattan) create heavily right-skewed data distributions, making standard mathematical averages statistically deceptive.
* **The Engineering Fix:** To preserve strict mathematical integrity, a non-parametric approach was utilized. Deployed discrete inverse distribution functions (`PERCENTILE_DISC`) at specific parameters (`0.25`, `0.50`, `0.75`) inside scoped nested subquery blocks to isolate the exact statistical quartile values, bypassing outlier skew entirely.

### 4. Mathematical Modeling of Absolute Variance (Manhattan Distance)
* **The Problem:** Evaluating how closely an individual county's demographic makeup mirrors the national average requires aggregate variance calculations across multiple independent columns. If raw values are accumulated directly, positive deviations (values above the national average) and negative deviations (values below the national average) will mathematically cancel each other out, artificially bringing the final composite score closer to zero and distorting the ranking.
* **The Engineering Fix:** Implemented a multi-dimensional absolute variance calculation loop. Individual county cohort values are first converted to a localized percentage ratio against their parent population and subtracted from the national aggregated baseline. The script wraps every dimensional delta inside an absolute value function (`ABS`). This forces all variances to scale as positive values, preventing directional cancellation errors and measuring true multi-faceted geometric distance.

### 5. Multi-Dimensional Distance Normalization (Feature Scaling)
* **The Problem:** Building a composite index to measure how closely a county's demographic array matches the national baseline requires combining disparate data categories. Introducing raw population density metrics alongside 0–100% racial ratios creates a scale mismatch error, where density values would mathematically overwhelm percentage differences.
* **The Engineering Fix:** Implemented feature scaling directly inside the SQL variance equation. While race metrics were evaluated via standard absolute percentage differences, the population density variance was normalized as a **relative percentage deviation** from the national baseline:

```sql
ABS(((county_pop_density - national_pop_density) / national_pop_density) * 100)
```

---

## Comprehensive Demographic Indexing Pipeline

To measure multi-dimensional variance, individual county ratios are converted into percentages and compared directly against window-aggregated national totals (`SUM() OVER()`). This constructs a Manhattan Distance model entirely within SQL to locate the national baseline microcosm:

```sql
WITH demographics AS (
    SELECT 
        c2000.geo_name,
        ROUND((c2000.p0010003 / c2000.p0010001::numeric) * 100, 2) AS county_white,
        ROUND((SUM(c2000.p0010003) OVER () / SUM(c2000.p0010001) OVER ()::numeric) * 100, 2) AS national_white,
        -- [Additional demographic attributes systematically mapped...]
        ROUND((c2000.p0010001 / (c2019.area_land::numeric / 2589988.11)), 2) AS county_pop_density,
        ROUND((SUM(c2000.p0010001) OVER () / (SUM(c2019.area_land) OVER ()::numeric / 2589988.11)), 2) AS national_pop_density
    FROM us_counties_2000 c2000
    INNER JOIN us_counties_pop_est_2019 c2019 ON c2000.geo_name = c2019.geo_name_2019
    WHERE c2000.p0010001 > 0
),
variances AS (
    SELECT
        geo_name,
        county_pop_density,
        national_pop_density,
        (ABS(county_white - national_white) +
         ABS(county_black - national_black) +
         ABS(county_american_indian - national_american_indian) +
         ABS(county_asian - national_asian) +
         ABS(county_native_hawaiian - national_native_hawaiian) +
         ABS(county_other_race - national_other_race) +
         ABS(county_two_or_more_races - national_two_or_more_races) +
         ABS(county_two_races - national_two_races) + 
         ABS(((county_pop_density - national_pop_density) / national_pop_density) * 100)) AS total_absolute_variance
    FROM demographics
)
SELECT 
    geo_name, 
    ROUND(total_absolute_variance, 2) AS total_absolute_variance
FROM variances
ORDER BY total_absolute_variance ASC
LIMIT 1;
```

---

## Embedded Pipeline Assumptions

To maintain academic rigor and transparent data governance, the codebase operates under the following structural assumptions:

* **Taxonomic Integrity:** The population identifier field `p0010001` in the 2000 decennial census was validated as the correct aggregate anchor column to contrast against modern annual population estimations.
* **Boundary Invariance Constraints:** It is assumed that county geographical boundaries remained relatively stable over the 19-year longitudinal window. Where modern county splits or membership modifications occurred, records were safely handled using strict relational `INNER JOIN` matching intersections to protect data density. 

---

## Academic Context & Deployment
Developed as an advanced data-staging project for **CSCI 343: Database Management Systems** at UNC Asheville. 


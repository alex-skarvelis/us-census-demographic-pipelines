-- ====================================================================
-- US CENSUS DEMOGRAPHIC PIPELINES
-- Coursework: CSCI 343 - Database Management Systems (UNC Asheville)
-- Target Platform: PostgreSQL
-- Implementation: Population Growth, Density Metrics, and Variance Modeling
-- ====================================================================

-- --------------------------------------------------------------------
-- STAGE 1: Schema Reconciliation & Key Alignment
-- --------------------------------------------------------------------

ALTER TABLE us_counties_pop_est  
RENAME TO us_counties_pop_est_2019;

-- Creates a column where county name and state name are combined together to match the 2000 schema
ALTER TABLE us_counties_pop_est_2019 
ADD COLUMN geo_name_2019 TEXT 
GENERATED ALWAYS AS (county_name || ', ' || state_name) STORED;


-- --------------------------------------------------------------------
-- STAGE 2: Decadal Population Growth Analytics (Question 1)
-- --------------------------------------------------------------------

-- Query: Maximum Raw Population Growth (2000 to 2019)
SELECT 
    c2019.geo_name_2019, 
    MAX(c2019.pop_est_2019 - c2000.p0010001) AS raw_growth 
FROM us_counties_2000 c2000
INNER JOIN us_counties_pop_est_2019 c2019 
    ON c2000.geo_name = c2019.geo_name_2019
GROUP BY c2019.geo_name_2019
ORDER BY raw_growth DESC
LIMIT 1;

-- Query: Minimum/Negative Raw Population Growth (2000 to 2019)
SELECT 
    c2019.geo_name_2019, 
    MIN(c2019.pop_est_2019 - c2000.p0010001) AS raw_growth 
FROM us_counties_2000 c2000
INNER JOIN us_counties_pop_est_2019 c2019 
    ON c2000.geo_name = c2019.geo_name_2019
GROUP BY c2019.geo_name_2019
ORDER BY raw_growth ASC
LIMIT 1;

-- Query: Median Raw Population Growth (2000 to 2019)
SELECT 
    c2019.geo_name_2019, 
    (c2019.pop_est_2019 - c2000.p0010001) AS raw_growth
FROM us_counties_2000 c2000
INNER JOIN us_counties_pop_est_2019 c2019
    ON c2000.geo_name = c2019.geo_name_2019
WHERE (c2019.pop_est_2019 - c2000.p0010001) = (
    SELECT 
        PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY (c2019.pop_est_2019 - c2000.p0010001))
    FROM us_counties_2000 c2000
    INNER JOIN us_counties_pop_est_2019 c2019
        ON c2000.geo_name = c2019.geo_name_2019
);


-- --------------------------------------------------------------------
-- STAGE 3: Longitudinal Population Density Distribution (Question 2)
-- --------------------------------------------------------------------

-- Query: Maximum Population Density in 2019
SELECT 
    c2019.geo_name_2019, 
    ROUND(MAX(c2019.pop_est_2019 / (c2019.area_land::numeric / 2589988.11)), 2) AS pop_density 
FROM us_counties_pop_est_2019 c2019
GROUP BY c2019.geo_name_2019
ORDER BY pop_density DESC
LIMIT 1;

-- Query: Minimum Population Density in 2019
SELECT 
    c2019.geo_name_2019, 
    ROUND(MIN(c2019.pop_est_2019 / (c2019.area_land::numeric / 2589988.11)), 2) AS pop_density 
FROM us_counties_pop_est_2019 c2019
GROUP BY c2019.geo_name_2019
ORDER BY pop_density ASC
LIMIT 1;

-- Query: Median Population Density in 2019
SELECT 
    c2019.geo_name_2019,
    ROUND((c2019.pop_est_2019 / (c2019.area_land::numeric / 2589988.11)), 2) AS pop_density
FROM us_counties_pop_est_2019 c2019
WHERE ROUND((c2019.pop_est_2019 / (c2019.area_land::numeric / 2589988.11)), 2) = (
	SELECT 
		ROUND(PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY (c2019.pop_est_2019 / (c2019.area_land::numeric / 2589988.11))), 2)
	FROM us_counties_pop_est_2019 AS c2019
);

-- Query: 1st Quartile Population Density in 2019
SELECT 
    c2019.geo_name_2019,
    ROUND((c2019.pop_est_2019 / (c2019.area_land::numeric / 2589988.11)), 2) AS pop_density
FROM us_counties_pop_est_2019 c2019
WHERE ROUND((c2019.pop_est_2019 / (c2019.area_land::numeric / 2589988.11)), 2) = (
	SELECT 
		ROUND(PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY (c2019.pop_est_2019 / (c2019.area_land::numeric / 2589988.11))), 2)
	FROM us_counties_pop_est_2019 AS c2019
);

-- Query: 3rd Quartile Population Density in 2019
SELECT 
    c2019.geo_name_2019,
    ROUND((c2019.pop_est_2019 / (c2019.area_land::numeric / 2589988.11)), 2) AS pop_density
FROM us_counties_pop_est_2019 c2019
WHERE ROUND((c2019.pop_est_2019 / (c2019.area_land::numeric / 2589988.11)), 2) = (
	SELECT 
		ROUND(PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY (c2019.pop_est_2019 / (c2019.area_land::numeric / 2589988.11))), 2)
	FROM us_counties_pop_est_2019 AS c2019
);

-- Query: Maximum Population Density in 2000 (Using 2019 Boundary Proxies)
SELECT 
    c2000.geo_name, 
    ROUND(MAX(c2000.p0010001 / (c2019.area_land::numeric / 2589988.11)), 2) AS pop_density 
FROM us_counties_2000 c2000
INNER JOIN us_counties_pop_est_2019 c2019
	ON c2000.geo_name = c2019.geo_name_2019
GROUP BY c2000.geo_name
ORDER BY pop_density DESC
LIMIT 1;

-- Query: Minimum Population Density in 2000 (Using 2019 Boundary Proxies)
SELECT 
    c2000.geo_name, 
    ROUND(MIN(c2000.p0010001 / (c2019.area_land::numeric / 2589988.11)), 2) AS pop_density 
FROM us_counties_2000 c2000
INNER JOIN us_counties_pop_est_2019 c2019
	ON c2000.geo_name = c2019.geo_name_2019
GROUP BY c2000.geo_name
ORDER BY pop_density ASC
LIMIT 1;

-- Query: Median Population Density in 2000 (Using 2019 Boundary Proxies)
SELECT 
    c2000.geo_name,
    ROUND((c2000.p0010001 / (c2019.area_land::numeric / 2589988.11)), 2) AS pop_density
FROM us_counties_2000 c2000
INNER JOIN us_counties_pop_est_2019 c2019
	ON c2000.geo_name = c2019.geo_name_2019
WHERE ROUND((c2000.p0010001 / (c2019.area_land::numeric / 2589988.11)), 2) = (
	SELECT 
		ROUND(PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY (c2000.p0010001 / (c2019.area_land::numeric / 2589988.11))), 2)
	FROM us_counties_2000 AS c2000
	INNER JOIN us_counties_pop_est_2019 c2019
		ON c2000.geo_name = c2019.geo_name_2019
);

-- Query: 1st Quartile Population Density in 2000 (Using 2019 Boundary Proxies)
SELECT 
    c2000.geo_name,
    ROUND((c2000.p0010001 / (c2019.area_land::numeric / 2589988.11)), 2) AS pop_density
FROM us_counties_2000 c2000
INNER JOIN us_counties_pop_est_2019 c2019
	ON c2000.geo_name = c2019.geo_name_2019
WHERE ROUND((c2000.p0010001 / (c2019.area_land::numeric / 2589988.11)), 2) = (
	SELECT 
		ROUND(PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY (c2000.p0010001 / (c2019.area_land::numeric / 2589988.11))), 2)
	FROM us_counties_2000 AS c2000
	INNER JOIN us_counties_pop_est_2019 c2019
		ON c2000.geo_name = c2019.geo_name_2019
);

-- Query: 3rd Quartile Population Density in 2000 (Using 2019 Boundary Proxies)
SELECT 
    c2000.geo_name,
    ROUND((c2000.p0010001 / (c2019.area_land::numeric / 2589988.11)), 2) AS pop_density
FROM us_counties_2000 c2000
INNER JOIN us_counties_pop_est_2019 c2019
	ON c2000.geo_name = c2019.geo_name_2019
WHERE ROUND((c2000.p0010001 / (c2019.area_land::numeric / 2589988.11)), 2) = (
	SELECT 
		ROUND(PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY (c2000.p0010001 / (c2019.area_land::numeric / 2589988.11))), 2)
	FROM us_counties_2000 AS c2000
	INNER JOIN us_counties_pop_est_2019 c2019
		ON c2000.geo_name = c2019.geo_name_2019
);


-- --------------------------------------------------------------------
-- STAGE 4: Multi-Dimensional Macro Demographic Cluster Modeling (Question 3)
-- --------------------------------------------------------------------

-- Query 3.1: Calculate National Baseline Percentages for Isolated Race Fields
SELECT 
    ROUND((SUM(p0010003) / SUM(p0010001)::numeric) * 100, 2) AS percent_white,
    ROUND((SUM(p0010004) / SUM(p0010001)::numeric) * 100, 2) AS percent_black,
    ROUND((SUM(p0010005) / SUM(p0010001)::numeric) * 100, 2) AS percent_american_indian, 
    ROUND((SUM(p0010006) / SUM(p0010001)::numeric) * 100, 2) AS percent_asian,
    ROUND((SUM(p0010007) / SUM(p0010001)::numeric) * 100, 2) AS percent_native_hawaiian,
    ROUND((SUM(p0010008) / SUM(p0010001)::numeric) * 100, 2) AS percent_other_race,
    ROUND((SUM(p0010009) / SUM(p0010001)::numeric) * 100, 2) AS percent_two_or_more_races,
    ROUND((SUM(p0010010) / SUM(p0010001)::numeric) * 100, 2) AS percent_two_races			
FROM us_counties_2000;

-- Query 3.2: Absolute Demographic Variance Distance Indexing (Excluding Density)
WITH demographics AS (
    SELECT 
        c2000.geo_name,
        ROUND((c2000.p0010003 / c2000.p0010001::numeric) * 100, 2) AS county_white,
        ROUND((SUM(c2000.p0010003) OVER () / SUM(c2000.p0010001) OVER ()::numeric) * 100, 2) AS national_white,
        
        ROUND((c2000.p0010004 / c2000.p0010001::numeric) * 100, 2) AS county_black,
        ROUND((SUM(c2000.p0010004) OVER () / SUM(c2000.p0010001) OVER ()::numeric) * 100, 2) AS national_black,
        
        ROUND((c2000.p0010005 / c2000.p0010001::numeric) * 100, 2) AS county_american_indian,
        ROUND((SUM(c2000.p0010005) OVER () / SUM(c2000.p0010001) OVER ()::numeric) * 100, 2) AS national_american_indian,
        
        ROUND((c2000.p0010006 / c2000.p0010001::numeric) * 100, 2) AS county_asian,
        ROUND((SUM(c2000.p0010006) OVER () / SUM(c2000.p0010001) OVER ()::numeric) * 100, 2) AS national_asian,
        
        ROUND((c2000.p0010007 / c2000.p0010001::numeric) * 100, 2) AS county_native_hawaiian,
        ROUND((SUM(c2000.p0010007) OVER () / SUM(c2000.p0010001) OVER ()::numeric) * 100, 2) AS national_native_hawaiian,
        
        ROUND((c2000.p0010008 / c2000.p0010001::numeric) * 100, 2) AS county_other_race,
        ROUND((SUM(c2000.p0010008) OVER () / SUM(c2000.p0010001) OVER ()::numeric) * 100, 2) AS national_other_race,
        
        ROUND((c2000.p0010009 / c2000.p0010001::numeric) * 100, 2) AS county_two_or_more_races,
        ROUND((SUM(c2000.p0010009) OVER () / SUM(c2000.p0010001) OVER ()::numeric) * 100, 2) AS national_two_or_more_races,
        
        ROUND((c2000.p0010010 / c2000.p0010001::numeric) * 100, 2) AS county_two_races,
        ROUND((SUM(c2000.p0010010) OVER () / SUM(c2000.p0010001) OVER ()::numeric) * 100, 2) AS national_two_races
    FROM us_counties_2000 c2000
),
variances AS (
	SELECT
		geo_name,
		(ABS(county_white - national_white) +
		 ABS(county_black - national_black) +
		 ABS(county_american_indian - national_american_indian) +
		 ABS(county_asian - national_asian) +
		 ABS(county_native_hawaiian - national_native_hawaiian) +
		 ABS(county_other_race - national_other_race) +
		 ABS(county_two_or_more_races - national_two_or_more_races) +
		 ABS(county_two_races - national_two_races)) AS total_absolute_variance
	FROM demographics
)
SELECT 
	geo_name, 
	total_absolute_variance
FROM variances
ORDER BY total_absolute_variance ASC
LIMIT 1;

-- Query 3.3: Scaled Distance Model (Integrating Feature-Normalized Population Density Deviation)
WITH demographics AS (
    SELECT 
        c2000.geo_name,
        ROUND((c2000.p0010003 / c2000.p0010001::numeric) * 100, 2) AS county_white,
        ROUND((SUM(c2000.p0010003) OVER () / SUM(c2000.p0010001) OVER ()::numeric) * 100, 2) AS national_white,
        
        ROUND((c2000.p0010004 / c2000.p0010001::numeric) * 100, 2) AS county_black,
        ROUND((SUM(c2000.p0010004) OVER () / SUM(c2000.p0010001) OVER ()::numeric) * 100, 2) AS national_black,
        
        ROUND((c2000.p0010005 / c2000.p0010001::numeric) * 100, 2) AS county_american_indian,
        ROUND((SUM(c2000.p0010005) OVER () / SUM(c2000.p0010001) OVER ()::numeric) * 100, 2) AS national_american_indian,
        
        ROUND((c2000.p0010006 / c2000.p0010001::numeric) * 100, 2) AS county_asian,
        ROUND((SUM(c2000.p0010006) OVER () / SUM(c2000.p0010001) OVER ()::numeric) * 100, 2) AS national_asian,
        
        ROUND((c2000.p0010007 / c2000.p0010001::numeric) * 100, 2) AS county_native_hawaiian,
        ROUND((SUM(c2000.p0010007) OVER () / SUM(c2000.p0010001) OVER ()::numeric) * 100, 2) AS national_native_hawaiian,
        
        ROUND((c2000.p0010008 / c2000.p0010001::numeric) * 100, 2) AS county_other_race,
        ROUND((SUM(c2000.p0010008) OVER () / SUM(c2000.p0010001) OVER ()::numeric) * 100, 2) AS national_other_race,
        
        ROUND((c2000.p0010009 / c2000.p0010001::numeric) * 100, 2) AS county_two_or_more_races,
        ROUND((SUM(c2000.p0010009) OVER () / SUM(c2000.p0010001) OVER ()::numeric) * 100, 2) AS national_two_or_more_races,
        
        ROUND((c2000.p0010010 / c2000.p0010001::numeric) * 100, 2) AS county_two_races,
        ROUND((SUM(c2000.p0010010) OVER () / SUM(c2000.p0010001) OVER ()::numeric) * 100, 2) AS national_two_races,
        
        ROUND((c2000.p0010001 / (c2019.area_land::numeric / 2589988.11)), 2) AS county_pop_density,
        ROUND((SUM(c2000.p0010001) OVER () / (SUM(c2019.area_land) OVER ()::numeric / 2589988.11)), 2) AS national_pop_density
    FROM us_counties_2000 c2000
    INNER JOIN us_counties_pop_est_2019 c2019
	    ON c2000.geo_name = c2019.geo_name_2019
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
		 -- Feature scaling: density variance evaluated as a relative percentage deviation
		 ABS(((county_pop_density - national_pop_density) / national_pop_density) * 100)) AS total_absolute_variance
	FROM demographics
)
SELECT 
	geo_name, 
	ROUND(total_absolute_variance, 2) AS total_absolute_variance
FROM variances
ORDER BY total_absolute_variance ASC
LIMIT 1;

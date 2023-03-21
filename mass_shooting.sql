-- Note: I use postgreSQL
-- 1. Data importing

CREATE TABLE mass_shooting
(
    case_name character varying(100) COLLATE pg_catalog."default",
    "location" character varying(100) COLLATE pg_catalog."default",
    occurance_date date,
	summary text,
    fatalities smallint,
    injured smallint,
    total_victims smallint,
    location_type character varying(20) COLLATE pg_catalog."default",
    age_of_shooter smallint,
    prior_signs_mental_health_issues character varying(20) COLLATE pg_catalog."default",
	mental_health_details text,
    weapons_obtained_legally character varying(255) COLLATE pg_catalog."default",
    where_obtained character varying(255) COLLATE pg_catalog."default",
    weapon_type character varying(500) COLLATE pg_catalog."default",
	weapon_details text,
    race character varying(20) COLLATE pg_catalog."default",
    gender character varying(20) COLLATE pg_catalog."default",
	sources text,
	mental_health_sources varchar(500), 
	sources_additional_age varchar(500),
    latitude numeric,
    longitude numeric,
    "type" character varying(10) COLLATE pg_catalog."default"
)

-- 2. Data cleaning

-- Data inspection
SELECT * FROM mass_shooting

-- Remove unused columns
ALTER TABLE mass_shooting
DROP COLUMN summary, 
DROP COLUMN mental_health_details, 
DROP COLUMN weapon_details, 
DROP COLUMN sources, 
DROP COLUMN mental_health_sources, 
DROP COLUMN sources_additional_age

-- Standardize input for "prior_signs_mental_health_issues" column
SELECT DISTINCT prior_signs_mental_health_issues FROM mass_shooting

UPDATE mass_shooting
SET prior_signs_mental_health_issues = TRIM(LOWER(prior_signs_mental_health_issues))

UPDATE mass_shooting
SET prior_signs_mental_health_issues = 'TBD'
WHERE prior_signs_mental_health_issues = 'Unclear '  
	OR prior_signs_mental_health_issues = 'Unclear'  
	OR prior_signs_mental_health_issues = 'Unknown'  
	OR prior_signs_mental_health_issues ISNULL 
		
-- Add column 'state'
ALTER TABLE mass_shooting
ADD COLUMN "state" varchar(20)

UPDATE mass_shooting
SET "state" = SPLIT_PART("location", ',', 2)

-- Add column 'year'
ALTER TABLE mass_shooting
ADD COLUMN "year" INT

UPDATE mass_shooting
SET "year" = SELECT EXTRACT(YEAR FROM occurance_date)::int FROM my_table;

-- Standardize input for "weapons_obtained_legally" column
UPDATE mass_shooting
SET weapons_obtained_legally = TRIM(LOWER(weapons_obtained_legally))

UPDATE mass_shooting
SET weapons_obtained_legally = regexp_replace(weapons_obtained_legally, E'\\n', '');

UPDATE mass_shooting
SET weapons_obtained_legally = 'TBD'
WHERE weapons_obtained_legally = 'unknown'
	OR weapons_obtained_legally ISNULL
    OR weapons_obtained_legally = 'tbd'

-- Clean column 'where_obtained'
UPDATE mass_shooting
SET where_obtained = NULL
WHERE where_obtained = 'Unknown'
	OR where_obtained = 'Unclear'

-- Set standard input for 'race'
SELECT DISTINCT race FROM mass_shooting

UPDATE mass_shooting
SET race = INITCAP(TRIM(race))

UPDATE mass_shooting
SET race = NULL
WHERE race = 'Unclear'

-- Set standard input for 'gender'
SELECT DISTINCT gender FROM mass_shooting

UPDATE mass_shooting
SET gender = 
	CASE
		WHEN gender = 'M' THEN 'Male'
		WHEN gender = 'F' THEN 'Female'
		ELSE 'Both'
	END

-- Check and remove duplicates
SELECT * FROM (
	SELECT case_name, location, occurance_date, count(1) dup FROM mass_shooting
	GROUP BY case_name, location, occurance_date
	) x
WHERE dup > 1

-- 3. Data Analyzing

--Number of case according to state
SELECT "state", count(1) AS num_of_case FROM mass_shooting
GROUP BY "state"
ORDER BY num_of_case DESC

--Number of case according to year
SELECT "year", count(1) AS num_of_case FROM mass_shooting
GROUP BY "year"
ORDER BY 1 DESC

--Number of case according to month
SELECT EXTRACT(month FROM occurance_date) "month", count(1) AS num_of_case FROM mass_shooting
GROUP BY "month"
ORDER BY 1 

--Number of death, injured people, total victims according to state
SELECT "state", SUM(fatalities) death, SUM(injured) injured
	, SUM(total_victims) total
FROM mass_shooting
GROUP BY "state"
ORDER BY 4 DESC

--Number of case according to location type
SELECT location_type, count(1) num_of_case
FROM mass_shooting
GROUP BY location_type
ORDER BY 2 DESC

--Number of death, injured people, total victims according to location type
SELECT location_type, SUM(fatalities) death, SUM(injured) injured
	, SUM(total_victims) total
FROM mass_shooting
GROUP BY location_type
ORDER BY 4 DESC

--Age group of shooters
SELECT 
  CASE 
    WHEN age_of_shooter < 20 THEN 'Under 20'
    WHEN age_of_shooter BETWEEN 20 AND 30 THEN 'Between 20 and 30'
	WHEN age_of_shooter BETWEEN 31 AND 65 THEN 'Between 31 and 65'
	ELSE 'Over 65'
  END AS age_group,
  COUNT(*) AS num_of_people
FROM 
  mass_shooting
GROUP BY 
  age_group
ORDER BY num_of_people DESC

--Number of shooters who have prior signs of mental health problems
WITH cte AS (
  SELECT 
    COUNT(*) AS total_count,
    COUNT(CASE 
            WHEN prior_signs_mental_health_issues = 'yes' THEN 1 
          END) AS yes_count
  FROM 
    mass_shooting
)
SELECT 
  yes_count * 100 / total_count AS percentage_of_people_with_mental_health
FROM 
  cte;

-- The percentage of illegally obtained weapons by shooters
SELECT COUNT(*) * 100
	/
	(SELECT COUNT(*) FROM mass_shooting) percen_weapons_illegal
FROM mass_shooting
WHERE weapons_obtained_legally = 'no'

-- Number of case according to race
SELECT race, count(1) num_of_case FROM mass_shooting
WHERE race IS NOT NULL
GROUP BY race
ORDER BY 2 DESC

-- Percentage of case according to race with highest number of case
SELECT COUNT(race) * 100
	/
	(SELECT COUNT(race) FROM mass_shooting) percen_white_shooters
FROM mass_shooting
WHERE race = 'White'
	
-- Number of case according to gender
SELECT gender, count(1) num_of_case FROM mass_shooting
GROUP BY gender
ORDER BY 2 DESC

--Number of case by shooting type
SELECT type, count(1) num_of_case FROM mass_shooting
GROUP BY type
ORDER BY 2 DESC






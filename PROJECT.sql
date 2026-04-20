-- SQL PROJECT: DATA CLEANING

CREATE DATABASE PROJECT11;
USE PROJECT11;

RENAME TABLE `layoffs (1)` TO layoffs_data;
SELECT * FROM layoffs_data;

-- FIRST THING WE WANT TO DO IS CREATE A STAGGING TABLE.
-- THIS IS THE ONE WE WILL WORK IN AND CLEAN THE DATA.
-- WE WANT A TABLE WITH THE RAW DATA IN CASE SOMETHING HAPPENS.

CREATE TABLE layoffs_data_staging
like layoffs_data;

INSERT layoffs_data_staging
SELECT * FROM layoffs_data;

SELECT * FROM layoffs_data_staging;

-- NOW WHEN WE ARE DATA CLEANING WE USUALLY FOLLOW A FEW STEPS
-- 1. CHECK FOR DUPLICATES AND REMOVE ANY.
-- 2. STANDARDIZE DATA AND FIX ERRORS.
-- 3. LOOK AT NULL VALUES AND SEE WHAT
-- 4. REMOVE ANY COLUMNS AND ROWS THAT ARE NOT NECCESARY

-- 1. REMOVE DULPICATES
-- WE DID PARTITIONING
SELECT COMPANY, INDUSTRY, TOTAL_LAID_OFF, `DATE`,
	ROW_NUMBER() OVER(
		PARTITION BY COMPANY, INDUSTRY, TOTAL_LAID_OFF, `DATE`)
        AS ROW_NUM
	FROM layoffs_data_staging;

-- TO SEE ROW_NUM > 1, THOSE ARE DUPLICATE ROWS
SELECT * FROM
(
	SELECT COMPANY, INDUSTRY, TOTAL_LAID_OFF, `DATE`,
		ROW_NUMBER() OVER(
			PARTITION BY COMPANY, INDUSTRY, TOTAL_LAID_OFF, `DATE`)
			AS ROW_NUM
	FROM layoffs_data_staging
) DUPLICATES
WHERE ROW_NUM > 1;

-- ODA IS A COMPANY WHICH APPERS 3 TIMES 
SELECT * FROM layoffs_data_staging WHERE COMPANY ='ODA';
-- ODA HAS NO DUPLICATES SOME VALUES ARE DIFF

SELECT * FROM layoffs_data_staging WHERE COMPANY ='CASPER';
SELECT * FROM layoffs_data_staging WHERE COMPANY ='CAZOO';

-- NOW CHECKING FOR ALL THE COLUMNS 
SELECT * FROM (
        SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions,
               ROW_NUMBER() OVER (
                   PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
               ) AS rn
        FROM layoffs_data_staging
    ) t
    WHERE rn > 1;

SELECT * FROM layoffs_data_staging;

ALTER TABLE layoffs_data_staging ADD ROW_NUM INT;

CREATE TABLE `layoffs_data_staging2` (
 `company` text,
 `location`text,
 `industry`text,
 `total_laid_off` INT,
 `percentage_laid_off` text,
 `date` text,
 `stage`text,
 `country` text,
 `funds_raised_millions` int,
 row_num INT
 );

INSERT INTO layoffs_data_staging2
(`company`, `location`, `industry`, `total_laid_off`, `percentage_laid_off`, `date`, `stage`, `country`, `funds_raised_millions`, `row_num`)

SELECT 
    `company`,
    `location`,
    `industry`,
    `total_laid_off`,
    `percentage_laid_off`,
    `date`,
    `stage`,
    `country`,
    `funds_raised_millions`,
    ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, total_laid_off,
                     percentage_laid_off, date, stage, country, funds_raised_millions
    ) AS row_num
FROM layoffs_data_staging;

-- NOW DELETE FROM layoffs_data_staging2
DELETE FROM layoffs_data_staging2
WHERE ROW_NUM >= 2;

SET SQL_SAFE_UPDATE = 0;

SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS unique_rows
FROM layoffs_data_staging;

-- 2. STANDARDIZE DATA

SELECT * FROM layoffs_data_staging2;
-- IF WE LOOK AT THE INDUSTRY IT LOOKS LIKE WE HAVE SOME NULL
-- AND EMPTY ROWS, LETS TAKE A LOOK AT THESE

SELECT DISTINCT INDUSTRY
FROM layoffs_data_staging2
ORDER BY INDUSTRY;

SELECT * FROM layoffs_data_staging2
WHERE INDUSTRY IS NULL
OR INDUSTRY = ''
ORDER BY INDUSTRY;

SELECT * FROM layoffs_data_staging2
WHERE COMPANY LIKE 'BALLY%';

-- NOTHINH WRONG HERE
SELECT * FROM layoffs_data_staging2
WHERE COMPANY LIKE 'AIRBNB%';

-- IT LOOKS LIKE AIRBNB IS A TRAVEL, BUT THIS ONE ISN'T JUST POLPULATED
-- I'M SURE IT'S THE SAME FOR THE OTHERS 
-- WHAT WE CAN DO IS WRITE A QUERY THAT IF ANOTHER ROW WITH THE SAME COMPANY NAME
-- IT WILL UPDATE IT TO NON-NULL INDUSTRY VALUES
-- MAKES IT EASY SO IF THERE WERE THOUSANDS WE WOULDN'T HAVE TO MANUALLY CHECK THEM ALL

-- WE SHOULD SET THE BLANKS TO NULL SINCE THOSE ARE TYPICALLY EASIER TO WORK WITH
UPDATE layoffs_data_staging2
SET INDUSTRY = null
WHERE INDUSTRY = '';

-- NOW IF WE CHECK THOSE ARE ALL NULL
SELECT * FROM layoffs_data_staging2
WHERE INDUSTRY IS NULL
OR INDUSTRY = ''
ORDER BY INDUSTRY;

-- NOW WE NEED TO POPULATE THOSE NULLS IF POSSIBLE
UPDATE layoffs_data_staging2 t1
JOIN layoffs_data_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- and if we check it looks like Bally's was
-- the only one without a populated row to populate this null values

SELECT *
FROM layoffs_data_staging2
WHERE industry IS NULL
OR industry = ''
ORDER BY INDUSTRY;

-- I also noticed the Crypto has multiple different variations.
-- We need to standardize that - let's say all to Crypto

SELECT DISTINCT industry
FROM layoffs_data_staging2
ORDER BY industry;

UPDATE layoffs_data_staging2
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');

-- now that's taken care of:
SELECT DISTINCT industry
FROM layoffs_data_staging2
ORDER BY industry;

select * from layoffs_data_staging2;
-- we also need to look at 

-- everything looks good except apparently
-- we have some "united states" and some "united states."
-- with a period at the end. let's standardize this.

SELECT DISTINCT country
FROM layoffs_data_staging2
ORDER BY country;

UPDATE layoffs_data_staging2
SET country = TRIM(TRAILING '.' FROM country); 
-- This query will successfully remove any trailing periods from the country column.

-- now if we run this again it is fixed
SELECT DISTINCT country
FROM layoffs_data_staging2
ORDER BY country;

-- Let's also fix the date columns:
SELECT * FROM layoffs_data_staging2;

-- we can use str_to_date to update this field
UPDATE layoffs_data_staging2
SET `date` = 
CASE
    -- Handle M/D/YYYY or MM/DD/YYYY
    WHEN `date` REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
        THEN STR_TO_DATE(`date`, '%m/%d/%Y')
    
    -- Handle YYYY-MM-DD (already correct format)
    WHEN `date` REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
        THEN `date`
    
    -- Else set NULL for invalid values
    ELSE NULL
END;

SELECT * FROM layoffs_data_staging2;

-- 3. Look at Null Values

-- the null values in total_laid_off, percentage_laid_off, and funds_raised_millions 
-- all look normal. I don't think I want to change that
-- I like having them null because it makes it easier for calculations during the EDA phase
-- so there isn't anything I want to change with the null values

-- 4. remove any columns and rows we need to
SELECT * FROM layoffs_data_staging2 
WHERE TOTAL_LAID_OFF IS NULL;

SELECT * FROM layoffs_data_staging2 
WHERE TOTAL_LAID_OFF IS NULL
AND PERCENTAGE_LAID_OFF IS NULL;

-- DELETE USELESS DATA WE CANT REALLY USE
DELETE FROM layoffs_data_staging2
WHERE TOTAL_LAID_OFF IS NULL
AND PERCENTAGE_LAID_OFF IS NULL;

SET SQL_SAFE_UPDATES = 0;

SELECT * FROM layoffs_data_staging2;

ALTER TABLE layoffs_data_staging2
DROP COLUMN ROW_NUM;

SELECT * FROM layoffs_data_staging2;

-- EDA

-- Here we are jsut going to explore the data and find trends or patterns or 
-- anything interesting like outliers
-- A ={1,2,3,4,5,6,7,8,100}
-- normally when you start the EDA process you have some idea of what you're looking for

-- with this info we are just going to look around and see what we find!

SELECT * FROM layoffs_data_staging2;

-- EASIER QUERIES

SELECT MAX(TOTAL_LAID_OFF)
FROM layoffs_data_staging2;

-- LOOKING AT PERCENTAGE TO SEE HOW BIG THESE LAYOFF WERE
SELECT MAX(PERCENTAGE_LAID_OFF) , MIN(PERCENTAGE_LAID_OFF)
FROM layoffs_data_staging2
WHERE PERCENTAGE_LAID_OFF IS NOT NULL;

-- WHICH COMPANIES HAD 1 WHICH IS BASICALLY 100 PERCENTOF THEY COMPANY LAID OFF
SELECT * FROM layoffs_data_staging2
WHERE PERCENTAGE_LAID_OFF = 1;
-- these are mostly startups it looks like who all went 
-- out of business during this time
 
-- if we order by funds_raised_millions we can see
-- how big some of these companies were
SELECT * FROM layoffs_data_staging2
WHERE PERCENTAGE_LAID_OFF = 1
ORDER BY FUNDS_RAISED_MILLIONS DESC;

-- BritishVolt looks like an EV company, Quibi! 
-- I recognize that company - wow raised like 2 billion 
-- dollars and went under - ouch

-- SOMEWHAT TOUGHER AND MOSTLY USING GROUP BY

-- COMPANIES WITH THE BIGGEST SINGLE DAY LAYOFF

SELECT COMPANY, TOTAL_LAID_OFF
FROM layoffs_data_staging2
ORDER BY 2 DESC
LIMIT 5;
-- NOW THATS JUST ON A SINGLE DAY

-- COMAPNIES WITH THE MOST TOTAL LAYOFFS
SELECT COMPANY, SUM(TOTAL_LAID_OFF)
FROM layoffs_data_staging2
GROUP BY COMPANY
ORDER BY 2 DESC
LIMIT 10;

-- by location
 SELECT location, SUM(total_laid_off)
 FROM layoffs_data_staging2
 GROUP BY location
 ORDER BY 2 DESC
 LIMIT 10;
 
-- THIS IS TOTAL IN THE PAST 3 YEARS OR IN THE DATASET

SELECT COUNTRY, SUM(TOTAL_LAID_OFF)
FROM layoffs_data_staging2
GROUP BY COUNTRY
ORDER BY 2 DESC;

SELECT YEAR(DATE), SUM(TOTAL_LAID_OFF)
FROM layoffs_data_staging2
GROUP BY YEAR(DATE)
ORDER BY 1 ASC;

SELECT INDUSTRY, SUM(TOTAL_LAID_OFF)
FROM layoffs_data_staging2
GROUP BY INDUSTRY
ORDER BY 2 ASC;

SELECT STAGE, SUM(TOTAL_LAID_OFF)
FROM layoffs_data_staging2
GROUP BY STAGE
ORDER BY 2 ASC;

WITH Company_Year AS 
 (
 SELECT company, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off
 FROM layoffs_data_staging2
 GROUP BY company, YEAR(date)
 )
 , Company_Year_Rank AS (
 SELECT company, years, total_laid_off, DENSE_RANK() OVER (PARTITION BY years ORDER BY 
 total_laid_off DESC) AS ranking
 FROM Company_Year
 )
 SELECT company, years, total_laid_off, ranking
 FROM Company_Year_Rank
 WHERE ranking <= 3
 AND years IS NOT NULL
 ORDER BY years ASC, total_laid_off DESC;
 
 -- ROLLING TOTAL OF LAYOFFS PER MONTH
SELECT SUBSTRING(DATE,1,7) AS DATES, SUM(TOTAL_LAID_OFF) AS TOTAL_LAID_OFF
FROM layoffs_data_staging2
GROUP BY DATES
ORDER BY DATES ASC;

-- NOW USE IT IN A CTE SO WE CAN QUERY OFF OF IT
WITH DATE_CTE AS 
 (
 SELECT SUBSTRING(date,1,7) as dates, SUM(total_laid_off) AS total_laid_off
 FROM layoffs_data_staging2
 GROUP BY dates
 ORDER BY dates ASC
 )
 SELECT dates, SUM(total_laid_off) OVER (ORDER BY dates ASC) as rolling_total_layoffs
 FROM DATE_CTE
 ORDER BY dates ASC;
 
 
 SELECT * FROM layoffs_data_staging2;
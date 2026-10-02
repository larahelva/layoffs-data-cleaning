-- Data cleaning workflow for the layoffs dataset


-- 1. Identify duplicate rows
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,
 `date` , stage, country, funds_raised_millions) AS row_num
 FROM layoffs_staging; 
  

WITH duplicate_cte AS
( SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,
`date`, stage, country, funds_raised_millions) AS row_num
 FROM layoffs_staging
)
SELECT *
FROM duplicate_cte 
WHERE row_num > 1;



-- DELETE 
-- FROM duplicate_cte
-- WHERE row_num > 1; c 

-- 2. Create staging table with row numbers
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num`INT 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- 3. Insert data and assign row numbers
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,
`date`, stage, country, funds_raised_millions) AS row_num
 FROM layoffs_staging;


-- 4. Remove duplicate rows
DELETE
FROM layoffs_staging2
WHERE row_num > 1;


-- 5. Standardize company names
SELECT company, TRIM(company)
FROM layoffs_staging2;


UPDATE layoffs_staging2
SET company = TRIM(company);



-- 6. Check distinct industries
SELECT distinct industry
From layoffs_staging2
ORDER BY 1;


-- 7. Standardize country values
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%' ;

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;


-- 8. Convert date from text to DATE
select `date`,
str_to_date(`date`, '%m/%d/%Y')
FROM layoffs_staging2;


UPDATE layoffs_staging2
SET `date` = str_to_date(`date`, '%m/%d/%Y');


ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- 9. Find missing industry values
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';


-- Convert blank industries to NULL
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = ''; 


-- 10. Find missing industries using the same company
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
   AND t1.location = t2.location
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;

SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;


-- 11. Fill missing industry values
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;


-- 12. Remove rows with no layoff information
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;


DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;


-- 13. Remove helper column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


-- 14. Final cleaned dataset
SELECT *
FROM layoffs_staging2;















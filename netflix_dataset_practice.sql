-- 1. Count the number of Movies vs TV Shows
select type,count(*) from ar.netflix_titles
group by 1 ;

-- 2. Find the most common rating for movies and TV shows

select type,rating from 
(select type,rating,count(*) ,rank() over(partition by type order by count(*) desc) as rs
from ar.netflix_titles
group by 1,2 ) as t1
where rs=1;

-- 3. List all movies released in a specific year (e.g., 2020)
select * from ar.netflix_titles
where type='Movie' and release_year=2020;

-- 4). Find the top 5 countries with the most content on Netflix

WITH RECURSIVE countries AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(country, ',', 1)) AS country,
        SUBSTRING(country, LENGTH(SUBSTRING_INDEX(country, ',', 1)) + 2) AS remaining
    FROM ar.netflix_titles
    WHERE country IS NOT NULL

    UNION ALL

    SELECT
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)),
        CASE
            WHEN remaining LIKE '%,%'
            THEN SUBSTRING(remaining, LENGTH(SUBSTRING_INDEX(remaining, ',', 1)) + 2)
            ELSE ''
        END
    FROM countries
    WHERE remaining <> ''
)
SELECT 
    country,
    COUNT(*) AS total_content
FROM countries
GROUP BY country
ORDER BY total_content DESC
LIMIT 5;

-- 5. Identify the longest movie

SELECT title, duration
FROM ar.netflix_titles
WHERE type = 'Movie'
  AND duration LIKE '% min'
ORDER BY CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) DESC
LIMIT 1;

-- 6. Find content added in the last 5 years

UPDATE ar.netflix_titles
SET date_added = STR_TO_DATE(date_added, '%M %e, %Y'); 
ALTER TABLE ar.netflix_titles
MODIFY COLUMN date_added DATE;
SELECT *
FROM ar.netflix_titles
WHERE date_added >= DATE_SUB(CURDATE(), INTERVAL 5 YEAR);

-- 7. Find all the movies/TV shows by director 'Rajiv Chilaka'!
select * from ar.netflix_titles
where director="Rajiv Chilaka";

-- 8. List all TV shows with more than 5 seasons
SELECT title, duration
FROM ar.netflix_titles
WHERE type = 'TV Show'
  AND CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) > 5;
  
  -- 9. Count the number of content items in each genre
  SELECT TRIM(j.genre) AS genre,
       COUNT(*) AS content_count
FROM ar.netflix_titles n
JOIN JSON_TABLE(
    CONCAT('["', REPLACE(n.listed_in, ', ', '","'), '"]'),
    '$[*]' COLUMNS (
        genre VARCHAR(100) PATH '$'
    )
) j
GROUP BY TRIM(j.genre)
ORDER BY content_count DESC;
  
  -- 10.Find each year and the average numbers of content release in India on netflix. 
  -- return top 5 year with highest avg content release!
select release_year,count(release_year) as cont_content from ar.netflix_titles
group by release_year order by cont_content desc limit 5;

SELECT AVG(cont_content) AS avg_content
FROM (
    SELECT 
        release_year,
        COUNT(*) AS cont_content
    FROM ar.netflix_titles
    WHERE country = 'India'
    GROUP BY release_year
) AS yearly_content;
  
-- 11. List all movies that are documentaries
SELECT title
FROM ar.netflix_titles
WHERE type = 'Movie'
  AND (
      listed_in = 'Documentaries'
      OR listed_in LIKE 'Documentaries, %'
      OR listed_in LIKE '%, Documentaries'
      OR listed_in LIKE '%, Documentaries, %'
  );
  
-- 12. Find all content without a director
update ar.netflix_titles
set  director=null
where director="" ;
select * from ar.netflix_titles
where director is null ;

-- 13. Find how many movies actor 'Salman Khan' appeared in last 10 years!  
select count(*) from ar.netflix_titles
where type="Movie"
and cast like  '%Salman Khan' or 'Salman Khan%'
and release_year between 2012 and 2022;
  
-- 14. Find the top 10 actors who have appeared in the highest number of movies produced in India.
SELECT 
    TRIM(a.actor) AS actor,
    COUNT(*) AS movie_count
FROM ar.netflix_titles n
JOIN JSON_TABLE(
    CONCAT('["', REPLACE(n.cast, ', ', '","'), '"]'),
    '$[*]' COLUMNS (
        actor VARCHAR(100) PATH '$'
    )
) a
WHERE n.type = 'Movie'
  AND n.country LIKE '%India%'
GROUP BY TRIM(a.actor)
ORDER BY movie_count DESC
LIMIT 10;
  
-- 15.
-- Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
-- the description field. Label content containing these keywords as 'Bad' and all other 
-- content as 'Good'. Count how many items fall into each category.
SELECT 
    CASE
        WHEN description LIKE '%kill%'
          OR description LIKE '%violence%'
        THEN 'Bad'
        ELSE 'Good'
    END AS category,
    COUNT(*) AS content_count
FROM ar.netflix_titles
GROUP BY category;
  
  
  
  
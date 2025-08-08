/*
Case Study #8 – Fresh Segments (MySQL 8+)
Assumed tables:
- interest_metrics(segment_id, month_year, num_customers, interest_score, composition, ranking)
- interest_map(segment_id, interest_topic, interest_category, interest_subcategory)
*/

-- A. Data Cleaning & Exploration

-- A1: Check distinct months
SELECT DISTINCT month_year
FROM interest_metrics
ORDER BY STR_TO_DATE(month_year, '%M %Y');

-- A2: Count distinct segments
SELECT COUNT(DISTINCT segment_id) AS total_segments
FROM interest_metrics;

-- A3: Count distinct interest topics
SELECT COUNT(DISTINCT interest_topic) AS total_topics
FROM interest_map;

-- A4: Segments with multiple categories
SELECT segment_id, COUNT(DISTINCT interest_category) AS category_count
FROM interest_map
GROUP BY segment_id
HAVING category_count > 1;

-- B. Segment Performance Over Time

-- B1: Average interest score per month
SELECT month_year, ROUND(AVG(interest_score), 2) AS avg_score
FROM interest_metrics
GROUP BY month_year
ORDER BY STR_TO_DATE(month_year, '%M %Y');

-- B2: Top 5 segments by interest score each month
SELECT month_year, segment_id, interest_score
FROM (
    SELECT month_year, segment_id, interest_score,
           ROW_NUMBER() OVER (PARTITION BY month_year ORDER BY interest_score DESC) AS rn
    FROM interest_metrics
) ranked
WHERE rn <= 5;

-- B3: Segments with improving interest score trend
WITH score_change AS (
    SELECT segment_id, 
           MIN(interest_score) AS min_score,
           MAX(interest_score) AS max_score
    FROM interest_metrics
    GROUP BY segment_id
)
SELECT segment_id, min_score, max_score
FROM score_change
WHERE max_score > min_score;

-- C. Composition & Category Analysis

-- C1: Average composition by category
SELECT imap.interest_category, ROUND(AVG(im.composition), 2) AS avg_composition
FROM interest_metrics im
JOIN interest_map imap ON im.segment_id = imap.segment_id
GROUP BY imap.interest_category
ORDER BY avg_composition DESC;

-- C2: Category-wise ranking count
SELECT imap.interest_category, COUNT(*) AS ranking_count
FROM interest_metrics im
JOIN interest_map imap ON im.segment_id = imap.segment_id
WHERE im.ranking <= 5
GROUP BY imap.interest_category
ORDER BY ranking_count DESC;

-- C3: Top category each month by average interest score
WITH cat_scores AS (
    SELECT month_year, imap.interest_category, ROUND(AVG(im.interest_score), 2) AS avg_score
    FROM interest_metrics im
    JOIN interest_map imap ON im.segment_id = imap.segment_id
    GROUP BY month_year, imap.interest_category
)
SELECT month_year, interest_category, avg_score
FROM (
    SELECT month_year, interest_category, avg_score,
           ROW_NUMBER() OVER (PARTITION BY month_year ORDER BY avg_score DESC) AS rn
    FROM cat_scores
) ranked
WHERE rn = 1;

-- D. Ranking Trends

-- D1: Segments consistently ranked in top 3
SELECT segment_id, COUNT(DISTINCT month_year) AS months_in_top3
FROM interest_metrics
WHERE ranking <= 3
GROUP BY segment_id
HAVING months_in_top3 = (SELECT COUNT(DISTINCT month_year) FROM interest_metrics);

-- D2: Average ranking per category
SELECT imap.interest_category, ROUND(AVG(im.ranking), 2) AS avg_ranking
FROM interest_metrics im
JOIN interest_map imap ON im.segment_id = imap.segment_id
GROUP BY imap.interest_category
ORDER BY avg_ranking;

-- D3: Ranking improvement calculation
WITH rank_change AS (
    SELECT segment_id, 
           MIN(ranking) AS best_rank,
           MAX(ranking) AS worst_rank
    FROM interest_metrics
    GROUP BY segment_id
)
SELECT segment_id, worst_rank, best_rank, (worst_rank - best_rank) AS rank_improvement
FROM rank_change
WHERE (worst_rank - best_rank) > 0;

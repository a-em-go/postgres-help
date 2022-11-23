select * from pg_catalog.pg_stat_activity;
select * from pg_catalog.pg_stat_database;
select * from pg_catalog.pg_stat_user_tables;
select * from pg_catalog.pg_statio_user_tables;
select * from pg_catalog.pg_stat_user_indexes;

-- найти большие таблицы, которые часто просматриваются после-
-- довательно. Эти таблицы окажутся в начале списка и будут содержать умопом-
-- рачительные значения в поле seq_tup_read.
SELECT schemaname, relname, seq_scan, seq_tup_read,
       seq_tup_read / seq_scan AS avg, idx_scan
FROM pg_catalog.pg_stat_user_tables
WHERE seq_scan > 0
ORDER BY seq_tup_read DESC
    LIMIT 25;

-- неиспользуемые индексы и их размер
SELECT schemaname, relname, indexrelname, idx_scan,
       pg_size_pretty(pg_relation_size(indexrelid)) AS idx_size,
       pg_size_pretty(sum(pg_relation_size(indexrelid))
           OVER (ORDER BY idx_scan, indexrelid)) AS total
FROM pg_catalog.pg_stat_user_indexes
ORDER BY 6 ;
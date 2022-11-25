select * from pg_catalog.pg_stat_activity;
-- сколько запросов к базе данных выполняется в данный момент
SELECT datname,
       count(*) AS open,
       count(*) FILTER (WHERE state = 'active') AS active,
       count(*) FILTER (WHERE state = 'idle') AS idle,
       count(*) FILTER (WHERE state = 'idle in transaction') AS idle_in_trans
FROM pg_stat_activity
WHERE backend_type = 'client backend'
GROUP BY ROLLUP(1);

-- Если количество неактивных запросов внутри транзакции велико,
-- то нужно разобраться, как долго эти транзакции открыты:
SELECT pid, xact_start, now() - xact_start AS duration
FROM pg_stat_activity
WHERE state LIKE '%transaction%'
ORDER BY 3 DESC;

-- долгие запросы
SELECT now() - query_start AS duration, datname, query
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY 1 DESC;

-- Обратите внимание на два последних поля: blk_read_time и blk_write_time. Они
-- говорят, сколько времени PostgreSQL потратила на ожидание ответа от опера-
-- ционной системы. Подчеркнем, что измеряется не само время ожидания диска,
-- а время, понадобившееся операционной системе, чтобы вернуть данные.
-- Часто значения blk_read_time и blk_write_time велики, когда велики значения
-- temp_files и temp_bytes. Во многих случаях это свидетельствует о неправильной
-- установке параметров work_mem или maintenance_work_mem.
select * from pg_catalog.pg_stat_database;
select * from pg_catalog.pg_stat_user_tables;
select * from pg_catalog.pg_statio_user_tables;
select * from pg_catalog.pg_stat_user_indexes;
-- фоновый процесс записи или процесс контрольной точки
select * from pg_catalog.pg_stat_bgwriter;
-- архивация
select * from pg_catalog.pg_stat_archiver;
-- не стороне мастера
select * from pg_catalog.pg_stat_replication;
-- не стороне реплики
select * from pg_catalog.pg_stat_wal_receiver;
--
select * from pg_catalog.pg_stat_xact_user_tables;
select * from pg_catalog.pg_stat_progress_vacuum;

-- агрегированные сведения о запросах
select * from pg_catalog.pg_stat_statements;

-- непроизводительные запросы
SELECT round((100 * total_time / sum(total_time) OVER ())::numeric, 2) percent,
       round(total_time::numeric, 2) AS total,
       calls,
       round(mean_time::numeric, 2) AS mean,
       substring(query, 1, 40)
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;



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
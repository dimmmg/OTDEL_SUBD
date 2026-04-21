-- Запуск полного учебного проекта в psql
-- Команда из папки проекта:
-- psql -U postgres -d content_agency_db -f 00_run_all.sql

\encoding UTF8

\i 01_schema.sql
\i 02_seed_01_core.sql
\i 02_seed_02_projects.sql
\i 02_seed_03_tasks_checklists.sql
\i 02_seed_04_finance_materials.sql

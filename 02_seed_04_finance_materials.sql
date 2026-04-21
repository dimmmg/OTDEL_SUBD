-- Тестовые данные: встречи, оплаты, выплаты, версии материалов и ссылки
-- Запускать после 02_seed_03_tasks_checklists.sql

BEGIN;

INSERT INTO meetings (
    meeting_id, project_id, meeting_type, meeting_at, format, location_or_link, organizer_id, status, notes
) VALUES
(1, 1, 'primary_call', '2026-03-04 11:00:00', 'online', 'https://meet.example.com/baikalfood-intro', 2, 'completed', 'Первичный созвон, подтвержден интерес'),
(2, 1, 'briefing', '2026-03-05 15:00:00', 'online', 'https://meet.example.com/baikalfood-brief', 2, 'completed', 'Заполнен основной бриф'),
(3, 1, 'shooting', '2026-04-12 10:00:00', 'offline', 'Иркутская область, сыроварня клиента', 5, 'planned', 'Съемка продукта и производства'),
(4, 2, 'planning', '2026-03-18 10:00:00', 'online', 'https://meet.example.com/angara-plan', 2, 'completed', 'План работ на первый месяц'),
(5, 2, 'review', '2026-04-17 16:00:00', 'online', 'https://meet.example.com/angara-review', 3, 'completed', 'Правки по креативам и титрам'),
(6, 3, 'briefing', '2026-03-20 14:00:00', 'online', 'https://meet.example.com/morozova-brief', 7, 'completed', 'Обсуждены темы экспертности'),
(7, 4, 'shooting', '2026-03-11 18:30:00', 'offline', 'Кофейня "Северное зерно"', 6, 'completed', 'Съемка прошла после закрытия кофейни'),
(8, 5, 'meeting', '2026-03-18 15:00:00', 'offline', 'СТО "Моторика"', 2, 'completed', 'Осмотр площадки и ограничений'),
(9, 6, 'review', '2026-04-09 12:00:00', 'online', 'https://meet.example.com/vetrova-catalog', 3, 'completed', 'Каталог принят с мелкими замечаниями'),
(10, 7, 'planning', '2026-04-18 13:00:00', 'online', 'https://meet.example.com/baikaltravel-route', 6, 'planned', 'Планирование маршрутов и резервных дат'),
(11, 8, 'meeting', '2026-04-22 17:00:00', 'hybrid', 'Культурный центр "Арка" и https://meet.example.com/arka-board', 3, 'planned', 'Презентация концепций совету'),
(12, 10, 'postbrief', '2026-04-12 16:00:00', 'online', 'https://meet.example.com/northstar-postbrief', 2, 'completed', 'Собрана обратная связь по курсу');

INSERT INTO payments (payment_id, project_id, payment_type, amount, payment_date, status, comment) VALUES
(1, 1, 'prepayment', 210000, '2026-03-12', 'paid', '50% предоплата после утверждения сметы'),
(2, 1, 'final', 210000, NULL, 'planned', 'Финальная оплата после сдачи материалов'),
(3, 2, 'prepayment', 300000, '2026-03-14', 'paid', 'Старт абонентского сопровождения'),
(4, 2, 'intermediate', 175000, '2026-04-15', 'paid', 'Оплата второго месяца'),
(5, 2, 'final', 175000, NULL, 'invoiced', 'Финальный счет выставлен'),
(6, 3, 'prepayment', 140000, '2026-03-21', 'paid', 'Предоплата проекта'),
(7, 3, 'final', 140000, NULL, 'planned', 'Оплата после утверждения визуала'),
(8, 4, 'prepayment', 90000, '2026-02-26', 'paid', 'Предоплата 50%'),
(9, 4, 'final', 90000, '2026-04-18', 'paid', 'Оплачено после передачи роликов'),
(10, 5, 'prepayment', 170000, '2026-03-23', 'paid', 'Предоплата абонентского периода'),
(11, 5, 'final', 170000, NULL, 'planned', 'Оплата после отчетного периода'),
(12, 6, 'prepayment', 110000, '2026-03-02', 'paid', 'Предоплата каталога'),
(13, 6, 'final', 110000, '2026-04-26', 'paid', 'Финальная оплата получена'),
(14, 7, 'prepayment', 260000, NULL, 'invoiced', 'Счет на предоплату отправлен'),
(15, 8, 'prepayment', 150000, NULL, 'planned', 'Будет выставлен после согласования условий'),
(16, 9, 'prepayment', 180000, '2026-04-12', 'paid', 'Предоплата первого месяца'),
(17, 10, 'prepayment', 120000, '2026-02-12', 'paid', 'Предоплата упаковки курса'),
(18, 10, 'final', 120000, '2026-04-14', 'paid', 'Финальная оплата и закрытие');

INSERT INTO employee_payouts (
    payout_id, project_id, employee_id, payout_type, salary_period,
    fixed_part, percent_part, gross_amount, tax_amount, net_amount, payout_date, comment
) VALUES
(1, 1, 3, 'mixed', '2026-03-01', 30000, 10500, 40500, 5265, 35235, '2026-03-31', 'Креативная стратегия запуска'),
(2, 1, 5, 'mixed', '2026-04-01', 25000, 7000, 32000, 4160, 27840, NULL, 'Подготовка и съемочный этап'),
(3, 2, 7, 'mixed', '2026-03-01', 28000, 9750, 37750, 4907.50, 32842.50, '2026-03-31', 'Контент-план и тексты ЖК'),
(4, 2, 4, 'mixed', '2026-04-01', 26000, 9750, 35750, 4647.50, 31102.50, NULL, 'Дизайн креативов ЖК'),
(5, 2, 8, 'mixed', '2026-04-01', 26000, 8450, 34450, 4478.50, 29971.50, NULL, 'Монтаж видео по ЖК'),
(6, 3, 7, 'mixed', '2026-04-01', 25000, 4200, 29200, 3796, 25404, NULL, 'Контент-план личного бренда'),
(7, 4, 6, 'mixed', '2026-03-01', 22000, 2160, 24160, 3140.80, 21019.20, '2026-04-05', 'Видеосъемка кофейни'),
(8, 4, 8, 'mixed', '2026-04-01', 24000, 2340, 26340, 3424.20, 22915.80, '2026-04-18', 'Монтаж роликов кофейни'),
(9, 5, 4, 'mixed', '2026-04-01', 24000, 5100, 29100, 3783, 25317, NULL, 'Шаблоны автосервиса'),
(10, 6, 5, 'mixed', '2026-03-01', 30000, 2200, 32200, 4186, 28014, '2026-04-01', 'Предметная съемка украшений'),
(11, 6, 4, 'mixed', '2026-04-01', 23000, 3300, 26300, 3419, 22881, '2026-04-26', 'Карточки товаров'),
(12, 10, 8, 'mixed', '2026-04-01', 30000, 3120, 33120, 4305.60, 28814.40, '2026-04-14', 'Монтаж курса английского');

INSERT INTO project_versions (
    version_id, project_id, stage_id, version_number, uploaded_by, description,
    sent_to_client_at, is_approved, client_feedback, created_at
) VALUES
(1, 1, 4, 1, 3, 'Moodboard запуска линейки сыров v1', '2026-04-03 12:00:00', FALSE, 'Добавить больше локального характера и меньше студийности', '2026-04-03 10:30:00'),
(2, 1, 4, 2, 3, 'Moodboard запуска линейки сыров v2', '2026-04-07 15:00:00', TRUE, 'Концепция утверждена', '2026-04-07 13:20:00'),
(3, 2, 8, 1, 7, 'Контент-план ЖК на апрель v1', '2026-03-24 16:00:00', FALSE, 'Нужно усилить ипотечный блок', '2026-03-24 14:10:00'),
(4, 2, 8, 2, 7, 'Контент-план ЖК на апрель v2', '2026-03-25 17:00:00', TRUE, 'Утверждено', '2026-03-25 15:40:00'),
(5, 2, 10, 1, 8, 'Ролик о районе v1', '2026-04-18 17:30:00', FALSE, 'Исправить титры и сократить начало', '2026-04-18 15:50:00'),
(6, 2, 12, 2, 8, 'Ролик о районе v2 с правками', '2026-04-20 11:00:00', FALSE, 'Ожидается повторная проверка', '2026-04-20 10:10:00'),
(7, 3, 16, 1, 7, 'Контент-план личного бренда v1', '2026-04-16 13:00:00', FALSE, 'Слишком много экспертных терминов', '2026-04-16 11:20:00'),
(8, 4, 21, 1, 8, 'Ролики сезонного меню v1', '2026-03-28 18:00:00', FALSE, 'Заменить музыку в двух роликах', '2026-03-28 16:00:00'),
(9, 4, 21, 2, 8, 'Ролики сезонного меню v2', '2026-04-02 17:00:00', TRUE, 'Утверждено без дополнительных правок', '2026-04-02 16:20:00'),
(10, 5, 26, 1, 7, 'Рубрикатор автосервиса v1', '2026-04-12 12:00:00', FALSE, 'Добавить блок про гарантии', '2026-04-12 10:00:00'),
(11, 6, 30, 1, 4, 'Каталог украшений v1', '2026-04-05 14:00:00', FALSE, 'Проверить оттенок серебра на 8 позициях', '2026-04-05 12:30:00'),
(12, 6, 30, 2, 4, 'Каталог украшений v2', '2026-04-09 16:00:00', TRUE, 'Каталог принят', '2026-04-09 15:15:00'),
(13, 8, 37, 1, 4, 'Варианты концепции культурного центра v1', '2026-04-18 15:00:00', FALSE, 'Ожидает обсуждения с советом', '2026-04-18 13:00:00'),
(14, 10, 45, 1, 8, 'Финальные уроки курса v1', '2026-04-04 18:00:00', TRUE, 'Видео приняты', '2026-04-04 17:30:00'),
(15, 10, 46, 1, 2, 'Закрывающий отчет по курсу', '2026-04-14 15:00:00', TRUE, 'Отчет принят', '2026-04-14 14:30:00');

INSERT INTO project_links (
    link_id, project_id, stage_id, version_id, link_type, link_url, description, added_by, added_at
) VALUES
(1, 1, 3, NULL, 'brief', 'https://drive.example.com/baikalfood/brief', 'Бриф проекта БайкалФуд', 2, '2026-03-07 16:40:00'),
(2, 1, 4, 2, 'reference', 'https://drive.example.com/baikalfood/moodboard-v2', 'Утвержденный moodboard', 3, '2026-04-07 13:30:00'),
(3, 1, 5, NULL, 'drive_folder', 'https://drive.example.com/baikalfood/production', 'Рабочая папка съемочного этапа', 5, '2026-04-08 10:00:00'),
(4, 2, 8, 4, 'work_file', 'https://docs.example.com/angara/content-plan-april-v2', 'Контент-план ЖК на апрель', 7, '2026-03-25 16:00:00'),
(5, 2, 10, 5, 'work_file', 'https://drive.example.com/angara/video-district-v1', 'Черновой ролик о районе', 8, '2026-04-18 16:00:00'),
(6, 2, 12, 6, 'work_file', 'https://drive.example.com/angara/video-district-v2', 'Версия ролика с правками', 8, '2026-04-20 10:30:00'),
(7, 3, 16, 7, 'work_file', 'https://docs.example.com/morozova/content-plan-v1', 'Контент-план личного бренда', 7, '2026-04-16 11:30:00'),
(8, 4, 20, NULL, 'source_files', 'https://drive.example.com/coffee/source', 'Исходники съемки кофейни', 6, '2026-03-12 10:10:00'),
(9, 4, 21, 9, 'final_material', 'https://drive.example.com/coffee/final-reels', 'Финальные ролики кофейни', 8, '2026-04-02 16:40:00'),
(10, 5, 25, NULL, 'brief', 'https://drive.example.com/motorika/brief', 'Бриф автосервиса', 2, '2026-03-20 17:00:00'),
(11, 5, 26, 10, 'work_file', 'https://docs.example.com/motorika/rubricator-v1', 'Рубрикатор автосервиса', 7, '2026-04-12 10:20:00'),
(12, 6, 29, NULL, 'source_files', 'https://drive.example.com/vetrova/source-photo', 'Исходники предметной съемки', 5, '2026-03-24 17:40:00'),
(13, 6, 30, 12, 'final_material', 'https://drive.example.com/vetrova/catalog-final', 'Финальный каталог украшений', 4, '2026-04-09 15:40:00'),
(14, 7, 34, NULL, 'work_file', 'https://docs.example.com/baikaltravel/route-plan', 'Маршрутный план съемок', 6, '2026-04-18 12:00:00'),
(15, 8, 37, 13, 'reference', 'https://drive.example.com/arka/concept-v1', 'Концепции ребрендинга v1', 4, '2026-04-18 13:20:00'),
(16, 9, 41, NULL, 'drive_folder', 'https://drive.example.com/pulse/work', 'Рабочая папка фитнес-клуба', 7, '2026-04-13 11:00:00'),
(17, 10, 45, 14, 'final_material', 'https://drive.example.com/northstar/final-lessons', 'Финальные видео уроков', 8, '2026-04-04 18:20:00'),
(18, 10, 46, 15, 'final_material', 'https://drive.example.com/northstar/final-report', 'Закрывающий отчет', 2, '2026-04-14 15:20:00'),
(19, 10, 46, NULL, 'contract', 'https://docs.example.com/northstar/closing-docs', 'Закрывающие документы', 1, '2026-04-14 15:40:00');

SELECT setval(pg_get_serial_sequence('positions', 'position_id'), (SELECT MAX(position_id) FROM positions));
SELECT setval(pg_get_serial_sequence('teams', 'team_id'), (SELECT MAX(team_id) FROM teams));
SELECT setval(pg_get_serial_sequence('employees', 'employee_id'), (SELECT MAX(employee_id) FROM employees));
SELECT setval(pg_get_serial_sequence('clients', 'client_id'), (SELECT MAX(client_id) FROM clients));
SELECT setval(pg_get_serial_sequence('client_contacts', 'contact_id'), (SELECT MAX(contact_id) FROM client_contacts));
SELECT setval(pg_get_serial_sequence('services', 'service_id'), (SELECT MAX(service_id) FROM services));
SELECT setval(pg_get_serial_sequence('briefs', 'brief_id'), (SELECT MAX(brief_id) FROM briefs));
SELECT setval(pg_get_serial_sequence('projects', 'project_id'), (SELECT MAX(project_id) FROM projects));
SELECT setval(pg_get_serial_sequence('project_services', 'project_service_id'), (SELECT MAX(project_service_id) FROM project_services));
SELECT setval(pg_get_serial_sequence('project_stages', 'stage_id'), (SELECT MAX(stage_id) FROM project_stages));
SELECT setval(pg_get_serial_sequence('checklist_templates', 'template_id'), (SELECT MAX(template_id) FROM checklist_templates));
SELECT setval(pg_get_serial_sequence('checklist_items', 'item_id'), (SELECT MAX(item_id) FROM checklist_items));
SELECT setval(pg_get_serial_sequence('tasks', 'task_id'), (SELECT MAX(task_id) FROM tasks));
SELECT setval(pg_get_serial_sequence('task_checklist_status', 'task_checklist_status_id'), (SELECT MAX(task_checklist_status_id) FROM task_checklist_status));
SELECT setval(pg_get_serial_sequence('meetings', 'meeting_id'), (SELECT MAX(meeting_id) FROM meetings));
SELECT setval(pg_get_serial_sequence('payments', 'payment_id'), (SELECT MAX(payment_id) FROM payments));
SELECT setval(pg_get_serial_sequence('employee_payouts', 'payout_id'), (SELECT MAX(payout_id) FROM employee_payouts));
SELECT setval(pg_get_serial_sequence('project_versions', 'version_id'), (SELECT MAX(version_id) FROM project_versions));
SELECT setval(pg_get_serial_sequence('project_links', 'link_id'), (SELECT MAX(link_id) FROM project_links));

COMMIT;

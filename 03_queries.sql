-- Готовые SQL-запросы для учебного проекта
-- Параметры обозначены как $1, $2, если запрос предполагает ввод значения из интерфейса.

-- 1. Простые запросы

-- 1.1. Список сотрудников с должностями
SELECT
    e.employee_id,
    e.full_name,
    p.position_name,
    t.city_name AS team_city,
    e.telegram,
    e.phone,
    e.salary_type,
    e.fixed_salary,
    e.percent_rate,
    e.is_active
FROM employees e
JOIN positions p ON p.position_id = e.position_id
JOIN teams t ON t.team_id = e.team_id
ORDER BY p.position_name, e.full_name;

-- 1.2. Список клиентов
SELECT
    client_id,
    client_type,
    COALESCE(company_name, full_name) AS client_name,
    niche,
    short_tz,
    created_at
FROM clients
ORDER BY client_name;

-- 1.3. Список услуг
SELECT
    service_id,
    service_name,
    base_price,
    is_active
FROM services
ORDER BY service_name;

-- 1.4. Список проектов
SELECT
    project_id,
    project_name,
    project_type,
    status,
    start_date,
    planned_end_date,
    budget
FROM projects
ORDER BY start_date DESC, project_name;

-- 2. JOIN-запросы

-- 2.1. Проекты с клиентами и ответственными
SELECT
    p.project_id,
    p.project_name,
    COALESCE(c.company_name, c.full_name) AS client_name,
    p.project_type,
    p.status,
    director.full_name AS director_name,
    lead.full_name AS lead_name,
    creative.full_name AS creative_director_name,
    p.budget,
    p.start_date,
    p.planned_end_date
FROM projects p
JOIN clients c ON c.client_id = p.client_id
LEFT JOIN employees director ON director.employee_id = p.director_id
LEFT JOIN employees lead ON lead.employee_id = p.lead_id
LEFT JOIN employees creative ON creative.employee_id = p.creative_director_id
ORDER BY p.start_date DESC;

-- 2.2. Задачи с исполнителями и этапами
SELECT
    t.task_id,
    pr.project_name,
    ps.stage_name,
    t.task_name,
    assignee.full_name AS assignee_name,
    assigner.full_name AS assigner_name,
    t.priority,
    t.status,
    t.planned_hours,
    t.deadline
FROM tasks t
JOIN projects pr ON pr.project_id = t.project_id
JOIN project_stages ps ON ps.stage_id = t.stage_id
LEFT JOIN employees assignee ON assignee.employee_id = t.assignee_id
LEFT JOIN employees assigner ON assigner.employee_id = t.assigner_id
ORDER BY t.deadline NULLS LAST, t.priority DESC;

-- 2.3. Встречи по проектам
SELECT
    m.meeting_id,
    p.project_name,
    COALESCE(c.company_name, c.full_name) AS client_name,
    m.meeting_type,
    m.meeting_at,
    m.format,
    m.location_or_link,
    e.full_name AS organizer_name,
    m.status,
    m.notes
FROM meetings m
JOIN projects p ON p.project_id = m.project_id
JOIN clients c ON c.client_id = p.client_id
LEFT JOIN employees e ON e.employee_id = m.organizer_id
ORDER BY m.meeting_at;

-- 2.4. Оплаты по клиентам
SELECT
    pay.payment_id,
    COALESCE(c.company_name, c.full_name) AS client_name,
    p.project_name,
    pay.payment_type,
    pay.amount,
    pay.payment_date,
    pay.status,
    pay.comment
FROM payments pay
JOIN projects p ON p.project_id = pay.project_id
JOIN clients c ON c.client_id = p.client_id
ORDER BY pay.payment_date NULLS LAST, client_name;

-- 3. Вычисляемые запросы

-- 3.1. Общая выручка по проектам
SELECT
    p.project_id,
    p.project_name,
    p.budget AS planned_budget,
    COALESCE(SUM(pay.amount) FILTER (WHERE pay.status = 'paid'), 0) AS paid_revenue,
    p.budget - COALESCE(SUM(pay.amount) FILTER (WHERE pay.status = 'paid'), 0) AS remaining_amount
FROM projects p
LEFT JOIN payments pay ON pay.project_id = p.project_id
GROUP BY p.project_id, p.project_name, p.budget
ORDER BY paid_revenue DESC;

-- 3.2. Общая выручка по клиентам
SELECT
    c.client_id,
    COALESCE(c.company_name, c.full_name) AS client_name,
    COALESCE(SUM(pay.amount) FILTER (WHERE pay.status = 'paid'), 0) AS paid_revenue
FROM clients c
LEFT JOIN projects p ON p.client_id = c.client_id
LEFT JOIN payments pay ON pay.project_id = p.project_id
GROUP BY c.client_id, COALESCE(c.company_name, c.full_name)
ORDER BY paid_revenue DESC;

-- 3.3. Загрузка сотрудников по количеству активных задач
SELECT
    e.employee_id,
    e.full_name,
    pos.position_name,
    COUNT(t.task_id) FILTER (WHERE t.status NOT IN ('done', 'cancelled')) AS active_tasks,
    COALESCE(SUM(t.planned_hours) FILTER (WHERE t.status NOT IN ('done', 'cancelled')), 0) AS active_planned_hours
FROM employees e
JOIN positions pos ON pos.position_id = e.position_id
LEFT JOIN tasks t ON t.assignee_id = e.employee_id
GROUP BY e.employee_id, e.full_name, pos.position_name
ORDER BY active_tasks DESC, active_planned_hours DESC;

-- 3.4. Сумма выплат сотруднику
SELECT
    e.employee_id,
    e.full_name,
    SUM(ep.gross_amount) AS gross_total,
    SUM(ep.tax_amount) AS tax_total,
    SUM(ep.net_amount) AS net_total
FROM employees e
JOIN employee_payouts ep ON ep.employee_id = e.employee_id
GROUP BY e.employee_id, e.full_name
ORDER BY net_total DESC;

-- 3.5. Количество проектов по статусам
SELECT
    status,
    COUNT(*) AS project_count,
    SUM(budget) AS total_budget
FROM projects
GROUP BY status
ORDER BY project_count DESC, status;

-- 4. Параметрические запросы

-- 4.1. Проекты конкретного клиента: $1 = client_id
SELECT
    project_id,
    project_name,
    project_type,
    status,
    start_date,
    planned_end_date,
    budget
FROM projects
WHERE client_id = $1
ORDER BY start_date DESC;

-- 4.2. Задачи конкретного сотрудника: $1 = employee_id
SELECT
    t.task_id,
    p.project_name,
    ps.stage_name,
    t.task_name,
    t.priority,
    t.status,
    t.deadline
FROM tasks t
JOIN projects p ON p.project_id = t.project_id
JOIN project_stages ps ON ps.stage_id = t.stage_id
WHERE t.assignee_id = $1
ORDER BY t.deadline NULLS LAST;

-- 4.3. Оплаты за период: $1 = date_from, $2 = date_to
SELECT
    pay.payment_id,
    p.project_name,
    COALESCE(c.company_name, c.full_name) AS client_name,
    pay.payment_type,
    pay.amount,
    pay.payment_date,
    pay.status
FROM payments pay
JOIN projects p ON p.project_id = pay.project_id
JOIN clients c ON c.client_id = p.client_id
WHERE pay.payment_date BETWEEN $1 AND $2
ORDER BY pay.payment_date;

-- 4.4. Этапы конкретного проекта: $1 = project_id
SELECT
    stage_order,
    stage_name,
    responsible.full_name AS responsible_name,
    planned_start_date,
    planned_end_date,
    actual_start_date,
    actual_end_date,
    status,
    comments
FROM project_stages ps
LEFT JOIN employees responsible ON responsible.employee_id = ps.responsible_id
WHERE ps.project_id = $1
ORDER BY stage_order;

-- 4.5. Версии конкретного проекта: $1 = project_id
SELECT
    pv.version_id,
    ps.stage_name,
    pv.version_number,
    e.full_name AS uploaded_by,
    pv.description,
    pv.sent_to_client_at,
    pv.is_approved,
    pv.client_feedback,
    pv.created_at
FROM project_versions pv
LEFT JOIN project_stages ps ON ps.stage_id = pv.stage_id
LEFT JOIN employees e ON e.employee_id = pv.uploaded_by
WHERE pv.project_id = $1
ORDER BY pv.created_at DESC;

-- 5. Управленческие запросы

-- 5.1. Просроченные задачи
SELECT
    t.task_id,
    p.project_name,
    t.task_name,
    e.full_name AS assignee_name,
    t.priority,
    t.status,
    t.deadline
FROM tasks t
JOIN projects p ON p.project_id = t.project_id
LEFT JOIN employees e ON e.employee_id = t.assignee_id
WHERE t.status NOT IN ('done', 'cancelled')
  AND t.deadline < CURRENT_TIMESTAMP
ORDER BY t.deadline;

-- 5.2. Проекты без оплаченной предоплаты
SELECT
    p.project_id,
    p.project_name,
    COALESCE(c.company_name, c.full_name) AS client_name,
    p.status,
    p.budget
FROM projects p
JOIN clients c ON c.client_id = p.client_id
WHERE NOT EXISTS (
    SELECT 1
    FROM payments pay
    WHERE pay.project_id = p.project_id
      AND pay.payment_type = 'prepayment'
      AND pay.status = 'paid'
)
ORDER BY p.start_date;

-- 5.3. Проекты на этапе правок
SELECT
    p.project_id,
    p.project_name,
    COALESCE(c.company_name, c.full_name) AS client_name,
    ps.stage_name,
    ps.status AS stage_status,
    responsible.full_name AS responsible_name
FROM projects p
JOIN clients c ON c.client_id = p.client_id
JOIN project_stages ps ON ps.project_id = p.project_id
LEFT JOIN employees responsible ON responsible.employee_id = ps.responsible_id
WHERE p.status = 'revisions'
   OR (ps.stage_name = 'Правки' AND ps.status IN ('planned', 'in_progress'))
ORDER BY p.project_name;

-- 5.4. Сотрудники с максимальной загрузкой
SELECT
    e.employee_id,
    e.full_name,
    pos.position_name,
    COUNT(t.task_id) AS active_task_count,
    SUM(t.planned_hours) AS planned_hours_sum
FROM employees e
JOIN positions pos ON pos.position_id = e.position_id
JOIN tasks t ON t.assignee_id = e.employee_id
WHERE t.status NOT IN ('done', 'cancelled')
GROUP BY e.employee_id, e.full_name, pos.position_name
ORDER BY active_task_count DESC, planned_hours_sum DESC
LIMIT 5;

-- 5.5. Клиенты с наибольшей выручкой
SELECT
    c.client_id,
    COALESCE(c.company_name, c.full_name) AS client_name,
    COUNT(DISTINCT p.project_id) AS project_count,
    SUM(pay.amount) FILTER (WHERE pay.status = 'paid') AS paid_revenue
FROM clients c
JOIN projects p ON p.client_id = c.client_id
JOIN payments pay ON pay.project_id = p.project_id
GROUP BY c.client_id, COALESCE(c.company_name, c.full_name)
ORDER BY paid_revenue DESC NULLS LAST
LIMIT 10;

-- 5.6. Незакрытые этапы с ближайшими дедлайнами
SELECT
    p.project_name,
    ps.stage_name,
    ps.status,
    ps.planned_end_date,
    e.full_name AS responsible_name
FROM project_stages ps
JOIN projects p ON p.project_id = ps.project_id
LEFT JOIN employees e ON e.employee_id = ps.responsible_id
WHERE ps.status NOT IN ('completed', 'approved', 'cancelled')
ORDER BY ps.planned_end_date NULLS LAST;

-- 5.7. Версии, которые отправлены клиенту, но еще не согласованы
SELECT
    p.project_name,
    ps.stage_name,
    pv.version_number,
    pv.description,
    pv.sent_to_client_at,
    pv.client_feedback,
    e.full_name AS uploaded_by
FROM project_versions pv
JOIN projects p ON p.project_id = pv.project_id
LEFT JOIN project_stages ps ON ps.stage_id = pv.stage_id
LEFT JOIN employees e ON e.employee_id = pv.uploaded_by
WHERE pv.sent_to_client_at IS NOT NULL
  AND pv.is_approved = FALSE
ORDER BY pv.sent_to_client_at DESC;

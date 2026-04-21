-- Combined PostgreSQL database file for the content agency project


-- BEGIN 01_schema.sql

-- РРЅС„РѕСЂРјР°С†РёРѕРЅРЅР°СЏ СЃРёСЃС‚РµРјР° РєРѕРЅС‚РµРЅС‚-Р°РіРµРЅС‚СЃС‚РІР°
-- PostgreSQL DDL

DROP TABLE IF EXISTS project_links CASCADE;
DROP TABLE IF EXISTS project_versions CASCADE;
DROP TABLE IF EXISTS employee_payouts CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS meetings CASCADE;
DROP TABLE IF EXISTS task_checklist_status CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS checklist_items CASCADE;
DROP TABLE IF EXISTS checklist_templates CASCADE;
DROP TABLE IF EXISTS project_stages CASCADE;
DROP TABLE IF EXISTS project_services CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS briefs CASCADE;
DROP TABLE IF EXISTS services CASCADE;
DROP TABLE IF EXISTS client_contacts CASCADE;
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS teams CASCADE;
DROP TABLE IF EXISTS positions CASCADE;

CREATE TABLE positions (
    position_id BIGSERIAL PRIMARY KEY,
    position_name VARCHAR(80) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE teams (
    team_id BIGSERIAL PRIMARY KEY,
    city_name VARCHAR(80) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE employees (
    employee_id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    telegram VARCHAR(80) UNIQUE,
    phone VARCHAR(30),
    position_id BIGINT NOT NULL REFERENCES positions(position_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    team_id BIGINT NOT NULL REFERENCES teams(team_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    responsibility_area TEXT,
    salary_type VARCHAR(20) NOT NULL DEFAULT 'fixed',
    fixed_salary NUMERIC(12,2) NOT NULL DEFAULT 0,
    percent_rate NUMERIC(5,2) NOT NULL DEFAULT 0,
    hire_date DATE NOT NULL DEFAULT CURRENT_DATE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_employee_telegram CHECK (telegram IS NULL OR telegram LIKE '@%'),
    CONSTRAINT chk_employee_salary_type CHECK (salary_type IN ('fixed', 'percent', 'mixed')),
    CONSTRAINT chk_employee_fixed_salary CHECK (fixed_salary >= 0),
    CONSTRAINT chk_employee_percent_rate CHECK (percent_rate >= 0 AND percent_rate <= 100)
);

CREATE TABLE clients (
    client_id BIGSERIAL PRIMARY KEY,
    client_type VARCHAR(20) NOT NULL,
    company_name VARCHAR(180),
    full_name VARCHAR(150),
    niche VARCHAR(150) NOT NULL,
    short_tz TEXT,
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_client_type CHECK (client_type IN ('individual', 'legal')),
    CONSTRAINT chk_client_required_name CHECK (
        (client_type = 'legal' AND company_name IS NOT NULL)
        OR
        (client_type = 'individual' AND full_name IS NOT NULL)
    )
);

CREATE TABLE client_contacts (
    contact_id BIGSERIAL PRIMARY KEY,
    client_id BIGINT NOT NULL REFERENCES clients(client_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    contact_type VARCHAR(30) NOT NULL,
    contact_value VARCHAR(180) NOT NULL,
    contact_person VARCHAR(150),
    role_title VARCHAR(120),
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    comments TEXT,
    CONSTRAINT chk_contact_type CHECK (contact_type IN ('phone', 'email', 'telegram', 'website', 'other')),
    CONSTRAINT uq_client_contact UNIQUE (client_id, contact_type, contact_value)
);

CREATE TABLE services (
    service_id BIGSERIAL PRIMARY KEY,
    service_name VARCHAR(150) NOT NULL UNIQUE,
    description TEXT,
    base_price NUMERIC(12,2) NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_service_base_price CHECK (base_price >= 0)
);

CREATE TABLE briefs (
    brief_id BIGSERIAL PRIMARY KEY,
    client_id BIGINT NOT NULL REFERENCES clients(client_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    brief_type VARCHAR(20) NOT NULL DEFAULT 'initial',
    purpose TEXT NOT NULL,
    target_audience TEXT,
    platforms TEXT,
    references_text TEXT,
    restrictions TEXT,
    expected_deadline DATE,
    expected_budget NUMERIC(12,2),
    full_tz TEXT NOT NULL,
    author_id BIGINT REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_brief_type CHECK (brief_type IN ('initial', 'additional', 'post')),
    CONSTRAINT chk_brief_expected_budget CHECK (expected_budget IS NULL OR expected_budget >= 0)
);

CREATE TABLE projects (
    project_id BIGSERIAL PRIMARY KEY,
    client_id BIGINT NOT NULL REFERENCES clients(client_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    brief_id BIGINT REFERENCES briefs(brief_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    project_name VARCHAR(180) NOT NULL,
    project_type VARCHAR(20) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'lead',
    director_id BIGINT REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    lead_id BIGINT REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    creative_director_id BIGINT REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    start_date DATE,
    planned_end_date DATE,
    actual_end_date DATE,
    budget NUMERIC(12,2) NOT NULL DEFAULT 0,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_project_type CHECK (project_type IN ('one_time', 'subscription')),
    CONSTRAINT chk_project_status CHECK (
        status IN ('lead', 'negotiation', 'prepaid', 'in_progress', 'approval', 'revisions', 'completed', 'closed', 'cancelled')
    ),
    CONSTRAINT chk_project_budget CHECK (budget >= 0),
    CONSTRAINT chk_project_dates CHECK (
        planned_end_date IS NULL OR start_date IS NULL OR planned_end_date >= start_date
    ),
    CONSTRAINT uq_project_client_name UNIQUE (client_id, project_name)
);

CREATE TABLE project_services (
    project_service_id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL REFERENCES projects(project_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    service_id BIGINT NOT NULL REFERENCES services(service_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    quantity INTEGER NOT NULL DEFAULT 1,
    price NUMERIC(12,2) NOT NULL,
    service_comment TEXT,
    CONSTRAINT chk_project_service_quantity CHECK (quantity > 0),
    CONSTRAINT chk_project_service_price CHECK (price >= 0),
    CONSTRAINT uq_project_service UNIQUE (project_id, service_id)
);

CREATE TABLE project_stages (
    stage_id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL REFERENCES projects(project_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    stage_name VARCHAR(120) NOT NULL,
    stage_order INTEGER NOT NULL,
    responsible_id BIGINT REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    planned_start_date DATE,
    planned_end_date DATE,
    actual_start_date DATE,
    actual_end_date DATE,
    status VARCHAR(30) NOT NULL DEFAULT 'planned',
    comments TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_stage_status CHECK (status IN ('planned', 'in_progress', 'completed', 'approved', 'on_hold', 'cancelled')),
    CONSTRAINT chk_stage_order CHECK (stage_order > 0),
    CONSTRAINT chk_stage_planned_dates CHECK (
        planned_end_date IS NULL OR planned_start_date IS NULL OR planned_end_date >= planned_start_date
    ),
    CONSTRAINT chk_stage_actual_dates CHECK (
        actual_end_date IS NULL OR actual_start_date IS NULL OR actual_end_date >= actual_start_date
    ),
    CONSTRAINT uq_project_stage_order UNIQUE (project_id, stage_order),
    CONSTRAINT uq_project_stage_name UNIQUE (project_id, stage_name),
    CONSTRAINT uq_stage_project_pair UNIQUE (stage_id, project_id)
);

CREATE TABLE checklist_templates (
    template_id BIGSERIAL PRIMARY KEY,
    template_name VARCHAR(150) NOT NULL UNIQUE,
    stage_name VARCHAR(120),
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE checklist_items (
    item_id BIGSERIAL PRIMARY KEY,
    template_id BIGINT NOT NULL REFERENCES checklist_templates(template_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    item_order INTEGER NOT NULL,
    item_text TEXT NOT NULL,
    is_required BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_checklist_item_order CHECK (item_order > 0),
    CONSTRAINT uq_template_item_order UNIQUE (template_id, item_order)
);

CREATE TABLE tasks (
    task_id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL REFERENCES projects(project_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    stage_id BIGINT NOT NULL,
    assigner_id BIGINT REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    assignee_id BIGINT REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    task_name VARCHAR(180) NOT NULL,
    description TEXT,
    priority VARCHAR(20) NOT NULL DEFAULT 'medium',
    status VARCHAR(30) NOT NULL DEFAULT 'new',
    planned_hours NUMERIC(6,2) NOT NULL DEFAULT 0,
    deadline TIMESTAMP,
    completed_at TIMESTAMP,
    checklist_template_id BIGINT REFERENCES checklist_templates(template_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_task_stage_project FOREIGN KEY (stage_id, project_id)
        REFERENCES project_stages(stage_id, project_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_task_priority CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    CONSTRAINT chk_task_status CHECK (status IN ('new', 'in_progress', 'review', 'revision', 'done', 'cancelled')),
    CONSTRAINT chk_task_planned_hours CHECK (planned_hours >= 0)
);

CREATE TABLE task_checklist_status (
    task_checklist_status_id BIGSERIAL PRIMARY KEY,
    task_id BIGINT NOT NULL REFERENCES tasks(task_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    checklist_item_id BIGINT NOT NULL REFERENCES checklist_items(item_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    checked_by BIGINT REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    is_done BOOLEAN NOT NULL DEFAULT FALSE,
    checked_at TIMESTAMP,
    comment TEXT,
    CONSTRAINT uq_task_checklist_item UNIQUE (task_id, checklist_item_id),
    CONSTRAINT chk_task_checklist_checked_at CHECK (
        (is_done = FALSE AND checked_at IS NULL) OR (is_done = TRUE)
    )
);

CREATE TABLE meetings (
    meeting_id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL REFERENCES projects(project_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    meeting_type VARCHAR(30) NOT NULL,
    meeting_at TIMESTAMP NOT NULL,
    format VARCHAR(20) NOT NULL,
    location_or_link TEXT NOT NULL,
    organizer_id BIGINT REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'planned',
    notes TEXT,
    CONSTRAINT chk_meeting_type CHECK (
        meeting_type IN ('primary_call', 'meeting', 'briefing', 'additional_brief', 'shooting', 'planning', 'review', 'postbrief', 'other')
    ),
    CONSTRAINT chk_meeting_format CHECK (format IN ('online', 'offline', 'hybrid')),
    CONSTRAINT chk_meeting_status CHECK (status IN ('planned', 'completed', 'cancelled', 'postponed'))
);

CREATE TABLE payments (
    payment_id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL REFERENCES projects(project_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    payment_type VARCHAR(20) NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    payment_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'planned',
    comment TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_payment_type CHECK (payment_type IN ('prepayment', 'intermediate', 'final', 'refund')),
    CONSTRAINT chk_payment_amount CHECK (amount >= 0),
    CONSTRAINT chk_payment_status CHECK (status IN ('planned', 'invoiced', 'paid', 'overdue', 'cancelled'))
);

CREATE TABLE employee_payouts (
    payout_id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL REFERENCES projects(project_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    employee_id BIGINT NOT NULL REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    payout_type VARCHAR(20) NOT NULL DEFAULT 'mixed',
    salary_period DATE NOT NULL,
    fixed_part NUMERIC(12,2) NOT NULL DEFAULT 0,
    percent_part NUMERIC(12,2) NOT NULL DEFAULT 0,
    gross_amount NUMERIC(12,2) NOT NULL,
    tax_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    net_amount NUMERIC(12,2) NOT NULL,
    payout_date DATE,
    comment TEXT,
    CONSTRAINT chk_payout_type CHECK (payout_type IN ('fixed', 'percent', 'mixed', 'bonus')),
    CONSTRAINT chk_payout_amounts CHECK (
        fixed_part >= 0
        AND percent_part >= 0
        AND gross_amount >= 0
        AND tax_amount >= 0
        AND net_amount >= 0
        AND gross_amount >= tax_amount
    )
);

CREATE TABLE project_versions (
    version_id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL REFERENCES projects(project_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    stage_id BIGINT REFERENCES project_stages(stage_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    version_number INTEGER NOT NULL,
    uploaded_by BIGINT REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    description TEXT NOT NULL,
    sent_to_client_at TIMESTAMP,
    is_approved BOOLEAN NOT NULL DEFAULT FALSE,
    client_feedback TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_version_number CHECK (version_number > 0),
    CONSTRAINT uq_project_stage_version UNIQUE (project_id, stage_id, version_number)
);

CREATE TABLE project_links (
    link_id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL REFERENCES projects(project_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    stage_id BIGINT REFERENCES project_stages(stage_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    version_id BIGINT REFERENCES project_versions(version_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    link_type VARCHAR(30) NOT NULL,
    link_url TEXT NOT NULL,
    description TEXT,
    added_by BIGINT REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    added_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_link_type CHECK (
        link_type IN ('brief', 'drive_folder', 'source_files', 'work_file', 'final_material', 'meeting_record', 'contract', 'invoice', 'reference', 'publication')
    ),
    CONSTRAINT chk_link_url CHECK (link_url ~* '^https?://')
);

CREATE UNIQUE INDEX uq_client_primary_contact
    ON client_contacts(client_id)
    WHERE is_primary = TRUE;

CREATE INDEX idx_employees_position ON employees(position_id);
CREATE INDEX idx_employees_team ON employees(team_id);
CREATE INDEX idx_employees_active ON employees(is_active);
CREATE INDEX idx_clients_type ON clients(client_type);
CREATE INDEX idx_briefs_client ON briefs(client_id);
CREATE INDEX idx_projects_client ON projects(client_id);
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_lead ON projects(lead_id);
CREATE INDEX idx_project_services_project ON project_services(project_id);
CREATE INDEX idx_project_stages_project ON project_stages(project_id);
CREATE INDEX idx_project_stages_status ON project_stages(status);
CREATE INDEX idx_tasks_project ON tasks(project_id);
CREATE INDEX idx_tasks_stage ON tasks(stage_id);
CREATE INDEX idx_tasks_assignee ON tasks(assignee_id);
CREATE INDEX idx_tasks_status_deadline ON tasks(status, deadline);
CREATE INDEX idx_meetings_project_date ON meetings(project_id, meeting_at);
CREATE INDEX idx_payments_project ON payments(project_id);
CREATE INDEX idx_payments_status_type ON payments(status, payment_type);
CREATE INDEX idx_employee_payouts_employee ON employee_payouts(employee_id);
CREATE INDEX idx_employee_payouts_project ON employee_payouts(project_id);
CREATE INDEX idx_project_versions_project ON project_versions(project_id);
CREATE INDEX idx_project_links_project ON project_links(project_id);

-- END 01_schema.sql


-- BEGIN 02_seed_01_core.sql

-- РўРµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ: СЃРїСЂР°РІРѕС‡РЅРёРєРё, СЃРѕС‚СЂСѓРґРЅРёРєРё, РєР»РёРµРЅС‚С‹, РєРѕРЅС‚Р°РєС‚С‹, СѓСЃР»СѓРіРё, Р±СЂРёС„С‹
-- Р—Р°РїСѓСЃРєР°С‚СЊ РїРѕСЃР»Рµ 01_schema.sql

BEGIN;

INSERT INTO positions (position_id, position_name, description) VALUES
(1, 'Р”РёСЂРµРєС‚РѕСЂ', 'РЈС‚РІРµСЂР¶РґР°РµС‚ РєР»РёРµРЅС‚РѕРІ, Р±СЋРґР¶РµС‚С‹, РєР»СЋС‡РµРІС‹Рµ СЂРµС€РµРЅРёСЏ Рё РѕС‚С‡РµС‚С‹'),
(2, 'Р СѓРєРѕРІРѕРґРёС‚РµР»СЊ', 'Р’РµРґРµС‚ РїСЂРѕРµРєС‚С‹ РІ РіРѕСЂРѕРґРµ, СЂР°СЃРїСЂРµРґРµР»СЏРµС‚ Р·Р°РґР°С‡Рё Рё РєРѕРЅС‚СЂРѕР»РёСЂСѓРµС‚ СЃСЂРѕРєРё'),
(3, 'РљСЂРµР°С‚РёРІРЅС‹Р№ РґРёСЂРµРєС‚РѕСЂ', 'РЈС‚РІРµСЂР¶РґР°РµС‚ РєРѕРЅС†РµРїС†РёРё, РєРѕРЅС‚СЂРѕР»РёСЂСѓРµС‚ СЃРјС‹СЃР» Рё РІРёР·СѓР°Р»СЊРЅСѓСЋ СЃС‚СЂР°С‚РµРіРёСЋ'),
(4, 'Р”РёР·Р°Р№РЅРµСЂ', 'Р“РѕС‚РѕРІРёС‚ РјР°РєРµС‚С‹, РІРёР·СѓР°Р»С‹, РїСЂРµР·РµРЅС‚Р°С†РёРё Рё РіСЂР°С„РёС‡РµСЃРєРёРµ РјР°С‚РµСЂРёР°Р»С‹'),
(5, 'Р¤РѕС‚РѕРіСЂР°С„', 'РџСЂРѕРІРѕРґРёС‚ С„РѕС‚РѕСЃСЉРµРјРєРё Рё РїРµСЂРµРґР°РµС‚ РёСЃС…РѕРґРЅС‹Рµ РјР°С‚РµСЂРёР°Р»С‹'),
(6, 'Р’РёРґРµРѕРіСЂР°С„', 'РџСЂРѕРІРѕРґРёС‚ РІРёРґРµРѕСЃСЉРµРјРєРё Рё РїРµСЂРµРґР°РµС‚ РјР°С‚РµСЂРёР°Р» РІ РїРѕСЃС‚РїСЂРѕРґР°РєС€РЅ'),
(7, 'SMM-СЃРїРµС†РёР°Р»РёСЃС‚', 'Р’РµРґРµС‚ РєРѕРЅС‚РµРЅС‚-РїР»Р°РЅ, С‚РµРєСЃС‚С‹, СЃС†РµРЅР°СЂРёРё Рё РїСѓР±Р»РёРєР°С†РёРё'),
(8, 'РњРѕРЅС‚Р°Р¶РµСЂ', 'РњРѕРЅС‚РёСЂСѓРµС‚ РІРёРґРµРѕ, РІРµРґРµС‚ РІРµСЂСЃРёРё Рё РїСЂР°РІРєРё РЅР° РїРѕСЃС‚РїСЂРѕРґР°РєС€РЅРµ');

INSERT INTO teams (team_id, city_name, description) VALUES
(1, 'РСЂРєСѓС‚СЃРє', 'РћСЃРЅРѕРІРЅР°СЏ РєРѕРјР°РЅРґР° Р°РіРµРЅС‚СЃС‚РІР°'),
(2, 'Р‘СЂР°С‚СЃРє', 'Р›РѕРєР°Р»СЊРЅР°СЏ РєРѕРјР°РЅРґР° РґР»СЏ СЃРµРІРµСЂРЅС‹С… РїСЂРѕРµРєС‚РѕРІ');

INSERT INTO employees (
    employee_id, full_name, telegram, phone, position_id, team_id,
    responsibility_area, salary_type, fixed_salary, percent_rate, hire_date, is_active
) VALUES
(1, 'РђРЅРЅР° РџР°РІР»РѕРІР°', '@pavlova_director', '+7 902 510-10-01', 1, 1, 'РЎС‚СЂР°С‚РµРіРёСЏ Р°РіРµРЅС‚СЃС‚РІР°, Р±СЋРґР¶РµС‚С‹, С„РёРЅР°Р»СЊРЅС‹Рµ СЂРµС€РµРЅРёСЏ, РїР»Р°РЅРµСЂРєРё РјРµРЅРµРґР¶РјРµРЅС‚Р°', 'mixed', 90000, 5.00, '2022-01-10', TRUE),
(2, 'Р”РјРёС‚СЂРёР№ РћСЂР»РѕРІ', '@orlov_lead', '+7 902 510-10-02', 2, 1, 'РџСЂРѕРµРєС‚С‹ РСЂРєСѓС‚СЃРєР°, СЂР°СЃРїСЂРµРґРµР»РµРЅРёРµ Р·Р°РґР°С‡, РєРѕРЅС‚СЂРѕР»СЊ РґРµРґР»Р°Р№РЅРѕРІ', 'mixed', 70000, 3.00, '2022-02-15', TRUE),
(3, 'РњР°СЂРёСЏ РЎРѕРєРѕР»РѕРІР°', '@sokolova_creative', '+7 902 510-10-03', 3, 1, 'РљСЂРµР°С‚РёРІРЅС‹Рµ РєРѕРЅС†РµРїС†РёРё, РїРѕР·РёС†РёРѕРЅРёСЂРѕРІР°РЅРёРµ, РІРёР·СѓР°Р»СЊРЅР°СЏ СЃС‚СЂР°С‚РµРіРёСЏ', 'mixed', 80000, 2.50, '2022-03-01', TRUE),
(4, 'РљРёСЂРёР»Р» РђРЅС‚РѕРЅРѕРІ', '@antonov_design', '+7 902 510-10-04', 4, 1, 'Р”РёР·Р°Р№РЅ СЃРѕС†СЃРµС‚РµР№, РїСЂРµР·РµРЅС‚Р°С†РёРё, key visual, РѕР±Р»РѕР¶РєРё Рё РјР°РєРµС‚С‹', 'mixed', 52000, 1.50, '2023-04-12', TRUE),
(5, 'РћР»СЊРіР° Р›РµР±РµРґРµРІР°', '@lebedeva_photo', '+7 902 510-10-05', 5, 1, 'РџСЂРµРґРјРµС‚РЅР°СЏ, РёРЅС‚РµСЂСЊРµСЂРЅР°СЏ, РїРѕСЂС‚СЂРµС‚РЅР°СЏ Рё СЂРµРїРѕСЂС‚Р°Р¶РЅР°СЏ С„РѕС‚РѕСЃСЉРµРјРєР°', 'mixed', 43000, 1.00, '2023-05-20', TRUE),
(6, 'РРІР°РЅ РњР°РєР°СЂРѕРІ', '@makarov_video', '+7 902 510-10-06', 6, 2, 'Р’РёРґРµРѕСЃСЉРµРјРєР°, СЃРІРµС‚, Р·РІСѓРє, СЃСЉРµРјРѕС‡РЅС‹Рµ РїР»Р°РЅС‹, РїРµСЂРµРґР°С‡Р° РёСЃС…РѕРґРЅРёРєРѕРІ', 'mixed', 46000, 1.20, '2023-07-03', TRUE),
(7, 'РЎРѕС„РёСЏ РљРёРј', '@kim_smm', '+7 902 510-10-07', 7, 2, 'РљРѕРЅС‚РµРЅС‚-РїР»Р°РЅС‹, С‚РµРєСЃС‚С‹, СЃС†РµРЅР°СЂРёРё, РїСѓР±Р»РёРєР°С†РёРё, РѕС„РѕСЂРјР»РµРЅРёРµ РїСЂРѕС„РёР»РµР№', 'mixed', 48000, 1.50, '2023-08-18', TRUE),
(8, 'Р”РµРЅРёСЃ Р’РѕР»РєРѕРІ', '@volkov_edit', '+7 902 510-10-08', 8, 2, 'РњРѕРЅС‚Р°Р¶ Reels, РєР»РёРїРѕРІ, СЂРµРєР»Р°РјРЅС‹С… СЂРѕР»РёРєРѕРІ, С†РІРµС‚, Р·РІСѓРє, РІРµСЂСЃРёРё РїСЂР°РІРѕРє', 'mixed', 47000, 1.30, '2023-09-11', TRUE);

INSERT INTO clients (client_id, client_type, company_name, full_name, niche, short_tz, notes) VALUES
(1, 'legal', 'РћРћРћ "Р‘Р°Р№РєР°Р»Р¤СѓРґ"', NULL, 'РџСЂРѕРёР·РІРѕРґСЃС‚РІРѕ Р»РѕРєР°Р»СЊРЅС‹С… РїСЂРѕРґСѓРєС‚РѕРІ', 'Р—Р°РїСѓСЃРє Р»РёРЅРµР№РєРё РєСЂР°С„С‚РѕРІС‹С… СЃС‹СЂРѕРІ: С„РѕС‚Рѕ, РІРёРґРµРѕ, SMM Рё РїСЂРµР·РµРЅС‚Р°С†РёСЏ', 'РљР»РёРµРЅС‚Сѓ РІР°Р¶РµРЅ РЅР°С‚СѓСЂР°Р»СЊРЅС‹Р№ РІРёР·СѓР°Р»СЊРЅС‹Р№ СЃС‚РёР»СЊ Рё Р°РєС†РµРЅС‚ РЅР° РїСЂРѕРёСЃС…РѕР¶РґРµРЅРёРµ СЃС‹СЂСЊСЏ'),
(2, 'legal', 'РћРћРћ "РђРЅРіР°СЂР° Р”РµРІРµР»РѕРїРјРµРЅС‚"', NULL, 'РќРµРґРІРёР¶РёРјРѕСЃС‚СЊ', 'Р•Р¶РµРјРµСЃСЏС‡РЅРѕРµ SMM-СЃРѕРїСЂРѕРІРѕР¶РґРµРЅРёРµ Р¶РёР»РѕРіРѕ РєРѕРјРїР»РµРєСЃР°', 'Р”Р»РёРЅРЅС‹Р№ С†РёРєР» СЃРґРµР»РєРё, РЅСѓР¶РЅС‹ СЂРµРіСѓР»СЏСЂРЅС‹Рµ РѕС‚С‡РµС‚С‹ РїРѕ Р»РёРґР°Рј'),
(3, 'individual', NULL, 'Р•Р»РµРЅР° РњРѕСЂРѕР·РѕРІР°', 'РќСѓС‚СЂРёС†РёРѕР»РѕРіРёСЏ Рё Р»РёС‡РЅС‹Р№ Р±СЂРµРЅРґ', 'РЈРїР°РєРѕРІРєР° Р»РёС‡РЅРѕРіРѕ Р±СЂРµРЅРґР°, РєРѕРЅС‚РµРЅС‚-РїР»Р°РЅ Рё СЌРєСЃРїРµСЂС‚РЅС‹Рµ Reels', 'РљР»РёРµРЅС‚ Р°РєС‚РёРІРЅРѕ СѓС‡Р°СЃС‚РІСѓРµС‚ РІ СЃРѕРіР»Р°СЃРѕРІР°РЅРёРё СЃРјС‹СЃР»РѕРІ'),
(4, 'legal', 'РљРѕС„РµР№РЅСЏ "РЎРµРІРµСЂРЅРѕРµ Р·РµСЂРЅРѕ"', NULL, 'HoReCa', 'РЎРµСЂРёСЏ РєРѕСЂРѕС‚РєРёС… РІРёРґРµРѕСЂРѕР»РёРєРѕРІ Рё С„РѕС‚Рѕ РґР»СЏ СЃРµР·РѕРЅРЅРѕРіРѕ РјРµРЅСЋ', 'РќСѓР¶РЅС‹ С‚РµРїР»С‹Рµ РєР°РґСЂС‹, Р°РєС†РµРЅС‚ РЅР° Р°С‚РјРѕСЃС„РµСЂСѓ'),
(5, 'legal', 'РЎРўРћ "РњРѕС‚РѕСЂРёРєР°"', NULL, 'РђРІС‚РѕСЃРµСЂРІРёСЃ', 'РљРѕРЅС‚РµРЅС‚ РґР»СЏ РґРѕРІРµСЂРёСЏ: РєРѕРјР°РЅРґР°, РїСЂРѕС†РµСЃСЃС‹, РєРµР№СЃС‹ СЂРµРјРѕРЅС‚Р°', 'Р•СЃС‚СЊ РѕРіСЂР°РЅРёС‡РµРЅРёСЏ РїРѕ СЃСЉРµРјРєРµ РєР»РёРµРЅС‚РѕРІ Рё РЅРѕРјРµСЂРѕРІ Р°РІС‚Рѕ'),
(6, 'individual', NULL, 'РђР»РёРЅР° Р’РµС‚СЂРѕРІР°', 'Handmade СѓРєСЂР°С€РµРЅРёСЏ', 'РљР°С‚Р°Р»РѕРі СѓРєСЂР°С€РµРЅРёР№ Рё РІРёР·СѓР°Р»С‹ РґР»СЏ РјР°СЂРєРµС‚РїР»РµР№СЃРѕРІ', 'Р’Р°Р¶РЅС‹ С‡РёСЃС‚С‹Рµ РїСЂРµРґРјРµС‚РЅС‹Рµ С„РѕС‚Рѕ Рё РµРґРёРЅС‹Р№ С„РѕРЅ'),
(7, 'legal', 'РўСѓСЂРєР»СѓР± "Р‘Р°Р№РєР°Р» РўСЂСЌРІРµР»"', NULL, 'РўСѓСЂРёР·Рј', 'РљРѕРЅС‚РµРЅС‚ Рє Р»РµС‚РЅРµРјСѓ СЃРµР·РѕРЅСѓ: РјР°СЂС€СЂСѓС‚С‹, РІРёРґРµРѕ, СЃС‚РѕСЂРёСЃ, Р»РµРЅРґРёРЅРі-РјР°С‚РµСЂРёР°Р»С‹', 'РЎСЉРµРјРєРё Р·Р°РІРёСЃСЏС‚ РѕС‚ РїРѕРіРѕРґС‹ Рё РґРѕСЃС‚СѓРїРЅРѕСЃС‚Рё Р»РѕРєР°С†РёР№'),
(8, 'legal', 'РљСѓР»СЊС‚СѓСЂРЅС‹Р№ С†РµРЅС‚СЂ "РђСЂРєР°"', NULL, 'РљСѓР»СЊС‚СѓСЂР° Рё СЃРѕР±С‹С‚РёСЏ', 'Р РµР±СЂРµРЅРґРёРЅРі РІРёР·СѓР°Р»СЊРЅС‹С… РєРѕРјРјСѓРЅРёРєР°С†РёР№ Рё Р°С„РёС€Рё РјРµСЂРѕРїСЂРёСЏС‚РёР№', 'РЎРѕРіР»Р°СЃРѕРІР°РЅРёРµ С‡РµСЂРµР· С…СѓРґРѕР¶РµСЃС‚РІРµРЅРЅС‹Р№ СЃРѕРІРµС‚'),
(9, 'legal', 'Р¤РёС‚РЅРµСЃ-РєР»СѓР± "РџСѓР»СЊСЃ"', NULL, 'Р¤РёС‚РЅРµСЃ', 'РђР±РѕРЅРµРЅС‚СЃРєРѕРµ SMM-СЃРѕРїСЂРѕРІРѕР¶РґРµРЅРёРµ Рё СЃСЉРµРјРєРё С‚СЂРµРЅРёСЂРѕРІРѕРє', 'РќСѓР¶РµРЅ РґРёРЅР°РјРёС‡РЅС‹Р№ РІРёР·СѓР°Р», РјРЅРѕРіРѕ СЃС‚РѕСЂРёСЃ Рё РєРѕСЂРѕС‚РєРёС… РІРёРґРµРѕ'),
(10, 'legal', 'РЁРєРѕР»Р° Р°РЅРіР»РёР№СЃРєРѕРіРѕ "North Star"', NULL, 'РћР±СЂР°Р·РѕРІР°РЅРёРµ', 'Р’РёРґРµРѕСѓРїР°РєРѕРІРєР° РєСѓСЂСЃР°, СЃС†РµРЅР°СЂРёРё Рё РјРѕРЅС‚Р°Р¶ СѓСЂРѕРєРѕРІ', 'РќСѓР¶РЅРѕ РїРѕРєР°Р·Р°С‚СЊ РїСЂРµРїРѕРґР°РІР°С‚РµР»РµР№ Рё СЂРµР·СѓР»СЊС‚Р°С‚С‹ СѓС‡РµРЅРёРєРѕРІ');

INSERT INTO client_contacts (
    contact_id, client_id, contact_type, contact_value, contact_person, role_title, is_primary, comments
) VALUES
(1, 1, 'phone', '+7 914 100-20-01', 'РСЂРёРЅР° Р‘РµР»РѕРІР°', 'РњР°СЂРєРµС‚РѕР»РѕРі', TRUE, 'РћСЃРЅРѕРІРЅРѕР№ РєРѕРЅС‚Р°РєС‚ РїРѕ РїСЂРѕРµРєС‚Сѓ'),
(2, 1, 'email', 'marketing@baikalfood.example', 'РСЂРёРЅР° Р‘РµР»РѕРІР°', 'РњР°СЂРєРµС‚РѕР»РѕРі', FALSE, 'Р”Р»СЏ РґРѕРіРѕРІРѕСЂРѕРІ Рё РґРѕРєСѓРјРµРЅС‚РѕРІ'),
(3, 2, 'telegram', '@angara_marketing', 'РџР°РІРµР» РќРёРєРёС„РѕСЂРѕРІ', 'Р СѓРєРѕРІРѕРґРёС‚РµР»СЊ РјР°СЂРєРµС‚РёРЅРіР°', TRUE, 'Р‘С‹СЃС‚СЂРѕ РѕС‚РІРµС‡Р°РµС‚ РІ СЂР°Р±РѕС‡РёРµ РґРЅРё'),
(4, 3, 'telegram', '@morozova_nutri', 'Р•Р»РµРЅР° РњРѕСЂРѕР·РѕРІР°', 'РљР»РёРµРЅС‚', TRUE, 'РџСЂРµРґРїРѕС‡РёС‚Р°РµС‚ РіРѕР»РѕСЃРѕРІС‹Рµ СЃРѕРѕР±С‰РµРЅРёСЏ'),
(5, 4, 'phone', '+7 914 100-20-04', 'РќРёРєРёС‚Р° Р РѕРјР°РЅРѕРІ', 'РЈРїСЂР°РІР»СЏСЋС‰РёР№', TRUE, 'РЎРѕР·РІРѕРЅС‹ РїРѕСЃР»Рµ 12:00'),
(6, 5, 'phone', '+7 914 100-20-05', 'РЎРµСЂРіРµР№ РџР»Р°С‚РѕРЅРѕРІ', 'РЎРѕР±СЃС‚РІРµРЅРЅРёРє', TRUE, 'Р’СЃРµ С„РёРЅР°Р»СЊРЅС‹Рµ СЂРµС€РµРЅРёСЏ РїСЂРёРЅРёРјР°РµС‚ СЃР°Рј'),
(7, 6, 'telegram', '@alina_vetrova', 'РђР»РёРЅР° Р’РµС‚СЂРѕРІР°', 'РњР°СЃС‚РµСЂ', TRUE, 'РћС‚РїСЂР°РІР»СЏРµС‚ СЂРµС„РµСЂРµРЅСЃС‹ РІ Telegram'),
(8, 7, 'email', 'hello@baikaltravel.example', 'Р”Р°СЂСЊСЏ РЎР°РІРёРЅР°', 'PR-РјРµРЅРµРґР¶РµСЂ', TRUE, 'Р”Р»СЏ СѓС‚РІРµСЂР¶РґРµРЅРёСЏ РјР°СЂС€СЂСѓС‚РѕРІ Рё СЃРјРµС‚'),
(9, 7, 'phone', '+7 914 100-20-07', 'РђСЂС‚РµРј РЎР°РІРёРЅ', 'РљРѕРѕСЂРґРёРЅР°С‚РѕСЂ С‚СѓСЂРѕРІ', FALSE, 'РљРѕРЅС‚Р°РєС‚ РїРѕ СЃСЉРµРјРѕС‡РЅС‹Рј РґРЅСЏРј'),
(10, 8, 'email', 'pr@arka.example', 'Р’Р°Р»РµСЂРёСЏ Р—Р°Р№С†РµРІР°', 'PR-СЃРїРµС†РёР°Р»РёСЃС‚', TRUE, 'РЎРѕРіР»Р°СЃСѓРµС‚ Р°С„РёС€Рё СЃ СЃРѕРІРµС‚РѕРј'),
(11, 9, 'telegram', '@pulse_fit', 'РњР°РєСЃРёРј Р“СЂРѕРјРѕРІ', 'РЈРїСЂР°РІР»СЏСЋС‰РёР№', TRUE, 'РќСѓР¶РЅС‹ Р±С‹СЃС‚СЂС‹Рµ СЃРѕРіР»Р°СЃРѕРІР°РЅРёСЏ СЃС‚РѕСЂРёСЃ'),
(12, 10, 'email', 'course@northstar.example', 'РћРєСЃР°РЅР° Р›Рё', 'РњРµС‚РѕРґРёСЃС‚', TRUE, 'РЎРѕРіР»Р°СЃСѓРµС‚ СЃС†РµРЅР°СЂРёРё СѓСЂРѕРєРѕРІ');

INSERT INTO services (service_id, service_name, description, base_price, is_active) VALUES
(1, 'Р‘СЂРёС„РёРЅРі Рё СЃС‚СЂР°С‚РµРіРёСЏ', 'РЎР±РѕСЂ РґР°РЅРЅС‹С…, Р°РЅР°Р»РёР· РЅРёС€Рё, РїРѕР·РёС†РёРѕРЅРёСЂРѕРІР°РЅРёРµ, С„РѕСЂРјРёСЂРѕРІР°РЅРёРµ СЃС‚СЂР°С‚РµРіРёРё РєРѕРјРјСѓРЅРёРєР°С†РёРё', 45000, TRUE),
(2, 'РљРѕРЅС‚РµРЅС‚-РїР»Р°РЅ РЅР° РјРµСЃСЏС†', 'Р СѓР±СЂРёРєР°С‚РѕСЂ, РєР°Р»РµРЅРґР°СЂСЊ РїСѓР±Р»РёРєР°С†РёР№, С‚РµРјС‹ РїРѕСЃС‚РѕРІ, СЃС‚РѕСЂРёСЃ Рё Reels', 35000, TRUE),
(3, 'Р¤РѕС‚РѕСЃСЉРµРјРєР°', 'РЎСЉРµРјРѕС‡РЅС‹Р№ РґРµРЅСЊ СЃ С„РѕС‚РѕРіСЂР°С„РѕРј, Р±Р°Р·РѕРІР°СЏ РѕР±СЂР°Р±РѕС‚РєР° Рё РїРµСЂРµРґР°С‡Р° РёСЃС…РѕРґРЅРёРєРѕРІ', 60000, TRUE),
(4, 'Р’РёРґРµРѕСЃСЉРµРјРєР°', 'РЎСЉРµРјРѕС‡РЅС‹Р№ РґРµРЅСЊ СЃ РІРёРґРµРѕРіСЂР°С„РѕРј, СЃРІРµС‚, Р·РІСѓРє, РёСЃС…РѕРґРЅС‹Р№ РјР°С‚РµСЂРёР°Р»', 75000, TRUE),
(5, 'РњРѕРЅС‚Р°Р¶ Reels', 'РњРѕРЅС‚Р°Р¶ РєРѕСЂРѕС‚РєРёС… РІРµСЂС‚РёРєР°Р»СЊРЅС‹С… СЂРѕР»РёРєРѕРІ СЃ С‚РёС‚СЂР°РјРё, РјСѓР·С‹РєРѕР№ Рё С†РІРµС‚РѕРєРѕСЂСЂРµРєС†РёРµР№', 25000, TRUE),
(6, 'Р”РёР·Р°Р№РЅ СЃРѕС†СЃРµС‚РµР№', 'РЁР°Р±Р»РѕРЅС‹ РїРѕСЃС‚РѕРІ, РѕР±Р»РѕР¶РєРё, РѕС„РѕСЂРјР»РµРЅРёРµ РїСЂРѕС„РёР»СЏ, РІРёР·СѓР°Р»СЊРЅС‹Рµ СЃРµСЂРёРё', 50000, TRUE),
(7, 'SMM-СЃРѕРїСЂРѕРІРѕР¶РґРµРЅРёРµ', 'Р’РµРґРµРЅРёРµ Р°РєРєР°СѓРЅС‚РѕРІ, РїСѓР±Р»РёРєР°С†РёРё, СЃС‚РѕСЂРёСЃ, РєРѕРјРјСѓРЅРёРєР°С†РёСЏ Рё РѕС‚С‡РµС‚РЅРѕСЃС‚СЊ', 90000, TRUE),
(8, 'РљСЂРµР°С‚РёРІРЅР°СЏ РєРѕРЅС†РµРїС†РёСЏ', 'РРґРµСЏ РєР°РјРїР°РЅРёРё, tone of voice, РІРёР·СѓР°Р»СЊРЅС‹Рµ РЅР°РїСЂР°РІР»РµРЅРёСЏ, moodboard', 70000, TRUE),
(9, 'РЎС†РµРЅР°СЂРёРё РІРёРґРµРѕ', 'РЎС†РµРЅР°СЂРёРё СЂРµРєР»Р°РјРЅС‹С… СЂРѕР»РёРєРѕРІ, СЌРєСЃРїРµСЂС‚РЅС‹С… РІРёРґРµРѕ Рё Reels', 30000, TRUE),
(10, 'РџРѕСЃС‚РїСЂРѕРґР°РєС€РЅ РІРёРґРµРѕ', 'РњРѕРЅС‚Р°Р¶, С†РІРµС‚, Р·РІСѓРє, РІРµСЂСЃРёРё РїСЂР°РІРѕРє, С„РёРЅР°Р»СЊРЅС‹Р№ СЌРєСЃРїРѕСЂС‚', 55000, TRUE),
(11, 'РџСЂРµРґРјРµС‚РЅР°СЏ СЃСЉРµРјРєР°', 'Р¤РѕС‚Рѕ С‚РѕРІР°СЂРѕРІ РґР»СЏ РєР°С‚Р°Р»РѕРіР°, РјР°СЂРєРµС‚РїР»РµР№СЃРѕРІ Рё СЃР°Р№С‚Р°', 65000, TRUE),
(12, 'РћС‚С‡РµС‚ Рё Р°РЅР°Р»РёС‚РёРєР°', 'РћС‚С‡РµС‚ РїРѕ РІС‹РїРѕР»РЅРµРЅРЅС‹Рј СЂР°Р±РѕС‚Р°Рј, РјР°С‚РµСЂРёР°Р»Р°Рј, РїРѕРєР°Р·Р°С‚РµР»СЏРј Рё СЂРµРєРѕРјРµРЅРґР°С†РёСЏРј', 20000, TRUE);

INSERT INTO briefs (
    brief_id, client_id, brief_type, purpose, target_audience, platforms, references_text,
    restrictions, expected_deadline, expected_budget, full_tz, author_id, created_at
) VALUES
(1, 1, 'initial', 'Р—Р°РїСѓСЃС‚РёС‚СЊ РЅРѕРІСѓСЋ Р»РёРЅРµР№РєСѓ СЃС‹СЂРѕРІ Рё СЃС„РѕСЂРјРёСЂРѕРІР°С‚СЊ РґРѕРІРµСЂРёРµ Рє Р»РѕРєР°Р»СЊРЅРѕРјСѓ РїСЂРѕРёР·РІРѕРґСЃС‚РІСѓ', 'Р–РёС‚РµР»Рё РСЂРєСѓС‚СЃРєР° 25-45, СЃРµРјСЊРё, Р»СЋР±РёС‚РµР»Рё С„РµСЂРјРµСЂСЃРєРёС… РїСЂРѕРґСѓРєС‚РѕРІ', 'VK, Instagram, СЃР°Р№С‚, РїСЂРµР·РµРЅС‚Р°С†РёСЏ РґР»СЏ РїР°СЂС‚РЅРµСЂРѕРІ', 'РќР°С‚СѓСЂР°Р»СЊРЅС‹Р№ СЃРІРµС‚, С„РµСЂРјРµСЂСЃРєРёРµ Р±СЂРµРЅРґС‹, РµРІСЂРѕРїРµР№СЃРєРёРµ СЃС‹СЂРѕРІР°СЂРЅРё', 'РќРµ РёСЃРїРѕР»СЊР·РѕРІР°С‚СЊ РѕР±СЂР°Р· РјР°СЃСЃРѕРІРѕРіРѕ РїСЂРѕРёР·РІРѕРґСЃС‚РІР°', '2026-05-30', 420000, 'РќСѓР¶РЅС‹ С„РѕС‚Рѕ РїСЂРѕРґСѓРєС‚Р°, РІРёРґРµРѕ РїСЂРѕРёР·РІРѕРґСЃС‚РІР°, РєРѕРЅС‚РµРЅС‚-РїР»Р°РЅ Рё С„РёРЅР°Р»СЊРЅР°СЏ РїСЂРµР·РµРЅС‚Р°С†РёСЏ', 2, '2026-03-04 11:20:00'),
(2, 2, 'initial', 'РџРѕРґРґРµСЂР¶РёРІР°С‚СЊ СЃС‚Р°Р±РёР»СЊРЅС‹Р№ РїРѕС‚РѕРє Р·Р°СЏРІРѕРє РїРѕ Р¶РёР»РѕРјСѓ РєРѕРјРїР»РµРєСЃСѓ', 'РЎРµРјСЊРё 28-45, РёРЅРІРµСЃС‚РѕСЂС‹, Р¶РёС‚РµР»Рё Р‘СЂР°С‚СЃРєР° Рё РСЂРєСѓС‚СЃРєР°', 'VK, Telegram, СЃР°Р№С‚ Р·Р°СЃС‚СЂРѕР№С‰РёРєР°', 'РЎРѕРІСЂРµРјРµРЅРЅР°СЏ Р°СЂС…РёС‚РµРєС‚СѓСЂР°, СЂРµР°Р»СЊРЅС‹Рµ Р¶РёР»СЊС†С‹, СЃРµРјРµР№РЅС‹Рµ СЃС†РµРЅР°СЂРёРё', 'РЎРѕРіР»Р°СЃРѕРІР°РЅРёРµ СЋСЂРёРґРёС‡РµСЃРєРёС… С„РѕСЂРјСѓР»РёСЂРѕРІРѕРє РѕР±СЏР·Р°С‚РµР»СЊРЅРѕ', '2026-06-30', 650000, 'РђР±РѕРЅРµРЅС‚СЃРєРѕРµ SMM РЅР° 3 РјРµСЃСЏС†Р°, СЃСЉРµРјРєРё РѕР±СЉРµРєС‚Р°, РѕС‚С‡РµС‚С‹ Рё СЂРµРєР»Р°РјРЅС‹Рµ РєСЂРµР°С‚РёРІС‹', 2, '2026-03-06 10:00:00'),
(3, 3, 'initial', 'РЈРїР°РєРѕРІР°С‚СЊ СЌРєСЃРїРµСЂС‚РЅС‹Р№ Р»РёС‡РЅС‹Р№ Р±СЂРµРЅРґ РЅСѓС‚СЂРёС†РёРѕР»РѕРіР°', 'Р–РµРЅС‰РёРЅС‹ 25-40, РёРЅС‚РµСЂРµСЃ Рє Р·РґРѕСЂРѕРІСЊСЋ, РјСЏРіРєРѕРјСѓ РїРѕС…СѓРґРµРЅРёСЋ, СЂРµР¶РёРјСѓ РїРёС‚Р°РЅРёСЏ', 'Instagram, Telegram, VK', 'Р§РёСЃС‚С‹Р№ СЌРєСЃРїРµСЂС‚РЅС‹Р№ РІРёР·СѓР°Р», С‚РµРїР»С‹Рµ РїРѕСЂС‚СЂРµС‚С‹, РїСЂРѕСЃС‚С‹Рµ СЃС…РµРјС‹', 'РќРµ РѕР±РµС‰Р°С‚СЊ РјРµРґРёС†РёРЅСЃРєРёР№ СЌС„С„РµРєС‚', '2026-05-15', 280000, 'РЎС‚СЂР°С‚РµРіРёСЏ, РєРѕРЅС‚РµРЅС‚-РїР»Р°РЅ, СЃС†РµРЅР°СЂРёРё Reels, С„РѕС‚РѕСЃРµСЃСЃРёСЏ Рё РѕС„РѕСЂРјР»РµРЅРёРµ РїСЂРѕС„РёР»СЏ', 3, '2026-03-09 14:30:00'),
(4, 4, 'initial', 'РџСЂРѕРґРІРёРЅСѓС‚СЊ СЃРµР·РѕРЅРЅРѕРµ РјРµРЅСЋ РєРѕС„РµР№РЅРё С‡РµСЂРµР· Р°С‚РјРѕСЃС„РµСЂРЅС‹Рµ СЂРѕР»РёРєРё', 'Р“РѕСЃС‚Рё РєРѕС„РµР№РЅРё 18-35, СЃС‚СѓРґРµРЅС‚С‹, РѕС„РёСЃРЅС‹Рµ СЃРѕС‚СЂСѓРґРЅРёРєРё', 'VK, Instagram, РЇРЅРґРµРєСЃ РљР°СЂС‚С‹', 'РўРµРїР»С‹Р№ СЃРІРµС‚, slow coffee, СѓСЋС‚РЅС‹Рµ РґРµС‚Р°Р»Рё', 'РЎСЉРµРјРєР° С‚РѕР»СЊРєРѕ РґРѕ РѕС‚РєСЂС‹С‚РёСЏ РёР»Рё РїРѕСЃР»Рµ 21:00', '2026-04-20', 180000, 'РЎРЅСЏС‚СЊ РјРµРЅСЋ, РєРѕРјР°РЅРґСѓ, РёРЅС‚РµСЂСЊРµСЂ, РїРѕРґРіРѕС‚РѕРІРёС‚СЊ 6 РєРѕСЂРѕС‚РєРёС… СЂРѕР»РёРєРѕРІ', 2, '2026-02-21 12:10:00'),
(5, 5, 'initial', 'РџРѕРІС‹СЃРёС‚СЊ РґРѕРІРµСЂРёРµ Рє Р°РІС‚РѕСЃРµСЂРІРёСЃСѓ С‡РµСЂРµР· РґРµРјРѕРЅСЃС‚СЂР°С†РёСЋ РїСЂРѕС†РµСЃСЃРѕРІ Рё РєРѕРјР°РЅРґС‹', 'Р’Р»Р°РґРµР»СЊС†С‹ Р°РІС‚Рѕ 25-55, РјСѓР¶С‡РёРЅС‹ Рё Р¶РµРЅС‰РёРЅС‹, РєРѕСЂРїРѕСЂР°С‚РёРІРЅС‹Рµ РєР»РёРµРЅС‚С‹', 'VK, 2GIS, СЃР°Р№С‚', 'Р РµР°Р»СЊРЅС‹Рµ РїСЂРѕС†РµСЃСЃС‹ СЂРµРјРѕРЅС‚Р°, С‡РµСЃС‚РЅР°СЏ СЌРєСЃРїРµСЂС‚РЅРѕСЃС‚СЊ', 'РќРµ РїРѕРєР°Р·С‹РІР°С‚СЊ РЅРѕРјРµСЂР° РјР°С€РёРЅ Рё Р»РёС†Р° РєР»РёРµРЅС‚РѕРІ Р±РµР· СЃРѕРіР»Р°СЃРёСЏ', '2026-06-15', 340000, 'РЎСЉРµРјРєРё СЃРµСЂРІРёСЃР°, СЌРєСЃРїРµСЂС‚РЅС‹Рµ РїРѕСЃС‚С‹, РєРµР№СЃС‹, РІРёР·СѓР°Р»СЊРЅС‹Рµ С€Р°Р±Р»РѕРЅС‹', 2, '2026-03-18 16:45:00'),
(6, 6, 'initial', 'РџРѕРґРіРѕС‚РѕРІРёС‚СЊ РєР°С‚Р°Р»РѕРі СѓРєСЂР°С€РµРЅРёР№ РґР»СЏ РјР°СЂРєРµС‚РїР»РµР№СЃРѕРІ Рё СЃРѕС†СЃРµС‚РµР№', 'Р–РµРЅС‰РёРЅС‹ 20-45, РїРѕРєСѓРїР°С‚РµР»Рё handmade, РїРѕРґР°СЂРѕС‡РЅС‹Р№ СЃРµРіРјРµРЅС‚', 'Wildberries, Ozon, Instagram, VK', 'РњРёРЅРёРјР°Р»РёСЃС‚РёС‡РЅС‹Рµ РєР°С‚Р°Р»РѕРіРё, С‡РёСЃС‚С‹Р№ СЃРІРµС‚Р»С‹Р№ С„РѕРЅ', 'Р¦РІРµС‚ СѓРєСЂР°С€РµРЅРёР№ РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ РјР°РєСЃРёРјР°Р»СЊРЅРѕ С‚РѕС‡РЅС‹Рј', '2026-04-28', 220000, 'РџСЂРµРґРјРµС‚РЅР°СЏ СЃСЉРµРјРєР° 60 SKU, РєР°СЂС‚РѕС‡РєРё, РѕР±Р»РѕР¶РєРё, С„РёРЅР°Р»СЊРЅС‹Рµ Р°СЂС…РёРІС‹', 5, '2026-02-25 09:30:00'),
(7, 7, 'initial', 'РџСЂРѕРґР°С‚СЊ Р»РµС‚РЅРёРµ С‚СѓСЂС‹ РЅР° Р‘Р°Р№РєР°Р» С‡РµСЂРµР· СЌРјРѕС†РёРѕРЅР°Р»СЊРЅС‹Р№ РІРёР·СѓР°Р»СЊРЅС‹Р№ РєРѕРЅС‚РµРЅС‚', 'РўСѓСЂРёСЃС‚С‹ 25-50 РёР· СЂРµРіРёРѕРЅРѕРІ Р Р¤, СЃРµРјСЊРё Рё РјР°Р»С‹Рµ РіСЂСѓРїРїС‹', 'VK, Telegram, СЃР°Р№С‚, YouTube Shorts', 'РџРµР№Р·Р°Р¶Рё, РјР°СЂС€СЂСѓС‚РЅС‹Рµ РґРЅРµРІРЅРёРєРё, Р¶РёРІС‹Рµ СЌРјРѕС†РёРё РіСЂСѓРїРїС‹', 'РЎСЉРµРјРєРё Р·Р°РІРёСЃСЏС‚ РѕС‚ РїРѕРіРѕРґС‹, РЅСѓР¶РµРЅ СЂРµР·РµСЂРІРЅС‹Р№ РґРµРЅСЊ', '2026-07-10', 520000, 'РЎСЉРµРјРєРё РјР°СЂС€СЂСѓС‚РѕРІ, РІРёРґРµРѕ, С„РѕС‚Рѕ, СЃС‚РѕСЂРёСЃ, РјР°С‚РµСЂРёР°Р»С‹ РґР»СЏ СЃР°Р№С‚Р°', 3, '2026-03-25 13:00:00'),
(8, 8, 'initial', 'РћР±РЅРѕРІРёС‚СЊ РІРёР·СѓР°Р»СЊРЅСѓСЋ СЃРёСЃС‚РµРјСѓ РєСѓР»СЊС‚СѓСЂРЅРѕРіРѕ С†РµРЅС‚СЂР°', 'Р“РѕСЂРѕР¶Р°РЅРµ 18-55, С‚РІРѕСЂС‡РµСЃРєРёРµ СЃРѕРѕР±С‰РµСЃС‚РІР°, РїР°СЂС‚РЅРµСЂС‹ С†РµРЅС‚СЂР°', 'VK, Telegram, Р°С„РёС€Рё, РїРµС‡Р°С‚РЅС‹Рµ РјР°С‚РµСЂРёР°Р»С‹', 'РЎРѕРІСЂРµРјРµРЅРЅС‹Рµ РєСѓР»СЊС‚СѓСЂРЅС‹Рµ С†РµРЅС‚СЂС‹, С‚РёРїРѕРіСЂР°С„РёРєР°, Р°С„РёС€РЅР°СЏ РіСЂР°С„РёРєР°', 'РќСѓР¶РЅРѕ СЃРѕС…СЂР°РЅРёС‚СЊ СѓР·РЅР°РІР°РµРјРѕСЃС‚СЊ СЃС‚Р°СЂРѕРіРѕ Р»РѕРіРѕС‚РёРїР°', '2026-06-20', 300000, 'Р Р°Р·СЂР°Р±РѕС‚Р°С‚СЊ РІРёР·СѓР°Р»СЊРЅРѕРµ РЅР°РїСЂР°РІР»РµРЅРёРµ, С€Р°Р±Р»РѕРЅС‹ Р°С„РёС€ Рё РєРѕРЅС‚РµРЅС‚РЅС‹Рµ РјР°РєРµС‚С‹', 3, '2026-04-01 15:20:00'),
(9, 9, 'additional', 'РЈС‚РѕС‡РЅРёС‚СЊ С„РѕСЂРјР°С‚ Р°Р±РѕРЅРµРЅС‚СЃРєРѕРіРѕ СЃРѕРїСЂРѕРІРѕР¶РґРµРЅРёСЏ С„РёС‚РЅРµСЃ-РєР»СѓР±Р°', 'Р–РёС‚РµР»Рё СЂР°Р№РѕРЅР° 18-45, РґРµР№СЃС‚РІСѓСЋС‰РёРµ Рё РїРѕС‚РµРЅС†РёР°Р»СЊРЅС‹Рµ РєР»РёРµРЅС‚С‹ РєР»СѓР±Р°', 'VK, Instagram, Telegram', 'Р”РёРЅР°РјРёРєР°, СЌРЅРµСЂРіРёСЏ, СЂРµР°Р»СЊРЅС‹Рµ С‚СЂРµРЅРёСЂРѕРІРєРё', 'РќРµ РїСѓР±Р»РёРєРѕРІР°С‚СЊ РєР»РёРµРЅС‚РѕРІ Р±РµР· РїРёСЃСЊРјРµРЅРЅРѕРіРѕ СЃРѕРіР»Р°СЃРёСЏ', '2026-05-31', 360000, 'РњРµСЃСЏС‡РЅС‹Р№ РєРѕРЅС‚РµРЅС‚-РїР°Рє, СЃСЉРµРјРєРё С‚СЂРµРЅРёСЂРѕРІРѕРє, СЃС‚РѕСЂРёСЃ, Reels, РѕС‚С‡РµС‚С‹', 7, '2026-04-05 11:40:00'),
(10, 10, 'post', 'РЎРѕР±СЂР°С‚СЊ РѕР±СЂР°С‚РЅСѓСЋ СЃРІСЏР·СЊ РїРѕСЃР»Рµ СѓРїР°РєРѕРІРєРё РєСѓСЂСЃР° Р°РЅРіР»РёР№СЃРєРѕРіРѕ', 'Р РѕРґРёС‚РµР»Рё С€РєРѕР»СЊРЅРёРєРѕРІ, СЃС‚СѓРґРµРЅС‚С‹, РІР·СЂРѕСЃР»С‹Рµ СѓС‡РµРЅРёРєРё', 'YouTube, VK, СЃР°Р№С‚ С€РєРѕР»С‹', 'РћР±СЂР°Р·РѕРІР°С‚РµР»СЊРЅС‹Рµ РІРёРґРµРѕ, РґСЂСѓР¶РµР»СЋР±РЅС‹Р№ СЌРєСЃРїРµСЂС‚РЅС‹Р№ СЃС‚РёР»СЊ', 'РќРµ РїРѕРєР°Р·С‹РІР°С‚СЊ РЅРµСЃРѕРІРµСЂС€РµРЅРЅРѕР»РµС‚РЅРёС… Р±РµР· СЃРѕРіР»Р°СЃРёСЏ СЂРѕРґРёС‚РµР»РµР№', '2026-04-15', 240000, 'РџРѕСЃС‚Р±СЂРёС„ РїРѕ СЂРµР·СѓР»СЊС‚Р°С‚Р°Рј РєСѓСЂСЃР°, СЃРїРёСЃРѕРє РґРѕСЂР°Р±РѕС‚РѕРє Рё С„РёРЅР°Р»СЊРЅР°СЏ РѕС‚С‡РµС‚РЅРѕСЃС‚СЊ', 2, '2026-04-12 17:10:00');

COMMIT;

-- END 02_seed_01_core.sql


-- BEGIN 02_seed_02_projects.sql

-- РўРµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ: РїСЂРѕРµРєС‚С‹, СѓСЃР»СѓРіРё РїСЂРѕРµРєС‚РѕРІ Рё СЌС‚Р°РїС‹
-- Р—Р°РїСѓСЃРєР°С‚СЊ РїРѕСЃР»Рµ 02_seed_01_core.sql

BEGIN;

INSERT INTO projects (
    project_id, client_id, brief_id, project_name, project_type, status,
    director_id, lead_id, creative_director_id, start_date, planned_end_date, actual_end_date,
    budget, description
) VALUES
(1, 1, 1, 'Р—Р°РїСѓСЃРє Р»РёРЅРµР№РєРё РєСЂР°С„С‚РѕРІС‹С… СЃС‹СЂРѕРІ', 'one_time', 'in_progress', 1, 2, 3, '2026-03-10', '2026-05-30', NULL, 420000, 'РљРѕРјРїР»РµРєСЃРЅС‹Р№ Р·Р°РїСѓСЃРє РїСЂРѕРґСѓРєС‚Р°: СЃС‚СЂР°С‚РµРіРёСЏ, С„РѕС‚Рѕ, РІРёРґРµРѕ, РґРёР·Р°Р№РЅ Рё С„РёРЅР°Р»СЊРЅР°СЏ РїСЂРµР·РµРЅС‚Р°С†РёСЏ'),
(2, 2, 2, 'SMM-СЃРѕРїСЂРѕРІРѕР¶РґРµРЅРёРµ Р–Рљ "РЎРѕР»РЅРµС‡РЅС‹Р№"', 'subscription', 'revisions', 1, 2, 3, '2026-03-15', '2026-06-30', NULL, 650000, 'РђР±РѕРЅРµРЅС‚СЃРєРѕРµ СЃРѕРїСЂРѕРІРѕР¶РґРµРЅРёРµ РїСЂРѕРµРєС‚Р° РЅРµРґРІРёР¶РёРјРѕСЃС‚Рё СЃ СЂРµРіСѓР»СЏСЂРЅРѕР№ РѕС‚С‡РµС‚РЅРѕСЃС‚СЊСЋ'),
(3, 3, 3, 'Р›РёС‡РЅС‹Р№ Р±СЂРµРЅРґ РЅСѓС‚СЂРёС†РёРѕР»РѕРіР°', 'subscription', 'approval', 1, 2, 3, '2026-03-20', '2026-05-15', NULL, 280000, 'РЎС‚СЂР°С‚РµРіРёСЏ, РІРёР·СѓР°Р», С‚РµРєСЃС‚С‹ Рё СЌРєСЃРїРµСЂС‚РЅС‹Р№ РєРѕРЅС‚РµРЅС‚ РґР»СЏ Р»РёС‡РЅРѕРіРѕ Р±СЂРµРЅРґР°'),
(4, 4, 4, 'Р’РёРґРµРѕСЂРѕР»РёРєРё РґР»СЏ РєРѕС„РµР№РЅРё', 'one_time', 'closed', 1, 2, 3, '2026-02-25', '2026-04-20', '2026-04-18', 180000, 'РЎСЉРµРјРєР° Рё РјРѕРЅС‚Р°Р¶ СЃРµСЂРёРё РєРѕСЂРѕС‚РєРёС… СЂРѕР»РёРєРѕРІ СЃРµР·РѕРЅРЅРѕРіРѕ РјРµРЅСЋ'),
(5, 5, 5, 'РљРѕРЅС‚РµРЅС‚ РґР»СЏ Р°РІС‚РѕСЃРµСЂРІРёСЃР°', 'subscription', 'in_progress', 1, 2, 3, '2026-03-22', '2026-06-15', NULL, 340000, 'РљРѕРЅС‚РµРЅС‚ Рѕ РєРѕРјР°РЅРґРµ, РїСЂРѕС†РµСЃСЃР°С… СЂРµРјРѕРЅС‚Р°, РєРµР№СЃР°С… Рё СЌРєСЃРїРµСЂС‚РЅРѕСЃС‚Рё'),
(6, 6, 6, 'РљР°С‚Р°Р»РѕРі handmade СѓРєСЂР°С€РµРЅРёР№', 'one_time', 'completed', 1, 2, 3, '2026-03-01', '2026-04-28', '2026-04-26', 220000, 'РџСЂРµРґРјРµС‚РЅР°СЏ СЃСЉРµРјРєР° СѓРєСЂР°С€РµРЅРёР№ Рё РїРѕРґРіРѕС‚РѕРІРєР° РєР°СЂС‚РѕС‡РµРє С‚РѕРІР°СЂРѕРІ'),
(7, 7, 7, 'РўСѓСЂРёСЃС‚РёС‡РµСЃРєРёР№ СЃРµР·РѕРЅ Р‘Р°Р№РєР°Р»', 'one_time', 'in_progress', 1, 2, 3, '2026-04-01', '2026-07-10', NULL, 520000, 'Р¤РѕС‚Рѕ- Рё РІРёРґРµРѕРєРѕРЅС‚РµРЅС‚ РјР°СЂС€СЂСѓС‚РѕРІ РґР»СЏ Р»РµС‚РЅРµРіРѕ С‚СѓСЂРёСЃС‚РёС‡РµСЃРєРѕРіРѕ СЃРµР·РѕРЅР°'),
(8, 8, 8, 'Р РµР±СЂРµРЅРґРёРЅРі РєСѓР»СЊС‚СѓСЂРЅРѕРіРѕ С†РµРЅС‚СЂР°', 'one_time', 'negotiation', 1, 2, 3, '2026-04-08', '2026-06-20', NULL, 300000, 'Р’РёР·СѓР°Р»СЊРЅРѕРµ РЅР°РїСЂР°РІР»РµРЅРёРµ, С€Р°Р±Р»РѕРЅС‹ Р°С„РёС€ Рё РєРѕРјРјСѓРЅРёРєР°С†РёРѕРЅРЅС‹Рµ РјР°С‚РµСЂРёР°Р»С‹'),
(9, 9, 9, 'РљРѕРЅС‚РµРЅС‚-РїР°Рє РґР»СЏ С„РёС‚РЅРµСЃ-РєР»СѓР±Р°', 'subscription', 'prepaid', 1, 2, 3, '2026-04-10', '2026-05-31', NULL, 360000, 'РњРµСЃСЏС‡РЅС‹Р№ РєРѕРЅС‚РµРЅС‚-РїР°Рє СЃ Reels, СЃС‚РѕСЂРёСЃ, РїРѕСЃС‚Р°РјРё Рё РѕС‚С‡РµС‚РѕРј'),
(10, 10, 10, 'Р’РёРґРµРѕСѓРїР°РєРѕРІРєР° РєСѓСЂСЃР° Р°РЅРіР»РёР№СЃРєРѕРіРѕ', 'one_time', 'closed', 1, 2, 3, '2026-02-10', '2026-04-15', '2026-04-14', 240000, 'РЎС†РµРЅР°СЂРёРё, СЃСЉРµРјРєР° Рё РјРѕРЅС‚Р°Р¶ РІРёРґРµРѕ РґР»СЏ РѕРЅР»Р°Р№РЅ-РєСѓСЂСЃР°');

INSERT INTO project_services (project_service_id, project_id, service_id, quantity, price, service_comment) VALUES
(1, 1, 1, 1, 45000, 'РЎС‚СЂР°С‚РµРіРёСЏ Р·Р°РїСѓСЃРєР° РїСЂРѕРґСѓРєС‚Р°'),
(2, 1, 3, 1, 70000, 'Р¤РѕС‚РѕСЃСЉРµРјРєР° РїСЂРѕРґСѓРєС†РёРё Рё РїСЂРѕРёР·РІРѕРґСЃС‚РІР°'),
(3, 1, 4, 1, 85000, 'Р’РёРґРµРѕСЃСЉРµРјРєР° РїСЂРѕРёР·РІРѕРґСЃС‚РІР°'),
(4, 1, 6, 1, 55000, 'Р”РёР·Р°Р№РЅ РїСЂРµР·РµРЅС‚Р°С†РёРё Рё РІРёР·СѓР°Р»РѕРІ'),
(5, 1, 10, 1, 65000, 'РџРѕСЃС‚РїСЂРѕРґР°РєС€РЅ СЂРѕР»РёРєР°'),
(6, 2, 2, 3, 105000, 'РљРѕРЅС‚РµРЅС‚-РїР»Р°РЅС‹ РЅР° 3 РјРµСЃСЏС†Р°'),
(7, 2, 7, 3, 300000, 'SMM-СЃРѕРїСЂРѕРІРѕР¶РґРµРЅРёРµ'),
(8, 2, 3, 2, 120000, 'РЎСЉРµРјРєРё РѕР±СЉРµРєС‚Р°'),
(9, 2, 12, 3, 60000, 'Р•Р¶РµРјРµСЃСЏС‡РЅС‹Рµ РѕС‚С‡РµС‚С‹'),
(10, 3, 1, 1, 45000, 'РЎС‚СЂР°С‚РµРіРёСЏ Р»РёС‡РЅРѕРіРѕ Р±СЂРµРЅРґР°'),
(11, 3, 2, 2, 70000, 'РљРѕРЅС‚РµРЅС‚-РїР»Р°РЅ Рё СЂСѓР±СЂРёРєР°С‚РѕСЂ'),
(12, 3, 9, 1, 35000, 'РЎС†РµРЅР°СЂРёРё СЌРєСЃРїРµСЂС‚РЅС‹С… Reels'),
(13, 3, 6, 1, 60000, 'РћС„РѕСЂРјР»РµРЅРёРµ РїСЂРѕС„РёР»СЏ'),
(14, 4, 4, 1, 80000, 'РЎСЉРµРјРєР° СЃРµР·РѕРЅРЅРѕРіРѕ РјРµРЅСЋ'),
(15, 4, 5, 6, 90000, 'РњРѕРЅС‚Р°Р¶ 6 РєРѕСЂРѕС‚РєРёС… СЂРѕР»РёРєРѕРІ'),
(16, 5, 7, 2, 180000, 'SMM-СЃРѕРїСЂРѕРІРѕР¶РґРµРЅРёРµ Р°РІС‚РѕСЃРµСЂРІРёСЃР°'),
(17, 5, 3, 1, 65000, 'РЎСЉРµРјРєР° РєРѕРјР°РЅРґС‹ Рё РїСЂРѕС†РµСЃСЃРѕРІ'),
(18, 5, 6, 1, 50000, 'Р”РёР·Р°Р№РЅ С€Р°Р±Р»РѕРЅРѕРІ'),
(19, 6, 11, 1, 140000, 'РљР°С‚Р°Р»РѕРі 60 SKU'),
(20, 6, 6, 1, 45000, 'РљР°СЂС‚РѕС‡РєРё Рё РѕР±Р»РѕР¶РєРё'),
(21, 7, 3, 2, 140000, 'Р¤РѕС‚РѕСЃСЉРµРјРєР° РјР°СЂС€СЂСѓС‚РѕРІ'),
(22, 7, 4, 2, 170000, 'Р’РёРґРµРѕСЃСЉРµРјРєР° С‚СѓСЂРѕРІ'),
(23, 7, 10, 1, 85000, 'РњРѕРЅС‚Р°Р¶ РїСЂРѕРјРѕСЂРѕР»РёРєРѕРІ'),
(24, 8, 8, 1, 90000, 'РљСЂРµР°С‚РёРІРЅР°СЏ РєРѕРЅС†РµРїС†РёСЏ СЂРµР±СЂРµРЅРґРёРЅРіР°'),
(25, 8, 6, 2, 100000, 'РЁР°Р±Р»РѕРЅС‹ Р°С„РёС€ Рё СЃРѕС†СЃРµС‚РµР№'),
(26, 9, 2, 1, 35000, 'РљРѕРЅС‚РµРЅС‚-РїР»Р°РЅ РЅР° РјРµСЃСЏС†'),
(27, 9, 7, 1, 110000, 'Р’РµРґРµРЅРёРµ СЃРѕС†СЃРµС‚РµР№'),
(28, 9, 4, 1, 80000, 'РЎСЉРµРјРєР° С‚СЂРµРЅРёСЂРѕРІРѕРє'),
(29, 10, 9, 1, 40000, 'РЎС†РµРЅР°СЂРёРё СѓСЂРѕРєРѕРІ'),
(30, 10, 4, 1, 75000, 'РЎСЉРµРјРєР° РєСѓСЂСЃР°'),
(31, 10, 10, 1, 90000, 'РњРѕРЅС‚Р°Р¶ СѓС‡РµР±РЅС‹С… РІРёРґРµРѕ');

INSERT INTO project_stages (
    stage_id, project_id, stage_name, stage_order, responsible_id,
    planned_start_date, planned_end_date, actual_start_date, actual_end_date, status, comments
) VALUES
(1, 1, 'Р›РёРґ', 1, 1, '2026-03-01', '2026-03-03', '2026-03-01', '2026-03-03', 'completed', 'Р›РёРґ РїСЂРёС€РµР» РїРѕ СЂРµРєРѕРјРµРЅРґР°С†РёРё'),
(2, 1, 'РџРµСЂРІРёС‡РЅС‹Р№ РєРѕРЅС‚Р°РєС‚', 2, 2, '2026-03-04', '2026-03-04', '2026-03-04', '2026-03-04', 'completed', 'РџСЂРѕРІРµРґРµРЅ РїРµСЂРІРёС‡РЅС‹Р№ СЃРѕР·РІРѕРЅ'),
(3, 1, 'Р‘СЂРёС„', 3, 2, '2026-03-05', '2026-03-07', '2026-03-05', '2026-03-07', 'completed', 'Р‘СЂРёС„ Р·Р°РїРѕР»РЅРµРЅ Рё СЃРѕРіР»Р°СЃРѕРІР°РЅ'),
(4, 1, 'РџСЂРµРїСЂРѕРґР°РєС€РЅ', 4, 3, '2026-03-20', '2026-04-05', '2026-03-20', NULL, 'in_progress', 'РџРѕРґР±РѕСЂ Р»РѕРєР°С†РёР№ Рё РјСѓРґР±РѕСЂРґР°'),
(5, 1, 'РџСЂРѕРґР°РєС€РЅ', 5, 5, '2026-04-06', '2026-04-18', NULL, NULL, 'planned', 'РЎСЉРµРјРѕС‡РЅС‹Р№ СЌС‚Р°Рї'),
(6, 1, 'Р¤РёРЅР°Р»СЊРЅР°СЏ СЃРґР°С‡Р°', 6, 2, '2026-05-20', '2026-05-30', NULL, NULL, 'planned', 'РџРµСЂРµРґР°С‡Р° С„РёРЅР°Р»СЊРЅС‹С… РјР°С‚РµСЂРёР°Р»РѕРІ'),
(7, 2, 'Р—Р°РїСѓСЃРє РїСЂРѕРµРєС‚Р°', 1, 2, '2026-03-15', '2026-03-17', '2026-03-15', '2026-03-17', 'completed', 'РџСЂРѕРµРєС‚ РѕС‚РєСЂС‹С‚ РїРѕСЃР»Рµ РїСЂРµРґРѕРїР»Р°С‚С‹'),
(8, 2, 'РЎС‚СЂР°С‚РµРіРёСЏ / РїР»Р°РЅ СЂР°Р±РѕС‚', 2, 3, '2026-03-18', '2026-03-25', '2026-03-18', '2026-03-25', 'approved', 'РљРѕРЅС‚РµРЅС‚-СЃС‚СЂР°С‚РµРіРёСЏ СѓС‚РІРµСЂР¶РґРµРЅР°'),
(9, 2, 'РџСЂРѕРґР°РєС€РЅ', 3, 5, '2026-03-26', '2026-05-30', '2026-03-26', NULL, 'in_progress', 'Р РµРіСѓР»СЏСЂРЅС‹Рµ СЃСЉРµРјРєРё РѕР±СЉРµРєС‚Р°'),
(10, 2, 'РџРѕСЃС‚РїСЂРѕРґР°РєС€РЅ', 4, 8, '2026-04-01', '2026-06-10', '2026-04-01', NULL, 'in_progress', 'РњРѕРЅС‚Р°Р¶ Рё Р°РґР°РїС‚Р°С†РёСЏ СЂРѕР»РёРєРѕРІ'),
(11, 2, 'РЎРѕРіР»Р°СЃРѕРІР°РЅРёРµ', 5, 3, '2026-04-10', '2026-06-20', '2026-04-10', NULL, 'in_progress', 'РњР°С‚РµСЂРёР°Р»С‹ СЃРѕРіР»Р°СЃСѓСЋС‚СЃСЏ СЃ РјР°СЂРєРµС‚РёРЅРіРѕРј'),
(12, 2, 'РџСЂР°РІРєРё', 6, 8, '2026-04-15', '2026-06-25', '2026-04-15', NULL, 'in_progress', 'Р’РЅРµСЃРµРЅРёРµ РїСЂР°РІРѕРє РїРѕ РєСЂРµР°С‚РёРІР°Рј'),
(13, 3, 'Р‘СЂРёС„', 1, 2, '2026-03-20', '2026-03-22', '2026-03-20', '2026-03-22', 'completed', 'РЎРѕР±СЂР°РЅС‹ С†РµР»Рё Рё РѕРіСЂР°РЅРёС‡РµРЅРёСЏ'),
(14, 3, 'РџРѕРґРіРѕС‚РѕРІРєР° РїСЂРµРґР»РѕР¶РµРЅРёСЏ', 2, 3, '2026-03-23', '2026-03-27', '2026-03-23', '2026-03-27', 'completed', 'РџСЂРµРґР»РѕР¶РµРЅРёРµ РїСЂРёРЅСЏС‚Рѕ РєР»РёРµРЅС‚РѕРј'),
(15, 3, 'Р—Р°РїСѓСЃРє РїСЂРѕРµРєС‚Р°', 3, 2, '2026-03-28', '2026-03-29', '2026-03-28', '2026-03-29', 'completed', 'РљРѕРјР°РЅРґР° РЅР°Р·РЅР°С‡РµРЅР°'),
(16, 3, 'РЎС‚СЂР°С‚РµРіРёСЏ / РїР»Р°РЅ СЂР°Р±РѕС‚', 4, 7, '2026-03-30', '2026-04-15', '2026-03-30', NULL, 'in_progress', 'Р“РѕС‚РѕРІРёС‚СЃСЏ РєРѕРЅС‚РµРЅС‚-РїР»Р°РЅ'),
(17, 3, 'РЎРѕРіР»Р°СЃРѕРІР°РЅРёРµ', 5, 3, '2026-04-16', '2026-05-05', NULL, NULL, 'planned', 'РЎРѕРіР»Р°СЃРѕРІР°РЅРёРµ РІРёР·СѓР°Р»Р° Рё СЃРјС‹СЃР»РѕРІ'),
(18, 4, 'Р‘СЂРёС„', 1, 2, '2026-02-25', '2026-02-27', '2026-02-25', '2026-02-27', 'completed', 'Р‘СЂРёС„ Р·Р°РІРµСЂС€РµРЅ'),
(19, 4, 'РџСЂРµРїСЂРѕРґР°РєС€РЅ', 2, 3, '2026-02-28', '2026-03-05', '2026-02-28', '2026-03-05', 'completed', 'РЎС†РµРЅР°СЂРёРё Рё РїР»Р°РЅ СЃСЉРµРјРєРё СѓС‚РІРµСЂР¶РґРµРЅС‹'),
(20, 4, 'РџСЂРѕРґР°РєС€РЅ', 3, 6, '2026-03-06', '2026-03-12', '2026-03-06', '2026-03-11', 'completed', 'РЎСЉРµРјРєР° РјРµРЅСЋ Р·Р°РІРµСЂС€РµРЅР°'),
(21, 4, 'РџРѕСЃС‚РїСЂРѕРґР°РєС€РЅ', 4, 8, '2026-03-13', '2026-04-05', '2026-03-13', '2026-04-02', 'completed', 'Р РѕР»РёРєРё СЃРјРѕРЅС‚РёСЂРѕРІР°РЅС‹'),
(22, 4, 'Р¤РёРЅР°Р»СЊРЅР°СЏ СЃРґР°С‡Р°', 5, 2, '2026-04-06', '2026-04-20', '2026-04-06', '2026-04-18', 'approved', 'Р¤РёРЅР°Р»СЊРЅС‹Рµ РјР°С‚РµСЂРёР°Р»С‹ РїРµСЂРµРґР°РЅС‹'),
(23, 5, 'Р›РёРґ', 1, 1, '2026-03-15', '2026-03-17', '2026-03-15', '2026-03-17', 'completed', 'Р—Р°СЏРІРєР° СЃ СЃР°Р№С‚Р°'),
(24, 5, 'РЎРѕР·РІРѕРЅ / РІСЃС‚СЂРµС‡Р°', 2, 2, '2026-03-18', '2026-03-18', '2026-03-18', '2026-03-18', 'completed', 'Р’СЃС‚СЂРµС‡Р° РЅР° СЃС‚Р°РЅС†РёРё'),
(25, 5, 'Р‘СЂРёС„', 3, 2, '2026-03-19', '2026-03-20', '2026-03-19', '2026-03-20', 'completed', 'Р—Р°С„РёРєСЃРёСЂРѕРІР°РЅС‹ РѕРіСЂР°РЅРёС‡РµРЅРёСЏ СЃСЉРµРјРєРё'),
(26, 5, 'РЎС‚СЂР°С‚РµРіРёСЏ / РїР»Р°РЅ СЂР°Р±РѕС‚', 4, 3, '2026-03-21', '2026-04-05', '2026-03-21', NULL, 'in_progress', 'Р¤РѕСЂРјРёСЂСѓРµС‚СЃСЏ СЂСѓР±СЂРёРєР°С‚РѕСЂ'),
(27, 5, 'РџСЂРѕРґР°РєС€РЅ', 5, 5, '2026-04-06', '2026-05-30', NULL, NULL, 'planned', 'РЎСЉРµРјРєРё РєРѕРјР°РЅРґС‹ Рё СЃРµСЂРІРёСЃР°'),
(28, 6, 'Р‘СЂРёС„', 1, 5, '2026-03-01', '2026-03-02', '2026-03-01', '2026-03-02', 'completed', 'РЎРїРёСЃРѕРє С‚РѕРІР°СЂРѕРІ РїРѕР»СѓС‡РµРЅ'),
(29, 6, 'РџСЂРѕРґР°РєС€РЅ', 2, 5, '2026-03-05', '2026-03-25', '2026-03-05', '2026-03-24', 'completed', 'РЎСЉРµРјРєР° СѓРєСЂР°С€РµРЅРёР№ Р·Р°РІРµСЂС€РµРЅР°'),
(30, 6, 'РЎРѕРіР»Р°СЃРѕРІР°РЅРёРµ', 3, 3, '2026-03-26', '2026-04-10', '2026-03-26', '2026-04-09', 'approved', 'РљР°С‚Р°Р»РѕРі СЃРѕРіР»Р°СЃРѕРІР°РЅ'),
(31, 6, 'Р¤РёРЅР°Р»СЊРЅР°СЏ РѕРїР»Р°С‚Р°', 4, 1, '2026-04-20', '2026-04-28', '2026-04-20', '2026-04-26', 'completed', 'РћРїР»Р°С‚Р° РїРѕР»СѓС‡РµРЅР°'),
(32, 7, 'РЎРѕР·РІРѕРЅ / РІСЃС‚СЂРµС‡Р°', 1, 2, '2026-04-01', '2026-04-02', '2026-04-01', '2026-04-02', 'completed', 'РћР±СЃСѓР¶РґРµРЅС‹ РјР°СЂС€СЂСѓС‚С‹'),
(33, 7, 'Р‘СЂРёС„', 2, 3, '2026-04-03', '2026-04-07', '2026-04-03', '2026-04-07', 'completed', 'Р‘СЂРёС„ РїРѕ С‚СѓСЂР°Рј РіРѕС‚РѕРІ'),
(34, 7, 'РџСЂРµРїСЂРѕРґР°РєС€РЅ', 3, 6, '2026-04-08', '2026-04-30', '2026-04-08', NULL, 'in_progress', 'РЎСЉРµРјРѕС‡РЅС‹Р№ РіСЂР°С„РёРє Р·Р°РІРёСЃРёС‚ РѕС‚ РїРѕРіРѕРґС‹'),
(35, 7, 'РџСЂРѕРґР°РєС€РЅ', 4, 6, '2026-05-05', '2026-06-10', NULL, NULL, 'planned', 'Р’С‹РµР·РґРЅС‹Рµ СЃСЉРµРјРєРё РјР°СЂС€СЂСѓС‚РѕРІ'),
(36, 7, 'РџРѕСЃС‚РїСЂРѕРґР°РєС€РЅ', 5, 8, '2026-06-11', '2026-07-05', NULL, NULL, 'planned', 'РњРѕРЅС‚Р°Р¶ РїСЂРѕРјРѕСЂРѕР»РёРєРѕРІ'),
(37, 8, 'РџРѕРґРіРѕС‚РѕРІРєР° РїСЂРµРґР»РѕР¶РµРЅРёСЏ', 1, 3, '2026-04-08', '2026-04-15', '2026-04-08', NULL, 'in_progress', 'Р¤РѕСЂРјРёСЂСѓСЋС‚СЃСЏ РІР°СЂРёР°РЅС‚С‹ РєРѕРЅС†РµРїС†РёРё'),
(38, 8, 'РЎРѕРіР»Р°СЃРѕРІР°РЅРёРµ СѓСЃР»РѕРІРёР№', 2, 1, '2026-04-16', '2026-04-25', NULL, NULL, 'planned', 'РћР¶РёРґР°РµС‚СЃСЏ РІСЃС‚СЂРµС‡Р° СЃ СЃРѕРІРµС‚РѕРј'),
(39, 8, 'РџСЂРµРґРѕРїР»Р°С‚Р°', 3, 1, '2026-04-26', '2026-05-02', NULL, NULL, 'planned', 'РЎС‡РµС‚ Р±СѓРґРµС‚ РІС‹СЃС‚Р°РІР»РµРЅ РїРѕСЃР»Рµ СѓС‚РІРµСЂР¶РґРµРЅРёСЏ СѓСЃР»РѕРІРёР№'),
(40, 9, 'РџСЂРµРґРѕРїР»Р°С‚Р°', 1, 1, '2026-04-10', '2026-04-12', '2026-04-10', '2026-04-12', 'completed', 'РџСЂРµРґРѕРїР»Р°С‚Р° РїРѕР»СѓС‡РµРЅР°'),
(41, 9, 'Р—Р°РїСѓСЃРє РїСЂРѕРµРєС‚Р°', 2, 2, '2026-04-13', '2026-04-15', '2026-04-13', NULL, 'in_progress', 'РЎРѕР±РёСЂР°РµС‚СЃСЏ СЂР°Р±РѕС‡Р°СЏ РіСЂСѓРїРїР°'),
(42, 9, 'РЎС‚СЂР°С‚РµРіРёСЏ / РїР»Р°РЅ СЂР°Р±РѕС‚', 3, 7, '2026-04-16', '2026-04-25', NULL, NULL, 'planned', 'РљРѕРЅС‚РµРЅС‚-СЃРµС‚РєР° РЅР° РјРµСЃСЏС†'),
(43, 10, 'Р‘СЂРёС„', 1, 2, '2026-02-10', '2026-02-12', '2026-02-10', '2026-02-12', 'completed', 'Р‘СЂРёС„ РєСѓСЂСЃР° РіРѕС‚РѕРІ'),
(44, 10, 'РџСЂРѕРґР°РєС€РЅ', 2, 6, '2026-02-15', '2026-03-15', '2026-02-15', '2026-03-13', 'completed', 'РЎСЉРµРјРєР° СѓСЂРѕРєРѕРІ Р·Р°РІРµСЂС€РµРЅР°'),
(45, 10, 'Р¤РёРЅР°Р»СЊРЅР°СЏ СЃРґР°С‡Р°', 3, 8, '2026-03-16', '2026-04-05', '2026-03-16', '2026-04-04', 'approved', 'Р’РёРґРµРѕ РїРµСЂРµРґР°РЅС‹ РєР»РёРµРЅС‚Сѓ'),
(46, 10, 'Р—Р°РєСЂС‹С‚РёРµ РїСЂРѕРµРєС‚Р°', 4, 1, '2026-04-06', '2026-04-15', '2026-04-06', '2026-04-14', 'completed', 'РџСЂРѕРµРєС‚ Р·Р°РєСЂС‹С‚');

COMMIT;

-- END 02_seed_02_projects.sql


-- BEGIN 02_seed_03_tasks_checklists.sql

-- РўРµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ: С‡РµРє-Р»РёСЃС‚С‹, Р·Р°РґР°С‡Рё Рё СЃС‚Р°С‚СѓСЃС‹ С‡РµРє-Р»РёСЃС‚РѕРІ
-- Р—Р°РїСѓСЃРєР°С‚СЊ РїРѕСЃР»Рµ 02_seed_02_projects.sql

BEGIN;

INSERT INTO checklist_templates (template_id, template_name, stage_name, description, is_active) VALUES
(1, 'Р§РµРє-Р»РёСЃС‚ Р±СЂРёС„Р°', 'Р‘СЂРёС„', 'РљРѕРЅС‚СЂРѕР»СЊ РїРѕР»РЅРѕС‚С‹ РґР°РЅРЅС‹С… РїРµСЂРµРґ Р·Р°РїСѓСЃРєРѕРј РїСЂРѕРµРєС‚Р°', TRUE),
(2, 'Р§РµРє-Р»РёСЃС‚ СЃСЉРµРјРѕС‡РЅРѕРіРѕ РґРЅСЏ', 'РџСЂРѕРґР°РєС€РЅ', 'РџРѕРґРіРѕС‚РѕРІРєР° Рё РєРѕРЅС‚СЂРѕР»СЊ С„РѕС‚Рѕ- РёР»Рё РІРёРґРµРѕСЃСЉРµРјРєРё', TRUE),
(3, 'Р§РµРє-Р»РёСЃС‚ РґРёР·Р°Р№РЅ-РјР°РєРµС‚Р°', 'Р”РёР·Р°Р№РЅ', 'РџСЂРѕРІРµСЂРєР° РјР°РєРµС‚РѕРІ РїРµСЂРµРґ РѕС‚РїСЂР°РІРєРѕР№ РєР»РёРµРЅС‚Сѓ', TRUE),
(4, 'Р§РµРє-Р»РёСЃС‚ РїРѕСЃС‚РїСЂРѕРґР°РєС€РЅР°', 'РџРѕСЃС‚РїСЂРѕРґР°РєС€РЅ', 'РљРѕРЅС‚СЂРѕР»СЊ РјРѕРЅС‚Р°Р¶Р°, С†РІРµС‚Р°, Р·РІСѓРєР° Рё СЌРєСЃРїРѕСЂС‚Р°', TRUE),
(5, 'Р§РµРє-Р»РёСЃС‚ С„РёРЅР°Р»СЊРЅРѕР№ СЃРґР°С‡Рё', 'Р¤РёРЅР°Р»СЊРЅР°СЏ СЃРґР°С‡Р°', 'РљРѕРЅС‚СЂРѕР»СЊ РїРµСЂРµРґР°С‡Рё РјР°С‚РµСЂРёР°Р»РѕРІ Рё Р·Р°РєСЂС‹РІР°СЋС‰РёС… РґРѕРєСѓРјРµРЅС‚РѕРІ', TRUE);

INSERT INTO checklist_items (item_id, template_id, item_order, item_text, is_required) VALUES
(1, 1, 1, 'Р¦РµР»СЊ РїСЂРѕРµРєС‚Р° Р·Р°С„РёРєСЃРёСЂРѕРІР°РЅР° РїРёСЃСЊРјРµРЅРЅРѕ', TRUE),
(2, 1, 2, 'Р¦РµР»РµРІР°СЏ Р°СѓРґРёС‚РѕСЂРёСЏ РѕРїРёСЃР°РЅР° СЃРµРіРјРµРЅС‚Р°РјРё', TRUE),
(3, 1, 3, 'РџР»РѕС‰Р°РґРєРё РїСѓР±Р»РёРєР°С†РёРё СѓРєР°Р·Р°РЅС‹', TRUE),
(4, 1, 4, 'РћРіСЂР°РЅРёС‡РµРЅРёСЏ Рё СЋСЂРёРґРёС‡РµСЃРєРёРµ СЂРёСЃРєРё Р·Р°РїРёСЃР°РЅС‹', TRUE),
(5, 2, 1, 'Р”Р°С‚Р°, РІСЂРµРјСЏ Рё РјРµСЃС‚Рѕ СЃСЉРµРјРєРё РїРѕРґС‚РІРµСЂР¶РґРµРЅС‹', TRUE),
(6, 2, 2, 'РЎСЉРµРјРѕС‡РЅС‹Р№ РїР»Р°РЅ СѓС‚РІРµСЂР¶РґРµРЅ РѕС‚РІРµС‚СЃС‚РІРµРЅРЅС‹Рј', TRUE),
(7, 2, 3, 'Р РµРєРІРёР·РёС‚, С‚РµС…РЅРёРєР° Рё СѓС‡Р°СЃС‚РЅРёРєРё РїРѕРґРіРѕС‚РѕРІР»РµРЅС‹', TRUE),
(8, 2, 4, 'РСЃС…РѕРґРЅРёРєРё Р·Р°РіСЂСѓР¶РµРЅС‹ РІ СЂР°Р±РѕС‡СѓСЋ РїР°РїРєСѓ', TRUE),
(9, 3, 1, 'РњР°РєРµС‚ СЃРѕРѕС‚РІРµС‚СЃС‚РІСѓРµС‚ Р±СЂРµРЅРґ-СЃС‚РёР»СЋ Рё РўР—', TRUE),
(10, 3, 2, 'РўРµРєСЃС‚ РІС‹С‡РёС‚Р°РЅ Рё РЅРµ СЃРѕРґРµСЂР¶РёС‚ РѕС€РёР±РѕРє', TRUE),
(11, 3, 3, 'Р Р°Р·РјРµСЂС‹ Рё С„РѕСЂРјР°С‚С‹ РїРѕРґС…РѕРґСЏС‚ РґР»СЏ РїР»РѕС‰Р°РґРѕРє', TRUE),
(12, 3, 4, 'Р¤Р°Р№Р» СЃРѕС…СЂР°РЅРµРЅ РІ СЂР°Р±РѕС‡РµРј Рё СЌРєСЃРїРѕСЂС‚РЅРѕРј С„РѕСЂРјР°С‚Рµ', TRUE),
(13, 4, 1, 'РСЃС…РѕРґРЅРёРєРё РїРѕР»СѓС‡РµРЅС‹ Рё СЂР°Р·Р»РѕР¶РµРЅС‹ РїРѕ РїР°РїРєР°Рј', TRUE),
(14, 4, 2, 'РњРѕРЅС‚Р°Р¶ СЃРѕРѕС‚РІРµС‚СЃС‚РІСѓРµС‚ СЃС†РµРЅР°СЂРёСЋ', TRUE),
(15, 4, 3, 'Р—РІСѓРє, С†РІРµС‚ Рё С‚РёС‚СЂС‹ РїСЂРѕРІРµСЂРµРЅС‹', TRUE),
(16, 4, 4, 'Р­РєСЃРїРѕСЂС‚ СЃРґРµР»Р°РЅ РІ РЅСѓР¶РЅС‹С… С„РѕСЂРјР°С‚Р°С…', TRUE),
(17, 5, 1, 'Р¤РёРЅР°Р»СЊРЅС‹Рµ РјР°С‚РµСЂРёР°Р»С‹ Р·Р°РіСЂСѓР¶РµРЅС‹', TRUE),
(18, 5, 2, 'РЎСЃС‹Р»РєРё РѕС‚РєСЂС‹РІР°СЋС‚СЃСЏ Сѓ РєР»РёРµРЅС‚Р°', TRUE),
(19, 5, 3, 'РћР±СЂР°С‚РЅР°СЏ СЃРІСЏР·СЊ РєР»РёРµРЅС‚Р° Р·Р°С„РёРєСЃРёСЂРѕРІР°РЅР°', TRUE),
(20, 5, 4, 'Р¤РёРЅР°Р»СЊРЅР°СЏ РѕРїР»Р°С‚Р° Рё Р·Р°РєСЂС‹С‚РёРµ РїСЂРѕРІРµСЂРµРЅС‹', TRUE);

INSERT INTO tasks (
    task_id, project_id, stage_id, assigner_id, assignee_id, task_name, description,
    priority, status, planned_hours, deadline, completed_at, checklist_template_id
) VALUES
(1, 1, 3, 2, 7, 'РЎРѕР±СЂР°С‚СЊ РѕС‚РІРµС‚С‹ РїРѕ Р±СЂРёС„Сѓ', 'РЈС‚РѕС‡РЅРёС‚СЊ С†РµР»Рё Р·Р°РїСѓСЃРєР°, Р°СѓРґРёС‚РѕСЂРёСЋ, РїР»РѕС‰Р°РґРєРё Рё РѕРіСЂР°РЅРёС‡РµРЅРёСЏ РїРѕ РїСЂРѕРґСѓРєС‚Сѓ', 'high', 'done', 4, '2026-03-07 18:00:00', '2026-03-07 16:30:00', 1),
(2, 1, 4, 3, 5, 'РџРѕРґРѕР±СЂР°С‚СЊ Р»РѕРєР°С†РёРё РґР»СЏ СЃСЉРµРјРєРё', 'РџРѕРґРіРѕС‚РѕРІРёС‚СЊ РІР°СЂРёР°РЅС‚С‹ РїСЂРѕРёР·РІРѕРґСЃС‚РІРµРЅРЅС‹С… Рё РЅР°С‚СѓСЂР°Р»СЊРЅС‹С… Р»РѕРєР°С†РёР№', 'medium', 'in_progress', 6, '2026-04-02 18:00:00', NULL, 2),
(3, 1, 4, 3, 4, 'РЎРѕР±СЂР°С‚СЊ moodboard Р·Р°РїСѓСЃРєР°', 'РЎРѕР±СЂР°С‚СЊ РІРёР·СѓР°Р»СЊРЅС‹Рµ СЂРµС„РµСЂРµРЅСЃС‹ РґР»СЏ СЃС‹СЂР°, СѓРїР°РєРѕРІРєРё Рё РїСЂРѕРёР·РІРѕРґСЃС‚РІР°', 'medium', 'review', 5, '2026-04-03 18:00:00', NULL, 3),
(4, 1, 5, 2, 5, 'РџСЂРѕРІРµСЃС‚Рё С„РѕС‚РѕСЃСЉРµРјРєСѓ РїСЂРѕРґСѓРєС‚Р°', 'РЎРЅСЏС‚СЊ РїСЂРѕРґСѓРєС‚, СѓРїР°РєРѕРІРєСѓ, РґРµС‚Р°Р»Рё РїСЂРѕРёР·РІРѕРґСЃС‚РІР° Рё РїРѕСЂС‚СЂРµС‚ СЃС‹СЂРѕРІР°СЂР°', 'high', 'new', 8, '2026-04-16 20:00:00', NULL, 2),
(5, 1, 6, 2, 4, 'РЎРѕР±СЂР°С‚СЊ С„РёРЅР°Р»СЊРЅСѓСЋ РїСЂРµР·РµРЅС‚Р°С†РёСЋ', 'РћР±СЉРµРґРёРЅРёС‚СЊ С„РѕС‚Рѕ, РєР»СЋС‡РµРІС‹Рµ СЃРѕРѕР±С‰РµРЅРёСЏ Рё СЃСЃС‹Р»РєРё РЅР° РјР°С‚РµСЂРёР°Р»С‹', 'medium', 'new', 7, '2026-05-27 18:00:00', NULL, 5),
(6, 2, 8, 3, 7, 'РџРѕРґРіРѕС‚РѕРІРёС‚СЊ РєРѕРЅС‚РµРЅС‚-РїР»Р°РЅ Р–Рљ', 'Р Р°Р·СЂР°Р±РѕС‚Р°С‚СЊ СЂСѓР±СЂРёРєРё РЅР° РјРµСЃСЏС†: С…РѕРґ СЃС‚СЂРѕРёС‚РµР»СЊСЃС‚РІР°, РїСЂРµРёРјСѓС‰РµСЃС‚РІР°, РёРїРѕС‚РµРєР°, СЂР°Р№РѕРЅ', 'high', 'done', 10, '2026-03-25 18:00:00', '2026-03-25 17:10:00', 1),
(7, 2, 9, 2, 7, 'РќР°РїРёСЃР°С‚СЊ С‚РµРєСЃС‚С‹ РїРѕСЃС‚РѕРІ Р·Р° Р°РїСЂРµР»СЊ', 'РџРѕРґРіРѕС‚РѕРІРёС‚СЊ С‚РµРєСЃС‚С‹ РґР»СЏ VK Рё Telegram СЃ СЋСЂРёРґРёС‡РµСЃРєРё РєРѕСЂСЂРµРєС‚РЅС‹РјРё С„РѕСЂРјСѓР»РёСЂРѕРІРєР°РјРё', 'medium', 'in_progress', 12, '2026-04-22 18:00:00', NULL, NULL),
(8, 2, 9, 3, 4, 'РЎРґРµР»Р°С‚СЊ РґРёР·Р°Р№РЅ РєСЂРµР°С‚РёРІРѕРІ Р–Рљ', 'РћС„РѕСЂРјРёС‚СЊ СЃРµСЂРёСЋ РїРѕСЃС‚РѕРІ Рё СЃС‚РѕСЂРёСЃ РїРѕ СѓС‚РІРµСЂР¶РґРµРЅРЅРѕР№ СЃРµС‚РєРµ', 'medium', 'revision', 14, '2026-04-24 18:00:00', NULL, 3),
(9, 2, 10, 2, 8, 'РЎРјРѕРЅС‚РёСЂРѕРІР°С‚СЊ СЂРѕР»РёРє Рѕ СЂР°Р№РѕРЅРµ', 'РЎРѕР±СЂР°С‚СЊ РєРѕСЂРѕС‚РєРѕРµ РІРёРґРµРѕ СЃ РїСЂРµРёРјСѓС‰РµСЃС‚РІР°РјРё СЂР°Р№РѕРЅР° Рё РёРЅС„СЂР°СЃС‚СЂСѓРєС‚СѓСЂС‹', 'high', 'review', 9, '2026-04-23 18:00:00', NULL, 4),
(10, 2, 12, 3, 8, 'Р’РЅРµСЃС‚Рё РїСЂР°РІРєРё РїРѕ С‚РёС‚СЂР°Рј', 'РСЃРїСЂР°РІРёС‚СЊ СЋСЂРёРґРёС‡РµСЃРєРёРµ С„РѕСЂРјСѓР»РёСЂРѕРІРєРё Рё РѕР±РЅРѕРІРёС‚СЊ С„РёРЅР°Р»СЊРЅС‹Рµ С‚РёС‚СЂС‹', 'urgent', 'in_progress', 3, '2026-04-19 18:00:00', NULL, 5),
(11, 3, 13, 2, 7, 'Р”РѕСЃРѕР±СЂР°С‚СЊ РґР°РЅРЅС‹Рµ РїРѕ Р°СѓРґРёС‚РѕСЂРёРё', 'РЈС‚РѕС‡РЅРёС‚СЊ СЃРµРіРјРµРЅС‚С‹ Р°СѓРґРёС‚РѕСЂРёРё, Р±РѕР»Рё, РІРѕР·СЂР°Р¶РµРЅРёСЏ Рё С‚РµРјС‹ СЌРєСЃРїРµСЂС‚РЅРѕСЃС‚Рё', 'medium', 'done', 5, '2026-03-22 18:00:00', '2026-03-22 14:00:00', 1),
(12, 3, 16, 3, 7, 'РЎРѕР±СЂР°С‚СЊ РєРѕРЅС‚РµРЅС‚-РїР»Р°РЅ Р»РёС‡РЅРѕРіРѕ Р±СЂРµРЅРґР°', 'РџРѕРґРіРѕС‚РѕРІРёС‚СЊ С‚РµРјС‹ РїРѕСЃС‚РѕРІ, Reels Рё Telegram-Р·Р°РјРµС‚РѕРє РЅР° РјРµСЃСЏС†', 'high', 'in_progress', 12, '2026-04-20 18:00:00', NULL, NULL),
(13, 3, 17, 3, 4, 'РџРѕРґРіРѕС‚РѕРІРёС‚СЊ РІРёР·СѓР°Р»СЊРЅСѓСЋ СЃРµС‚РєСѓ РїСЂРѕС„РёР»СЏ', 'РћС„РѕСЂРјРёС‚СЊ С‡РµСЂРЅРѕРІСѓСЋ СЃРµС‚РєСѓ РёР· 12 РїСѓР±Р»РёРєР°С†РёР№ РґР»СЏ СЃРѕРіР»Р°СЃРѕРІР°РЅРёСЏ', 'medium', 'new', 8, '2026-04-28 18:00:00', NULL, 3),
(14, 4, 20, 2, 6, 'РЎРЅСЏС‚СЊ СЃРµР·РѕРЅРЅРѕРµ РјРµРЅСЋ РєРѕС„РµР№РЅРё', 'РџСЂРѕРІРµСЃС‚Рё РІРµС‡РµСЂРЅСЋСЋ СЃСЉРµРјРєСѓ РЅР°РїРёС‚РєРѕРІ, РґРµСЃРµСЂС‚РѕРІ Рё Р°С‚РјРѕСЃС„РµСЂС‹', 'high', 'done', 8, '2026-03-11 22:00:00', '2026-03-11 21:30:00', 2),
(15, 4, 21, 2, 8, 'РЎРјРѕРЅС‚РёСЂРѕРІР°С‚СЊ 6 СЂРѕР»РёРєРѕРІ РјРµРЅСЋ', 'РџРѕРґРіРѕС‚РѕРІРёС‚СЊ РІРµСЂС‚РёРєР°Р»СЊРЅС‹Рµ СЂРѕР»РёРєРё СЃ РјСѓР·С‹РєРѕР№ Рё С‚РёС‚СЂР°РјРё', 'high', 'done', 18, '2026-04-02 18:00:00', '2026-04-02 16:45:00', 4),
(16, 4, 22, 2, 8, 'РџРµСЂРµРґР°С‚СЊ С„РёРЅР°Р»СЊРЅС‹Рµ СЂРѕР»РёРєРё', 'Р—Р°РіСЂСѓР·РёС‚СЊ С„РёРЅР°Р»СЊРЅС‹Рµ РІРµСЂСЃРёРё Рё РїСЂРѕРІРµСЂРёС‚СЊ РґРѕСЃС‚СѓРї РїРѕ СЃСЃС‹Р»РєР°Рј', 'medium', 'done', 2, '2026-04-18 18:00:00', '2026-04-18 13:00:00', 5),
(17, 5, 24, 2, 2, 'РџСЂРѕРІРµСЃС‚Рё РІСЃС‚СЂРµС‡Сѓ РЅР° РЎРўРћ', 'Р—Р°С„РёРєСЃРёСЂРѕРІР°С‚СЊ Р·РѕРЅС‹ СЃСЉРµРјРєРё, РѕРіСЂР°РЅРёС‡РµРЅРёСЏ Рё РѕС‚РІРµС‚СЃС‚РІРµРЅРЅС‹С… РЅР° РїР»РѕС‰Р°РґРєРµ', 'medium', 'done', 3, '2026-03-18 17:00:00', '2026-03-18 16:20:00', NULL),
(18, 5, 26, 3, 7, 'Р Р°Р·СЂР°Р±РѕС‚Р°С‚СЊ СЂСѓР±СЂРёРєР°С‚РѕСЂ Р°РІС‚РѕСЃРµСЂРІРёСЃР°', 'РЎРѕР±СЂР°С‚СЊ С‚РµРјС‹: РґРёР°РіРЅРѕСЃС‚РёРєР°, С‡РµСЃС‚РЅС‹Рµ РєРµР№СЃС‹, РєРѕРјР°РЅРґР°, СЃРѕРІРµС‚С‹ РІР»Р°РґРµР»СЊС†Р°Рј Р°РІС‚Рѕ', 'high', 'in_progress', 10, '2026-04-21 18:00:00', NULL, NULL),
(19, 5, 27, 2, 5, 'РЎРЅСЏС‚СЊ РєРѕРјР°РЅРґСѓ Рё РїСЂРѕС†РµСЃСЃ РґРёР°РіРЅРѕСЃС‚РёРєРё', 'РџСЂРѕРІРµСЃС‚Рё СЃСЉРµРјРєСѓ РјР°СЃС‚РµСЂРѕРІ, РѕР±РѕСЂСѓРґРѕРІР°РЅРёСЏ Рё РѕР±С‰РёС… РїР»Р°РЅРѕРІ СЃРµСЂРІРёСЃР°', 'medium', 'new', 7, '2026-04-30 18:00:00', NULL, 2),
(20, 5, 27, 3, 4, 'РЎРґРµР»Р°С‚СЊ С€Р°Р±Р»РѕРЅС‹ РїРѕСЃС‚РѕРІ РґР»СЏ РЎРўРћ', 'РџРѕРґРіРѕС‚РѕРІРёС‚СЊ РјР°РєРµС‚С‹ РґР»СЏ РєРµР№СЃРѕРІ СЂРµРјРѕРЅС‚Р° Рё СЌРєСЃРїРµСЂС‚РЅС‹С… СЃРѕРІРµС‚РѕРІ', 'medium', 'new', 8, '2026-05-05 18:00:00', NULL, 3),
(21, 6, 29, 2, 5, 'РЎРЅСЏС‚СЊ РєР°С‚Р°Р»РѕРі СѓРєСЂР°С€РµРЅРёР№', 'РЎРЅСЏС‚СЊ 60 SKU РЅР° СЃРІРµС‚Р»РѕРј С„РѕРЅРµ СЃ РєРѕРЅС‚СЂРѕР»РµРј С†РІРµС‚Р° РјРµС‚Р°Р»Р»Р° Рё РєР°РјРЅРµР№', 'high', 'done', 20, '2026-03-24 18:00:00', '2026-03-24 17:00:00', 2),
(22, 6, 30, 3, 4, 'РџРѕРґРіРѕС‚РѕРІРёС‚СЊ РєР°СЂС‚РѕС‡РєРё С‚РѕРІР°СЂРѕРІ', 'РЎРѕР±СЂР°С‚СЊ РѕР±Р»РѕР¶РєРё Рё СЌРєСЃРїРѕСЂС‚РЅС‹Рµ С„РѕСЂРјР°С‚С‹ РґР»СЏ РјР°СЂРєРµС‚РїР»РµР№СЃРѕРІ', 'medium', 'done', 16, '2026-04-09 18:00:00', '2026-04-09 15:30:00', 3),
(23, 7, 34, 6, 6, 'РЎРѕСЃС‚Р°РІРёС‚СЊ РјР°СЂС€СЂСѓС‚РЅС‹Р№ РїР»Р°РЅ СЃСЉРµРјРѕРє', 'Р Р°Р·Р±РёС‚СЊ РјР°СЂС€СЂСѓС‚С‹ РїРѕ РґРЅСЏРј, С‚РѕС‡РєР°Рј Рё СЂРµР·РµСЂРІРЅС‹Рј РїРѕРіРѕРґРЅС‹Рј РґР°С‚Р°Рј', 'high', 'in_progress', 8, '2026-04-25 18:00:00', NULL, NULL),
(24, 7, 35, 2, 6, 'РџСЂРѕРІРµСЃС‚Рё РІРёРґРµРѕСЃСЉРµРјРєСѓ РјР°СЂС€СЂСѓС‚Р°', 'РЎРЅСЏС‚СЊ РіСЂСѓРїРїСѓ, РїРµР№Р·Р°Р¶Рё, С‚СЂР°РЅСЃРїРѕСЂС‚, РіРёРґРѕРІ Рё СЌРјРѕС†РёРѕРЅР°Р»СЊРЅС‹Рµ РјРѕРјРµРЅС‚С‹', 'high', 'new', 16, '2026-05-20 20:00:00', NULL, 2),
(25, 8, 37, 3, 4, 'РЎРѕР±СЂР°С‚СЊ РІР°СЂРёР°РЅС‚С‹ РІРёР·СѓР°Р»СЊРЅРѕР№ РєРѕРЅС†РµРїС†РёРё', 'РџРѕРґРіРѕС‚РѕРІРёС‚СЊ 3 РЅР°РїСЂР°РІР»РµРЅРёСЏ Р°С„РёС€РЅРѕР№ РіСЂР°С„РёРєРё Рё С€Р°Р±Р»РѕРЅРѕРІ', 'high', 'in_progress', 14, '2026-04-22 18:00:00', NULL, 3),
(26, 9, 41, 2, 7, 'РџСЂРѕРІРµСЃС‚Рё СЃС‚Р°СЂС‚РѕРІСѓСЋ РїР»Р°РЅРµСЂРєСѓ', 'РќР°Р·РЅР°С‡РёС‚СЊ СЃСЉРµРјРѕС‡РЅС‹Рµ РґРЅРё, РїСѓР±Р»РёРєР°С†РёРё Рё Р·РѕРЅС‹ РѕС‚РІРµС‚СЃС‚РІРµРЅРЅРѕСЃС‚Рё', 'medium', 'in_progress', 2, '2026-04-19 12:00:00', NULL, NULL),
(27, 9, 42, 7, 7, 'РЎРѕР±СЂР°С‚СЊ РєРѕРЅС‚РµРЅС‚-СЃРµС‚РєСѓ С„РёС‚РЅРµСЃ-РєР»СѓР±Р°', 'РџРѕРґРіРѕС‚РѕРІРёС‚СЊ С‚РµРјС‹ РїРѕСЃС‚РѕРІ, СЃС‚РѕСЂРёСЃ, Reels Рё Р°РєС†РёРё РЅР° РјРµСЃСЏС†', 'high', 'new', 10, '2026-04-25 18:00:00', NULL, NULL),
(28, 10, 44, 2, 8, 'РЎРјРѕРЅС‚РёСЂРѕРІР°С‚СЊ С„СЂР°РіРјРµРЅС‚С‹ СѓСЂРѕРєРѕРІ', 'РЎРѕР±СЂР°С‚СЊ СѓС‡РµР±РЅС‹Рµ РІРёРґРµРѕ, Р·Р°СЃС‚Р°РІРєРё, С‚РёС‚СЂС‹ Рё СЌРєСЃРїРѕСЂС‚ РІ LMS', 'high', 'done', 22, '2026-04-04 18:00:00', '2026-04-04 17:20:00', 4),
(29, 10, 46, 1, 2, 'РџРѕРґРіРѕС‚РѕРІРёС‚СЊ Р·Р°РєСЂС‹РІР°СЋС‰РёР№ РѕС‚С‡РµС‚', 'РЎРѕР±СЂР°С‚СЊ РѕС‚С‡РµС‚ РїРѕ РјР°С‚РµСЂРёР°Р»Р°Рј, СЃСЃС‹Р»РєР°Рј, РѕРїР»Р°С‚Р°Рј Рё СЂРµРєРѕРјРµРЅРґР°С†РёСЏРј', 'medium', 'done', 4, '2026-04-14 18:00:00', '2026-04-14 15:10:00', 5);

INSERT INTO task_checklist_status (
    task_checklist_status_id, task_id, checklist_item_id, checked_by, is_done, checked_at, comment
) VALUES
(1, 1, 1, 2, TRUE, '2026-03-07 12:00:00', 'Р¦РµР»СЊ Р·Р°РїСѓСЃРєР° РїРѕРґС‚РІРµСЂР¶РґРµРЅР°'),
(2, 1, 2, 7, TRUE, '2026-03-07 12:20:00', 'РЎРµРіРјРµРЅС‚С‹ Р°СѓРґРёС‚РѕСЂРёРё Р·Р°РїРёСЃР°РЅС‹'),
(3, 1, 3, 7, TRUE, '2026-03-07 12:40:00', 'РџР»РѕС‰Р°РґРєРё СѓРєР°Р·Р°РЅС‹'),
(4, 1, 4, 2, TRUE, '2026-03-07 13:00:00', 'РћРіСЂР°РЅРёС‡РµРЅРёСЏ РїРѕ РїСЂРѕРёР·РІРѕРґСЃС‚РІСѓ Р·Р°С„РёРєСЃРёСЂРѕРІР°РЅС‹'),
(5, 2, 5, 5, TRUE, '2026-03-29 10:00:00', 'Р”Р°С‚Р° СЃРѕРіР»Р°СЃРѕРІР°РЅР° РїСЂРµРґРІР°СЂРёС‚РµР»СЊРЅРѕ'),
(6, 2, 6, 3, TRUE, '2026-03-30 11:30:00', 'РЎСЉРµРјРѕС‡РЅС‹Р№ РїР»Р°РЅ РІ С‡РµСЂРЅРѕРІРёРєРµ'),
(7, 2, 7, NULL, FALSE, NULL, 'РћР¶РёРґР°РµС‚СЃСЏ СЃРїРёСЃРѕРє СЂРµРєРІРёР·РёС‚Р°'),
(8, 2, 8, NULL, FALSE, NULL, 'РСЃС…РѕРґРЅРёРєРѕРІ РµС‰Рµ РЅРµС‚'),
(9, 5, 17, NULL, FALSE, NULL, 'Р¤РёРЅР°Р»С‹ Р±СѓРґСѓС‚ РїРѕСЃР»Рµ РїРѕСЃС‚РїСЂРѕРґР°РєС€РЅР°'),
(10, 5, 18, NULL, FALSE, NULL, 'РЎСЃС‹Р»РєРё РµС‰Рµ РЅРµ СЃС„РѕСЂРјРёСЂРѕРІР°РЅС‹'),
(11, 5, 19, NULL, FALSE, NULL, 'РћР±СЂР°С‚РЅР°СЏ СЃРІСЏР·СЊ РїРѕСЏРІРёС‚СЃСЏ РїРѕСЃР»Рµ РѕС‚РїСЂР°РІРєРё'),
(12, 5, 20, NULL, FALSE, NULL, 'Р¤РёРЅР°Р»СЊРЅР°СЏ РѕРїР»Р°С‚Р° РЅРµ РЅР°СЃС‚СѓРїРёР»Р°'),
(13, 8, 9, 3, TRUE, '2026-04-17 14:00:00', 'РЎС‚РёР»СЊ СЃРѕРѕС‚РІРµС‚СЃС‚РІСѓРµС‚ СЃРµС‚РєРµ Р–Рљ'),
(14, 8, 10, 7, TRUE, '2026-04-17 14:20:00', 'РўРµРєСЃС‚ РІС‹С‡РёС‚Р°РЅ'),
(15, 8, 11, 4, FALSE, NULL, 'РќСѓР¶РЅРѕ РґРѕР±Р°РІРёС‚СЊ С„РѕСЂРјР°С‚ РґР»СЏ СЃС‚РѕСЂРёСЃ'),
(16, 8, 12, 4, FALSE, NULL, 'Р­РєСЃРїРѕСЂС‚ РїРѕСЃР»Рµ РїСЂР°РІРѕРє'),
(17, 9, 13, 8, TRUE, '2026-04-16 10:00:00', 'РСЃС…РѕРґРЅРёРєРё РїРѕР»СѓС‡РµРЅС‹'),
(18, 9, 14, 8, TRUE, '2026-04-18 16:00:00', 'Р§РµСЂРЅРѕРІРѕР№ РјРѕРЅС‚Р°Р¶ РіРѕС‚РѕРІ'),
(19, 9, 15, NULL, FALSE, NULL, 'РћР¶РёРґР°РµС‚СЃСЏ РїСЂРѕРІРµСЂРєР° Р·РІСѓРєР°'),
(20, 9, 16, NULL, FALSE, NULL, 'Р­РєСЃРїРѕСЂС‚ РїРѕСЃР»Рµ РїСЂР°РІРѕРє'),
(21, 14, 5, 6, TRUE, '2026-03-06 12:00:00', 'Р”Р°С‚Р° Рё РјРµСЃС‚Рѕ РїРѕРґС‚РІРµСЂР¶РґРµРЅС‹'),
(22, 14, 6, 3, TRUE, '2026-03-06 12:20:00', 'РџР»Р°РЅ СЃСЉРµРјРєРё СѓС‚РІРµСЂР¶РґРµРЅ'),
(23, 14, 7, 6, TRUE, '2026-03-11 18:00:00', 'РЎРІРµС‚ Рё СЂРµРєРІРёР·РёС‚ РіРѕС‚РѕРІС‹'),
(24, 14, 8, 6, TRUE, '2026-03-12 10:00:00', 'РСЃС…РѕРґРЅРёРєРё Р·Р°РіСЂСѓР¶РµРЅС‹'),
(25, 15, 13, 8, TRUE, '2026-03-13 10:00:00', 'РСЃС…РѕРґРЅРёРєРё РїСЂРёРЅСЏС‚С‹'),
(26, 15, 14, 8, TRUE, '2026-03-26 17:00:00', 'РњРѕРЅС‚Р°Р¶ РїРѕ СЃС†РµРЅР°СЂРёСЋ'),
(27, 15, 15, 8, TRUE, '2026-04-01 16:00:00', 'Р—РІСѓРє Рё С†РІРµС‚ РїСЂРѕРІРµСЂРµРЅС‹'),
(28, 15, 16, 8, TRUE, '2026-04-02 16:00:00', 'Р­РєСЃРїРѕСЂС‚ СЃРґРµР»Р°РЅ'),
(29, 16, 17, 8, TRUE, '2026-04-18 12:00:00', 'Р¤РёРЅР°Р»С‹ Р·Р°РіСЂСѓР¶РµРЅС‹'),
(30, 16, 18, 2, TRUE, '2026-04-18 12:20:00', 'Р”РѕСЃС‚СѓРї РїСЂРѕРІРµСЂРµРЅ'),
(31, 16, 19, 2, TRUE, '2026-04-18 12:40:00', 'РљР»РёРµРЅС‚ РїРѕРґС‚РІРµСЂРґРёР»'),
(32, 16, 20, 1, TRUE, '2026-04-18 13:00:00', 'РћРїР»Р°С‚Р° РѕС‚РјРµС‡РµРЅР°'),
(33, 21, 5, 5, TRUE, '2026-03-05 09:00:00', 'РЎС‚СѓРґРёСЏ РїРѕРґС‚РІРµСЂР¶РґРµРЅР°'),
(34, 21, 6, 5, TRUE, '2026-03-05 09:10:00', 'РџР»Р°РЅ SKU СѓС‚РІРµСЂР¶РґРµРЅ'),
(35, 21, 7, 5, TRUE, '2026-03-05 09:20:00', 'Р¤РѕРЅС‹ Рё СЂРµРєРІРёР·РёС‚ РіРѕС‚РѕРІС‹'),
(36, 21, 8, 5, TRUE, '2026-03-24 17:30:00', 'РСЃС…РѕРґРЅРёРєРё РІ РїР°РїРєРµ'),
(37, 22, 9, 3, TRUE, '2026-04-04 11:00:00', 'РЎС‚РёР»СЊ СѓС‚РІРµСЂР¶РґРµРЅ'),
(38, 22, 10, 4, TRUE, '2026-04-04 11:20:00', 'РќР°Р·РІР°РЅРёСЏ РїСЂРѕРІРµСЂРµРЅС‹'),
(39, 22, 11, 4, TRUE, '2026-04-08 14:00:00', 'Р¤РѕСЂРјР°С‚С‹ РїРѕРґС…РѕРґСЏС‚'),
(40, 22, 12, 4, TRUE, '2026-04-09 15:00:00', 'Р­РєСЃРїРѕСЂС‚ РіРѕС‚РѕРІ'),
(41, 28, 13, 8, TRUE, '2026-03-16 10:00:00', 'РСЃС…РѕРґРЅРёРєРё РєСѓСЂСЃР° РїРѕР»СѓС‡РµРЅС‹'),
(42, 28, 14, 8, TRUE, '2026-03-28 18:00:00', 'РњРѕРЅС‚Р°Р¶ СЃРѕРѕС‚РІРµС‚СЃС‚РІСѓРµС‚ СЃС†РµРЅР°СЂРёСЏРј'),
(43, 28, 15, 8, TRUE, '2026-04-03 12:00:00', 'Р—РІСѓРє Рё С‚РёС‚СЂС‹ РїСЂРѕРІРµСЂРµРЅС‹'),
(44, 28, 16, 8, TRUE, '2026-04-04 17:00:00', 'Р­РєСЃРїРѕСЂС‚ РІ LMS РіРѕС‚РѕРІ'),
(45, 29, 17, 2, TRUE, '2026-04-14 12:00:00', 'РњР°С‚РµСЂРёР°Р»С‹ РїРµСЂРµРґР°РЅС‹'),
(46, 29, 18, 2, TRUE, '2026-04-14 12:30:00', 'РЎСЃС‹Р»РєРё РїСЂРѕРІРµСЂРµРЅС‹'),
(47, 29, 19, 2, TRUE, '2026-04-14 13:00:00', 'РџРѕСЃС‚Р±СЂРёС„ Р·Р°С„РёРєСЃРёСЂРѕРІР°РЅ'),
(48, 29, 20, 1, TRUE, '2026-04-14 15:00:00', 'Р—Р°РєСЂС‹С‚РёРµ РїРѕРґС‚РІРµСЂР¶РґРµРЅРѕ');

COMMIT;

-- END 02_seed_03_tasks_checklists.sql


-- BEGIN 02_seed_04_finance_materials.sql

-- РўРµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ: РІСЃС‚СЂРµС‡Рё, РѕРїР»Р°С‚С‹, РІС‹РїР»Р°С‚С‹, РІРµСЂСЃРёРё РјР°С‚РµСЂРёР°Р»РѕРІ Рё СЃСЃС‹Р»РєРё
-- Р—Р°РїСѓСЃРєР°С‚СЊ РїРѕСЃР»Рµ 02_seed_03_tasks_checklists.sql

BEGIN;

INSERT INTO meetings (
    meeting_id, project_id, meeting_type, meeting_at, format, location_or_link, organizer_id, status, notes
) VALUES
(1, 1, 'primary_call', '2026-03-04 11:00:00', 'online', 'https://meet.example.com/baikalfood-intro', 2, 'completed', 'РџРµСЂРІРёС‡РЅС‹Р№ СЃРѕР·РІРѕРЅ, РїРѕРґС‚РІРµСЂР¶РґРµРЅ РёРЅС‚РµСЂРµСЃ'),
(2, 1, 'briefing', '2026-03-05 15:00:00', 'online', 'https://meet.example.com/baikalfood-brief', 2, 'completed', 'Р—Р°РїРѕР»РЅРµРЅ РѕСЃРЅРѕРІРЅРѕР№ Р±СЂРёС„'),
(3, 1, 'shooting', '2026-04-12 10:00:00', 'offline', 'РСЂРєСѓС‚СЃРєР°СЏ РѕР±Р»Р°СЃС‚СЊ, СЃС‹СЂРѕРІР°СЂРЅСЏ РєР»РёРµРЅС‚Р°', 5, 'planned', 'РЎСЉРµРјРєР° РїСЂРѕРґСѓРєС‚Р° Рё РїСЂРѕРёР·РІРѕРґСЃС‚РІР°'),
(4, 2, 'planning', '2026-03-18 10:00:00', 'online', 'https://meet.example.com/angara-plan', 2, 'completed', 'РџР»Р°РЅ СЂР°Р±РѕС‚ РЅР° РїРµСЂРІС‹Р№ РјРµСЃСЏС†'),
(5, 2, 'review', '2026-04-17 16:00:00', 'online', 'https://meet.example.com/angara-review', 3, 'completed', 'РџСЂР°РІРєРё РїРѕ РєСЂРµР°С‚РёРІР°Рј Рё С‚РёС‚СЂР°Рј'),
(6, 3, 'briefing', '2026-03-20 14:00:00', 'online', 'https://meet.example.com/morozova-brief', 7, 'completed', 'РћР±СЃСѓР¶РґРµРЅС‹ С‚РµРјС‹ СЌРєСЃРїРµСЂС‚РЅРѕСЃС‚Рё'),
(7, 4, 'shooting', '2026-03-11 18:30:00', 'offline', 'РљРѕС„РµР№РЅСЏ "РЎРµРІРµСЂРЅРѕРµ Р·РµСЂРЅРѕ"', 6, 'completed', 'РЎСЉРµРјРєР° РїСЂРѕС€Р»Р° РїРѕСЃР»Рµ Р·Р°РєСЂС‹С‚РёСЏ РєРѕС„РµР№РЅРё'),
(8, 5, 'meeting', '2026-03-18 15:00:00', 'offline', 'РЎРўРћ "РњРѕС‚РѕСЂРёРєР°"', 2, 'completed', 'РћСЃРјРѕС‚СЂ РїР»РѕС‰Р°РґРєРё Рё РѕРіСЂР°РЅРёС‡РµРЅРёР№'),
(9, 6, 'review', '2026-04-09 12:00:00', 'online', 'https://meet.example.com/vetrova-catalog', 3, 'completed', 'РљР°С‚Р°Р»РѕРі РїСЂРёРЅСЏС‚ СЃ РјРµР»РєРёРјРё Р·Р°РјРµС‡Р°РЅРёСЏРјРё'),
(10, 7, 'planning', '2026-04-18 13:00:00', 'online', 'https://meet.example.com/baikaltravel-route', 6, 'planned', 'РџР»Р°РЅРёСЂРѕРІР°РЅРёРµ РјР°СЂС€СЂСѓС‚РѕРІ Рё СЂРµР·РµСЂРІРЅС‹С… РґР°С‚'),
(11, 8, 'meeting', '2026-04-22 17:00:00', 'hybrid', 'РљСѓР»СЊС‚СѓСЂРЅС‹Р№ С†РµРЅС‚СЂ "РђСЂРєР°" Рё https://meet.example.com/arka-board', 3, 'planned', 'РџСЂРµР·РµРЅС‚Р°С†РёСЏ РєРѕРЅС†РµРїС†РёР№ СЃРѕРІРµС‚Сѓ'),
(12, 10, 'postbrief', '2026-04-12 16:00:00', 'online', 'https://meet.example.com/northstar-postbrief', 2, 'completed', 'РЎРѕР±СЂР°РЅР° РѕР±СЂР°С‚РЅР°СЏ СЃРІСЏР·СЊ РїРѕ РєСѓСЂСЃСѓ');

INSERT INTO payments (payment_id, project_id, payment_type, amount, payment_date, status, comment) VALUES
(1, 1, 'prepayment', 210000, '2026-03-12', 'paid', '50% РїСЂРµРґРѕРїР»Р°С‚Р° РїРѕСЃР»Рµ СѓС‚РІРµСЂР¶РґРµРЅРёСЏ СЃРјРµС‚С‹'),
(2, 1, 'final', 210000, NULL, 'planned', 'Р¤РёРЅР°Р»СЊРЅР°СЏ РѕРїР»Р°С‚Р° РїРѕСЃР»Рµ СЃРґР°С‡Рё РјР°С‚РµСЂРёР°Р»РѕРІ'),
(3, 2, 'prepayment', 300000, '2026-03-14', 'paid', 'РЎС‚Р°СЂС‚ Р°Р±РѕРЅРµРЅС‚СЃРєРѕРіРѕ СЃРѕРїСЂРѕРІРѕР¶РґРµРЅРёСЏ'),
(4, 2, 'intermediate', 175000, '2026-04-15', 'paid', 'РћРїР»Р°С‚Р° РІС‚РѕСЂРѕРіРѕ РјРµСЃСЏС†Р°'),
(5, 2, 'final', 175000, NULL, 'invoiced', 'Р¤РёРЅР°Р»СЊРЅС‹Р№ СЃС‡РµС‚ РІС‹СЃС‚Р°РІР»РµРЅ'),
(6, 3, 'prepayment', 140000, '2026-03-21', 'paid', 'РџСЂРµРґРѕРїР»Р°С‚Р° РїСЂРѕРµРєС‚Р°'),
(7, 3, 'final', 140000, NULL, 'planned', 'РћРїР»Р°С‚Р° РїРѕСЃР»Рµ СѓС‚РІРµСЂР¶РґРµРЅРёСЏ РІРёР·СѓР°Р»Р°'),
(8, 4, 'prepayment', 90000, '2026-02-26', 'paid', 'РџСЂРµРґРѕРїР»Р°С‚Р° 50%'),
(9, 4, 'final', 90000, '2026-04-18', 'paid', 'РћРїР»Р°С‡РµРЅРѕ РїРѕСЃР»Рµ РїРµСЂРµРґР°С‡Рё СЂРѕР»РёРєРѕРІ'),
(10, 5, 'prepayment', 170000, '2026-03-23', 'paid', 'РџСЂРµРґРѕРїР»Р°С‚Р° Р°Р±РѕРЅРµРЅС‚СЃРєРѕРіРѕ РїРµСЂРёРѕРґР°'),
(11, 5, 'final', 170000, NULL, 'planned', 'РћРїР»Р°С‚Р° РїРѕСЃР»Рµ РѕС‚С‡РµС‚РЅРѕРіРѕ РїРµСЂРёРѕРґР°'),
(12, 6, 'prepayment', 110000, '2026-03-02', 'paid', 'РџСЂРµРґРѕРїР»Р°С‚Р° РєР°С‚Р°Р»РѕРіР°'),
(13, 6, 'final', 110000, '2026-04-26', 'paid', 'Р¤РёРЅР°Р»СЊРЅР°СЏ РѕРїР»Р°С‚Р° РїРѕР»СѓС‡РµРЅР°'),
(14, 7, 'prepayment', 260000, NULL, 'invoiced', 'РЎС‡РµС‚ РЅР° РїСЂРµРґРѕРїР»Р°С‚Сѓ РѕС‚РїСЂР°РІР»РµРЅ'),
(15, 8, 'prepayment', 150000, NULL, 'planned', 'Р‘СѓРґРµС‚ РІС‹СЃС‚Р°РІР»РµРЅ РїРѕСЃР»Рµ СЃРѕРіР»Р°СЃРѕРІР°РЅРёСЏ СѓСЃР»РѕРІРёР№'),
(16, 9, 'prepayment', 180000, '2026-04-12', 'paid', 'РџСЂРµРґРѕРїР»Р°С‚Р° РїРµСЂРІРѕРіРѕ РјРµСЃСЏС†Р°'),
(17, 10, 'prepayment', 120000, '2026-02-12', 'paid', 'РџСЂРµРґРѕРїР»Р°С‚Р° СѓРїР°РєРѕРІРєРё РєСѓСЂСЃР°'),
(18, 10, 'final', 120000, '2026-04-14', 'paid', 'Р¤РёРЅР°Р»СЊРЅР°СЏ РѕРїР»Р°С‚Р° Рё Р·Р°РєСЂС‹С‚РёРµ');

INSERT INTO employee_payouts (
    payout_id, project_id, employee_id, payout_type, salary_period,
    fixed_part, percent_part, gross_amount, tax_amount, net_amount, payout_date, comment
) VALUES
(1, 1, 3, 'mixed', '2026-03-01', 30000, 10500, 40500, 5265, 35235, '2026-03-31', 'РљСЂРµР°С‚РёРІРЅР°СЏ СЃС‚СЂР°С‚РµРіРёСЏ Р·Р°РїСѓСЃРєР°'),
(2, 1, 5, 'mixed', '2026-04-01', 25000, 7000, 32000, 4160, 27840, NULL, 'РџРѕРґРіРѕС‚РѕРІРєР° Рё СЃСЉРµРјРѕС‡РЅС‹Р№ СЌС‚Р°Рї'),
(3, 2, 7, 'mixed', '2026-03-01', 28000, 9750, 37750, 4907.50, 32842.50, '2026-03-31', 'РљРѕРЅС‚РµРЅС‚-РїР»Р°РЅ Рё С‚РµРєСЃС‚С‹ Р–Рљ'),
(4, 2, 4, 'mixed', '2026-04-01', 26000, 9750, 35750, 4647.50, 31102.50, NULL, 'Р”РёР·Р°Р№РЅ РєСЂРµР°С‚РёРІРѕРІ Р–Рљ'),
(5, 2, 8, 'mixed', '2026-04-01', 26000, 8450, 34450, 4478.50, 29971.50, NULL, 'РњРѕРЅС‚Р°Р¶ РІРёРґРµРѕ РїРѕ Р–Рљ'),
(6, 3, 7, 'mixed', '2026-04-01', 25000, 4200, 29200, 3796, 25404, NULL, 'РљРѕРЅС‚РµРЅС‚-РїР»Р°РЅ Р»РёС‡РЅРѕРіРѕ Р±СЂРµРЅРґР°'),
(7, 4, 6, 'mixed', '2026-03-01', 22000, 2160, 24160, 3140.80, 21019.20, '2026-04-05', 'Р’РёРґРµРѕСЃСЉРµРјРєР° РєРѕС„РµР№РЅРё'),
(8, 4, 8, 'mixed', '2026-04-01', 24000, 2340, 26340, 3424.20, 22915.80, '2026-04-18', 'РњРѕРЅС‚Р°Р¶ СЂРѕР»РёРєРѕРІ РєРѕС„РµР№РЅРё'),
(9, 5, 4, 'mixed', '2026-04-01', 24000, 5100, 29100, 3783, 25317, NULL, 'РЁР°Р±Р»РѕРЅС‹ Р°РІС‚РѕСЃРµСЂРІРёСЃР°'),
(10, 6, 5, 'mixed', '2026-03-01', 30000, 2200, 32200, 4186, 28014, '2026-04-01', 'РџСЂРµРґРјРµС‚РЅР°СЏ СЃСЉРµРјРєР° СѓРєСЂР°С€РµРЅРёР№'),
(11, 6, 4, 'mixed', '2026-04-01', 23000, 3300, 26300, 3419, 22881, '2026-04-26', 'РљР°СЂС‚РѕС‡РєРё С‚РѕРІР°СЂРѕРІ'),
(12, 10, 8, 'mixed', '2026-04-01', 30000, 3120, 33120, 4305.60, 28814.40, '2026-04-14', 'РњРѕРЅС‚Р°Р¶ РєСѓСЂСЃР° Р°РЅРіР»РёР№СЃРєРѕРіРѕ');

INSERT INTO project_versions (
    version_id, project_id, stage_id, version_number, uploaded_by, description,
    sent_to_client_at, is_approved, client_feedback, created_at
) VALUES
(1, 1, 4, 1, 3, 'Moodboard Р·Р°РїСѓСЃРєР° Р»РёРЅРµР№РєРё СЃС‹СЂРѕРІ v1', '2026-04-03 12:00:00', FALSE, 'Р”РѕР±Р°РІРёС‚СЊ Р±РѕР»СЊС€Рµ Р»РѕРєР°Р»СЊРЅРѕРіРѕ С…Р°СЂР°РєС‚РµСЂР° Рё РјРµРЅСЊС€Рµ СЃС‚СѓРґРёР№РЅРѕСЃС‚Рё', '2026-04-03 10:30:00'),
(2, 1, 4, 2, 3, 'Moodboard Р·Р°РїСѓСЃРєР° Р»РёРЅРµР№РєРё СЃС‹СЂРѕРІ v2', '2026-04-07 15:00:00', TRUE, 'РљРѕРЅС†РµРїС†РёСЏ СѓС‚РІРµСЂР¶РґРµРЅР°', '2026-04-07 13:20:00'),
(3, 2, 8, 1, 7, 'РљРѕРЅС‚РµРЅС‚-РїР»Р°РЅ Р–Рљ РЅР° Р°РїСЂРµР»СЊ v1', '2026-03-24 16:00:00', FALSE, 'РќСѓР¶РЅРѕ СѓСЃРёР»РёС‚СЊ РёРїРѕС‚РµС‡РЅС‹Р№ Р±Р»РѕРє', '2026-03-24 14:10:00'),
(4, 2, 8, 2, 7, 'РљРѕРЅС‚РµРЅС‚-РїР»Р°РЅ Р–Рљ РЅР° Р°РїСЂРµР»СЊ v2', '2026-03-25 17:00:00', TRUE, 'РЈС‚РІРµСЂР¶РґРµРЅРѕ', '2026-03-25 15:40:00'),
(5, 2, 10, 1, 8, 'Р РѕР»РёРє Рѕ СЂР°Р№РѕРЅРµ v1', '2026-04-18 17:30:00', FALSE, 'РСЃРїСЂР°РІРёС‚СЊ С‚РёС‚СЂС‹ Рё СЃРѕРєСЂР°С‚РёС‚СЊ РЅР°С‡Р°Р»Рѕ', '2026-04-18 15:50:00'),
(6, 2, 12, 2, 8, 'Р РѕР»РёРє Рѕ СЂР°Р№РѕРЅРµ v2 СЃ РїСЂР°РІРєР°РјРё', '2026-04-20 11:00:00', FALSE, 'РћР¶РёРґР°РµС‚СЃСЏ РїРѕРІС‚РѕСЂРЅР°СЏ РїСЂРѕРІРµСЂРєР°', '2026-04-20 10:10:00'),
(7, 3, 16, 1, 7, 'РљРѕРЅС‚РµРЅС‚-РїР»Р°РЅ Р»РёС‡РЅРѕРіРѕ Р±СЂРµРЅРґР° v1', '2026-04-16 13:00:00', FALSE, 'РЎР»РёС€РєРѕРј РјРЅРѕРіРѕ СЌРєСЃРїРµСЂС‚РЅС‹С… С‚РµСЂРјРёРЅРѕРІ', '2026-04-16 11:20:00'),
(8, 4, 21, 1, 8, 'Р РѕР»РёРєРё СЃРµР·РѕРЅРЅРѕРіРѕ РјРµРЅСЋ v1', '2026-03-28 18:00:00', FALSE, 'Р—Р°РјРµРЅРёС‚СЊ РјСѓР·С‹РєСѓ РІ РґРІСѓС… СЂРѕР»РёРєР°С…', '2026-03-28 16:00:00'),
(9, 4, 21, 2, 8, 'Р РѕР»РёРєРё СЃРµР·РѕРЅРЅРѕРіРѕ РјРµРЅСЋ v2', '2026-04-02 17:00:00', TRUE, 'РЈС‚РІРµСЂР¶РґРµРЅРѕ Р±РµР· РґРѕРїРѕР»РЅРёС‚РµР»СЊРЅС‹С… РїСЂР°РІРѕРє', '2026-04-02 16:20:00'),
(10, 5, 26, 1, 7, 'Р СѓР±СЂРёРєР°С‚РѕСЂ Р°РІС‚РѕСЃРµСЂРІРёСЃР° v1', '2026-04-12 12:00:00', FALSE, 'Р”РѕР±Р°РІРёС‚СЊ Р±Р»РѕРє РїСЂРѕ РіР°СЂР°РЅС‚РёРё', '2026-04-12 10:00:00'),
(11, 6, 30, 1, 4, 'РљР°С‚Р°Р»РѕРі СѓРєСЂР°С€РµРЅРёР№ v1', '2026-04-05 14:00:00', FALSE, 'РџСЂРѕРІРµСЂРёС‚СЊ РѕС‚С‚РµРЅРѕРє СЃРµСЂРµР±СЂР° РЅР° 8 РїРѕР·РёС†РёСЏС…', '2026-04-05 12:30:00'),
(12, 6, 30, 2, 4, 'РљР°С‚Р°Р»РѕРі СѓРєСЂР°С€РµРЅРёР№ v2', '2026-04-09 16:00:00', TRUE, 'РљР°С‚Р°Р»РѕРі РїСЂРёРЅСЏС‚', '2026-04-09 15:15:00'),
(13, 8, 37, 1, 4, 'Р’Р°СЂРёР°РЅС‚С‹ РєРѕРЅС†РµРїС†РёРё РєСѓР»СЊС‚СѓСЂРЅРѕРіРѕ С†РµРЅС‚СЂР° v1', '2026-04-18 15:00:00', FALSE, 'РћР¶РёРґР°РµС‚ РѕР±СЃСѓР¶РґРµРЅРёСЏ СЃ СЃРѕРІРµС‚РѕРј', '2026-04-18 13:00:00'),
(14, 10, 45, 1, 8, 'Р¤РёРЅР°Р»СЊРЅС‹Рµ СѓСЂРѕРєРё РєСѓСЂСЃР° v1', '2026-04-04 18:00:00', TRUE, 'Р’РёРґРµРѕ РїСЂРёРЅСЏС‚С‹', '2026-04-04 17:30:00'),
(15, 10, 46, 1, 2, 'Р—Р°РєСЂС‹РІР°СЋС‰РёР№ РѕС‚С‡РµС‚ РїРѕ РєСѓСЂСЃСѓ', '2026-04-14 15:00:00', TRUE, 'РћС‚С‡РµС‚ РїСЂРёРЅСЏС‚', '2026-04-14 14:30:00');

INSERT INTO project_links (
    link_id, project_id, stage_id, version_id, link_type, link_url, description, added_by, added_at
) VALUES
(1, 1, 3, NULL, 'brief', 'https://drive.example.com/baikalfood/brief', 'Р‘СЂРёС„ РїСЂРѕРµРєС‚Р° Р‘Р°Р№РєР°Р»Р¤СѓРґ', 2, '2026-03-07 16:40:00'),
(2, 1, 4, 2, 'reference', 'https://drive.example.com/baikalfood/moodboard-v2', 'РЈС‚РІРµСЂР¶РґРµРЅРЅС‹Р№ moodboard', 3, '2026-04-07 13:30:00'),
(3, 1, 5, NULL, 'drive_folder', 'https://drive.example.com/baikalfood/production', 'Р Р°Р±РѕС‡Р°СЏ РїР°РїРєР° СЃСЉРµРјРѕС‡РЅРѕРіРѕ СЌС‚Р°РїР°', 5, '2026-04-08 10:00:00'),
(4, 2, 8, 4, 'work_file', 'https://docs.example.com/angara/content-plan-april-v2', 'РљРѕРЅС‚РµРЅС‚-РїР»Р°РЅ Р–Рљ РЅР° Р°РїСЂРµР»СЊ', 7, '2026-03-25 16:00:00'),
(5, 2, 10, 5, 'work_file', 'https://drive.example.com/angara/video-district-v1', 'Р§РµСЂРЅРѕРІРѕР№ СЂРѕР»РёРє Рѕ СЂР°Р№РѕРЅРµ', 8, '2026-04-18 16:00:00'),
(6, 2, 12, 6, 'work_file', 'https://drive.example.com/angara/video-district-v2', 'Р’РµСЂСЃРёСЏ СЂРѕР»РёРєР° СЃ РїСЂР°РІРєР°РјРё', 8, '2026-04-20 10:30:00'),
(7, 3, 16, 7, 'work_file', 'https://docs.example.com/morozova/content-plan-v1', 'РљРѕРЅС‚РµРЅС‚-РїР»Р°РЅ Р»РёС‡РЅРѕРіРѕ Р±СЂРµРЅРґР°', 7, '2026-04-16 11:30:00'),
(8, 4, 20, NULL, 'source_files', 'https://drive.example.com/coffee/source', 'РСЃС…РѕРґРЅРёРєРё СЃСЉРµРјРєРё РєРѕС„РµР№РЅРё', 6, '2026-03-12 10:10:00'),
(9, 4, 21, 9, 'final_material', 'https://drive.example.com/coffee/final-reels', 'Р¤РёРЅР°Р»СЊРЅС‹Рµ СЂРѕР»РёРєРё РєРѕС„РµР№РЅРё', 8, '2026-04-02 16:40:00'),
(10, 5, 25, NULL, 'brief', 'https://drive.example.com/motorika/brief', 'Р‘СЂРёС„ Р°РІС‚РѕСЃРµСЂРІРёСЃР°', 2, '2026-03-20 17:00:00'),
(11, 5, 26, 10, 'work_file', 'https://docs.example.com/motorika/rubricator-v1', 'Р СѓР±СЂРёРєР°С‚РѕСЂ Р°РІС‚РѕСЃРµСЂРІРёСЃР°', 7, '2026-04-12 10:20:00'),
(12, 6, 29, NULL, 'source_files', 'https://drive.example.com/vetrova/source-photo', 'РСЃС…РѕРґРЅРёРєРё РїСЂРµРґРјРµС‚РЅРѕР№ СЃСЉРµРјРєРё', 5, '2026-03-24 17:40:00'),
(13, 6, 30, 12, 'final_material', 'https://drive.example.com/vetrova/catalog-final', 'Р¤РёРЅР°Р»СЊРЅС‹Р№ РєР°С‚Р°Р»РѕРі СѓРєСЂР°С€РµРЅРёР№', 4, '2026-04-09 15:40:00'),
(14, 7, 34, NULL, 'work_file', 'https://docs.example.com/baikaltravel/route-plan', 'РњР°СЂС€СЂСѓС‚РЅС‹Р№ РїР»Р°РЅ СЃСЉРµРјРѕРє', 6, '2026-04-18 12:00:00'),
(15, 8, 37, 13, 'reference', 'https://drive.example.com/arka/concept-v1', 'РљРѕРЅС†РµРїС†РёРё СЂРµР±СЂРµРЅРґРёРЅРіР° v1', 4, '2026-04-18 13:20:00'),
(16, 9, 41, NULL, 'drive_folder', 'https://drive.example.com/pulse/work', 'Р Р°Р±РѕС‡Р°СЏ РїР°РїРєР° С„РёС‚РЅРµСЃ-РєР»СѓР±Р°', 7, '2026-04-13 11:00:00'),
(17, 10, 45, 14, 'final_material', 'https://drive.example.com/northstar/final-lessons', 'Р¤РёРЅР°Р»СЊРЅС‹Рµ РІРёРґРµРѕ СѓСЂРѕРєРѕРІ', 8, '2026-04-04 18:20:00'),
(18, 10, 46, 15, 'final_material', 'https://drive.example.com/northstar/final-report', 'Р—Р°РєСЂС‹РІР°СЋС‰РёР№ РѕС‚С‡РµС‚', 2, '2026-04-14 15:20:00'),
(19, 10, 46, NULL, 'contract', 'https://docs.example.com/northstar/closing-docs', 'Р—Р°РєСЂС‹РІР°СЋС‰РёРµ РґРѕРєСѓРјРµРЅС‚С‹', 1, '2026-04-14 15:40:00');

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

-- END 02_seed_04_finance_materials.sql



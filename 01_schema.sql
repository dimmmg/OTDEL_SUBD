-- Информационная система контент-агентства
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

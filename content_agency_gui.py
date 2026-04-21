import csv
import io
import os
import subprocess
import tkinter as tk
from tkinter import messagebox, ttk


PSQL_PATH = r"C:\Program Files\PostgreSQL\18\bin\psql.exe"
PSQL_CLIENT_ENCODING = "WIN1251"
PSQL_TEXT_ENCODING = "cp1251"


TABLES = [
    {
        "title": "Сотрудники",
        "table": "employees",
        "pk": "employee_id",
        "search": ["e.full_name", "p.position_name", "tm.city_name", "e.telegram", "e.phone"],
        "select": """
            SELECT e.employee_id, e.full_name, p.position_name, tm.city_name,
                   e.telegram, e.phone, e.salary_type, e.fixed_salary,
                   e.percent_rate, e.hire_date, e.is_active
            FROM employees e
            JOIN positions p ON p.position_id = e.position_id
            JOIN teams tm ON tm.team_id = e.team_id
        """,
        "order": "e.employee_id",
        "fields": [
            "full_name", "telegram", "phone", "position_id", "team_id",
            "responsibility_area", "salary_type", "fixed_salary",
            "percent_rate", "hire_date", "is_active",
        ],
    },
    {
        "title": "Клиенты",
        "table": "clients",
        "pk": "client_id",
        "search": ["COALESCE(c.company_name, c.full_name)", "c.niche", "c.short_tz"],
        "select": """
            SELECT c.client_id, c.client_type,
                   COALESCE(c.company_name, c.full_name) AS client_name,
                   c.company_name, c.full_name, c.niche, c.short_tz, c.notes
            FROM clients c
        """,
        "order": "c.client_id",
        "fields": ["client_type", "company_name", "full_name", "niche", "short_tz", "notes"],
    },
    {
        "title": "Проекты",
        "table": "projects",
        "pk": "project_id",
        "search": ["p.project_name", "COALESCE(c.company_name, c.full_name)", "p.status"],
        "select": """
            SELECT p.project_id, p.project_name,
                   COALESCE(c.company_name, c.full_name) AS client_name,
                   p.project_type, p.status, lead.full_name AS lead_name,
                   creative.full_name AS creative_director_name,
                   p.start_date, p.planned_end_date, p.budget
            FROM projects p
            JOIN clients c ON c.client_id = p.client_id
            LEFT JOIN employees lead ON lead.employee_id = p.lead_id
            LEFT JOIN employees creative ON creative.employee_id = p.creative_director_id
        """,
        "order": "p.project_id",
        "fields": [
            "client_id", "brief_id", "project_name", "project_type", "status",
            "director_id", "lead_id", "creative_director_id", "start_date",
            "planned_end_date", "actual_end_date", "budget", "description",
        ],
    },
    {
        "title": "Этапы",
        "table": "project_stages",
        "pk": "stage_id",
        "search": ["p.project_name", "ps.stage_name", "ps.status", "e.full_name"],
        "select": """
            SELECT ps.stage_id, p.project_name, ps.stage_order, ps.stage_name,
                   e.full_name AS responsible_name, ps.planned_start_date,
                   ps.planned_end_date, ps.actual_start_date, ps.actual_end_date,
                   ps.status, ps.comments
            FROM project_stages ps
            JOIN projects p ON p.project_id = ps.project_id
            LEFT JOIN employees e ON e.employee_id = ps.responsible_id
        """,
        "order": "ps.project_id, ps.stage_order",
        "fields": [
            "project_id", "stage_name", "stage_order", "responsible_id",
            "planned_start_date", "planned_end_date", "actual_start_date",
            "actual_end_date", "status", "comments",
        ],
    },
    {
        "title": "Задачи",
        "table": "tasks",
        "pk": "task_id",
        "search": ["t.task_name", "p.project_name", "ps.stage_name", "assignee.full_name", "t.status"],
        "select": """
            SELECT t.task_id, p.project_name, ps.stage_name, t.task_name,
                   assignee.full_name AS assignee_name, assigner.full_name AS assigner_name,
                   t.priority, t.status, t.planned_hours, t.deadline, t.completed_at
            FROM tasks t
            JOIN projects p ON p.project_id = t.project_id
            JOIN project_stages ps ON ps.stage_id = t.stage_id
            LEFT JOIN employees assignee ON assignee.employee_id = t.assignee_id
            LEFT JOIN employees assigner ON assigner.employee_id = t.assigner_id
        """,
        "order": "t.task_id",
        "fields": [
            "project_id", "stage_id", "assigner_id", "assignee_id", "task_name",
            "description", "priority", "status", "planned_hours", "deadline",
            "completed_at", "checklist_template_id",
        ],
    },
    {
        "title": "Встречи",
        "table": "meetings",
        "pk": "meeting_id",
        "search": ["p.project_name", "m.meeting_type", "m.status", "e.full_name"],
        "select": """
            SELECT m.meeting_id, p.project_name, m.meeting_type, m.meeting_at,
                   m.format, m.location_or_link, e.full_name AS organizer_name,
                   m.status, m.notes
            FROM meetings m
            JOIN projects p ON p.project_id = m.project_id
            LEFT JOIN employees e ON e.employee_id = m.organizer_id
        """,
        "order": "m.meeting_at",
        "fields": [
            "project_id", "meeting_type", "meeting_at", "format",
            "location_or_link", "organizer_id", "status", "notes",
        ],
    },
    {
        "title": "Оплаты",
        "table": "payments",
        "pk": "payment_id",
        "search": ["p.project_name", "pay.payment_type", "pay.status", "pay.comment"],
        "select": """
            SELECT pay.payment_id, p.project_name, pay.payment_type,
                   pay.amount, pay.payment_date, pay.status, pay.comment
            FROM payments pay
            JOIN projects p ON p.project_id = pay.project_id
        """,
        "order": "pay.payment_id",
        "fields": ["project_id", "payment_type", "amount", "payment_date", "status", "comment"],
    },
    {
        "title": "Выплаты",
        "table": "employee_payouts",
        "pk": "payout_id",
        "search": ["p.project_name", "e.full_name", "ep.payout_type", "ep.comment"],
        "select": """
            SELECT ep.payout_id, p.project_name, e.full_name AS employee_name,
                   ep.payout_type, ep.salary_period, ep.fixed_part,
                   ep.percent_part, ep.gross_amount, ep.tax_amount,
                   ep.net_amount, ep.payout_date, ep.comment
            FROM employee_payouts ep
            JOIN projects p ON p.project_id = ep.project_id
            JOIN employees e ON e.employee_id = ep.employee_id
        """,
        "order": "ep.payout_id",
        "fields": [
            "project_id", "employee_id", "payout_type", "salary_period",
            "fixed_part", "percent_part", "gross_amount", "tax_amount",
            "net_amount", "payout_date", "comment",
        ],
    },
    {
        "title": "Версии",
        "table": "project_versions",
        "pk": "version_id",
        "search": ["p.project_name", "ps.stage_name", "pv.description", "pv.client_feedback"],
        "select": """
            SELECT pv.version_id, p.project_name, ps.stage_name,
                   pv.version_number, e.full_name AS uploaded_by,
                   pv.description, pv.sent_to_client_at, pv.is_approved,
                   pv.client_feedback, pv.created_at
            FROM project_versions pv
            JOIN projects p ON p.project_id = pv.project_id
            LEFT JOIN project_stages ps ON ps.stage_id = pv.stage_id
            LEFT JOIN employees e ON e.employee_id = pv.uploaded_by
        """,
        "order": "pv.version_id",
        "fields": [
            "project_id", "stage_id", "version_number", "uploaded_by",
            "description", "sent_to_client_at", "is_approved", "client_feedback",
        ],
    },
    {
        "title": "Ссылки",
        "table": "project_links",
        "pk": "link_id",
        "search": ["p.project_name", "pl.link_type", "pl.link_url", "pl.description"],
        "select": """
            SELECT pl.link_id, p.project_name, ps.stage_name, pv.version_number,
                   pl.link_type, pl.link_url, pl.description,
                   e.full_name AS added_by, pl.added_at
            FROM project_links pl
            JOIN projects p ON p.project_id = pl.project_id
            LEFT JOIN project_stages ps ON ps.stage_id = pl.stage_id
            LEFT JOIN project_versions pv ON pv.version_id = pl.version_id
            LEFT JOIN employees e ON e.employee_id = pl.added_by
        """,
        "order": "pl.link_id",
        "fields": [
            "project_id", "stage_id", "version_id", "link_type",
            "link_url", "description", "added_by",
        ],
    },
]


REPORTS = {
    "Выручка по проектам": """
        SELECT p.project_id, p.project_name, p.budget AS planned_budget,
               COALESCE(SUM(pay.amount) FILTER (WHERE pay.status = 'paid'), 0) AS paid_revenue,
               p.budget - COALESCE(SUM(pay.amount) FILTER (WHERE pay.status = 'paid'), 0) AS remaining_amount
        FROM projects p
        LEFT JOIN payments pay ON pay.project_id = p.project_id
        GROUP BY p.project_id, p.project_name, p.budget
        ORDER BY paid_revenue DESC
    """,
    "Просроченные задачи": """
        SELECT t.task_id, p.project_name, t.task_name, e.full_name AS assignee_name,
               t.priority, t.status, t.deadline
        FROM tasks t
        JOIN projects p ON p.project_id = t.project_id
        LEFT JOIN employees e ON e.employee_id = t.assignee_id
        WHERE t.status NOT IN ('done', 'cancelled')
          AND t.deadline < CURRENT_TIMESTAMP
        ORDER BY t.deadline
    """,
    "Проекты без предоплаты": """
        SELECT p.project_id, p.project_name,
               COALESCE(c.company_name, c.full_name) AS client_name,
               p.status, p.budget
        FROM projects p
        JOIN clients c ON c.client_id = p.client_id
        WHERE NOT EXISTS (
            SELECT 1
            FROM payments pay
            WHERE pay.project_id = p.project_id
              AND pay.payment_type = 'prepayment'
              AND pay.status = 'paid'
        )
        ORDER BY p.start_date
    """,
    "Загрузка сотрудников": """
        SELECT e.employee_id, e.full_name, pos.position_name,
               COUNT(t.task_id) FILTER (WHERE t.status NOT IN ('done', 'cancelled')) AS active_tasks,
               COALESCE(SUM(t.planned_hours) FILTER (WHERE t.status NOT IN ('done', 'cancelled')), 0) AS active_hours
        FROM employees e
        JOIN positions pos ON pos.position_id = e.position_id
        LEFT JOIN tasks t ON t.assignee_id = e.employee_id
        GROUP BY e.employee_id, e.full_name, pos.position_name
        ORDER BY active_tasks DESC, active_hours DESC
    """,
    "Версии на согласовании": """
        SELECT p.project_name, ps.stage_name, pv.version_number, pv.description,
               pv.sent_to_client_at, pv.client_feedback, e.full_name AS uploaded_by
        FROM project_versions pv
        JOIN projects p ON p.project_id = pv.project_id
        LEFT JOIN project_stages ps ON ps.stage_id = pv.stage_id
        LEFT JOIN employees e ON e.employee_id = pv.uploaded_by
        WHERE pv.sent_to_client_at IS NOT NULL
          AND pv.is_approved = FALSE
        ORDER BY pv.sent_to_client_at DESC
    """,
}


def sql_literal(value):
    value = "" if value is None else str(value).strip()
    if value == "":
        return "NULL"
    lower = value.lower()
    if lower in ("true", "false"):
        return lower.upper()
    return "'" + value.replace("'", "''") + "'"


class PgClient:
    def __init__(self, host, port, database, user, password):
        self.host = host
        self.port = port
        self.database = database
        self.user = user
        self.password = password

    def run_csv(self, sql):
        env = os.environ.copy()
        env["PGPASSWORD"] = self.password
        env["PGCLIENTENCODING"] = PSQL_CLIENT_ENCODING
        result = subprocess.run(
            [
                PSQL_PATH,
                "-h",
                self.host,
                "-p",
                self.port,
                "-U",
                self.user,
                "-d",
                self.database,
                "-v",
                "ON_ERROR_STOP=1",
                "--csv",
                "-c",
                sql,
            ],
            env=env,
            text=True,
            capture_output=True,
            encoding=PSQL_TEXT_ENCODING,
            errors="replace",
        )
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip() or result.stdout.strip())
        reader = csv.reader(io.StringIO(result.stdout))
        rows = list(reader)
        if not rows:
            return [], []
        return rows[0], rows[1:]

    def execute(self, sql):
        env = os.environ.copy()
        env["PGPASSWORD"] = self.password
        env["PGCLIENTENCODING"] = PSQL_CLIENT_ENCODING
        result = subprocess.run(
            [
                PSQL_PATH,
                "-h",
                self.host,
                "-p",
                self.port,
                "-U",
                self.user,
                "-d",
                self.database,
                "-v",
                "ON_ERROR_STOP=1",
                "-c",
                sql,
            ],
            env=env,
            text=True,
            capture_output=True,
            encoding=PSQL_TEXT_ENCODING,
            errors="replace",
        )
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip() or result.stdout.strip())
        return result.stdout


class LoginDialog(tk.Toplevel):
    def __init__(self, root):
        super().__init__(root)
        self.title("Подключение к PostgreSQL")
        self.resizable(False, False)
        self.result = None
        self.grab_set()

        values = {
            "host": "localhost",
            "port": "5432",
            "database": "content_agency_db",
            "user": "postgres",
            "password": "",
        }
        self.entries = {}

        frame = ttk.Frame(self, padding=18)
        frame.grid(row=0, column=0)

        ttk.Label(frame, text="Параметры подключения", font=("Segoe UI", 14, "bold")).grid(
            row=0, column=0, columnspan=2, sticky="w", pady=(0, 12)
        )

        labels = [
            ("host", "Хост"),
            ("port", "Порт"),
            ("database", "База"),
            ("user", "Пользователь"),
            ("password", "Пароль"),
        ]
        for row, (key, label) in enumerate(labels, start=1):
            ttk.Label(frame, text=label).grid(row=row, column=0, sticky="w", pady=4)
            entry = ttk.Entry(frame, width=34, show="*" if key == "password" else "")
            entry.insert(0, values[key])
            entry.grid(row=row, column=1, sticky="ew", pady=4)
            self.entries[key] = entry

        buttons = ttk.Frame(frame)
        buttons.grid(row=7, column=0, columnspan=2, sticky="e", pady=(14, 0))
        ttk.Button(buttons, text="Подключиться", command=self.connect).grid(row=0, column=0, padx=4)
        ttk.Button(buttons, text="Выход", command=self.cancel).grid(row=0, column=1, padx=4)

        self.bind("<Return>", lambda _event: self.connect())
        self.protocol("WM_DELETE_WINDOW", self.cancel)
        self.entries["password"].focus_set()

    def connect(self):
        self.result = {key: entry.get() for key, entry in self.entries.items()}
        self.destroy()

    def cancel(self):
        self.result = None
        self.destroy()


class RecordDialog(tk.Toplevel):
    def __init__(self, root, title, fields, values=None):
        super().__init__(root)
        self.title(title)
        self.geometry("560x520")
        self.result = None
        self.grab_set()
        self.entries = {}

        outer = ttk.Frame(self, padding=14)
        outer.pack(fill="both", expand=True)
        ttk.Label(outer, text=title, font=("Segoe UI", 13, "bold")).pack(anchor="w", pady=(0, 8))
        ttk.Label(
            outer,
            text="ID-поля вводятся числами. Пустое поле будет записано как NULL.",
            foreground="#555",
        ).pack(anchor="w", pady=(0, 10))

        canvas = tk.Canvas(outer, highlightthickness=0)
        scrollbar = ttk.Scrollbar(outer, orient="vertical", command=canvas.yview)
        body = ttk.Frame(canvas)
        body.bind("<Configure>", lambda _event: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.create_window((0, 0), window=body, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)
        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")

        values = values or {}
        for row, field in enumerate(fields):
            ttk.Label(body, text=field).grid(row=row, column=0, sticky="nw", padx=(0, 8), pady=5)
            entry = ttk.Entry(body, width=54)
            entry.insert(0, "" if values.get(field) is None else str(values.get(field)))
            entry.grid(row=row, column=1, sticky="ew", pady=5)
            self.entries[field] = entry

        buttons = ttk.Frame(self, padding=(14, 0, 14, 14))
        buttons.pack(fill="x")
        ttk.Button(buttons, text="Сохранить", command=self.save).pack(side="right", padx=4)
        ttk.Button(buttons, text="Отмена", command=self.destroy).pack(side="right", padx=4)

    def save(self):
        self.result = {field: entry.get() for field, entry in self.entries.items()}
        self.destroy()


class DataTab(ttk.Frame):
    def __init__(self, master, app, config):
        super().__init__(master, padding=10)
        self.app = app
        self.config_data = config
        self.columns = []

        top = ttk.Frame(self)
        top.pack(fill="x", pady=(0, 8))

        ttk.Label(top, text=config["title"], font=("Segoe UI", 14, "bold")).pack(side="left")
        self.search_var = tk.StringVar()
        ttk.Entry(top, textvariable=self.search_var, width=34).pack(side="left", padx=(18, 6))
        ttk.Button(top, text="Поиск", command=self.load).pack(side="left", padx=3)
        ttk.Button(top, text="Обновить", command=self.load).pack(side="left", padx=3)
        ttk.Button(top, text="Добавить", command=self.add_record).pack(side="right", padx=3)
        ttk.Button(top, text="Изменить", command=self.edit_record).pack(side="right", padx=3)
        ttk.Button(top, text="Удалить", command=self.delete_record).pack(side="right", padx=3)

        table_frame = ttk.Frame(self)
        table_frame.pack(fill="both", expand=True)
        self.tree = ttk.Treeview(table_frame, show="headings")
        yscroll = ttk.Scrollbar(table_frame, orient="vertical", command=self.tree.yview)
        xscroll = ttk.Scrollbar(table_frame, orient="horizontal", command=self.tree.xview)
        self.tree.configure(yscrollcommand=yscroll.set, xscrollcommand=xscroll.set)
        self.tree.grid(row=0, column=0, sticky="nsew")
        yscroll.grid(row=0, column=1, sticky="ns")
        xscroll.grid(row=1, column=0, sticky="ew")
        table_frame.rowconfigure(0, weight=1)
        table_frame.columnconfigure(0, weight=1)

    def build_query(self):
        cfg = self.config_data
        sql = cfg["select"]
        term = self.search_var.get().strip()
        if term:
            pattern = sql_literal("%" + term + "%")
            clauses = [f"CAST({column} AS TEXT) ILIKE {pattern}" for column in cfg["search"]]
            sql += " WHERE " + " OR ".join(clauses)
        sql += " ORDER BY " + cfg["order"]
        return sql

    def load(self):
        try:
            headers, rows = self.app.client.run_csv(self.build_query())
            self.columns = headers
            self.tree.delete(*self.tree.get_children())
            self.tree["columns"] = headers
            for header in headers:
                self.tree.heading(header, text=header)
                self.tree.column(header, width=150, minwidth=90, stretch=True)
            for row in rows:
                self.tree.insert("", "end", values=row)
            self.app.set_status(f"{self.config_data['title']}: строк {len(rows)}")
        except Exception as exc:
            messagebox.showerror("Ошибка загрузки", str(exc))

    def selected_pk(self):
        item_id = self.tree.focus()
        if not item_id:
            messagebox.showwarning("Нет выбора", "Выберите строку в таблице.")
            return None
        values = self.tree.item(item_id, "values")
        return values[0] if values else None

    def fetch_raw_record(self, pk_value):
        cfg = self.config_data
        sql = (
            f"SELECT {', '.join(cfg['fields'])} "
            f"FROM {cfg['table']} WHERE {cfg['pk']} = {sql_literal(pk_value)}"
        )
        headers, rows = self.app.client.run_csv(sql)
        if not rows:
            raise RuntimeError("Запись не найдена.")
        return dict(zip(headers, rows[0]))

    def add_record(self):
        cfg = self.config_data
        dialog = RecordDialog(self, f"Добавить: {cfg['title']}", cfg["fields"])
        self.wait_window(dialog)
        if not dialog.result:
            return
        fields = list(dialog.result.keys())
        values = [sql_literal(dialog.result[field]) for field in fields]
        sql = f"INSERT INTO {cfg['table']} ({', '.join(fields)}) VALUES ({', '.join(values)});"
        try:
            self.app.client.execute(sql)
            self.load()
        except Exception as exc:
            messagebox.showerror("Ошибка добавления", str(exc))

    def edit_record(self):
        cfg = self.config_data
        pk_value = self.selected_pk()
        if pk_value is None:
            return
        try:
            current = self.fetch_raw_record(pk_value)
        except Exception as exc:
            messagebox.showerror("Ошибка чтения", str(exc))
            return
        dialog = RecordDialog(self, f"Изменить: {cfg['title']}", cfg["fields"], current)
        self.wait_window(dialog)
        if not dialog.result:
            return
        assignments = [f"{field} = {sql_literal(value)}" for field, value in dialog.result.items()]
        sql = (
            f"UPDATE {cfg['table']} SET {', '.join(assignments)} "
            f"WHERE {cfg['pk']} = {sql_literal(pk_value)};"
        )
        try:
            self.app.client.execute(sql)
            self.load()
        except Exception as exc:
            messagebox.showerror("Ошибка изменения", str(exc))

    def delete_record(self):
        cfg = self.config_data
        pk_value = self.selected_pk()
        if pk_value is None:
            return
        if not messagebox.askyesno("Удаление", f"Удалить запись #{pk_value} из {cfg['table']}?"):
            return
        sql = f"DELETE FROM {cfg['table']} WHERE {cfg['pk']} = {sql_literal(pk_value)};"
        try:
            self.app.client.execute(sql)
            self.load()
        except Exception as exc:
            messagebox.showerror("Ошибка удаления", str(exc))


class ReportsTab(ttk.Frame):
    def __init__(self, master, app):
        super().__init__(master, padding=10)
        self.app = app
        self.columns = []

        top = ttk.Frame(self)
        top.pack(fill="x", pady=(0, 8))
        ttk.Label(top, text="Отчеты", font=("Segoe UI", 14, "bold")).pack(side="left")
        self.report_var = tk.StringVar(value=list(REPORTS.keys())[0])
        ttk.Combobox(top, textvariable=self.report_var, values=list(REPORTS.keys()), state="readonly", width=34).pack(
            side="left", padx=(18, 6)
        )
        ttk.Button(top, text="Сформировать", command=self.load).pack(side="left", padx=3)

        table_frame = ttk.Frame(self)
        table_frame.pack(fill="both", expand=True)
        self.tree = ttk.Treeview(table_frame, show="headings")
        yscroll = ttk.Scrollbar(table_frame, orient="vertical", command=self.tree.yview)
        xscroll = ttk.Scrollbar(table_frame, orient="horizontal", command=self.tree.xview)
        self.tree.configure(yscrollcommand=yscroll.set, xscrollcommand=xscroll.set)
        self.tree.grid(row=0, column=0, sticky="nsew")
        yscroll.grid(row=0, column=1, sticky="ns")
        xscroll.grid(row=1, column=0, sticky="ew")
        table_frame.rowconfigure(0, weight=1)
        table_frame.columnconfigure(0, weight=1)

    def load(self):
        name = self.report_var.get()
        try:
            headers, rows = self.app.client.run_csv(REPORTS[name])
            self.tree.delete(*self.tree.get_children())
            self.tree["columns"] = headers
            for header in headers:
                self.tree.heading(header, text=header)
                self.tree.column(header, width=160, minwidth=90, stretch=True)
            for row in rows:
                self.tree.insert("", "end", values=row)
            self.app.set_status(f"{name}: строк {len(rows)}")
        except Exception as exc:
            messagebox.showerror("Ошибка отчета", str(exc))


class Dashboard(ttk.Frame):
    def __init__(self, master, app):
        super().__init__(master, padding=16)
        self.app = app
        ttk.Label(self, text="Контент-агентство", font=("Segoe UI", 22, "bold")).pack(anchor="w")
        ttk.Label(
            self,
            text="Клиенты, проекты, задачи, оплаты, версии материалов и рабочие ссылки.",
            font=("Segoe UI", 11),
        ).pack(anchor="w", pady=(4, 16))

        self.metrics_frame = ttk.Frame(self)
        self.metrics_frame.pack(fill="x", pady=(0, 16))
        ttk.Button(self, text="Обновить показатели", command=self.load).pack(anchor="w")

    def load(self):
        for child in self.metrics_frame.winfo_children():
            child.destroy()
        queries = [
            ("Клиенты", "SELECT COUNT(*) FROM clients"),
            ("Активные проекты", "SELECT COUNT(*) FROM projects WHERE status NOT IN ('closed', 'cancelled')"),
            ("Незавершенные задачи", "SELECT COUNT(*) FROM tasks WHERE status NOT IN ('done', 'cancelled')"),
            ("Оплачено", "SELECT COALESCE(SUM(amount), 0) FROM payments WHERE status = 'paid'"),
            ("Версии на согласовании", "SELECT COUNT(*) FROM project_versions WHERE sent_to_client_at IS NOT NULL AND is_approved = FALSE"),
        ]
        for idx, (label, sql) in enumerate(queries):
            try:
                _headers, rows = self.app.client.run_csv(sql)
                value = rows[0][0] if rows else "0"
            except Exception:
                value = "?"
            box = ttk.Frame(self.metrics_frame, padding=12, relief="ridge")
            box.grid(row=0, column=idx, sticky="nsew", padx=(0, 8))
            ttk.Label(box, text=label).pack(anchor="w")
            ttk.Label(box, text=value, font=("Segoe UI", 16, "bold")).pack(anchor="w")
            self.metrics_frame.columnconfigure(idx, weight=1)


class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("ИС контент-агентства")
        self.geometry("1280x760")
        self.minsize(980, 620)
        self.client = None
        self.status_var = tk.StringVar(value="Нет подключения")
        self.tabs = []

        style = ttk.Style(self)
        style.theme_use("clam")

        self.withdraw()
        dialog = LoginDialog(self)
        self.wait_window(dialog)
        if not dialog.result:
            self.destroy()
            return

        self.client = PgClient(**dialog.result)
        try:
            self.client.run_csv("SELECT 1 AS ok")
        except Exception as exc:
            messagebox.showerror("Не удалось подключиться", str(exc))
            self.destroy()
            return

        self.deiconify()
        self.build_ui()

    def build_ui(self):
        notebook = ttk.Notebook(self)
        notebook.pack(fill="both", expand=True)

        dashboard = Dashboard(notebook, self)
        notebook.add(dashboard, text="Главная")
        dashboard.load()

        for config in TABLES:
            tab = DataTab(notebook, self, config)
            notebook.add(tab, text=config["title"])
            self.tabs.append(tab)

        reports = ReportsTab(notebook, self)
        notebook.add(reports, text="Отчеты")

        status = ttk.Label(self, textvariable=self.status_var, anchor="w", padding=(10, 4))
        status.pack(fill="x")

        for tab in self.tabs:
            tab.load()

    def set_status(self, text):
        self.status_var.set(text)


if __name__ == "__main__":
    if not os.path.exists(PSQL_PATH):
        raise SystemExit(f"psql.exe not found: {PSQL_PATH}")
    App().mainloop()

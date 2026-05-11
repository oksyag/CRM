-- =========================================================
-- CRM для обработки лидов — схема БД (PostgreSQL).
-- Состав: типы lead_status / lead_source, таблицы manager / lead / client,
-- ограничения целостности, индексы под дедупликацию и фильтры.
-- Файл рассчитан на одноразовое создание схемы; для повторного запуска
-- очистка существующей схемы выполняется отдельно.
-- =========================================================

BEGIN;

-- =========================================================
-- ENUM-типы
-- =========================================================

CREATE TYPE lead_status AS ENUM (
    'Новый',
    'В работе',
    'Отложен',
    'Успешно',
    'Ложный',
    'Отказ'
);

CREATE TYPE lead_source AS ENUM (
    'web',
    'phone',
    'chat',
    'social',
    'manual'
);

-- =========================================================
-- Таблицы
-- =========================================================

-- Менеджеры, доступные для назначения ответственного.
CREATE TABLE manager (
    id          BIGSERIAL   PRIMARY KEY,
    name        TEXT        NOT NULL,
    is_active   BOOLEAN     NOT NULL DEFAULT TRUE
);

COMMENT ON TABLE  manager           IS 'Менеджеры, доступные для назначения на лид.';
COMMENT ON COLUMN manager.is_active IS 'Доступность менеджера для назначения.';

-- Лид: основная сущность жизненного цикла обработки.
CREATE TABLE lead (
    id                  BIGSERIAL   PRIMARY KEY,
    source              lead_source NOT NULL,
    full_name           TEXT        NOT NULL,
    phone               TEXT        NOT NULL,
    email               TEXT        NOT NULL,
    status              lead_status NOT NULL DEFAULT 'Новый',
    assignee_id         BIGINT      NULL
        REFERENCES manager(id) ON DELETE RESTRICT,
    follow_up_at        TIMESTAMPTZ NULL,
    close_reason        TEXT        NULL,
    comment             TEXT        NULL,
    reopen_of_lead_id   BIGINT      NULL
        REFERENCES lead(id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Бизнес-правило: при status='Отложен' обязателен follow_up_at.
    CONSTRAINT lead_postponed_requires_follow_up
        CHECK (
            status <> 'Отложен'
            OR follow_up_at IS NOT NULL
        ),

    -- Бизнес-правило: при status в ('Ложный','Отказ') обязателен непустой close_reason.
    CONSTRAINT lead_closed_requires_reason
        CHECK (
            status NOT IN ('Ложный', 'Отказ')
            OR (close_reason IS NOT NULL AND length(trim(close_reason)) > 0)
        )
);

COMMENT ON TABLE  lead                  IS
    'Лид. Инвариант "status=''Успешно'' тогда и только тогда, когда есть запись в client.lead_id" обеспечивается приложением через POST /leads/{id}/convert.';
COMMENT ON COLUMN lead.phone            IS 'Телефон. Перед дедупликацией нормализуется на прикладном уровне.';
COMMENT ON COLUMN lead.email            IS 'Email. Перед дедупликацией нормализуется (lower + trim).';
COMMENT ON COLUMN lead.follow_up_at     IS 'Дата следующего контакта; обязательна при status=''Отложен''.';
COMMENT ON COLUMN lead.close_reason     IS 'Причина закрытия; обязательна при status в (''Ложный'',''Отказ'').';
COMMENT ON COLUMN lead.reopen_of_lead_id IS 'Ссылка на предыдущий лид при повторном обращении после ''Ложный''/''Отказ''.';

-- Клиент: создаётся при успешной конвертации лида.
CREATE TABLE client (
    id          BIGSERIAL   PRIMARY KEY,
    lead_id     BIGINT      NOT NULL UNIQUE
        REFERENCES lead(id) ON DELETE RESTRICT,
    full_name   TEXT        NOT NULL,
    phone       TEXT        NOT NULL,
    email       TEXT        NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE  client         IS 'Клиент, созданный при конвертации лида в статус ''Успешно''.';
COMMENT ON COLUMN client.lead_id IS 'Ссылка на исходный лид; UNIQUE — один клиент на один лид.';

-- =========================================================
-- Индексы
-- =========================================================

-- Дедупликация по нормализованным phone и email.
CREATE INDEX idx_lead_phone        ON lead (phone);
CREATE INDEX idx_lead_email_lower  ON lead (lower(email));

-- Фильтры списка лидов: GET /leads.
CREATE INDEX idx_lead_status       ON lead (status);
CREATE INDEX idx_lead_assignee_id  ON lead (assignee_id);
CREATE INDEX idx_lead_source       ON lead (source);

-- Цепочки повторных обращений: только заполненные значения.
CREATE INDEX idx_lead_reopen_of_lead_id
    ON lead (reopen_of_lead_id)
    WHERE reopen_of_lead_id IS NOT NULL;

COMMIT;

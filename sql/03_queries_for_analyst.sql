-- =========================================================
-- CRM для обработки лидов — типовые и аналитические запросы.
-- Литералы в WHERE подставлены для наглядности; в реальном приложении
-- значения параметров приходят из API.
-- Все запросы согласованы с docs/data-model.md, api/openapi.yaml и
-- user stories US-01..US-04 / use cases UC-01..UC-03.
-- =========================================================


-- =========================================================
-- Q1. Список лидов с опциональными фильтрами и пагинацией.
-- Покрывает: GET /leads (US-03, UC-02).
-- Параметры: status, manager (assignee_id), source, limit, offset.
-- Любую строку фильтра можно закомментировать, чтобы отключить условие.
-- =========================================================
SELECT
    l.id,
    l.source,
    l.full_name,
    l.phone,
    l.email,
    l.status,
    l.assignee_id,
    l.follow_up_at,
    l.close_reason,
    l.reopen_of_lead_id,
    l.created_at,
    l.updated_at
FROM lead AS l
WHERE l.status      = 'В работе'
  AND l.assignee_id = 1
  AND l.source      = 'phone'
ORDER BY l.created_at DESC
LIMIT 50 OFFSET 0;


-- =========================================================
-- Q2. Карточка лида с именем ответственного менеджера.
-- Покрывает: GET /leads/{id} и требование NFR usability
-- (в карточке отображается ответственный менеджер).
-- =========================================================
SELECT
    l.id,
    l.source,
    l.full_name,
    l.phone,
    l.email,
    l.status,
    l.assignee_id,
    m.name           AS assignee_name,
    l.follow_up_at,
    l.close_reason,
    l.comment,
    l.reopen_of_lead_id,
    l.created_at,
    l.updated_at
FROM lead AS l
LEFT JOIN manager AS m ON m.id = l.assignee_id
WHERE l.id = 1002;


-- =========================================================
-- Q3. Дедупликация: активный дубликат по phone или email.
-- Покрывает: US-01, US-02, UC-01 (правило 409 duplicate).
-- Активные статусы для блокировки: 'Новый', 'В работе', 'Отложен'.
-- Email сравнивается по нормализованному виду (lower + trim).
-- Phone приходит уже нормализованным с прикладного уровня.
-- =========================================================
SELECT
    l.id    AS existing_lead_id,
    l.status,
    l.source,
    l.phone,
    l.email,
    l.created_at
FROM lead AS l
WHERE l.status IN ('Новый', 'В работе', 'Отложен')
  AND (
        l.phone                  = '+79011234567'
        OR lower(trim(l.email))  = lower(trim('ivan@example.com'))
      )
ORDER BY l.created_at DESC;


-- =========================================================
-- Q4. Конфликт идентичности: один активный лид найден по phone,
-- другой активный — по email. В API соответствует 409 conflict.
-- Покрывает: UC-01, альтернативный поток A3.
-- =========================================================
WITH active_by_phone AS (
    SELECT id
    FROM lead
    WHERE status IN ('Новый', 'В работе', 'Отложен')
      AND phone = '+79011234567'
    ORDER BY created_at DESC
    LIMIT 1
),
active_by_email AS (
    SELECT id
    FROM lead
    WHERE status IN ('Новый', 'В работе', 'Отложен')
      AND lower(trim(email)) = lower(trim('anna@example.com'))
    ORDER BY created_at DESC
    LIMIT 1
)
SELECT
    p.id AS lead_id_by_phone,
    e.id AS lead_id_by_email
FROM active_by_phone AS p
CROSS JOIN active_by_email AS e
WHERE p.id <> e.id;


-- =========================================================
-- Q5. Совпадение только с закрытыми лидами ('Ложный'/'Отказ') —
-- кандидат для повторного обращения с заполнением reopen_of_lead_id.
-- Покрывает: UC-01, альтернативный поток A2.
-- Возвращает идентификатор предыдущего закрытого лида,
-- если активных совпадений нет.
-- =========================================================
SELECT
    l.id    AS reopen_of_lead_id,
    l.status,
    l.updated_at
FROM lead AS l
WHERE l.status IN ('Ложный', 'Отказ')
  AND (
        l.phone                  = '+79055554444'
        OR lower(trim(l.email))  = lower(trim('ivan.p@example.com'))
      )
  AND NOT EXISTS (
      SELECT 1
      FROM lead AS l2
      WHERE l2.status IN ('Новый', 'В работе', 'Отложен')
        AND (
              l2.phone                  = '+79055554444'
              OR lower(trim(l2.email))  = lower(trim('ivan.p@example.com'))
            )
  )
ORDER BY l.updated_at DESC
LIMIT 1;


-- =========================================================
-- Q6. Лиды с наступающим follow-up: status='Отложен' и
-- follow_up_at <= текущего момента.
-- Покрывает: UC-03 A1 (возврат 'Отложен' -> 'В работе').
-- =========================================================
SELECT
    l.id,
    l.full_name,
    l.assignee_id,
    m.name        AS assignee_name,
    l.follow_up_at
FROM lead AS l
LEFT JOIN manager AS m ON m.id = l.assignee_id
WHERE l.status        = 'Отложен'
  AND l.follow_up_at <= now()
ORDER BY l.follow_up_at ASC;


-- =========================================================
-- Q7. Распределение лидов по статусам.
-- Аналитический срез текущего pipeline.
-- =========================================================
SELECT
    l.status,
    count(*) AS leads_count
FROM lead AS l
GROUP BY l.status
ORDER BY leads_count DESC, l.status ASC;


-- =========================================================
-- Q8. Топ менеджеров по числу конвертированных лидов
-- (status='Успешно'). Аналитический срез по эффективности.
-- =========================================================
SELECT
    m.id           AS manager_id,
    m.name         AS manager_name,
    m.is_active,
    count(l.id)    AS converted_leads
FROM manager AS m
LEFT JOIN lead AS l
       ON l.assignee_id = m.id
      AND l.status      = 'Успешно'
GROUP BY m.id, m.name, m.is_active
ORDER BY converted_leads DESC, m.name ASC;

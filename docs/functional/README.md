# Functional Requirements Overview

## User Stories
- **US-01** — Создание лида из веб-формы с валидацией и дедупликацией по телефону и email.
- **US-02** — Создание лида вручную менеджером.
- **US-03** — Назначение лида ответственному менеджеру и перевод в работу.
- **US-04** — Финализация лида: отложить, конвертировать в клиента или закрыть.

## Use Cases
- **UC-01** — Регистрация нового лида.
- **UC-02** — Активная обработка лида (квалификация и маршрутизация).
- **UC-03** — Финализация лида (отложить, конвертировать или закрыть).

## Зачем в проекте оба формата
- **User Stories** фиксируют ценность и потребность с точки зрения actor.
- **Use Cases** раскрывают сценарий выполнения процесса от входа до результата.
- Вместе они дают и бизнес-фокус, и процессную детализацию без лишнего объема.

## Traceability (компактно)
| User Story | Use Case | Сущности данных | API методы | Диаграммы |
|---|---|---|---|---|
| US-01 Создание лида из веб-формы с валидацией и дедупликацией по телефону и email | UC-01 Регистрация нового лида | `Lead` | `POST /web/leads`, `GET /leads/{id}` | `sequence-webform-to-crm.mmd`, `bpmn-lead-lifecycle.mmd`, `state-lead-lifecycle.mmd` |
| US-02 Создание лида вручную менеджером | UC-01 Регистрация нового лида | `Lead` | `POST /leads`, `GET /leads/{id}` | `uml-use-case.mmd`, `bpmn-lead-lifecycle.mmd`, `state-lead-lifecycle.mmd` |
| US-03 Назначение лида ответственному менеджеру и перевод в работу | UC-02 Активная обработка лида (квалификация и маршрутизация) | `Lead`, `Manager` | `GET /managers`, `PATCH /leads/{id}/assignee`, `PATCH /leads/{id}/status`, `GET /leads?status=&manager=&source=` | `bpmn-lead-lifecycle.mmd`, `state-lead-lifecycle.mmd`, `uml-use-case.mmd` |
| US-04 Финализация лида: отложить, конвертировать в клиента или закрыть | UC-03 Финализация лида (отложить, конвертировать или закрыть; включая обратный переход `Отложен → В работе`) | `Lead`, `Client` | `PATCH /leads/{id}/status`, `POST /leads/{id}/convert`, `GET /leads/{id}` | `bpmn-lead-lifecycle.mmd`, `state-lead-lifecycle.mmd`, `erd.mmd`, `uml-use-case.mmd` |

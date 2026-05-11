# CRM для обработки лидов

Документация системного аналитика для CRM, обрабатывающей лиды из веб-формы и при ручном создании менеджером. Проект ведётся в формате doc-as-code и охватывает полный цикл артефактов: бизнес-контекст, требования, модель данных, API, SQL, диаграммы.

**Технологии и форматы:** Markdown, OpenAPI 3.1, PostgreSQL, Mermaid.

## Что показано

- Бизнес-контекст: scope, stakeholders, жизненный цикл лида, бизнес-правила дедупликации.
- Требования: 4 user stories, 3 use cases, NFR, DoR/DoD, traceability между артефактами.
- Модель данных: 3 сущности, ENUM-типы, FK и CHECK-ограничения.
- API: OpenAPI 3.1 — 8 эндпоинтов, схемы, примеры запросов и ответов.
- SQL: схема PostgreSQL, демонстрационные данные, аналитические запросы.
- Визуализация: BPMN, state machine, sequence, UML use case, ERD.

## Структура репозитория

```
.
├── docs/
│   ├── overview.md
│   ├── nfr.md
│   ├── data-model.md
│   ├── glossary.md
│   ├── integration.md
│   ├── dor-dod.md
│   └── functional/
│       ├── README.md
│       ├── user-stories/      # US-01..US-04
│       └── use-cases/         # UC-01..UC-03
├── api/
│   └── openapi.yaml
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_sample_data.sql
│   └── 03_queries_for_analyst.sql
├── diagrams/
│   ├── bpmn-lead-lifecycle.mmd
│   ├── state-lead-lifecycle.mmd
│   ├── sequence-webform-to-crm.mmd
│   ├── uml-use-case.mmd
│   └── erd.mmd
├── templates/
│   ├── user-story-template.md
│   ├── use-case-template.md
│   └── change-log-template.md
├── index.html
├── styles.css
└── README.md
```

## Точки входа

- **Лендинг-витрина:** [index.html](index.html) — entry point на GitHub Pages.
- **Бизнес-контекст:** [overview](docs/overview.md), [NFR](docs/nfr.md), [DoR/DoD](docs/dor-dod.md), [глоссарий](docs/glossary.md).
- **Функциональные требования:** [обзор US и UC с traceability](docs/functional/README.md).
- **Модель данных:** [data-model.md](docs/data-model.md), [ERD](diagrams/erd.mmd).
- **Интеграция:** [integration.md](docs/integration.md).
- **API:** [openapi.yaml](api/openapi.yaml) — можно открыть в [Swagger Editor](https://editor.swagger.io/) или [Redocly](https://redocly.github.io/redoc/).
- **SQL:** [схема](sql/01_create_tables.sql), [данные](sql/02_sample_data.sql), [запросы](sql/03_queries_for_analyst.sql).
- **Диаграммы:** [BPMN](diagrams/bpmn-lead-lifecycle.mmd), [state](diagrams/state-lead-lifecycle.mmd), [sequence](diagrams/sequence-webform-to-crm.mmd), [use case](diagrams/uml-use-case.mmd), [ERD](diagrams/erd.mmd).
- **Шаблоны:** [user-story](templates/user-story-template.md), [use-case](templates/use-case-template.md), [changelog](templates/change-log-template.md).

## Автор

Oksana Gaibova

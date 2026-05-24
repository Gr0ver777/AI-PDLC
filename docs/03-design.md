# Дизайн

## Архитектура

Продукт реализован как monorepo:

- React UI вызывает REST API.
- Spring Boot API валидирует запросы, сохраняет заявки и запускает rule-based AI simulator.
- PostgreSQL хранит заявки и историю обработки.
- Pytest Playwright тесты проверяют happy-path сценарии через UI.

## Хранение данных

Рабочий backend использует PostgreSQL:

- database: `ai_pdlc`
- user: `ai_pdlc`
- default local URL: `jdbc:postgresql://localhost:5432/ai_pdlc`

Локальный PostgreSQL поднимается через `docker-compose.yml`. Spring Boot создает и обновляет таблицы через Hibernate `ddl-auto=update`, что достаточно для MVP. Для промышленного режима следующий шаг - добавить миграции Flyway или Liquibase.

Backend-тесты используют отдельный `test` profile и H2 in-memory в режиме совместимости PostgreSQL, чтобы быстрые проверки не требовали Docker.

## Основной поток

1. Оператор заполняет форму реструктуризации или банкротства.
2. Frontend отправляет `POST` запрос в backend.
3. Backend создает заявку, рассчитывает риск и рекомендацию.
4. Backend сохраняет заявку и историю в PostgreSQL.
5. Frontend открывает карточку созданной заявки.
6. Оператор применяет решение, backend обновляет статус и историю.

## Правила AI simulator

Риск растет при высокой сумме долга, большой просрочке, отсутствии обеспечения и банкротном процессе. Рекомендация формируется отдельно для реструктуризации и банкротства.

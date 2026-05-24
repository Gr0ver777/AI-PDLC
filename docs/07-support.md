# Поддержка

## Диагностика

- Health endpoint: `GET /actuator/health`.
- API base URL: `http://localhost:8080/api`.
- Frontend dev server: `http://localhost:5173`.
- H2 console: `http://localhost:8080/h2-console`.

## Типовые действия поддержки

- Проверить, что backend запущен на порту `8080`.
- Проверить, что frontend использует корректный `VITE_API_URL`.
- При проблемах с данными открыть H2 console и проверить таблицу `ASSET_CASES`.
- При падении UI автотестов открыть Allure results или pytest trace.

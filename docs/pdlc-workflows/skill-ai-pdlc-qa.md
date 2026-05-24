---
name: ai-pdlc-qa
description: Repo-local workflow for Senior QA review of AI-PDLC requirements, manual tests, Playwright checks, and automated UI coverage.
---

# AI-PDLC QA Workflow

Использовать, когда в проекте появились новые требования, ручные тест-кейсы или UI-автотесты.

## Основной порядок

1. Найти новые требования в `docs/requirements/`.
2. Проверить требования по `docs/pdlc-workflows/requirements-review.md`.
3. Записать review в `docs/qa-reviews/`.
4. Если review не `NEEDS_REWORK`, создать ручной тест-кейс в `tests/manual/`.
5. Для frontend-фич пройти сценарий через Playwright или Playwright route mocking.
6. На основе ручного кейса создать автотест в `tests/ui/`.
7. Запустить релевантные проверки и зафиксировать результат в коммите.

## Правила

- Не писать автотест раньше ручного тест-кейса.
- Не менять backend contract для frontend-only требований.
- Не коммитить `.pw-browsers`, `node_modules`, `.venv`, `__pycache__`, кеши и отчеты Allure.
- Если backend недоступен, использовать route mocking только для frontend-only сценариев.

# AI-PDLC MVP

MVP имитирует рабочее место банковского департамента по работе с проблемными активами. В первой версии реализованы два процесса: реструктуризация и банкротство.

## Структура

- `frontend` - React + TypeScript + Vite UI.
- `backend` - Spring Boot 4 API, Java 21, PostgreSQL.
- `docs` - документация по PDLC: идея, требования, дизайн, разработка, тестирование, релиз, поддержка.
- `tests` - pytest + Playwright UI-автотесты с Page Object, Page Factory и Page Element.
- `scripts` - локальная автоматизация PDLC flow.

## Локальный Gradle

Gradle 9.4.1 распакован в `tools/gradle-9.4.1` из архива `C:\Users\grafm\Downloads\gradle-9.4.1-bin.zip`.

Wrapper backend настроен на этот локальный архив:

```properties
distributionUrl=file:///C:/Users/grafm/Downloads/gradle-9.4.1-bin.zip
```

Если архив перемещен, обновите `backend/gradle/wrapper/gradle-wrapper.properties`.

## Локальный запуск

PostgreSQL:

```powershell
.\scripts\start_postgres.ps1
```

Если Docker Desktop закрыт, можно попросить скрипт открыть его:

```powershell
.\scripts\start_postgres.ps1 -OpenDockerDesktop
```

Backend:

```powershell
cd backend
.\gradlew.bat bootRun
```

Если терминал открыт в Git Bash:

```bash
cd backend
./gradlew.bat bootRun
```

Frontend:

```powershell
cd frontend
npm.cmd install
npm.cmd run dev
```

UI доступен на `http://localhost:5173`, API - на `http://localhost:8080/api`.

Backend по умолчанию подключается к PostgreSQL:

```text
jdbc:postgresql://localhost:5432/ai_pdlc
user: ai_pdlc
password: ai_pdlc
```

Переменные окружения для переопределения:

```powershell
$env:AI_PDLC_DB_URL="jdbc:postgresql://localhost:5432/ai_pdlc"
$env:AI_PDLC_DB_USER="ai_pdlc"
$env:AI_PDLC_DB_PASSWORD="ai_pdlc"
```

## Проверки

Frontend:

```powershell
npm.cmd --prefix frontend run lint
npm.cmd --prefix frontend run build
```

UI-автотесты:

```powershell
$env:PLAYWRIGHT_BROWSERS_PATH="D:\PycharmProject\AI-PDLC\.pw-browsers"
python -m pytest tests\ui -q
```

UI-автотесты с видимым браузером:

```powershell
$env:PLAYWRIGHT_BROWSERS_PATH="D:\PycharmProject\AI-PDLC\.pw-browsers"
python -m pytest tests\ui -q --headed --slowmo 300
```

Backend:

```powershell
tools\gradle-9.4.1\bin\gradle.bat -p backend test --no-daemon
```

Backend-тесты используют отдельный Spring profile `test` и H2 in-memory в режиме совместимости PostgreSQL. Рабочий запуск приложения использует PostgreSQL.

Первый backend-запуск требует сетевой доступ к Gradle Plugin Portal и Maven Central для загрузки Spring Boot 4.0.6 и зависимостей. После прогрева Gradle cache backend можно запускать повторно без повторного скачивания большинства артефактов.

## Правило веток для PDLC

Каждый новый функционал начинается в отдельной feature-ветке от актуального `main`.

Рекомендуемый формат:

```text
codex/pdlc-<feature-slug>
```

PDLC runner не должен выполнять delivery-коммиты напрямую в `main`, `dev` или в уже используемой feature-ветке другого функционала.

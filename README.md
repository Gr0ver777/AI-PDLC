# AI-PDLC MVP

MVP имитирует рабочее место банковского департамента по работе с проблемными активами. В первой версии реализованы два процесса: реструктуризация и банкротство.

## Структура

- `frontend` — React + TypeScript + Vite UI.
- `backend` — Spring Boot 4 API, Java 21, H2 file DB.
- `docs` — документация по PDLC: идея, требования, дизайн, разработка, тестирование, релиз, поддержка.
- `tests` — pytest + Playwright UI автотесты с Page Object, Page Factory и Page Element.

## Локальный запуск

Backend:

```powershell
cd backend
.\gradlew.bat bootRun
```

Если терминал открыт в Git Bash, используйте прямой слэш:

```bash
cd backend
./gradlew.bat bootRun
```

Если терминал открыт в CMD:

```cmd
cd backend
gradlew.bat bootRun
```

Frontend:

```powershell
cd frontend
npm.cmd install
npm.cmd run dev
```

UI доступен на `http://localhost:5173`, API — на `http://localhost:8080/api`, H2 console — на `http://localhost:8080/h2-console`.

## Автотесты

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r tests\requirements.txt
.\.venv\Scripts\python.exe -m playwright install chromium
.\.venv\Scripts\python.exe -m pytest tests\ui --alluredir=tests\allure-results
```

Запуск UI-тестов с видимым окном браузера:

```powershell
$env:PLAYWRIGHT_BROWSERS_PATH="D:\PycharmProject\AI-PDLC\.pw-browsers"
python -m pytest tests\ui -q --headed --slowmo 300
```

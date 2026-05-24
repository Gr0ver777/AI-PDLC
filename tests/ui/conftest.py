import json
import os
from pathlib import Path
from urllib.parse import urlparse

import pytest
from playwright.sync_api import Page, Route, expect


PROJECT_ROOT = Path(__file__).resolve().parents[2]
LOCAL_CHROMIUM = PROJECT_ROOT / ".pw-browsers" / "chromium-1181" / "chrome-win" / "chrome.exe"


@pytest.fixture(scope="session")
def base_url() -> str:
    return os.getenv("AI_PDLC_BASE_URL", "http://localhost:5173")


@pytest.fixture(scope="session")
def browser_type_launch_args(browser_type_launch_args):
    if LOCAL_CHROMIUM.exists():
        return {
            **browser_type_launch_args,
            "executable_path": str(LOCAL_CHROMIUM),
            "args": ["--no-sandbox"],
        }
    return browser_type_launch_args


@pytest.fixture()
def mock_api(page: Page):
    cases: list[dict] = []
    next_id = 1

    def make_case(payload: dict, module: str) -> dict:
        nonlocal next_id
        risk_level = "HIGH" if payload["debtAmount"] >= 5_000_000 or module == "BANKRUPTCY" else "MEDIUM"
        item = {
            "id": next_id,
            "clientName": payload["clientName"],
            "clientId": payload["clientId"],
            "debtAmount": payload["debtAmount"],
            "overdueDays": payload["overdueDays"],
            "collateral": payload["collateral"],
            "module": module,
            "status": "IN_REVIEW",
            "riskLevel": risk_level,
            "priority": "CRITICAL" if risk_level == "HIGH" else "URGENT",
            "recommendation": "Mock AI: проверить документы и согласовать следующий шаг с ответственным менеджером.",
            "createdAt": "2026-05-24T12:00:00Z",
            "history": ["2026-05-24T12:00:00Z | Создана заявка в mock API"],
            **module_fields(payload, module),
        }
        next_id += 1
        cases.append(item)
        return item

    def route_api(route: Route) -> None:
        request = route.request
        parsed = urlparse(request.url)
        path = parsed.path

        if request.method == "GET" and path.endswith("/api/cases"):
            route.fulfill(status=200, content_type="application/json", body=json.dumps(cases))
            return

        if request.method == "GET" and "/api/cases/" in path:
            case_id = int(path.rsplit("/", 1)[1])
            route.fulfill(status=200, content_type="application/json", body=json.dumps(find_case(cases, case_id)))
            return

        if request.method == "POST" and path.endswith("/api/restructuring-cases"):
            route.fulfill(status=201, content_type="application/json", body=json.dumps(make_case(post_data_json(request), "RESTRUCTURING")))
            return

        if request.method == "POST" and path.endswith("/api/bankruptcy-cases"):
            route.fulfill(status=201, content_type="application/json", body=json.dumps(make_case(post_data_json(request), "BANKRUPTCY")))
            return

        if request.method == "POST" and "/api/cases/" in path and path.endswith("/decision"):
            case_id = int(path.split("/api/cases/")[1].split("/")[0])
            item = find_case(cases, case_id)
            item["status"] = "ESCALATED"
            item["history"].append("2026-05-24T12:05:00Z | Решение оператора ESCALATE")
            route.fulfill(status=200, content_type="application/json", body=json.dumps(item))
            return

        route.fallback()

    page.route("**/api/**", route_api)
    return cases


@pytest.fixture()
def app(page: Page, base_url: str, mock_api):
    page.goto(base_url)
    expect(page.get_by_role("heading", name="Рабочая панель отдела")).to_be_visible()
    return page


def module_fields(payload: dict, module: str) -> dict:
    if module == "RESTRUCTURING":
        return {
            "newPaymentSchedule": payload["newPaymentSchedule"],
            "restructuringTermMonths": payload["restructuringTermMonths"],
            "newInterestRate": payload["newInterestRate"],
            "hardshipReason": payload["hardshipReason"],
        }
    return {
        "bankruptcyStage": payload["bankruptcyStage"],
        "courtCaseNumber": payload["courtCaseNumber"],
        "debtorAssets": payload["debtorAssets"],
        "legalRisk": payload["legalRisk"],
    }


def find_case(cases: list[dict], case_id: int) -> dict:
    return next(item for item in cases if item["id"] == case_id)


def post_data_json(request) -> dict:
    payload = request.post_data_json
    return payload() if callable(payload) else payload

import os
from pathlib import Path

import pytest
from playwright.sync_api import Page, expect


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
def app(page: Page, base_url: str):
    page.goto(base_url)
    expect(page.get_by_role("heading", name="Рабочая панель отдела")).to_be_visible()
    return page

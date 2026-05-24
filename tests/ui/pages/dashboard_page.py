from playwright.sync_api import expect

from tests.ui.pages.base_page import BasePage


class DashboardPage(BasePage):
    def expect_loaded(self) -> None:
        expect(self.page.get_by_role("heading", name="Рабочая панель отдела")).to_be_visible()

    def filter_module(self, module_name: str) -> None:
        self.page.get_by_label("Модуль").select_option(label=module_name)

    def open_first_case(self) -> None:
        self.page.get_by_role("button", name="Открыть").first.click()

    def expect_case_visible(self, client_name: str) -> None:
        expect(self.page.get_by_text(client_name).first).to_be_visible()

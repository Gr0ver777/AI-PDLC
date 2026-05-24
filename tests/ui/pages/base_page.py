from playwright.sync_api import Page


class BasePage:
    def __init__(self, page: Page):
        self.page = page

    def open_section(self, name: str) -> None:
        self.page.get_by_role("button", name=name).click()

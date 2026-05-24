from playwright.sync_api import Locator


class BaseElement:
    def __init__(self, locator: Locator):
        self.locator = locator

    def click(self) -> None:
        self.locator.click()

    def fill(self, value: str) -> None:
        self.locator.fill(value)

    def text(self) -> str:
        return self.locator.inner_text()

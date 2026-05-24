from playwright.sync_api import expect

from tests.ui.factories.case_data_factory import SupportPlanData
from tests.ui.pages.base_page import BasePage


class CaseDetailsPage(BasePage):
    def expect_recommendation(self) -> None:
        expect(self.page.get_by_role("heading", name="AI-рекомендация")).to_be_visible()

    def expect_support_plan(self, data: SupportPlanData) -> None:
        expect(self.page.get_by_role("heading", name="План сопровождения клиента")).to_be_visible()
        expect(self.page.get_by_text(data.relationship_manager)).to_be_visible()
        expect(self.page.get_by_text(data.contact_channel)).to_be_visible()
        expect(self.page.get_by_text(data.document_package_status)).to_be_visible()
        expect(self.page.get_by_text(data.support_comment)).to_be_visible()

    def escalate(self) -> None:
        self.page.get_by_role("button", name="Эскалировать").click()

    def expect_escalated(self) -> None:
        expect(self.page.get_by_text("Эскалировано").first).to_be_visible()
        expect(self.page.get_by_text("Решение оператора ESCALATE").first).to_be_visible()

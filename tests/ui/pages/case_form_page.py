from playwright.sync_api import expect

from tests.ui.factories.case_data_factory import BankruptcyData, RestructuringData, SupportPlanData
from tests.ui.pages.base_page import BasePage


class CaseFormPage(BasePage):
    def fill_common(self, client_name: str, client_id: str, debt_amount: str, overdue_days: str) -> None:
        self.page.get_by_label("Клиент").fill(client_name)
        self.page.get_by_label("ИНН / ID").fill(client_id)
        self.page.get_by_label("Сумма долга").fill(debt_amount)
        self.page.get_by_label("Просрочка, дней").fill(overdue_days)

    def expect_support_plan_fields(self) -> None:
        expect(self.page.get_by_text("План сопровождения клиента")).to_be_visible()
        expect(self.page.get_by_label("Дата следующего контакта")).to_be_visible()
        expect(self.page.get_by_label("Ответственный менеджер")).to_be_visible()
        expect(self.page.get_by_label("Канал связи")).to_be_visible()
        expect(self.page.get_by_label("Статус пакета документов")).to_be_visible()
        expect(self.page.get_by_label("Комментарий по сопровождению")).to_be_visible()

    def fill_support_plan(self, data: SupportPlanData) -> None:
        self.page.get_by_label("Дата следующего контакта").fill(data.next_contact_date)
        self.page.get_by_label("Ответственный менеджер").fill(data.relationship_manager)
        self.page.get_by_label("Канал связи").select_option(label=data.contact_channel)
        self.page.get_by_label("Статус пакета документов").select_option(label=data.document_package_status)
        self.page.get_by_label("Комментарий по сопровождению").fill(data.support_comment)

    def clear_required_support_plan_fields(self) -> None:
        self.page.get_by_label("Дата следующего контакта").fill("")
        self.page.get_by_label("Ответственный менеджер").fill("")

    def expect_support_plan_validation(self) -> None:
        expect(self.page.get_by_label("Дата следующего контакта")).to_have_js_property("validity.valid", False)
        expect(self.page.get_by_label("Ответственный менеджер")).to_have_js_property("validity.valid", False)

    def submit(self) -> None:
        self.page.get_by_role("button", name="Создать заявку").click()
        expect(self.page.locator("h1").filter(has_text="Заявка #")).to_be_visible()

    def create_restructuring(self, data: RestructuringData) -> None:
        self.open_section("Реструктуризация")
        self.fill_common(data.client_name, data.client_id, data.debt_amount, data.overdue_days)
        self.page.get_by_label("Новый график").fill(data.new_payment_schedule)
        self.page.get_by_label("Срок, мес.").fill(data.term_months)
        self.page.get_by_label("Новая ставка, %").fill(data.new_interest_rate)
        self.page.get_by_label("Причина ухудшения платежеспособности").fill(data.hardship_reason)
        self.fill_support_plan(data.support_plan)
        self.submit()

    def create_bankruptcy(self, data: BankruptcyData) -> None:
        self.open_section("Банкротство")
        self.fill_common(data.client_name, data.client_id, data.debt_amount, data.overdue_days)
        self.page.get_by_label("Стадия процесса").fill(data.stage)
        self.page.get_by_label("Судебное дело").fill(data.court_case_number)
        self.page.get_by_label("Активы должника").fill(data.debtor_assets)
        self.page.get_by_label("Юридический риск").fill(data.legal_risk)
        self.submit()

import allure
from playwright.sync_api import expect

from tests.ui.factories.case_data_factory import CaseDataFactory
from tests.ui.pages.case_details_page import CaseDetailsPage
from tests.ui.pages.case_form_page import CaseFormPage


@allure.feature("Проблемные активы")
@allure.story("План сопровождения клиента")
def test_restructuring_support_plan_frontend_only(app):
    form = CaseFormPage(app)
    details = CaseDetailsPage(app)
    data = CaseDataFactory.restructuring()

    form.open_section("Реструктуризация")
    form.expect_support_plan_fields()
    form.clear_required_support_plan_fields()
    form.page.get_by_role("button", name="Создать заявку").click()
    form.expect_support_plan_validation()

    form.fill_common(data.client_name, data.client_id, data.debt_amount, data.overdue_days)
    form.page.get_by_label("Новый график").fill(data.new_payment_schedule)
    form.page.get_by_label("Срок, мес.").fill(data.term_months)
    form.page.get_by_label("Новая ставка, %").fill(data.new_interest_rate)
    form.page.get_by_label("Причина ухудшения платежеспособности").fill(data.hardship_reason)
    form.fill_support_plan(data.support_plan)
    form.submit()

    details.expect_support_plan(data.support_plan)
    details.open_section("Банкротство")
    expect(form.page.get_by_text("План сопровождения клиента")).not_to_be_visible()

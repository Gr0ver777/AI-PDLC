import allure

from tests.ui.factories.case_data_factory import CaseDataFactory
from tests.ui.pages.case_details_page import CaseDetailsPage
from tests.ui.pages.case_form_page import CaseFormPage
from tests.ui.pages.dashboard_page import DashboardPage


@allure.feature("Проблемные активы")
@allure.story("Реструктуризация")
def test_create_restructuring_case(app):
    form = CaseFormPage(app)
    details = CaseDetailsPage(app)

    form.create_restructuring(CaseDataFactory.restructuring())

    details.expect_recommendation()


@allure.feature("Проблемные активы")
@allure.story("Банкротство")
def test_create_bankruptcy_case(app):
    form = CaseFormPage(app)
    details = CaseDetailsPage(app)

    form.create_bankruptcy(CaseDataFactory.bankruptcy())

    details.expect_recommendation()


@allure.feature("Проблемные активы")
@allure.story("Фильтры")
def test_filter_cases_by_module(app):
    form = CaseFormPage(app)
    dashboard = DashboardPage(app)
    data = CaseDataFactory.restructuring()

    form.create_restructuring(data)
    dashboard.open_section("Обзор")
    dashboard.filter_module("Реструктуризация")

    dashboard.expect_case_visible(data.client_name)


@allure.feature("Проблемные активы")
@allure.story("Решение оператора")
def test_escalate_case(app):
    form = CaseFormPage(app)
    details = CaseDetailsPage(app)

    form.create_bankruptcy(CaseDataFactory.bankruptcy())
    details.escalate()

    details.expect_escalated()

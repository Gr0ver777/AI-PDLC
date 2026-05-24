from dataclasses import dataclass
from datetime import date, timedelta


@dataclass(frozen=True)
class SupportPlanData:
    next_contact_date: str = "2026-06-01"
    relationship_manager: str = "Иван Петров"
    contact_channel: str = "Телефон"
    document_package_status: str = "Запрошен"
    support_comment: str = "Согласовать дату звонка и проверить комплектность документов"


@dataclass(frozen=True)
class SlaPlanData:
    processing_deadline: str = (date.today() + timedelta(days=2)).isoformat()
    urgency: str = "Повышенная"
    sla_comment: str = "Проконтролировать контакт до дедлайна"
    expected_status: str = "Под контролем"


@dataclass(frozen=True)
class RestructuringData:
    client_name: str = "ООО Автотест Реструктуризация"
    client_id: str = "7701999001"
    debt_amount: str = "2500000"
    overdue_days: str = "75"
    new_payment_schedule: str = "Ежемесячно равными платежами"
    term_months: str = "18"
    new_interest_rate: str = "11.5"
    hardship_reason: str = "Снижение выручки"
    support_plan: SupportPlanData = SupportPlanData()
    sla_plan: SlaPlanData = SlaPlanData()


@dataclass(frozen=True)
class BankruptcyData:
    client_name: str = "ООО Автотест Банкротство"
    client_id: str = "7701999002"
    debt_amount: str = "6200000"
    overdue_days: str = "210"
    stage: str = "Наблюдение"
    court_case_number: str = "А40-99999/2026"
    debtor_assets: str = "Складской комплекс и дебиторская задолженность"
    legal_risk: str = "Риск недостаточности конкурсной массы"


class CaseDataFactory:
    @staticmethod
    def restructuring() -> RestructuringData:
        return RestructuringData()

    @staticmethod
    def bankruptcy() -> BankruptcyData:
        return BankruptcyData()

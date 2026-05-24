from dataclasses import dataclass


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

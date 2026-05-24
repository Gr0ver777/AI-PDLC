package ru.aipdlc.backend.caseflow;

import org.springframework.stereotype.Service;

import java.math.BigDecimal;

@Service
public class AiAssessmentService {
    public void assess(AssetCase assetCase) {
        int score = 0;
        BigDecimal debt = assetCase.getDebtAmount();

        if (debt.compareTo(BigDecimal.valueOf(5_000_000)) >= 0) {
            score += 3;
        } else if (debt.compareTo(BigDecimal.valueOf(1_000_000)) >= 0) {
            score += 2;
        } else {
            score += 1;
        }

        if (assetCase.getOverdueDays() >= 180) {
            score += 3;
        } else if (assetCase.getOverdueDays() >= 60) {
            score += 2;
        } else {
            score += 1;
        }

        if (!assetCase.isCollateral()) {
            score += 2;
        }
        if (assetCase.getModule() == CaseModule.BANKRUPTCY) {
            score += 2;
        }

        if (score >= 8) {
            assetCase.setRiskLevel(RiskLevel.HIGH);
            assetCase.setPriority(Priority.CRITICAL);
        } else if (score >= 5) {
            assetCase.setRiskLevel(RiskLevel.MEDIUM);
            assetCase.setPriority(Priority.URGENT);
        } else {
            assetCase.setRiskLevel(RiskLevel.LOW);
            assetCase.setPriority(Priority.NORMAL);
        }

        assetCase.setRecommendation(buildRecommendation(assetCase));
    }

    private String buildRecommendation(AssetCase assetCase) {
        if (assetCase.getModule() == CaseModule.RESTRUCTURING) {
            return switch (assetCase.getRiskLevel()) {
                case LOW -> "Рекомендовать реструктуризацию по заявленному графику и перевести заявку на проверку документов.";
                case MEDIUM -> "Запросить подтверждение доходов, проверить обеспечение и согласовать реструктуризацию с риск-менеджером.";
                case HIGH -> "Не утверждать автоматически: эскалировать на кредитный комитет и подготовить альтернативный сценарий взыскания.";
            };
        }

        return switch (assetCase.getRiskLevel()) {
            case LOW -> "Проверить банкротный статус и оценить возможность мирового соглашения.";
            case MEDIUM -> "Передать юристам для анализа активов должника и перспектив включения в реестр требований.";
            case HIGH -> "Срочно эскалировать юридическому блоку, инициировать банкротный сценарий и контроль обеспечительных мер.";
        };
    }
}

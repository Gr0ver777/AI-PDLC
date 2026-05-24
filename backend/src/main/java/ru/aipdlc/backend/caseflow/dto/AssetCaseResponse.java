package ru.aipdlc.backend.caseflow.dto;

import ru.aipdlc.backend.caseflow.AssetCase;
import ru.aipdlc.backend.caseflow.CaseModule;
import ru.aipdlc.backend.caseflow.CaseStatus;
import ru.aipdlc.backend.caseflow.Priority;
import ru.aipdlc.backend.caseflow.RiskLevel;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public record AssetCaseResponse(
        Long id,
        String clientName,
        String clientId,
        BigDecimal debtAmount,
        int overdueDays,
        boolean collateral,
        CaseModule module,
        CaseStatus status,
        RiskLevel riskLevel,
        Priority priority,
        String recommendation,
        Instant createdAt,
        String newPaymentSchedule,
        Integer restructuringTermMonths,
        BigDecimal newInterestRate,
        String hardshipReason,
        String bankruptcyStage,
        String courtCaseNumber,
        String debtorAssets,
        String legalRisk,
        List<String> history
) {
    public static AssetCaseResponse from(AssetCase assetCase) {
        return new AssetCaseResponse(
                assetCase.getId(),
                assetCase.getClientName(),
                assetCase.getClientId(),
                assetCase.getDebtAmount(),
                assetCase.getOverdueDays(),
                assetCase.isCollateral(),
                assetCase.getModule(),
                assetCase.getStatus(),
                assetCase.getRiskLevel(),
                assetCase.getPriority(),
                assetCase.getRecommendation(),
                assetCase.getCreatedAt(),
                assetCase.getNewPaymentSchedule(),
                assetCase.getRestructuringTermMonths(),
                assetCase.getNewInterestRate(),
                assetCase.getHardshipReason(),
                assetCase.getBankruptcyStage(),
                assetCase.getCourtCaseNumber(),
                assetCase.getDebtorAssets(),
                assetCase.getLegalRisk(),
                assetCase.getHistory()
        );
    }
}

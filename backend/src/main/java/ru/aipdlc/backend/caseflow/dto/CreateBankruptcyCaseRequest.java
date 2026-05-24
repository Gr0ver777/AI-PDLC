package ru.aipdlc.backend.caseflow.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;

public record CreateBankruptcyCaseRequest(
        @NotBlank String clientName,
        @NotBlank String clientId,
        @NotNull @Positive BigDecimal debtAmount,
        @PositiveOrZero int overdueDays,
        boolean collateral,
        @NotBlank String bankruptcyStage,
        @NotBlank String courtCaseNumber,
        @NotBlank String debtorAssets,
        @NotBlank String legalRisk
) {
}

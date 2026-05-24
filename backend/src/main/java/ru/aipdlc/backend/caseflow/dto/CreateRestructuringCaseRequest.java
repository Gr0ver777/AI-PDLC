package ru.aipdlc.backend.caseflow.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;

public record CreateRestructuringCaseRequest(
        @NotBlank String clientName,
        @NotBlank String clientId,
        @NotNull @Positive BigDecimal debtAmount,
        @PositiveOrZero int overdueDays,
        boolean collateral,
        @NotBlank String newPaymentSchedule,
        @NotNull @Positive Integer restructuringTermMonths,
        @NotNull @Positive BigDecimal newInterestRate,
        @NotBlank String hardshipReason
) {
}

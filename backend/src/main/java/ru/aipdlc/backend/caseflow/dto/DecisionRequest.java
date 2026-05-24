package ru.aipdlc.backend.caseflow.dto;

import jakarta.validation.constraints.NotNull;
import ru.aipdlc.backend.caseflow.OperatorDecision;

public record DecisionRequest(@NotNull OperatorDecision decision, String comment) {
}

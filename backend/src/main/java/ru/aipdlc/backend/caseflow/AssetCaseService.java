package ru.aipdlc.backend.caseflow;

import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.aipdlc.backend.caseflow.dto.CreateBankruptcyCaseRequest;
import ru.aipdlc.backend.caseflow.dto.CreateRestructuringCaseRequest;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Service
public class AssetCaseService {
    private final AssetCaseRepository repository;
    private final AiAssessmentService aiAssessmentService;

    public AssetCaseService(AssetCaseRepository repository, AiAssessmentService aiAssessmentService) {
        this.repository = repository;
        this.aiAssessmentService = aiAssessmentService;
    }

    @Transactional
    public AssetCase createRestructuring(CreateRestructuringCaseRequest request) {
        AssetCase assetCase = new AssetCase();
        applyCommonFields(assetCase, request.clientName(), request.clientId(), request.debtAmount(), request.overdueDays(), request.collateral());
        assetCase.setModule(CaseModule.RESTRUCTURING);
        assetCase.setNewPaymentSchedule(request.newPaymentSchedule());
        assetCase.setRestructuringTermMonths(request.restructuringTermMonths());
        assetCase.setNewInterestRate(request.newInterestRate());
        assetCase.setHardshipReason(request.hardshipReason());
        return assessAndSave(assetCase, "Создана заявка на реструктуризацию");
    }

    @Transactional
    public AssetCase createBankruptcy(CreateBankruptcyCaseRequest request) {
        AssetCase assetCase = new AssetCase();
        applyCommonFields(assetCase, request.clientName(), request.clientId(), request.debtAmount(), request.overdueDays(), request.collateral());
        assetCase.setModule(CaseModule.BANKRUPTCY);
        assetCase.setBankruptcyStage(request.bankruptcyStage());
        assetCase.setCourtCaseNumber(request.courtCaseNumber());
        assetCase.setDebtorAssets(request.debtorAssets());
        assetCase.setLegalRisk(request.legalRisk());
        return assessAndSave(assetCase, "Создана заявка на банкротство");
    }

    @Transactional(readOnly = true)
    public List<AssetCase> findCases(CaseModule module, CaseStatus status, RiskLevel riskLevel) {
        return repository.findAll(filterBy(module, status, riskLevel));
    }

    @Transactional(readOnly = true)
    public AssetCase getCase(long id) {
        return repository.findById(id).orElseThrow(() -> new CaseNotFoundException(id));
    }

    @Transactional
    public AssetCase applyDecision(long id, OperatorDecision decision, String comment) {
        AssetCase assetCase = getCase(id);
        CaseStatus nextStatus = switch (decision) {
            case APPROVE -> CaseStatus.APPROVED;
            case REQUEST_INFO -> CaseStatus.NEEDS_MORE_INFO;
            case ESCALATE -> CaseStatus.ESCALATED;
        };
        assetCase.setStatus(nextStatus);
        String suffix = comment == null || comment.isBlank() ? "" : ": " + comment;
        assetCase.getHistory().add(Instant.now() + " | Решение оператора " + decision + suffix);
        return repository.save(assetCase);
    }

    private void applyCommonFields(AssetCase assetCase, String clientName, String clientId, java.math.BigDecimal debtAmount, int overdueDays, boolean collateral) {
        assetCase.setClientName(clientName);
        assetCase.setClientId(clientId);
        assetCase.setDebtAmount(debtAmount);
        assetCase.setOverdueDays(overdueDays);
        assetCase.setCollateral(collateral);
        assetCase.setStatus(CaseStatus.IN_REVIEW);
    }

    private AssetCase assessAndSave(AssetCase assetCase, String event) {
        aiAssessmentService.assess(assetCase);
        assetCase.getHistory().add(Instant.now() + " | " + event);
        assetCase.getHistory().add(Instant.now() + " | AI assessment: " + assetCase.getRiskLevel() + ", " + assetCase.getPriority());
        return repository.save(assetCase);
    }

    private Specification<AssetCase> filterBy(CaseModule module, CaseStatus status, RiskLevel riskLevel) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            if (module != null) {
                predicates.add(cb.equal(root.get("module"), module));
            }
            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }
            if (riskLevel != null) {
                predicates.add(cb.equal(root.get("riskLevel"), riskLevel));
            }
            return cb.and(predicates.toArray(Predicate[]::new));
        };
    }
}

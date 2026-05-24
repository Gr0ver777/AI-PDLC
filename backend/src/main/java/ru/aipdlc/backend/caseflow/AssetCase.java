package ru.aipdlc.backend.caseflow;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "asset_cases")
public class AssetCase {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    private String clientName;

    @NotBlank
    private String clientId;

    @NotNull
    @Positive
    private BigDecimal debtAmount;

    @PositiveOrZero
    private int overdueDays;

    private boolean collateral;

    @Enumerated(EnumType.STRING)
    private CaseModule module;

    @Enumerated(EnumType.STRING)
    private CaseStatus status = CaseStatus.NEW;

    @Enumerated(EnumType.STRING)
    private RiskLevel riskLevel = RiskLevel.LOW;

    @Enumerated(EnumType.STRING)
    private Priority priority = Priority.NORMAL;

    @Column(length = 1200)
    private String recommendation;

    private Instant createdAt = Instant.now();

    private String newPaymentSchedule;
    private Integer restructuringTermMonths;
    private BigDecimal newInterestRate;
    @Column(length = 800)
    private String hardshipReason;

    private String bankruptcyStage;
    private String courtCaseNumber;
    @Column(length = 800)
    private String debtorAssets;
    @Column(length = 800)
    private String legalRisk;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "case_history", joinColumns = @JoinColumn(name = "case_id"))
    @Column(name = "event", length = 1000)
    private List<String> history = new ArrayList<>();

    public Long getId() {
        return id;
    }

    public String getClientName() {
        return clientName;
    }

    public void setClientName(String clientName) {
        this.clientName = clientName;
    }

    public String getClientId() {
        return clientId;
    }

    public void setClientId(String clientId) {
        this.clientId = clientId;
    }

    public BigDecimal getDebtAmount() {
        return debtAmount;
    }

    public void setDebtAmount(BigDecimal debtAmount) {
        this.debtAmount = debtAmount;
    }

    public int getOverdueDays() {
        return overdueDays;
    }

    public void setOverdueDays(int overdueDays) {
        this.overdueDays = overdueDays;
    }

    public boolean isCollateral() {
        return collateral;
    }

    public void setCollateral(boolean collateral) {
        this.collateral = collateral;
    }

    public CaseModule getModule() {
        return module;
    }

    public void setModule(CaseModule module) {
        this.module = module;
    }

    public CaseStatus getStatus() {
        return status;
    }

    public void setStatus(CaseStatus status) {
        this.status = status;
    }

    public RiskLevel getRiskLevel() {
        return riskLevel;
    }

    public void setRiskLevel(RiskLevel riskLevel) {
        this.riskLevel = riskLevel;
    }

    public Priority getPriority() {
        return priority;
    }

    public void setPriority(Priority priority) {
        this.priority = priority;
    }

    public String getRecommendation() {
        return recommendation;
    }

    public void setRecommendation(String recommendation) {
        this.recommendation = recommendation;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public String getNewPaymentSchedule() {
        return newPaymentSchedule;
    }

    public void setNewPaymentSchedule(String newPaymentSchedule) {
        this.newPaymentSchedule = newPaymentSchedule;
    }

    public Integer getRestructuringTermMonths() {
        return restructuringTermMonths;
    }

    public void setRestructuringTermMonths(Integer restructuringTermMonths) {
        this.restructuringTermMonths = restructuringTermMonths;
    }

    public BigDecimal getNewInterestRate() {
        return newInterestRate;
    }

    public void setNewInterestRate(BigDecimal newInterestRate) {
        this.newInterestRate = newInterestRate;
    }

    public String getHardshipReason() {
        return hardshipReason;
    }

    public void setHardshipReason(String hardshipReason) {
        this.hardshipReason = hardshipReason;
    }

    public String getBankruptcyStage() {
        return bankruptcyStage;
    }

    public void setBankruptcyStage(String bankruptcyStage) {
        this.bankruptcyStage = bankruptcyStage;
    }

    public String getCourtCaseNumber() {
        return courtCaseNumber;
    }

    public void setCourtCaseNumber(String courtCaseNumber) {
        this.courtCaseNumber = courtCaseNumber;
    }

    public String getDebtorAssets() {
        return debtorAssets;
    }

    public void setDebtorAssets(String debtorAssets) {
        this.debtorAssets = debtorAssets;
    }

    public String getLegalRisk() {
        return legalRisk;
    }

    public void setLegalRisk(String legalRisk) {
        this.legalRisk = legalRisk;
    }

    public List<String> getHistory() {
        return history;
    }
}

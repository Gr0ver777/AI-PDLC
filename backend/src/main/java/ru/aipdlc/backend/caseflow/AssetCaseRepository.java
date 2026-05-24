package ru.aipdlc.backend.caseflow;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface AssetCaseRepository extends JpaRepository<AssetCase, Long>, JpaSpecificationExecutor<AssetCase> {
}

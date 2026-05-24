package ru.aipdlc.backend.caseflow;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import ru.aipdlc.backend.caseflow.dto.AssetCaseResponse;
import ru.aipdlc.backend.caseflow.dto.CreateBankruptcyCaseRequest;
import ru.aipdlc.backend.caseflow.dto.CreateRestructuringCaseRequest;
import ru.aipdlc.backend.caseflow.dto.DecisionRequest;

import java.util.List;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = {"http://localhost:5173", "http://127.0.0.1:5173"})
public class AssetCaseController {
    private final AssetCaseService service;

    public AssetCaseController(AssetCaseService service) {
        this.service = service;
    }

    @PostMapping("/restructuring-cases")
    @ResponseStatus(HttpStatus.CREATED)
    public AssetCaseResponse createRestructuring(@Valid @RequestBody CreateRestructuringCaseRequest request) {
        return AssetCaseResponse.from(service.createRestructuring(request));
    }

    @PostMapping("/bankruptcy-cases")
    @ResponseStatus(HttpStatus.CREATED)
    public AssetCaseResponse createBankruptcy(@Valid @RequestBody CreateBankruptcyCaseRequest request) {
        return AssetCaseResponse.from(service.createBankruptcy(request));
    }

    @GetMapping("/cases")
    public List<AssetCaseResponse> listCases(
            @RequestParam(required = false) CaseModule module,
            @RequestParam(required = false) CaseStatus status,
            @RequestParam(required = false) RiskLevel riskLevel
    ) {
        return service.findCases(module, status, riskLevel).stream()
                .map(AssetCaseResponse::from)
                .toList();
    }

    @GetMapping("/cases/{id}")
    public AssetCaseResponse getCase(@PathVariable long id) {
        return AssetCaseResponse.from(service.getCase(id));
    }

    @PostMapping("/cases/{id}/decision")
    public AssetCaseResponse decide(@PathVariable long id, @Valid @RequestBody DecisionRequest request) {
        return AssetCaseResponse.from(service.applyDecision(id, request.decision(), request.comment()));
    }
}

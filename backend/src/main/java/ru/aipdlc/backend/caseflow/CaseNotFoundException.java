package ru.aipdlc.backend.caseflow;

public class CaseNotFoundException extends RuntimeException {
    public CaseNotFoundException(long id) {
        super("Заявка " + id + " не найдена");
    }
}

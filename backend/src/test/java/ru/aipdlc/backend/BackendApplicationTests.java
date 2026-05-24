package ru.aipdlc.backend;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class BackendApplicationTests {
    @Autowired
    MockMvc mockMvc;

    @Test
    void contextLoads() {
    }

    @Test
    void createsRestructuringCase() throws Exception {
        String body = """
                {
                  "clientName": "ООО Север",
                  "clientId": "7701000011",
                  "debtAmount": 2500000,
                  "overdueDays": 75,
                  "collateral": true,
                  "newPaymentSchedule": "Ежемесячно равными платежами",
                  "restructuringTermMonths": 18,
                  "newInterestRate": 11.5,
                  "hardshipReason": "Снижение выручки"
                }
                """;

        mockMvc.perform(post("/api/restructuring-cases")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.module").value("RESTRUCTURING"))
                .andExpect(jsonPath("$.riskLevel").value("MEDIUM"));
    }
}

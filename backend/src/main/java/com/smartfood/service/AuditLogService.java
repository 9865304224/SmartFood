package com.smartfood.service;

import com.smartfood.model.AuditLog;
import com.smartfood.repository.AuditLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuditLogService {

    private final AuditLogRepository auditLogRepository;

    public void logAction(String adminId, String adminEmail, String action, String targetResource, String targetId, String details, String ipAddress) {
        AuditLog auditLog = AuditLog.builder()
                .adminId(adminId)
                .adminEmail(adminEmail)
                .action(action)
                .targetResource(targetResource)
                .targetId(targetId)
                .details(details)
                .ipAddress(ipAddress != null ? ipAddress : "127.0.0.1")
                .timestamp(Instant.now())
                .build();

        auditLogRepository.save(auditLog);
        log.info("AUDIT LOG: [Admin: {}] performed [{}] on [{}:{}] - Details: {}", adminEmail, action, targetResource, targetId, details);
    }

    public List<AuditLog> getRecentLogs() {
        return auditLogRepository.findByOrderByTimestampDesc();
    }
}

package com.smartfood.service;

import com.smartfood.model.Notification;
import com.smartfood.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final SimpMessagingTemplate messagingTemplate;

    @Value("${smartfood.fcm.enabled:false}")
    private boolean fcmEnabled;

    public Notification sendNotification(String userId, String title, String message, String type) {
        return sendNotification(userId, title, message, type, Map.of());
    }

    public Notification sendNotification(String userId, String title, String message, String type, Map<String, String> data) {
        Notification notification = Notification.builder()
                .userId(userId)
                .title(title)
                .message(message)
                .type(type)
                .data(data)
                .isRead(false)
                .build();

        notification = notificationRepository.save(notification);

        // Send via WebSocket to user's real-time topic
        try {
            messagingTemplate.convertAndSend("/topic/users/" + userId + "/notifications", notification);
        } catch (Exception ex) {
            log.error("Failed to dispatch WebSocket notification: ", ex);
        }

        if (fcmEnabled) {
            log.info("Dispatching FCM push to user {}: {} - {}", userId, title, message);
        } else {
            log.debug("FCM disabled. In-app & WebSocket notification saved for user {}: {}", userId, title);
        }

        return notification;
    }

    public List<Notification> getUserNotifications(String userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public void markAsRead(String notificationId) {
        notificationRepository.findById(notificationId).ifPresent(n -> {
            n.setRead(true);
            notificationRepository.save(n);
        });
    }
}

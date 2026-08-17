package com.smartfood.service;

import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmailService {

    @Autowired(required = false)
    private JavaMailSender mailSender;

    @Value("${spring.mail.username:}")
    private String mailUsername;

    public boolean sendRegistrationOtp(String toEmail, String fullName, String otp) {
        String subject = "SmartFood - Verify Your Email & Complete Registration";
        String htmlContent = buildOtpHtml(
                "Welcome to SmartFood!",
                "Hello " + (fullName != null && !fullName.isBlank() ? fullName : "Food Lover") + ",",
                "Thank you for registering on SmartFood. Please use the 6-digit verification code below to verify your email address and activate your account.",
                otp,
                "This code will expire in 15 minutes. If you did not request this registration, please ignore this email."
        );

        return sendHtmlEmail(toEmail, subject, htmlContent, otp);
    }

    public boolean sendPasswordResetOtp(String toEmail, String fullName, String otp) {
        String subject = "SmartFood - Reset Your Password";
        String htmlContent = buildOtpHtml(
                "Password Reset Request",
                "Hello " + (fullName != null && !fullName.isBlank() ? fullName : "User") + ",",
                "We received a request to reset the password for your SmartFood account. Enter the verification code below to set a new password.",
                otp,
                "This code will expire in 15 minutes. If you did not make this request, please change your credentials immediately or contact support."
        );

        return sendHtmlEmail(toEmail, subject, htmlContent, otp);
    }

    private boolean sendHtmlEmail(String toEmail, String subject, String htmlContent, String otp) {
        log.info("=================================================================");
        log.info("📧 [SMARTFOOD EMAIL OTP DISPATCH]");
        log.info("To: {}", toEmail);
        log.info("Subject: {}", subject);
        log.info(">>> VERIFICATION OTP CODE: {} <<<", otp);
        log.info("=================================================================");

        if (mailSender == null || mailUsername == null || mailUsername.isBlank()) {
            log.warn("JavaMailSender is not fully configured (MAIL_USERNAME empty). OTP logged to console for development/demo.");
            return true;
        }

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(mailUsername, "SmartFood Support");
            helper.setTo(toEmail);
            helper.setSubject(subject);
            helper.setText(htmlContent, true);

            mailSender.send(message);
            log.info("Email successfully delivered to {}", toEmail);
            return true;
        } catch (Exception e) {
            log.error("Failed to deliver email to {} via SMTP: {}. (OTP is logged above for testing)", toEmail, e.getMessage());
            return true; // Still allow testing flow without hard failure
        }
    }

    private String buildOtpHtml(String title, String greeting, String message, String otp, String footerNote) {
        String template = """
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="UTF-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <style>
                body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #0F172A; margin: 0; padding: 20px; color: #E2E8F0; }
                .container { max-width: 540px; margin: 0 auto; background-color: #1E293B; border-radius: 16px; border: 1px solid #334155; overflow: hidden; box-shadow: 0 10px 25px rgba(0,0,0,0.5); }
                .header { background: linear-gradient(135deg, #F97316 0%, #EA580C 100%); padding: 24px; text-align: center; }
                .header h1 { margin: 0; color: #FFFFFF; font-size: 24px; font-weight: 800; letter-spacing: -0.5px; }
                .header p { margin: 4px 0 0; color: #FED7AA; font-size: 13px; font-weight: 500; }
                .body { padding: 32px 28px; }
                .greeting { font-size: 16px; font-weight: 600; color: #F8FAFC; margin-bottom: 12px; }
                .text { font-size: 14px; line-height: 1.6; color: #94A3B8; margin-bottom: 24px; }
                .otp-box { background: #0F172A; border: 2px dashed #F97316; border-radius: 12px; padding: 20px; text-align: center; margin: 24px 0; }
                .otp-code { font-size: 36px; font-weight: 800; letter-spacing: 8px; color: #FB923C; margin: 0; font-family: monospace; }
                .otp-subtext { font-size: 12px; color: #64748B; margin-top: 6px; }
                .footer { padding: 20px; text-align: center; font-size: 11px; color: #64748B; border-top: 1px solid #334155; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="header">
                  <h1>SmartFood</h1>
                  <p>Next-Gen AI Food Delivery</p>
                </div>
                <div class="body">
                  <div class="greeting">__GREETING__</div>
                  <div class="text">__MESSAGE__</div>
                  <div class="otp-box">
                    <p style="margin:0; font-size:12px; color:#94A3B8; text-transform:uppercase; letter-spacing:1px; font-weight:700;">Verification Code</p>
                    <div class="otp-code">__OTP__</div>
                    <div class="otp-subtext">Valid for 15 minutes</div>
                  </div>
                  <div class="text" style="font-size:12px; color:#64748B;">__FOOTER_NOTE__</div>
                </div>
                <div class="footer">
                  © SmartFood Inc. All rights reserved. &bull; Secure Authentication
                </div>
              </div>
            </body>
            </html>
            """;

        return template
                .replace("__GREETING__", greeting != null ? greeting : "")
                .replace("__MESSAGE__", message != null ? message : "")
                .replace("__OTP__", otp != null ? otp : "")
                .replace("__FOOTER_NOTE__", footerNote != null ? footerNote : "");
    }
}

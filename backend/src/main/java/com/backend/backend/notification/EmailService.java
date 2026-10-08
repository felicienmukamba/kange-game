package com.backend.backend.notification;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

/** Sends transactional email when SMTP is configured (spring.mail.host); otherwise a no-op. */
@Service
@Slf4j
public class EmailService {

    private final ObjectProvider<JavaMailSender> mailSender;

    public EmailService(ObjectProvider<JavaMailSender> mailSender) {
        this.mailSender = mailSender;
    }

    @Async
    public void sendWelcomeEmail(String to, String username) {
        JavaMailSender sender = mailSender.getIfAvailable();
        if (sender == null) return;

        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(to);
        message.setSubject("Welcome to REWIFY!");
        message.setText("Hi " + username + ",\n\nWelcome to the ultimate social gaming platform. Ready to win?");
        try {
            sender.send(message);
        } catch (Exception ex) {
            log.warn("Could not send welcome email to {}: {}", to, ex.getMessage());
        }
    }
}

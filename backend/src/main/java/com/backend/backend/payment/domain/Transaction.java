package com.backend.backend.payment.domain;

import com.backend.backend.core.domain.User;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "transactions")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Transaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;

    private Long amount;

    private String type; // CREDIT, DEBIT, DONATION

    private String status; // PENDING, COMPLETED, FAILED

    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}

package com.backend.backend.payment;

import com.backend.backend.core.domain.User;
import com.backend.backend.core.repository.UserRepository;
import com.backend.backend.payment.domain.Transaction;
import com.backend.backend.payment.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class WalletService {

    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;

    @Transactional
    public void processTransaction(String username, Long amount, String type) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if ("DEBIT".equals(type) && user.getCoins() < Math.abs(amount)) {
            throw new RuntimeException("Insufficient balance");
        }

        user.setCoins(user.getCoins() + amount);
        userRepository.save(user);

        Transaction transaction = Transaction.builder()
                .user(user)
                .amount(amount)
                .type(type)
                .status("COMPLETED")
                .build();
        transactionRepository.save(transaction);
    }
}

package com.backend.backend.payment;

import com.backend.backend.core.domain.User;
import com.backend.backend.core.exception.ApiException;
import com.backend.backend.core.repository.UserRepository;
import com.backend.backend.payment.domain.Transaction;
import com.backend.backend.payment.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class WalletService {

    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;

    /**
     * Applies a signed coin amount to the user's balance and records it.
     * Negative amounts are debits and fail if the balance is insufficient.
     */
    @Transactional
    public User processTransaction(String username, long amount, String type) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> ApiException.notFound("User not found"));

        if (amount < 0 && user.getCoins() < -amount) {
            throw new ApiException(HttpStatus.PAYMENT_REQUIRED, "Insufficient balance");
        }

        user.setCoins(user.getCoins() + amount);
        userRepository.save(user);

        transactionRepository.save(Transaction.builder()
                .user(user)
                .amount(amount)
                .type(type)
                .status("COMPLETED")
                .build());
        return user;
    }
}

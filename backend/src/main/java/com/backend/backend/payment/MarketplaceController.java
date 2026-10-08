package com.backend.backend.payment;

import com.backend.backend.core.domain.User;
import com.backend.backend.core.dto.UserProfile;
import com.backend.backend.core.exception.ApiException;
import com.backend.backend.payment.domain.InventoryItem;
import com.backend.backend.payment.domain.MarketplaceItem;
import com.backend.backend.payment.repository.InventoryItemRepository;
import com.backend.backend.payment.repository.MarketplaceItemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/marketplace")
@RequiredArgsConstructor
public class MarketplaceController {

    private final MarketplaceItemRepository repository;
    private final InventoryItemRepository inventoryRepository;
    private final WalletService walletService;

    @GetMapping("/items")
    public ResponseEntity<List<MarketplaceItem>> getItems() {
        return ResponseEntity.ok(repository.findAll());
    }

    @GetMapping("/inventory")
    public ResponseEntity<List<InventoryItem>> getInventory(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(inventoryRepository.findByUserIdOrderByAcquiredAtDesc(user.getId()));
    }

    @PostMapping("/purchase/{itemId}")
    @Transactional
    public ResponseEntity<UserProfile> purchaseItem(
            @PathVariable Long itemId,
            @AuthenticationPrincipal User principal
    ) {
        MarketplaceItem item = repository.findById(itemId)
                .orElseThrow(() -> ApiException.notFound("Item not found"));
        if (inventoryRepository.existsByUserIdAndItemId(principal.getId(), itemId)) {
            throw ApiException.conflict("You already own " + item.getName());
        }

        User user = walletService.processTransaction(principal.getUsername(), -item.getPrice(), "PURCHASE");
        inventoryRepository.save(InventoryItem.builder().user(user).item(item).build());
        return ResponseEntity.ok(UserProfile.of(user));
    }
}

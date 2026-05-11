package com.backend.backend.payment;

import com.backend.backend.payment.domain.MarketplaceItem;
import com.backend.backend.payment.repository.MarketplaceItemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/marketplace")
@RequiredArgsConstructor
public class MarketplaceController {

    private final MarketplaceItemRepository repository;
    private final WalletService walletService;

    @GetMapping("/items")
    public ResponseEntity<List<MarketplaceItem>> getItems() {
        return ResponseEntity.ok(repository.findAll());
    }

    @PostMapping("/purchase/{itemId}")
    public ResponseEntity<String> purchaseItem(
            @PathVariable Long itemId,
            Authentication authentication
    ) {
        MarketplaceItem item = repository.findById(itemId)
                .orElseThrow(() -> new RuntimeException("Item not found"));
        
        walletService.processTransaction(authentication.getName(), -item.getPrice(), "PURCHASE");
        
        // Logic to grant the item to the user would go here (e.g. UserInventory)
        return ResponseEntity.ok("Purchase successful");
    }
}

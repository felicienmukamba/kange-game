package com.backend.backend.payment.repository;

import com.backend.backend.payment.domain.InventoryItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface InventoryItemRepository extends JpaRepository<InventoryItem, Long> {
    List<InventoryItem> findByUserIdOrderByAcquiredAtDesc(Long userId);
    boolean existsByUserIdAndItemId(Long userId, Long itemId);
}

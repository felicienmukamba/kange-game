package com.backend.backend.payment.repository;

import com.backend.backend.payment.domain.MarketplaceItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface MarketplaceItemRepository extends JpaRepository<MarketplaceItem, Long> {
}

package com.backend.backend.payment.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "marketplace_items")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MarketplaceItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String description;
    private Long price;
    private String type; // SKIN, AVATAR, BOOST
    private String imageUrl;
}

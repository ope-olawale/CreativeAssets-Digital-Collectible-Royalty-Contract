# Creative Assets Digital Collectible Royalty Contract

A comprehensive Stacks blockchain smart contract for minting, trading, and managing NFTs with built-in creator royalty distribution and marketplace functionality.

## Overview

This contract enables creators to mint digital assets as NFTs with automatic royalty payments on secondary sales. It includes a built-in marketplace for listing and trading assets while ensuring original creators receive ongoing compensation.

## Key Features

### 🎨 Asset Creation
- **Individual Minting**: Create single digital assets with custom metadata and royalty rates
- **Bulk Minting**: Create multiple assets in a single transaction (up to 10 assets)
- **Royalty Protection**: Maximum 50% royalty rate cap to prevent exploitation
- **Metadata Storage**: Store up to 256 UTF-8 characters of asset information

### 💰 Royalty System
- **Automatic Distribution**: Creator fees are automatically distributed on transfers
- **Perpetual Payments**: Original creators receive royalties on all secondary sales
- **Transparent Rates**: Royalty percentages are permanently stored and publicly viewable

### 🛒 Built-in Marketplace
- **Asset Listings**: Owners can list assets for sale with custom pricing
- **Sale Management**: Easy listing and delisting functionality
- **Ownership Verification**: Only asset owners can list their items

### 🔐 Access Control
- **Owner Authorization**: Only asset owners can authorize handlers
- **Transfer Permissions**: Flexible authorization system for delegated operations
- **Admin Functions**: Contract admin controls for system management

## Core Functions

### Asset Creation
```clarity
;; Create a single asset
(create-asset (asset-info (string-utf8 256)) (creator-fee-rate uint))

;; Create multiple assets at once
(bulk-create (info-list (list 10 (string-utf8 256))) (fee-rates (list 10 uint)))
```

### Marketplace Operations
```clarity
;; List asset for sale
(put-for-sale (asset-id uint) (offer-price uint))

;; Remove from marketplace
(remove-from-sale (asset-id uint))
```

### Transfer & Royalties
```clarity
;; Transfer with automatic royalty distribution
(transfer-asset (asset-id uint) (current-owner principal) (new-owner principal))
```

### Authorization
```clarity
;; Authorize a handler for asset operations
(authorize-handler (asset-id uint) (authorized-handler (optional principal)))
```

## Read-Only Functions

### Asset Information
- `get-creator-fee-info`: Get royalty rate and creator details for an asset
- `get-collection-count`: Total number of minted assets
- `get-asset-owner`: Current owner of a specific asset
- `get-sale-details`: Marketplace listing information

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `error-admin-required` | Action requires admin/owner permissions |
| u101 | `error-balance-insufficient` | Insufficient STX balance for transaction |
| u102 | `error-royalty-invalid` | Royalty rate exceeds maximum (50%) |
| u103 | `error-unauthorized-action` | User not authorized for this action |
| u104 | `error-asset-missing` | Asset ID does not exist |

## Usage Examples

### Creating Your First Asset
```clarity
;; Create an asset with 5% royalty
(contract-call? .creative-assets-contract create-asset 
  "My Digital Artwork - Limited Edition #1" 
  u5)
```

### Listing an Asset for Sale
```clarity
;; List asset #1 for 1000 microSTX
(contract-call? .creative-assets-contract put-for-sale u1 u1000)
```

### Bulk Asset Creation
```clarity
;; Create 3 assets with different royalty rates
(contract-call? .creative-assets-contract bulk-create 
  (list "Art #1" "Art #2" "Art #3")
  (list u5 u10 u15))
```

## Security Features

- **Ownership Verification**: All operations verify caller permissions
- **Royalty Caps**: Maximum 50% royalty prevents abuse
- **Safe Transfers**: Built-in checks prevent invalid transfers
- **Authorization System**: Flexible permission management

## Technical Requirements

- **Blockchain**: Stacks 2.0+
- **Language**: Clarity
- **Dependencies**: None (uses native Stacks functions)

## Contract Deployment

Deploy this contract to the Stacks blockchain using your preferred deployment method. The deploying address becomes the contract admin with special privileges.

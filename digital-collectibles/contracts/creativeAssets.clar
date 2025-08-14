;; Creative Assets Digital Collectible Royalty Contract

(define-constant admin-address tx-sender)
(define-constant error-admin-required (err u100))
(define-constant error-balance-insufficient (err u101))
(define-constant error-royalty-invalid (err u102))
(define-constant error-unauthorized-action (err u103))
(define-constant error-asset-missing (err u104))

;; Digital collectible trait implementation
(define-non-fungible-token creative-asset uint)

(define-constant ERROR-ITEM-UNAVAILABLE (err u103))
(define-constant ERROR-ADMIN-REQUIRED (err u100))
(define-constant ERROR-PRICE-INVALID (err u104))

;; Storage for tracking creator fees and asset details
(define-map creator-fee-data 
  { asset-id: uint }
  { 
    fee-rate: uint, 
    original-creator: principal, 
    asset-info: (string-utf8 256)
  }
)

;; Authorization mapping for asset transfers
(define-map asset-permissions 
  { asset-id: uint }
  { authorized-handler: (optional principal) }
)

;; Store total number of created assets
(define-data-var collection-size uint u0)

;; Create a new digital asset with enhanced details and creator fee
(define-public (create-asset 
  (asset-info (string-utf8 256)) 
  (creator-fee-rate uint)
)
  (begin
    ;; Validate creator fee rate (max 50%)
    (asserts! (< creator-fee-rate u50) error-royalty-invalid)

    ;; Increment collection size
    (var-set collection-size (+ (var-get collection-size) u1))
    (let 
      ((next-asset-id (var-get collection-size)))
      ;; Create the digital asset for the sender
      (try! (nft-mint? creative-asset next-asset-id tx-sender))

      ;; Store creator fee and asset information
      (map-set creator-fee-data 
        { asset-id: next-asset-id }
        { 
          fee-rate: creator-fee-rate, 
          original-creator: tx-sender,
          asset-info: asset-info
        }
      )

      (ok next-asset-id)
    )
  )
)

;; Authorize a handler for a specific asset
(define-public (authorize-handler 
  (asset-id uint)
  (authorized-handler (optional principal))
)
  (begin
    ;; Ensure only asset owner can authorize
    (asserts! 
      (is-eq tx-sender (unwrap-panic (nft-get-owner? creative-asset asset-id))) 
      error-admin-required
    )

    ;; Set authorization
    (map-set asset-permissions 
      { asset-id: asset-id }
      { authorized-handler: authorized-handler }
    )

    (ok true)
  )
)

;; Check if action is authorized
(define-private (is-action-authorized (asset-id uint) (handler principal))
  (match (map-get? asset-permissions { asset-id: asset-id })
    permission 
      (or
        (is-eq (get authorized-handler permission) (some handler))
        (is-eq handler tx-sender)
      )
    true  ;; Default to true if no specific authorization set
  )
)

;; Dynamic market value calculation (placeholder)
(define-private (get-market-value (asset-id uint))
  ;; In a real implementation, this would fetch from an external oracle or marketplace
  ;; For now, we'll use a base value with some variation
  (let 
    ((base-value u1000))
    (+ base-value (* asset-id u10))
  )
)

;; Bulk creation for multiple digital assets
(define-public (bulk-create 
  (info-list (list 10 (string-utf8 256)))
  (fee-rates (list 10 uint))
)
  (let 
    ((created-assets 
      (map create-individual-asset 
        info-list 
        fee-rates
      )
    ))
    (ok created-assets)
  )
)

;; Helper function for bulk creation
(define-private (create-individual-asset 
  (asset-info (string-utf8 256))
  (creator-fee-rate uint)
)
  (let 
    ((result (create-asset asset-info creator-fee-rate)))
    (unwrap-panic result)
  )
)

;; View functions for creator fee and asset information
(define-read-only (get-creator-fee-info (asset-id uint))
  (map-get? creator-fee-data { asset-id: asset-id })
)

(define-read-only (get-collection-count)
  (var-get collection-size)
)

(define-read-only (get-asset-owner (asset-id uint))
  (nft-get-owner? creative-asset asset-id)
)

;; Retrieve Sale Details
(define-read-only (get-sale-details (asset-id uint))
  (map-get? marketplace-offers { asset-id: asset-id })
)


;; Transfer function with creator fee distribution
(define-public (transfer-asset 
  (asset-id uint)
  (current-owner principal)
  (new-owner principal)
)
  (let 
    (
      ;; Get creator fee information
      (fee-info 
        (unwrap! 
          (map-get? creator-fee-data { asset-id: asset-id }) 
          (err u404)
        )
      )

      ;; Calculate fee amount (assuming transaction price is passed externally)
      (transaction-price (get-recent-sale-price asset-id))
      (creator-fee-amount 
        (/ (* transaction-price (get fee-rate fee-info)) u100)
      )
      (original-creator (get original-creator fee-info))
    )

    ;; Ensure only current owner can transfer
    (asserts! (is-eq current-owner (unwrap-panic (nft-get-owner? creative-asset asset-id))) error-admin-required)

    ;; Transfer creator fee to original creator
    (and (> creator-fee-amount u0)
      (try! (stx-transfer? creator-fee-amount current-owner original-creator))
    )

    ;; Standard digital asset transfer
    (try! (nft-transfer? creative-asset asset-id current-owner new-owner))

    (ok true)
  )
)
;; Get the recent sale price (placeholder - would be implemented with external oracle)
(define-private (get-recent-sale-price (asset-id uint))
  ;; In a real implementation, this would fetch from an oracle or marketplace
  (default-to u1000 (some u1000))
)


;; Marketplace Offers Storage
(define-map marketplace-offers 
  { asset-id: uint }
  { 
    vendor: principal, 
    offer-price: uint, 
    available: bool 
  }
)



;; ;; ;; Remove Asset from Sale
(define-public (remove-from-sale (asset-id uint))
  (let 
    ((sale-info (unwrap! 
      (map-get? marketplace-offers { asset-id: asset-id }) 
      ERROR-ITEM-UNAVAILABLE))
    )
    (asserts! 
      (is-eq tx-sender (get vendor sale-info)) 
      ERROR-ADMIN-REQUIRED
    )

    (map-set marketplace-offers 
      { asset-id: asset-id }
      { 
        vendor: tx-sender, 
        offer-price: u0, 
        available: false 
      }
    )

    (ok true)
  )
)


;; Put Asset for Sale
(define-public (put-for-sale 
  (asset-id uint)
  (offer-price uint)
)
  (begin
    (asserts! 
      (is-eq tx-sender (unwrap-panic (nft-get-owner? creative-asset asset-id))) 
      ERROR-ADMIN-REQUIRED
    )
    (asserts! (> offer-price u0) ERROR-PRICE-INVALID)

    (map-set marketplace-offers 
      { asset-id: asset-id }
      { 
        vendor: tx-sender, 
        offer-price: offer-price, 
        available: true 
      }
    )

    (ok true)
  )
)
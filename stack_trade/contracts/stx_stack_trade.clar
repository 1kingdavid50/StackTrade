;; Digital Asset Exchange Smart Contract
;; Facilitates peer-to-peer trading of digital content on Stacks blockchain

;; Contract configuration
(define-constant owner-address tx-sender)
(define-constant ERR_UNAUTHORIZED (err u201))
(define-constant ERR_ITEM_UNAVAILABLE (err u202))
(define-constant ERR_DUPLICATE_ITEM (err u203))
(define-constant ERR_INSUFFICIENT_FUNDS (err u204))
(define-constant ERR_SELF_TRADE_BLOCKED (err u205))
(define-constant ERR_PRICE_INVALID (err u206))
(define-constant ERR_INPUT_INVALID (err u207))
;; No need for block height error since we're using a constant
(define-constant ERR_BLOCK_HEIGHT (err u208))

;; Storage structures
(define-map content-offerings 
    { item-id: uint }
    {
        owner: principal,
        price-tag: uint,
        content-summary: (string-ascii 256),
        content-type: (string-ascii 64),
        tradeable: bool,
        creation-block: uint
    }
)

(define-map trader-metrics
    { participant: principal }
    {
        trade-count: uint,
        quality-score: uint,
        last-active: uint
    }
)

(define-map exchange-records
    { customer: principal, item-id: uint }
    {
        timestamp: uint,
        cost: uint,
        merchant: principal
    }
)

(define-map content-keys
    { item-id: uint }
    { secure-access-token: (string-ascii 512) }
)

;; State variables
(define-data-var item-counter uint u1)
(define-data-var exchange-fee uint u3) ;; 3% fee
(define-data-var exchange-volume uint u0)

;; Since block-height and get-block-info? aren't available in this Clarinet version,
;; we'll use a mock block height function that returns u0 for testing purposes
(define-private (get-current-block-height)
    u0
)

;; Input validators
(define-private (verify-summary (text (string-ascii 256)))
    (and 
        (not (is-eq text ""))
        (<= (len text) u256)
    )
)

(define-private (verify-type (text (string-ascii 64)))
    (and
        (not (is-eq text ""))
        (<= (len text) u64)
    )
)

(define-private (verify-token (text (string-ascii 512)))
    (and
        (not (is-eq text ""))
        (<= (len text) u512)
    )
)

;; Helper functions
(define-private (compute-fee (price uint))
    (/ (* price (var-get exchange-fee)) u100)
)

(define-private (process-payment (from principal) (to principal) (amount uint))
    (stx-transfer? amount from to)
)

;; List digital content
(define-public (register-content (asking-price uint) 
                               (summary (string-ascii 256)) 
                               (content-type (string-ascii 64)) 
                               (access-token (string-ascii 512)))
    (let
        (
            (current-id (var-get item-counter))
            (current-block (get-current-block-height))
        )
        (asserts! (> asking-price u0) ERR_PRICE_INVALID)
        (asserts! (verify-summary summary) ERR_INPUT_INVALID)
        (asserts! (verify-type content-type) ERR_INPUT_INVALID)
        (asserts! (verify-token access-token) ERR_INPUT_INVALID)
        (asserts! (not (default-to false (get tradeable 
            (map-get? content-offerings { item-id: current-id })))) 
            ERR_DUPLICATE_ITEM)
        
        (map-set content-offerings
            { item-id: current-id }
            {
                owner: tx-sender,
                price-tag: asking-price,
                content-summary: summary,
                content-type: content-type,
                tradeable: true,
                creation-block: current-block
            }
        )
        
        (map-set content-keys
            { item-id: current-id }
            { secure-access-token: access-token }
        )
        
        (var-set item-counter (+ current-id u1))
        (ok current-id)
    )
)

;; Acquire digital content
(define-public (acquire-content (item-id uint))
    (let
        (
            (item-info (unwrap! (map-get? content-offerings { item-id: item-id }) 
                ERR_ITEM_UNAVAILABLE))
            (total-cost (get price-tag item-info))
            (merchant (get owner item-info))
            (fee-amount (compute-fee total-cost))
            (merchant-share (- total-cost fee-amount))
            (current-block (get-current-block-height))
        )
        (asserts! (< item-id (var-get item-counter)) ERR_INPUT_INVALID)
        (asserts! (get tradeable item-info) ERR_ITEM_UNAVAILABLE)
        (asserts! (is-eq false (is-eq tx-sender merchant)) ERR_SELF_TRADE_BLOCKED)
        
        (try! (process-payment tx-sender merchant merchant-share))
        (try! (process-payment tx-sender owner-address fee-amount))
        
        (map-set exchange-records
            { customer: tx-sender, item-id: item-id }
            {
                timestamp: current-block,
                cost: total-cost,
                merchant: merchant
            }
        )
        
        (let
            (
                (merchant-stats (default-to 
                    { trade-count: u0, quality-score: u0, last-active: u0 }
                    (map-get? trader-metrics { participant: merchant })))
            )
            (map-set trader-metrics
                { participant: merchant }
                {
                    trade-count: (+ (get trade-count merchant-stats) u1),
                    quality-score: (get quality-score merchant-stats),
                    last-active: current-block
                }
            )
        )
        
        (var-set exchange-volume (+ (var-get exchange-volume) u1))
        (ok true)
    )
)

;; Retrieve content access
(define-public (retrieve-access-token (item-id uint))
    (let
        (
            (purchase-info (unwrap! (map-get? exchange-records 
                { customer: tx-sender, item-id: item-id }) ERR_UNAUTHORIZED))
            (content-access (unwrap! (map-get? content-keys 
                { item-id: item-id }) ERR_ITEM_UNAVAILABLE))
        )
        (asserts! (< item-id (var-get item-counter)) ERR_INPUT_INVALID)
        (ok (get secure-access-token content-access))
    )
)

;; Modify listing price
(define-public (modify-price (item-id uint) (updated-price uint))
    (let
        (
            (item-info (unwrap! (map-get? content-offerings { item-id: item-id }) 
                ERR_ITEM_UNAVAILABLE))
        )
        (asserts! (< item-id (var-get item-counter)) ERR_INPUT_INVALID)
        (asserts! (is-eq (get owner item-info) tx-sender) ERR_UNAUTHORIZED)
        (asserts! (> updated-price u0) ERR_PRICE_INVALID)
        
        (map-set content-offerings
            { item-id: item-id }
            (merge item-info { price-tag: updated-price })
        )
        (ok true)
    )
)

;; Remove from marketplace
(define-public (delist-content (item-id uint))
    (let
        (
            (item-info (unwrap! (map-get? content-offerings { item-id: item-id }) 
                ERR_ITEM_UNAVAILABLE))
        )
        (asserts! (< item-id (var-get item-counter)) ERR_INPUT_INVALID)
        (asserts! (is-eq (get owner item-info) tx-sender) ERR_UNAUTHORIZED)
        
        (map-set content-offerings
            { item-id: item-id }
            (merge item-info { tradeable: false })
        )
        (ok true)
    )
)

;; Administrative functions
(define-public (adjust-fee-rate (new-rate uint))
    (begin
        (asserts! (is-eq tx-sender owner-address) ERR_UNAUTHORIZED)
        (asserts! (<= new-rate u100) ERR_PRICE_INVALID)
        (var-set exchange-fee new-rate)
        (ok true)
    )
)

;; Query functions
(define-read-only (get-content-info (item-id uint))
    (map-get? content-offerings { item-id: item-id })
)

(define-read-only (get-trader-info (participant principal))
    (map-get? trader-metrics { participant: participant })
)

(define-read-only (get-exchange-stats)
    (var-get exchange-volume)
)

(define-read-only (get-current-fee)
    (var-get exchange-fee)
)
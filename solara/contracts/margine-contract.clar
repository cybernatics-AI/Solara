;; Solar Farm Cooperative Contract
;; Enables fractional ownership of solar energy installations with automated revenue distribution

;; Constants
(define-constant GRID_OPERATOR tx-sender)
(define-constant ERR_UNAUTHORIZED_MEMBER (err u700))
(define-constant ERR_INSUFFICIENT_PANELS (err u701))
(define-constant ERR_FARM_NOT_FOUND (err u702))
(define-constant ERR_INVALID_AMOUNT (err u703))
(define-constant ERR_UPGRADE_NOT_FOUND (err u704))
(define-constant ERR_ALREADY_VOTED (err u705))

;; Data Variables
(define-data-var next-farm-id uint u1)
(define-data-var next-upgrade-id uint u1)

;; Farm Structure
(define-map solar-farms 
  { farm-id: uint }
  {
    location: (string-ascii 100),
    total-panels: uint,
    panel-price: uint,
    monthly-revenue: uint,
    chief-engineer: principal,
    is-operational: bool
  }
)

;; Panel Ownership
(define-map member-panels
  { farm-id: uint, member: principal }
  { panels: uint }
)

;; Upgrade Proposals
(define-map farm-upgrades
  { upgrade-id: uint }
  {
    farm-id: uint,
    upgrade-title: (string-ascii 100),
    specifications: (string-ascii 500),
    proposer: principal,
    approval-count: uint,
    rejection-count: uint,
    voting-deadline: uint,
    implemented: bool
  }
)

;; Voting Records
(define-map upgrade-votes
  { upgrade-id: uint, voter: principal }
  { voted: bool, approves: bool }
)

;; Revenue Distribution Tracking
(define-map revenue-claims
  { farm-id: uint, member: principal, month: uint }
  { claimed: bool }
)

;; Farm Installation
(define-public (install-farm 
  (location (string-ascii 100))
  (total-panels uint)
  (panel-price uint)
  (monthly-revenue uint)
  (chief-engineer principal))
  (let ((farm-id (var-get next-farm-id)))
    (asserts! (is-eq tx-sender GRID_OPERATOR) ERR_UNAUTHORIZED_MEMBER)
    (asserts! (> total-panels u0) ERR_INVALID_AMOUNT)
    (asserts! (> panel-price u0) ERR_INVALID_AMOUNT)
    
    (map-set solar-farms
      { farm-id: farm-id }
      {
        location: location,
        total-panels: total-panels,
        panel-price: panel-price,
        monthly-revenue: monthly-revenue,
        chief-engineer: chief-engineer,
        is-operational: true
      }
    )
    
    (var-set next-farm-id (+ farm-id u1))
    (ok farm-id)
  )
)

;; Purchase Solar Panels
(define-public (buy-panels (farm-id uint) (panel-amount uint))
  (let (
    (farm (unwrap! (map-get? solar-farms { farm-id: farm-id }) ERR_FARM_NOT_FOUND))
    (total-cost (* panel-amount (get panel-price farm)))
    (current-panels (default-to u0 (get panels (map-get? member-panels { farm-id: farm-id, member: tx-sender }))))
  )
    (asserts! (get is-operational farm) ERR_FARM_NOT_FOUND)
    (asserts! (> panel-amount u0) ERR_INVALID_AMOUNT)
    
    (map-set member-panels
      { farm-id: farm-id, member: tx-sender }
      { panels: (+ current-panels panel-amount) }
    )
    
    (ok panel-amount)
  )
)

;; Distribute Energy Revenue
(define-public (distribute-revenue (farm-id uint) (month uint))
  (let (
    (farm (unwrap! (map-get? solar-farms { farm-id: farm-id }) ERR_FARM_NOT_FOUND))
    (monthly-revenue (get monthly-revenue farm))
    (total-panels (get total-panels farm))
  )
    (asserts! (is-eq tx-sender (get chief-engineer farm)) ERR_UNAUTHORIZED_MEMBER)
    (asserts! (get is-operational farm) ERR_FARM_NOT_FOUND)
    
    (ok true)
  )
)

;; Claim Revenue Share
(define-public (claim-revenue (farm-id uint) (month uint))
  (let (
    (farm (unwrap! (map-get? solar-farms { farm-id: farm-id }) ERR_FARM_NOT_FOUND))
    (panel-balance (default-to u0 (get panels (map-get? member-panels { farm-id: farm-id, member: tx-sender }))))
    (already-claimed (default-to false (get claimed (map-get? revenue-claims { farm-id: farm-id, member: tx-sender, month: month }))))
    (monthly-revenue (get monthly-revenue farm))
    (total-panels (get total-panels farm))
    (revenue-share (/ (* monthly-revenue panel-balance) total-panels))
  )
    (asserts! (> panel-balance u0) ERR_INSUFFICIENT_PANELS)
    (asserts! (not already-claimed) ERR_UNAUTHORIZED_MEMBER)
    
    (map-set revenue-claims
      { farm-id: farm-id, member: tx-sender, month: month }
      { claimed: true }
    )
    
    (ok revenue-share)
  )
)

;; Create Upgrade Proposal
(define-public (create-upgrade 
  (farm-id uint)
  (upgrade-title (string-ascii 100))
  (specifications (string-ascii 500))
  (voting-period uint))
  (let (
    (upgrade-id (var-get next-upgrade-id))
    (panel-balance (default-to u0 (get panels (map-get? member-panels { farm-id: farm-id, member: tx-sender }))))
    (voting-deadline (+ block-height voting-period))
  )
    (asserts! (> panel-balance u0) ERR_UNAUTHORIZED_MEMBER)
    
    (map-set farm-upgrades
      { upgrade-id: upgrade-id }
      {
        farm-id: farm-id,
        upgrade-title: upgrade-title,
        specifications: specifications,
        proposer: tx-sender,
        approval-count: u0,
        rejection-count: u0,
        voting-deadline: voting-deadline,
        implemented: false
      }
    )
    
    (var-set next-upgrade-id (+ upgrade-id u1))
    (ok upgrade-id)
  )
)

;; Vote on Upgrade
(define-public (vote-upgrade (upgrade-id uint) (approves bool))
  (let (
    (upgrade (unwrap! (map-get? farm-upgrades { upgrade-id: upgrade-id }) ERR_UPGRADE_NOT_FOUND))
    (farm-id (get farm-id upgrade))
    (panel-balance (default-to u0 (get panels (map-get? member-panels { farm-id: farm-id, member: tx-sender }))))
    (already-voted (default-to false (get voted (map-get? upgrade-votes { upgrade-id: upgrade-id, voter: tx-sender }))))
    (current-approval (get approval-count upgrade))
    (current-rejection (get rejection-count upgrade))
  )
    (asserts! (> panel-balance u0) ERR_UNAUTHORIZED_MEMBER)
    (asserts! (<= block-height (get voting-deadline upgrade)) ERR_UNAUTHORIZED_MEMBER)
    (asserts! (not already-voted) ERR_ALREADY_VOTED)
    
    (map-set upgrade-votes
      { upgrade-id: upgrade-id, voter: tx-sender }
      { voted: true, approves: approves }
    )
    
    (if approves
      (map-set farm-upgrades
        { upgrade-id: upgrade-id }
        (merge upgrade { approval-count: (+ current-approval panel-balance) })
      )
      (map-set farm-upgrades
        { upgrade-id: upgrade-id }
        (merge upgrade { rejection-count: (+ current-rejection panel-balance) })
      )
    )
    
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-farm (farm-id uint))
  (map-get? solar-farms { farm-id: farm-id })
)

(define-read-only (get-panel-balance (farm-id uint) (member principal))
  (default-to u0 (get panels (map-get? member-panels { farm-id: farm-id, member: member })))
)

(define-read-only (get-upgrade (upgrade-id uint))
  (map-get? farm-upgrades { upgrade-id: upgrade-id })
)

(define-read-only (calculate-revenue-share (farm-id uint) (member principal))
  (let (
    (farm (unwrap! (map-get? solar-farms { farm-id: farm-id }) ERR_FARM_NOT_FOUND))
    (panel-balance (default-to u0 (get panels (map-get? member-panels { farm-id: farm-id, member: member }))))
    (monthly-revenue (get monthly-revenue farm))
    (total-panels (get total-panels farm))
  )
    (if (> panel-balance u0)
      (ok (/ (* monthly-revenue panel-balance) total-panels))
      (ok u0)
    )
  )
)
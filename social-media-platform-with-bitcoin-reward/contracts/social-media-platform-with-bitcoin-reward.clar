;; title: social-media-platform-with-bitcoin-reward
;; Error Constants
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-PROFILE-EXISTS (err u2))
(define-constant ERR-PROFILE-NOT-FOUND (err u3))
(define-constant ERR-CONTENT-NOT-FOUND (err u4))
(define-constant ERR-ALREADY-REWARDED (err u5))
(define-constant ERR-INSUFFICIENT-REPUTATION (err u6))

;; Governance Parameters
(define-constant PLATFORM-OWNER tx-sender)
(define-constant MIN-REPUTATION-FOR-VERIFIED u100)
(define-constant REWARD-MULTIPLIER u10)
(define-constant MAX-REPORT-THRESHOLD u3)

;; User Reputation Tracking
(define-map user-profiles
  principal
  {
    username: (string-ascii 50),
    bio: (string-ascii 200),
    profile-image-hash: (string-ascii 64),
    reputation-score: uint,
    total-contributions: uint,
    verified-status: bool,
    followers: uint,
    following: uint,
    joined-at: uint
  }
)

;; Content Management
(define-map content-registry
  uint
  {
    content-id: uint,
    creator: principal,
    content-type: (string-ascii 20),
    content-hash: (string-ascii 64),
    description: (string-ascii 200),
    timestamp: uint,
    engagement: {
      likes: uint,
      comments: uint,
      shares: uint,
      views: uint
    },
    rewards-distributed: bool,
    tags: (list 5 (string-ascii 20))
  }
)

;; User Content Tracking
(define-map user-content-index
  principal
  (list 100 uint)
)

;; Engagement Tracking
(define-map content-engagement
  {content-id: uint, user: principal}
  {
    engagement-type: (string-ascii 20),
    timestamp: uint
  }
)

;; Reward Pool Management
(define-data-var total-reward-pool uint u10000)
(define-data-var platform-fee uint u5)

;; User Profile Creation
(define-public (create-profile 
  (username (string-ascii 50))
  (bio (string-ascii 200))
  (profile-image-hash (string-ascii 64))
)
  (begin
    (asserts! (is-none (map-get? user-profiles tx-sender)) ERR-PROFILE-EXISTS)
    
    (map-set user-profiles 
      tx-sender 
      {
        username: username,
        bio: bio,
        profile-image-hash: profile-image-hash,
        reputation-score: u0,
        total-contributions: u0,
        verified-status: false,
        followers: u0,
        following: u0,
        joined-at: stacks-block-height
      }
    )
    
    (ok true)
  )
)

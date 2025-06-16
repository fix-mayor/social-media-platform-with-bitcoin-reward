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


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

;; Content Creation
(define-public (create-content
  (content-type (string-ascii 20))
  (content-hash (string-ascii 64))
  (description (string-ascii 200))
  (tags (list 5 (string-ascii 20)))
)
  (let 
    (
      (content-id (var-get total-reward-pool))
      (user-profile (unwrap! (map-get? user-profiles tx-sender) ERR-PROFILE-NOT-FOUND))
    )
    
    ;; Create content registry entry
    (map-set content-registry 
      content-id 
      {
        content-id: content-id,
        creator: tx-sender,
        content-type: content-type,
        content-hash: content-hash,
        description: description,
        timestamp: stacks-block-height,
        engagement: {
          likes: u0,
          comments: u0,
          shares: u0,
          views: u0
        },
        rewards-distributed: false,
        tags: tags
      }
    )
    
    ;; Update user content index
    (let 
      ((current-content-list (default-to (list) (map-get? user-content-index tx-sender))))
      (map-set user-content-index 
        tx-sender 
        (unwrap! (as-max-len? (append current-content-list content-id) u100) ERR-NOT-AUTHORIZED)
      )
    )
    
    ;; Increment total reward pool and content ID
    (var-set total-reward-pool (+ (var-get total-reward-pool) u1))
    
    (ok content-id)
  )
)

;; Engagement Mechanism
(define-public (engage-content
  (content-id uint)
  (engagement-type (string-ascii 20))
)
  (let 
    (
      (content (unwrap! (map-get? content-registry content-id) ERR-CONTENT-NOT-FOUND))
      (current-engagement (get engagement content))
    )
    
    ;; Record engagement
    (map-set content-engagement 
      {content-id: content-id, user: tx-sender}
      {
        engagement-type: engagement-type,
        timestamp: stacks-block-height
      }
    )
    
    ;; Update content engagement metrics
    (map-set content-registry 
      content-id 
      (merge content 
        {
          engagement: 
            (if (is-eq engagement-type "like")
              (merge current-engagement {likes: (+ (get likes current-engagement) u1)})
            (if (is-eq engagement-type "comment")
              (merge current-engagement {comments: (+ (get comments current-engagement) u1)})
            (if (is-eq engagement-type "share")
              (merge current-engagement {shares: (+ (get shares current-engagement) u1)})
              current-engagement
            ))
          )
        }
      )
    )
    
    (ok true)
  )
)

;; Reward Distribution
(define-public (distribute-rewards (content-id uint))
  (let 
    (
      (content (unwrap! (map-get? content-registry content-id) ERR-CONTENT-NOT-FOUND))
      (creator (get creator content))
      (engagement (get engagement content))
      (total-engagement (+ 
        (get likes engagement) 
        (get comments engagement) 
        (get shares engagement)
      ))
      (reward (* total-engagement REWARD-MULTIPLIER))
    )
    
    ;; Check if already rewarded
    (asserts! (not (get rewards-distributed content)) ERR-ALREADY-REWARDED)
    
    ;; Update content reward status
    (map-set content-registry 
      content-id 
      (merge content {rewards-distributed: true})
    )
    
    ;; Implement Bitcoin reward transfer logic here
    ;; This would typically involve calling an external contract or service
    
    (ok reward)
  )
)

;; Governance Functions
(define-public (update-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender PLATFORM-OWNER) ERR-NOT-AUTHORIZED)
    (var-set platform-fee new-fee)
    (ok true)
  )
)

;; Read-Only Functions
(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles user)
)

(define-read-only (get-content (content-id uint))
  (map-get? content-registry content-id)
)

;; New Error Constants
(define-constant ERR-ALREADY-FOLLOWING (err u7))
(define-constant ERR-NOT-FOLLOWING (err u8))
(define-constant ERR-INVALID-REPORT (err u9))
(define-constant ERR-TRANSFER-FAILED (err u10))

;; Following Relationship Map
(define-map user-followers 
  {follower: principal, followed: principal} 
  {timestamp: uint}
)

;; Content Reporting System
(define-map content-reports 
  {content-id: uint, reporter: principal} 
  {
    reason: (string-ascii 100),
    timestamp: uint,
    status: (string-ascii 20)
  }
)

;; Direct Messaging Map
(define-map direct-messages 
  {sender: principal, recipient: principal} 
  (list 50 {
    message: (string-ascii 200),
    timestamp: uint,
    read-status: bool
  })
)

;; New: Follow/Unfollow Mechanism
(define-public (follow-user (target-user principal))
  (let 
    (
      (sender-profile (unwrap! (map-get? user-profiles tx-sender) ERR-PROFILE-NOT-FOUND))
      (target-profile (unwrap! (map-get? user-profiles target-user) ERR-PROFILE-NOT-FOUND))
    )
    ;; Check if already following
    (asserts! 
      (is-none (map-get? user-followers {follower: tx-sender, followed: target-user})) 
      ERR-ALREADY-FOLLOWING
    )
    
    ;; Add following relationship
    (map-set user-followers 
      {follower: tx-sender, followed: target-user}
      {timestamp: stacks-block-height}
    )
    
    ;; Update follower/following counts
    (map-set user-profiles 
      tx-sender 
      (merge sender-profile {following: (+ (get following sender-profile) u1)})
    )
    (map-set user-profiles 
      target-user 
      (merge target-profile {followers: (+ (get followers target-profile) u1)})
    )
    
    (ok true)
  )
)

(define-constant ROOM_BOOKED u0)
(define-constant DONT_OWN_ROOM u1)
(define-constant TRANSACTION_FAILED u2)
(define-constant ROOM_CHKnt u3)
(define-constant DAYS_0 u4)
(define-map room {room-id: uint} {rentee: (optional principal), booked: bool, price: uint, total-days: uint, chk-in-time: uint})
(map-insert room {room-id: u1} {rentee: none, booked: false, price: u50, total-days: u0, chk-in-time: u0})
(map-insert room {room-id: u2} {rentee: none, booked: false, price: u100, total-days: u0, chk-in-time: u0})
(map-insert room {room-id: u3} {rentee: none, booked: false, price: u150, total-days: u0, chk-in-time: u0})

(define-read-only (what-is (room-num uint))
    (map-get? room {room-id: room-num})
)

(define-read-only (get-rentee (room-num uint))
   (unwrap-panic (get rentee (map-get? room {room-id: room-num})))
)
    
(define-read-only (is-booked (room-num uint))
    (unwrap-panic (get booked (map-get? room {room-id: room-num})))
)

(define-read-only (get-price (room-num uint))
   (unwrap-panic (get price (map-get? room {room-id: room-num})))
)

(define-read-only (get-days (room-num uint))
   (unwrap-panic (get total-days (map-get? room {room-id: room-num})))
)

(define-read-only (get-time (room-num uint))
   (unwrap-panic (get chk-in-time (map-get? room {room-id: room-num})))
)

;;--------------------PUBLIC  FUNCTIONS----------------------------------

(define-public (check-in (days uint) (room-num uint))
    (let ( 
            (x (is-booked room-num))
            (y (get-price room-num))
            (time (unwrap-panic (get-block-info? time (- block-height u1))))
        )

        (if (is-eq (to-int days) 0)
            (err {kind: "Days can't be 0.", code: DAYS_0})
            (begin
                (if x
                    (err {kind: "Room is already booked.", code: ROOM_BOOKED})
                    (begin
                        (unwrap! (stx-transfer? (* y days) tx-sender (as-contract tx-sender)) (err {kind: "Transaction has failed.", code: TRANSACTION_FAILED}))
                        (map-set room {room-id: room-num} {rentee: (some tx-sender), booked: true, price: y, total-days: days, chk-in-time: time})
                        (ok "You have checked in to your room.")
                    )
                )   
            )
        )
    )
)

(define-public (check-out (room-num uint))
    (let (
            (x (unwrap! (get-rentee room-num) (err {kind: "This room isn't currently checked in.", code: ROOM_CHKnt})))
            (in-time (get-time room-num))
            (din (get-days room-num))
            (y (get-price room-num))

            (chk-out-time (unwrap-panic (get-block-info? time (- block-height u1))))
            (diff (/ (- chk-out-time in-time) u86400))
        )
        (if (is-eq x tx-sender)
            (begin
                (if (> diff din)
                    (unwrap! (stx-transfer? (* (- diff din) (get-price room-num)) tx-sender (as-contract tx-sender)) (err {kind: "Transaction has failed.", code: TRANSACTION_FAILED}))
                    false
                )
                (map-set room {room-id: room-num} {rentee: none, booked: false, price: y, total-days: u0, chk-in-time: u0})
                ;; (print diff)
                (ok "Successfully, checked out.")
            )
            (err {kind: "This is not your room.", code: DONT_OWN_ROOM})
        )
    )
)

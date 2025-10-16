------------------------------ MODULE XrplEscrow ------------------------------
EXTENDS Naturals, TLC

(*
XRPL-like escrow with ghost accounting:
  - Ghost totals: Locked + Released + Refunded = Committed
  - Single escrow at a time; you may open a new one after finish/cancel
*)

CONSTANTS
  MAX_AMOUNT,   
  MAX_TIME,     
  MAX_DELAY,    
  MAX_COMM      \* upper bound for Committed/Released/Refunded (e.g., 12)

VARIABLES
  Escrow, Fulfilled, Deadline, now,
  Locked, Released, Refunded, Committed,
  DeltaReleased, DeltaRefunded,
  ReleasedThisCycle, RefundedThisCycle

vars == << Escrow, Fulfilled, Deadline, now,
           Locked, Released, Refunded, Committed,
           DeltaReleased, DeltaRefunded,
           ReleasedThisCycle, RefundedThisCycle >>

Min(a, b) == IF a <= b THEN a ELSE b

(***************************************************************************)
(* Types                                                                    *)
(***************************************************************************)
TypeOK ==
  /\ Escrow \in 0..MAX_AMOUNT
  /\ Fulfilled \in BOOLEAN
  /\ Deadline \in 0..MAX_TIME
  /\ now \in 0..MAX_TIME
  /\ Locked \in 0..MAX_AMOUNT
  /\ Released \in 0..MAX_COMM
  /\ Refunded \in 0..MAX_COMM
  /\ Committed \in 0..MAX_COMM
  /\ DeltaReleased \in 0..MAX_AMOUNT
  /\ DeltaRefunded \in 0..MAX_AMOUNT
  /\ ReleasedThisCycle \in BOOLEAN
  /\ RefundedThisCycle \in BOOLEAN

(***************************************************************************)
(* Initial state                                                            *)
(***************************************************************************)
Init ==
  /\ Escrow = 0
  /\ Fulfilled = FALSE
  /\ Deadline = 0
  /\ now = 0
  /\ Locked = 0
  /\ Released = 0
  /\ Refunded = 0
  /\ Committed = 0
  /\ DeltaReleased = 0
  /\ DeltaRefunded = 0
  /\ ReleasedThisCycle = FALSE
  /\ RefundedThisCycle = FALSE

(***************************************************************************)
(* Actions                                                                  *)
(***************************************************************************)
Lock ==
  /\ Escrow = 0
  /\ now < MAX_TIME
  /\ \E a \in 1..MAX_AMOUNT, d \in 1..Min(MAX_DELAY, MAX_TIME - now):
       /\ Committed + a <= MAX_COMM
       /\ Escrow' = a
       /\ Fulfilled' = FALSE
       /\ Deadline' = now + d
       /\ now' = now
       /\ Locked' = a
       /\ Committed' = Committed + a
       /\ DeltaReleased' = 0
       /\ DeltaRefunded' = 0
       /\ ReleasedThisCycle' = FALSE
       /\ RefundedThisCycle' = FALSE
       /\ UNCHANGED << Released, Refunded >>

Fulfill ==
  /\ Escrow > 0
  /\ ~Fulfilled
  /\ now < Deadline
  /\ Fulfilled' = TRUE
  /\ DeltaReleased' = 0
  /\ DeltaRefunded' = 0
  /\ UNCHANGED <<Escrow, Deadline, now, Locked, Released, Refunded,
                 Committed, ReleasedThisCycle, RefundedThisCycle>>

Finish ==
  /\ Escrow > 0
  /\ Fulfilled
  /\ now < Deadline
  /\ Escrow' = 0
  /\ Locked' = 0
  /\ Released' = Released + Escrow
  /\ DeltaReleased' = Escrow
  /\ DeltaRefunded' = 0
  /\ ReleasedThisCycle' = TRUE
  /\ UNCHANGED <<Fulfilled, Deadline, now, Refunded, Committed, RefundedThisCycle>>

Cancel ==
  /\ Escrow > 0
  /\ now >= Deadline
  /\ Escrow' = 0
  /\ Locked' = 0
  /\ Refunded' = Refunded + Escrow
  /\ DeltaRefunded' = Escrow
  /\ DeltaReleased' = 0
  /\ RefundedThisCycle' = TRUE
  /\ UNCHANGED <<Fulfilled, Deadline, now, Released, Committed, ReleasedThisCycle>>

Tick ==
  /\ now < MAX_TIME
  /\ now' = now + 1
  /\ DeltaReleased' = 0
  /\ DeltaRefunded' = 0
  /\ UNCHANGED <<Escrow, Fulfilled, Deadline, Locked, Released, Refunded,
                 Committed, ReleasedThisCycle, RefundedThisCycle>>

Next == Lock \/ Fulfill \/ Finish \/ Cancel \/ Tick
Spec == Init /\ [][Next]_vars

(***************************************************************************)
(* Invariants                                                               *)
(***************************************************************************)

\* 1) Ghost accounting must conserve value (ledger conservation)
Conservation ==
  Locked + Released + Refunded = Committed
\* if locked=0 than release equals something and in contrary
\* 2) Our ghost Locked mirrors concrete Escrow
LockedEqualsEscrow ==
  Locked = Escrow

\* 3) At most one outcome per escrow cycle
ExclusiveOutcome ==
  ~(ReleasedThisCycle /\ RefundedThisCycle)

\* 4) No incorrect release: any release delta implies the release gate holds
NoIncorrectRelease ==
  (DeltaReleased > 0) => (Fulfilled /\ now < Deadline)

\* 5) No incorrect cancellation: any refund delta implies deadline reached
NoIncorrectCancel ==
  (DeltaRefunded > 0) => (now >= Deadline)

\* Original enablement-style guards (still useful)
NoEmptyFinishEnabled ==
  (Escrow = 0) => ~ENABLED Finish

CancelNotBeforeDeadline ==
  (Escrow > 0 /\ now < Deadline) => ~ENABLED Cancel

NoFinishAfterDeadline ==
  (now >= Deadline) => ~ENABLED Finish

==============================================================================
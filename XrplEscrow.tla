------------------------------ MODULE XrplEscrow ------------------------------
EXTENDS Naturals, TLC

(*
XRPL-style escrow with ghost accounting (two-phase ledger view):
  - Allowed create combos: {FinishAfter} or {FinishAfter,CancelAfter} or
    {Condition,CancelAfter} or {FinishAfter,Condition,CancelAfter}.
  - Finish requires:
      * not expired (CancelAfter=0 \/ now < CancelAfter),
      * FinishAfter passed if present,
      * if Condition is set, a matching Fulfillment is provided in the same step.
  - Cancel requires CancelAfter present and passed.
  - 'now' models the close time of the previous validated ledger.
*)

CONSTANTS
  MAX_AMOUNT,   \* max single-escrow amount
  MAX_TIME,     \* time horizon
  MAX_DELAY,    \* unused here (kept for parity with your cfg)
  MAX_COMM      \* upper bound for Committed/Released/Refunded

VARIABLES
  \* Escrow state
  Escrow,              \* amount in escrow (0 = none)
  ConditionSet,        \* whether escrow has a crypto-condition
  FinishAfter,         \* 0 = absent, else time >=1..MAX_TIME
  CancelAfter,         \* 0 = absent, else time >=1..MAX_TIME
  now,                 \* ledger (previous) close time, 0..MAX_TIME

  \* Ghost accounting
  Locked, Released, Refunded, Committed,
  DeltaReleased, DeltaRefunded,
  ReleasedThisCycle, RefundedThisCycle,

  \* Bookkeeping
  HasFulfillment,      \* was a fulfillment supplied in EscrowFinish step?
  PrevLocked           \* previous state's Locked (for no-partial-release check)

vars ==
  << Escrow, ConditionSet, FinishAfter, CancelAfter, now,
     Locked, Released, Refunded, Committed,
     DeltaReleased, DeltaRefunded,
     ReleasedThisCycle, RefundedThisCycle,
     HasFulfillment, PrevLocked >>

Min(a,b) == IF a <= b THEN a ELSE b

(***************************************************************************)
(* Types                                                                    *)
(***************************************************************************)
TypeOK ==
  /\ Escrow \in 0..MAX_AMOUNT
  /\ ConditionSet \in BOOLEAN
  /\ FinishAfter \in 0..MAX_TIME
  /\ CancelAfter \in 0..MAX_TIME
  /\ now \in 0..MAX_TIME
  /\ Locked \in 0..MAX_AMOUNT
  /\ Released \in 0..MAX_COMM
  /\ Refunded \in 0..MAX_COMM
  /\ Committed \in 0..MAX_COMM
  /\ DeltaReleased \in 0..MAX_AMOUNT
  /\ DeltaRefunded \in 0..MAX_AMOUNT
  /\ ReleasedThisCycle \in BOOLEAN
  /\ RefundedThisCycle \in BOOLEAN
  /\ HasFulfillment \in BOOLEAN
  /\ PrevLocked \in 0..MAX_AMOUNT

(***************************************************************************)
(* Initial state                                                            *)
(***************************************************************************)
Init ==
  /\ Escrow = 0
  /\ ConditionSet = FALSE
  /\ FinishAfter = 0
  /\ CancelAfter = 0
  /\ now = 0
  /\ Locked = 0
  /\ Released = 0
  /\ Refunded = 0
  /\ Committed = 0
  /\ DeltaReleased = 0
  /\ DeltaRefunded = 0
  /\ ReleasedThisCycle = FALSE
  /\ RefundedThisCycle = FALSE
  /\ HasFulfillment = FALSE
  /\ PrevLocked = 0

(***************************************************************************)
(* Helpers                                                                  *)
(***************************************************************************)
IsExpired == (CancelAfter # 0) /\ (now >= CancelAfter)
FinishAfterPassed == (FinishAfter = 0) \/ (now >= FinishAfter)

AllowedCreateCombo(cond, fa, ca) ==
  \* XRPL: must be one of {fa}, {fa,ca}, {cond,ca}, {fa,cond,ca}
  \* and any present time must be strictly in the future at creation.
  LET faPresent == fa # 0
      caPresent == ca # 0
  IN  /\ ( \/ /\  faPresent /\ ~cond /\ ~caPresent
           \/ /\  faPresent /\  caPresent /\ ~cond
           \/ /\  cond      /\  caPresent /\ ~faPresent
           \/ /\  cond      /\  faPresent /\  caPresent )
      /\ ( ~faPresent \/ fa > now )
      /\ ( ~caPresent \/ ca > now )
      /\ ( ~(faPresent /\ caPresent) \/ fa < ca )

(***************************************************************************)
(* Actions                                                                  *)
(***************************************************************************)
EscrowCreate ==
  /\ Escrow = 0
  /\ now < MAX_TIME
  /\ \E a \in 1..MAX_AMOUNT,
        cond \in BOOLEAN,
        fa \in 0..MAX_TIME,
        ca \in 0..MAX_TIME:
       /\ AllowedCreateCombo(cond, fa, ca)
       /\ Committed + a <= MAX_COMM          \* capacity guard
       /\ Escrow' = a
       /\ ConditionSet' = cond
       /\ FinishAfter' = fa
       /\ CancelAfter' = ca
       /\ Locked' = a
       /\ Committed' = Committed + a
       /\ DeltaReleased' = 0
       /\ DeltaRefunded' = 0
       /\ ReleasedThisCycle' = FALSE
       /\ RefundedThisCycle' = FALSE
       /\ HasFulfillment' = FALSE
       /\ PrevLocked' = Locked               \* record pre-state Locked
       /\ UNCHANGED << now, Released, Refunded >>

EscrowFinish ==
  /\ Escrow > 0
  /\ FinishAfterPassed
  /\ ~IsExpired                      \* cannot finish after expiration
  /\ \E f \in BOOLEAN:
       /\ (~ConditionSet \/ f)        \* if conditional, a fulfillment is provided
       /\ Escrow' = 0
       /\ Locked' = 0
       /\ Released' = Released + Escrow
       /\ DeltaReleased' = Escrow
       /\ DeltaRefunded' = 0
       /\ ReleasedThisCycle' = TRUE
       /\ RefundedThisCycle' = FALSE
       /\ HasFulfillment' = f
       /\ PrevLocked' = Locked
       /\ UNCHANGED << ConditionSet, FinishAfter, CancelAfter, now,
                       Refunded, Committed >>

EscrowCancel ==
  /\ Escrow > 0
  /\ CancelAfter # 0
  /\ now >= CancelAfter
  /\ Escrow' = 0
  /\ Locked' = 0
  /\ Refunded' = Refunded + Escrow
  /\ DeltaRefunded' = Escrow
  /\ DeltaReleased' = 0
  /\ RefundedThisCycle' = TRUE
  /\ ReleasedThisCycle' = FALSE
  /\ HasFulfillment' = FALSE
  /\ PrevLocked' = Locked
  /\ UNCHANGED << ConditionSet, FinishAfter, CancelAfter, now,
                  Released, Committed >>

Tick ==
  /\ now < MAX_TIME
  /\ now' = now + 1
  /\ DeltaReleased' = 0
  /\ DeltaRefunded' = 0
  /\ ReleasedThisCycle' = FALSE
  /\ RefundedThisCycle' = FALSE
  /\ HasFulfillment' = FALSE
  /\ PrevLocked' = Locked
  /\ UNCHANGED << Escrow, ConditionSet, FinishAfter, CancelAfter,
                  Locked, Released, Refunded, Committed >>

Next == EscrowCreate \/ EscrowFinish \/ EscrowCancel \/ Tick
Spec == Init /\ [][Next]_vars

(***************************************************************************)
(* Invariants                                                               *)
(***************************************************************************)

\* 1) Ghost accounting: Locked + Released + Refunded == Committed
Conservation ==
  Locked + Released + Refunded = Committed

\* 2) Locked mirrors the concrete escrow amount
LockedEqualsEscrow ==
  Locked = Escrow

\* 3) At most one outcome per cycle
ExclusiveOutcome ==
  ~(ReleasedThisCycle /\ RefundedThisCycle)

\* 4) Releases only under XRPL gates
NoIncorrectRelease ==
  (DeltaReleased > 0)
    => /\ FinishAfterPassed
       /\ ~IsExpired
       /\ (~ConditionSet \/ HasFulfillment)

\* 5) Refunds only when CancelAfter present and passed
NoIncorrectCancel ==
  (DeltaRefunded > 0) => (CancelAfter # 0 /\ now >= CancelAfter)

\* 6) Enablement-style guards
NoEmptyFinishEnabled ==
  (Escrow = 0) => ~ENABLED EscrowFinish

CancelOnlyIfExpired ==
  (Escrow > 0 /\ (CancelAfter = 0 \/ now < CancelAfter)) => ~ENABLED EscrowCancel

NoFinishAfterExpiration ==
  (CancelAfter # 0 /\ now >= CancelAfter) => ~ENABLED EscrowFinish

ClosedImpliesAccounted ==
  (Escrow = 0) => (Released + Refunded = Committed)

\* 7) No creating a new escrow while one is open
NoCreateWhileOpen ==
  (Escrow > 0) => ~ENABLED EscrowCreate

\* 8) No partial fund release: if any release occurs, it equals the entire
\*    previously locked amount (i.e., all-or-nothing).
FullReleaseOnly ==
  (DeltaReleased = 0)
  \/ (DeltaReleased = PrevLocked /\ Escrow = 0 /\ Locked = 0)

==============================================================================
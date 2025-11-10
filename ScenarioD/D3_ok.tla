------------------------------ MODULE D3_ok ------------------------------
EXTENDS XrplEscrow

VARIABLE pc

InitD3 ==
  /\ Init
  /\ pc = "start"

\* Create escrow that will expire (refund path)
Create ==
  /\ pc = "start"
  /\ EscrowCreate
  /\ Escrow' = 2
  /\ ConditionSet' = TRUE
  /\ FinishAfter' = 0
  /\ CancelAfter' = now + 1
  /\ pc' = "locked"

TickToExpire ==
  /\ pc = "locked"
  /\ Tick
  /\ pc' = "expired"

\* GOOD: partial refund (1) WITH accounting: reduce Locked/Escrow accordingly.
PartialRefund1 ==
  /\ pc = "expired"
  /\ Escrow = 2 /\ Locked = 2
  /\ Released' = Released
  /\ Refunded' = Refunded + 1
  /\ DeltaRefunded' = 1
  /\ DeltaReleased' = 0
  /\ RefundedThisCycle' = TRUE
  /\ ReleasedThisCycle' = FALSE
  /\ Escrow' = 1
  /\ Locked' = 1
  /\ PrevLocked' = 2
  /\ UNCHANGED << ConditionSet, FinishAfter, CancelAfter, now, Committed, HasFulfillment >>
  /\ pc' = "partial_left_1"

\* Final refund of the remainder (1) to close escrow.
PartialRefund2_Close ==
  /\ pc = "partial_left_1"
  /\ Escrow = 1 /\ Locked = 1
  /\ Released' = Released
  /\ Refunded' = Refunded + 1
  /\ DeltaRefunded' = 1
  /\ DeltaReleased' = 0
  /\ RefundedThisCycle' = TRUE
  /\ ReleasedThisCycle' = FALSE
  /\ Escrow' = 0
  /\ Locked' = 0
  /\ PrevLocked' = 1
  /\ UNCHANGED << ConditionSet, FinishAfter, CancelAfter, now, Committed, HasFulfillment >>
  /\ pc' = "closed"

Done ==
  /\ pc = "closed"
  /\ UNCHANGED << vars, pc >>

NextD3 == Create \/ TickToExpire \/ PartialRefund1 \/ PartialRefund2_Close \/ Done
SpecD3 == InitD3 /\ [][NextD3]_<< vars, pc >>
=============================================================================
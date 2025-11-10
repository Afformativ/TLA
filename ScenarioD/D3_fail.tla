------------------------------ MODULE D3_fail ------------------------------
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

\* BAD: try to refund a partial amount (1) without unlocking escrow fully.
\* This should break Conservation because Locked stays 2 while Refunded increases.
BadPartialRefund ==
  /\ pc = "expired"
  /\ Escrow = 2 /\ Locked = 2
  /\ Released' = Released
  /\ Refunded' = Refunded + 1
  /\ DeltaRefunded' = 1
  /\ DeltaReleased' = 0
  /\ RefundedThisCycle' = TRUE
  /\ ReleasedThisCycle' = FALSE
  /\ PrevLocked' = Locked
  /\ UNCHANGED << Escrow, Locked, ConditionSet, FinishAfter, CancelAfter, now,
                  Committed, HasFulfillment >>
  /\ pc' = "bad_refunded"

Done ==
  /\ pc = "bad_refunded"
  /\ UNCHANGED << vars, pc >>

NextD3 == Create \/ TickToExpire \/ BadPartialRefund \/ Done
SpecD3 == InitD3 /\ [][NextD3]_<< vars, pc >>
=============================================================================
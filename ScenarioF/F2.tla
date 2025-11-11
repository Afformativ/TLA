------------------------------ MODULE F2 ------------------------------
EXTENDS XrplEscrow

VARIABLE pc

GhostOK_F == LockedEqualsEscrow /\ ClosedImpliesAccounted

InitF2 ==
  /\ Init
  /\ pc = "start"

\* Normal create that will expire
Create ==
  /\ pc = "start"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = TRUE
  /\ FinishAfter' = 0
  /\ CancelAfter' = now + 1
  /\ pc' = "locked"

TickToExpire ==
  /\ pc = "locked"
  /\ Tick
  /\ pc' = "expired"

\* BAD: refund but forget to clear Locked (and Escrow cleared)
BadCancel_NoUnlock ==
  /\ pc = "expired"
  /\ Escrow = 1 /\ Locked = 1
  /\ Escrow' = 0
  /\ Locked' = 1                 \* BUG: should be 0
  /\ Refunded' = Refunded + 1
  /\ DeltaRefunded' = 1
  /\ DeltaReleased' = 0
  /\ RefundedThisCycle' = TRUE
  /\ ReleasedThisCycle' = FALSE
  /\ PrevLocked' = 1
  /\ UNCHANGED << ConditionSet, FinishAfter, CancelAfter, now,
                  Released, Committed, HasFulfillment >>
  /\ pc' = "bad_refunded"

Done ==
  /\ pc = "bad_refunded"
  /\ UNCHANGED << vars, pc >>

NextF2 == Create \/ TickToExpire \/ BadCancel_NoUnlock \/ Done
SpecF2 == InitF2 /\ [][NextF2]_<< vars, pc >>
=============================================================================
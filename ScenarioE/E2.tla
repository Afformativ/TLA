------------------------------ MODULE E2 ------------------------------
EXTENDS XrplEscrow

VARIABLE pc

InitE2 ==
  /\ Init
  /\ pc = "start"

Create_NotReady ==
  /\ pc = "start"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = FALSE
  /\ FinishAfter' = now + 2      \* not yet passed
  /\ CancelAfter' = 0
  /\ pc' = "locked"

\* BAD: fabricate an early release while gates are not satisfied
BadPrematureRelease ==
  /\ pc = "locked"
  /\ Escrow = 1 /\ Locked = 1
  /\ Released' = Released + 1
  /\ DeltaReleased' = 1
  /\ DeltaRefunded' = 0
  /\ ReleasedThisCycle' = TRUE
  /\ RefundedThisCycle' = FALSE
  /\ Escrow' = 0
  /\ Locked' = 0
  /\ PrevLocked' = 1
  /\ UNCHANGED << ConditionSet, FinishAfter, CancelAfter, now, Refunded, Committed, HasFulfillment >>
  /\ pc' = "bad"

Done ==
  /\ pc = "bad"
  /\ UNCHANGED << vars, pc >>

NextE2 == Create_NotReady \/ BadPrematureRelease \/ Done
SpecE2 == InitE2 /\ [][NextE2]_<< vars, pc >>
=============================================================================
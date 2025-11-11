------------------------------ MODULE F1 ------------------------------
EXTENDS XrplEscrow

VARIABLE pc

\* GhostOK we want TLC to catch early
GhostOK_F == LockedEqualsEscrow /\ ClosedImpliesAccounted

InitF1 ==
  /\ Init
  /\ pc = "start"

\* BAD: "commit" without bumping Locked (and not using EscrowCreate)
BadCreate_MissingLocked ==
  /\ pc = "start"
  /\ Escrow = 0 /\ Locked = 0
  /\ Escrow' = 1                     \* escrow opened
  /\ Locked' = 0                     \* BUG: not incremented
  /\ Committed' = Committed + 1
  /\ DeltaReleased' = 0
  /\ DeltaRefunded' = 0
  /\ ReleasedThisCycle' = FALSE
  /\ RefundedThisCycle' = FALSE
  /\ PrevLocked' = Locked
  /\ UNCHANGED << ConditionSet, FinishAfter, CancelAfter, now,
                  Released, Refunded, HasFulfillment >>
  /\ pc' = "bad_state"

\* (Optional) try to finish — TLC will already stop on the prior bad state
TryFinish_NoEffect ==
  /\ pc = "bad_state"
  /\ UNCHANGED << vars, pc >>

NextF1 == BadCreate_MissingLocked \/ TryFinish_NoEffect
SpecF1 == InitF1 /\ [][NextF1]_<< vars, pc >>
=============================================================================
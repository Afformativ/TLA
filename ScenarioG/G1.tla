------------------------------ MODULE G1 ------------------------------
EXTENDS XrplEscrow

VARIABLE pc, CurrentActor, Manager

TypeOK_G1 ==
  /\ CurrentActor \in {0,1}
  /\ Manager \in {0,1}

\* Optional role check to accompany NoIncorrectRelease
AuthorizedFinisherOnly ==
  (DeltaReleased = 0) \/ (CurrentActor = Manager)

InitG1 ==
  /\ Init
  /\ pc = "start"
  /\ Manager = 0
  /\ CurrentActor = 1

\* Create a conditional escrow that is NOT yet fulfilled by the caller.
Create ==
  /\ pc = "start"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = TRUE
  /\ FinishAfter' = 0
  /\ CancelAfter' = now + 3
  /\ pc' = "locked"
  /\ UNCHANGED << CurrentActor, Manager >>   \* <<— add this

\* BAD: attacker forges a release without fulfillment (not via EscrowFinish)
BadUnauthorizedRelease ==
  /\ pc = "locked"
  /\ CurrentActor = 1 /\ Manager = 0
  /\ Escrow = 1 /\ Locked = 1 /\ ConditionSet
  /\ Released' = Released + 1
  /\ DeltaReleased' = 1
  /\ DeltaRefunded' = 0
  /\ ReleasedThisCycle' = TRUE
  /\ RefundedThisCycle' = FALSE
  /\ Escrow' = 0
  /\ Locked' = 0
  /\ PrevLocked' = 1
  /\ UNCHANGED << ConditionSet, FinishAfter, CancelAfter, now,
                  Refunded, Committed, HasFulfillment,
                  CurrentActor, Manager >>     \* <<— and this
  /\ pc' = "bad"

Done ==
  /\ pc = "bad"
  /\ UNCHANGED << vars, pc, CurrentActor, Manager >>

NextG1 == Create \/ BadUnauthorizedRelease \/ Done
SpecG1 == InitG1 /\ [][NextG1]_<< vars, pc, CurrentActor, Manager >>
=============================================================================
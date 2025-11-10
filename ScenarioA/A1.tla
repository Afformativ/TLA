------------------------------ MODULE A1 ------------------------------
EXTENDS XrplEscrow

VARIABLE pc

InitA1 ==
  /\ Init
  /\ pc = "start"

StepCreate ==
  /\ pc = "start"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = FALSE
  /\ FinishAfter' = now + 1
  /\ CancelAfter' = 0
  /\ pc' = "locked"

StepTick ==
  /\ pc = "locked"
  /\ Tick
  /\ pc' = "finishable"

StepFinish ==
  /\ pc = "finishable"
  /\ EscrowFinish
  /\ pc' = "released"

StepDone ==
  /\ pc = "released"
  /\ UNCHANGED <<vars, pc>>

NextA1 ==
  StepCreate \/ StepTick \/ StepFinish \/ StepDone

SpecA1 ==
  InitA1 /\ [][NextA1]_<<vars, pc>>

GhostOK == LockedEqualsEscrow /\ ClosedImpliesAccounted
=============================================================================
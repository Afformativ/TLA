------------------------------ MODULE A2 ------------------------------
EXTENDS XrplEscrow

VARIABLE pc

InitA2 ==
  /\ Init
  /\ pc = "start"

StepCreate ==
  /\ pc = "start"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = TRUE
  /\ FinishAfter' = 0
  /\ CancelAfter' = now + 2
  /\ pc' = "locked"

StepTick1 ==
  /\ pc = "locked"
  /\ Tick
  /\ pc' = "t1"

StepTick2 ==
  /\ pc = "t1"
  /\ Tick
  /\ pc' = "expired"

StepCancel ==
  /\ pc = "expired"
  /\ EscrowCancel
  /\ pc' = "refunded"

StepDone ==
  /\ pc = "refunded"
  /\ UNCHANGED <<vars, pc>>

NextA2 ==
  StepCreate \/ StepTick1 \/ StepTick2 \/ StepCancel \/ StepDone

SpecA2 ==
  InitA2 /\ [][NextA2]_<<vars, pc>>

GhostOK == LockedEqualsEscrow /\ ClosedImpliesAccounted
=============================================================================
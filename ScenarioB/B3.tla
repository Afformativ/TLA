------------------------------ MODULE B3 ------------------------------
EXTENDS XrplEscrow

VARIABLE pc

InitB3 ==
  /\ Init
  /\ pc = "s0"

\* Normal release
C_Create ==
  /\ pc = "s0"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = FALSE
  /\ FinishAfter' = now + 1
  /\ CancelAfter' = 0
  /\ pc' = "locked"

C_Tick ==
  /\ pc = "locked"
  /\ Tick
  /\ pc' = "finishable"

C_Finish ==
  /\ pc = "finishable"
  /\ EscrowFinish
  /\ pc' = "released"

\* Retry the same Release message: should be a no-op
RetryFinishNoOp ==
  /\ pc = "released"
  /\ UNCHANGED vars
  /\ pc' = "done"

Done ==
  /\ pc = "done"
  /\ UNCHANGED <<vars, pc>>

NextB3 == C_Create \/ C_Tick \/ C_Finish \/ RetryFinishNoOp \/ Done
SpecB3 == InitB3 /\ [][NextB3]_<<vars, pc>>
=============================================================================
------------------------------ MODULE A3 ------------------------------
EXTENDS XrplEscrow

VARIABLE pc

InitA3 ==
  /\ Init
  /\ pc = "s0"

\* Cycle 1: Finish, then retry finish (idempotent)
C1_Create ==
  /\ pc = "s0"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = FALSE
  /\ FinishAfter' = now + 1
  /\ CancelAfter' = 0
  /\ pc' = "c1_locked"

C1_Tick ==
  /\ pc = "c1_locked"
  /\ Tick
  /\ pc' = "c1_finishable"

C1_Finish ==
  /\ pc = "c1_finishable"
  /\ EscrowFinish
  /\ pc' = "c1_released"

C1_RetryFinish ==
  /\ pc = "c1_released"
  /\ UNCHANGED vars
  /\ pc' = "s1"

\* Cycle 2: Cancel after expiry, then retry cancel (idempotent)
C2_Create ==
  /\ pc = "s1"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = TRUE
  /\ FinishAfter' = 0
  /\ CancelAfter' = now + 2
  /\ pc' = "c2_locked"

C2_Tick1 ==
  /\ pc = "c2_locked"
  /\ Tick
  /\ pc' = "c2_t1"

C2_Tick2 ==
  /\ pc = "c2_t1"
  /\ Tick
  /\ pc' = "c2_expired"

C2_Cancel ==
  /\ pc = "c2_expired"
  /\ EscrowCancel
  /\ pc' = "c2_refunded"

C2_RetryCancel ==
  /\ pc = "c2_refunded"
  /\ UNCHANGED vars
  /\ pc' = "done"

Done ==
  /\ pc = "done"
  /\ UNCHANGED <<vars, pc>>

NextA3 ==
  C1_Create \/ C1_Tick \/ C1_Finish \/ C1_RetryFinish \/
  C2_Create \/ C2_Tick1 \/ C2_Tick2 \/ C2_Cancel \/ C2_RetryCancel \/
  Done

SpecA3 ==
  InitA3 /\ [][NextA3]_<<vars, pc>>

GhostOK == LockedEqualsEscrow /\ ClosedImpliesAccounted
=============================================================================
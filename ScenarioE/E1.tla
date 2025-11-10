------------------------------ MODULE E1 ------------------------------
EXTENDS XrplEscrow

VARIABLE pc

InitE1 ==
  /\ Init
  /\ pc = "start"

\* Case 1: Finish allowed when now == FinishAfter (arrive by 1 tick)
C1_Create ==
  /\ pc = "start"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = FALSE
  /\ FinishAfter' = now + 1     \* strictly future at create
  /\ CancelAfter' = now + 3
  /\ pc' = "c1_wait"

C1_TickToEq ==
  /\ pc = "c1_wait"
  /\ Tick
  /\ pc' = "c1_eq"               \* now == FinishAfter

C1_FinishEq ==
  /\ pc = "c1_eq"
  /\ EscrowFinish                \* allowed at equality
  /\ pc' = "c1_released"

\* Case 2: Finish blocked when now == CancelAfter
C2_Create ==
  /\ pc = "c1_released"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = FALSE
  /\ FinishAfter' = now + 5
  /\ CancelAfter' = now + 1      \* strictly future at create
  /\ pc' = "c2_wait"

C2_TickToEq ==
  /\ pc = "c2_wait"
  /\ Tick
  /\ pc' = "c2_eqexpired"        \* now == CancelAfter

Done ==
  /\ pc \in {"c1_released","c2_eqexpired"}
  /\ UNCHANGED << vars, pc >>

NextE1 ==
  C1_Create \/ C1_TickToEq \/ C1_FinishEq \/
  C2_Create \/ C2_TickToEq \/
  Done

SpecE1 ==
  InitE1 /\ [][NextE1]_<< vars, pc >> /\
  WF_<<vars,pc>>(C1_Create) /\ WF_<<vars,pc>>(C1_TickToEq) /\ WF_<<vars,pc>>(C1_FinishEq) /\
  WF_<<vars,pc>>(C2_Create) /\ WF_<<vars,pc>>(C2_TickToEq)

\* Checks
EqExpiredBlocksFinish == (pc = "c2_eqexpired") => ~ENABLED EscrowFinish
EventuallyEqReleased  == <> (pc = "c1_released")
=============================================================================
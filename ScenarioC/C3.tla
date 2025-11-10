------------------------------ MODULE C3 ------------------------------
EXTENDS XrplEscrow

(*
We exercise boundary/precondition protection:
1) Finish at Escrow=0 must be disabled (NoEmptyFinishEnabled).
2) Once Committed hits MAX_COMM, EscrowCreate is disabled.
3) A maximal-amount escrow (Escrow=MAX_AMOUNT) can be finished safely.
*)

VARIABLE pc

NoCreateBeyondCap ==
  (Committed = MAX_COMM) => ~ENABLED EscrowCreate

InitC3 ==
  /\ Init
  /\ pc = "z_check"   \* start with zero-escrow checks

\* --- (1) At zero escrow, Finish is not enabled (checked via invariant) ---
Z_Step ==
  /\ pc = "z_check"
  /\ UNCHANGED vars
  /\ pc' = "max_cycle_create"

\* --- (2) Create+Finish once at MAX_AMOUNT (legal path) ---
Max_Create ==
  /\ pc = "max_cycle_create"
  /\ EscrowCreate
  /\ Escrow' = MAX_AMOUNT
  /\ ConditionSet' = FALSE
  /\ FinishAfter' = now + 1
  /\ CancelAfter' = 0
  /\ pc' = "max_cycle_wait"

Max_Tick ==
  /\ pc = "max_cycle_wait"
  /\ Tick
  /\ pc' = "max_cycle_finish"

Max_Finish ==
  /\ pc = "max_cycle_finish"
  /\ EscrowFinish
  /\ pc' = "fill_start"

\* --- (3) Fill capacity until Committed = MAX_COMM, then ensure create is blocked ---
Fill_Create ==
  /\ pc = "fill_start"
  /\ Committed + 2 <= MAX_COMM
  /\ EscrowCreate
  /\ Escrow' = 2
  /\ ConditionSet' = TRUE
  /\ FinishAfter' = 0
  /\ CancelAfter' = now + 1
  /\ pc' = "fill_wait"

Fill_Tick ==
  /\ pc = "fill_wait"
  /\ Tick
  /\ pc' = "fill_cancel"

Fill_Cancel ==
  /\ pc = "fill_cancel"
  /\ EscrowCancel
  /\ IF Committed = MAX_COMM
        THEN pc' = "cap_reached"
        ELSE pc' = "fill_start"

Cap_Done ==
  /\ pc = "cap_reached"
  /\ UNCHANGED vars
  /\ pc' = "done"

Done ==
  /\ pc = "done"
  /\ UNCHANGED << vars, pc >>

NextC3 ==
  Z_Step \/
  Max_Create \/ Max_Tick \/ Max_Finish \/
  Fill_Create \/ Fill_Tick \/ Fill_Cancel \/
  Cap_Done \/ Done

SpecC3 ==
  InitC3 /\ [][NextC3]_<< vars, pc >>
=============================================================================
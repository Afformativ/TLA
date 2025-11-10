------------------------------ MODULE D1 ------------------------------
EXTENDS XrplEscrow

VARIABLE pc

InitD1 ==
  /\ Init
  /\ pc = "start"

\* Create escrow where Finish is already enabled, but Cancel will be enabled after a Tick.
CreateRace ==
  /\ pc = "start"
  /\ EscrowCreate
  /\ Escrow' = 2
  /\ ConditionSet' = FALSE
  /\ FinishAfter' = now        \* finish enabled now
  /\ CancelAfter' = now + 1    \* refund enabled after time advances
  /\ pc' = "race_ready"

\* Branch 1: Finish before expiration.
FinishBranch ==
  /\ pc = "race_ready"
  /\ EscrowFinish
  /\ pc' = "released"

\* Branch 2: Time advances first, then refund (finish becomes disabled by spec).
ExpireThenRefund ==
  /\ pc = "race_ready"
  /\ Tick
  /\ pc' = "expired"

DoCancel ==
  /\ pc = "expired"
  /\ EscrowCancel
  /\ pc' = "refunded"

Done ==
  /\ pc \in {"released","refunded"}
  /\ UNCHANGED << vars, pc >>

NextD1 ==
  CreateRace \/ FinishBranch \/ ExpireThenRefund \/ DoCancel \/ Done

SpecD1 ==
  InitD1 /\ [][NextD1]_<< vars, pc >>
=============================================================================
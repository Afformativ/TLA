------------------------------ MODULE G2 ------------------------------
EXTENDS XrplEscrow

VARIABLE pc, Payer, CurrentActor

TypeOK_G2 ==
  /\ Payer \in {0,1}
  /\ CurrentActor \in {0,1}

\* Authorization rule to check: only the payer may cause a refund delta.
OnlyPayerCancels ==
  (DeltaRefunded = 0) \/ (CurrentActor = Payer)

InitG2 ==
  /\ Init
  /\ pc = "start"
  /\ Payer = 0
  /\ CurrentActor = 1

\* Create escrow that will expire so Cancel becomes enabled.
Create ==
  /\ pc = "start"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = TRUE
  /\ FinishAfter' = 0
  /\ CancelAfter' = now + 1
  /\ pc' = "locked"
  /\ UNCHANGED << Payer, CurrentActor >>

TickToExpire ==
  /\ pc = "locked"
  /\ Tick
  /\ pc' = "expired"
  /\ UNCHANGED << Payer, CurrentActor >>

\* BAD: non-payer executes cancel (base spec doesn’t model payer auth).
UnauthorizedCancel ==
  /\ pc = "expired"
  /\ CurrentActor = 1 /\ Payer = 0
  /\ EscrowCancel
  /\ pc' = "bad_refunded"
  /\ UNCHANGED << Payer, CurrentActor >>

Done ==
  /\ pc = "bad_refunded"
  /\ UNCHANGED << vars, pc, Payer, CurrentActor >>

NextG2 == Create \/ TickToExpire \/ UnauthorizedCancel \/ Done
SpecG2 == InitG2 /\ [][NextG2]_<< vars, pc, Payer, CurrentActor >>
=============================================================================
------------------------------ MODULE B1 ------------------------------
EXTENDS XrplEscrow, TLC

\* Extra ghosts just for this check
VARIABLES pc, Intended, ReleasedTo

InitB1 ==
  /\ Init
  /\ pc = "start"
  /\ Intended = 0
  /\ ReleasedTo = 0

StepCreate ==
  /\ pc = "start"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = FALSE
  /\ FinishAfter' = now + 1
  /\ CancelAfter' = 0
  /\ Intended' = 0
  /\ ReleasedTo' = ReleasedTo
  /\ pc' = "locked"

StepTick ==
  /\ pc = "locked"
  /\ Tick
  /\ Intended' = Intended
  /\ ReleasedTo' = ReleasedTo
  /\ pc' = "finishable"

\* Finish but mark funds as delivered to a wrong payee (ghost)
BadFinishWrongRecipient ==
  /\ pc = "finishable"
  /\ EscrowFinish
  /\ ReleasedTo' = 1            \* wrong recipient (Intended = 0)
  /\ Intended' = Intended
  /\ pc' = "badreleased"

Done ==
  /\ pc = "badreleased"
  /\ UNCHANGED <<vars, pc, Intended, ReleasedTo>>

NextB1 == StepCreate \/ StepTick \/ BadFinishWrongRecipient \/ Done
SpecB1 == InitB1 /\ [][NextB1]_<<vars, pc, Intended, ReleasedTo>>

\* This is the property we expect TLC to FAIL here:
RecipientOK == (DeltaReleased = 0) \/ (ReleasedTo = Intended)

TypeOK_B1 ==
  /\ Intended \in {0,1}
  /\ ReleasedTo \in {0,1}
=============================================================================
------------------------------ MODULE G3 ------------------------------
EXTENDS XrplEscrow, FiniteSets, Naturals

VARIABLE pc, SeenProofs, CurrentProof

TypeOK_G3 ==
  /\ SeenProofs \subseteq 0..10
  /\ CurrentProof \in 0..10

\* Any release delta must use a fresh proof (no replay).
NoReplayProof ==
  (DeltaReleased = 0) \/ ~(CurrentProof \in SeenProofs)

InitG3 ==
  /\ Init
  /\ pc = "start"
  /\ SeenProofs = {}
  /\ CurrentProof = 0

\* Cycle 1: legitimate conditional finish records proof 1
C1_Create ==
  /\ pc = "start"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = TRUE
  /\ FinishAfter' = 0
  /\ CancelAfter' = now + 5
  /\ pc' = "c1_locked"
  /\ UNCHANGED << SeenProofs, CurrentProof >>

C1_Finish_Legit ==
  /\ pc = "c1_locked"
  /\ EscrowFinish
  /\ CurrentProof' = 1
  /\ SeenProofs'  = SeenProofs \cup {1}
  /\ pc' = "c2_start"

\* Cycle 2: new escrow; attacker replays proof 1 (BAD) while gates are OK
C2_Create ==
  /\ pc = "c2_start"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = FALSE
  /\ FinishAfter' = 0
  /\ CancelAfter' = 0
  /\ pc' = "c2_ready"
  /\ UNCHANGED << SeenProofs, CurrentProof >>

Bad_ReplayFinish ==
  /\ pc = "c2_ready"
  /\ Escrow = 1 /\ Locked = 1
  /\ CurrentProof' = 1                 \* replay old proof
  /\ Released' = Released + 1
  /\ DeltaReleased' = 1
  /\ DeltaRefunded' = 0
  /\ ReleasedThisCycle' = TRUE
  /\ RefundedThisCycle' = FALSE
  /\ Escrow' = 0
  /\ Locked' = 0
  /\ PrevLocked' = 1
  /\ UNCHANGED << ConditionSet, FinishAfter, CancelAfter, now,
                  Refunded, Committed, HasFulfillment, SeenProofs >>
  /\ pc' = "replay_bad"

Done ==
  /\ pc = "replay_bad"
  /\ UNCHANGED << vars, pc, SeenProofs, CurrentProof >>

NextG3 ==
  C1_Create \/ C1_Finish_Legit \/
  C2_Create \/ Bad_ReplayFinish \/
  Done

SpecG3 ==
  InitG3 /\ [][NextG3]_<< vars, pc, SeenProofs, CurrentProof >>
=============================================================================
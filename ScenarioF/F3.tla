------------------------------ MODULE F3 ------------------------------
EXTENDS XrplEscrow, Integers

VARIABLE pc, GLocked, GReleased, GRefunded, GCommitted

\* Simple types for ghost totals
TypeOK_F3 ==
  /\ GLocked   \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ GReleased \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ GRefunded \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ GCommitted \in (-2*MAX_COMM)..(2*MAX_COMM)

\* Global ghost accounting must match its own sum and the ledger Committed
GhostOK_total ==
  /\ (GLocked + GReleased + GRefunded) = GCommitted
  /\ GCommitted = Committed

InitF3 ==
  /\ Init
  /\ pc = "start"
  /\ GLocked = 0
  /\ GReleased = 0
  /\ GRefunded = 0
  /\ GCommitted = 0

\* Normal create (amount = 1) mirrored into ghost totals
C_Create ==
  /\ pc = "start"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = FALSE
  /\ FinishAfter' = now + 1
  /\ CancelAfter' = 0
  /\ GLocked' = GLocked + 1
  /\ GReleased' = GReleased
  /\ GRefunded' = GRefunded
  /\ GCommitted' = GCommitted + 1
  /\ pc' = "wait"

C_Tick ==
  /\ pc = "wait"
  /\ Tick
  /\ GLocked' = GLocked
  /\ GReleased' = GReleased
  /\ GRefunded' = GRefunded
  /\ GCommitted' = GCommitted
  /\ pc' = "finishable"

C_Finish ==
  /\ pc = "finishable"
  /\ EscrowFinish
  /\ GLocked' = GLocked - 1
  /\ GReleased' = GReleased + 1
  /\ GRefunded' = GRefunded
  /\ GCommitted' = GCommitted
  /\ pc' = "skew"

\* DRIFT: global table's committed is bumped (ledger remains balanced)
Skew_GlobalCommitted ==
  /\ pc = "skew"
  /\ GLocked' = GLocked
  /\ GReleased' = GReleased
  /\ GRefunded' = GRefunded
  /\ GCommitted' = GCommitted + 1   \* BUG: drift
  /\ UNCHANGED vars
  /\ pc' = "bad_total"

Done ==
  /\ pc = "bad_total"
  /\ UNCHANGED << vars, pc, GLocked, GReleased, GRefunded, GCommitted >>

NextF3 ==
  C_Create \/ C_Tick \/ C_Finish \/ Skew_GlobalCommitted \/ Done

SpecF3 ==
  InitF3 /\ [][NextF3]_<< vars, pc, GLocked, GReleased, GRefunded, GCommitted >>
=============================================================================
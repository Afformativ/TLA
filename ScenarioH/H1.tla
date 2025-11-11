------------------------------ MODULE H1 ------------------------------
EXTENDS XrplEscrow, Integers

VARIABLE pc,
         GA_Locked, GA_Released, GA_Refunded, GA_Committed,
         GB_Locked, GB_Released, GB_Refunded, GB_Committed

TypeOK_H1 ==
  /\ GA_Locked \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ GA_Released \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ GA_Refunded \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ GA_Committed \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ GB_Locked \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ GB_Released \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ GB_Refunded \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ GB_Committed \in (-2*MAX_COMM)..(2*MAX_COMM)

GhostOK_A ==
  GA_Locked + GA_Released + GA_Refunded = GA_Committed
GhostOK_B ==
  GB_Locked + GB_Released + GB_Refunded = GB_Committed

GhostOK_LedgerMatch ==
  /\ GA_Locked + GB_Locked   = Locked
  /\ GA_Released + GB_Released = Released
  /\ GA_Refunded + GB_Refunded = Refunded
  /\ GA_Committed + GB_Committed = Committed

InitH1 ==
  /\ Init
  /\ pc = "A_start"
  /\ GA_Locked = 0 /\ GA_Released = 0 /\ GA_Refunded = 0 /\ GA_Committed = 0
  /\ GB_Locked = 0 /\ GB_Released = 0 /\ GB_Refunded = 0 /\ GB_Committed = 0

\* --- payId A: Create -> Tick -> Finish ---
A_Create ==
  /\ pc = "A_start"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = FALSE
  /\ FinishAfter' = now + 1
  /\ CancelAfter' = 0
  /\ GA_Locked' = GA_Locked + 1
  /\ GA_Committed' = GA_Committed + 1
  /\ GA_Released' = GA_Released
  /\ GA_Refunded' = GA_Refunded
  /\ UNCHANGED << GB_Locked, GB_Released, GB_Refunded, GB_Committed >>
  /\ pc' = "A_wait"

A_Tick ==
  /\ pc = "A_wait"
  /\ Tick
  /\ UNCHANGED << GA_Locked, GA_Released, GA_Refunded, GA_Committed,
                  GB_Locked, GB_Released, GB_Refunded, GB_Committed >>
  /\ pc' = "A_finishable"

A_Finish ==
  /\ pc = "A_finishable"
  /\ EscrowFinish
  /\ GA_Locked' = GA_Locked - 1
  /\ GA_Released' = GA_Released + 1
  /\ UNCHANGED << GA_Refunded, GA_Committed,
                  GB_Locked, GB_Released, GB_Refunded, GB_Committed >>
  /\ pc' = "B_start"

\* --- payId B: Create -> Tick -> Finish (interleaved) ---
B_Create ==
  /\ pc = "B_start"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = FALSE
  /\ FinishAfter' = now + 1
  /\ CancelAfter' = 0
  /\ GB_Locked' = GB_Locked + 1
  /\ GB_Committed' = GB_Committed + 1
  /\ GB_Released' = GB_Released
  /\ GB_Refunded' = GB_Refunded
  /\ UNCHANGED << GA_Locked, GA_Released, GA_Refunded, GA_Committed >>
  /\ pc' = "B_wait"

B_Tick ==
  /\ pc = "B_wait"
  /\ Tick
  /\ UNCHANGED << GA_Locked, GA_Released, GA_Refunded, GA_Committed,
                  GB_Locked, GB_Released, GB_Refunded, GB_Committed >>
  /\ pc' = "B_finishable"

B_Finish ==
  /\ pc = "B_finishable"
  /\ EscrowFinish
  /\ GB_Locked' = GB_Locked - 1
  /\ GB_Released' = GB_Released + 1
  /\ UNCHANGED << GB_Refunded, GB_Committed,
                  GA_Locked, GA_Released, GA_Refunded, GA_Committed >>
  /\ pc' = "done"

Done ==
  /\ pc = "done"
  /\ UNCHANGED << vars, pc,
                  GA_Locked, GA_Released, GA_Refunded, GA_Committed,
                  GB_Locked, GB_Released, GB_Refunded, GB_Committed >>

NextH1 ==
  A_Create \/ A_Tick \/ A_Finish \/
  B_Create \/ B_Tick \/ B_Finish \/
  Done

SpecH1 ==
  InitH1 /\ [][NextH1]_<< vars, pc,
                      GA_Locked, GA_Released, GA_Refunded, GA_Committed,
                      GB_Locked, GB_Released, GB_Refunded, GB_Committed >>
=============================================================================
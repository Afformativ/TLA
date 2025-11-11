------------------------------ MODULE H2 ------------------------------
EXTENDS XrplEscrow, Integers

VARIABLE pc,
         GA_Locked, GA_Released, GA_Refunded, GA_Committed,   \* payId A ghosts
         GB_Locked, GB_Released, GB_Refunded, GB_Committed,   \* payId B ghosts
         NetPayer, NetPayee                                   \* global net (no fee)

TypeOK_H2 ==
  /\ GA_Locked \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ GA_Released \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ GA_Refunded \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ GA_Committed \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ GB_Locked \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ GB_Released \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ GB_Refunded \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ GB_Committed \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ NetPayer \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ NetPayee \in (-2*MAX_COMM)..(2*MAX_COMM)

GhostOK_A ==
  GA_Locked + GA_Released + GA_Refunded = GA_Committed
GhostOK_B ==
  GB_Locked + GB_Released + GB_Refunded = GB_Committed
GhostOK_LedgerMatch ==
  /\ GA_Locked + GB_Locked   = Locked
  /\ GA_Released + GB_Released = Released
  /\ GA_Refunded + GB_Refunded = Refunded
  /\ GA_Committed + GB_Committed = Committed

\* Net conservation across payer+payee+escrow (no fee):
NetZero ==
  NetPayer + NetPayee + Locked = 0

InitH2 ==
  /\ Init
  /\ pc = "A_start"
  /\ GA_Locked = 0 /\ GA_Released = 0 /\ GA_Refunded = 0 /\ GA_Committed = 0
  /\ GB_Locked = 0 /\ GB_Released = 0 /\ GB_Refunded = 0 /\ GB_Committed = 0
  /\ NetPayer = 0 /\ NetPayee = 0

\* --- payId A: Create -> Tick -> Cancel (refund path) ---
A_Create ==
  /\ pc = "A_start"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = TRUE
  /\ FinishAfter' = 0
  /\ CancelAfter' = now + 1
  /\ GA_Locked' = GA_Locked + 1
  /\ GA_Committed' = GA_Committed + 1
  /\ NetPayer' = NetPayer - 1
  /\ UNCHANGED << GA_Released, GA_Refunded,
                  GB_Locked, GB_Released, GB_Refunded, GB_Committed,
                  NetPayee >>
  /\ pc' = "A_wait"

A_Tick ==
  /\ pc = "A_wait"
  /\ Tick
  /\ UNCHANGED << GA_Locked, GA_Released, GA_Refunded, GA_Committed,
                  GB_Locked, GB_Released, GB_Refunded, GB_Committed,
                  NetPayer, NetPayee >>
  /\ pc' = "A_expired"

A_Cancel ==
  /\ pc = "A_expired"
  /\ EscrowCancel
  /\ GA_Locked'   = GA_Locked - 1
  /\ GA_Refunded' = GA_Refunded + 1
  /\ UNCHANGED << GA_Released, GA_Committed,
                  GB_Locked, GB_Released, GB_Refunded, GB_Committed >>
  /\ NetPayer' = NetPayer + 1
  /\ UNCHANGED NetPayee
  /\ pc' = "B_start"

\* --- payId B: Create -> Tick -> Finish (release path) ---
B_Create ==
  /\ pc = "B_start"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = FALSE
  /\ FinishAfter' = now + 1
  /\ CancelAfter' = 0
  /\ GB_Locked' = GB_Locked + 1
  /\ GB_Committed' = GB_Committed + 1
  /\ NetPayer' = NetPayer - 1
  /\ UNCHANGED << GB_Released, GB_Refunded,
                  GA_Locked, GA_Released, GA_Refunded, GA_Committed,
                  NetPayee >>
  /\ pc' = "B_wait"

B_Tick ==
  /\ pc = "B_wait"
  /\ Tick
  /\ UNCHANGED << GA_Locked, GA_Released, GA_Refunded, GA_Committed,
                  GB_Locked, GB_Released, GB_Refunded, GB_Committed,
                  NetPayer, NetPayee >>
  /\ pc' = "B_finishable"

B_Finish ==
  /\ pc = "B_finishable"
  /\ EscrowFinish
  /\ GB_Locked'   = GB_Locked - 1
  /\ GB_Released' = GB_Released + 1
  /\ NetPayee' = NetPayee + 1
  /\ UNCHANGED << GA_Locked, GA_Released, GA_Refunded, GA_Committed,
                  GB_Refunded, GB_Committed, NetPayer >>
  /\ pc' = "done"

Done ==
  /\ pc = "done"
  /\ UNCHANGED << vars, pc,
                  GA_Locked, GA_Released, GA_Refunded, GA_Committed,
                  GB_Locked, GB_Released, GB_Refunded, GB_Committed,
                  NetPayer, NetPayee >>

NextH2 ==
  A_Create \/ A_Tick \/ A_Cancel \/
  B_Create \/ B_Tick \/ B_Finish \/
  Done

SpecH2 ==
  InitH2 /\ [][NextH2]_<< vars, pc,
                      GA_Locked, GA_Released, GA_Refunded, GA_Committed,
                      GB_Locked, GB_Released, GB_Refunded, GB_Committed,
                      NetPayer, NetPayee >>
=============================================================================
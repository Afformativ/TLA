------------------------------ MODULE C1 ------------------------------
EXTENDS XrplEscrow, Integers

(*
Fee model (ghost):
- We track net balance deltas since Init (all start at 0).
- On Create(a): Payer -= a, Escrow += a   (Escrow is represented by Locked)
- On Finish(a): Payee += (a - FEE), FeeSink += FEE, Escrow -= a
- On Cancel(a): Payer += (a - FEE), FeeSink += FEE, Escrow -= a
Invariant to check: NetPayer + NetPayee + NetFee + Locked = 0
*)

\* constant fee per Release/Refund (must be <= MAX_AMOUNT to avoid underflow)
FEE == 1

VARIABLES pc, NetPayer, NetPayee, NetFee

TypeOK_C1 ==
  /\ NetPayer \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ NetPayee \in (-2*MAX_COMM)..(2*MAX_COMM)
  /\ NetFee   \in (-2*MAX_COMM)..(2*MAX_COMM)

FeeConservationZero ==
  NetPayer + NetPayee + NetFee + Locked = 0

InitC1 ==
  /\ Init
  /\ pc = "r_start"
  /\ NetPayer = 0
  /\ NetPayee = 0
  /\ NetFee   = 0

\* ---------- Cycle R: time-locked release with fee ----------
R_Create ==
  /\ pc = "r_start"
  /\ EscrowCreate
  /\ Escrow' = 2
  /\ ConditionSet' = FALSE
  /\ FinishAfter' = now + 1
  /\ CancelAfter' = 0
  /\ NetPayer' = NetPayer - 2
  /\ NetPayee' = NetPayee
  /\ NetFee'   = NetFee
  /\ pc' = "r_locked"

R_Tick ==
  /\ pc = "r_locked"
  /\ Tick
  /\ NetPayer' = NetPayer
  /\ NetPayee' = NetPayee
  /\ NetFee'   = NetFee
  /\ pc' = "r_finishable"

R_FinishWithFee ==
  /\ pc = "r_finishable"
  /\ EscrowFinish
  /\ NetPayer' = NetPayer
  /\ NetPayee' = NetPayee + (Escrow - FEE)
  /\ NetFee'   = NetFee + FEE
  /\ pc' = "c_start"

\* ---------- Cycle C: conditional escrow refunded after expiry with fee ----------
C_Create ==
  /\ pc = "c_start"
  /\ EscrowCreate
  /\ Escrow' = 2
  /\ ConditionSet' = TRUE
  /\ FinishAfter' = 0
  /\ CancelAfter' = now + 2
  /\ NetPayer' = NetPayer - 2
  /\ NetPayee' = NetPayee
  /\ NetFee'   = NetFee
  /\ pc' = "c_locked"

C_Tick1 ==
  /\ pc = "c_locked"
  /\ Tick
  /\ NetPayer' = NetPayer
  /\ NetPayee' = NetPayee
  /\ NetFee'   = NetFee
  /\ pc' = "c_t1"

C_Tick2 ==
  /\ pc = "c_t1"
  /\ Tick
  /\ NetPayer' = NetPayer
  /\ NetPayee' = NetPayee
  /\ NetFee'   = NetFee
  /\ pc' = "c_expired"

C_CancelWithFee ==
  /\ pc = "c_expired"
  /\ EscrowCancel
  /\ NetPayer' = NetPayer + (Escrow - FEE)
  /\ NetPayee' = NetPayee
  /\ NetFee'   = NetFee + FEE
  /\ pc' = "done"

Done ==
  /\ pc = "done"
  /\ UNCHANGED << vars, pc, NetPayer, NetPayee, NetFee >>

NextC1 ==
  R_Create \/ R_Tick \/ R_FinishWithFee \/
  C_Create \/ C_Tick1 \/ C_Tick2 \/ C_CancelWithFee \/
  Done

SpecC1 ==
  InitC1 /\ [][NextC1]_<< vars, pc, NetPayer, NetPayee, NetFee >>
=============================================================================
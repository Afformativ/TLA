------------------------------ MODULE B2 ------------------------------
EXTENDS XrplEscrow, TLC

VARIABLE pc

InitB2 ==
  /\ Init
  /\ pc = "start"

C_Create ==
  /\ pc = "start"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = FALSE
  /\ FinishAfter' = now + 1
  /\ CancelAfter' = 0
  /\ pc' = "locked"

C_Tick ==
  /\ pc = "locked"
  /\ Tick
  /\ pc' = "finishable"

\* BAD finish: release amount d != Escrow (either too small or too large)
BadFinishWrongAmount ==
  /\ pc = "finishable"
  /\ \E d \in {Escrow-1, Escrow+1}:
        /\ d \in 0..MAX_AMOUNT /\ d # Escrow
        /\ Escrow' = 0
        /\ Locked' = 0
        /\ Released' = Released + d
        /\ DeltaReleased' = d
        /\ DeltaRefunded' = 0
        /\ ReleasedThisCycle' = TRUE
        /\ RefundedThisCycle' = FALSE
        /\ HasFulfillment' = TRUE
        /\ PrevLocked' = Locked
        /\ UNCHANGED <<ConditionSet, FinishAfter, CancelAfter, now,
                       Refunded, Committed>>     \* Committed unchanged -> breaks Conservation
  /\ pc' = "badreleased"

Done ==
  /\ pc = "badreleased"
  /\ UNCHANGED <<vars, pc>>

NextB2 == C_Create \/ C_Tick \/ BadFinishWrongAmount \/ Done
SpecB2 == InitB2 /\ [][NextB2]_<<vars, pc>>
=============================================================================
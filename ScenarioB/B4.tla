------------------------------ MODULE B4 ------------------------------
EXTENDS XrplEscrow

VARIABLE pc

InitB4 ==
  /\ Init
  /\ pc = "start"

C_Create ==
  /\ pc = "start"
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = TRUE
  /\ FinishAfter' = 0
  /\ CancelAfter' = now + 1
  /\ pc' = "locked"

C_Tick ==
  /\ pc = "locked"
  /\ Tick
  /\ pc' = "expired"

C_Cancel ==
  /\ pc = "expired"
  /\ EscrowCancel
  /\ pc' = "refunded"

\* BAD: attempt to release AFTER refund; should violate ExclusiveOutcome
BadFinishAfterCancel ==
  /\ pc = "refunded"
  /\ Escrow = 0 /\ Locked = 0          \* escrow already closed by cancel
  /\ Released' = Released + 1
  /\ DeltaReleased' = 1
  /\ DeltaRefunded' = DeltaRefunded
  /\ ReleasedThisCycle' = TRUE
  /\ RefundedThisCycle' = TRUE          \* both TRUE -> exclusivity breaks
  /\ PrevLocked' = Locked
  /\ UNCHANGED << ConditionSet, FinishAfter, CancelAfter, now,
                  Escrow, Locked, Refunded, Committed, HasFulfillment >>
  /\ pc' = "badreleased"

Done ==
  /\ pc = "badreleased"
  /\ UNCHANGED << vars, pc >>

NextB4 == C_Create \/ C_Tick \/ C_Cancel \/ BadFinishAfterCancel \/ Done
SpecB4 == InitB4 /\ [][NextB4]_<<vars, pc>>
=============================================================================
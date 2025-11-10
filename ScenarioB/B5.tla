------------------------------ MODULE B5 ------------------------------
EXTENDS XrplEscrow

VARIABLE pc

InitB5 ==
  /\ Init
  /\ pc = "s0"

\* BAD: try to "release" funds when there is no escrow
BadReleaseWithoutLock ==
  /\ pc = "s0"
  /\ Escrow = 0 /\ Locked = 0
  /\ Released' = Released + 1
  /\ DeltaReleased' = 1
  /\ ReleasedThisCycle' = TRUE
  /\ RefundedThisCycle' = FALSE
  /\ PrevLocked' = Locked
  /\ UNCHANGED << Escrow, ConditionSet, FinishAfter, CancelAfter, now,
                  Locked, Refunded, Committed, DeltaRefunded, HasFulfillment >>
  /\ pc' = "badreleased"

Done ==
  /\ pc = "badreleased"
  /\ UNCHANGED << vars, pc >>

NextB5 == BadReleaseWithoutLock \/ Done
SpecB5 == InitB5 /\ [][NextB5]_<<vars, pc>>
=============================================================================
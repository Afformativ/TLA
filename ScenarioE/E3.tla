------------------------------ MODULE E3 ------------------------------
EXTENDS XrplEscrow

VARIABLE pc

InitE3 ==
  /\ Init
  /\ pc = "idle"

TickWhilePossible ==
  /\ pc = "idle"
  /\ Tick
  /\ IF now' = MAX_TIME THEN pc' = "done" ELSE pc' = "idle"

Done ==
  /\ pc = "done"
  /\ UNCHANGED << vars, pc >>

NextE3 == TickWhilePossible \/ Done
SpecE3 == InitE3 /\ [][NextE3]_<< vars, pc >>

GhostOK == LockedEqualsEscrow /\ ClosedImpliesAccounted
=============================================================================
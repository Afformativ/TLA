------------------------------ MODULE D2 ------------------------------
EXTENDS XrplEscrow, FiniteSets, Naturals

VARIABLES pc, SeenIds, CurrId

TypeOK_D2 ==
  /\ CurrId \in 0..10
  /\ SeenIds \subseteq 0..10

InitD2 ==
  /\ Init
  /\ pc = "start"
  /\ SeenIds = {}
  /\ CurrId = 1

\* First commit with CurrId = 1 (unique)
CreateUnique ==
  /\ pc = "start"
  /\ ~(CurrId \in SeenIds)
  /\ EscrowCreate
  /\ Escrow' = 1
  /\ ConditionSet' = FALSE
  /\ FinishAfter' = now + 1
  /\ CancelAfter' = 0
  /\ SeenIds' = SeenIds \cup {CurrId}
  /\ CurrId' = CurrId
  /\ pc' = "locked"

Tick1 ==
  /\ pc = "locked"
  /\ Tick
  /\ UNCHANGED << SeenIds, CurrId >>
  /\ pc' = "finishable"

Finish1 ==
  /\ pc = "finishable"
  /\ EscrowFinish
  /\ UNCHANGED << SeenIds, CurrId >>
  /\ pc' = "dup_attempt"

\* Attempt duplicate commit with the SAME CurrId (rejected: no state change to ledger vars)
DuplicateCommitRejected ==
  /\ pc = "dup_attempt"
  /\ CurrId \in SeenIds
  /\ UNCHANGED vars
  /\ UNCHANGED << SeenIds, CurrId >>
  /\ pc' = "dup_rejected"

\* Force client to use a new id, then proceed normally if desired
UseNewId ==
  /\ pc = "dup_rejected"
  /\ CurrId' = CurrId + 1
  /\ UNCHANGED << vars, SeenIds >>
  /\ pc' = "done"

Done ==
  /\ pc = "done"
  /\ UNCHANGED << vars, pc, SeenIds, CurrId >>

NextD2 ==
  CreateUnique \/ Tick1 \/ Finish1 \/ DuplicateCommitRejected \/ UseNewId \/ Done

SpecD2 ==
  InitD2 /\ [][NextD2]_<< vars, pc, SeenIds, CurrId >> /\
  WF_<<vars, pc, SeenIds, CurrId>>(DuplicateCommitRejected) /\
  WF_<<vars, pc, SeenIds, CurrId>>(UseNewId)


\* If CurrId is already seen, a new EscrowCreate must not be enabled.
NoDupCommitEnabled ==
  (CurrId \in SeenIds) => ~ENABLED EscrowCreate

\* Sanity: when we reach the duplicate attempt step, the id must be known.
AtDupAttemptSeen ==
  (pc = "dup_attempt") => (CurrId \in SeenIds)

  \* From any dup attempt, we eventually reach the rejected state.
DupEventuallyRejected ==
  [] ( (pc = "dup_attempt") => <> (pc = "dup_rejected") )
=============================================================================
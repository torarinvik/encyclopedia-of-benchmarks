# Rights and provenance

This is a clean-room implementation of the Farey-sequence successor
algorithm. RosettaGit's [task page](https://rosettagit.org/tasks/farey-sequence/)
was used to identify the task and its broad semantics. The recurrence and
mathematical properties were checked against [MathWorld](https://mathworld.wolfram.com/FareySequence.html)
and Pătrașcu and Pătrașcu's [paper](https://people.csail.mit.edu/mip/papers/farey/farey.pdf).
The pinned [RosettaCodeData popular-title index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
was used for discovery only.

No source code, task prose, sample output list, or tests were copied. The
language ports, input/output contract, oracle implementations, workload,
inventory, and documentation were independently authored. The independent
reference uses gcd enumeration and exact cross-product sorting, a different
method from the native adjacent-term recurrence.

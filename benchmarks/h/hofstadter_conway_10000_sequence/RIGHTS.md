# Source and rights notes

This package is a clean-room implementation of a mathematical recurrence.
No source code, fixtures, or problem text were copied.

- The sequence definition and initial values are documented by OEIS entry
  [A004001](https://oeis.org/A004001) and by Eric W. Weisstein,
  [Hofstadter-Conway $10,000 Sequence](https://mathworld.wolfram.com/Hofstadter-Conway10000Sequence.html).
- The published analysis cited for the sequence is T. Kubo and R. Vakil,
  [“On Conway's recursive sequence,” *Discrete Mathematics* 152 (1996),
  225–252](https://doi.org/10.1016/0012-365X(94)00303-Z).
- The RosettaGit public title index was used only to discover the task name:
  [RosettaGit task index](https://rosettagit.org/tasks/). No task page or
  implementation was used.

The algorithmic recurrence is expressed independently in the native ports and
Python references. The workload contains original bounded fixtures; the
power-of-two expected values follow from the published property
`a(2^k)=2^(k-1)`.

# Rights and provenance

The RosettaGit Maze generation page was used only to discover the task family
and confirm that maze construction is an established cross-language exercise:
https://rosettagit.org/tasks/maze-generation/.

The recursive-backtracker profile was independently checked against Matej
Gabrovsek, *Analysis of Maze Generating Algorithms* (2019):
https://ipsitransactions.org/journals/papers/tir/2019jan/p5.pdf. The output's
spanning-tree property was cross-checked against the recursive-backtracker
discussion in an Ohio State thesis on maze generation:
https://etd.ohiolink.edu/acprod/odb_etd/ws/send_file/send?accession=osu1563286393237089&disposition=inline.

No source code, problem text, examples, submissions, or tests were copied. The
bounded rectangular contract, explicit neighbor-choice tape, byte wall-mask
encoding, workload, references, and language implementations are original to
this benchmark package. The tape makes the selected DFS trace reproducible;
it does not assert uniform spanning-tree sampling.

# Irving stable roommates

This profile decides whether a stable matching exists for one even-sized set
with complete, strict preference rankings. Unlike stable marriage, a stable
roommates instance can have no solution. Irving's algorithm first removes
choices ruled out by proposal rejections, then repeatedly eliminates
all-or-nothing rotations until every remaining list is a singleton or one
becomes empty. Its worst-case running time is O(n²).

## Contract

Input is `[n, preference rows...]`. `n` is even and in `2..8`; each of the
`n` rows contains a permutation of the other `n-1` person IDs in
`0..n-1`, ordered from most to least preferred. The exact input length is
`1 + n*(n-1)`. The scalar result is `1` if a stable matching exists and `0`
if it does not. Malformed input returns `-1`.

The primary oracle implements Irving's two-phase list-reduction algorithm.
The independent oracle enumerates every pairing and rejects any matching with
a blocking pair. The small bound keeps that independent decision procedure
bounded while exercising both proposal reductions and rotation elimination.
The workload includes a size-eight instance with three stable matchings; the
benchmark observes existence only, avoiding a tie to one of several valid
outputs.

The complete ranking table contains at most 56 entries. Ports use fixed
storage within the declared 32,768-byte workspace.

The algorithm idea follows Robert W. Irving, [“An efficient algorithm for the
stable roommates problem”](https://doi.org/10.1016/0196-6774(85)90033-1),
*Journal of Algorithms* 6(4), 1985. A public copy of the paper is available
[here](https://www.cse.iitb.ac.in/~swaprava/courses/cs6002/papers/irving85stable-roommates.pdf).
Only the algorithm description and published examples were consulted; this
contract, workload, oracles, and ports are independently authored.

| Language | Port |
|---|---|
| C | [c/s/stable_roommates.c](../../../c/s/stable_roommates.c) |
| C3 | [c3/s/stable_roommates.c3](../../../c3/s/stable_roommates.c3) |
| C++ | [cpp/s/stable_roommates.cpp](../../../cpp/s/stable_roommates.cpp) |
| Elisa | [elisa/s/stable_roommates.elisa](../../../elisa/s/stable_roommates.elisa) |
| Mojo | [mojo/s/stable_roommates.mojo](../../../mojo/s/stable_roommates.mojo) |
| Nim | [nim/s/stable_roommates.nim](../../../nim/s/stable_roommates.nim) |
| Odin | [odin/s/stable_roommates.odin](../../../odin/s/stable_roommates.odin) |
| Rust | [rust/s/stable_roommates.rs](../../../rust/s/stable_roommates.rs) |
| V | [v/s/stable_roommates.v](../../../v/s/stable_roommates.v) |
| Zig | [zig/s/stable_roommates.zig](../../../zig/s/stable_roommates.zig) |

# Clock Patience simulation

This package replays the deterministic Clock Patience reveal chain for a
caller-supplied 52-card deal. It follows the direct pile simulation described
in Knuth's *The Art of Computer Programming*, Volume 1, Exercise 16, and the
independent rules summary from University College Dublin. The public [Codewars
Algorithms title listing](https://www.codewars.com/kata/search?tags=Algorithms)
was used only to discover the game; no kata page or task content was consulted.

## Contract

- Input is exactly 52 signed 64-bit rank values. Four consecutive values form
  each pile, in pile-major order: piles 1 through 12, then the center pile 13.
  Each pile's four values are ordered top to bottom.
- Suit is not part of the input because the game uses card rank alone.
- Ranks are 1 through 13, each occurring exactly four times. Ace is 1, jack is
  11, queen is 12, and king is 13.
- Start by revealing the top card of pile 13. Each revealed rank chooses the
  next pile with the same number. Stop when that pile has no unrevealed cards.
- Return 1 if all 52 cards were revealed, 0 if the chain stops while any card
  remains face down, and -1 for a null input, wrong length, out-of-range rank,
  or wrong rank multiplicity.
- This measures a supplied deal only. It does not shuffle cards or estimate a
  win probability.

The primary reference replays the card chain with one cursor per pile. The
independent reference uses Knuth's bottom-card theorem: for piles 1 through 12,
draw an arc to the pile named by that pile's bottom card. The game is won iff
these arcs form a tree spanning all 13 piles and rooted at the center. The
bottom card of the center pile is irrelevant to that test. This independent
criterion avoids replaying the 52-card sequence.

The algorithm uses O(52) time and O(13) cursor space. The tree oracle also uses
O(13²) time and O(13) temporary state.

## Workload and static review

[`workload.json`](workload.json) pins a spanning-tree win, a self-loop loss, a
win after changing the center pile's bottom card, malformed lengths and ranks,
an extra trailing value, and null inputs.
[`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py) are structurally independent.
The static inventory checker is `check_inventory.py`; the shared
`i64_array_scalar` suite includes the package workload and references.

## Independent references

- D. E. Knuth, *The Art of Computer Programming*, Volume 1, Exercise 16,
  reproduced in [Stanford's recreational-CS PDF](https://cs.stanford.edu/~knuth/recreational-cs.pdf).
  The exercise states the bottom-card directed-tree characterization and
  defines winning as exposing all 52 cards.
- University College Dublin, [How to play Clock Patience](https://maths.ucd.ie/openday/97/how2cp.html).
  The page defines the 13 piles, center start, rank-directed moves, and win
  condition.

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/c/clock_patience_simulation.c`](../../../c/c/clock_patience_simulation.c) |
| C3 | [`c3/c/clock_patience_simulation.c3`](../../../c3/c/clock_patience_simulation.c3) |
| C++ | [`cpp/c/clock_patience_simulation.cpp`](../../../cpp/c/clock_patience_simulation.cpp) |
| Elisa | [`elisa/c/clock_patience_simulation.elisa`](../../../elisa/c/clock_patience_simulation.elisa) |
| Mojo | [`mojo/c/clock_patience_simulation.mojo`](../../../mojo/c/clock_patience_simulation.mojo) |
| Nim | [`nim/c/clock_patience_simulation.nim`](../../../nim/c/clock_patience_simulation.nim) |
| Odin | [`odin/c/clock_patience_simulation.odin`](../../../odin/c/clock_patience_simulation.odin) |
| Rust | [`rust/c/clock_patience_simulation.rs`](../../../rust/c/clock_patience_simulation.rs) |
| V | [`v/c/clock_patience_simulation.v`](../../../v/c/clock_patience_simulation.v) |
| Zig | [`zig/c/clock_patience_simulation.zig`](../../../zig/c/clock_patience_simulation.zig) |

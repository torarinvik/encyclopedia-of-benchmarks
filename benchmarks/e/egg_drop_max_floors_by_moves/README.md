# Egg Drop Maximum Floors by Moves

Given an egg count and a fixed drop budget, return the greatest number of
contiguous floors whose critical threshold can always be distinguished. This
profiles the move-to-coverage recurrence as a timed primary. The existing
[`egg_dropping`](../egg_dropping/README.md) and
[`egg_dropping_puzzle`](../egg_dropping_puzzle/README.md) primaries accept a
floor count and compute the minimum worst-case number of drops instead.

## Contract

Input is `[eggs, moves]`, with `0 <= eggs,moves <= 32`. Zero eggs or zero moves
cover zero floors. The result is in `0..4,294,967,295`; malformed arrays,
null input, and values outside the bounds return `-1`. The recurrence ports
use a fixed 33-element signed 64-bit state array (264 bytes).

## Move-count recurrence

Let `covered[e]` be the maximum number of floors distinguishable with `e` eggs
after the already processed number of moves. For each additional move, update
egg counts in descending order:

`covered[e] = covered[e] + covered[e-1] + 1`.

The broken outcome covers `covered[e-1]` floors below the test floor, the
current test floor contributes one, and the intact outcome covers
`covered[e]` floors above it. Descending updates preserve the prior-move value
of `covered[e-1]`. Boardman also derives the independent identity
`sum(C(moves,j), j=1..eggs)`, used by the reference oracle. See
[the paper](https://doi.org/10.1080/0025570X.2004.11953281) and its
[JSTOR record](https://www.jstor.org/stable/3219201), plus [`RIGHTS.md`](RIGHTS.md)
and [`INVENTORY.md`](INVENTORY.md).

| Language | Source |
| --- | --- |
| C | [`c/e/egg_drop_max_floors_by_moves.c`](../../../c/e/egg_drop_max_floors_by_moves.c) |
| C3 | [`c3/e/egg_drop_max_floors_by_moves.c3`](../../../c3/e/egg_drop_max_floors_by_moves.c3) |
| C++ | [`cpp/e/egg_drop_max_floors_by_moves.cpp`](../../../cpp/e/egg_drop_max_floors_by_moves.cpp) |
| Elisa | [`elisa/e/egg_drop_max_floors_by_moves.elisa`](../../../elisa/e/egg_drop_max_floors_by_moves.elisa) |
| Mojo | [`mojo/e/egg_drop_max_floors_by_moves.mojo`](../../../mojo/e/egg_drop_max_floors_by_moves.mojo) |
| Nim | [`nim/e/egg_drop_max_floors_by_moves.nim`](../../../nim/e/egg_drop_max_floors_by_moves.nim) |
| Odin | [`odin/e/egg_drop_max_floors_by_moves.odin`](../../../odin/e/egg_drop_max_floors_by_moves.odin) |
| Rust | [`rust/e/egg_drop_max_floors_by_moves.rs`](../../../rust/e/egg_drop_max_floors_by_moves.rs) |
| V | [`v/e/egg_drop_max_floors_by_moves.v`](../../../v/e/egg_drop_max_floors_by_moves.v) |
| Zig | [`zig/e/egg_drop_max_floors_by_moves.zig`](../../../zig/e/egg_drop_max_floors_by_moves.zig) |

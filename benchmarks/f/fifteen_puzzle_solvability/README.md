# 15-puzzle solvability

Classify whether a valid 4-by-4 sliding-puzzle state can reach the canonical
goal `[1,2,...,15,0]` through legal moves that slide a neighboring tile into the
blank. This is a constant-workspace parity test; it does not search for a move
sequence.

## Contract

The `i64_array_scalar` symbol is `fifteen_puzzle_solvability`. Input is exactly
16 row-major signed 64-bit values containing each tile `0..15` once, with `0`
representing the blank. Return `1` for solvable states and `0` for
parity-incompatible states. Null input, malformed length, or a non-permutation
returns `-1`. The valid input length is 16; the parser accepts a maximum frame
of 17 values so a trailing-cell case is rejected explicitly.
The workload declares 64 bytes for fixed scalar bookkeeping; the ports require
no dynamic allocation.

The primary algorithm counts inversions in the row-major sequence after
removing the blank, then adds the blank's 1-based row from the top. The state is
solvable exactly when that sum is even. The independent oracle maps every tile
to its position in the canonical goal, computes the parity of the full
permutation through its cycle decomposition, and compares it with the blank's
checkerboard color. Each legal move flips both parities, so their equality is
invariant. Both methods take O(1) time for the fixed board size and use O(1)
auxiliary space.

## Distinctness and provenance

[`a_star_search`](../../a/a_star_search/README.md) provides a general graph-path
operation and uses a sliding puzzle only as an example state space. It does not
classify arbitrary boards by the parity invariant, and this package does not
search states or return paths.

The algorithm description is from [CP-Algorithms, “15 Puzzle Game: Existence
Of The Solution”](https://cp-algorithms.com/others/15-puzzle.html), licensed
under CC BY-SA 4.0. Only the high-level invariant is used; all code, oracle
formulations, and fixtures are clean-room. See [`RIGHTS.md`](RIGHTS.md),
[`workload.json`](workload.json), the [primary oracle](primary_oracle.py), the
[independent oracle](independent_oracle.py), and the [static package checker](verify_fifteen_puzzle_solvability_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/f/fifteen_puzzle_solvability.c`](../../../c/f/fifteen_puzzle_solvability.c) |
| C3 | [`c3/f/fifteen_puzzle_solvability.c3`](../../../c3/f/fifteen_puzzle_solvability.c3) |
| C++ | [`cpp/f/fifteen_puzzle_solvability.cpp`](../../../cpp/f/fifteen_puzzle_solvability.cpp) |
| Elisa | [`elisa/f/fifteen_puzzle_solvability.elisa`](../../../elisa/f/fifteen_puzzle_solvability.elisa) |
| Mojo | [`mojo/f/fifteen_puzzle_solvability.mojo`](../../../mojo/f/fifteen_puzzle_solvability.mojo) |
| Nim | [`nim/f/fifteen_puzzle_solvability.nim`](../../../nim/f/fifteen_puzzle_solvability.nim) |
| Odin | [`odin/f/fifteen_puzzle_solvability.odin`](../../../odin/f/fifteen_puzzle_solvability.odin) |
| Rust | [`rust/f/fifteen_puzzle_solvability.rs`](../../../rust/f/fifteen_puzzle_solvability.rs) |
| V | [`v/f/fifteen_puzzle_solvability.v`](../../../v/f/fifteen_puzzle_solvability.v) |
| Zig | [`zig/f/fifteen_puzzle_solvability.zig`](../../../zig/f/fifteen_puzzle_solvability.zig) |

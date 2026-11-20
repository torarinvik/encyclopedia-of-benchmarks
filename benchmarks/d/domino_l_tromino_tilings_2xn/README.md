# Domino and L-tromino tilings of a 2×n board

Count complete tilings of a `2 × n` rectangle using 2-cell dominoes and
3-cell L-shaped trominoes, allowing every rotation and reflection of the
L-piece. Distinct placements of tiles count as distinct tilings.

## Bounded contract

The exported `domino_l_tromino_tilings_2xn` symbol uses the
`i64_array_scalar` ABI. Input is exactly one signed 64-bit word `[n]`, with
`0 <= n <= 32`. The maximum valid input length is one word and the maximum
parseable length is two. The result is the exact number of tilings; invalid,
null, or malformed input returns `-1`. Counts through `n=32` fit signed 64-bit.
The primary uses four frontier counts and less than 256 bytes of working
storage.

The primary processes columns from left to right. A two-bit state records
which cells in the current column were already occupied by tiles that crossed
the preceding boundary. The four-state transition table is derived from
vertical/horizontal domino placements and the four possible missing corners
of an L tromino in a `2 × 2` block. Only state zero after the final column is a
complete board. This is a bounded `O(n)` frontier dynamic program. The
independent reference uses the scalar recurrence
`a(0)=1, a(1)=1, a(2)=2`, `a(n)=2a(n-1)+a(n-3)` for `n>=3`, derived for this
tile set by Dresden and Tulskikh.

With mask bit 0 for the top cell and bit 1 for the bottom cell, the
per-column transitions (each with multiplicity one) are `0 -> {0,1,2,3}`,
`1 -> {2,3}`, `2 -> {1,3}`, and `3 -> {0}`. The choices account for the
vertical domino, paired horizontal dominoes, and each legal L-tromino
orientation without overlap.

The prefix is `1, 1, 2, 5, 11, 24, 53, 117, ...`; at the maximum workload
width, the exact count is `a(32)=45,300,228,866`. This differs from local
[`tilingproblem`](../../t/tilingproblem/README.md), which permits dominoes
only and uses a Fibonacci recurrence; from
[`broken_profile_domino_tilings`](../../b/broken_profile_domino_tilings/README.md),
which supports arbitrary bounded rectangles but only domino placements; and
from [`tiling_problem`](../../t/tiling_problem/README.md), which constructs a
single L-tromino tiling of a power-of-two board with one hole. General
[`linear_recurrence_matrix`](../../l/linear_recurrence_matrix/README.md) and
[`bostan_mori_recurrence_term`](../../b/bostan_mori_recurrence_term/README.md)
evaluate supplied recurrences by matrix or generating-function methods; the
primary here counts geometric placements with a tile-specific frontier.

## Sources, rights, and files

The public Codewars title [“Dominoes and L-Trominoes on a Very Long Board”](https://www.codewars.com/kata/6ac3dbb358ef7bac7b16dd52)
was used only for discovery. The method comes from Dresden and Tulskikh,
[“Tiling a 2×n Board with Dominos and L-Shaped Trominos”](https://cs.uwaterloo.ca/journals/JIS/VOL24/Dresden2/dresden9.pdf),
which establishes the recurrence, and the independent OEIS
[A052980 table](https://oeis.org/A052980/list). No kata statement, examples,
tests, submissions, or code were copied. See [RIGHTS.md](RIGHTS.md).

- [`primary_oracle.py`](primary_oracle.py): four-state frontier DP.
- [`independent_oracle.py`](independent_oracle.py): scalar recurrence.
- [`workload.json`](workload.json): published values and malformed-input cases.
- [`check_inventory.py`](check_inventory.py): static inventory and fixture
  consistency helper; it does not compile or run language ports.
- [`INVENTORY.md`](INVENTORY.md): ten language source paths.

| Language | Source |
| --- | --- |
| C | [`c/d/domino_l_tromino_tilings_2xn.c`](../../../c/d/domino_l_tromino_tilings_2xn.c) |
| C3 | [`c3/d/domino_l_tromino_tilings_2xn.c3`](../../../c3/d/domino_l_tromino_tilings_2xn.c3) |
| C++ | [`cpp/d/domino_l_tromino_tilings_2xn.cpp`](../../../cpp/d/domino_l_tromino_tilings_2xn.cpp) |
| Elisa | [`elisa/d/domino_l_tromino_tilings_2xn.elisa`](../../../elisa/d/domino_l_tromino_tilings_2xn.elisa) |
| Mojo | [`mojo/d/domino_l_tromino_tilings_2xn.mojo`](../../../mojo/d/domino_l_tromino_tilings_2xn.mojo) |
| Nim | [`nim/d/domino_l_tromino_tilings_2xn.nim`](../../../nim/d/domino_l_tromino_tilings_2xn.nim) |
| Odin | [`odin/d/domino_l_tromino_tilings_2xn.odin`](../../../odin/d/domino_l_tromino_tilings_2xn.odin) |
| Rust | [`rust/d/domino_l_tromino_tilings_2xn.rs`](../../../rust/d/domino_l_tromino_tilings_2xn.rs) |
| V | [`v/d/domino_l_tromino_tilings_2xn.v`](../../../v/d/domino_l_tromino_tilings_2xn.v) |
| Zig | [`zig/d/domino_l_tromino_tilings_2xn.zig`](../../../zig/d/domino_l_tromino_tilings_2xn.zig) |

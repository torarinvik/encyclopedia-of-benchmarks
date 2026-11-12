# Hunt–Szymanski sparse LCS

This package computes the length of a longest common subsequence by processing
only matching symbol-position pairs and maintaining the minimum-tail frontier
of an increasing subsequence. It measures a different computation from the
repository's one-row prefix dynamic program: its work scales with the number of
matching pairs `R`.

## Bounded contract

The `i64_array_scalar` entry point is
`hunt_szymanski_lcs(input, length) -> i64`. The input is
`[left_length, right_length, left_symbols..., right_symbols...]`. Both sequence
lengths are in `0..=64`, each symbol is an ASCII value in `0..=127`, and the
packed frame must contain exactly `2 + left_length + right_length` values. A
valid call returns the LCS length; malformed frames or out-of-range values
return `-1`. The input pointer must address the full declared frame.

The fixed-position-list implementation stores at most 64 right-side positions
for each of 128 symbols and at most 64 LIS tails, using at most 33,536 bytes of
local integer storage with 32-bit positions. Its time is
`O(n + m + R log(min(n,m)+1))`, where `R` is the number of equal-symbol
position pairs; the worst case is `O(n*m*log(min(n,m)+1))`. The local cap is
deliberately small and does not claim an asymptotic speedup on dense matches.

For each left-side symbol, its matching right-side positions are visited in
descending order so a single left position cannot contribute twice to a
strictly increasing subsequence. A lower-bound search updates the earliest
right endpoint for each achievable subsequence length. The result is the
frontier length.

## Distinction from local LCS packages

[`longest_common_subsequence`](../../l/longest_common_subsequence/README.md) uses
the standard one-row prefix recurrence and returns only the length.
[`rle_lcs_block_dp`](../../r/rle_lcs_block_dp/README.md) works on run-length encoded
input with a block recurrence. This package instead enumerates sparse matching
pairs and performs a tails/LIS update. It is a distinct algorithmic method for
the same LCS length objective.

## Oracles and workload

[`primary_oracle.py`](primary_oracle.py) independently implements the
matching-pair/LIS method. [`independent_oracle.py`](independent_oracle.py) uses
a full-table LCS recurrence. [`workload.json`](workload.json) covers empty
sequences, repeated and disjoint symbols, sparse matches, maximum-length dense
and disjoint inputs, and malformed frames. [`verify_workload.py`](verify_workload.py)
statically checks fixture/oracle agreement, provenance, and all ten port paths;
it does not launch benchmark programs.

## Provenance

Hunt and Szymanski introduced the algorithm in “A fast algorithm for computing
longest common subsequences,” *Communications of the ACM* 20(5), 1977,
[DOI 10.1145/359581.359603](https://doi.org/10.1145/359581.359603). The package
uses the paper's algorithm description only; see [`RIGHTS.md`](RIGHTS.md).

## Implementations

| Language | Source |
|---|---|
| C | [`c/h/hunt_szymanski_lcs.c`](../../../c/hunt_szymanski_lcs.c) |
| C3 | [`c3/h/hunt_szymanski_lcs.c3`](../../../c3/hunt_szymanski_lcs.c3) |
| C++ | [`cpp/h/hunt_szymanski_lcs.cpp`](../../../cpp/hunt_szymanski_lcs.cpp) |
| Elisa | [`elisa/h/hunt_szymanski_lcs.elisa`](../../../elisa/h/hunt_szymanski_lcs.elisa) |
| Mojo | [`mojo/h/hunt_szymanski_lcs.mojo`](../../../mojo/h/hunt_szymanski_lcs.mojo) |
| Nim | [`nim/h/hunt_szymanski_lcs.nim`](../../../nim/h/hunt_szymanski_lcs.nim) |
| Odin | [`odin/h/hunt_szymanski_lcs.odin`](../../../odin/h/hunt_szymanski_lcs.odin) |
| Rust | [`rust/h/hunt_szymanski_lcs.rs`](../../../rust/h/hunt_szymanski_lcs.rs) |
| V | [`v/h/hunt_szymanski_lcs.v`](../../../v/hunt_szymanski_lcs.v) |
| Zig | [`zig/h/hunt_szymanski_lcs.zig`](../../../zig/h/hunt_szymanski_lcs.zig) |

The shared `i64_array_scalar` suite validates the bounded workload and compares
all ten ports against the independent full-table dynamic-programming oracle.

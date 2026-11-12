# Hirschberg linear-space LCS reconstruction

This package reconstructs and returns one longest common subsequence using
Hirschberg's divide-and-conquer traceback. It splits the longer sequence at
its midpoint, computes forward and backward one-row LCS values, and recurses
through a maximizing split. The rows are shared between recursive calls, so
the algorithm does not retain a row per recursion level.

## Contract

The `i64_array_bytes_output` symbol is
`hirschberg_lcs(input, length, output, capacity) -> i64`. Input is
`[first_length, second_length, first_symbols..., second_symbols...]`. Each
length is in `0..=64`, symbols are ASCII values `0..=127`, and the packed
frame must contain exactly `2 + first_length + second_length` signed 64-bit
values. Invalid input returns `-1` before output checks.

The output bytes are the symbols of one common subsequence, in order, with no
header or terminator. A valid empty subsequence returns zero bytes. A null
output pointer or insufficient output capacity returns `-2` without writes,
including when the valid result is empty. Maximum output is 64 bytes. The
workspace budget is 2,048 bytes: two 65-element integer rows, a 64-byte staged
result, and the bounded recursion stack.

The deterministic tie rule is shared by all ports: the longer input is the
recursion axis (ties keep the first input as that axis); each midpoint split
uses the smallest second-sequence offset among those maximizing the sum of
forward and backward LCS lengths; a one-symbol base case selects its earliest
matching position. Left recursion runs before right recursion. The result is
therefore reproducible for a fixed ordered input pair.

For lengths `n` and `m`, running time is `O(n*m)`. The two DP rows use
`O(min(n,m))` space, the recursion stack uses `O(log(max(n,m)))`, and the
returned certificate uses at most `O(min(n,m))` bytes.

## Distinction and verification

[`longest_common_subsequence`](../../l/longest_common_subsequence/README.md)
uses one-row DP to return only the length;
[`hunt_szymanski_lcs`](../hunt_szymanski_lcs/README.md) processes matching
position pairs through an LIS frontier and also returns only the length; and
[`rle_lcs_block_dp`](../../r/rle_lcs_block_dp/README.md) operates on
run-length encoded input. This package instead reconstructs an actual LCS via
divide-and-conquer midpoint traceback with linear DP-row space.

The [primary oracle](primary_oracle.py) implements Hirschberg reconstruction.
The [independent oracle](independent_oracle.py) builds the full LCS table and
checks that each returned byte string is a subsequence of both inputs with
optimal length; it does not rely on the primary oracle's tie choices. The
[workload](workload.json) covers empty, unique, tie-heavy, repeated, asymmetric,
maximum-size, malformed, null-output, and short-capacity cases.

## Provenance

The algorithm is from Daniel S. Hirschberg, “A linear space algorithm for
computing maximal common subsequences,” *Communications of the ACM* 18(6),
1975, [DOI 10.1145/360825.360861](https://doi.org/10.1145/360825.360861). Only
the algorithm description was used; see [`RIGHTS.md`](RIGHTS.md).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/hirschberg_lcs.c`](../../../c/h/hirschberg_lcs.c) |
| C3 | [`c3/h/hirschberg_lcs.c3`](../../../c3/h/hirschberg_lcs.c3) |
| C++ | [`cpp/h/hirschberg_lcs.cpp`](../../../cpp/h/hirschberg_lcs.cpp) |
| Elisa | [`elisa/h/hirschberg_lcs.elisa`](../../../elisa/h/hirschberg_lcs.elisa) |
| Mojo | [`mojo/h/hirschberg_lcs.mojo`](../../../mojo/h/hirschberg_lcs.mojo) |
| Nim | [`nim/h/hirschberg_lcs.nim`](../../../nim/h/hirschberg_lcs.nim) |
| Odin | [`odin/h/hirschberg_lcs.odin`](../../../odin/h/hirschberg_lcs.odin) |
| Rust | [`rust/h/hirschberg_lcs.rs`](../../../rust/h/hirschberg_lcs.rs) |
| V | [`v/h/hirschberg_lcs.v`](../../../v/h/hirschberg_lcs.v) |
| Zig | [`zig/h/hirschberg_lcs.zig`](../../../zig/h/hirschberg_lcs.zig) |

The shared byte-output suite can compare the exact deterministic byte string
from the primary oracle and independently validate its subsequence and
optimality certificate.

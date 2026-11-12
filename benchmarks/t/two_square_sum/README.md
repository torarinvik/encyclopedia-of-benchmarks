# Represent a number as a sum of two squares

## Contract

Input is `[Q, N_0, ..., N_(Q-1)]`, with `1 <= Q <= 8` and each
`0 <= N_i <= 10000`. For every query, enumerate all ordered pairs of
nonnegative integers `(a, b)` such that `N_i = a^2 + b^2`. The scan visits
each possible first coordinate `a` once and obtains `b` with integer square
root, so swapped pairs are included when they are distinct.

Output contains one record per query: a 32-bit little-endian pair count,
followed by each `(a, b)` as two 32-bit little-endian values. The call returns
the total number of output bytes. Invalid input returns `-1`; a null output or
insufficient capacity returns `-2` without writing. The largest output is
6,496 bytes: at most 101 pairs for each of eight queries.

The official Library Checker task allows `Q <= 100` and `N_i <= 10^18` and
uses number factorization to construct the representations. This profile is
intentionally bounded at 10,000 and uses direct coordinate enumeration with
integer square root instead. It preserves the ordered-pair semantics while
keeping one implementation suitable for all target languages.

## Distinctness

The local `pythagoras` package computes a geometric distance, while
`pythagorean_triple` and Project Euler 9/39 handle triples satisfying
`a^2 + b^2 = c^2`. None enumerates all pairs representing one supplied
integer as a sum of two squares.

Official task: [Library Checker — Represent A Number As Two Square Sum](https://github.com/yosupo06/library-checker-problems/blob/master/number_theory/two_square_sum/task.md).

## Workload and ports

[`workload.json`](workload.json) covers zero, one and two representations,
ordered swapped pairs, nonsquares, the upper input bound, capacity failures,
and malformed input. The independent oracle uses Python's integer-square-root
primitive in [`benchmarks/two_square_sum_oracle.py`](../../two_square_sum_oracle.py).

| Language | Port |
|---|---|
| C | [`c/t/two_square_sum.c`](../../../c/t/two_square_sum.c) |
| C3 | [`c3/t/two_square_sum.c3`](../../../c3/t/two_square_sum.c3) |
| C++ | [`cpp/t/two_square_sum.cpp`](../../../cpp/t/two_square_sum.cpp) |
| Elisa | [`elisa/t/two_square_sum.elisa`](../../../elisa/t/two_square_sum.elisa) |
| Nim | [`nim/t/two_square_sum.nim`](../../../nim/t/two_square_sum.nim) |
| Odin | [`odin/t/two_square_sum.odin`](../../../odin/t/two_square_sum.odin) |
| Rust | [`rust/t/two_square_sum.rs`](../../../rust/t/two_square_sum.rs) |
| V | [`v/t/two_square_sum.v`](../../../v/t/two_square_sum.v) |
| Zig | [`zig/t/two_square_sum.zig`](../../../zig/t/two_square_sum.zig) |
| Mojo | [`mojo/t/two_square_sum.mojo`](../../../mojo/t/two_square_sum.mojo) |

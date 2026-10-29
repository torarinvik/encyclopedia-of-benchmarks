# Static Range Mode Query

This benchmark answers static subarray mode queries. It follows the problem
taxonomy in [Library Checker issue #959](https://github.com/yosupo06/library-checker-problems/issues/959)
and the range-mode data-structure discussion in
[Linear-Space Data Structures for Range Mode Query in Arrays](https://cs.au.dk/~larsen/papers/linear_mode.pdf).
These references supply the problem and algorithm context only; the benchmark
ports and oracle are clean-room implementations, with no source or prose copied.

## Contract

Input is `[n, q, A_0, ..., A_(n-1), (l, r)*q]`, where `1 <= n <= 32`,
`1 <= q <= 16`, each `A_i` is in `[0, 1_000_000_000]`, and each half-open
query satisfies `0 <= l < r <= n`. Return two little-endian signed 64-bit
values per query: the mode and its frequency. Ties choose the smallest mode
value. Invalid input returns `-1`; null output or capacity below `16*q`
returns `-2`, without writing output.

The ABI maximums are 66 input integers and 256 output bytes. The workload uses
4,096 bytes of declared workspace.

## Algorithm and complexity

Each port compresses values, stores each compressed value's sorted occurrence
positions, and precomputes the mode for every span of whole blocks. A query
starts with the stored mode of its whole-block span, then counts candidates
from the at most two boundary fragments by binary searching their occurrence
lists. If there is no whole block in the range, every range element is a
boundary candidate. Equal frequencies are resolved by compressed value order,
which is the original numeric order.

The block width is `ceil(sqrt(n))`, so there are at most `ceil(sqrt(n))`
blocks. The implementation uses insertion sort for rank compression, giving
`O(n^2 + n*ceil(n/B) + q*B*log n)` time with `B = ceil(sqrt(n))` and `O(n)`
working space. This states the actual bounded implementation cost rather than
the stronger asymptotic preprocessing bound of the paper's comparison model.

The independent oracle scans each query directly. See [`workload.json`](workload.json)
and [`verify_workload.py`](verify_workload.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/s/static_range_mode_query.c`](../../../c/s/static_range_mode_query.c) |
| C3 | [`c3/s/static_range_mode_query.c3`](../../../c3/s/static_range_mode_query.c3) |
| C++ | [`cpp/s/static_range_mode_query.cpp`](../../../cpp/s/static_range_mode_query.cpp) |
| Elisa | [`elisa/s/static_range_mode_query.elisa`](../../../elisa/s/static_range_mode_query.elisa) |
| Nim | [`nim/s/static_range_mode_query.nim`](../../../nim/s/static_range_mode_query.nim) |
| Odin | [`odin/s/static_range_mode_query.odin`](../../../odin/s/static_range_mode_query.odin) |
| Rust | [`rust/s/static_range_mode_query.rs`](../../../rust/s/static_range_mode_query.rs) |
| V | [`v/s/static_range_mode_query.v`](../../../v/s/static_range_mode_query.v) |
| Zig | [`zig/s/static_range_mode_query.zig`](../../../zig/s/static_range_mode_query.zig) |

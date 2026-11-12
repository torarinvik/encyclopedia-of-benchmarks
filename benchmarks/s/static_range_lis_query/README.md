# Static range LIS query

This profile stores a bounded permutation and answers multiple static
longest-increasing-subsequence length queries on half-open subarrays.

## Contract

Input is `[N,Q,P_0,...,P_(N-1),(left,right)*Q]`. The permutation contains
every value in `[0,N)` exactly once. Local bounds are `1<=N<=128`,
`1<=Q<=32`, and each query satisfies `0<=left<=right<=N`. Empty ranges return
zero. LIS is strictly increasing. The result is one little-endian signed
64-bit length per query. Malformed framing, non-permutations, and invalid
endpoints return `-1`; null output or insufficient capacity returns `-2`,
with no writes on error. Maximum input is 194 words (195 parseable); output is
at most 256 bytes; declared workspace is 2048 bytes.

## Bounded query algorithm

Each query scans its selected subarray and maintains patience-sorting tails.
For each value it binary-searches the first tail greater than or equal to that
value, then replaces that tail or appends a new one. Lower-bound replacement
preserves the source task's strict-increase rule. The total bounded work is
`O(sum((right-left) * log N))` and workspace is `O(N+Q)`.

This is a direct bounded query baseline, not a claim to implement the most
advanced preprocessed range-LIS structure for the official 100,000-element,
100,000-query limits. The existing `longest_increasing_subsequence` package
answers one whole-array query; it does not provide repeated subrange queries
over a shared permutation. This package therefore measures the distinct
range-query operation, using the existing strict LIS semantics.

## Upstream and rights

The operation follows [Library Checker: Static Range LIS Query](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/static_range_lis_query/task.md)
and its [input bounds](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/static_range_lis_query/info.toml).
The task defines a permutation and asks for LIS length on `P[left..right)`.
The local profile bounds that operation to small inputs and makes no claim
about an optimized solution for the upstream maximum. See [RIGHTS.md](RIGHTS.md).

The primary oracle uses the same tails invariant per query. The independent
verifier uses quadratic dynamic programming over each selected subarray.

## Ports

| Language | Source |
|---|---|
| C | [`c/s/static_range_lis_query.c`](../../../c/s/static_range_lis_query.c) |
| C3 | [`c3/s/static_range_lis_query.c3`](../../../c3/s/static_range_lis_query.c3) |
| C++ | [`cpp/s/static_range_lis_query.cpp`](../../../cpp/s/static_range_lis_query.cpp) |
| Elisa | [`elisa/s/static_range_lis_query.elisa`](../../../elisa/s/static_range_lis_query.elisa) |
| Mojo | [`mojo/s/static_range_lis_query.mojo`](../../../mojo/s/static_range_lis_query.mojo) |
| Nim | [`nim/s/static_range_lis_query.nim`](../../../nim/s/static_range_lis_query.nim) |
| Odin | [`odin/s/static_range_lis_query.odin`](../../../odin/s/static_range_lis_query.odin) |
| Rust | [`rust/s/static_range_lis_query.rs`](../../../rust/s/static_range_lis_query.rs) |
| V | [`v/s/static_range_lis_query.v`](../../../v/s/static_range_lis_query.v) |
| Zig | [`zig/s/static_range_lis_query.zig`](../../../zig/s/static_range_lis_query.zig) |

See [`workload.json`](workload.json), [`static_range_lis_query_oracle.py`](../../static_range_lis_query_oracle.py), and [`static_range_lis_query_verifier_oracle.py`](../../static_range_lis_query_verifier_oracle.py).

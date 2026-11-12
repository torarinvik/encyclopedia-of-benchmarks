# Static range inversions query

This package answers strict inversion-count queries over half-open ranges in a
static integer array. Duplicates are allowed and equal values do not form an
inversion.

## Contract

The `i64_array_bytes_output` frame is `[N,Q,A_0,...,A_(N-1),(left,right)*Q]`.
The local profile accepts `1<=N<=128`, `1<=Q<=32`, values in
`[0,1,000,000,000]`, and `0<=left<right<=N`. It emits one little-endian signed
64-bit inversion count per query in original order. Malformed input returns
`-1`; null output or insufficient capacity returns `-2`, without writes.
Maximum input is 194 words (195 parseable), maximum output is 256 bytes, and
declared workspace is 8192 bytes.

The official task permits `N,Q<=100,000` and values in `[0,10^9]`; this local
profile retains the operation while capping its input for fixed-size ports.

## Algorithm

The ports coordinate-compress values and process queries in alternating
Mo-order by left block and right endpoint. A Fenwick frequency tree tracks
the values in the current interval. Inserting an element at the left adds the
number of current values strictly smaller than it; inserting at the right adds
the number strictly greater. Removing either endpoint subtracts the same
contribution for that endpoint. The Fenwick tree's strict prefixes handle
duplicates without counting equal pairs. Answers are restored to input query
order.

This is distinct from `inversions` and `count_inversions`, which count only the
whole input. The local `mos_algorithm` package uses Mo ordering for range sums
and fixed-target frequencies, but does not maintain inversion pairs as the
window moves. The independent verifier instead scans all index pairs per
query. The package is a bounded implementation of the official query
semantics, not a claim about a particular upstream solution strategy.

## Upstream and rights

See [Library Checker: Static Range Inversions Query](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/static_range_inversions_query/task.md),
its [bounds](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/static_range_inversions_query/info.toml),
and [RIGHTS.md](RIGHTS.md). The repository is Apache-2.0; the task definition
is used only for attribution and input/output semantics. Ports are
independently authored.

## Ports

| Language | Source |
|---|---|
| C | [`c/s/static_range_inversions_query.c`](../../../c/s/static_range_inversions_query.c) |
| C3 | [`c3/s/static_range_inversions_query.c3`](../../../c3/s/static_range_inversions_query.c3) |
| C++ | [`cpp/s/static_range_inversions_query.cpp`](../../../cpp/s/static_range_inversions_query.cpp) |
| Elisa | [`elisa/s/static_range_inversions_query.elisa`](../../../elisa/s/static_range_inversions_query.elisa) |
| Mojo | [`mojo/s/static_range_inversions_query.mojo`](../../../mojo/s/static_range_inversions_query.mojo) |
| Nim | [`nim/s/static_range_inversions_query.nim`](../../../nim/s/static_range_inversions_query.nim) |
| Odin | [`odin/s/static_range_inversions_query.odin`](../../../odin/s/static_range_inversions_query.odin) |
| Rust | [`rust/s/static_range_inversions_query.rs`](../../../rust/s/static_range_inversions_query.rs) |
| V | [`v/s/static_range_inversions_query.v`](../../../v/s/static_range_inversions_query.v) |
| Zig | [`zig/s/static_range_inversions_query.zig`](../../../zig/s/static_range_inversions_query.zig) |

Primary oracle: [`static_range_inversions_query_oracle.py`](../../static_range_inversions_query_oracle.py).
Independent verifier: [`static_range_inversions_query_verifier_oracle.py`](../../static_range_inversions_query_verifier_oracle.py).
Workload: [`workload.json`](workload.json).

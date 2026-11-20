# Arpa's offline range minimum query

This profile answers a batch of inclusive range-minimum queries by sweeping
the array from left to right. A monotone stack links each index to its next
strictly smaller value; a disjoint-set find follows those links to the
leftmost minimum for a query ending at the current sweep position.

## Contract

The `i64_array_scalar` input is `[n,q,values[n],(left,right)*q]`. The array
length is 1..64, the query count is 0..64, values are in `[-1000,1000]`, and
each query is inclusive with `0<=left<=right<n`. The result is
`sum((query_ordinal+1)*(leftmost_minimum_index+1))`; an empty batch returns 0.
Malformed or out-of-profile input returns `-1`.

Strictly smaller links preserve the leftmost index when minima tie. The
algorithm takes `O((n+q) alpha(n))` time and `O(n+q)` space for this bounded
profile. The independent oracle scans each requested range directly.

This is distinct from [`sparse_table`](../../s/sparse_table/README.md), which
answers a query from two overlapping precomputed blocks, and from segment-tree
queries. It is the DSU/monotone-stack offline method, not a title variant of
those structures.

## Provenance and inventory

The algorithm idea comes from CP-Algorithms' [Disjoint Set Union article,
Offline RMQ / Arpa's trick section](https://cp-algorithms.com/data_structures/disjoint_set_union.html),
published under CC BY-SA 4.0. The contract, implementations, references,
fixtures, and prose are independently authored. See [RIGHTS.md](RIGHTS.md).
[`workload.json`](workload.json) covers ties, monotone arrays, empty and
maximum-size batches, and malformed frames. The maximum frame has 64 zero
values and the 64 singleton queries `[i,i]`; its checksum is
`1^2 + ... + 64^2 = 89,440`. The primary and direct-scan
references are [`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py); the source-only
[`verify_workload.py`](verify_workload.py) inventories the package and fixtures.

| Language | Source |
|---|---|
| C | [`c/a/arpa_offline_rmq.c`](../../../c/a/arpa_offline_rmq.c) |
| C3 | [`c3/a/arpa_offline_rmq.c3`](../../../c3/a/arpa_offline_rmq.c3) |
| C++ | [`cpp/a/arpa_offline_rmq.cpp`](../../../cpp/a/arpa_offline_rmq.cpp) |
| Elisa | [`elisa/a/arpa_offline_rmq.elisa`](../../../elisa/a/arpa_offline_rmq.elisa) |
| Mojo | [`mojo/a/arpa_offline_rmq.mojo`](../../../mojo/a/arpa_offline_rmq.mojo) |
| Nim | [`nim/a/arpa_offline_rmq.nim`](../../../nim/a/arpa_offline_rmq.nim) |
| Odin | [`odin/a/arpa_offline_rmq.odin`](../../../odin/a/arpa_offline_rmq.odin) |
| Rust | [`rust/a/arpa_offline_rmq.rs`](../../../rust/a/arpa_offline_rmq.rs) |
| V | [`v/a/arpa_offline_rmq.v`](../../../v/a/arpa_offline_rmq.v) |
| Zig | [`zig/a/arpa_offline_rmq.zig`](../../../zig/a/arpa_offline_rmq.zig) |

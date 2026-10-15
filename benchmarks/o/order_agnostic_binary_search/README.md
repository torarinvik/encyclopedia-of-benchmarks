# Order agnostic binary search

Search a monotone signed 32-bit integer sequence without being told whether it is ascending or descending. The source chooses ascending order only when the first item is less than the last; an all-equal sequence follows the descending branch.

## Contract

- The package uses the existing `i64_array_scalar` ABI and returns one signed 64-bit index.
- The signed 64-bit input array is `[target, item_count, item_0, ..., item_(n-1)]`.
- `item_count` is from 1 through 99,999 and the packed input length must equal `item_count + 2`.
- The target and sequence elements are signed 32-bit integers. The sequence must be monotone nondecreasing or monotone nonincreasing; duplicates are allowed.
- Return the index selected by the source midpoint loop, or `-1` when the target is absent or the packed layout is invalid. Duplicate hits follow midpoint-loop order, not first-index order.
- The search loop uses `middle = start + (end - start) / 2`, chooses direction from the endpoint comparison, checks equality before moving either bound, and returns at the first equal midpoint.

## Workload

[`workload.json`](workload.json) covers ascending and descending sequences, singleton and all-equal inputs, duplicate midpoint selection, hits, misses, and malformed packed layouts.

The shared `i64_array_scalar` runner checks the monotonicity precondition, endpoint-based direction choice, and source midpoint loop for each workload.

## Pinned source

- [Java `OrderAgnosticBinarySearch.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/OrderAgnosticBinarySearch.java)

## Ports

| Language | Source |
| --- | --- |
| C | [`c/o/order_agnostic_binary_search.c`](../../../c/o/order_agnostic_binary_search.c) |
| C3 | [`c3/o/order_agnostic_binary_search.c3`](../../../c3/o/order_agnostic_binary_search.c3) |
| C++ | [`cpp/o/order_agnostic_binary_search.cpp`](../../../cpp/o/order_agnostic_binary_search.cpp) |
| Elisa | [`elisa/o/order_agnostic_binary_search.elisa`](../../../elisa/o/order_agnostic_binary_search.elisa) |
| Nim | [`nim/o/order_agnostic_binary_search.nim`](../../../nim/o/order_agnostic_binary_search.nim) |
| Odin | [`odin/o/order_agnostic_binary_search.odin`](../../../odin/o/order_agnostic_binary_search.odin) |
| Rust | [`rust/o/order_agnostic_binary_search.rs`](../../../rust/o/order_agnostic_binary_search.rs) |
| V | [`v/o/order_agnostic_binary_search.v`](../../../v/o/order_agnostic_binary_search.v) |
| Zig | [`zig/o/order_agnostic_binary_search.zig`](../../../zig/o/order_agnostic_binary_search.zig) |

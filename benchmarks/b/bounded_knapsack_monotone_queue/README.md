# Bounded knapsack with a monotone queue

This benchmark solves bounded-multiplicity knapsack exactly. Each type has a positive weight, a nonnegative value, and an upper bound on how many copies may be selected. The result is the maximum total value for a total weight no greater than the capacity.

## Contract

- Scalar input is `[capacity, type_count, (weight, value, count)*]`.
- Capacity is `0..64`; type count is `0..16`; weights are `1..16`, values `0..100`, and multiplicities `0..16`.
- The frame must contain exactly `2 + 3*type_count` signed 64-bit values. Maximum valid and parseable lengths are 50 and 51 values; the latter catches one trailing value.
- The function returns the maximum achievable value, or `-1` for null, malformed, or out-of-range input. Valid values are nonnegative.
- The bounds keep all arithmetic in signed 64-bit range. Implementations use fixed local arrays and no dynamic allocation.

## Algorithm and distinction

For each item type, the implementation treats capacities with the same residue modulo the item's weight as one sequence. At sequence position `t`, taking `k` copies gives `old[t-k] + k*value`, which is `t*value + (old[t-k] - (t-k)*value)`. A decreasing deque maintains the maximum adjusted old-state value over the sliding window `t-count <= t-k <= t`. This processes one item type in `O(capacity)` time, for total `O(type_count*capacity)` time and `O(capacity)` space.

The independent oracle uses the direct bounded transition, enumerating each allowed copy count in a two-row DP. This package differs from the local 0/1 profile, which permits one copy of each item and scans capacities downward, and the unbounded profile, which permits unlimited reuse. It also measures a different exact optimization from binary grouping: the bounded transition is evaluated through residue-class sliding maxima rather than expanded into 0/1 bundles.

## Workload and verification

[`workload.json`](workload.json) covers empty input sets, zero capacity, zero multiplicity, zero value, several residue classes, competing item types, a multiplicity cap, the maximum frame, and malformed/trailing/null input. [`primary_oracle.py`](primary_oracle.py) uses the monotone-queue transition; [`independent_oracle.py`](independent_oracle.py) enumerates copy counts directly. [`check_inventory.py`](check_inventory.py) statically checks the package manifest, workload fixtures, and all ten ports; it is provided for maintainers and was not run during authoring.

## Source and ports

The algorithm description is from [CP-Algorithms, Knapsack Problem: Multiple Knapsack and Monotone Queue Optimization](https://cp-algorithms.com/dynamic_programming/knapsack.html#monotone-queue-optimization). The source is licensed CC BY-SA 4.0. This package uses the mathematical description only; all code, test data, and benchmark contracts here are independently written.

| Language | Source |
| --- | --- |
| C | [`c/b/bounded_knapsack_monotone_queue.c`](../../../c/b/bounded_knapsack_monotone_queue.c) |
| C3 | [`c3/b/bounded_knapsack_monotone_queue.c3`](../../../c3/b/bounded_knapsack_monotone_queue.c3) |
| C++ | [`cpp/b/bounded_knapsack_monotone_queue.cpp`](../../../cpp/b/bounded_knapsack_monotone_queue.cpp) |
| Elisa | [`elisa/b/bounded_knapsack_monotone_queue.elisa`](../../../elisa/b/bounded_knapsack_monotone_queue.elisa) |
| Mojo | [`mojo/b/bounded_knapsack_monotone_queue.mojo`](../../../mojo/b/bounded_knapsack_monotone_queue.mojo) |
| Nim | [`nim/b/bounded_knapsack_monotone_queue.nim`](../../../nim/b/bounded_knapsack_monotone_queue.nim) |
| Odin | [`odin/b/bounded_knapsack_monotone_queue.odin`](../../../odin/b/bounded_knapsack_monotone_queue.odin) |
| Rust | [`rust/b/bounded_knapsack_monotone_queue.rs`](../../../rust/b/bounded_knapsack_monotone_queue.rs) |
| V | [`v/b/bounded_knapsack_monotone_queue.v`](../../../v/b/bounded_knapsack_monotone_queue.v) |
| Zig | [`zig/b/bounded_knapsack_monotone_queue.zig`](../../../zig/b/bounded_knapsack_monotone_queue.zig) |

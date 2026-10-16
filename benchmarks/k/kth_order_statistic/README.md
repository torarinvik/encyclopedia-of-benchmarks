# K-th order statistic

This benchmark ports the pinned Python recursive quickselect. Its source chooses a random pivot, partitions values below and above it, then recurses into the relevant side. The benchmark uses unique values because the source drops values equal to a pivot from both partitions, making duplicate inputs unsafe. Ports choose a deterministic pivot while preserving the same partition-and-recurse result.

## Contract

Input is `[k, values...]`, with a one-based rank `k`, 1 to 64 unique integers in `[-10000,10000]`, and `1 <= k <= count`. Output is the k-th smallest value; invalid input returns -1.

See [workload](workload.json), [independent oracle](../../kth_order_statistic_oracle.py), and the pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/divide_and_conquer/kth_order_statistic.py).

| Language | Port |
|---|---|
| C | [`c/k/kth_order_statistic.c`](../../../c/k/kth_order_statistic.c) |
| C3 | [`c3/k/kth_order_statistic.c3`](../../../c3/k/kth_order_statistic.c3) |
| C++ | [`cpp/k/kth_order_statistic.cpp`](../../../cpp/k/kth_order_statistic.cpp) |
| Elisa | [`elisa/k/kth_order_statistic.elisa`](../../../elisa/k/kth_order_statistic.elisa) |
| Nim | [`nim/k/kth_order_statistic.nim`](../../../nim/k/kth_order_statistic.nim) |
| Odin | [`odin/k/kth_order_statistic.odin`](../../../odin/k/kth_order_statistic.odin) |
| Rust | [`rust/k/kth_order_statistic.rs`](../../../rust/k/kth_order_statistic.rs) |
| V | [`v/k/kth_order_statistic.v`](../../../v/k/kth_order_statistic.v) |
| Zig | [`zig/k/kth_order_statistic.zig`](../../../zig/k/kth_order_statistic.zig) |

# K-th smallest with a max heap

This benchmark ports the pinned Rust routine. It keeps the first k values in a max heap, then compares each remaining value with the heap maximum, replacing that maximum when the new value is no greater. The heap root is the k-th smallest value.

## Contract

Input is `[k, values...]`, with `1 <= k <= value_count`, between 1 and 64 values, and values in `[-100000,100000]`. The result is the k-th smallest value; invalid input returns -1. Duplicates are supported, matching the ordering operations in the Rust source.

See [workload](workload.json), [independent oracle](../../kth_smallest_heap_oracle.py), and the pinned [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/searching/kth_smallest_heap.rs).

| Language | Port |
|---|---|
| C | [`c/k/kth_smallest_heap.c`](../../../c/k/kth_smallest_heap.c) |
| C3 | [`c3/k/kth_smallest_heap.c3`](../../../c3/k/kth_smallest_heap.c3) |
| C++ | [`cpp/k/kth_smallest_heap.cpp`](../../../cpp/k/kth_smallest_heap.cpp) |
| Elisa | [`elisa/k/kth_smallest_heap.elisa`](../../../elisa/k/kth_smallest_heap.elisa) |
| Nim | [`nim/k/kth_smallest_heap.nim`](../../../nim/k/kth_smallest_heap.nim) |
| Odin | [`odin/k/kth_smallest_heap.odin`](../../../odin/k/kth_smallest_heap.odin) |
| Rust | [`rust/k/kth_smallest_heap.rs`](../../../rust/k/kth_smallest_heap.rs) |
| V | [`v/k/kth_smallest_heap.v`](../../../v/k/kth_smallest_heap.v) |
| Zig | [`zig/k/kth_smallest_heap.zig`](../../../zig/k/kth_smallest_heap.zig) |

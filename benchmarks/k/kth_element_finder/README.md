# Kth element finder

The pinned Java source provides two heap-based order statistics. Mode `0` finds the kth largest value with a size-k min-heap; mode `1` finds the kth smallest value with a size-k max-heap. These ports bottom-up heapify the first k values, then replace the root only when a later value improves the selected k-element set. The Java source inserts values into `PriorityQueue` incrementally; selection semantics and O(n log k) time are preserved, while the initial heap-building cost differs. Both approaches use O(k) auxiliary space.

## Contract

Input is `[mode, n, k, value_0, ..., value_(n-1)]`. Mode `0` selects kth largest; mode `1` selects kth smallest. The input must contain exactly `3+n` signed 64-bit integers, `1 <= n <= 256`, `1 <= k <= n`, and every value must be in `[-1,000,000, 1,000,000]`. Duplicate values count as separate ranked positions. Return the selected value, widened from the Java `int` result. Invalid inputs return `INT64_MIN`. The value bound prevents overflow in the source max-heap comparator `(a, b) -> b - a`.

See [workload](workload.json), [oracle](../../kth_element_finder_oracle.py), and the pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/heaps/KthElementFinder.java).

| Language | Port |
|---|---|
| C | [`c/k/kth_element_finder.c`](../../../c/k/kth_element_finder.c) |
| C3 | [`c3/k/kth_element_finder.c3`](../../../c3/k/kth_element_finder.c3) |
| C++ | [`cpp/k/kth_element_finder.cpp`](../../../cpp/k/kth_element_finder.cpp) |
| Elisa | [`elisa/k/kth_element_finder.elisa`](../../../elisa/k/kth_element_finder.elisa) |
| Nim | [`nim/k/kth_element_finder.nim`](../../../nim/k/kth_element_finder.nim) |
| Odin | [`odin/k/kth_element_finder.odin`](../../../odin/k/kth_element_finder.odin) |
| Rust | [`rust/k/kth_element_finder.rs`](../../../rust/k/kth_element_finder.rs) |
| V | [`v/k/kth_element_finder.v`](../../../v/k/kth_element_finder.v) |
| Zig | [`zig/k/kth_element_finder.zig`](../../../zig/k/kth_element_finder.zig) |

Build and record with the shared `i64_array_scalar` ABI after its serialized dispatcher integration is complete:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm kth_element_finder --language rust
python3 benchmarks/run_i64_array_scalar.py --algorithm kth_element_finder
```

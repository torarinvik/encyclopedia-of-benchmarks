# Find the kth largest number with a max heap

## Contract

This package ports the deterministic `findKthMaxUsingHeap` method from the pinned Java `FindKthNumber` class. The `i64_array_scalar` input layout is `[k, value_0, value_1, ...]`. It requires 1..1024 signed int32 values and a one-based rank `k` in `1..n`. Return the kth largest value, counting duplicates as separate entries. Inputs outside this bounded contract return `INT64_MIN` as the benchmark sentinel; the source throws for an invalid rank.

The source inserts every value into a reverse-order `PriorityQueue<Integer>` in input order. It then polls the maximum `k-1` times and returns the next maximum. The ports preserve sequential heap insertion and repeated maximum removal; they do not use bulk heap construction or sort the array. Runtime is O(n log n + k log n), with O(n) auxiliary space.

The same Java class also exposes `findKthMax`, which uses a randomly chosen pivot and quickselect. That method is outside this package. The existing [`kth_largest_element`](../../k/kth_largest_element/README.md) package uses deterministic Lomuto quickselect, and [`kth_largest_by_sort`](../../k/kth_largest_by_sort/README.md) sorts the full array; this package preserves the source's separate max-heap strategy.

## Source

- [TheAlgorithms/Java `FindKthNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/FindKthNumber.java), pinned at `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Workload and implementations

[`workload.json`](workload.json) covers first, middle, and last ranks, duplicate values, negatives, signed int32 boundaries, and invalid ranks and values.

| Language | Implementation |
| --- | --- |
| C | [`c/f/find_kth_number.c`](../../../c/f/find_kth_number.c) |
| C3 | [`c3/f/find_kth_number.c3`](../../../c3/f/find_kth_number.c3) |
| C++ | [`cpp/f/find_kth_number.cpp`](../../../cpp/f/find_kth_number.cpp) |
| Elisa | [`elisa/f/find_kth_number.elisa`](../../../elisa/f/find_kth_number.elisa) |
| Nim | [`nim/f/find_kth_number.nim`](../../../nim/f/find_kth_number.nim) |
| Odin | [`odin/f/find_kth_number.odin`](../../../odin/f/find_kth_number.odin) |
| Rust | [`rust/f/find_kth_number.rs`](../../../rust/f/find_kth_number.rs) |
| V | [`v/f/find_kth_number.v`](../../../v/f/find_kth_number.v) |
| Zig | [`zig/f/find_kth_number.zig`](../../../zig/f/find_kth_number.zig) |

All implementations export `find_kth_number` through the `i64_array_scalar` ABI.

Build and record an implementation with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm find_kth_number --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/f/find_kth_number/rust/build.json
```

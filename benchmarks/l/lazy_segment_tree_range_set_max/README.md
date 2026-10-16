# Lazy Segment Tree Range Set and Maximum

This benchmark measures the Python source's lazy segment tree for assigning a constant to a range and querying the maximum over a range. The Java source is excluded because its lazy propagation applies additions twice.

## Contract

- Input is a signed 64-bit array packed as `[n, q, initial_values..., operation_records...]`.
- `n` is 1 through 256, `q` is 0 through 512, and initial and assigned values are in `[-1,000,000, 1,000,000]`.
- Operation `0` is a maximum query `[0, l, r]`; operation `1` assigns a value `[1, l, r, value]`. Both use nonempty 0-based half-open ranges with `0 <= l < r <= n`. The source receives the equivalent 1-based inclusive range `[l + 1, r]`.
- Invalid lengths, operations, ranges, or values return `-1`.
- For query answers `a_1 ... a_m`, return `sum(k * (a_k + 1,000,001))` for `k=1..m`. The result is zero when there are no queries. This checksum is nonnegative, fits signed 64-bit, and cannot collide with `-1`.
- The maximum packed input length is 2,306 signed 64-bit values.

## Workload and implementation

[`workload.json`](workload.json) covers single-element trees, partial and full-range assignment, negative values, repeated queries, empty operation lists, and invalid packed operations. All nine ports use the `i64_array_scalar` ABI family.

The ports use a recursive segment tree storing subtree maxima. Range assignments are propagated with a separate pending-value array and presence flags, so assigning zero is distinct from having no pending assignment.

## Upstream source

[Python `lazy_segment_tree.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/lazy_segment_tree.py)

Build with `python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm lazy_segment_tree_range_set_max --language c` and record with `benchmarks/run_i64_array_scalar.py`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/l/lazy_segment_tree_range_set_max.c`](../../../c/l/lazy_segment_tree_range_set_max.c) |
| C3 | [`c3/l/lazy_segment_tree_range_set_max.c3`](../../../c3/l/lazy_segment_tree_range_set_max.c3) |
| C++ | [`cpp/l/lazy_segment_tree_range_set_max.cpp`](../../../cpp/l/lazy_segment_tree_range_set_max.cpp) |
| Elisa | [`elisa/l/lazy_segment_tree_range_set_max.elisa`](../../../elisa/l/lazy_segment_tree_range_set_max.elisa) |
| Nim | [`nim/l/lazy_segment_tree_range_set_max.nim`](../../../nim/l/lazy_segment_tree_range_set_max.nim) |
| Odin | [`odin/l/lazy_segment_tree_range_set_max.odin`](../../../odin/l/lazy_segment_tree_range_set_max.odin) |
| Rust | [`rust/l/lazy_segment_tree_range_set_max.rs`](../../../rust/l/lazy_segment_tree_range_set_max.rs) |
| V | [`v/l/lazy_segment_tree_range_set_max.v`](../../../v/l/lazy_segment_tree_range_set_max.v) |
| Zig | [`zig/l/lazy_segment_tree_range_set_max.zig`](../../../zig/l/lazy_segment_tree_range_set_max.zig) |

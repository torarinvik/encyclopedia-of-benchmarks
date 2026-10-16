# Smallest Range

This benchmark finds the narrowest interval containing at least one value from each of several sorted lists. It follows the heap-based traversal used by the pinned Python and Rust sources.

## Contract

- The read-only signed 64-bit input packs `[list_count, length_0, values..., length_1, values..., ...]`.
- `list_count` is from 1 through 16. Each list length is from 1 through 16, for at most 256 values total. Values are in `[-1,000,000,000, 1,000,000,000]` and each list is sorted nondecreasingly.
- Malformed layouts, empty lists, unsorted lists, and out-of-range values return `-1`.
- The result encodes the chosen interval as `(lo + 1,000,000,000) * 2,000,000,001 + (hi + 1,000,000,000)`. This is an unambiguous signed 64-bit value for the supported domain.
- The selected interval has minimum width. Equal-width candidates preserve the first interval found by the strict-improvement heap traversal.

## Workload and implementation

[`workload.json`](workload.json) covers one-list inputs, ties, duplicate values, negative values, mixed list lengths, signed domain edges, and malformed packed inputs. The nine ports use the `i64_array_scalar` ABI family.

The algorithm keeps one current head per list in a min-heap and tracks the largest head. It evaluates the current range, then advances the list holding the minimum; it stops when that list is exhausted.

## Upstream sources

- [Python `smallest_range.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/greedy_methods/smallest_range.py)
- [Rust `smallest_range.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/greedy/smallest_range.rs)

Build with `python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm smallest_range --language c` and record with `benchmarks/run_i64_array_scalar.py`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/smallest_range.c`](../../../c/s/smallest_range.c) |
| C3 | [`c3/s/smallest_range.c3`](../../../c3/s/smallest_range.c3) |
| C++ | [`cpp/s/smallest_range.cpp`](../../../cpp/s/smallest_range.cpp) |
| Elisa | [`elisa/s/smallest_range.elisa`](../../../elisa/s/smallest_range.elisa) |
| Nim | [`nim/s/smallest_range.nim`](../../../nim/s/smallest_range.nim) |
| Odin | [`odin/s/smallest_range.odin`](../../../odin/s/smallest_range.odin) |
| Rust | [`rust/s/smallest_range.rs`](../../../rust/s/smallest_range.rs) |
| V | [`v/s/smallest_range.v`](../../../v/s/smallest_range.v) |
| Zig | [`zig/s/smallest_range.zig`](../../../zig/s/smallest_range.zig) |

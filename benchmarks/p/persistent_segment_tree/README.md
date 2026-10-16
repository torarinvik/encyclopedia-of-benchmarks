# Persistent Segment Tree

This benchmark measures the pinned Python source's persistent segment tree for point assignment and historical range sums.

## Contract

- Input is a signed 64-bit array packed as `[n, q, initial_values..., records...]`.
- `n` is 1 through 64, `q` is 0 through 64, and initial and assigned values are in `[-1000, 1000]`.
- Every operation record has four fields. Opcode `0` is an update `[0, base_version, index, value]`; it creates a new version by setting one point in the selected prior version. Opcode `1` is a query `[1, version, left, right]`; it returns the inclusive sum from that version. Version 0 is the initial array, and each update appends the next version. Operations may branch from any version already created.
- Indices are zero-based. Update indices must be in `[0, n)`, query bounds must satisfy `0 <= left <= right < n`, and a version must already exist when referenced. Invalid lengths, values, opcodes, indices, ranges, or versions return `-1`.
- The result is the low 63 bits of 64-bit FNV-1a over the signed-i64 little-endian words `[version_count, query_count, query_sum_1, ...]`. With no queries, the two count words are still hashed.
- The maximum packed input length is 322 signed 64-bit values.

## Workload and implementation

[`workload.json`](workload.json) covers the initial version, branching updates, historical queries, repeated assignments, negative values, single-element trees, empty operation streams, and malformed records. All nine ports use the `i64_array_scalar` ABI family.

Each port builds a balanced binary sum tree in a bounded node arena. A point update creates new nodes only along its root-to-leaf path and reuses the untouched child, so older roots remain unchanged. Queries traverse the requested root and include both endpoints.

## Upstream source

[Python `persistent_segment_tree.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/persistent_segment_tree.py)

Build with `python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm persistent_segment_tree --language c` and record with `benchmarks/run_i64_array_scalar.py`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/persistent_segment_tree.c`](../../../c/p/persistent_segment_tree.c) |
| C3 | [`c3/p/persistent_segment_tree.c3`](../../../c3/p/persistent_segment_tree.c3) |
| C++ | [`cpp/p/persistent_segment_tree.cpp`](../../../cpp/p/persistent_segment_tree.cpp) |
| Elisa | [`elisa/p/persistent_segment_tree.elisa`](../../../elisa/p/persistent_segment_tree.elisa) |
| Nim | [`nim/p/persistent_segment_tree.nim`](../../../nim/p/persistent_segment_tree.nim) |
| Odin | [`odin/p/persistent_segment_tree.odin`](../../../odin/p/persistent_segment_tree.odin) |
| Rust | [`rust/p/persistent_segment_tree.rs`](../../../rust/p/persistent_segment_tree.rs) |
| V | [`v/p/persistent_segment_tree.v`](../../../v/p/persistent_segment_tree.v) |
| Zig | [`zig/p/persistent_segment_tree.zig`](../../../zig/p/persistent_segment_tree.zig) |

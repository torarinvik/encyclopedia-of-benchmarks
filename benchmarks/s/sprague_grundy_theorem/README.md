# Sprague–Grundy Theorem

This benchmark adapts the pinned [TheAlgorithms/Rust `sprague_grundy_theorem.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/sprague_grundy_theorem.rs) single-heap subtraction-game recurrence.

## Contract

- ABI: `i64_array_scalar`, with packed input `[position, move_count, move_sizes...]`.
- `position` is in `0..=64`, `move_count` is in `0..=32`, and the array contains exactly `2 + move_count` values. Every move size is in `1..=32`. Duplicates and arbitrary move order are valid.
- The memo table covers positions `0..=position` and starts with every cell set to `-1`. Position 0 has Grundy number 0. For a positive position, recursively collect the Grundy numbers reachable by subtracting each move no larger than the current position and return their minimum excluded nonnegative integer (mex). Moves larger than the current position are ignored.
- Return `-1` for invalid framing, positions, move counts, or move sizes. The empty move list is valid and has mex 0 at every position.

The independent oracle is [`benchmarks/sprague_grundy_theorem_oracle.py`](../../sprague_grundy_theorem_oracle.py). The workload includes the source example (position 6, moves `[1, 4]`, result 1), terminal and empty-move cases, duplicates and unsorted moves, ignored oversized moves, maximum bounds, and malformed inputs.

## Pinned source

The source is `TheAlgorithms/Rust` commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`, file `src/math/sprague_grundy_theorem.rs`. It memoizes with `-1`, treats position 0 as terminal, recursively visits each legal subtraction, sorts reachable values, and computes mex. Its example confirms `calculate_grundy_number(6, [1, 4]) == 1`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/sprague_grundy_theorem.c`](../../../c/s/sprague_grundy_theorem.c) |
| C3 | [`c3/s/sprague_grundy_theorem.c3`](../../../c3/s/sprague_grundy_theorem.c3) |
| C++ | [`cpp/s/sprague_grundy_theorem.cpp`](../../../cpp/s/sprague_grundy_theorem.cpp) |
| Elisa | [`elisa/s/sprague_grundy_theorem.elisa`](../../../elisa/s/sprague_grundy_theorem.elisa) |
| Nim | [`nim/s/sprague_grundy_theorem.nim`](../../../nim/s/sprague_grundy_theorem.nim) |
| Odin | [`odin/s/sprague_grundy_theorem.odin`](../../../odin/s/sprague_grundy_theorem.odin) |
| Rust | [`rust/s/sprague_grundy_theorem.rs`](../../../rust/s/sprague_grundy_theorem.rs) |
| V | [`v/s/sprague_grundy_theorem.v`](../../../v/s/sprague_grundy_theorem.v) |
| Zig | [`zig/s/sprague_grundy_theorem.zig`](../../../zig/s/sprague_grundy_theorem.zig) |

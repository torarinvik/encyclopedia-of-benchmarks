# Heap's permutation algorithm

## Contract

This package follows the pinned Dart and Python recursive/iterative Heap's permutation sources. Input is a signed 64-bit value array with length `n` from 1 through 6. It emits all `n!` permutations in the shared source order as contiguous rows of `n` little-endian signed 64-bit values. Rows are permutations of positions: equal values at different positions are not deduplicated, so identical rows are retained. The empty input is excluded because the byte-output ABI cannot distinguish one empty row from zero rows.

For clarity, `[1,2,3]` emits `[1,2,3]`, `[2,1,3]`, `[3,1,2]`, `[1,3,2]`, `[2,3,1]`, `[3,2,1]`. This is distinct from the pinned Rust `heap_permutation` swap-before-recursion order and from depth-first `all_permutations`.

The successful result is the number of rows (`n!`). Invalid input returns `-1`; insufficient output capacity returns `-2` and writes no output. Input length 7 is the parser limit and is rejected as overlength. The maximum valid output is `6! * 6 * 8 = 34,560` bytes.

## Workload

Cases and expected bytes are in [`workload.json`](workload.json). The package uses the `i64_array_bytes_output` ABI.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/heaps_algorithm.c`](../../../c/h/heaps_algorithm.c) |
| C3 | [`c3/h/heaps_algorithm.c3`](../../../c3/h/heaps_algorithm.c3) |
| C++ | [`cpp/h/heaps_algorithm.cpp`](../../../cpp/h/heaps_algorithm.cpp) |
| Elisa | [`elisa/h/heaps_algorithm.elisa`](../../../elisa/h/heaps_algorithm.elisa) |
| Nim | [`nim/h/heaps_algorithm.nim`](../../../nim/h/heaps_algorithm.nim) |
| Odin | [`odin/h/heaps_algorithm.odin`](../../../odin/h/heaps_algorithm.odin) |
| Rust | [`rust/h/heaps_algorithm.rs`](../../../rust/h/heaps_algorithm.rs) |
| V | [`v/h/heaps_algorithm.v`](../../../v/h/heaps_algorithm.v) |
| Zig | [`zig/h/heaps_algorithm.zig`](../../../zig/h/heaps_algorithm.zig) |

## TheAlgorithms references

- [Dart `heaps_algorithm.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/other/heaps_algorithm.dart)
- [Python recursive `heaps_algorithm.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/divide_and_conquer/heaps_algorithm.py)
- [Python iterative `heaps_algorithm_iterative.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/divide_and_conquer/heaps_algorithm_iterative.py)

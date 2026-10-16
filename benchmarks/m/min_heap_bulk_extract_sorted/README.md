# Min heap bulk build and sorted extraction

This package normalizes the min-heap implementations to one observable operation: take a nonempty list of signed 32-bit values, build a min heap, extract every value, and return the extracted values in ascending order. Equal values are retained as separate entries.

## Contract

Input is a signed 64-bit array `[count, values...]`. `count` is from 1 through 4,095, the array length must equal `count + 1`, and each value must fit a signed 32-bit integer. The maximum packed input is 4,096 i64 values.

Output is the full sorted sequence encoded as little-endian signed 64-bit integers. Success returns the number of output bytes (`count * 8`). Malformed input returns `-1`; null or insufficient output capacity returns `-2` without writing output.

## Source behavior and normalization

- The C source inserts each value into an initially empty min heap, then repeatedly pops the minimum.
- The Java source bulk-builds a heap from the input and then extracts its elements.
- The Python source heapifies `Node` objects and removes them. The adapter gives every input node a unique name, so equal values remain distinct; names do not affect the emitted value sequence.
- The Dart source's `buildHead` constructs the heap but does not provide extraction. This benchmark adds an extraction adapter that repeatedly swaps the root with the last live item and adjusts the new root downward. The extraction phase is adapter logic, not a source method in the Dart implementation.

The workload includes duplicates, already ordered inputs, signed 32-bit boundaries, the maximum packed input size, malformed inputs, and insufficient output capacity.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm min_heap_bulk_extract_sorted --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/m/min_heap_bulk_extract_sorted/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/min_heap_bulk_extract_sorted.c`](../../../c/m/min_heap_bulk_extract_sorted.c) |
| C3 | [`c3/m/min_heap_bulk_extract_sorted.c3`](../../../c3/m/min_heap_bulk_extract_sorted.c3) |
| C++ | [`cpp/m/min_heap_bulk_extract_sorted.cpp`](../../../cpp/m/min_heap_bulk_extract_sorted.cpp) |
| Elisa | [`elisa/m/min_heap_bulk_extract_sorted.elisa`](../../../elisa/m/min_heap_bulk_extract_sorted.elisa) |
| Nim | [`nim/m/min_heap_bulk_extract_sorted.nim`](../../../nim/m/min_heap_bulk_extract_sorted.nim) |
| Odin | [`odin/m/min_heap_bulk_extract_sorted.odin`](../../../odin/m/min_heap_bulk_extract_sorted.odin) |
| Rust | [`rust/m/min_heap_bulk_extract_sorted.rs`](../../../rust/m/min_heap_bulk_extract_sorted.rs) |
| V | [`v/m/min_heap_bulk_extract_sorted.v`](../../../v/m/min_heap_bulk_extract_sorted.v) |
| Zig | [`zig/m/min_heap_bulk_extract_sorted.zig`](../../../zig/m/min_heap_bulk_extract_sorted.zig) |

## Pinned source references

- [C `min_heap.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/heap/min_heap.c)
- [Dart `Min_Heap.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/data_structures/Heap/Binary_Heap/Min_Heap.dart)
- [Java `MinHeap.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/heaps/MinHeap.java)
- [Python `min_heap.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/heap/min_heap.py)

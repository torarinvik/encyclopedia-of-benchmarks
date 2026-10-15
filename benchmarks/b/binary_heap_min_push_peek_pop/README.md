# Binary Min Heap Push, Peek, and Pop

This benchmark inserts every input value into an initially empty min heap, then peeks at and extracts the root exactly once per value. Duplicate values remain present, and extracted values are emitted in ascending order.

## Contract

Input is a signed 64-bit array `[count, values...]`, with `count` from 1 through 256 and exactly `count` values. Each value must fit a signed 32-bit integer. Values are inserted one at a time; the heap is not built with a bulk heapification step.

For each extraction, the current minimum is observed at the root, then removed. The output is the extracted values as little-endian signed 64-bit integers. Success returns the number of output bytes written. Malformed input returns `-1`; insufficient output capacity returns `-2`.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm binary_heap_min_push_peek_pop --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/binary_heap_min_push_peek_pop/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binary_heap_min_push_peek_pop.c`](../../../c/b/binary_heap_min_push_peek_pop.c) |
| C3 | [`c3/b/binary_heap_min_push_peek_pop.c3`](../../../c3/b/binary_heap_min_push_peek_pop.c3) |
| C++ | [`cpp/b/binary_heap_min_push_peek_pop.cpp`](../../../cpp/b/binary_heap_min_push_peek_pop.cpp) |
| Elisa | [`elisa/b/binary_heap_min_push_peek_pop.elisa`](../../../elisa/b/binary_heap_min_push_peek_pop.elisa) |
| Nim | [`nim/b/binary_heap_min_push_peek_pop.nim`](../../../nim/b/binary_heap_min_push_peek_pop.nim) |
| Odin | [`odin/b/binary_heap_min_push_peek_pop.odin`](../../../odin/b/binary_heap_min_push_peek_pop.odin) |
| Rust | [`rust/b/binary_heap_min_push_peek_pop.rs`](../../../rust/b/binary_heap_min_push_peek_pop.rs) |
| V | [`v/b/binary_heap_min_push_peek_pop.v`](../../../v/b/binary_heap_min_push_peek_pop.v) |
| Zig | [`zig/b/binary_heap_min_push_peek_pop.zig`](../../../zig/b/binary_heap_min_push_peek_pop.zig) |

## Pinned sources

- C# [`BinaryHeap.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Heap/BinaryHeap.cs). The benchmark uses the custom comparer configured for min ordering.
- JavaScript [`BinaryHeap.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Heap/BinaryHeap.js), using its min-heap comparator.
- Julia [`binary_heap.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/data_structures/binary_heap.jl), using `MinHeap`.
- R [`binary_heap.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/data_structures/binary_heap.r). Its adapter must reassign the heap returned by each `push` and `pop` call.

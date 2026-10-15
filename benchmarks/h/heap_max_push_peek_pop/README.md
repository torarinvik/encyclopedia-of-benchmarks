# Max heap: incremental push, peek, and pop

This benchmark compares the incremental construction and extraction path of a binary max heap. Each valid input is inserted into an initially empty heap in its listed order. The benchmark then observes and removes the maximum exactly once per item, producing descending output. Duplicate values are kept.

## Source review

The source set includes Go `Heap.Push`/`Top`/`Pop`, Lua `heap.push`/`top`/`pop`, Python `Heap.insert`/`extract_max`, Rust `Heap::new_max`/`add`/`pop`, Swift `Heap.insert`/`extractMin`, TypeScript `MaxHeap.insert`/`extract`, and Zig `Heap.insert`/`peek`/`extract`. For Go, `Top` must be read before `Pop`, since `Pop` removes the root without returning it. Rust constructs an empty max heap and adds each item; it does not use `from_vec`. The comparators select larger values first.

The Rust source URL uses the catalog-pinned repository commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`.

Swift's `extractMin` removes the first array element with `removeFirst`, so repeated extraction shifts the remaining elements and can make its full extraction sequence quadratic. That source-level cost can create performance variance relative to heaps that replace the root and sift down.

Pinned sources:

- Go [`heap.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/structure/heap/heap.go)
- Lua [`heap.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/heap.lua)
- Python [`heap.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/heap/heap.py)
- Rust [`heap.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/heap.rs)
- Swift [`heap.swift`](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/data_structures/heap/heap.swift)
- TypeScript [`heap.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/heap/heap.ts)
- Zig [`heap.zig`](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/dataStructures/heap.zig)

## Contract

Input is a signed 64-bit integer array `[count, item_0, ..., item_(count-1)]`. `count` is 1 through 256. Each item is a positive integer from 1 through 1,000,000,000. The positive-only domain avoids the TypeScript source's truthiness checks treating zero as an absent child. Empty heaps and bulk construction are outside the workload.

The output contains all `count` items in descending order, encoded as signed 64-bit little-endian integers. The function returns the output byte length (`8 * count`), `-1` for malformed or out-of-domain input, and `-2` for null or insufficient output capacity. Errors are returned before output is written.

`workload.json` covers one item, unsorted and ordered inputs, duplicate maxima, the maximum count, malformed lengths and values, and insufficient capacity.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm heap_max_push_peek_pop --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/h/heap_max_push_peek_pop/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/heap_max_push_peek_pop.c`](../../../c/h/heap_max_push_peek_pop.c) |
| C3 | [`c3/h/heap_max_push_peek_pop.c3`](../../../c3/h/heap_max_push_peek_pop.c3) |
| C++ | [`cpp/h/heap_max_push_peek_pop.cpp`](../../../cpp/h/heap_max_push_peek_pop.cpp) |
| Elisa | [`elisa/h/heap_max_push_peek_pop.elisa`](../../../elisa/h/heap_max_push_peek_pop.elisa) |
| Nim | [`nim/h/heap_max_push_peek_pop.nim`](../../../nim/h/heap_max_push_peek_pop.nim) |
| Odin | [`odin/h/heap_max_push_peek_pop.odin`](../../../odin/h/heap_max_push_peek_pop.odin) |
| Rust | [`rust/h/heap_max_push_peek_pop.rs`](../../../rust/h/heap_max_push_peek_pop.rs) |
| V | [`v/h/heap_max_push_peek_pop.v`](../../../v/h/heap_max_push_peek_pop.v) |
| Zig | [`zig/h/heap_max_push_peek_pop.zig`](../../../zig/h/heap_max_push_peek_pop.zig) |

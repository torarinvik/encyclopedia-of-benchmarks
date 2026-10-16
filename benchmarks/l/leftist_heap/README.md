# Leftist heap

The pinned Java `LeftistHeap` recursively merges min-heap roots. It swaps roots only when the first key is greater, merges into the first root’s right child, moves the right child to the left when the left child is absent, and otherwise swaps children only when the left null-path length is smaller. The source initializes NPL to zero and updates a non-leaf node to right-child NPL plus one. Merging another heap clears that heap, and extracting from an empty heap returns −1.

## Contract

Input is `[operation_count, kind, heap_id, value, ...]`, with at most 14 operations, two heaps (0 and 1), and inserted keys in `[0,9]`. Kinds are 0 insert, 1 extract-min, 2 merge heap 1 into heap 0 (heap_id and value must be zero), and 3 clear. At most ten extracts are allowed. Results are encoded in encounter order as base-13 digits `result = result*13 + value + 2`, including −1 for an empty extraction. Invalid inputs return `-1e300`.

See [workload](workload.json), [oracle](../../leftist_heap_oracle.py), and the pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/heaps/LeftistHeap.java).

| Language | Port |
|---|---|
| C | c/l/leftist_heap.c |
| C3 | c3/l/leftist_heap.c3 |
| C++ | cpp/l/leftist_heap.cpp |
| Elisa | elisa/l/leftist_heap.elisa |
| Nim | nim/l/leftist_heap.nim |
| Odin | odin/l/leftist_heap.odin |
| Rust | rust/l/leftist_heap.rs |
| V | v/l/leftist_heap.v |
| Zig | zig/l/leftist_heap.zig |

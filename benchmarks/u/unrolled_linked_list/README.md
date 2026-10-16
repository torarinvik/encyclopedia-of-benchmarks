# Unrolled linked list append and flatten

The pinned C# `UnrolledLinkedList` is a linked chain of fixed-size arrays. Its `Insert` method appends to the tail chunk until full, then keeps `floor(count/2)+1` values in that chunk and moves the suffix plus the new item into a new tail chunk. `GetRolledItems` flattens values in insertion order. This chunk splitting behavior is distinct from ordinary singly or doubly linked list and deque benchmarks.

## Contract

The benchmark accepts 0–1,024 signed 64-bit values in the range -1,000,000 through 1,000,000. It appends each value using chunk size 4 (five allocated slots, four usable under the source's insertion condition), applies the source's tail split exactly, then returns `sum((index + 1) * (value + 1,000,000))` over flattened values. Invalid length or value returns -1. The bounded implementation uses at most 512 chunks.

The pinned source documents that `Insert` is O(n) and exposes `GetRolledItems` for inspecting order. This benchmark measures the resulting data structure semantics through a deterministic checksum; it does not claim to measure allocation or cache behavior.

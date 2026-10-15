# Ascending Priority Queue

This benchmark follows the pinned [TheAlgorithms/C ascending priority queue](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/linked_list/ascending_priority_queue.c). The source appends inserted values to a singly linked list and scans that list to remove the smallest value. Equal minima retain their insertion order because the source replaces its current minimum only when it finds a strictly smaller value.

## Contract

The `i64_array_scalar` input is `[operation_count, opcode_0, payload_0, ...]`. It accepts 0–512 operations and requires exactly two values per operation. Opcode `0` inserts its payload, which must be in `[-1,000,000, 1,000,000]`; at most 64 values may be queued at once. Opcode `1` removes the smallest value and requires a zero payload. Unknown opcodes, malformed input, capacity overflow, or removal from an empty queue return `-1`.

For each removal at zero-based operation index `i`, the benchmark adds `(i + 1) * (removed_value + 1,000,001)` to the result. It then adds `position * (remaining_value + 1,000,001)` for each queued value, where positions start at one and follow list order. This makes both removed values and the remaining queue contribute to one scalar result. The bounded implementation uses a fixed 64-node pool, appends in O(1), and scans in O(n) to remove the minimum, matching the source's data-structure behavior without allocator or processor-specific dependencies.

## Implementations

| Language | Implementation |
| --- | --- |
| C | [`c/a/ascending_priority_queue.c`](../../../c/a/ascending_priority_queue.c) |
| C3 | [`c3/a/ascending_priority_queue.c3`](../../../c3/a/ascending_priority_queue.c3) |
| C++ | [`cpp/a/ascending_priority_queue.cpp`](../../../cpp/a/ascending_priority_queue.cpp) |
| Elisa | [`elisa/a/ascending_priority_queue.elisa`](../../../elisa/a/ascending_priority_queue.elisa) |
| Nim | [`nim/a/ascending_priority_queue.nim`](../../../nim/a/ascending_priority_queue.nim) |
| Odin | [`odin/a/ascending_priority_queue.odin`](../../../odin/a/ascending_priority_queue.odin) |
| Rust | [`rust/a/ascending_priority_queue.rs`](../../../rust/a/ascending_priority_queue.rs) |
| V | [`v/a/ascending_priority_queue.v`](../../../v/a/ascending_priority_queue.v) |
| Zig | [`zig/a/ascending_priority_queue.zig`](../../../zig/a/ascending_priority_queue.zig) |

The shared workload is in [`workload.json`](workload.json). Build one implementation and its ABI checker with `python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm ascending_priority_queue --language <language> --with-checker`.

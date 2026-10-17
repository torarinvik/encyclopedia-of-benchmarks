# Indexed priority queue

This benchmark ports the pinned Java [`IndexedPriorityQueue`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/heaps/IndexedPriorityQueue.java) min-heap. The trace uses bounded element IDs as handles and integer keys ordered in ascending priority.

## Contract

The `i64_array_bytes_output` ABI accepts `[event_count, event_0, ...]`. Each event is six signed 64-bit integers: `[opcode, element_id, key, reserved0, reserved1, reserved2]`. The event count is 0–256, the input length is exactly `1 + 6 * event_count`, and the parser accepts at most 1,538 values (the maximum valid input plus one trailing value). The source's default constructor starts with capacity 11 and grows as needed. The bounded workload allows at most 64 active elements.

IDs are in 0–63 and unique while active; an ID can be reused after removal, polling, or clear. Keys fit signed 32-bit integers and are unique among active elements, which avoids comparator ties. Unused event fields must be zero.

| Opcode | Event fields | Source operation |
| --- | --- | --- |
| 0 | `id, key` | `offer`; requires an inactive ID, a key not already active, and fewer than 64 active elements |
| 1 | all zero | `peek` |
| 2 | all zero | `poll` |
| 3 | `id` | `remove`; a missing ID returns false |
| 4 | `id` | `contains` |
| 5 | `id, new_key` | `changeKey`; the ID must be active, and the new key must not collide with another active key; the current key is allowed |
| 6 | `id, new_key` | `decreaseKey`; the new key must be strictly smaller |
| 7 | `id, new_key` | `increaseKey`; the new key must be strictly larger |
| 8 | all zero | `clear` |
| 9 | all zero | `size` |
| 10 | all zero | `isEmpty` |

The output contains one six-i64 little-endian record per event: `[status, result_id, result_key, size_after, minimum_id_after, minimum_key_after]`. An empty post-operation queue has zero minimum fields. For `peek` and `poll`, status is 1 when an element is returned and 0 when the source returns null; the result fields contain that element's ID and key or zeros. For `remove`, `contains`, and `offer`, status is the source boolean result. For successful void operations, status is 1. For `size`, `result_id` contains the returned size; for `isEmpty`, it contains 0 or 1. Other operations without an element return use zero result fields. The state snapshot records the queue size and minimum after every operation.

Invalid framing, field ranges, reserved fields, or state transitions return `-1` without writing output. This includes repeated active IDs or keys, more than 64 active elements, missing key-update targets, and a non-strict `decreaseKey`/`increaseKey`. Invalid traces take precedence over output capacity. A valid nonempty trace with null or short output returns `-2` without writes. An empty trace returns zero even with null output or zero capacity. The maximum trace output is 12,288 bytes.

[`workload.json`](workload.json) covers queue results, all operations, key changes in both directions, removal and reuse, empty queries, malformed traces, and output capacity. The independent state oracle is [`benchmarks/indexed_priority_queue_oracle.py`](../../indexed_priority_queue_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/indexed_priority_queue.c](../../../c/p/indexed_priority_queue.c) |
| C3 | [c3/p/indexed_priority_queue.c3](../../../c3/p/indexed_priority_queue.c3) |
| C++ | [cpp/p/indexed_priority_queue.cpp](../../../cpp/p/indexed_priority_queue.cpp) |
| Elisa | [elisa/p/indexed_priority_queue.elisa](../../../elisa/p/indexed_priority_queue.elisa) |
| Nim | [nim/p/indexed_priority_queue.nim](../../../nim/p/indexed_priority_queue.nim) |
| Odin | [odin/p/indexed_priority_queue.odin](../../../odin/p/indexed_priority_queue.odin) |
| Rust | [rust/p/indexed_priority_queue.rs](../../../rust/p/indexed_priority_queue.rs) |
| V | [v/p/indexed_priority_queue.v](../../../v/p/indexed_priority_queue.v) |
| Zig | [zig/p/indexed_priority_queue.zig](../../../zig/p/indexed_priority_queue.zig) |

## Source distinction

TheAlgorithms/C-Plus-Plus `binary_heap_indexed_operations` uses array positions for decrease and delete on a fixed-capacity min-heap. This package follows the Java source's identity-addressed handles, arbitrary-element removal, automatic growth, and bidirectional key updates. The `priority_queues` package is a non-indexed max-heap.

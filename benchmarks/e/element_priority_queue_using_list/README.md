# Element Priority Queue Using a List

This package benchmarks the `ElementPriorityQueue` class in the pinned Python source. Enqueue appends an integer to an unsorted list. Dequeue finds the minimum and removes its first matching occurrence, giving an array-list remove-min behavior with O(1) append and O(n) dequeue.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[operation_count, (opcode, argument)*]`. The count is 0 through 256 and the packed length must be exactly `1 + 2 * operation_count`. The maximum valid input has 513 words; 514 words are parseable so a trailing word can be rejected.
- Opcode `0` enqueues a signed-i32 argument. Opcode `1` dequeues the minimum and requires zero argument padding.
- The queue holds at most 100 items. Enqueuing when full or dequeuing when empty invalidates the entire trace. Invalid opcodes, padding, or values also return `-1`.
- The output concatenates each dequeued value as one little-endian signed 64-bit word. At most 128 dequeues fit in 256 operations, so the output is at most 1,024 bytes. A valid trace with no dequeue returns 0 and writes no bytes.
- `ElementPriorityQueue.dequeue` uses `min(queue)` followed by `queue.remove(minimum)`. The first equal minimum is removed, preserving FIFO order among equal items; equal integer values are indistinguishable in the output trace.
- Input validity is resolved before output-buffer validation. Invalid traces return `-1` without partial output. A null output pointer or short capacity returns `-2`; a nonnull zero-capacity buffer succeeds for a zero-byte result. Output errors never write bytes.

This unsorted-list remove-min ADT is distinct from the linked-list implementation in `ascending_priority_queue` and the fixed-bucket class in [`fixed_priority_queue_using_list`](../../f/fixed_priority_queue_using_list/README.md).

## Workload and source

[`workload.json`](workload.json) includes minimum ordering, equal values, signed int32 boundaries, underflow, the 100-item capacity, malformed framing, and output-buffer ABI cases. The independent reference is [`element_priority_queue_using_list_oracle.py`](../../element_priority_queue_using_list_oracle.py).

The pinned source is [TheAlgorithms/Python `priority_queue_using_list.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/queues/priority_queue_using_list.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`, class `ElementPriorityQueue`.

## Language ports

| Language | Source |
| --- | --- |
| C | [c/e/element_priority_queue_using_list.c](../../c/e/element_priority_queue_using_list.c) |
| C3 | [c3/e/element_priority_queue_using_list.c3](../../c3/e/element_priority_queue_using_list.c3) |
| C++ | [cpp/e/element_priority_queue_using_list.cpp](../../cpp/e/element_priority_queue_using_list.cpp) |
| Elisa | [elisa/e/element_priority_queue_using_list.elisa](../../elisa/e/element_priority_queue_using_list.elisa) |
| Nim | [nim/e/element_priority_queue_using_list.nim](../../nim/e/element_priority_queue_using_list.nim) |
| Odin | [odin/e/element_priority_queue_using_list.odin](../../odin/e/element_priority_queue_using_list.odin) |
| Rust | [rust/e/element_priority_queue_using_list.rs](../../rust/e/element_priority_queue_using_list.rs) |
| V | [v/e/element_priority_queue_using_list.v](../../v/e/element_priority_queue_using_list.v) |
| Zig | [zig/e/element_priority_queue_using_list.zig](../../zig/e/element_priority_queue_using_list.zig) |

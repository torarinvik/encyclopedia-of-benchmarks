# Fixed Priority Queue Using a List

This package benchmarks the `FixedPriorityQueue` class in the pinned Python source. It has three FIFO buckets. Dequeue checks bucket 0 first, then bucket 1, then bucket 2, so lower numeric priority values are served before higher values. This is distinct from the linked-list remove-min algorithm in `ascending_priority_queue` and the max-heap in `priority_queues`.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[operation_count, (opcode, priority, data)*]`. The count is 0 through 256 and the packed length must be exactly `1 + 3 * operation_count`. The maximum valid input has 769 words; 770 words are parseable so a trailing word can be rejected.
- Opcode `0` enqueues signed-i32 `data` at priority `-3` through `2`. Priorities `0`, `1`, and `2` select their documented buckets. The pinned Python list indexing also accepts `-3`, `-2`, and `-1`, mapping them to buckets 0, 1, and 2 respectively; this observable behavior is included.
- Opcode `1` dequeues and requires zero priority/data padding. It removes the first item in the earliest nonempty bucket, preserving FIFO order within each bucket.
- Each bucket holds at most 100 items. Enqueuing into a full bucket or dequeuing from an empty queue invalidates the entire trace. Invalid operation records and out-of-range inputs also return `-1`.
- The output concatenates each dequeued value as one little-endian signed 64-bit word. At most 128 dequeues fit in 256 operations, so the output is at most 1,024 bytes. A valid trace with no dequeue returns 0 and writes no bytes.
- Input validity is resolved before output-buffer validation. Invalid traces return `-1` without partial output. A null output pointer or short capacity returns `-2`; a nonnull zero-capacity buffer succeeds for a zero-byte result. Output errors never write bytes.

The source's `ElementPriorityQueue` is a separate unsorted-list remove-min ADT and has its own package, [`element_priority_queue_using_list`](../../e/element_priority_queue_using_list/README.md).

## Workload and source

[`workload.json`](workload.json) includes priority order, FIFO behavior, Python negative-index priorities, int32 boundaries, underflow, per-bucket capacity, malformed framing, and output-buffer ABI cases. The independent reference is [`fixed_priority_queue_using_list_oracle.py`](../../fixed_priority_queue_using_list_oracle.py).

The pinned source is [TheAlgorithms/Python `priority_queue_using_list.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/queues/priority_queue_using_list.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`, class `FixedPriorityQueue`.

## Language ports

| Language | Source |
| --- | --- |
| C | [c/f/fixed_priority_queue_using_list.c](../../c/f/fixed_priority_queue_using_list.c) |
| C3 | [c3/f/fixed_priority_queue_using_list.c3](../../c3/f/fixed_priority_queue_using_list.c3) |
| C++ | [cpp/f/fixed_priority_queue_using_list.cpp](../../cpp/f/fixed_priority_queue_using_list.cpp) |
| Elisa | [elisa/f/fixed_priority_queue_using_list.elisa](../../elisa/f/fixed_priority_queue_using_list.elisa) |
| Nim | [nim/f/fixed_priority_queue_using_list.nim](../../nim/f/fixed_priority_queue_using_list.nim) |
| Odin | [odin/f/fixed_priority_queue_using_list.odin](../../odin/f/fixed_priority_queue_using_list.odin) |
| Rust | [rust/f/fixed_priority_queue_using_list.rs](../../rust/f/fixed_priority_queue_using_list.rs) |
| V | [v/f/fixed_priority_queue_using_list.v](../../v/f/fixed_priority_queue_using_list.v) |
| Zig | [zig/f/fixed_priority_queue_using_list.zig](../../zig/f/fixed_priority_queue_using_list.zig) |

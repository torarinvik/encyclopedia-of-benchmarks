# Min-priority queue operation trace

This benchmark follows the pinned Java and JavaScript fixed-capacity, 1-indexed binary min-heaps. Both insert keys into a min-heap, peek at the minimum, delete the minimum, and report whether the queue is empty or full. Equal keys are valid; the observable results are key values, so internal tie placement does not change the trace.

## Contract

- The ABI is `i64_array_bytes_output`. Input is `[capacity, operation_count, opcode, key_if_insert, ...]`. Capacity and operation count are each 0–64. Opcode `0` inserts a signed-i32 key, `1` peeks, `2` deletes the minimum, `3` checks emptiness, and `4` checks fullness. Only insert consumes a key. The input must contain exactly the declared operations.
- Insert into a full queue, or peek/delete on an empty queue, makes the trace invalid and returns `-1`. This gives the Java exception and JavaScript no-op/undefined paths one deterministic ABI. Both status queries remain valid at every queue size. With capacity zero, both `isEmpty` and `isFull` are true.
- Inserts emit no result. Each peek, delete, or status query emits a `[kind, value]` pair. Kinds are `1` peek, `2` delete, `3` empty (`1` true), and `4` full (`1` true). Output is `[query_count, kind, value, ...]` in little-endian signed-i32 words.
- A valid empty trace `[capacity, 0]` returns `[0]` in 4 bytes. The maximum output is 516 bytes for 64 query operations; the maximum input is 130 signed-i64 words for 64 inserts at capacity 64. Invalid or null input returns `-1` before output-buffer checks. A null output pointer or insufficient capacity returns `-2` without writes.
- Printing and the source-specific `heapSort`/`heapReverse` helpers are excluded. Java's `heapSort` loop tests against the changing queue size, so it does not drain every initial item. JavaScript's `heapReverse` drains the queue and then stores the values in descending order.

The workload and ABI fixtures are in [workload.json](workload.json). The independent min-heap oracle is [benchmarks/min_priority_queue_oracle.py](../../min_priority_queue_oracle.py).

Pinned sources: [TheAlgorithms/Java `MinPriorityQueue.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/heaps/MinPriorityQueue.java) and [TheAlgorithms/JavaScript `MinPriorityQueue.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Heap/MinPriorityQueue.js).

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm min_priority_queue --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm min_priority_queue
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm min_priority_queue --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/m/min_priority_queue.c](../../../c/m/min_priority_queue.c) |
| C3 | [c3/m/min_priority_queue.c3](../../../c3/m/min_priority_queue.c3) |
| C++ | [cpp/m/min_priority_queue.cpp](../../../cpp/m/min_priority_queue.cpp) |
| Elisa | [elisa/m/min_priority_queue.elisa](../../../elisa/m/min_priority_queue.elisa) |
| Nim | [nim/m/min_priority_queue.nim](../../../nim/m/min_priority_queue.nim) |
| Odin | [odin/m/min_priority_queue.odin](../../../odin/m/min_priority_queue.odin) |
| Rust | [rust/m/min_priority_queue.rs](../../../rust/m/min_priority_queue.rs) |
| V | [v/m/min_priority_queue.v](../../../v/m/min_priority_queue.v) |
| Zig | [zig/m/min_priority_queue.zig](../../../zig/m/min_priority_queue.zig) |

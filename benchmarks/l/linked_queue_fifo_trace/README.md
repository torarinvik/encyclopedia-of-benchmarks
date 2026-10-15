# Linked queue FIFO trace

This package compares linked FIFO queue operations over a deterministic integer trace. It records explicit dequeues, then drains any remaining elements and emits the removed values in order.

## Contract

- Input is `[operation_count, (operation,value)...]` as signed 64-bit integers, with exact packing and no trailing fields. There are 0 through 127 operations.
- Operation `0` enqueues a signed i32 value. Operation `1` dequeues and requires its paired value to be zero. Values are ordinary non-null integers; the whole signed i32 range is allowed.
- A dequeue must have a queued element. Once a dequeue empties the queue, no later enqueue is allowed; such traces avoid TypeScript's stale-tail reuse behavior. After the explicit operations, the remaining queue is drained.
- Output is the sequence of explicit-dequeue results followed by the final drain, encoded as little-endian signed i32 values. The function returns the output byte count.
- Malformed traces return `-1`; insufficient output capacity returns `-2`.

The queue is represented by linked nodes with front/head and rear/tail pointers. The pinned Python implementation computes emptiness through `len(self)`, which traverses the queue, so its emptiness check is O(n); the bounded contract preserves its FIFO results while avoiding timing empty-check behavior as part of the output. Java rejects null enqueues, which the integer-only input domain excludes. The Lua and TypeScript implementations also expose empty-state sentinels that are avoided by requiring nonempty explicit dequeues.

## Pinned source variants

- [TheAlgorithms/Java `LinkedQueue.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/queues/LinkedQueue.java)
- [TheAlgorithms/Lua `linked_queue.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/linked_queue.lua)
- [TheAlgorithms/Python `linked_queue.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/queues/linked_queue.py)
- [TheAlgorithms/TypeScript `linked_queue.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/queue/linked_queue.ts)

[`workload.json`](workload.json) covers alternating operations, batch dequeues and final draining, repeated and negative values, empty traces, an i32 boundary value, and invalid underflow/reuse/domain cases.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/l/linked_queue_fifo_trace.c`](../../../c/l/linked_queue_fifo_trace.c) |
| C3 | [`c3/l/linked_queue_fifo_trace.c3`](../../../c3/l/linked_queue_fifo_trace.c3) |
| C++ | [`cpp/l/linked_queue_fifo_trace.cpp`](../../../cpp/l/linked_queue_fifo_trace.cpp) |
| Elisa | [`elisa/l/linked_queue_fifo_trace.elisa`](../../../elisa/l/linked_queue_fifo_trace.elisa) |
| Nim | [`nim/l/linked_queue_fifo_trace.nim`](../../../nim/l/linked_queue_fifo_trace.nim) |
| Odin | [`odin/l/linked_queue_fifo_trace.odin`](../../../odin/l/linked_queue_fifo_trace.odin) |
| Rust | [`rust/l/linked_queue_fifo_trace.rs`](../../../rust/l/linked_queue_fifo_trace.rs) |
| V | [`v/l/linked_queue_fifo_trace.v`](../../../v/l/linked_queue_fifo_trace.v) |
| Zig | [`zig/l/linked_queue_fifo_trace.zig`](../../../zig/l/linked_queue_fifo_trace.zig) |

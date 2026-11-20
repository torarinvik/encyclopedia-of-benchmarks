# Erasable priority queue trace

This profile benchmarks a min-priority queue that supports erasing one matching value. The implementation strategy uses a live min-heap and a second min-heap of deleted values; equal roots are cancelled lazily before a read or removal. Repeated values represent separate queue entries.

## Contract

- ABI: `i64_array_scalar`. Input is `[Q, (opcode, value)...]` with exact framing; `Q` is 0 through 63.
- Values for push and erase are in `[-100,100]`. Opcode `0` pushes one value. Opcode `1` erases one existing copy by value and is invalid when no copy exists.
- Opcode `2` peeks the minimum and requires `value=0`. Peeking an empty queue returns `-101`. Opcode `3` removes and returns the minimum, requires `value=0`, and is invalid when the queue is empty.
- The response is 0 for push, 1 for erase, and the observed value for peek/pop. The result is the sum of `operation_index * (opcode*202 + response + 101)`, with one-based indices. Invalid input returns `-1`.
- The maximum valid input length is 127 words; the maximum parseable length is 128. Each implementation uses bounded storage for at most 63 trace entries.

The trace contract makes erase-by-value's missing-item behavior explicit and defines duplicate erasure as removing exactly one copy. Lazy cancellation preserves the abstract multiset while allowing the heap operations to measure the intended two-heap method. The primary reference uses two heaps; the independent reference uses an ordered multiset.

## Algorithm source

The implementation is a clean-room translation of the two-heap lazy-cancellation technique described by [NyaanNyaan Library's erasable priority queue](https://github.com/NyaanNyaan/library/blob/master/data-structure/erasable-priority-queue.hpp), also indexed in its [public library index](https://nyaannyaan.github.io/library/). No source code was copied.

[`workload.json`](workload.json) includes empty and duplicate-heavy traces, negative values, lazy cancellation below the live heap root, invalid erasures and pops, malformed framing, and null input.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/erasable_priority_queue_trace.c`](../../../c/e/erasable_priority_queue_trace.c) |
| C3 | [`c3/e/erasable_priority_queue_trace.c3`](../../../c3/e/erasable_priority_queue_trace.c3) |
| C++ | [`cpp/e/erasable_priority_queue_trace.cpp`](../../../cpp/e/erasable_priority_queue_trace.cpp) |
| Elisa | [`elisa/e/erasable_priority_queue_trace.elisa`](../../../elisa/e/erasable_priority_queue_trace.elisa) |
| Mojo | [`mojo/e/erasable_priority_queue_trace.mojo`](../../../mojo/e/erasable_priority_queue_trace.mojo) |
| Nim | [`nim/e/erasable_priority_queue_trace.nim`](../../../nim/e/erasable_priority_queue_trace.nim) |
| Odin | [`odin/e/erasable_priority_queue_trace.odin`](../../../odin/e/erasable_priority_queue_trace.odin) |
| Rust | [`rust/e/erasable_priority_queue_trace.rs`](../../../rust/e/erasable_priority_queue_trace.rs) |
| V | [`v/e/erasable_priority_queue_trace.v`](../../../v/e/erasable_priority_queue_trace.v) |
| Zig | [`zig/e/erasable_priority_queue_trace.zig`](../../../zig/e/erasable_priority_queue_trace.zig) |

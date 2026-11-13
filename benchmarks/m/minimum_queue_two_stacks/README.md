# Minimum queue using two minimum-augmented stacks

This benchmark executes bounded FIFO traces that enqueue values, dequeue and
report the front value, and query the current minimum. The primary method
stores each stack item together with the minimum at that stack depth. Enqueues
go to the input stack; when a dequeue finds the output stack empty, all input
items transfer in reverse order. The queue minimum is the smaller of the two
stack minima.

## Contract

The `i64_array_scalar` symbol is `minimum_queue_two_stacks`. Input is
`[Q,(opcode[,value])...]` with `0<=Q<=32` and queue capacity 16. Opcode `0`
consumes a value in `[-1000,1000]` and enqueues it; opcode `1` dequeues and
reports the front value; opcode `2` reports the minimum. Dequeue and minimum
query on an empty queue, capacity overflow, unknown opcode, malformed framing,
or an out-of-range value returns `-1`.

For every dequeue or minimum query at zero-based operation index `i`, add
`(i+1)*(reported_value+1001)` to the scalar checksum. After all operations,
add `(j+1)*(queue_value+1001)` for each remaining item at zero-based FIFO
position `j`. This preserves distinctions between common operation traces
without requiring an output buffer. Maximum valid and parseable input lengths
are 57 and 65 i64 values. Four fixed 16-element i64 arrays for stack values and
prefix minima use a declared 512-byte workspace.

The primary takes O(Q) amortized time: each item is pushed once, transferred at
most once, and popped at most once; minimum queries are O(1). The independent
oracle uses a direct FIFO list and scans all current values for each minimum,
which is practical for the bounded capacity 16.

## Distinctness and provenance

[`queue_using_two_stacks`](../../q/queue_using_two_stacks/README.md) implements
FIFO operations without maintaining aggregate minima. [`min_stack`](../min_stack/README.md)
and [`min_stack_using_two_stacks`](../min_stack_using_two_stacks/README.md)
provide LIFO minimum queries. [`monotonic_queue`](../monotonic_queue/README.md)
computes sliding-window maxima using a candidate deque; it has different
operations and a different invariant.

The method description comes from [CP-Algorithms, “Minimum Stack / Minimum
Queue”](https://cp-algorithms.com/data_structures/stack_queue_modification.html),
licensed under CC BY-SA 4.0. Only the high-level two-stack method is used. See
[`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the [primary
oracle](primary_oracle.py), the [independent oracle](independent_oracle.py), and
the [static package checker](verify_minimum_queue_two_stacks_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/m/minimum_queue_two_stacks.c`](../../../c/m/minimum_queue_two_stacks.c) |
| C3 | [`c3/m/minimum_queue_two_stacks.c3`](../../../c3/m/minimum_queue_two_stacks.c3) |
| C++ | [`cpp/m/minimum_queue_two_stacks.cpp`](../../../cpp/m/minimum_queue_two_stacks.cpp) |
| Elisa | [`elisa/m/minimum_queue_two_stacks.elisa`](../../../elisa/m/minimum_queue_two_stacks.elisa) |
| Mojo | [`mojo/m/minimum_queue_two_stacks.mojo`](../../../mojo/m/minimum_queue_two_stacks.mojo) |
| Nim | [`nim/m/minimum_queue_two_stacks.nim`](../../../nim/m/minimum_queue_two_stacks.nim) |
| Odin | [`odin/m/minimum_queue_two_stacks.odin`](../../../odin/m/minimum_queue_two_stacks.odin) |
| Rust | [`rust/m/minimum_queue_two_stacks.rs`](../../../rust/m/minimum_queue_two_stacks.rs) |
| V | [`v/m/minimum_queue_two_stacks.v`](../../../v/m/minimum_queue_two_stacks.v) |
| Zig | [`zig/m/minimum_queue_two_stacks.zig`](../../../zig/m/minimum_queue_two_stacks.zig) |

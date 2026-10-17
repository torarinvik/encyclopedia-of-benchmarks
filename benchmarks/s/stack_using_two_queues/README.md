# Stack Using Two Queues

A stack implemented with two FIFO queues. Push places the new item at the front by enqueueing it in the temporary queue, moving the previous main queue behind it, and swapping queues. Pop removes the front; peek reads the front.

## Contract

- ABI: i64_array_bytes_output.
- Input is [op_count, (opcode, operand) ...], with 0–128 operations and exact length 1 + 2 * op_count. Opcode 0 pushes a signed 32-bit value; opcode 1 pops and requires operand 0; opcode 2 peeks and requires operand 0.
- Push accepts [-2^31, 2^31-1]. Pop from empty, an unknown opcode, malformed framing, a nonzero pop/peek operand, or an out-of-range push returns -1 before output storage is checked.
- Every pop returns [0, value] in two little-endian signed 64-bit words. A nonempty peek returns the same record without removing the value. An empty peek returns [1, 0] for None/null. Push emits no record. The function returns output bytes, with a maximum of 2,048.
- Null input returns -1. Null output returns -2, even for a trace that emits no records. A non-null output pointer with zero capacity succeeds for a zero-record trace. Insufficient capacity returns -2; errors do not write output.
- The Java source also provides size and isEmpty; these are outside the shared trace because the pinned Python API has no corresponding methods.

## Workload

[workload.json](workload.json) covers LIFO behavior, empty peek, invalid underflow, signed 32-bit boundaries, two-queue reordering, ABI precedence, and the maximum 128 empty-peek records. See the [oracle](../../stack_using_two_queues_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/stack_using_two_queues.c](../../../c/s/stack_using_two_queues.c) |
| C3 | [c3/s/stack_using_two_queues.c3](../../../c3/s/stack_using_two_queues.c3) |
| C++ | [cpp/s/stack_using_two_queues.cpp](../../../cpp/s/stack_using_two_queues.cpp) |
| Elisa | [elisa/s/stack_using_two_queues.elisa](../../../elisa/s/stack_using_two_queues.elisa) |
| Nim | [nim/s/stack_using_two_queues.nim](../../../nim/s/stack_using_two_queues.nim) |
| Odin | [odin/s/stack_using_two_queues.odin](../../../odin/s/stack_using_two_queues.odin) |
| Rust | [rust/s/stack_using_two_queues.rs](../../../rust/s/stack_using_two_queues.rs) |
| V | [v/s/stack_using_two_queues.v](../../../v/s/stack_using_two_queues.v) |
| Zig | [zig/s/stack_using_two_queues.zig](../../../zig/s/stack_using_two_queues.zig) |

## Pinned sources

- [TheAlgorithms/Python StackWithQueues](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/stack_using_two_queues.py) at e1a2a8b016001309a73d5fec4818c35cca139795.
- [TheAlgorithms/Java StackUsingTwoQueues](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/StackUsingTwoQueues.java) at e43ec3897e48f23843972d02cd05a5bb1b6864a2.

## Build and record

    python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm stack_using_two_queues --language rust
    python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/s/stack_using_two_queues/rust/build.json
    python3 benchmarks/verify_i64_array_bytes_output.py --algorithm stack_using_two_queues

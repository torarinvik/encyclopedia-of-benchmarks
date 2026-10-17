# Min stack using two stacks

This package ports the pinned Java `MinStackUsingTwoStacks`. One stack stores pushed values and the second stores each new minimum, including duplicate minima. Unlike the one-stack package, popping an empty stack raises `EmptyStackException`; the packed ABI records that exception and leaves the stack unchanged.

## Contract

- Input is an i64 array beginning with an operation count from 0 through 256, followed by exactly that many operations. Opcode `0` is `push` and consumes one signed 32-bit operand; `1` is `pop`; `2` is `top`; and `3` is `getMin`.
- Every `pop`, `top`, and `getMin` emits an event `[opcode, exception_flag, value]`. Successful pop emits `[1, 0, 0]`; empty pop emits `[1, 1, 0]` and does not mutate the stack. Successful top/min queries emit their value with flag `0`; an empty query emits flag `1` and value `0`. Execution continues after these expected empty-stack exceptions.
- The input must be non-null, contain at most 513 values, and end exactly after the declared operation count. Unknown opcodes, missing push operands, trailing values, or push operands outside signed 32-bit range return `-1` without output.
- Output starts with the number of event records, followed by each three-i64 event, all encoded as signed little-endian i64 values. Maximum output is 6,152 bytes. A null output buffer or insufficient capacity for a valid trace returns `-2` without writing.

The pinned Java source is [`MinStackUsingTwoStacks.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/MinStackUsingTwoStacks.java). This package stays separate from [min_stack](../min_stack/README.md), whose empty `pop` is a no-op. See the [workload](workload.json) and [oracle](../../min_stack_using_two_stacks_oracle.py).

| Language | Port |
|---|---|
| C | [min_stack_using_two_stacks.c](../../../c/m/min_stack_using_two_stacks.c) |
| C3 | [min_stack_using_two_stacks.c3](../../../c3/m/min_stack_using_two_stacks.c3) |
| C++ | [min_stack_using_two_stacks.cpp](../../../cpp/m/min_stack_using_two_stacks.cpp) |
| Elisa | [min_stack_using_two_stacks.elisa](../../../elisa/m/min_stack_using_two_stacks.elisa) |
| Nim | [min_stack_using_two_stacks.nim](../../../nim/m/min_stack_using_two_stacks.nim) |
| Odin | [min_stack_using_two_stacks.odin](../../../odin/m/min_stack_using_two_stacks.odin) |
| Rust | [min_stack_using_two_stacks.rs](../../../rust/m/min_stack_using_two_stacks.rs) |
| V | [min_stack_using_two_stacks.v](../../../v/m/min_stack_using_two_stacks.v) |
| Zig | [min_stack_using_two_stacks.zig](../../../zig/m/min_stack_using_two_stacks.zig) |

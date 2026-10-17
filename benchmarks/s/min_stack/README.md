# Min stack

This package ports the pinned Java `MinStackUsingSingleStack`. Each push stores the value together with the minimum seen at that depth, so `getMin` and `top` take constant time. Popping an empty stack is a no-op. Querying an empty stack corresponds to Java's `EmptyStackException` and is recorded in the packed output while later operations continue.

## Contract

- Input is an i64 array beginning with an operation count from 0 through 256, followed by exactly that many operations. Opcode `0` is `push` and consumes one signed 32-bit operand; `1` is `pop`; `2` is `top`; and `3` is `getMin`.
- Empty `pop` is a no-op. Each `top` or `getMin` emits a record `[opcode, exception_flag, value]`. A successful query has flag `0` and its returned value. An empty-stack query has flag `1` and value `0`, matching `EmptyStackException`; execution then continues.
- The i64 input must be non-null, contain at most 513 values, and end exactly after the declared operation count. Unknown opcodes, missing push operands, trailing values, or push operands outside signed 32-bit range return `-1` without output.
- Output starts with the number of query records, followed by each three-i64 record, all encoded as signed little-endian i64 values. The maximum output is 6,152 bytes. A null output buffer or insufficient capacity for an otherwise valid trace returns `-2` without writing.

The source is pinned to [`MinStackUsingSingleStack.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/MinStackUsingSingleStack.java). See the [workload](workload.json) and [oracle](../../min_stack_oracle.py).

| Language | Port |
|---|---|
| C | [min_stack.c](../../../c/s/min_stack.c) |
| C3 | [min_stack.c3](../../../c3/s/min_stack.c3) |
| C++ | [min_stack.cpp](../../../cpp/s/min_stack.cpp) |
| Elisa | [min_stack.elisa](../../../elisa/s/min_stack.elisa) |
| Nim | [min_stack.nim](../../../nim/s/min_stack.nim) |
| Odin | [min_stack.odin](../../../odin/s/min_stack.odin) |
| Rust | [min_stack.rs](../../../rust/s/min_stack.rs) |
| V | [min_stack.v](../../../v/s/min_stack.v) |
| Zig | [min_stack.zig](../../../zig/s/min_stack.zig) |

# List-based stack

This benchmark follows the pinned C# `ListBasedStack<T>`, backed by `LinkedList<T>`. The ABI models a fresh stack per call. Its initial items use the source's enumerable constructor, which pushes each item in sequence; the last initial item is therefore on top.

## Contract

The `i64_array_bytes_output` input is `[initial_count, initial_items..., operation_count, operation_records...]`. There are 0–32 initial signed-i32 items and 0–64 operations, for a maximum input of 162 signed-i64 words. Each operation is one of: `1 push(value)`, `2 pop()`, `3 peek()`, `4 count()`, `5 contains(value)`, or `6 clear()`. Push and contains consume one signed-i32 operand; all other operations consume only their opcode. Duplicates are allowed. Pop and peek require a nonempty stack, matching the source's `InvalidOperationException` behavior; an empty pop or peek makes the packed trace invalid and returns `-1`.

Each operation emits one `[opcode, result]` record of two little-endian signed-i64 words. Push and clear emit 0; pop emits and removes the top item; peek emits the top item without removing it; count emits the current size; contains emits 0 or 1. The function returns the number of output bytes. Invalid input returns `-1` before output checks. A null output pointer or insufficient capacity returns `-2` without writing output, including a null output pointer for an empty trace. Non-null capacity zero succeeds for an empty trace. The maximum output is 1,024 bytes, and the maximum stack size is 96 items.

The workload is [workload.json](workload.json); the independent list-based oracle is [list_based_stack_oracle.py](../../list_based_stack_oracle.py).

Pinned source: [TheAlgorithms/C-Sharp `ListBasedStack.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Stack/ListBasedStack.cs) at commit `96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c`.

## Reproduce

~~~sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm list_based_stack --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm list_based_stack
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm list_based_stack --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/l/list_based_stack.c](../../../c/l/list_based_stack.c) |
| C3 | [c3/l/list_based_stack.c3](../../../c3/l/list_based_stack.c3) |
| C++ | [cpp/l/list_based_stack.cpp](../../../cpp/l/list_based_stack.cpp) |
| Elisa | [elisa/l/list_based_stack.elisa](../../../elisa/l/list_based_stack.elisa) |
| Nim | [nim/l/list_based_stack.nim](../../../nim/l/list_based_stack.nim) |
| Odin | [odin/l/list_based_stack.odin](../../../odin/l/list_based_stack.odin) |
| Rust | [rust/l/list_based_stack.rs](../../../rust/l/list_based_stack.rs) |
| V | [v/l/list_based_stack.v](../../../v/l/list_based_stack.v) |
| Zig | [zig/l/list_based_stack.zig](../../../zig/l/list_based_stack.zig) |

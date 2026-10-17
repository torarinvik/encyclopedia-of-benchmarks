# Linked stack operation trace

This benchmark follows the pinned Lua linked stack. The stack starts empty; push links a new node above the current head, top reads the head, pop advances to the node below it, and empty reports whether the head is nil. Empty top and pop return nil and leave the stack unchanged, so later operations in the trace still execute.

## Contract

- The ABI uses the i64-array-bytes-output family. Input is [operation_count, opcode, push_value_if_needed, ...].
- There are 0 through 64 operations. Opcode 1 is push(value), opcode 2 is top, opcode 3 is pop, and opcode 4 is empty. Only push consumes an extra value. Push values are signed i32 carried in signed-i64 words. The input must end exactly after the declared operations.
- Push returns nil. Top returns the current value or nil if empty. Pop returns and removes the current value, or returns nil without mutation if empty. Empty returns a boolean. Repeated values are valid. The bounded operation count makes stack overflow impossible.
- Every operation emits one 24-byte record [opcode, result_tag, value], encoded as three little-endian signed-i64 words. Tag 0 means integer, tag 1 means boolean (value 1 for empty and 0 otherwise), and tag 2 means nil (value 0). Push emits nil. Empty top/pop emit nil and do not stop the trace.
- Invalid input returns -1 before output-buffer checks. A null output pointer returns -2 even for an empty trace. A non-null buffer with insufficient capacity returns -2 without writing partial output; a non-null buffer with capacity 0 succeeds for a zero-operation trace.
- The maximum packed input has 129 words and the maximum output is 1,536 bytes.

Ports represent linked nodes with a bounded node pool: each push links a fresh slot to the current head, and pop updates the head to the saved below link. This keeps the source's linked behavior while limiting per-call storage to the maximum operation count.

## Workload and oracle

[workload.json](workload.json) covers nil results on empty top/pop, continued execution, repeated values, signed-i32 boundaries, malformed traces, null pointers, and output capacity. The independent list-based oracle is [benchmarks/linked_stack_oracle.py](../../linked_stack_oracle.py).

Pinned source: [TheAlgorithms/Lua linked_stack.lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/linked_stack.lua)

## Reproduce

~~~sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm linked_stack --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm linked_stack
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm linked_stack --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/l/linked_stack.c](../../../c/l/linked_stack.c) |
| C3 | [c3/l/linked_stack.c3](../../../c3/l/linked_stack.c3) |
| C++ | [cpp/l/linked_stack.cpp](../../../cpp/l/linked_stack.cpp) |
| Elisa | [elisa/l/linked_stack.elisa](../../../elisa/l/linked_stack.elisa) |
| Nim | [nim/l/linked_stack.nim](../../../nim/l/linked_stack.nim) |
| Odin | [odin/l/linked_stack.odin](../../../odin/l/linked_stack.odin) |
| Rust | [rust/l/linked_stack.rs](../../../rust/l/linked_stack.rs) |
| V | [v/l/linked_stack.v](../../../v/l/linked_stack.v) |
| Zig | [zig/l/linked_stack.zig](../../../zig/l/linked_stack.zig) |

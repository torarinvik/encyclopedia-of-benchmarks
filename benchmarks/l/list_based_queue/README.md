# List-Based Queue

A bounded FIFO trace based on the pinned TheAlgorithms/C-Sharp `ListBasedQueue<T>`. The implementation uses a linked node pool and preserves enqueue/dequeue order, clearing, empty-state checks, and the source’s always-false `IsFull`.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[op_count, operation records...]`, with 0–32 operations and exact opcode-specific framing. Enqueue values are signed i32 integers. Maximum valid input length is 65 i64 words; 66 words is the maximum parseable length so a trailing word can be rejected.
- Opcodes: 0 enqueue(value), 1 dequeue, 2 peek, 3 clear, 4 isEmpty, 5 isFull. Dequeue and peek on an empty queue make the whole trace invalid.
- Each operation emits a two-word little-endian signed i64 record: enqueue `[0,1]`, dequeue `[1,value]`, peek `[2,value]`, clear `[3,1]`, isEmpty `[4,0|1]`, and isFull `[5,0]`.
- Invalid input, including empty dequeue/peek, returns -1 before output checks. Null input returns -1. Null output or insufficient capacity returns -2 without writes, even for a valid zero-output trace. Maximum output is 512 bytes.

## Workload

[workload.json](workload.json) includes FIFO, clear-and-reuse, boundary-value, invalid-trace, null-pointer precedence, and exact/short maximum-output cases. See the [oracle](../../list_based_queue_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/l/list_based_queue.c](../../../c/l/list_based_queue.c) |
| C3 | [c3/l/list_based_queue.c3](../../../c3/l/list_based_queue.c3) |
| C++ | [cpp/l/list_based_queue.cpp](../../../cpp/l/list_based_queue.cpp) |
| Elisa | [elisa/l/list_based_queue.elisa](../../../elisa/l/list_based_queue.elisa) |
| Nim | [nim/l/list_based_queue.nim](../../../nim/l/list_based_queue.nim) |
| Odin | [odin/l/list_based_queue.odin](../../../odin/l/list_based_queue.odin) |
| Rust | [rust/l/list_based_queue.rs](../../../rust/l/list_based_queue.rs) |
| V | [v/l/list_based_queue.v](../../../v/l/list_based_queue.v) |
| Zig | [zig/l/list_based_queue.zig](../../../zig/l/list_based_queue.zig) |

## Pinned source

[TheAlgorithms/C-Sharp `ListBasedQueue.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Queue/ListBasedQueue.cs) at commit `96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c`.

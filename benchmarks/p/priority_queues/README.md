# Priority Queues

This benchmark ports the pinned Java PriorityQueue as a fixed-capacity integer max-heap. It preserves the source's one-based heap indexing, strict comparisons during swim and sink, and its distinct full-insert and empty-remove errors.

## Contract

The i64_array_bytes_output input is a signed 64-bit array:

    [capacity, operation_count, opcode_0, argument_0, ...]

Capacity is 1 through 128. Operation count is 0 through 256, and the input length must be exactly 2 + 2 * operation_count. Opcode 0 inserts its signed 32-bit argument. Opcodes 1 through 5 are remove-max, peek, isEmpty, isFull, and getSize; their arguments must be zero.

Each operation produces two signed little-endian 64-bit values, [status, value]. Status 0 means success, 1 records the source's full-insert exception, and 2 records its empty-remove exception. A failed operation leaves the heap unchanged, and the trace continues as if the caller caught that exception. Insert emits value 0. Remove-max emits the removed maximum, or value 0 on an empty-queue error. Peek returns the root slot, which is 0 when empty. isEmpty and isFull return 0 or 1; getSize returns the current element count.

A zero-operation trace returns 0 and writes no bytes, including when output is null or has zero capacity. Otherwise the result is the number of output bytes written: 16 * operation_count, at most 4,096. Null or undersized output returns -2 without writing. Malformed input returns -1. The maximum valid input has 514 values; 515 values is the parser limit so overlong input can be rejected safely.

The heap uses fixed storage for 128 values. Insert swims only while parent < child. During sink, the right child is selected only when it is strictly larger than the left; sinking stops when parent >= selected child. These strict comparisons preserve the Java implementation's tie behavior.

## Workload and oracle

The shared workload includes ordering and observation traces, duplicate keys and tied children, full and empty operations, signed 32-bit limits, output-capacity handling, malformed framing, and the maximum input/output sizes. The independent reference implementation is benchmarks/priority_queues_oracle.py.

Build an implementation and its ABI checker with:

    python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm priority_queues --language rust --with-checker

## Implementations

| Language | Source |
| --- | --- |
| C | c/p/priority_queues.c |
| C3 | c3/p/priority_queues.c3 |
| C++ | cpp/p/priority_queues.cpp |
| Elisa | elisa/p/priority_queues.elisa |
| Nim | nim/p/priority_queues.nim |
| Odin | odin/p/priority_queues.odin |
| Rust | rust/p/priority_queues.rs |
| V | v/p/priority_queues.v |
| Zig | zig/p/priority_queues.zig |

## Reviewed source

The pinned source is TheAlgorithms/Java PriorityQueues.java at commit e43ec3897e48f23843972d02cd05a5bb1b6864a2. Its default constructor has capacity 11; this benchmark uses its parameterized constructor so capacity is part of the workload.

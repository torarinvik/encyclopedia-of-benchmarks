# Queue Using Array 2

This benchmark captures the fixed-capacity queue in the two pinned C++ sources. The queue holds ten signed integer values. A dequeue removes the front item and shifts every remaining item one position left, so freed capacity is reusable. This is a separate algorithm from queue_using_array, whose linear array does not reuse dequeued prefix slots.

## Contract

- Input is a signed 64-bit array encoded as [q, (opcode, value) repeated q times]. q is in 0 through 256, the exact input length is 1 + 2*q, and the maximum length is 513.
- Opcode 1 enqueues a value in [-1,000,000, 1,000,000]. Opcode 2 dequeues and opcode 3 shows the queue; both require a dummy value of zero.
- The queue capacity is ten. An enqueue when full and a dequeue when empty leave the queue unchanged. A successful dequeue compacts the remaining values to the start. Show never changes the queue.
- Invalid layout, opcode, dummy payload, or enqueue value returns -1. Console messages and display text are excluded.
- The result is a state-trace digest. Start with h = 0. After every operation, append the opcode, the post-operation queue length, and each post-operation queue value plus 1,000,001. For every appended token t, update h = (h * 1,000,003 + t) mod 1,000,000,007. With no operations, the result is zero.
- The largest intermediate multiplication fits in signed 64-bit arithmetic.

## Workload and implementation

[`workload.json`](workload.json) covers an empty trace, FIFO and show behavior, overflow with compaction and reuse, value boundaries, and invalid records. All nine ports use the i64_array_scalar ABI family.

## Upstream sources

- [C++ queue_using_array2.cpp](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/queue_using_array2.cpp)
- [C++-1 queue_using_array2.cpp](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/queue_using_array2.cpp)

Build with `python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm queue_using_array2 --language c` and record with `benchmarks/run_i64_array_scalar.py`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/q/queue_using_array2.c`](../../../c/q/queue_using_array2.c) |
| C3 | [`c3/q/queue_using_array2.c3`](../../../c3/q/queue_using_array2.c3) |
| C++ | [`cpp/q/queue_using_array2.cpp`](../../../cpp/q/queue_using_array2.cpp) |
| Elisa | [`elisa/q/queue_using_array2.elisa`](../../../elisa/q/queue_using_array2.elisa) |
| Nim | [`nim/q/queue_using_array2.nim`](../../../nim/q/queue_using_array2.nim) |
| Odin | [`odin/q/queue_using_array2.odin`](../../../odin/q/queue_using_array2.odin) |
| Rust | [`rust/q/queue_using_array2.rs`](../../../rust/q/queue_using_array2.rs) |
| V | [`v/q/queue_using_array2.v`](../../../v/q/queue_using_array2.v) |
| Zig | [`zig/q/queue_using_array2.zig`](../../../zig/q/queue_using_array2.zig) |

# Linear Queue Using a Fixed Array

This benchmark captures the fixed-capacity linear queue in the two pinned C++ sources. It uses an array of ten `int16_t` entries and monotonically advances `front` and `rear`; dequeuing does not free a prefix slot for reuse. The source's dequeue return value passes through an `int8_t`, so the benchmark restricts enqueued values to the signed 8-bit range for portable, exact behavior.

## Contract

- Input is `[q, (opcode, value) * q]` in a signed 64-bit array. `q` is 0 through 512 and the exact input length is `1 + 2*q`.
- Opcode `0` enqueues a value in `[-128,127]`. Opcode `1` dequeues and requires its value field to be zero.
- The queue has capacity ten. An enqueue while `rear` is at the last array slot is ignored even if earlier entries have been dequeued. Dequeue on an empty queue returns zero. Dequeuing the final item resets both indices so the queue can be reused.
- Invalid lengths, opcodes, dequeue payloads, or enqueue values return `-1`.
- For dequeue results `d_1 ... d_m`, return `sum(k * (d_k + 128))` for `k=1..m`. The result is zero if there are no dequeues and at most 33,488,640.
- Console messages and display output are outside the benchmark result.

## Workload and implementation

[`workload.json`](workload.json) covers FIFO order, empty dequeue, capacity overflow, no prefix reuse, draining and reusing the queue, signed 8-bit limits, and invalid operation records. All nine ports use the `i64_array_scalar` ABI family.

## Upstream sources

- [C++ `queue_using_array.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/queue_using_array.cpp)
- [C++-1 `queue_using_array.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/queue_using_array.cpp)

Build with `python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm queue_using_array --language c` and record with `benchmarks/run_i64_array_scalar.py`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/q/queue_using_array.c`](../../../c/q/queue_using_array.c) |
| C3 | [`c3/q/queue_using_array.c3`](../../../c3/q/queue_using_array.c3) |
| C++ | [`cpp/q/queue_using_array.cpp`](../../../cpp/q/queue_using_array.cpp) |
| Elisa | [`elisa/q/queue_using_array.elisa`](../../../elisa/q/queue_using_array.elisa) |
| Nim | [`nim/q/queue_using_array.nim`](../../../nim/q/queue_using_array.nim) |
| Odin | [`odin/q/queue_using_array.odin`](../../../odin/q/queue_using_array.odin) |
| Rust | [`rust/q/queue_using_array.rs`](../../../rust/q/queue_using_array.rs) |
| V | [`v/q/queue_using_array.v`](../../../v/q/queue_using_array.v) |
| Zig | [`zig/q/queue_using_array.zig`](../../../zig/q/queue_using_array.zig) |

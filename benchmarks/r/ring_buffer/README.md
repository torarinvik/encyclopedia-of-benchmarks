# Fixed-Capacity Ring Buffer

This benchmark models the generic ring buffer in the pinned Zig source, instantiated with signed 64-bit values and capacity 8. Push and pop advance circular tail and head indices; the buffer reports full and empty errors without changing state. The benchmark includes the source's logical access and query methods, not just its FIFO subset.

## Contract

- Input is a signed 64-bit array encoded as [q, (opcode, payload) repeated q times]. q is in 0 through 256, the exact length is 1 + 2*q, and the maximum length is 513.
- Opcode 0 pushes a value in [-1,000,000, 1,000,000]. Opcodes 1 through 3 pop, peek at the front, and peek at the back; they require payload zero. Opcode 4 gets the FIFO-relative element at an index in [0, 1,000,000]. Opcodes 5 through 9 clear the buffer, return its length, return available capacity, return whether it is empty, and return whether it is full; they require payload zero.
- Capacity is 8. A push on a full buffer reports status 1 and leaves state unchanged. Pop or either peek on an empty buffer reports status 2 and leaves state unchanged. A get index at or beyond the current length reports status 3 and leaves state unchanged. Successful operations report status 0.
- The result field is the item returned by pop, peek, peekBack, or get; query operations return their scalar value; push and clear return zero. Failed operations return result zero. Boolean query results are 0 or 1.
- Invalid layout, opcode, payload, push value, or get index returns -1.
- The returned value is a state-trace digest. Start with h = 0. After each operation, append tokens [opcode, status, result + 1,000,001, post-operation length, each FIFO-ordered post-operation value + 1,000,001]. For each token t, update h = (h * 1,000,003 + t) mod 1,000,000,007. With no operations, the result is zero.
- The iterator is omitted as a convenience API; the state trace records the same logical FIFO ordering, and indexed access is represented by opcode 4.

## Workload and implementation

[`workload.json`](workload.json) covers empty errors, full-buffer rejection, wraparound, indexed access, status queries, clear and reuse, value bounds, and malformed records. The nine ports use the i64_array_scalar ABI family.

The shared queue benchmark covers bounded FIFO behavior, including wraparound, with its own broader capacity and result contract. This benchmark also captures the ring buffer's get, clear, available, and isFull methods and its explicit full, empty, and out-of-bounds outcomes.

## Upstream source

- [Zig ring_buffer.zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/tiger_style/ring_buffer.zig)

Build with `python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm ring_buffer --language c` and record with `benchmarks/run_i64_array_scalar.py`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/ring_buffer.c`](../../../c/r/ring_buffer.c) |
| C3 | [`c3/r/ring_buffer.c3`](../../../c3/r/ring_buffer.c3) |
| C++ | [`cpp/r/ring_buffer.cpp`](../../../cpp/r/ring_buffer.cpp) |
| Elisa | [`elisa/r/ring_buffer.elisa`](../../../elisa/r/ring_buffer.elisa) |
| Nim | [`nim/r/ring_buffer.nim`](../../../nim/r/ring_buffer.nim) |
| Odin | [`odin/r/ring_buffer.odin`](../../../odin/r/ring_buffer.odin) |
| Rust | [`rust/r/ring_buffer.rs`](../../../rust/r/ring_buffer.rs) |
| V | [`v/r/ring_buffer.v`](../../../v/r/ring_buffer.v) |
| Zig | [`zig/r/ring_buffer.zig`](../../../zig/r/ring_buffer.zig) |

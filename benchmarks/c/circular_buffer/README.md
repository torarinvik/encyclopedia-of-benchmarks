# Circular buffer overwrite trace

Model the pinned Java `CircularBuffer` behavior: a fixed-capacity FIFO that discards the oldest item when a write arrives while full. The write returns whether the buffer was empty before that write; reads remove and return the oldest item.

## Contract

The `i64_array_scalar` function accepts `[capacity, opcode, payload, ...]`, with a capacity followed by zero to 512 operation pairs:

- Capacity is from 1 through 256.
- `0`: put a value in `[0, 1,000,000]`; return `1` if the buffer was empty before insertion, otherwise `0`. If full, discard the oldest value and insert the new one.
- `1`: get and remove the oldest value with payload zero; return `-1` when empty.
- `2`: report empty as `1` or `0`, with payload zero.
- `3`: report full as `1` or `0`, with payload zero.
- `4`: report the current item count, with payload zero.

Invalid capacity, malformed input, an unknown opcode, an out-of-range value, or a nonzero payload for opcodes 1 through 4 returns `-1`. Empty reads are valid and return `-1`. Values are nonnegative so the empty-read result lies outside the accepted value domain.

Every operation result contributes `(operation_index + 1) * (result + 1,000,000)` to the checksum. Remaining items contribute their FIFO contents with weights starting at `operation_count + 1`. The buffer uses a fixed 256-element array and modulo indices; all operations take `O(1)` time, with `O(1)` auxiliary space.

The Java source constructs a buffer with a runtime positive capacity, overwrites the oldest item on full, returns `null` from an empty read, and exposes `isEmpty`, `isFull`, `put`, and `get`. The trace bounds capacity and normalizes the empty result to `-1`. Java `put`'s boolean is preserved as its “was empty” return.

## Relationship to queue and ring-buffer candidates

This contract differs from the existing [`queue`](../../q/queue/README.md) benchmark and Zig `ring_buffer`: those reject writes when full. Zig's strict indexed access, peeks, availability count, and clear operation are outside the shared queue trace; its fail-fast FIFO core maps to `queue`. This Java overwrite-oldest behavior remains a separate benchmark.

## Implementations

The nine ports are in `c/c/circular_buffer.c`, `c3/c/circular_buffer.c3`, `cpp/c/circular_buffer.cpp`, `elisa/c/circular_buffer.elisa`, `nim/c/circular_buffer.nim`, `odin/c/circular_buffer.odin`, `rust/c/circular_buffer.rs`, `v/c/circular_buffer.v`, and `zig/c/circular_buffer.zig`.

## Pinned source

- [Java `CircularBuffer.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/buffers/CircularBuffer.java)

Build with the `i64_array_scalar` ABI family and record with `benchmarks/run_i64_array_scalar.py`.

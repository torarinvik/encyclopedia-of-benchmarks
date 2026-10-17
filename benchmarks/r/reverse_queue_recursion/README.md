# Reverse queue recursively

The pinned Java method reverses a queue in place by polling its front element, recursively reversing the remaining queue, and appending the saved element. Null and empty queues are no-ops.

## Contract

The `i64_array_bytes_output` ABI packs a bounded byte queue as `[n, byte_values...]`. The count is 0–32, each value is an unsigned byte (0–255), and the array length must be exactly `n + 1`. The source's null queue is represented by a null input pointer with declared length 1; it produces an empty result (0 bytes). A nonnull packed empty queue `[0]` has the same no-op result. A null ABI input with any other declared length, malformed packed input, or out-of-range value returns -1.

The returned bytes are the final queue elements in front-to-rear order after reversal, with one raw byte per queue item. The bounded recursion reaches at most 32 queue elements. Invalid input is handled before output storage is checked. A null output pointer returns -2, including for an empty result; a nonnull zero-capacity output succeeds for an empty result, and a short capacity returns -2 without writes.

[`workload.json`](workload.json) covers null and empty queues, singleton and duplicate values, embedded zero bytes, full reversal, the maximum queue length, short/null output, malformed framing, and out-of-byte-range values.

## Pinned source

- Java [`ReverseQueueRecursion.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/queues/ReverseQueueRecursion.java) at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`, symbol `ReverseQueueRecursion.reverseQueue`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/reverse_queue_recursion.c`](../../../c/r/reverse_queue_recursion.c) |
| C3 | [`c3/r/reverse_queue_recursion.c3`](../../../c3/r/reverse_queue_recursion.c3) |
| C++ | [`cpp/r/reverse_queue_recursion.cpp`](../../../cpp/r/reverse_queue_recursion.cpp) |
| Elisa | [`elisa/r/reverse_queue_recursion.elisa`](../../../elisa/r/reverse_queue_recursion.elisa) |
| Nim | [`nim/r/reverse_queue_recursion.nim`](../../../nim/r/reverse_queue_recursion.nim) |
| Odin | [`odin/r/reverse_queue_recursion.odin`](../../../odin/r/reverse_queue_recursion.odin) |
| Rust | [`rust/r/reverse_queue_recursion.rs`](../../../rust/r/reverse_queue_recursion.rs) |
| V | [`v/r/reverse_queue_recursion.v`](../../../v/r/reverse_queue_recursion.v) |
| Zig | [`zig/r/reverse_queue_recursion.zig`](../../../zig/r/reverse_queue_recursion.zig) |

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm reverse_queue_recursion --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm reverse_queue_recursion
```

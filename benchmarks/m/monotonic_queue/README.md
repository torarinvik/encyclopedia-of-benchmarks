# Monotonic queue

This package ports the pinned Python [`monotonic_queue`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/queues/monotonic_queue.py) sliding-window maximum algorithm. It maintains a deque of candidate indices and removes older equal maxima with a `>=` comparison, matching the source.

## Contract

Input is the signed-i64 array `[n, window, value_0, ..., value_(n-1)]` with exact length `n+2`. `n` is in `1..4096`, `window` is in `1..n`, and each value is a signed i32. Invalid lengths, bounds, or values return `-1`.

The output is the sequence of maximum values for every contiguous window, in input order. The scalar result is the low 63 bits of FNV-1a-64 over the output values, each encoded as a signed-i32 bit pattern in little-endian byte order. The source removes earlier equal values from the deque; this does not change the observable maxima sequence.

The independent oracle computes each window maximum directly, without the monotonic deque. [`workload.json`](workload.json) covers window sizes 1 and n, increasing/decreasing inputs, equal values, i32 boundaries, malformed encodings, and the maximum input length. The oracle is [`monotonic_queue_oracle.py`](../../monotonic_queue_oracle.py).

| Language | Port |
|---|---|
| C | [`c/m/monotonic_queue.c`](../../../c/m/monotonic_queue.c) |
| C3 | [`c3/m/monotonic_queue.c3`](../../../c3/m/monotonic_queue.c3) |
| C++ | [`cpp/m/monotonic_queue.cpp`](../../../cpp/m/monotonic_queue.cpp) |
| Elisa | [`elisa/m/monotonic_queue.elisa`](../../../elisa/m/monotonic_queue.elisa) |
| Nim | [`nim/m/monotonic_queue.nim`](../../../nim/m/monotonic_queue.nim) |
| Odin | [`odin/m/monotonic_queue.odin`](../../../odin/m/monotonic_queue.odin) |
| Rust | [`rust/m/monotonic_queue.rs`](../../../rust/m/monotonic_queue.rs) |
| V | [`v/m/monotonic_queue.v`](../../../v/m/monotonic_queue.v) |
| Zig | [`zig/m/monotonic_queue.zig`](../../../zig/m/monotonic_queue.zig) |

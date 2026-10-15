# Exponential moving average

Produce an exponential moving average for each price in an input series. This package maps the pinned Python and Rust implementations, whose warm-up behavior agrees for `window_size >= 2`. The Java implementation is a separate streaming-state algorithm and is intentionally not folded into this contract.

Pinned sources:

- Python: [TheAlgorithms/Python `exponential_moving_average.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/financial/exponential_moving_average.py)
- Rust: [TheAlgorithms/Rust `exponential_moving_average.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a4c939ec5163648458a8c2b46fd4c/src/financial/exponential_moving_average.rs)

## Contract

Input is packed signed 64-bit slots `[window_size, count, prices...]`. The window is 2 through 32, count is 1 through 256, and each integer price is -1,000,000 through 1,000,000. This finite integer subset keeps intermediate values bounded and makes the Python warm-up average and Rust `f64::midpoint` agree exactly.

For the first value, the EMA equals that price. For indices `1` through `window_size` inclusive, the algorithm repeatedly averages the previous value with the new price: `(previous + price) * 0.5`. After that, it uses `alpha = 2 / (1 + window_size)` and computes `(alpha * price) + ((1 - alpha) * previous)`. This preserves the source's warm-up loop, including its extra midpoint step at index `window_size`.

Output is `count` little-endian IEEE-754 binary64 values. The function returns the output byte count (`8 * count`), `-1` for malformed or out-of-domain input, and `-2` for insufficient or null output capacity.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/exponential_moving_average.c`](../../../c/f/exponential_moving_average.c) |
| C3 | [`c3/f/exponential_moving_average.c3`](../../../c3/f/exponential_moving_average.c3) |
| C++ | [`cpp/f/exponential_moving_average.cpp`](../../../cpp/f/exponential_moving_average.cpp) |
| Elisa | [`elisa/f/exponential_moving_average.elisa`](../../../elisa/f/exponential_moving_average.elisa) |
| Nim | [`nim/f/exponential_moving_average.nim`](../../../nim/f/exponential_moving_average.nim) |
| Odin | [`odin/f/exponential_moving_average.odin`](../../../odin/f/exponential_moving_average.odin) |
| Rust | [`rust/f/exponential_moving_average.rs`](../../../rust/f/exponential_moving_average.rs) |
| V | [`v/f/exponential_moving_average.v`](../../../v/f/exponential_moving_average.v) |
| Zig | [`zig/f/exponential_moving_average.zig`](../../../zig/f/exponential_moving_average.zig) |

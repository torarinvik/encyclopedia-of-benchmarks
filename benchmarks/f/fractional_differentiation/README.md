# Fractional Differentiation

The pinned Python source computes fixed-window fractional differentiation using binomial weights. Its public routine returns a full sequence whose first `window_size` entries are NaN. This benchmark measures the final fully defined output point so every language can use the existing scalar binary64 ABI.

## Contract

Input is `[degree_millionths, window_size, series_milli...]`. The degree is in `[0, 1]` scaled by one million. Window size is 1 to 8, and the series contains from `window_size + 1` to 16 signed values scaled by 1,000 and bounded to `[-1000, 1000]`. The result is the source weighted sum at the final series position, using `w0=1` and `wk=-w(k-1)*(d-k+1)/k`. Invalid input returns `-1e300`.

The oracle is [fractional_differentiation_oracle.py](../../fractional_differentiation_oracle.py); bounded examples and malformed inputs are in [workload.json](workload.json).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/f/fractional_differentiation.c](../../../c/f/fractional_differentiation.c) |
| C3 | [c3/f/fractional_differentiation.c3](../../../c3/f/fractional_differentiation.c3) |
| C++ | [cpp/f/fractional_differentiation.cpp](../../../cpp/f/fractional_differentiation.cpp) |
| Elisa | [elisa/f/fractional_differentiation.elisa](../../../elisa/f/fractional_differentiation.elisa) |
| Nim | [nim/f/fractional_differentiation.nim](../../../nim/f/fractional_differentiation.nim) |
| Odin | [odin/f/fractional_differentiation.odin](../../../odin/f/fractional_differentiation.odin) |
| Rust | [rust/f/fractional_differentiation.rs](../../../rust/f/fractional_differentiation.rs) |
| V | [v/f/fractional_differentiation.v](../../../v/f/fractional_differentiation.v) |
| Zig | [zig/f/fractional_differentiation.zig](../../../zig/f/fractional_differentiation.zig) |

## Pinned source

[TheAlgorithms/Python `fractional_differentiation.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/financial/fractional_differentiation.py)

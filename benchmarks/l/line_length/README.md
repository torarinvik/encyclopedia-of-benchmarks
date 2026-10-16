# Line length

Approximate the arc length of a sampled curve by summing the distances between successive points. The pinned Python and Julia functions accept a callback; this benchmark fixes that callback to the `sin(10*x)` function used in the Python demo so the computation fits the shared three-value ABI.

## Contract

- The `float64_triple` ABI receives `[x_start, x_end, steps]` as binary64 values. Require `-10 <= x_start <= x_end <= 10` and an integer `steps` value from 1 through 10,000. Invalid inputs return `-1e300`.
- Start from `(x_start, sin(10*x_start))`. On each step compute `x2 = (x_end - x_start) / steps + x1`, evaluate `sin(10*x2)`, add the Euclidean distance from the previous point, and then update the previous point. The repeated addition to `x1` preserves the source's accumulation order.
- Return the accumulated binary64 length. The workload comparison uses a relative input-scaled tolerance of `1e-10` to allow for small differences among standard math libraries.

## Source

The pinned [Python `line_length.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/line_length.py) and [Julia `line_length.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/line_length.jl) implement the same repeated-step polyline sum. The Python demo supplies `f(x) = sin(10*x)`; fixing that callback is the only function-specific normalization.

## Workload

[`workload.json`](workload.json) covers one and many subdivisions, the demo interval, a zero-width interval, varied endpoints, invalid ordering, fractional or out-of-range step counts, and endpoint bounds.

Verify with `python3 benchmarks/verify_line_length.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/l/line_length.c`](../../../c/l/line_length.c) |
| C3 | [`c3/l/line_length.c3`](../../../c3/l/line_length.c3) |
| C++ | [`cpp/l/line_length.cpp`](../../../cpp/l/line_length.cpp) |
| Elisa | [`elisa/l/line_length.elisa`](../../../elisa/l/line_length.elisa) |
| Nim | [`nim/l/line_length.nim`](../../../nim/l/line_length.nim) |
| Odin | [`odin/l/line_length.odin`](../../../odin/l/line_length.odin) |
| Rust | [`rust/l/line_length.rs`](../../../rust/l/line_length.rs) |
| V | [`v/l/line_length.v`](../../../v/l/line_length.v) |
| Zig | [`zig/l/line_length.zig`](../../../zig/l/line_length.zig) |

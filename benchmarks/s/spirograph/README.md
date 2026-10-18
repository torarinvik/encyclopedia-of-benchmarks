# Spirograph coordinates

This benchmark generates sampled coordinates for the pinned TheAlgorithms C and C++ spirograph routines. It measures the numeric point calculation only; graphics, animation, file output, and the C++ demo's duplicated-x CSV field are outside the operation.

## Contract

Input is `[n, l, k, rot]`. `n` is an exact integer from 1 through 32, `l` is finite and in `[0, 1]`, `k` is finite and in `[0.25, 0.75]`, and `rot` is finite and in `[0, 10]`. The input must contain exactly four float64 values. The maximum parseable input length is five, allowing one extra-value framing probe. The bounds keep output within the 64-element float64 workspace and keep the generated phase well-conditioned for cross-language trigonometric comparisons.

Set `dt = rot * 2π / n` and `k1 = 1 - k`. For each index `i` from 0 through `n - 1`, define `t = i * dt` and emit the interleaved pair

```text
x = k1*cos(t) + l*k*cos(k1*t/k)
y = k1*sin(t) - l*k*sin(k1*t/k)
```

The outer radius scale is one. The output contains exactly `2*n` float64 values in `[x0, y0, x1, y1, ...]` order. Compare coordinates with absolute tolerance `1e-10` and relative tolerance `0`. The pinned C implementation starts `t` at zero and increments it by `dt` after each point; both pinned C++ implementations calculate `i*dt` directly. The tolerance covers their small floating-point angle-rounding difference and cross-language math-library variation.

Malformed input, unsupported values, or a nonfinite coordinate returns `-1` before output-buffer checks. A null output pointer or capacity below `2*n` returns `-2` after input validation. Error returns write no output values. A valid call returns `2*n`.

[`workload.json`](workload.json) records the input/output and ABI fixtures. The independent oracle is [`benchmarks/spirograph_oracle.py`](../../spirograph_oracle.py).

## Pinned sources

- C [`spirograph.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/graphics/spirograph.c) uses two preallocated coordinate arrays and advances `t` cumulatively.
- C++ [`spirograph.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graphics/spirograph.cpp) and C++-1 [`spirograph.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/graphics/spirograph.cpp) use an array of coordinate pairs and calculate `t` directly from the point index. Their optional OpenMP loop directive is not required by this benchmark.

## Language ports

| Language | Port |
|---|---|
| C | [`c/s/spirograph.c`](../../../c/s/spirograph.c) |
| C3 | [`c3/s/spirograph.c3`](../../../c3/s/spirograph.c3) |
| C++ | [`cpp/s/spirograph.cpp`](../../../cpp/s/spirograph.cpp) |
| Elisa | [`elisa/s/spirograph.elisa`](../../../elisa/s/spirograph.elisa) |
| Nim | [`nim/s/spirograph.nim`](../../../nim/s/spirograph.nim) |
| Odin | [`odin/s/spirograph.odin`](../../../odin/s/spirograph.odin) |
| Rust | [`rust/s/spirograph.rs`](../../../rust/s/spirograph.rs) |
| V | [`v/s/spirograph.v`](../../../v/s/spirograph.v) |
| Zig | [`zig/s/spirograph.zig`](../../../zig/s/spirograph.zig) |

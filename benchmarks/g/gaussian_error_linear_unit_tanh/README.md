# Gaussian error linear unit (tanh approximation)

Benchmark the pinned Rust implementation's tanh-based GELU approximation. This is distinct from the Python sigmoid approximation in [`gaussian_error_linear_unit`](../gaussian_error_linear_unit/README.md).

## Contract

- The `float64_unary` ABI accepts one finite binary64 value `x` in `[-100, 100]`.
- Preserve the Rust expression and operation order: `x * 0.5 * (1 + tanh(pow(2/PI, 0.5) * (x + 0.044715 * pow(x, 3))))`, where its local tanh helper is `2 / (1 + pow(E, -2z)) - 1`.
- Inputs outside the finite bounded domain return `-1e300`. Compare outputs with relative tolerance `1e-12` and absolute tolerance `1e-15`.

The pinned Rust source evaluates powers through `powf`; the ports preserve that expression order. Its `tanh` helper uses the exponential identity rather than a platform tanh call. The finite input bound keeps the cubic term and its intermediate values bounded; the exponential identity approaches ±1 at the domain extremes.

[`workload.json`](workload.json) covers negative and positive inputs, zero, the Rust source examples, both bounds, and invalid finite values.

| Language | Source |
| --- | --- |
| C | [`c/g/gaussian_error_linear_unit_tanh.c`](../../../c/g/gaussian_error_linear_unit_tanh.c) |
| C3 | [`c3/g/gaussian_error_linear_unit_tanh.c3`](../../../c3/g/gaussian_error_linear_unit_tanh.c3) |
| C++ | [`cpp/g/gaussian_error_linear_unit_tanh.cpp`](../../../cpp/g/gaussian_error_linear_unit_tanh.cpp) |
| Elisa | [`elisa/g/gaussian_error_linear_unit_tanh.elisa`](../../../elisa/g/gaussian_error_linear_unit_tanh.elisa) |
| Nim | [`nim/g/gaussian_error_linear_unit_tanh.nim`](../../../nim/g/gaussian_error_linear_unit_tanh.nim) |
| Odin | [`odin/g/gaussian_error_linear_unit_tanh.odin`](../../../odin/g/gaussian_error_linear_unit_tanh.odin) |
| Rust | [`rust/g/gaussian_error_linear_unit_tanh.rs`](../../../rust/g/gaussian_error_linear_unit_tanh.rs) |
| V | [`v/g/gaussian_error_linear_unit_tanh.v`](../../../v/g/gaussian_error_linear_unit_tanh.v) |
| Zig | [`zig/g/gaussian_error_linear_unit_tanh.zig`](../../../zig/g/gaussian_error_linear_unit_tanh.zig) |

Pinned source: [TheAlgorithms/Rust `gaussian_error_linear_unit.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/gaussian_error_linear_unit.rs).

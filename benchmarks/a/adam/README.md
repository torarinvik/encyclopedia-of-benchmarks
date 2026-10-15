# Adam parameter update trace

## Contract

The pinned Rust source initializes first and second moments to zero, then updates both moments for every parameter on each call to `step`. It applies bias correction at the current optimizer step, divides by `sqrt(v_hat) + epsilon`, and subtracts the decoupled weight decay term. The source labels nonzero weight decay as the AdamW variant.

A benchmark call supplies an initial parameter vector and a row-major gradient vector for each step. The output from one step becomes the parameter input for the next step, while moment state continues across the trace. The signed-i64 input layout is `[step_count, parameter_count, learning_rate_scaled, beta1_scaled, beta2_scaled, epsilon_scaled, weight_decay_scaled, initial parameters..., then step_count * parameter_count gradients...]`. All floating-point values use input scale 1,000,000,000. Step count is 1 through 256 and parameter count is 1 through 16. Learning rate is `[1e-9, 1]`; each beta is `[0, 0.999999999]`; epsilon is `[1e-9, 0.01]`; weight decay is `[0, 0.1]`; initial parameters are `[-1e6, 1e6]`; gradients are `[-1000, 1000]`. Invalid input returns `-1`.

Implementations use binary64 and the same 80-iteration Newton square-root routine. They update beta powers by repeated multiplication, which computes the source's `beta^t` bias-correction factors without relying on language-specific power functions. The function returns the number of parameter values emitted and writes each updated parameter as signed-i64 little-endian fixed-point at scale 1,000,000, in step-major order. An insufficient output buffer returns `-2`.

## Workload and ABI

[`workload.json`](workload.json) covers the pinned source's default single-step vector, its nonzero-weight-decay behavior, a custom multi-step vector trace, zero gradients, and the maximum step count. The trace adapter preserves the source optimizer state while using the shared `i64_array_bytes_output` ABI.

Build with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm adam --language rust --with-checker
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/a/adam/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/adam.c`](../../../c/a/adam.c) |
| C3 | [`c3/a/adam.c3`](../../../c3/a/adam.c3) |
| C++ | [`cpp/a/adam.cpp`](../../../cpp/a/adam.cpp) |
| Elisa | [`elisa/a/adam.elisa`](../../../elisa/a/adam.elisa) |
| Nim | [`nim/a/adam.nim`](../../../nim/a/adam.nim) |
| Odin | [`odin/a/adam.odin`](../../../odin/a/adam.odin) |
| Rust | [`rust/a/adam.rs`](../../../rust/a/adam.rs) |
| V | [`v/a/adam.v`](../../../v/a/adam.v) |
| Zig | [`zig/a/adam.zig`](../../../zig/a/adam.zig) |

## Reviewed source

- [Rust `adam.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/machine_learning/optimization/adam.rs)

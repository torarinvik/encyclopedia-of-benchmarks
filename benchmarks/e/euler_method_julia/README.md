# Julia Euler method variant

This is a separate benchmark for the pinned [TheAlgorithms/Julia `euler_method`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/euler_method.jl). The Julia function returns a state vector and a time vector. Its length is `floor((span_end - span_start) / h)`, its first state is the supplied initial value, its first time is zero, and its loop applies only `length - 1` Euler updates.

## Contract

Input is `[initial_state_integer, step_count, step_denominator_power]`. The initial state is in `[-8,8]`, the count is 1..16, and the step denominator power is 1..4. The benchmark fixes the span to `[0, step_count * h]`, where `h = 2^(-step_denominator_power)`, and fixes the derivative to `f(state,time)=state+time`. Thus the source's floor expression produces exactly `step_count` output points.

Output is `state_0..state_(n-1)` followed by `time_0..time_(n-1)`, all as little-endian binary64 values. The return value is the byte count, `16*n`. Invalid input returns `-1`; insufficient capacity returns `-2` without writing.

[`workload.json`](workload.json) covers one point, several step sizes, the maximum step count, invalid bounds/length, and insufficient capacity.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm euler_method_julia --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/e/euler_method_julia/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/euler_method_julia.c`](../../../c/e/euler_method_julia.c) |
| C3 | [`c3/e/euler_method_julia.c3`](../../../c3/e/euler_method_julia.c3) |
| C++ | [`cpp/e/euler_method_julia.cpp`](../../../cpp/e/euler_method_julia.cpp) |
| Elisa | [`elisa/e/euler_method_julia.elisa`](../../../elisa/e/euler_method_julia.elisa) |
| Nim | [`nim/e/euler_method_julia.nim`](../../../nim/e/euler_method_julia.nim) |
| Odin | [`odin/e/euler_method_julia.odin`](../../../odin/e/euler_method_julia.odin) |
| Rust | [`rust/e/euler_method_julia.rs`](../../../rust/e/euler_method_julia.rs) |
| V | [`v/e/euler_method_julia.v`](../../../v/e/euler_method_julia.v) |
| Zig | [`zig/e/euler_method_julia.zig`](../../../zig/e/euler_method_julia.zig) |

## Pinned source

- Julia [`euler_method.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/euler_method.jl)

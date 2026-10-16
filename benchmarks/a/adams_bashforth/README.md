# Adams–Bashforth

This benchmark ports the pinned Python Adams–Bashforth solver for one bounded ODE workload, `y' = x + y`. It exercises the source's second through fifth order methods over a fixed, equally spaced grid.

## Contract

- Use the `i64_array_bytes_output` ABI. Pack input as `[order, forecast_step_count, y0_scaled, ..., y(order-1)_scaled]`.
- `order` is 2, 3, 4, or 5. `forecast_step_count` is 1 through 4. Exactly `order` initial y values must follow, each in `-100000..=100000`; divide each by 100000 to obtain the initial value.
- The initial x values are `0, 0.25, ..., (order-1)*0.25`, the step size is `0.25`, and `x_final = (order-1+forecast_step_count)*0.25`. The right-hand side is `f(x,y)=x+y`.
- Invalid packed inputs return `-1`; insufficient output capacity returns `-2`.
- Return every initial and computed y value as comma-separated signed decimal integers, where each integer is truncation toward zero of `y * 1,000,000`. The return value is the number of output bytes. This encoding makes the complete numerical sequence observable through the existing byte-output ABI while keeping the integration state in binary64.

## Source behavior and limits

The Python source accepts an arbitrary callable `f(x,y)`, initial x/y lists, a positive step, a final x value, and separate `step_2` through `step_5` methods. This package fixes the RHS and x grid to the source's documented `f(x,y)=x+y` example and bounds the number of forecast steps so every port uses the same finite input and output shape.

The source computes `n = int((x_final - x_last_initial) / step_size)`. Its second- and fourth-order loops perform `n` updates, while its third- and fifth-order loops perform `n+1` updates. The ports preserve this behavior, so third- and fifth-order outputs include one value beyond `x_final` under this workload's exact grid.

The pinned fifth-order update uses coefficient `-2616` for the third newest derivative term. The classical Adams–Bashforth fifth-order formula uses `+2616`; these ports preserve the pinned source's negative sign rather than silently correcting it. Output quantization applies only when encoding results; subsequent integration steps use the full binary64 values.

## Workload

[`workload.json`](workload.json) covers all four orders, short and maximum forecast lengths, the source examples' initial-value patterns, and malformed bounds and shapes. Workload measurements use the shared `i64_array_bytes_output` runner.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/adams_bashforth.c`](../../../c/a/adams_bashforth.c) |
| C3 | [`c3/a/adams_bashforth.c3`](../../../c3/a/adams_bashforth.c3) |
| C++ | [`cpp/a/adams_bashforth.cpp`](../../../cpp/a/adams_bashforth.cpp) |
| Elisa | [`elisa/a/adams_bashforth.elisa`](../../../elisa/a/adams_bashforth.elisa) |
| Nim | [`nim/a/adams_bashforth.nim`](../../../nim/a/adams_bashforth.nim) |
| Odin | [`odin/a/adams_bashforth.odin`](../../../odin/a/adams_bashforth.odin) |
| Rust | [`rust/a/adams_bashforth.rs`](../../../rust/a/adams_bashforth.rs) |
| V | [`v/a/adams_bashforth.v`](../../../v/a/adams_bashforth.v) |
| Zig | [`zig/a/adams_bashforth.zig`](../../../zig/a/adams_bashforth.zig) |

## Upstream source

- [TheAlgorithms/Python `adams_bashforth.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/numerical_analysis/adams_bashforth.py)

Build with the `i64_array_bytes_output` ABI family and record with `benchmarks/run_i64_array_bytes_output.py`. The independent cross-language verifier is:

```sh
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm adams_bashforth --languages rust
```

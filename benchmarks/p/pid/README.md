# PID Controller

This benchmark adapts the pinned C `pid_step` controller to a bounded sequence of error samples. Each call starts with a fresh controller state, then emits the result after every step.

## Contract

- ABI: `float64_slice_io`.
- Input is `[kP, kI, kD, dt, error_0, ...]`, with 5 through 64 values (1 through 60 errors).
- Gains and errors must be finite and in [-1, 1]. `dt` must be exactly 0 or in [0.01, 1]. These bounds are checked on the input float64 values before conversion to the source's float32 `float`.
- Convert accepted parameters and errors to float32. Start `integral` and `lastError` at zero for each call. For every error, preserve the source order and float32 rounding: compute `p = error * kP`; update `integral += error * dt * kI` left to right; compute `d = 0` when `dt == 0`, otherwise `((error - lastError) / dt) * kD`; update `lastError`; then return `p + integral + d` left to right.
- Emit each step result widened exactly to float64. The result is the number of error samples (at most 60).
- Invalid input returns -1. A null output or capacity smaller than the error count returns -2 without writing. Workspace is at most 60 float64 elements.
- Tolerances are zero: the ports and oracle preserve the source's float32 operations before widening each result.
- The C and C++ builds disable floating-point contraction for this algorithm so multiply-add fusion cannot bypass an intermediate float32 rounding point.

When `dt` is zero, only the derivative term is suppressed; the integral update and `lastError` update still occur.

## Workload and oracle

[`workload.json`](workload.json) covers each controller term, combined updates, the zero-`dt` rule, accepted `dt` boundaries, parameter and error limits, invalid inputs, and the maximum error sequence. The independent oracle is [`pid_oracle.py`](../../pid_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/pid.c`](../../../c/p/pid.c) |
| C3 | [`c3/p/pid.c3`](../../../c3/p/pid.c3) |
| C++ | [`cpp/p/pid.cpp`](../../../cpp/p/pid.cpp) |
| Elisa | [`elisa/p/pid.elisa`](../../../elisa/p/pid.elisa) |
| Nim | [`nim/p/pid.nim`](../../../nim/p/pid.nim) |
| Odin | [`odin/p/pid.odin`](../../../odin/p/pid.odin) |
| Rust | [`rust/p/pid.rs`](../../../rust/p/pid.rs) |
| V | [`v/p/pid.v`](../../../v/p/pid.v) |
| Zig | [`zig/p/pid.zig`](../../../zig/p/pid.zig) |

## Pinned source

The source is TheAlgorithms/C [`pid.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/misc/pid.c) at commit `e5dad3fa8def3726ec850ca66a7f51521f8ad393`, symbol `pid_step`.

## Build and record

```sh
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm pid --language rust
python3 benchmarks/run_float64_slice_io.py --algorithm pid
python3 benchmarks/verify_float64_slice_io.py --algorithm pid
```

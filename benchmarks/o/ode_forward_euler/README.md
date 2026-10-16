# Forward Euler oscillator

## Contract

Integrate the pinned two-state harmonic oscillator `u' = v`, `v' = -u` for a fixed number of forward-Euler steps. The packed input is `[steps, dt_quarters, u0, v0]`: `steps` is 1..16, `dt_quarters` is 1..4 and represents a step size of `dt_quarters / 4`, and each initial state is an integer in -10..10. Each update is simultaneous from the prior state:

```text
next_u = u + dt * v
next_v = v - dt * u
```

The output is two IEEE-754 binary64 values `[u, v]`, each encoded as eight little-endian bytes, for 16 bytes total. Invalid inputs return `-1` with no output. Insufficient output capacity returns `-2`. The bounded quarter-step inputs and state range keep every update finite; the fixed count avoids depending on the upstream driver's floating-point endpoint condition.

The source defines `omega = 1` and starts its CLI demonstration at `(u, v) = (1, 0)`. This contract exposes the initial state and step count so the recurrence can be measured on varied inputs while preserving the same oscillator and update order.

## Workload

Cases and expected output bytes are in [`workload.json`](workload.json). The package uses the `i64_array_bytes_output` ABI; static verification is handled by the shared byte-output verifier.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/o/ode_forward_euler.c`](../../../c/o/ode_forward_euler.c) |
| C3 | [`c3/o/ode_forward_euler.c3`](../../../c3/o/ode_forward_euler.c3) |
| C++ | [`cpp/o/ode_forward_euler.cpp`](../../../cpp/o/ode_forward_euler.cpp) |
| Elisa | [`elisa/o/ode_forward_euler.elisa`](../../../elisa/o/ode_forward_euler.elisa) |
| Nim | [`nim/o/ode_forward_euler.nim`](../../../nim/o/ode_forward_euler.nim) |
| Odin | [`odin/o/ode_forward_euler.odin`](../../../odin/o/ode_forward_euler.odin) |
| Rust | [`rust/o/ode_forward_euler.rs`](../../../rust/o/ode_forward_euler.rs) |
| V | [`v/o/ode_forward_euler.v`](../../../v/o/ode_forward_euler.v) |
| Zig | [`zig/o/ode_forward_euler.zig`](../../../zig/o/ode_forward_euler.zig) |

## TheAlgorithms references

- [C `ode_forward_euler.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/numerical_methods/ode_forward_euler.c)
- [C++ `ode_forward_euler.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/ode_forward_euler.cpp)
- [C++-1 `ode_forward_euler.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/numerical_methods/ode_forward_euler.cpp)

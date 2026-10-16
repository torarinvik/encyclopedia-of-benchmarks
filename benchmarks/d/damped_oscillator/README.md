# Damped oscillator Euler step

This package benchmarks the pinned Java `DampedOscillator.stepEuler` method for one mass-spring-damper integration step. The class also contains an analytical displacement method; this workload measures the explicit Euler state update only.

## Contract

- Input uses the `i64_array_bytes_output` ABI packed as `[omega0_q, gamma_q, x_q, v_q, dt_q]`. Each quantity is its physical value multiplied by 1,024, so all valid inputs decode exactly as binary64 dyadic fractions.
- `omega0_q` is `1..=1024`, `gamma_q` is `0..=1024`, `x_q` and `v_q` are `-1024..=1024`, and `dt_q` is `1..=1024`. These encode positive natural frequency, nonnegative damping, bounded state, and positive time step.
- Preserve source order: `acceleration = -2*gamma*v - omega0*omega0*x`, `x_next = x + dt*v`, then `v_next = v + dt*acceleration`. Return `[x_next, v_next]` as two little-endian IEEE-754 binary64 values. Success returns 16 bytes.
- The power-of-two input scale makes every bounded operation an exactly representable binary64 value. Invalid length or domain values return `-1`; a null or undersized output buffer returns `-2`.

The positive-frequency and nonnegative-damping bounds match the constructor checks; positive `dt` matches `stepEuler`. The state is a two-value vector `[x,v]`. The analytical displacement method is outside this benchmark contract.

## Pinned source

[TheAlgorithms/Java `DampedOscillator.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/physics/DampedOscillator.java) updates the state with explicit Euler and returns a two-element array. [`workload.json`](workload.json) covers undamped and damped steps, positive and negative velocity, rest state, source bounds, malformed input, and insufficient capacity.

## Build, record, and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm damped_oscillator --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/d/damped_oscillator/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm damped_oscillator --language rust
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/d/damped_oscillator.c`](../../../c/d/damped_oscillator.c) |
| C3 | [`c3/d/damped_oscillator.c3`](../../../c3/d/damped_oscillator.c3) |
| C++ | [`cpp/d/damped_oscillator.cpp`](../../../cpp/d/damped_oscillator.cpp) |
| Elisa | [`elisa/d/damped_oscillator.elisa`](../../../elisa/d/damped_oscillator.elisa) |
| Nim | [`nim/d/damped_oscillator.nim`](../../../nim/d/damped_oscillator.nim) |
| Odin | [`odin/d/damped_oscillator.odin`](../../../odin/d/damped_oscillator.odin) |
| Rust | [`rust/d/damped_oscillator.rs`](../../../rust/d/damped_oscillator.rs) |
| V | [`v/d/damped_oscillator.v`](../../../v/d/damped_oscillator.v) |
| Zig | [`zig/d/damped_oscillator.zig`](../../../zig/d/damped_oscillator.zig) |

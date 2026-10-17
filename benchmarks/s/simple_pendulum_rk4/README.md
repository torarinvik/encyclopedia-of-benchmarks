# Simple pendulum RK4

This package benchmarks one `stepRK4` call from the pinned Java
[`SimplePendulumRK4.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/physics/SimplePendulumRK4.java).
The method advances `[theta, omega]` by one classical Runge–Kutta 4 step for
`theta' = omega` and `omega' = -(gravity / length) * sin(theta)`. The four
stages and weighted sums follow the source order. Simulation loops and energy
helpers are outside this contract.

The `float64_slice_io` input is exactly five finite, integer-valued doubles in
micro-units: `[length, gravity, theta, omega, dt]`, with each value divided by
`1e6` before use. The accepted physical ranges are length `0.01..100` metres,
gravity `0.1..20` m/s², theta `-3.141593..3.141593` radians, omega
`-100..100` radians/s, and `0.000001..0.1` seconds. A successful call writes
physical `[theta_next, omega_next]` and returns `2`. Invalid input returns
`-1`; a null or short output buffer returns `-2`. Input validation precedes
output-buffer validation, and errors leave the output untouched.

The workload, independent oracle, and tolerances are in [`workload.json`](workload.json)
and [`simple_pendulum_rk4_oracle.py`](../../simple_pendulum_rk4_oracle.py).

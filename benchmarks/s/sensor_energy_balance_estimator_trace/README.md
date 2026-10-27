# Sensor energy-balance estimator trace

This package profiles the sink-side estimator in Fig. 2 of “Randomized Energy
Balance Algorithms in Sensor Networks,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_323`](https://doi.org/10.1007/978-1-4939-2864-4_323).
It executes a bounded sequence of estimator updates from the source's initial
event-rate vector and observed slice-path masks.

Input is `[N,H,lambda[N],path_mask[H],draw[H*N]]`, where `1<=N,H<=8` and
`S=1,000,000` is the fixed input probability scale. Lambdas are integers in
`[0,S]` and sum exactly to `S`. Every path mask is a nonempty subset of slices
`0..N-1`. Draws are step-major; for horizon `H`, the common exact denominator
is `Q=S*lcm(1,...,H)` and every supplied draw must be in `[0,Q)`.

The estimator initializes `x_tilde_i=lambda_i/S` and `NbrLoop=1`. For each
observation, slices are updated in ascending order using the current loop
counter: `X=1` iff the observed path mask contains the slice, `R=1` iff its
supplied draw is below the current scaled estimate, and
`x_tilde_i += (X-R)/NbrLoop`. Only after all slice updates is `NbrLoop`
incremented. Integer numerators over `Q` preserve each rational update exactly.
Because the source's unconstrained recurrence can leave the Bernoulli
parameter domain on some tapes, this bounded profile accepts only traces for
which every updated estimate remains in `[0,1]`; it rejects an out-of-domain
trace with `-1` rather than clamping or changing the recurrence.

Output is `[Q,final_numerator[N]]` as little-endian i64 values (maximum 72
bytes). Malformed input or a trace leaving the accepted state domain returns
`-1`; null output or insufficient capacity returns `-2` without writing. The
Bernoulli draws are supplied and replayed deterministically. This profile
makes no randomness, convergence, energy-balance, network-lifetime, or
data-routing guarantee and does not model network discovery or station
probability computation.

The primary oracle maintains exact integer numerators with the least-common
multiple denominator. The independent verifier uses rational fractions and
reconstructs the same scale only for serialization.

| Language | Port |
|---|---|
| C | `c/s/sensor_energy_balance_estimator_trace.c` |
| C3 | `c3/s/sensor_energy_balance_estimator_trace.c3` |
| C++ | `cpp/s/sensor_energy_balance_estimator_trace.cpp` |
| Elisa | `elisa/s/sensor_energy_balance_estimator_trace.elisa` |
| Nim | `nim/s/sensor_energy_balance_estimator_trace.nim` |
| Odin | `odin/s/sensor_energy_balance_estimator_trace.odin` |
| Rust | `rust/s/sensor_energy_balance_estimator_trace.rs` |
| V | `v/s/sensor_energy_balance_estimator_trace.v` |
| Zig | `zig/s/sensor_energy_balance_estimator_trace.zig` |

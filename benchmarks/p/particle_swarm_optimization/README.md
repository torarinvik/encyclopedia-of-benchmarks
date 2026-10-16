# Particle Swarm Optimization

This benchmark ports the core recurrence from TheAlgorithms/MATLAB-Octave's polynomial minimization example. The objective is the five-dimensional sphere `sum(x[d] * x[d])`. The fixed swarm has 50 particles, runs for 1,000 iterations, starts positions uniformly in `[-10, 10)`, uses zero initial velocities, starts inertia at 1.0 and multiplies it by 0.99 after each iteration, and uses personal/social acceleration coefficients of 2.0. Particle updates are sequential, so an improved global best is visible to later particles in the same iteration. The source does not clamp positions or velocities.

## Contract

- The `i64_array_bytes_output` input is exactly `[seed]`, with a positive signed 64-bit seed. The stream is xorshift64 with unsigned 64-bit state transitions `x ^= x << 13; x ^= x >> 7; x ^= x << 17`. Each draw uses `(state >> 11) * 2^-53`, producing a shared binary64 value in `[0, 1)`. Seed zero is invalid because it would leave this generator in its zero state.
- Draws follow the source order: 250 initialization values, then for each iteration and particle five personal values followed by five social values. Personal and global bests update immediately when the source's strict `<` comparison succeeds.
- The output is a 1,006-element IEEE-754 binary64 vector: final global-best cost, its five coordinates, then the 1,000 `BestCost` values recorded after each complete iteration. The MATLAB display and plotting calls are omitted. The successful result is the output byte length, 8,048. Invalid inputs return -1; a valid input with a missing or undersized output buffer returns -2.
- Output values are compared with an absolute tolerance of `1e-320` and relative tolerance of `1e-9`. The tiny absolute tolerance keeps near-zero final costs and coordinates meaningful while allowing normal binary64 rounding differences.

## Pinned source

- MATLAB [`code.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/Particle_Swarm_Optimization/Polynomial%20Minimization/code.m)
- Objective [`Parabola.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/Particle_Swarm_Optimization/Polynomial%20Minimization/Parabola.m)

## Workload and build

[`workload.json`](workload.json) contains fixed seeds, malformed seed inputs, a one-byte-short output-capacity case, and complete expected output vectors. [`particle_swarm_optimization_oracle.py`](../../particle_swarm_optimization_oracle.py) defines the deterministic random stream and independently evaluates the recurrence.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm particle_swarm_optimization --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/p/particle_swarm_optimization/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm particle_swarm_optimization
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/particle_swarm_optimization.c`](../../../c/p/particle_swarm_optimization.c) |
| C3 | [`c3/particle_swarm_optimization.c3`](../../../c3/p/particle_swarm_optimization.c3) |
| C++ | [`cpp/particle_swarm_optimization.cpp`](../../../cpp/p/particle_swarm_optimization.cpp) |
| Elisa | [`elisa/particle_swarm_optimization.elisa`](../../../elisa/p/particle_swarm_optimization.elisa) |
| Nim | [`nim/particle_swarm_optimization.nim`](../../../nim/p/particle_swarm_optimization.nim) |
| Odin | [`odin/particle_swarm_optimization.odin`](../../../odin/p/particle_swarm_optimization.odin) |
| Rust | [`rust/particle_swarm_optimization.rs`](../../../rust/p/particle_swarm_optimization.rs) |
| V | [`v/particle_swarm_optimization.v`](../../../v/p/particle_swarm_optimization.v) |
| Zig | [`zig/particle_swarm_optimization.zig`](../../../zig/p/particle_swarm_optimization.zig) |

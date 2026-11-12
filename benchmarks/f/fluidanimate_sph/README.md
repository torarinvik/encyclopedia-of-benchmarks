# PARSEC Fluidanimate SPH (bounded one-step profile)

This package benchmarks one bounded smoothed-particle hydrodynamics update:
density estimation, pressure, and symmetric pressure/viscosity acceleration.
It takes particle state directly and does not reproduce Fluidanimate's full
simulation loop, spatial cell construction, parallel scheduling, or file
format. The ports use direct pair traversal so the work is small, deterministic,
and independent of a scene loader.

## Operation

The input is `[N, rpm_milli, (x_milli, y_milli, z_milli, vx_milli, vy_milli,
vz_milli)*]`. `N` is 1..32, `rpm_milli` is 500..5000, each position coordinate
is in -10000..10000, and each velocity component is in -5000..5000. Positions
and velocities are signed thousandths of their source units. Let
`rpm = rpm_milli / 1000`, `h = 1.695 / rpm`, and `m = 1000 / rpm^3`.

Each particle starts with its self-density term. For each unordered pair with
`r² < h²`, the profile adds the poly6 contribution to both particles:

```text
rho_i = m * 315 / (64*pi*h^9)
        * (h^6 + sum((h^2-r_ij^2)^3 for j != i when r_ij^2 < h^2))
p_i   = 3 * (rho_i - 1000)
```

The pair acceleration uses `d = position_i - position_j`,
`r = sqrt(max(r², 1e-12))`, `q = h-r`, and the pair's symmetric density
normalization:

```text
pressure_coefficient  = 3 * (15 / (pi*h^6)) * 1.5 * m
viscosity_coefficient = 0.4 * (45 / (pi*h^6)) * m
delta_a_i = [d * pressure_coefficient * (q^2/r) * (rho_i+rho_j-2000)
             + (velocity_j-velocity_i) * viscosity_coefficient * q]
            / (rho_i*rho_j)
```

The update adds `delta_a_i` to particle `i` and subtracts it from particle
`j`. Each particle starts with external acceleration `(0, -9.8, 0)`. Output
contains `[rho, p, ax, ay, az]` for every particle in input order, encoded as
little-endian binary64 values. The maximum output is 1280 bytes; each port uses
2560 bytes of fixed internal workspace. Malformed input returns `-1`. Valid
input with a null output or fewer than `40*N` output bytes returns `-2` without
writing output.

## Algorithm distinction and provenance

The local [Water-Spatial profile](../../w/water_spatial/README.md) bins molecules
into cells and evaluates a bounded molecular pair law; [Water-Nsquared](../../s/splash2_water_nsquared/README.md)
uses a related non-SPH interaction in direct all-pairs traversal. Neither
computes poly6 density, SPH pressure, or the viscosity term and symmetric
density-normalized acceleration implemented here. Local particle-filter
benchmarks perform Bayesian weighting/resampling, and N-body profiles use a
different gravity force law and state update.

The [PARSEC characterization paper](https://www.cs.princeton.edu/techreports/2008/811.pdf)
describes Fluidanimate's SPH density, pressure, and viscosity computation.
The [source mirror's serial kernel](https://gem5.googlesource.com/public/gem5-resources/+/refs/heads/develop/src/parsec/disk-image/parsec/parsec-benchmark/pkgs/apps/fluidanimate/src/serial.cpp)
and [constants header](https://gem5.googlesource.com/public/gem5-resources/+/refs/heads/develop/src/parsec/disk-image/parsec/parsec-benchmark/pkgs/apps/fluidanimate/src/fluid.hpp)
provide formula and parameter provenance. This package is a clean-room
mathematical profile; it does not copy PARSEC implementation code or inputs.
The source tree names Intel Corp. in its `COPYRIGHT` file, while the PARSEC
root BSD-3-Clause license does not establish that every application has the
same terms. See [RIGHTS.md](RIGHTS.md) for scope details.

The bounded contract and fixtures are in [workload.json](workload.json).
The [primary direct oracle](../../parsec_fluidanimate_sph_oracle.py) updates
unordered pairs symmetrically. The [independent target-wise oracle](../../parsec_fluidanimate_sph_verifier_oracle.py)
recomputes each particle from its own neighbor traversal. The static package
checker is [verify_workload.py](verify_workload.py).

## Language ports

| Language | Port |
|---|---|
| C | [`c/f/fluidanimate_sph.c`](../../../c/f/fluidanimate_sph.c) |
| C3 | [`c3/f/fluidanimate_sph.c3`](../../../c3/f/fluidanimate_sph.c3) |
| C++ | [`cpp/f/fluidanimate_sph.cpp`](../../../cpp/f/fluidanimate_sph.cpp) |
| Elisa | [`elisa/f/fluidanimate_sph.elisa`](../../../elisa/f/fluidanimate_sph.elisa) |
| Mojo | [`mojo/f/fluidanimate_sph.mojo`](../../../mojo/f/fluidanimate_sph.mojo) |
| Nim | [`nim/f/fluidanimate_sph.nim`](../../../nim/f/fluidanimate_sph.nim) |
| Odin | [`odin/f/fluidanimate_sph.odin`](../../../odin/f/fluidanimate_sph.odin) |
| Rust | [`rust/f/fluidanimate_sph.rs`](../../../rust/f/fluidanimate_sph.rs) |
| V | [`v/f/fluidanimate_sph.v`](../../../v/f/fluidanimate_sph.v) |
| Zig | [`zig/f/fluidanimate_sph.zig`](../../../zig/f/fluidanimate_sph.zig) |

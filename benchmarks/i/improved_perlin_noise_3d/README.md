# Improved 3D Perlin noise

This package implements the classic gradient-noise `noise(x, y, z)` kernel in
the pinned `lac-dcc/Benchmarks` Misc/perlin source. It is distinct from the
existing [`perlin_noise`](../../p/perlin_noise/README.md) package: that package
implements seeded 2D value noise with octave interpolation, while this package
uses a fixed 256-entry permutation, hashed gradient directions, and smooth
trilinear interpolation in three dimensions.

## Contract

- ABI: `float64_triple`, function symbol `improved_perlin_noise_3d`.
- Inputs are three finite binary64 coordinates `[x, y, z]`, each in
  `[-1,000,000, 1,000,000]`. Out-of-range or non-finite values return `-1.0`.
- The implementation uses the pinned 256-value permutation, its repeated
  lookup table, floor-based lattice selection masked to eight bits, the
  quintic fade polynomial, the source's 16-way gradient mapping, and its
  nested interpolation order. Coordinates separated by 256 lattice units
  repeat because the lookup indices wrap at 256.
- The result is the scalar noise value at one coordinate. The upstream
  `main` accumulation loop is excluded; the package measures the reusable
  noise kernel directly. The source loop's inner `z` loop also increments
  `y`, so preserving that demo as the benchmark driver would reproduce its
  loop-variable typo instead of measuring the kernel on a useful bounded set
  of points.
- Comparisons use an input-scaled tolerance of `1e-12` to allow normal
  binary64 evaluation differences while keeping the output scale bounded.

The workload includes fractional and negative coordinates, periodic lookup
coordinates, lattice points, and an out-of-profile input. The independent
oracle preserves the source's arithmetic and interpolation order.

## Pinned source and license

The source is [`perlin.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/perlin/perlin.c) at commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher is
[`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/perlin/info.sh); it compiles `perlin.c` with `-lm` and supplies no run options. The source comment says the algorithm is derived from the Java reference implementation at <http://mrl.nyu.edu/~perlin/noise/>. The pinned file and repository do not provide an explicit license grant, so no license is inferred. The local ports are independently written.

## Workload and ports

See [`workload.json`](workload.json) and the independent
[`improved_perlin_noise_3d_oracle`](../../improved_perlin_noise_3d_oracle.py).

| Language | Implementation |
| --- | --- |
| C | [`c/i/improved_perlin_noise_3d.c`](../../../c/i/improved_perlin_noise_3d.c) |
| C3 | [`c3/i/improved_perlin_noise_3d.c3`](../../../c3/i/improved_perlin_noise_3d.c3) |
| C++ | [`cpp/i/improved_perlin_noise_3d.cpp`](../../../cpp/i/improved_perlin_noise_3d.cpp) |
| Elisa | [`elisa/i/improved_perlin_noise_3d.elisa`](../../../elisa/i/improved_perlin_noise_3d.elisa) |
| Nim | [`nim/i/improved_perlin_noise_3d.nim`](../../../nim/i/improved_perlin_noise_3d.nim) |
| Odin | [`odin/i/improved_perlin_noise_3d.odin`](../../../odin/i/improved_perlin_noise_3d.odin) |
| Rust | [`rust/i/improved_perlin_noise_3d.rs`](../../../rust/i/improved_perlin_noise_3d.rs) |
| V | [`v/i/improved_perlin_noise_3d.v`](../../../v/i/improved_perlin_noise_3d.v) |
| Zig | [`zig/i/improved_perlin_noise_3d.zig`](../../../zig/i/improved_perlin_noise_3d.zig) |

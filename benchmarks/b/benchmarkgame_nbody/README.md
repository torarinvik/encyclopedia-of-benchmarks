# Classic five-body N-body energy

This package ports the classic solar-system workload from [`lac-dcc/Benchmarks/BenchmarkGame/n-body/n-body.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/n-body/n-body.c), contributed upstream by Christoph Bauer. It is distinct from the repository's 2D softened N-body simulation: this profile uses the source's fixed Sun, Jupiter, Saturn, Uranus, and Neptune constants, three-dimensional pairwise Newtonian interactions, and momentum offset.

Input is `[step_count]` with `0 <= step_count <= 1000`. Each step uses `dt=0.01`. The implementation follows the source order: calculate initial momentum and adjust the Sun velocity; compute initial energy; for every time step update both velocities for each unordered pair in ascending body order; then move all bodies; finally calculate energy again. Output is two little-endian binary64 values: initial energy and final energy.

The upstream program defaults to five million steps; this bounded profile caps steps at 1000 so the complete pairwise simulation remains practical. It reports an energy pair, not an official Benchmark Game score. The referenced C source has no explicit license notice; the implementations here are independent ports and the immutable source reference is recorded in `workload.json`.

Invalid step counts or framing return `-1`. A null output pointer or capacity below 16 bytes returns `-2` without writes.

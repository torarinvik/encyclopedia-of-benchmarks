# Rodinia Pathfinder bounded grid dynamic programming

This package ports the source's row-wise minimum-cost path recurrence. The pinned CUDA launcher takes `cols rows pyramid_height`; the bounded ABI keeps that parameter order and accepts an explicit row-major cost grid in place of the source's `srand(9)` / `rand() % 10` input generation.

## Contract

- ABI: `i64_array_scalar`; exported symbol: `rodinia_pathfinder`.
- Input: `[cols, rows, pyramid_height, cell_cost...]`, with exactly `3 + cols*rows` signed 64-bit values. Costs are row-major.
- Bounds: `1 <= cols, rows <= 32`, `1 <= pyramid_height <= 4`, and each cost is in `0..9`.
- Initialize the frontier from row zero. For every later row, each column adds its cell cost to the minimum preceding-row cost at the same column or either in-range neighbor. At the grid edges, only in-range neighbors participate. Process rows in chunks of `pyramid_height`, retaining the same source recurrence at every step.
- Return the minimum accumulated cost in the last-row frontier. This is a scalar projection of the source's final result vector and represents the least-cost top-to-bottom path.
- Invalid input returns `-1`.

The workload uses hand-derived small grids, including one-row and one-column boundaries and multiple chunk heights. The oracle evaluates each endpoint with top-down memoized recursion, independently of the ports' rolling-frontier iteration.

## Source and rights

- Pinned source: [`cuda/pathfinder/pathfinder.cu`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/pathfinder/pathfinder.cu), commit `f30e63663cfb114939a15c7ffc4ae112055ae6a8`.
- The source uses a seeded C PRNG to fill the grid. The package accepts the generated bounded grid explicitly so fixtures and cross-language results are deterministic; it preserves the dynamic-programming recurrence and row-neighbor boundaries.
- Rodinia's full University of Virginia redistribution notice and citation request are in [`LICENSE.txt`](LICENSE.txt).

## Ports and workload

Implementations are in `c/r`, `c3/r`, `cpp/r`, `elisa/r`, `nim/r`, `odin/r`, `rust/r`, `v/r`, and `zig/r`. The independent oracle is [`benchmarks/rodinia_pathfinder_oracle.py`](../../rodinia_pathfinder_oracle.py); fixtures are in [`workload.json`](workload.json).

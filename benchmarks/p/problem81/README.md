# Project Euler Problem 81: Path Sum: Two Ways

## Contract

Given a square matrix, return the minimum sum along a path from its top-left cell to its bottom-right cell when each move goes right or down. The `i64_array_scalar` input is `[dimension, row-major cell values...]`. Dimensions must be 1 through 80, the packed input must contain exactly `1 + dimension²` values, and each cell must be from 0 through 9,999. Invalid inputs return -1.

The ports use one row of dynamic programming costs. Each cell adds its value to the smaller reachable cost from above or the left. This matches the pinned source's recurrence while using O(dimension) auxiliary space.

The pinned source's 5×5 example returns **2427**. Its default 80×80 `matrix.txt` returns **427337**.

## Pinned dataset

[`matrix.txt`](matrix.txt) is copied verbatim from TheAlgorithms/Python at commit `e1a2a8b016001309a73d5fec4818c35cca139795`, path `project_euler/problem_081/matrix.txt`. It contains 80 rows of 80 comma-separated values and has SHA-256 `43dbf3717094eb6b6cd733ab8319aa665c0efa58a4363ded7b1385edd35d4e0d`. The workload includes its flattened values, so compiled ports do not read files or access the network.

See [`DATASET_PROVENANCE.md`](DATASET_PROVENANCE.md) for the pinned source and shape record.

## Workload

[`workload.json`](workload.json) covers a singleton, a 2×2 matrix, the source's 5×5 example, the pinned dataset, malformed dimensions and lengths, and invalid cell values. Each benchmark call evaluates its supplied matrix once.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_081/sol1.py)
- Python [`matrix.txt`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_081/matrix.txt)

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm problem81 --language rust

Run it with:

    python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/p/problem81/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem81.c](../../../c/p/problem81.c) |
| C3 | [c3/p/problem81.c3](../../../c3/p/problem81.c3) |
| C++ | [cpp/p/problem81.cpp](../../../cpp/p/problem81.cpp) |
| Elisa | [elisa/p/problem81.elisa](../../../elisa/p/problem81.elisa) |
| Nim | [nim/p/problem81.nim](../../../nim/p/problem81.nim) |
| Odin | [odin/p/problem81.odin](../../../odin/p/problem81.odin) |
| Rust | [rust/p/problem81.rs](../../../rust/p/problem81.rs) |
| V | [v/p/problem81.v](../../../v/p/problem81.v) |
| Zig | [zig/p/problem81.zig](../../../zig/p/problem81.zig) |

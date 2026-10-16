# Project Euler Problem 107: Minimum Network

## Contract

Given an undirected weighted network, return the total edge weight saved by replacing it with a minimum spanning tree. The `i64_array_scalar` input is `[vertex_count, lower-triangle edge entries...]`, with each undirected edge represented once in row order for rows `i=1..n-1`, columns `j=0..i-1`. A value of -1 means no edge; weights must be 0 through 999. The vertex count must be 1 through 40, and the packed array must contain exactly `1 + n*(n-1)/2` values. Invalid or disconnected networks return -1.

The pinned source reads the lower triangle of a symmetric adjacency matrix, builds the undirected edge set, runs Prim's algorithm from vertex 0, and subtracts the MST weight from the original total. The ports preserve that calculation with an array-based Prim scan.

The source's seven-vertex example has total weight 243 and MST weight 93, so the saving is **150**. The pinned 40-vertex network has total weight 261,832 and returns **259679**.

## Pinned datasets

- [`p107_network.txt`](p107_network.txt) is copied verbatim from TheAlgorithms/Python at commit `e1a2a8b016001309a73d5fec4818c35cca139795`, path `project_euler/problem_107/p107_network.txt`. It is a symmetric 40×40 matrix, SHA-256 `81f6b2c8da3b6f89cb6164b2bdf192a91d445095ef23b39bcfb75f0d4578c1c2`.
- [`test_network.txt`](test_network.txt) is the source's seven-vertex example fixture from the same commit, SHA-256 `44087788c5f12aa0b8767f873c65c269a66016fc379f3737edc1880669f558ad`.

The workload packs the lower triangle directly, so compiled ports do not read files or access the network. See [`DATASET_PROVENANCE.md`](DATASET_PROVENANCE.md) for the pinned paths and shape record.

## Workload

[`workload.json`](workload.json) covers a singleton, connected and disconnected small graphs, the source's seven-vertex example, the full pinned network, malformed dimensions, and invalid edge weights.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_107/sol1.py)
- Python [`p107_network.txt`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_107/p107_network.txt)
- Python [`test_network.txt`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_107/test_network.txt)

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm problem107 --language rust

Run it with:

    python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/p/problem107/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem107.c](../../../c/p/problem107.c) |
| C3 | [c3/p/problem107.c3](../../../c3/p/problem107.c3) |
| C++ | [cpp/p/problem107.cpp](../../../cpp/p/problem107.cpp) |
| Elisa | [elisa/p/problem107.elisa](../../../elisa/p/problem107.elisa) |
| Nim | [nim/p/problem107.nim](../../../nim/p/problem107.nim) |
| Odin | [odin/p/problem107.odin](../../../odin/p/problem107.odin) |
| Rust | [rust/p/problem107.rs](../../../rust/p/problem107.rs) |
| V | [v/p/problem107.v](../../../v/p/problem107.v) |
| Zig | [zig/p/problem107.zig](../../../zig/p/problem107.zig) |

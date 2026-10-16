# Brightness

Classify an RGB color using the fixed labeled samples from the pinned MATLAB-Octave nearest-neighbor example.

## Contract

The `i64_array_scalar` input is exactly three integer channels in red, green, blue order. Each channel must be in the inclusive range 0 through 255. Return the label (`0` or `1`) of the closest training color by Euclidean distance. Invalid lengths or channels return `-1`.

The source updates its nearest sample only when a distance is strictly smaller, so equal-distance ties retain the earliest training row. The ports compare squared Euclidean distances using signed 64-bit integer arithmetic; squaring preserves the distance ordering and the maximum possible sum is 195,075.

## Source semantics

The pinned source contains 11 fixed RGB training rows, each with a binary label. Its distance uses the three RGB channels only. This benchmark keeps those rows and labels in source order while defining malformed input behavior for the shared ABI.

- MATLAB [`brightness.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/machine_learning/Nearest-Neighbor/brightness.m)

## Workload and recording

[`workload.json`](workload.json) includes every training sample, a nearest-distance tie between opposite labels, RGB extremes, grayscale colors, local perturbations, and malformed input. The shared array-scalar verifier also generates grayscale sweeps, a fixed color grid, and deterministic random RGB inputs.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm brightness --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/b/brightness/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms brightness --languages rust
```

| Language | Source |
| --- | --- |
| C | [`c/b/brightness.c`](../../../c/b/brightness.c) |
| C3 | [`c3/b/brightness.c3`](../../../c3/b/brightness.c3) |
| C++ | [`cpp/b/brightness.cpp`](../../../cpp/b/brightness.cpp) |
| Elisa | [`elisa/b/brightness.elisa`](../../../elisa/b/brightness.elisa) |
| Nim | [`nim/b/brightness.nim`](../../../nim/b/brightness.nim) |
| Odin | [`odin/b/brightness.odin`](../../../odin/b/brightness.odin) |
| Rust | [`rust/b/brightness.rs`](../../../rust/b/brightness.rs) |
| V | [`v/b/brightness.v`](../../../v/b/brightness.v) |
| Zig | [`zig/b/brightness.zig`](../../../zig/b/brightness.zig) |

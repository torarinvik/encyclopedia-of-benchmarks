# Sigmoid

Compute the scalar logistic sigmoid `1 / (1 + exp(-x))`.

## Contract

- Input is one binary64 value `x` in `[-20, 20]`; return the sigmoid as binary64.
- Return `-1e300` for non-finite or out-of-domain inputs.
- The source implementations apply the same elementwise formula. This benchmark calls it on one scalar: Python and Rust accept vectors, MATLAB accepts a matrix, and Dart's gain parameter is fixed to `1`.
- The Rust source uses `f32`; its port preserves that precision before converting the result to binary64. The workload uses relative tolerance `1e-7` and absolute tolerance `1e-8` to account for that source precision and platform exponential functions.
- The computation takes `O(1)` time and `O(1)` auxiliary space.

## Sources

- [C# `Sigmoid.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/Sigmoid.cs)
- [Dart `sigmoid.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/sigmoid.dart)
- [MATLAB `Sigmoid.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/machine_learning/Logistic-Regression/Sigmoid.m)
- [Python `sigmoid.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/sigmoid.py)
- [Rust `sigmoid.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/sigmoid.rs)

## Workload and build

[`workload.json`](workload.json) covers zero, positive and negative inputs, the domain endpoints, and out-of-domain values. All nine ports use the `float64_unary` ABI.

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm sigmoid --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/s/sigmoid/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/s/sigmoid.c`](../../../c/s/sigmoid.c) |
| C3 | [`c3/s/sigmoid.c3`](../../../c3/s/sigmoid.c3) |
| C++ | [`cpp/s/sigmoid.cpp`](../../../cpp/s/sigmoid.cpp) |
| Elisa | [`elisa/s/sigmoid.elisa`](../../../elisa/s/sigmoid.elisa) |
| Nim | [`nim/s/sigmoid.nim`](../../../nim/s/sigmoid.nim) |
| Odin | [`odin/s/sigmoid.odin`](../../../odin/s/sigmoid.odin) |
| Rust | [`rust/s/sigmoid.rs`](../../../rust/s/sigmoid.rs) |
| V | [`v/s/sigmoid.v`](../../../v/s/sigmoid.v) |
| Zig | [`zig/s/sigmoid.zig`](../../../zig/s/sigmoid.zig) |

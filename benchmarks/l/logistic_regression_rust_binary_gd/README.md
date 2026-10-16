# Rust Binary Logistic Regression with Summed Gradient Descent

This package ports the pinned Rust trainer, including its separate intercept and raw summed batch gradient.

## Contract

Input is a signed 64-bit array `[sample_count, feature_count, epochs, learning_rate_q1e6, row_major_feature_q1e6..., label_q1e6...]`. There are 1 through 32 samples and 1 through 8 features. Epochs range from 0 through 128. The learning-rate integer is from 1 through 100,000; each feature integer is from -1,000,000 through 1,000,000; each label integer is from 0 through 1,000,000. Features, labels, and learning rate are divided by 1,000,000. The array length must be exactly `4 + sample_count * feature_count + sample_count`.

The parameter vector starts with zero bias followed by zero feature weights. Each epoch computes `p = 1 / (1 + exp(-z))`, where `z` is the bias plus the feature dot product. It sums `p - label` for the bias gradient and `(p - label) * feature` for each weight gradient across samples in input order, then updates every parameter with `parameter -= learning_rate * summed_gradient`. The gradient is not divided by sample count.

Output is the parameter vector `[bias, weight_0, ...]` as little-endian IEEE-754 binary64 values, with no count prefix. The function returns `8 * (feature_count + 1)`. The workload uses absolute and relative tolerance `1e-10`. Invalid input returns -1; insufficient or null output capacity returns -2 without writing.

## Source-specific details

The pinned Rust function returns `None` for an empty dataset. Its first sample determines the number of weights, its initial parameter vector includes an intercept, and the optimizer applies the derivative vector directly once per iteration. This contract maps those behaviors to a bounded rectangular input and an explicit epoch count.

## Build

Run:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm logistic_regression_rust_binary_gd --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/l/logistic_regression_rust_binary_gd/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/l/logistic_regression_rust_binary_gd.c`](../../../c/l/logistic_regression_rust_binary_gd.c) |
| C3 | [`c3/l/logistic_regression_rust_binary_gd.c3`](../../../c3/l/logistic_regression_rust_binary_gd.c3) |
| C++ | [`cpp/l/logistic_regression_rust_binary_gd.cpp`](../../../cpp/l/logistic_regression_rust_binary_gd.cpp) |
| Elisa | [`elisa/l/logistic_regression_rust_binary_gd.elisa`](../../../elisa/l/logistic_regression_rust_binary_gd.elisa) |
| Nim | [`nim/l/logistic_regression_rust_binary_gd.nim`](../../../nim/l/logistic_regression_rust_binary_gd.nim) |
| Odin | [`odin/l/logistic_regression_rust_binary_gd.odin`](../../../odin/l/logistic_regression_rust_binary_gd.odin) |
| Rust | [`rust/l/logistic_regression_rust_binary_gd.rs`](../../../rust/l/logistic_regression_rust_binary_gd.rs) |
| V | [`v/l/logistic_regression_rust_binary_gd.v`](../../../v/l/logistic_regression_rust_binary_gd.v) |
| Zig | [`zig/l/logistic_regression_rust_binary_gd.zig`](../../../zig/l/logistic_regression_rust_binary_gd.zig) |

## Pinned source

- Rust [logistic_regression.rs](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/machine_learning/logistic_regression.rs)
- Rust [gradient_descent.rs](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/machine_learning/optimization/gradient_descent.rs)

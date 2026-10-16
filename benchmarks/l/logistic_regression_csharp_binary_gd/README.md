# C# binary logistic regression with full-batch gradient descent

This package follows TheAlgorithms C# `LogisticRegression` class. It initializes a feature weight for every column and a separate intercept to zero, applies full-batch gradient descent, and evaluates one query vector with `PredictProbability`.

## Contract

The `i64_array_float64` ABI receives `[sample_count, feature_count, epochs, learning_rate_q1e6, row_major_training_features_q1e6..., labels..., query_features_q1e6...]`. There are 1 through 32 training samples, 1 through 8 features, 0 through 128 epochs, and a learning-rate integer from 1 through 100,000. The learning rate, each training feature, and each query feature are divided by 1,000,000. Labels must be exactly 0 or 1. The packed length is `4 + sample_count * feature_count + sample_count + feature_count`, at most 300 integers.

Weights and bias begin at zero. Each epoch visits the training rows in their packed order and computes `error = sigmoid(dot(row, weights) + bias) - label`. It accumulates `error * feature` into each weight gradient and `error` into the bias gradient, then subtracts the learning rate times each mean gradient. After training, it returns `sigmoid(dot(query, weights) + bias)` as one binary64 value. The output tolerance is absolute `1e-10` and relative `1e-12`. Malformed input or values outside the bounds return `-1e300`.

The source's `Fit` method stores the model weights and its `PredictProbability` method returns a probability. This contract makes epochs, learning rate, training data, and one prediction query explicit; it does not include `Predict`'s 0.5 classification threshold.

## Workload

[`workload.json`](workload.json) covers zero and multiple epochs, positive and negative labels, a bias-only update, gradient cancellation, multiple feature counts, bounded batches, and malformed or out-of-range inputs. The expected probability follows the source's ordered full-batch updates.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm logistic_regression_csharp_binary_gd --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/l/logistic_regression_csharp_binary_gd/rust/build.json
```

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/l/logistic_regression_csharp_binary_gd.c`](../../../c/l/logistic_regression_csharp_binary_gd.c) |
| C3 | [`c3/l/logistic_regression_csharp_binary_gd.c3`](../../../c3/l/logistic_regression_csharp_binary_gd.c3) |
| C++ | [`cpp/l/logistic_regression_csharp_binary_gd.cpp`](../../../cpp/l/logistic_regression_csharp_binary_gd.cpp) |
| Elisa | [`elisa/l/logistic_regression_csharp_binary_gd.elisa`](../../../elisa/l/logistic_regression_csharp_binary_gd.elisa) |
| Nim | [`nim/l/logistic_regression_csharp_binary_gd.nim`](../../../nim/l/logistic_regression_csharp_binary_gd.nim) |
| Odin | [`odin/l/logistic_regression_csharp_binary_gd.odin`](../../../odin/l/logistic_regression_csharp_binary_gd.odin) |
| Rust | [`rust/l/logistic_regression_csharp_binary_gd.rs`](../../../rust/l/logistic_regression_csharp_binary_gd.rs) |
| V | [`v/l/logistic_regression_csharp_binary_gd.v`](../../../v/l/logistic_regression_csharp_binary_gd.v) |
| Zig | [`zig/l/logistic_regression_csharp_binary_gd.zig`](../../../zig/l/logistic_regression_csharp_binary_gd.zig) |

## Pinned source

- C# [`LogisticRegression.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/MachineLearning/LogisticRegression.cs)

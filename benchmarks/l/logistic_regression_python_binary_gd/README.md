# Python Binary Logistic Regression with Full-Batch Gradient Descent

This package follows the pinned Python function that trains a zero-initialized coefficient vector with a sigmoid hypothesis and full-batch gradient descent. The contract uses bounded Q1e6 features and learning rate, explicit epochs, and binary labels.

## Contract

Input is a signed 64-bit array [sample_count, feature_count, epochs, learning_rate_q1e6, row_major_feature_q1e6..., labels...]. There are 1 through 32 samples and 1 through 8 features. Epochs range from 0 through 128. The learning rate and every feature are divided by 1,000,000; the learning-rate integer is from 1 through 100,000 and feature integers are from -1,000,000 through 1,000,000. Labels are exactly 0 or 1. The input length must be 4 + sample_count * (feature_count + 1).

The coefficient vector starts at zero. On every epoch the implementation computes each sample score as the feature dot product with the current coefficients, applies sigmoid, forms the full-batch mean gradient X-transpose times (prediction minus label), then updates all coefficients simultaneously. It does not add an intercept or regularization.

Output is the returned coefficient vector as little-endian IEEE-754 binary64 values, in feature order and without a count prefix. The function returns 8 times the feature count. The workload compares coefficients with absolute and relative tolerance 1e-10. Invalid input returns -1; insufficient or null output capacity returns -2 without writing.

## Source-specific details

The pinned Python implementation defaults to 70,000 epochs; this contract supplies an explicit bounded epoch count. It recomputes loss and prints it every 100 iterations after updating the weights. Those calculations and logging do not affect the returned coefficients, so the ABI ports omit them.

## Build

Run:

python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm logistic_regression_python_binary_gd --language rust

python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/l/logistic_regression_python_binary_gd/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/l/logistic_regression_python_binary_gd.c](../../../c/l/logistic_regression_python_binary_gd.c) |
| C3 | [c3/l/logistic_regression_python_binary_gd.c3](../../../c3/l/logistic_regression_python_binary_gd.c3) |
| C++ | [cpp/l/logistic_regression_python_binary_gd.cpp](../../../cpp/l/logistic_regression_python_binary_gd.cpp) |
| Elisa | [elisa/l/logistic_regression_python_binary_gd.elisa](../../../elisa/l/logistic_regression_python_binary_gd.elisa) |
| Nim | [nim/l/logistic_regression_python_binary_gd.nim](../../../nim/l/logistic_regression_python_binary_gd.nim) |
| Odin | [odin/l/logistic_regression_python_binary_gd.odin](../../../odin/l/logistic_regression_python_binary_gd.odin) |
| Rust | [rust/l/logistic_regression_python_binary_gd.rs](../../../rust/l/logistic_regression_python_binary_gd.rs) |
| V | [v/l/logistic_regression_python_binary_gd.v](../../../v/l/logistic_regression_python_binary_gd.v) |
| Zig | [zig/l/logistic_regression_python_binary_gd.zig](../../../zig/l/logistic_regression_python_binary_gd.zig) |

## Pinned source

- Python [logistic_regression.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/logistic_regression.py)

# Logistic Regression Prediction

This benchmark follows the pinned MATLAB-Octave `Predict.m` and `Sigmoid.m`. It classifies each row of a bounded integer feature matrix with a supplied parameter vector, then packs the predictions into one signed 64-bit result. It does not train or update the parameters.

## Contract

The input is a signed 64-bit integer array laid out as `[row_count, feature_count, row_major_features..., theta...]`. It contains between 1 and 63 rows and between 1 and 32 features per row. Feature and parameter values are each in `[-1,000, 1,000]`. The exact input length is `2 + row_count * feature_count + feature_count`.

For each row, compute the integer dot product of that row and `theta`. The prediction is 1 when the score is nonnegative and 0 otherwise. This is equivalent to the pinned sigmoid classifier's `probability >= 0.5` decision, including the zero-score boundary. Prediction for row `j` is stored in bit `j` of the result, with the first row in bit 0. At most 63 rows are allowed so the result always fits in a nonnegative signed 64-bit integer. Malformed input returns `-1`.

The portable ABI is `i64_array_scalar`: the function receives the array pointer and its length and returns one signed 64-bit result.

## Workload and source

[`workload.json`](workload.json) covers zero and nonzero scores, mixed predictions, the inclusive threshold, invalid shapes and values, and the 63-row/32-feature boundary. The independent scalar oracle is [`logistic_regression_predict_oracle.py`](../../logistic_regression_predict_oracle.py).

Pinned MATLAB-Octave sources:

- [`Predict.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/machine_learning/Logistic-Regression/Predict.m)
- [`Sigmoid.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/machine_learning/Logistic-Regression/Sigmoid.m)

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm logistic_regression_predict --language rust --with-checker
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/l/logistic_regression_predict/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms logistic_regression_predict --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [c/l/logistic_regression_predict.c](../../../c/l/logistic_regression_predict.c) |
| C3 | [c3/l/logistic_regression_predict.c3](../../../c3/l/logistic_regression_predict.c3) |
| C++ | [cpp/l/logistic_regression_predict.cpp](../../../cpp/l/logistic_regression_predict.cpp) |
| Elisa | [elisa/l/logistic_regression_predict.elisa](../../../elisa/l/logistic_regression_predict.elisa) |
| Nim | [nim/l/logistic_regression_predict.nim](../../../nim/l/logistic_regression_predict.nim) |
| Odin | [odin/l/logistic_regression_predict.odin](../../../odin/l/logistic_regression_predict.odin) |
| Rust | [rust/l/logistic_regression_predict.rs](../../../rust/l/logistic_regression_predict.rs) |
| V | [v/l/logistic_regression_predict.v](../../../v/l/logistic_regression_predict.v) |
| Zig | [zig/l/logistic_regression_predict.zig](../../../zig/l/logistic_regression_predict.zig) |

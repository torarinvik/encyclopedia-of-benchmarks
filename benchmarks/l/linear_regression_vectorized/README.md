# Vectorized linear regression

This benchmark maps the local `linear_regression_vectorized` symbol to the pinned Python `gradient_descent` function. It excludes remote dataset collection, the script's `main`, progress printing, and mean absolute error; the measured result is the learned coefficient vector.

## Contract

- The ABI is `float64_slice_io`. Input is `[m, d, iterations, alpha, X row-major, y]`, where `X` has `m*d` feature values and `y` has `m` labels. The exact input length is `4 + m*d + m`. `m` is 2–8, `d` is 2–4, `iterations` is an integer-valued double in 10–128, and `alpha` is in `[0.0001, 0.01]`. All values must be finite.
- The first column of `X` must contain exactly `1.0` for the intercept. Other feature values and labels must be in `[-1, 1]`. The source initializes `theta` to zero and, on each iteration, computes `X @ theta`, subtracts `y`, computes `(X.T @ errors) / m`, then updates `theta -= alpha * gradient`. The benchmark preserves this update order and the source's f64 result without rounding.
- Output is the `d` learned coefficients in feature order. Results are compared with absolute and relative tolerances of `1e-10`. Invalid or null input returns `-1` before output-buffer checks; a null output or capacity below `d` returns `-2` without writes. The maximum input is 44 doubles and the workspace holds four output doubles.

The fixtures cover sample and feature bounds, all supported learning-rate and iteration boundaries, multiple feature dimensions, intercept validation, invalid shapes and ranges, and zero-target cases. See [workload.json](workload.json) and the independent [oracle](../../linear_regression_vectorized_oracle.py).

Pinned source: [TheAlgorithms/Python `linear_regression_vectorized.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/linear_regression_vectorized.py), function `gradient_descent`, at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm linear_regression_vectorized --language rust
python3 benchmarks/run_float64_slice_io.py --build-manifest build/float64_slice_io/l/linear_regression_vectorized/rust/build.json
python3 benchmarks/verify_float64_slice_io.py --algorithm linear_regression_vectorized --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/l/linear_regression_vectorized.c](../../../c/l/linear_regression_vectorized.c) |
| C3 | [c3/l/linear_regression_vectorized.c3](../../../c3/l/linear_regression_vectorized.c3) |
| C++ | [cpp/l/linear_regression_vectorized.cpp](../../../cpp/l/linear_regression_vectorized.cpp) |
| Elisa | [elisa/l/linear_regression_vectorized.elisa](../../../elisa/l/linear_regression_vectorized.elisa) |
| Nim | [nim/l/linear_regression_vectorized.nim](../../../nim/l/linear_regression_vectorized.nim) |
| Odin | [odin/l/linear_regression_vectorized.odin](../../../odin/l/linear_regression_vectorized.odin) |
| Rust | [rust/l/linear_regression_vectorized.rs](../../../rust/l/linear_regression_vectorized.rs) |
| V | [v/l/linear_regression_vectorized.v](../../../v/l/linear_regression_vectorized.v) |
| Zig | [zig/l/linear_regression_vectorized.zig](../../../zig/l/linear_regression_vectorized.zig) |

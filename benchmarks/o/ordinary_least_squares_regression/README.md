# Ordinary least squares regression

This benchmark follows the pinned Python `ols_regression` implementation, which computes the centered univariate least-squares slope and then the intercept. Inputs are packed signed integers `[n, x0, y0, ...]` with 2–32 observations and coordinates in `[-10,000, 10,000]`. At least two x coordinates must differ; constant y is valid and produces a zero slope.

The result is two little-endian binary64 values in order: intercept, slope. The finite workload avoids NumPy and image/file dependencies while retaining the source's mean, centered covariance, centered variance, and intercept formula. The runtime oracle is `ordinary_least_squares_regression_oracle.py`.

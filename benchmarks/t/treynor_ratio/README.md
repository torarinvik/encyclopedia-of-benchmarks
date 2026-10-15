# Treynor Ratio

This package benchmarks the pinned [TheAlgorithms/Rust implementation](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/financial/treynor_ratio.rs). It computes excess portfolio return per unit of market risk as `(portfolio_return - risk_free_rate) / beta`.

The `i64_array_float64` ABI accepts exactly three signed integers in this order: `[portfolio_return, risk_free_rate, beta]`. Each value must be in `[-1000, 1000]`; beta must be nonzero. The integer-valued domain is a bounded subset of the source's `f64` inputs. The source returns NaN for zero beta; the finite-result benchmark ABI maps that case and malformed or out-of-range inputs to `-1e300`.

The result is binary64. Implementations preserve the subtraction before division, and the workload compares finite results with absolute and relative tolerance `1e-12`. This is distinct from the Sharpe ratio, which divides excess return by return-series volatility rather than portfolio beta. Runtime and auxiliary space are O(1).

The shared `run_i64_array_float64.py` runner checks workload cases against the bounded source formula before timing.

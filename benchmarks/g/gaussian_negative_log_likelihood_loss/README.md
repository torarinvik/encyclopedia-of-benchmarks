# Gaussian negative log-likelihood loss

This benchmark ports the pinned Python [`gaussian_negative_log_likelihood_loss`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/loss_functions.py) method. It averages the source expression over aligned target, predicted-mean, and variance arrays. The source omits the Gaussian normalizing constant and floors each variance at `1e-6` before taking its logarithm and dividing the squared residual.

## Contract

The `i64_array_float64_call` ABI receives `[n, y_true_micro[0..n], expectation_micro[0..n], variance_nano[0..n]]`, with `1 <= n <= 256` and exactly `1 + 3*n` values. Targets and expectations are integers in `[-1,000,000, 1,000,000]` divided by `1,000,000`. Variances are positive integers in `[1, 1,000,000,000]` divided by `1,000,000,000`, so inputs can exercise the source's `1e-6` variance floor.

For each element compute `0.5 * log(max(variance, 1e-6)) + 0.5 * (target - expectation)^2 / max(variance, 1e-6)`, then return the arithmetic mean in input order. Malformed packing or out-of-domain values return `-1e300`. Results use absolute and relative tolerance `1e-12`.

## Workload

[`workload.json`](workload.json) covers zero and nonzero residuals, the variance floor, averaging, and invalid input. The independent oracle is [`gaussian_negative_log_likelihood_loss_oracle.py`](../../gaussian_negative_log_likelihood_loss_oracle.py).

## Implementations

The nine language ports live in the matching initial-letter folders: `c/g`, `c3/g`, `cpp/g`, `elisa/g`, `nim/g`, `odin/g`, `rust/g`, `v/g`, and `zig/g`.

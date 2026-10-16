# Categorical Cross Entropy

This benchmark ports `categorical_cross_entropy` from the pinned TheAlgorithms/Python loss-functions module.

## Contract

- Input is `[B, C, one_hot[B*C], probability_scaled[B*C]]`, flattened row-major, with `1 <= B <= 64`, `2 <= C <= 16`, and exact length `2 + 2BC`.
- Each label row is one-hot. Each probability is an integer from 0 through 1,000,000, scaled by 1,000,000; each un-clipped probability row must sum to exactly 1,000,000.
- Probabilities are clipped to `[1e-15, 1]`. The result is the source's sum of `-y*ln(p)` over every row and class; it is not divided by the batch size.
- Return one binary64 scalar. Invalid input returns `-1e300`.
- Comparison uses absolute and relative tolerances of `1e-12`.

The independent [`categorical_cross_entropy_oracle.py`](../../categorical_cross_entropy_oracle.py) evaluates the scalar formula directly.

## Pinned source

[TheAlgorithms/Python `loss_functions.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/loss_functions.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`, method `categorical_cross_entropy`.

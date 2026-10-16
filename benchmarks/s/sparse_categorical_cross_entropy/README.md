# Sparse Categorical Cross-Entropy

This package benchmarks the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/loss_functions.py), method `sparse_categorical_cross_entropy`. Sum, over rows, of `-ln(clip(probability[row, label], 1e-15, 1))`; source uses sum reduction.

The `i64_array_float64` ABI packs `[batch, classes, labels[0..batch], probabilities_scaled[0..batch*classes]]`. Each fixed-point value is divided by 1,000,000. Batch and classes are each 1..32; labels are in `[0, classes)`; probabilities are scaled integers in `[0,1_000_000]` and every row sums exactly to 1_000_000. Inputs must have the exact packed length.

Malformed layouts or out-of-domain values return `-1e300`. Results use absolute and relative tolerance `1e-12`. Runtime is O(batch*classes); auxiliary space is O(1).

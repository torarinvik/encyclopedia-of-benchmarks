# R binary and multiclass perceptron

This package follows the pinned R6 `Perceptron$fit` and `predict` implementation. It preserves both source branches: binary labels use one weight vector and a signed-margin update; three classes use one weight row per class and direct multiclass updates. Java, Python, and Rust perceptrons have separate packages because their label, initialization, and update rules differ.

## Contract

Input is `[learning_rate, n_epochs, sample_count, feature_count, row-major training features..., labels..., query_count, row-major query features...]`. Use learning rates `{0.25, 0.5, 0.75, 1.0}`, 1–12 epochs, 2–8 samples, 1–4 features, 1–4 queries, integer feature values in `[-2,2]`, and integer labels in `[-2,2]` with two or three distinct values. Numeric class labels are sorted as in the source. This workload fixes `shuffle=false`, `fit_intercept=true`, and `random_state=NULL` to keep row order deterministic and use the source's intercept column.

For two classes, the lower sorted class maps to -1 and the higher class maps to +1. Each epoch visits rows in input order and updates the single weight vector when `encoded_label * score <= 0`. For three classes, scores are computed for every class, the first maximum wins ties, and a mistake adds `learning_rate * augmented_row` to the true class row and subtracts it from the predicted class row. R runs exactly `n_epochs`; it does not stop early. Predictions return original class labels.

Output is `[class_count, sorted_classes..., parameter_count, parameters..., query_count, predictions...]`. Binary parameters contain one intercept-first weight vector; multiclass parameters contain the class-major weight matrix. Invalid inputs return `-1`; null output or insufficient capacity returns `-2` without writes. Tolerance is `1e-10` absolute and relative.

See the [workload](workload.json), [oracle](../../perceptron_r_oracle.py), and pinned [R source](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/machine_learning/perceptron.r).

## Ports

- [C](../../../c/p/perceptron_r.c)
- [C++](../../../cpp/p/perceptron_r.cpp)
- [C3](../../../c3/p/perceptron_r.c3)
- [Rust](../../../rust/p/perceptron_r.rs)
- [Elisa](../../../elisa/p/perceptron_r.elisa)
- [Nim](../../../nim/p/perceptron_r.nim)
- [Odin](../../../odin/p/perceptron_r.odin)
- [V](../../../v/p/perceptron_r.v)
- [Zig](../../../zig/p/perceptron_r.zig)

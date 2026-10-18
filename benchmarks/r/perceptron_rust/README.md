# Rust ±1 perceptron

This package follows the pinned Rust `perceptron` trainer and `classify` helper. It is separate from Java's binary 0/1 model, Python's seeded random initialization and fixed bias feature, and R's optional-shuffle binary/multiclass classifier.

## Contract

Input is `[max_iterations, learning_rate, sample_count, feature_count, row-major training features..., labels..., query_count, row-major query features...]`. The bounded domain uses 0–12 iterations, learning rates `{0.25, 0.5, 0.75, 1.0}`, 2–8 samples, 1–4 features, 1–4 queries, integer features in `[-2,2]`, and labels `-1` or `1`.

Training starts with zero weights and bias. Rows are visited in input order. Prediction is `1` when the ordered dot product plus bias is at least zero and `-1` otherwise. For each mistake, update each weight by `learning_rate * label * feature` and bias by `learning_rate * label`. Stop after an iteration with no misclassified rows or at `max_iterations`. The function returns final weights and bias; the benchmark also classifies each query with the pinned `>= 0` rule.

Output is `[feature_count, weights..., bias, query_count, predictions...]`. Invalid inputs return `-1`; null output or insufficient capacity returns `-2` without writes. Tolerance is `1e-10` absolute and relative.

See the [workload](workload.json), [oracle](../../perceptron_rust_oracle.py), and pinned [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/machine_learning/perceptron.rs).

## Ports

- [C](../../../c/p/perceptron_rust.c)
- [C++](../../../cpp/p/perceptron_rust.cpp)
- [C3](../../../c3/p/perceptron_rust.c3)
- [Rust](../../../rust/p/perceptron_rust.rs)
- [Elisa](../../../elisa/p/perceptron_rust.elisa)
- [Nim](../../../nim/p/perceptron_rust.nim)
- [Odin](../../../odin/p/perceptron_rust.odin)
- [V](../../../v/p/perceptron_rust.v)
- [Zig](../../../zig/p/perceptron_rust.zig)

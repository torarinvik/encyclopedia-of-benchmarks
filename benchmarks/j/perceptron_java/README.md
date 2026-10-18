# Java binary perceptron

This package follows the Java `Perceptron.fit` and `predict` implementation pinned in the workload. It is distinct from the Python seeded ±1 model, the R binary/multiclass implementation, and the Rust zero-initialized ±1 function.

## Contract

Input is `[learning_rate, max_epochs, sample_count, feature_count, row-major training features..., labels..., query_count, row-major query features...]`. The bounded domain uses learning rates `{0.25, 0.5, 0.75, 1.0}`, 1–12 epochs, 2–8 training samples, 1–4 features, 1–4 queries, integer feature values in `[-2,2]`, and binary labels `0` or `1`.

Training starts with zero weights and zero bias. Rows are visited in input order. Prediction is `1` when weighted sum plus bias is at least zero, otherwise `0`. For each mistake, update each weight by `learning_rate * (label - prediction) * feature` and bias by `learning_rate * (label - prediction)`. The model stops after the first epoch with no updates or after `max_epochs`; output includes the number of epochs and whether it converged. Queries use the fitted weights and bias.

Output is `[feature_count, weights..., bias, epochs_run, converged_as_0_or_1, query_count, predictions...]`. Invalid inputs return `-1`; null output or insufficient capacity returns `-2` without writes. Tolerance is `1e-10` absolute and relative.

See the [workload](workload.json), [oracle](../../perceptron_java_oracle.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/machinelearning/Perceptron.java).

## Ports

- [C](../../../c/p/perceptron_java.c)
- [C++](../../../cpp/p/perceptron_java.cpp)
- [C3](../../../c3/p/perceptron_java.c3)
- [Rust](../../../rust/p/perceptron_java.rs)
- [Elisa](../../../elisa/p/perceptron_java.elisa)
- [Nim](../../../nim/p/perceptron_java.nim)
- [Odin](../../../odin/p/perceptron_java.odin)
- [V](../../../v/p/perceptron_java.v)
- [Zig](../../../zig/p/perceptron_java.zig)

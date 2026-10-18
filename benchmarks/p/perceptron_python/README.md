# Python seeded ±1 perceptron

This package follows the pinned Python `Perceptron.training` and `sort` methods. It is separate from Java's zero-initialized 0/1 model, R's binary/multiclass trainer, and Rust's zero-initialized ±1 implementation.

## Contract

Input is `[learning_rate, epoch_number, sample_count, feature_count, row-major training features..., targets..., query_count, row-major query features...]`. Use learning rates `{0.25, 0.5, 0.75, 1.0}`, 1–12 epochs, 2–8 samples, 1–4 features, 1–4 queries, integer feature values in `[-2,2]`, and targets `-1` or `1`.

Each invocation constructs a fresh model with the source defaults `bias=-1` and `seed=0`. The pinned `random.Random(0)` generator supplies the first `feature_count` initial feature weights; the bias value is also prepended as the first weight and as the first feature of every training/query row. Samples are visited in input order. The sign function returns `1` for scores at least zero and `-1` otherwise. For each mistake, update every weight by `learning_rate * (target - prediction) * augmented_feature`. Stop after an epoch with no mistakes or at `epoch_number`.

Output is `[epochs_run, weight_count, weights..., query_count, predictions...]`, including the training method's epoch count and final augmented weight vector. Invalid framing/data returns `-1`; null output or insufficient capacity returns `-2` without writes. Tolerance is `1e-10` absolute and relative.

See the [workload](workload.json), [oracle](../../perceptron_python_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/perceptron.py).

## Ports

- [C](../../../c/p/perceptron_python.c)
- [C++](../../../cpp/p/perceptron_python.cpp)
- [C3](../../../c3/p/perceptron_python.c3)
- [Rust](../../../rust/p/perceptron_python.rs)
- [Elisa](../../../elisa/p/perceptron_python.elisa)
- [Nim](../../../nim/p/perceptron_python.nim)
- [Odin](../../../odin/p/perceptron_python.odin)
- [V](../../../v/p/perceptron_python.v)
- [Zig](../../../zig/p/perceptron_python.zig)

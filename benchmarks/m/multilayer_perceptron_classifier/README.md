# Python multilayer perceptron classifier

This package follows the pinned Python `Dataloader` and `MLP.train()` path. It preserves the source's fixed split, dimension choice, He-scaled seeded initialization, one-row gradient updates, and test metric history.

## Contract

Each call represents the first model constructed after a fresh import of the pinned module, whose module-global NumPy generator is initialized with `default_rng(42)`. The fixed network is 2 inputs, 2 ReLU hidden units, and 3 linear outputs. The source initializes `w1` from the first `(3,2)` standard-normal matrix scaled by `sqrt(2/2)`, then `w2` from the following `(2,3)` matrix scaled by `sqrt(2/2)`. The exact initial matrices are embedded in the oracle so ports do not depend on a NumPy RNG implementation.

Input is `[epoch_count, learning_rate, gamma, x00, x01, ..., x30, x31, label0, label1, label2, label3]`, with exactly four two-dimensional rows. The source's `Dataloader` always uses rows 0–2 for training and row 3 for testing; `shuffle_data` is a no-op. The output dimension is the number of training rows, three, even when some class IDs are absent. Labels are integers in `{0,1,2}` and one-hot targets contain `0.99` in the selected class column.

For each epoch, visit the three training rows in order. Append a bias feature of `1`, compute `z1 = x*w1`, ReLU hidden activations, and linear outputs `z2 = relu(z1)*w2`. Backpropagate `delta_out = z2-target`, `delta_hidden = delta_out*w2ᵀ * (z1>0)`, and update both matrices in place with the current learning rate. Then evaluate the one test row, record argmax accuracy (first index wins ties) and `sum((output-target)^2)/2`, and multiply the learning rate by `gamma` for the next epoch. There is no early stopping.

Output is `[epoch_count, test_accuracy_history..., test_loss_history..., mean_test_accuracy]`. The final value captures the average printed by `train()`; the histories correspond to `get_acc_loss()`. Invalid framing or values return `-1`; null output or insufficient capacity returns `-2` without writes. Feature inputs are finite quarter increments in `[-2,2]`; learning rate is one of `{0.05,0.1,0.2}`, gamma is one of `{0.5,0.75,1.0}`, and epochs are `1..12`. Tolerance is `1e-9` absolute and relative.

See the [workload](workload.json), [oracle](../../multilayer_perceptron_classifier_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/multilayer_perceptron_classifier.py).

## Ports

- [C](../../../c/m/multilayer_perceptron_classifier.c)
- [C++](../../../cpp/m/multilayer_perceptron_classifier.cpp)
- [C3](../../../c3/m/multilayer_perceptron_classifier.c3)
- [Rust](../../../rust/m/multilayer_perceptron_classifier.rs)
- [Elisa](../../../elisa/m/multilayer_perceptron_classifier.elisa)
- [Nim](../../../nim/m/multilayer_perceptron_classifier.nim)
- [Odin](../../../odin/m/multilayer_perceptron_classifier.odin)
- [V](../../../v/m/multilayer_perceptron_classifier.v)
- [Zig](../../../zig/m/multilayer_perceptron_classifier.zig)

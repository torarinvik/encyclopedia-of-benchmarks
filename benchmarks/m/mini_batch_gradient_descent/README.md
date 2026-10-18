# Mini-batch gradient descent

This package covers the pinned Python linear-regression routine with explicit per-epoch permutations. The permutation rows replace NumPy's seeded RNG output in the benchmark input, while retaining the source's update sequence and final short-batch behavior.

## Contract

The `float64_slice_io` input is `[sample_count, feature_count, batch_size, epoch_count, learning_rate, X..., y..., permutation_rows...]`. `X` is row-major. Each of the `epoch_count` permutation rows contains every sample index exactly once and specifies the shuffled order for that epoch. The bounds are 1–8 samples, 1–3 features, 0–8 epochs, batch size 1–sample_count, learning rate in `[0,0.25]`, features in `[-10,10]`, and targets in `[-100,100]`.

Weights and bias start at zero. For each epoch, process the supplied order in consecutive batches; the last batch may be shorter. Compute predictions from the current weights and bias, then errors. Accumulate each feature gradient and the error mean in batch order. Update all weights by `weight -= learning_rate * gradient / batch_length`, then update bias by `bias -= learning_rate * mean_error`, using the same pre-update errors. The benchmark uses explicit left-to-right accumulation for deterministic cross-language results. Output is `[weights..., bias]` in feature order. Invalid framing, bounds, or non-permutation rows return `-1`; non-finite training state also returns `-1`. Insufficient output capacity returns `-2` without writes.

See the [workload](workload.json), [oracle](../../mini_batch_gradient_descent_oracle.py), and pinned [`mini_batch_gradient_descent`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/mini_batch_gradient_descent.py).

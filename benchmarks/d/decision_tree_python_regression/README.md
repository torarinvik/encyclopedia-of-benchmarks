# Python regression decision tree

This package isolates the regression-tree implementation in the pinned Python source. The filename match also contains a Jupyter Gini classifier, an R `rpart` demo, and a Rust ID3 classifier; those have separate semantics and are not part of this workload.

## Contract

Input is a finite float64 array framed as `[depth, min_leaf_size, sample_count, x..., y..., query_count, queries...]`. Integer-valued fields and samples are required. The bounded domain is depth 1–6, minimum leaf size 1–6, 2–12 training samples, 1–12 queries, and feature, label, and query values in `[-8,8]`. Training samples remain in their supplied positional order; the benchmark does not sort them.

The source creates a leaf with the mean label when the current sample count is less than twice the minimum leaf size or the depth is one. Otherwise it examines split indices in ascending order, skipping children smaller than the minimum leaf size. Its split score is the sum of the mean squared errors of each **feature slice** against the corresponding mean **label slice**. The initial no-split threshold is twice the feature-array MSE against the mean label. This preserves the pinned source's actual `train()` behavior. The first strictly lower split score wins; if none beats the threshold, the node is a leaf. The split boundary is the first feature in the right slice, and prediction routes `query >= boundary` right.

The output is `[query_count, predictions...]` in query order. Invalid framing or values return `-1`; a null output or insufficient output capacity returns `-2` without writing. The comparison tolerance is `1e-10` absolute and relative.

See the [workload](workload.json), [oracle](../../decision_tree_python_regression_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/decision_tree.py). The demonstration's random query generation and printing are excluded.

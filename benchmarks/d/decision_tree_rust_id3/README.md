# Rust ID3 entropy decision tree

This package follows the pinned Rust `DecisionTree::fit` and `predict` implementation. It is separate from the Python regression tree and the Jupyter Gini classifier because it uses entropy gain, midpoint thresholds, majority-class leaves, and a maximum-depth/minimum-split policy.

## Contract

Input is `[max_depth, min_samples_split, sample_count, feature_count, row-major training rows (features..., label), query_count, row-major query features...]`. Use `max_depth` in `0..6`, `min_samples_split` in `2..8`, 2–8 samples, 1–4 features, and 1–4 queries. Features are finite quarter-step values in `[-4,4]`; labels are integer-valued classes in `{0,1,2}`.

At each node, stop at one unique label, when row count is less than `min_samples_split`, when `current_depth >= max_depth`, or when there are no features. A leaf predicts the most frequent label; a count tie keeps the label first seen in that node's input order. For each feature in index order, sort rows by that feature and consider the midpoint of every adjacent pair of distinct values. Compute base-2 entropy gain and retain only strict improvements, so feature and threshold ties keep the first candidate. Split values less than the threshold left and values greater than or equal to it right. All feature indices remain eligible in child nodes.

Output is `[query_count, predicted_labels...]`. Invalid framing or values return `-1`; null output or insufficient capacity returns `-2` without writes. The workload uses tolerance `1e-10` absolute and relative.

See the [workload](workload.json), [oracle](../../decision_tree_rust_id3_oracle.py), and pinned [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/machine_learning/decision_tree.rs).

## Ports

- [C](../../../c/d/decision_tree_rust_id3.c)
- [C++](../../../cpp/d/decision_tree_rust_id3.cpp)
- [C3](../../../c3/d/decision_tree_rust_id3.c3)
- [Rust](../../../rust/d/decision_tree_rust_id3.rs)
- [Elisa](../../../elisa/d/decision_tree_rust_id3.elisa)
- [Nim](../../../nim/d/decision_tree_rust_id3.nim)
- [Odin](../../../odin/d/decision_tree_rust_id3.odin)
- [V](../../../v/d/decision_tree_rust_id3.v)
- [Zig](../../../zig/d/decision_tree_rust_id3.zig)

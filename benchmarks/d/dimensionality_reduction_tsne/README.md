# Dimensionality reduction t-SNE slice

This is a bounded split of `t_distributed_stochastic_neighbor_embedding` from the pinned Python `machine_learning/dimensionality_reduction.py` source. The source accepts arbitrary feature dimensions and runs a configurable number of iterations; this contract fixes one feature, three samples, one output dimension, seed 42, perplexity 1.5, learning rate 10, and five iterations.

The float64 input is `[feature_count, sample_count, x0, x1, x2]`, so the supported shape is `[1, 3, ...]`. Feature values must be finite and within `[-100, 100]`. The output is the one-dimensional embedding in sample order. The seeded initial embedding is the exact three-value draw produced by NumPy `default_rng(42).normal(0, 1e-4, (1, 3))`; fixing these values makes the contract portable without requiring each language to reproduce NumPy's random-number generator. The implementation retains the source's conditional probability search, symmetrization, Student-t low-dimensional probabilities, gradient, and momentum updates.

Elisa evaluates exponential and logarithm terms with bounded range-reduced series. Its verifier links the runtime object from the configured Elisa compiler installation, since the compiler emits `arena_free` for the function's fixed arrays.

Malformed input returns `-1`; insufficient output capacity or a null output returns `-2`. See [`workload.json`](workload.json), the [independent oracle](../../dimensionality_reduction_tsne_oracle.py), and the [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/dimensionality_reduction.py).

| Language | Port |
|---|---|
| C | [`c/d/dimensionality_reduction_tsne.c`](../../../c/d/dimensionality_reduction_tsne.c) |
| C3 | [`c3/d/dimensionality_reduction_tsne.c3`](../../../c3/d/dimensionality_reduction_tsne.c3) |
| C++ | [`cpp/d/dimensionality_reduction_tsne.cpp`](../../../cpp/d/dimensionality_reduction_tsne.cpp) |
| Elisa | [`elisa/d/dimensionality_reduction_tsne.elisa`](../../../elisa/d/dimensionality_reduction_tsne.elisa) |
| Nim | [`nim/d/dimensionality_reduction_tsne.nim`](../../../nim/d/dimensionality_reduction_tsne.nim) |
| Odin | [`odin/d/dimensionality_reduction_tsne.odin`](../../../odin/d/dimensionality_reduction_tsne.odin) |
| Rust | [`rust/d/dimensionality_reduction_tsne.rs`](../../../rust/d/dimensionality_reduction_tsne.rs) |
| V | [`v/d/dimensionality_reduction_tsne.v`](../../../v/d/dimensionality_reduction_tsne.v) |
| Zig | [`zig/d/dimensionality_reduction_tsne.zig`](../../../zig/d/dimensionality_reduction_tsne.zig) |

Run focused verification with `python3 benchmarks/verify_float64_slice_io.py --algorithm dimensionality_reduction_tsne`.

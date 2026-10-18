# K-means (general Rust source variant)

This benchmark preserves the pinned Rust implementation's deterministic evenly spaced initialization and label-based convergence.

## Contract

- Input is `[n, x0, ..., x(n-1)]`, with `2 <= n <= 8` and strictly increasing integer coordinates in `[-16,16]`. The adapter represents each point as a one-dimensional binary64 vector and fixes `k = 2`.
- Initial centers are source points at indices `j * floor(n / 2)` for `j = 0,1`. Squared Euclidean distance selects the nearest center; ties go to the earlier center. The source recomputes means, reassigns labels, and returns when labels stop changing. The adapter caps this loop at 256 passes and returns `-2` if the cap is reached.
- Return one bit per point, `sum(label[i] << i)`. Malformed input returns `-1`.

See the [workload](workload.json) and [oracle](../../kmeans_rust_oracle.py).

## Pinned source

[`kmeans.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/general/kmeans.rs), commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`, function `f64::kmeans`.

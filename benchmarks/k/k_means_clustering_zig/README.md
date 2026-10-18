# K-means clustering (Zig source variant)

This benchmark preserves Zig's first-points initialization, `f32` arithmetic, and exact center-and-count convergence check.

## Contract

- Input is `[n, x0, ..., x(n-1)]`, with `2 <= n <= 8` and strictly increasing integer coordinates in `[-16,16]`. The adapter converts x coordinates to `f32`, sets y to zero, and fixes `k = 2`.
- Initial centers are the first two data points. Points use squared Euclidean distance, and equal distances stay with the earlier center. Each loop sums points in input order, divides by each cluster count in `f32`, and compares both center coordinates and counts exactly with the previous state.
- Return both center x coordinates and their counts. Quantize each f32 center by truncating `center * 256` toward zero; bias each by 4097 and pack the centers in base 8194. Multiply that pair by 81, then append `count0 * 9 + count1`. The adapter caps at 64 passes (`-2`); malformed input returns `-1`.

See the [workload](workload.json) and [oracle](../../k_means_clustering_zig_oracle.py).

## Pinned source

[`k_means_clustering.zig`](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/machine_learning/k_means_clustering.zig), commit `86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3`, function `KMeans`.

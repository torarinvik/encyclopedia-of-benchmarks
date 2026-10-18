# K-means clustering (C source variant)

This benchmark preserves the C source's randomized initial group labels and threshold-based Lloyd loop. The adapter passes the random label stream explicitly.

## Contract

- Input is `[n, initial_group[0..n-1], x0, ..., x(n-1)]`, with `3 <= n <= 8`, two groups, labels in `{0,1}`, and both groups represented. Coordinates are strictly increasing integers in `[-16,16]`; y coordinates are fixed at zero.
- The label words replace the source's successive `rand() % 2` values. Each loop computes group means, reassigns each point to its nearest centroid using squared Euclidean distance, and keeps the first group on equal distance.
- The source threshold is `n / 10000`, which is zero throughout this bounded domain, so it stops after a pass with no changed labels. If any pass empties a group, the adapter returns `-1` before the source's division by zero. The adapter caps the loop at 64 passes and returns `-2` only if the cap is reached.
- Return the final group centers in group order. Quantize each x coordinate by truncating `center * 256` toward zero, add 4097, and pack as `code0 * 8194 + code1`. Malformed input returns `-1`.

See the [workload](workload.json) and [oracle](../../k_means_clustering_c_oracle.py).

## Pinned source

[`k_means_clustering.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/machine_learning/k_means_clustering.c), commit `e5dad3fa8def3726ec850ca66a7f51521f8ad393`, function `kMeans`.

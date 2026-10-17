# k-means clustering

This benchmark covers one update of the pinned Python `kmeans` implementation. The caller provides both the data points and initial centroids, so the source's random initialization is not part of the workload. Every call uses `maxiter=1`.

## Contract

The ABI is `float64_slice_io`. Input is `[point_count, dimension, cluster_count, data..., initial_centroids...]`; both matrices are row-major. Counts must be exactly integral binary64 values. Data and initial-centroid coordinates must be integer-valued and in `[-16,16]`. There are 1–16 points, 1–4 dimensions, and 1–4 clusters, with no more clusters than points.

The pinned source assigns each data row to its nearest initial centroid using Euclidean pairwise distance and `numpy.argmin`, so an equal-distance point goes to the lowest centroid index. It then replaces each centroid with the arithmetic mean of its assigned rows. Inputs are valid only when every cluster receives at least one point; the source otherwise computes a NaN centroid. Since coordinates are bounded integers, squared Euclidean distances are exact integers and preserve the source's Euclidean-distance ordering and ties. Mean coordinates are returned as binary64 values.

Output is `[cluster_assignment[0..point_count), updated_centroids_row_major...]`, with assignments represented as exact integer-valued doubles. Its length is `point_count + cluster_count*dimension`, at most 32 elements. Malformed input, unsupported bounds, fractional counts or coordinates, or an empty assigned cluster returns `-1`. Input validity is checked before the output pointer and capacity; a null output or capacity below the required element count returns `-2` without writes.

## Pinned source

- Python `kmeans`, `assign_clusters`, and `revise_centroids`: https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/k_means_clust.py

The random initial-centroid helper, repeated convergence loop, heterogeneity recording, plotting, Iris demonstration, and report generation are outside this one-update workload.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`k_means_clust_oracle.py`](../../k_means_clust_oracle.py)

## Ports

| Language | Source |
| --- | --- |
| C | [`c/k/k_means_clust.c`](../../../c/k/k_means_clust.c) |
| C3 | [`c3/k/k_means_clust.c3`](../../../c3/k/k_means_clust.c3) |
| C++ | [`cpp/k/k_means_clust.cpp`](../../../cpp/k/k_means_clust.cpp) |
| Elisa | [`elisa/k/k_means_clust.elisa`](../../../elisa/k/k_means_clust.elisa) |
| Nim | [`nim/k/k_means_clust.nim`](../../../nim/k/k_means_clust.nim) |
| Odin | [`odin/k/k_means_clust.odin`](../../../odin/k/k_means_clust.odin) |
| Rust | [`rust/k/k_means_clust.rs`](../../../rust/k/k_means_clust.rs) |
| V | [`v/k/k_means_clust.v`](../../../v/k/k_means_clust.v) |
| Zig | [`zig/k/k_means_clust.zig`](../../../zig/k/k_means_clust.zig) |

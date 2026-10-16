# DBSCAN

This benchmark covers the common density-based clustering operation in the pinned Jupyter and Python implementations. The Jupyter version mutates a dictionary of 2D points and assigns cluster IDs from one; Python returns one label per point and begins cluster IDs at zero. Their seed worklists also differ, which can change ownership of a border point adjacent to two clusters. This contract makes expansion deterministic and reports labels in input order, so every port is evaluated against the same bounded behavior.

## Contract

- Pack `[point_count, epsilon, min_points, x0, y0, ...]` as signed 64-bit integers.
- Point count is `1..32`; epsilon and min_points are positive; coordinates are distinct and in `-1,000,000..1,000,000`; distinctness preserves the Jupyter dictionary-key input model.
- A point is a neighbor when squared Euclidean distance is at most `epsilon²`; min_points counts the point itself.
- Core points and neighbors are visited in input order. The first core point of each cluster determines its ID.
- Output is one byte per input point: `0` means noise, and `cluster_id + 1` means a cluster. The function returns the point count. Invalid input returns `-1`; insufficient output capacity returns `-2`.

Integer coordinates and epsilon preserve the exact Euclidean radius test without cross-language floating-point boundary differences. This is a bounded specialization of the source algorithm, not a claim that the upstream APIs accept only integer points.

The R file catalogued separately as `dbscan_clustering` only calls the external `dbscan` package on the Iris dataset and plots its result; it contains no DBSCAN implementation.

See [`workload.json`](workload.json) for separated clusters, noise, chained density reachability, inclusive radius boundaries, invalid inputs, and output-capacity handling. Verify with `python3 benchmarks/verify_i64_array_bytes_output.py --algorithm dbscan`.

## Sources

- [TheAlgorithms/Jupyter `dbscan.py`](https://github.com/TheAlgorithms/Jupyter/blob/ebf48b9d0373ae4accd1d2fad54ad173dbac9e9/machine_learning/dbscan/dbscan.py), commit `ebf48b9d0373ae4accd1d2fad54ad173dbac9e9`.
- [TheAlgorithms/Python `dbscan.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/dbscan.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

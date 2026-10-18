# Kohonen SOM topology update

This package applies one deterministic Kohonen self-organizing-map update to a single sample and a square 2-D grid of weight vectors. It follows the pinned C `kohonen_update_weights` routine and the equivalent C++ `machine_learning::update_weights` routine. Random initialization, file output, and the outer training schedule are outside this operation.

## Contract

The `float64_slice_io` input is `[map_size, feature_count, radius, alpha_code, sample..., weights_row_major...]`. The grid has `map_size` rows and columns, and weights are flattened in x, then y, then feature order. Exact input length is `4 + feature_count + map_size*map_size*feature_count`. Require map size 1–4, feature count 1–3, radius 0–8, `alpha_code` 1–16, and exact integer sample and weight values in `[-8,8]`. The source learning rate is `alpha_code/16`, keeping the bounded update arithmetic binary-exact.

For each grid cell in x-major then y order, sum squared coordinate differences in increasing feature order and take the square root. The best matching unit (BMU) is the first cell with the smallest Euclidean distance. Clip the inclusive-radius square neighborhood independently on both axes to `[max(0, BMU-radius), min(map_size, BMU+radius+1))`. For each selected cell and feature in increasing order, compute `scale = exp(-grid_distance_squared/(2*alpha*alpha))`, where `grid_distance_squared` is the squared x/y distance from the BMU, then update `W[x][y][k] += alpha*scale*(sample[k]-W[x][y][k])`.

The C and C++ helpers return the minimum Euclidean distance, which is the first output element, followed by the updated row-major weight matrix. Their distance scratch matrix `D` is omitted. The C++ helper obtains the y-grid width from `W[0][0].size()`; with the square map required here, that is the map width, independent of feature count. The C expression evaluates the update as `alpha*scale*(sample-weight)` while C++ groups `(sample-weight)*alpha*scale`; absolute and relative tolerances of `1e-12` cover this evaluation-order rounding.

Malformed framing, unsupported bounds, nonintegral values, or nonfinite output returns `-1` before output checks. A null output buffer or capacity below `1 + map_size*map_size*feature_count` returns `-2` without writes. The maximum valid input length is 55 values; one extra value is parseable so trailing data can be rejected. The maximum output length is 49 values.

## Pinned sources

- C [`kohonen_som_topology.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/machine_learning/kohonen_som_topology.c), commit `e5dad3fa8def3726ec850ca66a7f51521f8ad393`, symbol `kohonen_update_weights`.
- C++ [`kohonen_som_topology.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/machine_learning/kohonen_som_topology.cpp), commit `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`, symbol `machine_learning::update_weights`.
- C++-1 [`kohonen_som_topology.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/machine_learning/kohonen_som_topology.cpp), commit `0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680`.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`kohonen_som_topology_oracle.py`](../../kohonen_som_topology_oracle.py)

## Ports

| Language | Port |
|---|---|
| C | [`c/k/kohonen_som_topology.c`](../../../c/k/kohonen_som_topology.c) |
| C3 | [`c3/k/kohonen_som_topology.c3`](../../../c3/k/kohonen_som_topology.c3) |
| C++ | [`cpp/k/kohonen_som_topology.cpp`](../../../cpp/k/kohonen_som_topology.cpp) |
| Elisa | [`elisa/k/kohonen_som_topology.elisa`](../../../elisa/k/kohonen_som_topology.elisa) |
| Nim | [`nim/k/kohonen_som_topology.nim`](../../../nim/k/kohonen_som_topology.nim) |
| Odin | [`odin/k/kohonen_som_topology.odin`](../../../odin/k/kohonen_som_topology.odin) |
| Rust | [`rust/k/kohonen_som_topology.rs`](../../../rust/k/kohonen_som_topology.rs) |
| V | [`v/k/kohonen_som_topology.v`](../../../v/k/kohonen_som_topology.v) |
| Zig | [`zig/k/kohonen_som_topology.zig`](../../../zig/k/kohonen_som_topology.zig) |

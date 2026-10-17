# k-NN binary classification

This benchmark covers the pinned R implementation's classification path on one query. The caller supplies the training rows and query, so the source's Iris demonstration and random train/test split are excluded.

## Contract

The ABI is `i64_array_scalar`. Input is `[training_count, feature_count, k, training_features..., labels..., query_features...]`, with the training matrix in row-major order. There are 1–32 training rows, 1–8 features, and an odd `k` from 1 through the training count. Feature coordinates are signed integers in [-32, 32], interpreted as exact numeric values; each label is 0 or 1.

Adapters create factor labels with levels `"0"` and `"1"` in that order, then call the pinned training and prediction routines with `weighted=FALSE`, `normalize=FALSE`, `return_probs=FALSE`, and `return_neighbors=FALSE`. The source passes the query as matrix A and training rows as matrix B to `squared_euclidean_distances`, evaluating each squared distance in this order: `query_norm - 2*cross_product + training_row_norm`. It ranks those distances ascending, selects the first `k` neighbors, counts their factor labels, and returns the first maximum class. The contract requires every training row to have a distinct squared distance from the query; this removes dependence on R's ordering of equal distances. Since labels are binary and `k` is odd, the vote cannot tie. The scalar result is the predicted class ID, 0 or 1.

Malformed framing, unsupported bounds, nonbinary labels, an even or out-of-range `k`, or tied query distances return -1. Input length is exactly `3 + training_count*feature_count + training_count + feature_count` values. No output buffer is used.

## Pinned source

- R `knn_train` and `knn_predict`: https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/machine_learning/k-NN.r

The source's classification implementation is retained; regression, inverse-distance weighting, z-score normalization, optional neighbor/probability outputs, NA filtering, and the top-level Iris example are outside this bounded workload.

## Workload and oracle

- Workload: `workload.json`
- Oracle: `../../k_nn_oracle.py`

## Ports

| Language | Source |
| --- | --- |
| C | [`c/k/k_nn.c`](../../../c/k/k_nn.c) |
| C3 | [`c3/k/k_nn.c3`](../../../c3/k/k_nn.c3) |
| C++ | [`cpp/k/k_nn.cpp`](../../../cpp/k/k_nn.cpp) |
| Elisa | [`elisa/k/k_nn.elisa`](../../../elisa/k/k_nn.elisa) |
| Nim | [`nim/k/k_nn.nim`](../../../nim/k/k_nn.nim) |
| Odin | [`odin/k/k_nn.odin`](../../../odin/k/k_nn.odin) |
| Rust | [`rust/k/k_nn.rs`](../../../rust/k/k_nn.rs) |
| V | [`v/k/k_nn.v`](../../../v/k/k_nn.v) |
| Zig | [`zig/k/k_nn.zig`](../../../zig/k/k_nn.zig) |

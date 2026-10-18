# Kohonen SOM trace update

This package applies one deterministic Kohonen self-organizing-map update to a single sample and a 1-D chain of weight vectors. It follows the pinned C `kohonen_update_weights` routine and the equivalent C++ update routine. Random initialization, file output, and the outer training schedule are outside this operation. The `alpha_min` parameter and the C/C++ loop difference at `alpha_min >= 1` belong to that outer schedule and are outside this single-update contract.

## Contract

The `float64_slice_io` input is `[node_count, feature_count, radius, alpha_code, sample..., weights_row_major...]`. The exact length is `4 + feature_count + node_count*feature_count`. Require 1–8 nodes, 1–4 features, radius 0–8, `alpha_code` 1–16, and exact integer sample and weight values in `[-8,8]`. The source learning rate is `alpha_code/16`, keeping the bounded update arithmetic binary-exact.

For each node in increasing order, compute the sum of squared coordinate differences in increasing feature order. The best matching unit (BMU) is the first node with the smallest squared distance. The updated neighborhood is the clipped half-open interval `[max(0, BMU-radius), min(node_count, BMU+radius+1))`. For each selected node and feature in increasing order, update `W[node][feature] += alpha*(sample[feature]-W[node][feature])`.

The source helper writes per-node squared distances to its caller-supplied `D` vector. The benchmark wrapper supplies that scratch vector for BMU selection but exposes only the updated row-major weight matrix. The result code is the number of output elements, `node_count*feature_count`. Invalid framing or bounds returns `-1` before output checks. A null output buffer or capacity below the weight count returns `-2` without writes. Output values use absolute and relative tolerances of `1e-12`.

The maximum valid input length is 40 values; one extra value is parseable so trailing data can be rejected. The maximum output length is 32 values.

## Pinned sources

- C [`kohonen_som_trace.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/machine_learning/kohonen_som_trace.c), commit `e5dad3fa8def3726ec850ca66a7f51521f8ad393`, symbol `kohonen_update_weights`.
- C++ [`kohonen_som_trace.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/machine_learning/kohonen_som_trace.cpp), commit `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`, symbol `machine_learning::update_weights`.
- C++-1 [`kohonen_som_trace.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/machine_learning/kohonen_som_trace.cpp), commit `0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680`.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`kohonen_som_trace_oracle.py`](../../kohonen_som_trace_oracle.py)

## Ports

| Language | Port |
|---|---|
| C | [`c/k/kohonen_som_trace.c`](../../../c/k/kohonen_som_trace.c) |
| C3 | [`c3/k/kohonen_som_trace.c3`](../../../c3/k/kohonen_som_trace.c3) |
| C++ | [`cpp/k/kohonen_som_trace.cpp`](../../../cpp/k/kohonen_som_trace.cpp) |
| Elisa | [`elisa/k/kohonen_som_trace.elisa`](../../../elisa/k/kohonen_som_trace.elisa) |
| Nim | [`nim/k/kohonen_som_trace.nim`](../../../nim/k/kohonen_som_trace.nim) |
| Odin | [`odin/k/kohonen_som_trace.odin`](../../../odin/k/kohonen_som_trace.odin) |
| Rust | [`rust/k/kohonen_som_trace.rs`](../../../rust/k/kohonen_som_trace.rs) |
| V | [`v/k/kohonen_som_trace.v`](../../../v/k/kohonen_som_trace.v) |
| Zig | [`zig/k/kohonen_som_trace.zig`](../../../zig/k/kohonen_som_trace.zig) |

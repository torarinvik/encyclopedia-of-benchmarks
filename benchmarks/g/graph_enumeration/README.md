# Graph enumeration

This benchmark captures the pinned Rust utility that converts a graph with ordered labels into a 1-based dense adjacency representation.

## Contract

Input is a signed 64-bit vector `[n, labels..., (degree, neighbor_labels...)*]`. There are at most 16 unique labels in `[-1,000,000, 1,000,000]`. Each row is associated with its label's input position; each degree is 0 through 32, and every neighbor label must exist. Rows are emitted in ascending label order, matching `BTreeMap` iteration, with vertex IDs equal to each label's 1-based rank. Adjacency row order and duplicate neighbors are preserved. The output's row zero is empty.

The scalar result is the signed interpretation of FNV-1a over little-endian i64 values in `[n+1, 0, degree_1, mapped_neighbors..., ...]`. Invalid shape, duplicate labels, invalid degree, out-of-range labels, or unknown neighbors returns `-1`. The source panics for unknown neighbors; the bounded contract reports invalid input explicitly.

[`workload.json`](workload.json) covers unsorted labels, isolated vertices, duplicate neighbors, empty input, and invalid graphs.

## Pinned source

- [TheAlgorithms/Rust `graph_enumeration.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/graph_enumeration.rs)

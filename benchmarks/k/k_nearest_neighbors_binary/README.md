# Binary K-Nearest Neighbors

This package ports the reviewed C++, Python, and Rust K-nearest-neighbors classifiers for two classes.

## Contract

Input is a signed 64-bit array `[dimension, point_count, k, query_coordinates..., (training_coordinates..., class_id)...]`. Dimension is 1 through 8, there are 1 through 128 training points, and `k` is odd with `1 <= k <= point_count`. Coordinates are integers in `[-1000,1000]`; class IDs are 0 or 1. The array length must exactly match the declared dimension and point count.

The query's squared Euclidean distance to each training point must be distinct. This guarantees a strict gap at every neighbor rank, including the kth point, and removes source-specific distance tie behavior. Squared distance preserves the source's Euclidean ordering for these bounded coordinates. Because `k` is odd and labels are binary, the majority vote is unique.

Output is one little-endian signed i64 class ID (0 or 1). Success returns 8 bytes. Invalid input returns `-1`; a null or undersized output buffer returns `-2` without writing. The Python source returns a class-name string and the Rust source returns an f64 label; both are normalized to the class ID used by the C++ source.

## Pinned sources

- C++ [`machine_learning/k_nearest_neighbors.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/machine_learning/k_nearest_neighbors.cpp)
- C++ mirror [`machine_learning/k_nearest_neighbors.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/machine_learning/k_nearest_neighbors.cpp)
- Python [`machine_learning/k_nearest_neighbors.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/k_nearest_neighbors.py)
- Rust [`src/machine_learning/k_nearest_neighbors.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/machine_learning/k_nearest_neighbors.rs)

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm k_nearest_neighbors_binary --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/k/k_nearest_neighbors_binary/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/k/k_nearest_neighbors_binary.c`](../../../c/k/k_nearest_neighbors_binary.c) |
| C3 | [`c3/k/k_nearest_neighbors_binary.c3`](../../../c3/k/k_nearest_neighbors_binary.c3) |
| C++ | [`cpp/k/k_nearest_neighbors_binary.cpp`](../../../cpp/k/k_nearest_neighbors_binary.cpp) |
| Elisa | [`elisa/k/k_nearest_neighbors_binary.elisa`](../../../elisa/k/k_nearest_neighbors_binary.elisa) |
| Nim | [`nim/k/k_nearest_neighbors_binary.nim`](../../../nim/k/k_nearest_neighbors_binary.nim) |
| Odin | [`odin/k/k_nearest_neighbors_binary.odin`](../../../odin/k/k_nearest_neighbors_binary.odin) |
| Rust | [`rust/k/k_nearest_neighbors_binary.rs`](../../../rust/k/k_nearest_neighbors_binary.rs) |
| V | [`v/k/k_nearest_neighbors_binary.v`](../../../v/k/k_nearest_neighbors_binary.v) |
| Zig | [`zig/k/k_nearest_neighbors_binary.zig`](../../../zig/k/k_nearest_neighbors_binary.zig) |

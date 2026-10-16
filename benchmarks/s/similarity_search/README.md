# Similarity Search

This benchmark ports the nearest-vector search from the pinned `similarity_search.py` source.

## Contract

- Input is `[rows, queries, features, dataset_micro[rows*features], query_micro[queries*features]]`.
- Rows are 1 through 32, queries 1 through 8, features 1 through 16, and coordinates are signed micro-units in `[-1,000,000, 1,000,000]`.
- Coordinates are divided by 1,000,000 before distance calculation. Each query scans dataset rows in order and replaces the winner only on a strictly smaller Euclidean distance, preserving the first row on ties.
- Each query writes a record of little-endian `i64` row index, little-endian binary64 distance, and the selected row's original micro-coordinate `i64` values. Records have no header; total output is `queries * (16 + 8*features)` bytes, at most 1152.
- Invalid input returns `-1`; a null or short output buffer returns `-2` without writing.

The independent oracle is [`similarity_search_oracle.py`](../../similarity_search_oracle.py). The workload covers multiple queries, an ordered tie, signed coordinates, capacity failure, and malformed bounds/shapes.

## Pinned source

[TheAlgorithms/Python `machine_learning/similarity_search.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/similarity_search.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`, method `similarity_search(dataset, value_array)`.

## Implementations

| Language | Source |
| --- | --- |
| C | [similarity_search.c](../../../c/s/similarity_search.c) |
| C3 | [similarity_search.c3](../../../c3/s/similarity_search.c3) |
| C++ | [similarity_search.cpp](../../../cpp/s/similarity_search.cpp) |
| Elisa | [similarity_search.elisa](../../../elisa/s/similarity_search.elisa) |
| Nim | [similarity_search.nim](../../../nim/s/similarity_search.nim) |
| Odin | [similarity_search.odin](../../../odin/s/similarity_search.odin) |
| Rust | [similarity_search.rs](../../../rust/s/similarity_search.rs) |
| V | [similarity_search.v](../../../v/s/similarity_search.v) |
| Zig | [similarity_search.zig](../../../zig/s/similarity_search.zig) |

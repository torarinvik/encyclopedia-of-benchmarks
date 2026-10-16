# Wavelet tree rank, quantile, and range counting

This benchmark builds no mutable updates; it constructs a value-partitioned wavelet tree over a bounded integer sequence and evaluates rank, quantile, and value-range counting queries. These operations are distinct from index-partitioned segment-tree aggregates and static minimum queries.

## Contract

- Input is `[item_count, values..., query_count, (opcode, a, b, c, d)...]`.
- Item count is 1–64, query count is 0–128, and input values are in `[-1000, 1000]`.
- Opcode `0` counts occurrences of value `a` in inclusive prefix `[0, b]`; `b=-1` means an empty prefix.
- Opcode `1` returns zero-based quantile `c` in inclusive position range `[a, b]`.
- Opcode `2` counts values in inclusive value range `[c, d]` within inclusive position range `[a, b]`.
- Invalid dimensions, values, ranges, or opcodes return `-1`.
- The scalar result is the sum of each answer plus 1,000,001, weighted by its one-based query position.

Implementations split the actual value interval at its midpoint, stably partition each node's sequence, and store prefix counts of values sent left. Queries map positional boundaries through those prefix counts while descending the value tree. The bounded value domain has at most 12 levels. The pinned Python source implements these three query families; Java implements rank, select, and one-based kth-smallest. Select is omitted because Python does not provide it. This contract uses inclusive ranges and 0-based quantile indices, matching Python.

[`workload.json`](workload.json) includes duplicates, negative values, singleton and empty-query inputs, and invalid query parameters. `benchmarks/wavelet_tree_oracle.py` computes expected results independently.

## Reviewed source implementations

- [Java WaveletTree](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/WaveletTree.java)
- [Python wavelet_tree](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/wavelet_tree.py)

# Apriori association mining

This package implements the frequent-itemset stage in the pinned [TheAlgorithms/Jupyter association-mining notebook](https://github.com/TheAlgorithms/Jupyter/blob/ebf48b9d0373ae4caccd1d2fad54ad173dbac9e9/machine_learning/Associative%20Mining/Association.ipynb). The notebook reads grocery transactions, one-hot encodes them, and calls `mlxtend.frequent_patterns.apriori` with `min_support=0.01` and `use_colnames=True`.

## Contract

- Input is `[transaction_count, item_count, transaction_mask_0, ...]`, with one signed 64-bit mask per transaction. Bit `i` marks whether item `i` occurs in that transaction. Item positions follow the notebook's ascending item-column names.
- The bounded domain is 1–64 transactions and 1–11 items. A row mask may contain only the lowest `item_count` bits; input length must be exactly `2 + transaction_count`.
- Use the notebook's fixed minimum support `0.01`. In this bounded domain, a nonempty itemset is frequent exactly when its support count is at least one.
- Output each frequent itemset as two signed 64-bit little-endian integers: `[itemset_mask, support_count]`. The benchmark gives records a deterministic order: itemset cardinality, then mask ascending. This canonicalizes the notebook library's itemset representation while preserving every frequent set and its support. The support fraction displayed in the notebook is `support_count / transaction_count`.
- Return the output byte count, up to 32,752 bytes. Invalid input returns `-1`; insufficient output capacity returns `-2`; no frequent itemsets returns zero bytes.

The input bitmasks replace the notebook's external `grocery_data.csv` and Pandas one-hot table. The output pairs preserve the frequent itemsets and support values without Pandas formatting. The separate [`assignment_using_bitmask`](../assignment_using_bitmask/README.md) package counts task assignments and is not this algorithm.

[`workload.json`](workload.json) includes the pinned 20-transaction grocery example, small candidate-join/prune cases, support counts, empty output, malformed inputs, and insufficient capacity.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/association.c`](../../../c/a/association.c) |
| C3 | [`c3/a/association.c3`](../../../c3/a/association.c3) |
| C++ | [`cpp/a/association.cpp`](../../../cpp/a/association.cpp) |
| Elisa | [`elisa/a/association.elisa`](../../../elisa/a/association.elisa) |
| Nim | [`nim/a/association.nim`](../../../nim/a/association.nim) |
| Odin | [`odin/a/association.odin`](../../../odin/a/association.odin) |
| Rust | [`rust/a/association.rs`](../../../rust/a/association.rs) |
| V | [`v/a/association.v`](../../../v/a/association.v) |
| Zig | [`zig/a/association.zig`](../../../zig/a/association.zig) |

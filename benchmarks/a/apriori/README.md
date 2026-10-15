# Apriori Association Rules

This benchmark is based on the pinned [TheAlgorithms/R Apriori example](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/association_algorithms/apriori.r). That script calls `arules::apriori` with support `0.006`, confidence `0.25`, and minimum rule length 2 on a local grocery transaction file. The benchmark implements the levelwise Apriori candidate-pruning and association-rule counting directly, so it has no R, package, or external-dataset dependency.

The pinned [TheAlgorithms/Python Apriori source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/apriori_algorithm.py) also intends levelwise frequent-itemset mining. By inspection, it seeds candidates with complete transactions and then checks prior itemsets as transaction elements, so its candidate expansion does not form general itemset joins. This benchmark maps that source to the corrected Apriori implementation; it uses the association-rule count contract described below rather than reproducing the source's faulty candidate generation or its frequent-itemset list return type.

The `i64_array_scalar` input is `[transaction_count, item_count, min_support_ppm, min_confidence_ppm, transaction_mask_0, ...]`. Each transaction mask uses bits `0` through `item_count - 1` to identify present items. The input supports 1–64 transactions, 1–12 items, support from 1 to 1,000,000 parts per million, and confidence from 0 to 1,000,000 parts per million. The benchmark returns the number of association rules whose union is frequent and whose confidence meets the threshold. Rules have nonempty antecedent and consequent, so their union has at least two items. The source example's thresholds are encoded as `6000` and `250000`. Invalid input returns `-1`.

Support and confidence comparisons use integer cross multiplication, avoiding floating-point threshold rounding. Apriori generates a size-k candidate only when every size-(k-1) subset was frequent, counts its support across the transactions, then counts qualifying rules from each frequent itemset. Runtime is bounded by O(2^m × (m + t) + 3^m), where `m` is the item count and `t` is the transaction count; auxiliary space is O(2^m).

| Language | Implementation |
| --- | --- |
| C | [`c/a/apriori.c`](../../../c/a/apriori.c) |
| C3 | [`c3/a/apriori.c3`](../../../c3/a/apriori.c3) |
| C++ | [`cpp/a/apriori.cpp`](../../../cpp/a/apriori.cpp) |
| Elisa | [`elisa/a/apriori.elisa`](../../../elisa/a/apriori.elisa) |
| Nim | [`nim/a/apriori.nim`](../../../nim/a/apriori.nim) |
| Odin | [`odin/a/apriori.odin`](../../../odin/a/apriori.odin) |
| Rust | [`rust/a/apriori.rs`](../../../rust/a/apriori.rs) |
| V | [`v/a/apriori.v`](../../../v/a/apriori.v) |
| Zig | [`zig/a/apriori.zig`](../../../zig/a/apriori.zig) |

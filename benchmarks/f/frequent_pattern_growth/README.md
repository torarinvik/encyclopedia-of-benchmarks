# Frequent Pattern Growth

Count the nonempty frequent itemsets discovered by a bounded FP-growth traversal. The package follows the pinned Python source’s FP-tree conditional-pattern growth and makes the result deterministic.

## Contract

The signed integer input is `[transaction_count, item_count, minimum_support, transaction_mask...]`. Each transaction mask contains item bits `0` through `item_count - 1`. There are 1–64 transactions, 1–8 items, and an absolute minimum support from 1 through the transaction count. The output is the count of frequent nonempty itemsets. Invalid input returns `-1`.

The implementation orders items by descending singleton support, with item index as a tie breaker, and recursively grows conditional transaction projections. This yields each itemset once. It uses weighted conditional paths, preserving the path counts when constructing conditional databases. The pinned Python module’s `mine_tree` currently passes only the conditional path keys to `create_tree`, discarding those counts; the bounded contract repairs that loss and reports the number of itemsets rather than depending on Python set iteration order. It excludes FP-tree printing and the hard-coded demo.

This is distinct from the Apriori benchmark: Apriori generates candidates by levelwise subset joins and tests their support, while this package grows conditional pattern bases.

## Workload

[`workload.json`](workload.json) includes the pinned eight-transaction example, duplicate paths, support boundaries, maximum item count, and malformed inputs. The independent oracle enumerates subsets to validate the FP-growth count.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/frequent_pattern_growth.c`](../../../c/f/frequent_pattern_growth.c) |
| C3 | [`c3/f/frequent_pattern_growth.c3`](../../../c3/f/frequent_pattern_growth.c3) |
| C++ | [`cpp/f/frequent_pattern_growth.cpp`](../../../cpp/f/frequent_pattern_growth.cpp) |
| Elisa | [`elisa/f/frequent_pattern_growth.elisa`](../../../elisa/f/frequent_pattern_growth.elisa) |
| Nim | [`nim/f/frequent_pattern_growth.nim`](../../../nim/f/frequent_pattern_growth.nim) |
| Odin | [`odin/f/frequent_pattern_growth.odin`](../../../odin/f/frequent_pattern_growth.odin) |
| Rust | [`rust/f/frequent_pattern_growth.rs`](../../../rust/f/frequent_pattern_growth.rs) |
| V | [`v/f/frequent_pattern_growth.v`](../../../v/f/frequent_pattern_growth.v) |
| Zig | [`zig/f/frequent_pattern_growth.zig`](../../../zig/f/frequent_pattern_growth.zig) |

## Pinned source

[TheAlgorithms/Python `frequent_pattern_growth.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/frequent_pattern_growth.py)

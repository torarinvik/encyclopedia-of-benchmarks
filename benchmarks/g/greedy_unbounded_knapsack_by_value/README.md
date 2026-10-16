# Greedy unbounded knapsack by value

This benchmark ports Julia's `complete_pack!`: sort items by descending value, then repeatedly take each item while it fits before moving to the next value. Items are ordered by value alone, not by value-to-weight ratio, so this remains distinct from fractional knapsack and optimal unbounded-knapsack dynamic programming.

## Contract

- Input is `[capacity, item_count, values..., weights...]`, with `0..8` items, capacity `0..1,000,000`, values `0..1,000,000`, and weights `1..1,000,000`.
- Items are considered in descending value order, retaining input order for ties. Each item may be reused while it fits in the remaining capacity; then the next item is considered.
- Return the total value as a signed 64-bit integer. The input bounds keep the result below `10^12`.
- Malformed input returns `-1`.

The positive-weight restriction avoids the source routine's non-terminating zero-weight case. The paired `zero_one_pack!` routine in the same Julia file maps to [`greedy_item_selection_by_value`](../greedy_item_selection_by_value/README.md).

## Pinned source

- [TheAlgorithms/Julia `greedy_algorithm.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/knapsack/greedy_algorithm.jl)

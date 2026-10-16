# Greedy item selection by value

This benchmark preserves the pinned Python routine's stable descending-key sort and whole-item capacity scan. It is separate from ratio-based fractional knapsack: items are considered by value alone, and an item that does not fit is skipped while later items are still considered.

## Contract

- Input is `[capacity, item_count, values..., weights...]`, with `0..8` items, capacity `0..1,000,000`, values `0..1,000,000`, and weights `1..1,000,000`.
- Items are considered by descending value, with original input order retained for equal values. Add an item if its whole weight fits in the remaining capacity.
- The signed-64-bit result packs selected one-based input positions in four-bit slots, followed by the selected count in bits 32–35 and total selected value starting at bit 36. This retains the source's selection order and returned total value.
- Malformed input returns `-1`.

The input uses bounded integer value/weight pairs instead of Python object instances and a caller-supplied key function. It selects the same stable descending-value policy as the source's documented example.

## Pinned source

- [TheAlgorithms/Python `greedy.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/greedy.py)

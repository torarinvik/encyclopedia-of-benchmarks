# Maximum difference pair

Given a nonempty integer array, recursively find the pair of values `(small, big)` that maximizes `big - small` while the small value occurs no later than the big value. The source permits the same element at both positions, so the best difference is never negative.

## Contract

- Input is a packed signed-i64 array `[n, values...]`, with exact packing and no trailing fields.
- `n` is in `1..=128`; every value is in `[-1,000,000, 1,000,000]`.
- Output the chosen `small` and `big` values, in that order, as two little-endian signed-i64 words. A valid call returns 16 bytes.
- Malformed packing or out-of-domain values return `-1`; insufficient output capacity returns `-2`.

The ports preserve the pinned recursive split and comparison order. At each split they compare the left result, the cross pair `(min(left), max(right))`, and the right result. A right result wins only when strictly greater than both other differences; a left result wins only when strictly greater than the cross difference; ties otherwise select the cross pair. This preserves deterministic pair selection when several choices have the same difference.

This is related to `best_time_to_buy_and_sell_stock`, but returns the selected value pair and allows `i == j`. Consequently, decreasing inputs return a zero-difference singleton pair, while the stock benchmark returns a zero profit.

## Source

- [TheAlgorithms/Python `max_difference_pair.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/divide_and_conquer/max_difference_pair.py)

The bound keeps subtraction exact and safe in signed 64-bit arithmetic. The workload includes tie cases and singleton/decreasing arrays to expose the source's pair and equality behavior.

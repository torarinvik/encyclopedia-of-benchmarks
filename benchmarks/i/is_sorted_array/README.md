# Is a numeric array strictly increasing?

Checks adjacent values using the pinned TypeScript predicate. It returns false when an adjacent pair is equal or descending, so the input must be strictly increasing; this is stricter than a nondecreasing sortedness check.

## Contract

- Uses `i64_array_scalar` with the array values as the input sequence.
- The array has 0 through 100,000 elements. Each value is an integer in `[-(2^53-1), 2^53-1]`, so comparisons match exact JavaScript `Number` behavior.
- Returns 1 when every adjacent pair satisfies `arr[i] < arr[i+1]`, otherwise 0. Empty and single-element arrays return 1. Invalid lengths or values return `-1`.
- The source takes O(n) time and O(1) extra space, stopping at the first pair that is not strictly increasing.

Source: [TheAlgorithms TypeScript `other/is_sorted_array.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/other/is_sorted_array.ts).

The catalog's Lua `is_sorted` routine uses a generic comparator and accepts equal neighbors with its default comparator; the Python `is_sorted.py` checks binary-tree ordering. Neither has this exact array contract.

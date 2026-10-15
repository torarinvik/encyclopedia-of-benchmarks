# Longest Valid Parentheses with a Stack

This benchmark preserves the pinned JavaScript implementation's stack strategy: track unmatched opening-parenthesis positions, reset the segment boundary after an unmatched close, and measure each valid suffix when a close matches.

## Contract

- Input is an array of 0–4,096 signed 64-bit values encoding ASCII `(` as 40 and `)` as 41.
- Return the length of the longest contiguous, well-formed parenthesis substring. Return 0 when none exists, including empty input.
- Return `-1` for a value other than 40 or 41, or for an input longer than 4,096 values.
- The implementation uses O(n) time and O(n) local storage.

[`workload.json`](workload.json) uses the same inputs as the sibling dynamic-programming benchmark.

Build with the `i64_array_scalar` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm longest_valid_parentheses_stack --language rust
```

## Upstream source

- [TheAlgorithms/JavaScript `LongestValidParentheses.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/LongestValidParentheses.js)

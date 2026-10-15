# Factors

The pinned Dart, JavaScript, Python, Rust, and TypeScript sources enumerate positive divisors. They differ in validation, traversal order, and whether they scan every candidate or search divisor pairs up to the square root. The benchmark standardizes the result as an ascending comma-separated byte string for all nine target languages.

## Contract

- Input is a signed 64-bit integer `n` from 1 through 256.
- Return the positive divisors of `n`, each once, in ascending order, separated by commas with no trailing comma. For example, `12` returns `1,2,3,4,6,12`.
- Return `-1` outside the supported input range.
- Return `-2` when the caller's output buffer is too small; do not write to the buffer in that case.
- The largest result in the supported range is 54 bytes, so it fits the scalar byte-output ABI's 63-byte limit.

The nine portable ports use integer trial division. Their behavior depends only on standard integer operations, not CPU-specific instructions.

## Workload and verification

[`workload.json`](workload.json) covers one, prime and composite inputs, a highly composite input, the upper bound, and out-of-range signed values. [`benchmarks/verify_factors.py`](../../verify_factors.py) compares every value from 1 through 256 with a divisor oracle, checks invalid signed-64-bit boundaries and insufficient output capacities, and checks all 14 workload cases through the recorder. All nine languages passed 520 oracle cases each.

## Upstream sources

- [TheAlgorithms/Dart factors.dart](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/factors.dart)
- [TheAlgorithms/JavaScript Factors.js](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/Factors.js)
- [TheAlgorithms/Python factors.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/factors.py)
- [TheAlgorithms/Rust factors.rs](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/factors.rs)
- [TheAlgorithms/TypeScript factors.ts](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/factors.ts)

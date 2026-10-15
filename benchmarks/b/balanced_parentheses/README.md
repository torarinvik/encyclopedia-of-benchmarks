# Balanced Parentheses

Use a stack to check whether `()`, `[]`, and `{}` are properly nested. Characters outside those six brackets are ignored, matching the pinned source.

## Contract

- Input is a sequence of ASCII character codes, with maximum length 4096.
- Return `1` if all brackets close in the correct order and no opening bracket remains; otherwise return `0`.
- Lengths greater than 4096 return `-1`.
- The stack uses portable 64-bit values; no architecture-specific operations are used.

## Source

The pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/balanced_parentheses.py) uses a stack, supports all three bracket pairs, ignores other characters, and treats the empty string as balanced. The benchmark passes ASCII codes through the shared read-only integer-array ABI.

Build and record with the shared array-scalar ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm balanced_parentheses --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/b/balanced_parentheses/rust/build.json
```

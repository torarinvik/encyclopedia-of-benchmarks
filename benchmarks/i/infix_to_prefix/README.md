# Infix to prefix conversion

Convert an infix expression to prefix notation using the pinned stack-based conversion approach. The measured operation returns the prefix expression as raw ASCII bytes, without a trailing NUL byte.

## Contract

- The input is a signed 64-bit array of ASCII byte values. Its length is 0 through 256.
- Empty input returns empty output.
- A nonempty valid expression is either one ASCII letter or digit, or an exactly parenthesized binary expression `(left<op>right)`, where each child is another valid expression and `<op>` is one of `+ - * / ^`.
- Whitespace, unary operators, multi-character operands, and all other bytes are invalid. Fully parenthesized expressions remove precedence and associativity ambiguity between the source variants.
- The result is the prefix spelling with parentheses omitted. Valid calls return its byte length. Invalid lengths, bytes, or expression structure return `-1`; insufficient output capacity returns `-2`.
- Conversion takes O(n) time and O(n) auxiliary space.

## Source and normalization

The canonical source is Java's `InfixToPrefix.infix2Prefix`, which trims outer whitespace, reverses the expression, converts with an operator stack, then reverses the result. The related Python candidate `infix_to_prefix_conversion` uses the same reverse-and-stack method, but its helper also recognizes `%` and its precedence handling differs on unparenthesized equal-precedence chains. This benchmark excludes those inputs. Both sources agree on the documented grammar, including the empty result.

The existing `infix_to_postfix` benchmark returns postfix notation. This package returns prefix notation for the same bounded expression family.

- [TheAlgorithms/Java pinned `InfixToPrefix.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/InfixToPrefix.java)
- [TheAlgorithms/Python pinned `infix_to_prefix_conversion.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/infix_to_prefix_conversion.py)

## Workload and recording

[`workload.json`](workload.json) includes empty and single-operand expressions, nested operators, digits, malformed structures, unsupported operators, and an invalid byte. The nine ports use the shared `i64_array_bytes_output` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm infix_to_prefix --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm infix_to_prefix
```

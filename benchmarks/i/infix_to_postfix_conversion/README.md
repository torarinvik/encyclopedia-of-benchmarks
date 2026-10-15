# Infix to Postfix Conversion

This package benchmarks the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/infix_to_postfix_conversion.py). It applies the shunting-yard algorithm with precedence `+` and `-` < `*` and `/` < `^`. All operators are left-associative except `^`, which is right-associative. Output tokens are separated by one ASCII space.

The `i64_array_bytes_output` ABI accepts `[length, ASCII bytes...]`, with expression length from 0 through 256. The bounded grammar has single ASCII alphanumeric operands, binary `+ - * / ^` operators, balanced parentheses, no whitespace, no unary operators, and no implicit multiplication. Empty input produces the empty string, encoded as one NUL byte. Nonempty results are likewise NUL-terminated; the reported output length includes that byte. Invalid packed input or expressions return `-1`; insufficient output capacity returns `-2`.

This contract differs from the existing `infix_to_postfix` benchmark: that package preserves a Rust implementation whose `^` is left-associative and whose output has no spaces. For example, `2^3^2` becomes `2 3 2 ^ ^` here. The pinned Python source first checks balanced parentheses and joins its one-character operand/operator tokens with spaces; this benchmark restricts Python's Unicode character classes to ASCII for portable byte input.

Runtime and auxiliary space are O(n), where n is the expression length. The output buffer bound is `2*n` bytes for nonempty valid inputs, including the NUL terminator.

The shared `run_i64_array_bytes_output.py` runner checks each expression against the bounded shunting-yard oracle before timing.

# Binary palindrome check

Checks whether the significant binary representation of a signed 32-bit integer reads the same in both directions. The implementations reverse the significant bits of nonnegative inputs and compare the result with the input.

## Contract

- Uses the signed 64-bit scalar ABI: `int64_t binary_palindrome_check(int64_t input)`.
- Inputs in `[-2,147,483,648, 2,147,483,647]` are valid.
- Negative signed 32-bit values return `0`. Nonnegative values return `1` when their significant binary digits are a palindrome and `0` otherwise. Zero returns `1`.
- Inputs outside the signed 32-bit range return `-1`.
- Results are encoded as `1` for palindrome and `0` for not palindrome.

## Source semantics

The benchmark follows the pinned [TheAlgorithms Java `BinaryPalindromeCheck`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/BinaryPalindromeCheck.java). The source accepts Java `int`. Its helper reverses bits only while `x > 0`, so zero returns true (`0 == 0`) and negative values return false (the helper returns zero). For positive values, reversing the significant bits and comparing is equivalent to checking the binary representation without leading zeroes. The ports preserve those edge cases.

## Workload and build

[`workload.json`](workload.json) covers zero, negative inputs, powers of two, known palindromic bit patterns, signed 32-bit boundaries, and out-of-range values. Build and record using the scalar ABI:

```sh
python3 benchmarks/build_scalar.py --algorithm binary_palindrome_check --language c
python3 benchmarks/run_scalar.py --algorithm binary_palindrome_check
```

The nine implementations are in `c/b/binary_palindrome_check.c`, `c3/b/binary_palindrome_check.c3`, `cpp/b/binary_palindrome_check.cpp`, `elisa/b/binary_palindrome_check.elisa`, `nim/b/binary_palindrome_check.nim`, `odin/b/binary_palindrome_check.odin`, `rust/b/binary_palindrome_check.rs`, `v/b/binary_palindrome_check.v`, and `zig/b/binary_palindrome_check.zig`.

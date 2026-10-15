# Almost palindrome checker

Determine whether a lowercase ASCII string is already a palindrome or can become one after deleting at most one character. This is a distinct contract from [`valid_palindrome`](../../v/valid_palindrome/README.md): that benchmark ignores punctuation and folds ASCII case, while this one compares lowercase letters directly and permits a single deletion.

## Contract

- Input is an array of signed 64-bit integers representing lowercase ASCII letters (`97` through `122`), with length 0 through 100,000.
- Return `1` if the input is a palindrome or one deletion can make it a palindrome; return `0` otherwise. Empty input returns `1`, matching the source function's two-pointer loop.
- Inputs outside the length or lowercase-letter bounds return `-1`.
- The implementation scans inward from both ends. At the first mismatch, it checks the remaining range after skipping either the left or right character. Time is `O(n)`; auxiliary space is `O(1)`.

## Reviewed Ruby source

The pinned Ruby source uses two pointers and, at the first mismatch, calls a helper on the range with either side skipped. Its examples cover an exact palindrome, a string made palindromic by one deletion, and a string that needs more than one deletion. The benchmark ports that rule and uses a length-prefixed ASCII array so embedded storage and character handling are consistent across languages.

- [TheAlgorithms/Ruby `almost_palindrome_checker.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/strings/almost_palindrome_checker.rb)

## Workload and recording

`workload.json` covers empty and singleton inputs, odd/even palindromes, successful deletion from either side, impossible cases, invalid characters, and a 4,096-letter input. The nine language ports use the shared `i64_array_scalar` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm almost_palindrome_checker --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/a/almost_palindrome_checker/rust/build.json
```

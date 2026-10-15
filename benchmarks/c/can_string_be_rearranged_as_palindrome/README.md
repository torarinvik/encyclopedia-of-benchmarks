# Can String Be Rearranged as Palindrome

Count character frequencies and determine whether at most one frequency is odd. This asks whether some rearrangement can be a palindrome. [`valid_palindrome`](../../v/valid_palindrome/README.md) instead checks whether the current order is already a palindrome.

## Contract

The `i64_array_scalar` function receives the text as an array of signed 64-bit ASCII values. The input must contain 1 through 4,096 lowercase English letters (`a` through `z`). It returns `1` when the letters can be rearranged into a palindrome and `0` otherwise. Empty input, uppercase letters, spaces, non-ASCII values, and all other symbols return `-1`.

This bounded alphabet makes the pinned Python and JavaScript predicates equivalent: the Python source removes spaces and lowercases characters, while the JavaScript source counts exact characters and returns a non-boolean string for empty input. On nonempty lowercase ASCII-letter input, both count the same characters and accept exactly when no more than one count is odd. The contract excludes inputs where their preprocessing or empty-input behavior differs.

[`workload.json`](workload.json) includes single-letter, even-frequency, one-odd, multiple-odd, maximum-length, empty, and invalid-alphabet cases.

## Implementations

The nine portable implementations are in [`c/c/can_string_be_rearranged_as_palindrome.c`](../../../c/c/can_string_be_rearranged_as_palindrome.c), [`c3/c/can_string_be_rearranged_as_palindrome.c3`](../../../c3/c/can_string_be_rearranged_as_palindrome.c3), [`cpp/c/can_string_be_rearranged_as_palindrome.cpp`](../../../cpp/c/can_string_be_rearranged_as_palindrome.cpp), [`elisa/c/can_string_be_rearranged_as_palindrome.elisa`](../../../elisa/c/can_string_be_rearranged_as_palindrome.elisa), [`nim/c/can_string_be_rearranged_as_palindrome.nim`](../../../nim/c/can_string_be_rearranged_as_palindrome.nim), [`odin/c/can_string_be_rearranged_as_palindrome.odin`](../../../odin/c/can_string_be_rearranged_as_palindrome.odin), [`rust/c/can_string_be_rearranged_as_palindrome.rs`](../../../rust/c/can_string_be_rearranged_as_palindrome.rs), [`v/c/can_string_be_rearranged_as_palindrome.v`](../../../v/c/can_string_be_rearranged_as_palindrome.v), and [`zig/c/can_string_be_rearranged_as_palindrome.zig`](../../../zig/c/can_string_be_rearranged_as_palindrome.zig).

## Upstream references

- [Python can-string-be-rearranged-as-palindrome](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/can_string_be_rearranged_as_palindrome.py)
- [JavaScript CheckRearrangePalindrome](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/CheckRearrangePalindrome.js)

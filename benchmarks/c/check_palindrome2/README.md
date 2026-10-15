# PHP palindrome message

This benchmark preserves the default `checkPalindromeString` behavior from the pinned PHP source, including its returned message.

## Contract

- `i64_array_bytes_output` encodes an input string as ASCII byte values from 32 through 126. Inputs contain at most 1,024 bytes.
- Trim leading and trailing ASCII spaces. If the result is empty or exactly `0`, return `-1`, representing the source exception.
- Lowercase ASCII letters, compare the normalized bytes with their reverse, and return the normalized text followed by ` - a palindrome string.\n` or ` - not a palindrome string.\n`.
- The package fixes the default `caseInsensitive=true` argument and normalizes `PHP_EOL` to LF for deterministic byte output.
- Values outside printable ASCII or inputs over 1,024 bytes return `-1`; insufficient output capacity returns `-2`.

The source reverses the complete trimmed string, so spaces and punctuation inside the string remain significant. It does not remove punctuation or internal spaces. [`workload.json`](workload.json) covers trimmed and mixed-case inputs, palindrome and non-palindrome messages, the two source exception cases, and invalid byte values.

This message-returning PHP routine is distinct from the boolean palindrome predicates.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/check_palindrome2.c`](../../../c/c/check_palindrome2.c) |
| C3 | [`c3/c/check_palindrome2.c3`](../../../c3/c/check_palindrome2.c3) |
| C++ | [`cpp/c/check_palindrome2.cpp`](../../../cpp/c/check_palindrome2.cpp) |
| Elisa | [`elisa/c/check_palindrome2.elisa`](../../../elisa/c/check_palindrome2.elisa) |
| Nim | [`nim/c/check_palindrome2.nim`](../../../nim/c/check_palindrome2.nim) |
| Odin | [`odin/c/check_palindrome2.odin`](../../../odin/c/check_palindrome2.odin) |
| Rust | [`rust/c/check_palindrome2.rs`](../../../rust/c/check_palindrome2.rs) |
| V | [`v/c/check_palindrome2.v`](../../../v/c/check_palindrome2.v) |
| Zig | [`zig/c/check_palindrome2.zig`](../../../zig/c/check_palindrome2.zig) |

## Upstream source

- [TheAlgorithms PHP `CheckPalindrome2.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Strings/CheckPalindrome2.php)

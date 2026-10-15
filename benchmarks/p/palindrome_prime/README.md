# Palindrome Prime Generation

Generate the first `n` palindromic primes in ascending order. The sequence begins `2, 3, 5, 7, 11, 101, ...`; each value is both prime and equal to its decimal digit reversal.

## Contract

- Input is one signed 64-bit integer `n`.
- For `n <= 0`, return an empty sequence, matching the pinned Java generator.
- For `1 <= n <= 16`, return the first `n` palindromic primes.
- Inputs above 16 return `-1` under this benchmark's bounded contract; the pinned source itself has no count limit.
- Each output value is encoded as a 4-byte little-endian unsigned integer, concatenated without separators. The return value is the number of output bytes. The maximum output is 64 bytes.
- The source class also exposes prime and reverse helpers; the benchmark measures its public `generatePalindromePrimes(n)` list operation.

## Workload and measurement

[`workload.json`](workload.json) covers empty output, initial values, representative sequence lengths, the maximum valid count, and an oversized count. The scalar byte-output runner checks the packed sequence before timing calls.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/palindrome_prime.c`](../../../c/p/palindrome_prime.c) |
| C3 | [`c3/p/palindrome_prime.c3`](../../../c3/p/palindrome_prime.c3) |
| C++ | [`cpp/p/palindrome_prime.cpp`](../../../cpp/p/palindrome_prime.cpp) |
| Elisa | [`elisa/p/palindrome_prime.elisa`](../../../elisa/p/palindrome_prime.elisa) |
| Nim | [`nim/p/palindrome_prime.nim`](../../../nim/p/palindrome_prime.nim) |
| Odin | [`odin/p/palindrome_prime.odin`](../../../odin/p/palindrome_prime.odin) |
| Rust | [`rust/p/palindrome_prime.rs`](../../../rust/p/palindrome_prime.rs) |
| V | [`v/p/palindrome_prime.v`](../../../v/p/palindrome_prime.v) |
| Zig | [`zig/p/palindrome_prime.zig`](../../../zig/p/palindrome_prime.zig) |

## Source

The pinned [TheAlgorithms/Java implementation](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PalindromePrime.java) generates the list by testing successive odd values with its palindrome-reversal and primality helpers. The count bound is imposed by this benchmark so the packed output stays within the shared byte-output ABI.

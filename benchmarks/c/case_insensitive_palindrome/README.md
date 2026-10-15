# Case-insensitive palindrome

Check whether an ASCII sequence reads the same in either direction after folding only ASCII uppercase letters to lowercase. Every other code point, including punctuation, spaces, digits, and control characters, remains significant. This matches the pinned Julia string implementation on the benchmark's ASCII domain.

## Contract

- Input is an array of at most 4,096 signed 64-bit values, each from 0 through 127.
- Fold `A` through `Z` to `a` through `z`; leave all other values unchanged.
- Return `1` when the folded sequence is a palindrome, `0` otherwise, and `-1` for invalid values or an oversized input. Empty and single-value inputs are palindromes.

Each implementation validates the complete input before comparing mirrored values. It uses O(n) time and O(1) auxiliary space. The length-prefixed array represents ASCII exactly across the nine language ABIs, including embedded NUL values.

## Source and workload

The pinned Julia [`is_palindrome.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/strings/is_palindrome.jl) lowercases the input string and compares it with its reversal. This benchmark limits the source's Unicode string domain to ASCII and defines case folding explicitly for portability.

[`workload.json`](workload.json) covers empty and single-value inputs, mixed ASCII case, punctuation, digits, controls, mismatches, and invalid bounds. All ports use the shared `i64_array_scalar` ABI.

| Language | Source |
| --- | --- |
| C | [`c/c/case_insensitive_palindrome.c`](../../../c/c/case_insensitive_palindrome.c) |
| C3 | [`c3/c/case_insensitive_palindrome.c3`](../../../c3/c/case_insensitive_palindrome.c3) |
| C++ | [`cpp/c/case_insensitive_palindrome.cpp`](../../../cpp/c/case_insensitive_palindrome.cpp) |
| Elisa | [`elisa/c/case_insensitive_palindrome.elisa`](../../../elisa/c/case_insensitive_palindrome.elisa) |
| Nim | [`nim/c/case_insensitive_palindrome.nim`](../../../nim/c/case_insensitive_palindrome.nim) |
| Odin | [`odin/c/case_insensitive_palindrome.odin`](../../../odin/c/case_insensitive_palindrome.odin) |
| Rust | [`rust/c/case_insensitive_palindrome.rs`](../../../rust/c/case_insensitive_palindrome.rs) |
| V | [`v/c/case_insensitive_palindrome.v`](../../../v/c/case_insensitive_palindrome.v) |
| Zig | [`zig/c/case_insensitive_palindrome.zig`](../../../zig/c/case_insensitive_palindrome.zig) |

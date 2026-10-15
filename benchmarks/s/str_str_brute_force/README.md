# String Search by Brute Force

This benchmark returns the first occurrence of a pattern in a text using a direct scan. C LeetCode 28 contains both a brute-force `strStr` definition and a second `strStr` definition that uses KMP; this benchmark records the brute-force variant, while the KMP variant is covered by the existing [Knuth–Morris–Pratt benchmark](../../k/knuth_morris_pratt/README.md).

## Contract

- Input is `[text_length, pattern_length, text_bytes..., pattern_bytes...]` in the signed 64-bit array ABI.
- Text and pattern are each at most 1,024 bytes. Bytes must be nonzero ASCII values from 1 through 127, matching the source's NUL-terminated string domain.
- Return the first matching byte index, `0` for an empty pattern, and `-1` for no match or malformed packed input.
- The search checks every possible starting position and compares pattern bytes until a mismatch or a full match. Its worst-case time is O(text length × pattern length).

The source file defines `strStr` twice, so it cannot be compiled as-is. The benchmark preserves the first, explicitly labeled brute-force implementation as this standalone algorithm and maps the second implementation to the existing KMP benchmark.

Run `python3 benchmarks/verify_str_str_brute_force.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to check all nine ports against exhaustive short byte strings, random cases, maximum-length near-matches, and malformed packed inputs.

## Implementations

The portable ports are [`c/s/str_str_brute_force.c`](../../../c/s/str_str_brute_force.c), [`c3/s/str_str_brute_force.c3`](../../../c3/s/str_str_brute_force.c3), [`cpp/s/str_str_brute_force.cpp`](../../../cpp/s/str_str_brute_force.cpp), [`elisa/s/str_str_brute_force.elisa`](../../../elisa/s/str_str_brute_force.elisa), [`nim/s/str_str_brute_force.nim`](../../../nim/s/str_str_brute_force.nim), [`odin/s/str_str_brute_force.odin`](../../../odin/s/str_str_brute_force.odin), [`rust/s/str_str_brute_force.rs`](../../../rust/s/str_str_brute_force.rs), [`v/s/str_str_brute_force.v`](../../../v/s/str_str_brute_force.v), and [`zig/s/str_str_brute_force.zig`](../../../zig/s/str_str_brute_force.zig). They use generic compiler targets without architecture-specific instructions.

## Upstream reference

- [C LeetCode 28](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/28.c)
- [C++ `brute_force_string_searching.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/strings/brute_force_string_searching.cpp)
- [C++ (additional repository) `brute_force_string_searching.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/strings/brute_force_string_searching.cpp)

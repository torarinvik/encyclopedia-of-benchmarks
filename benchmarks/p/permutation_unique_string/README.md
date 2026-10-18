# Unique string permutations

This package covers the C# GetEveryUniquePermutation variant from the broader permutation candidate. It returns unique string anagrams; the Java array enumerator and Julia nPr count remain separate packages.

## Contract

The i64_array_bytes_output input is [length, char_code...], with length in 0..5 and each character a printable ASCII code in 32..126. Repeated characters are allowed. The result is a byte stream containing the unique permutation count in its first byte, followed by each permutation as exactly length ASCII bytes in ascending ordinal lexicographic order. The count byte makes the empty-string case unambiguous: the source returns one permutation, the empty string.

The pinned C# method recursively removes each character, prepends it to each suffix permutation, and unions the results in a HashSet<string>. The set removes duplicate strings, but HashSet enumeration order is not a portable source guarantee. The benchmark therefore canonicalizes that set into ordinal ASCII order for stable cross-language output while preserving the source's unique-string contents. At most 5! = 120 permutations are emitted, for at most 601 output bytes.

Malformed input, out-of-range characters, or malformed framing return -1. A null or undersized output buffer returns -2 after input validation and performs no writes.

## Pinned source

The source is Permutation.GetEveryUniquePermutation in [TheAlgorithms/C-Sharp at commit 96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Strings/Permutation.cs).

See the [workload](workload.json) and [oracle](../../permutation_unique_string_oracle.py).

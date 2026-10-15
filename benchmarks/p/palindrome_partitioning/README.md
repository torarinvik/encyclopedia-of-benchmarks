# Palindrome Partitioning

Find the minimum number of cuts that split a nonempty string into palindromic substrings.

## Contract

- Input is a signed 64-bit array of ASCII byte values, with no length prefix. The array length is the string length and must be from 1 through 256. Values from 0 through 127 are accepted, including NUL and whitespace; comparisons are case-sensitive. Invalid input returns -1.
- Output is one little-endian signed 64-bit integer containing the minimum cut count. The function returns 1, the number of output values. A null or undersized output buffer returns -2 without writing.
- The shared nonempty domain matches the C++, Python, and Kotlin sources, which do not handle empty strings consistently. The Rust source returns zero for an empty string, but that case is excluded from this shared contract.
- The ports use the end-index dynamic program: mark palindromic ranges using their endpoints and previously computed inner ranges, then minimize cuts for each prefix. This yields O(n²) time and O(n²) space.

The JavaScript source enumerates all palindrome partitions and is covered separately by palindrome_partitioning_all_partitions.

## Pinned sources

- [TheAlgorithms/C-Plus-Plus](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/palindrome_partitioning.cpp)
- [TheAlgorithms/Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/palindrome_partitioning.py)
- [TheAlgorithms/Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/palindrome_partitioning.rs)
- [TheAlgorithms/Kotlin](https://github.com/TheAlgorithms/Kotlin/blob/b913c1d85c972fd1e679c5d832d6458b21be8fb0/src/main/kotlin/dynamicProgramming/PalindromePartitioning.kt)

## Implementations

Portable ports use `c/`, `c3/`, `cpp/`, `elisa/`, `nim/`, `odin/`, `rust/`, `v/`, and `zig/`, with the `i64_array_bytes_output` ABI family.

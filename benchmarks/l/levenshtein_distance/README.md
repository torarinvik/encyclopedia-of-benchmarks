# Levenshtein distance

This benchmark computes the unit-cost Levenshtein distance between two ASCII byte sequences. The inspected upstream implementations use dynamic programming with insertion, deletion, and substitution costs of one; TheAlgorithms/Go exposes configurable costs, so its source algorithm is benchmarked with all three costs fixed at one. Adjacent transpositions remain two edits, which distinguishes this benchmark from Damerau–Levenshtein distance.

## Contract

- The read-only input array packs two strings as `[left_length, right_length, left_ascii_bytes..., right_ascii_bytes...]`.
- Each length is from 0 through 255, each byte is from 0 through 127, and the packed array must have exactly `2 + left_length + right_length` values.
- The function returns the minimum number of single-byte insertions, deletions, and substitutions. Equal bytes cost zero; each edit costs one.
- Invalid packed input returns `-1`.
- The implementation uses one dynamic-programming row with a fixed 256-element local buffer. It allocates no memory and does not modify the input.

The ASCII restriction makes byte-based, UTF-16, and character-indexed upstream sources agree on character boundaries. All nine ports use the same recurrence and portable integer operations.

TheAlgorithms source matches were found in C-Sharp, F-Sharp, Java, JavaScript, Nim, Python, Rust, Lua, R, and Go. The C++ `edit_distance` dynamic-programming source, Java and Kotlin variants, JavaScript recurrence, Python top-down and bottom-up variants, and Zig implementation all use the same unit-cost insertion, deletion, and substitution recurrence and are recorded as aliases of this contract. The Lua `levenshtein`, Go `levenshteindistance`, and standard `levenshtein_distance` names are cataloged as one algorithm. See the pinned [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/edit_distance.cpp), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/EditDistance.js), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/edit_distance.py), and [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/dynamicProgramming/editDistance.zig) sources. Damerau–Levenshtein remains a separate candidate because it supports adjacent transpositions.

## Workload

`workload.json` contains 12 published cases for empty inputs, identical strings, substitutions, insertions, deletions, repeated bytes, a classic word pair, adjacent transposition, and lengths near the supported maximum. Correctness verification additionally checks every pair of binary-alphabet strings up to length five, 512 deterministic random pairs, malformed packed inputs, and the 255-byte boundary.

## Run

Build with the `i64_array_scalar` ABI family and record with `benchmarks/run_i64_array_scalar.py`. `benchmarks/verify_levenshtein_distance.py` compares all nine ports against an independent Python dynamic-programming oracle and checks each published result record.

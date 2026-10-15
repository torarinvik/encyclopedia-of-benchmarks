# Abbreviation

This benchmark checks whether a source string can be transformed into a target string by capitalizing any lowercase source letter that is kept and deleting any lowercase source letter that is not kept. Uppercase source letters must be kept unchanged. This is the dynamic-programming problem implemented by the inspected TheAlgorithms sources.

## Contract

- The read-only `i64_array_scalar` input packs two strings as `[source_length, target_length, source_ascii_bytes..., target_ascii_bytes...]`.
- Each string is at most 128 ASCII letters. Source letters may be uppercase or lowercase; target letters must be uppercase. The packed input must contain exactly `2 + source_length + target_length` values.
- Return `1` when the transformation is possible, `0` when it is not, and `-1` for malformed input.
- The implementation uses two fixed 129-element Boolean rows, takes O(source length × target length) time, allocates no memory, and does not modify the input.

ASCII letters give every language the same capitalization and indexing rules. All nine ports use the same recurrence and portable integer operations.

## Workload

`workload.json` covers canonical positive and negative examples, deletable lowercase letters, mandatory uppercase letters, empty strings, malformed bytes and target case, and the maximum supported lengths.

## Sources

- [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/abbreviation.cpp)
- [Additional C++ repository](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/dynamic_programming/abbreviation.cpp)
- [Go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/dynamic/abbreviation.go)
- [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/Abbreviation.java)
- [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/Abbreviation.js)
- [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/abbreviation.py)

## Run

Build with `python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm abbreviation --language LANGUAGE` and record with `python3 benchmarks/run_i64_array_scalar.py --algorithm abbreviation`.

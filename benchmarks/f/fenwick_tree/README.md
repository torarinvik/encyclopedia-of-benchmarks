# Fenwick tree

This benchmark maintains a signed integer array with point additions and inclusive range-sum queries using a Fenwick tree (binary indexed tree).

## Contract

- Input is `[item_count, operation_count, opcode, first, second, ...]` with one triple per operation.
- Item count is 1 through 256; operation count is 0 through 512.
- Opcode `0` adds `second` to element `first`. Opcode `1` returns the sum over the inclusive range `[first, second]`.
- Update deltas are bounded to -1,000,000 through 1,000,000. Query endpoints must satisfy `0 <= first <= second < item_count`. Invalid traces return `-1`.
- The signed 64-bit scalar result is a weighted checksum of range sums and final array values. The offsets keep valid results nonnegative and all intermediate values within signed 64-bit range.
- Implementations use a one-based internal Fenwick array, low-bit index traversal, bounded storage, and portable integer operations.

## Workload and verification

[`workload.json`](workload.json) covers empty operation streams, point and repeated updates, negative values, full and partial ranges, the maximum array length, and malformed traces. [`verify_fenwick_tree.py`](../../verify_fenwick_tree.py) compares the nine ports against a direct-array oracle over exhaustive short traces, deterministic random traces, boundary inputs, and malformed data.

## Reviewed TheAlgorithms sources

The seven pinned implementations in C++ (two repositories), Java, JavaScript, Julia, Python, and Rust share point additions and prefix or range sums. Their indexing and query APIs vary: the C++ and Rust trees use zero-based public indices with a one-based internal array; Java and JavaScript expose prefix queries; Julia exposes range sums; Python additionally has point assignment and half-open ranges. The benchmark standardizes point addition and inclusive range queries.

- [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/range_queries/fenwick_tree.cpp) and [the additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/range_queries/fenwick_tree.cpp) provide point additions and range sums.
- [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/FenwickTree.java) and [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Trees/FenwickTree.js) provide point additions and prefix sums.
- [Julia](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/data_structures/fenwick_tree.jl) provides construction, range sums, and additive updates.
- [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/fenwick_tree.py) and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/fenwick_tree.rs) provide point additions and range queries; Python also provides point assignment.

## Implementations

The nine portable ports use the shared `i64_array_scalar` ABI. Their source files are in the `f` folder for each language.

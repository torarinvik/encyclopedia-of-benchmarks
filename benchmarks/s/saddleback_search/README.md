# Saddleback search

This benchmark searches a row-major encoded integer matrix with the staircase
algorithm. The candidate C++, Rust, and Java sources all search a matrix sorted
in both dimensions. The C++ and Rust versions begin at the top-right corner;
Java begins at the bottom-left. The benchmark uses strictly increasing rows
and columns and globally unique values, so both traversal directions identify
the same cell. C++ and Rust return one-based coordinates; Java returns
zero-based coordinates and (-1, -1) when absent. The adapter shifts Java's
found coordinates by one before encoding them and maps its absence sentinel to
zero.

## Contract

- Input is a signed 64-bit array [rows, columns, target, row-major values...].
- Rows and columns are each in 1..32. Matrix values and target fit signed
  32-bit integers, matching the source APIs.
- The matrix is rectangular and strictly increasing across every row and
  column. Values are globally unique.
- A found coordinate (row, column) is encoded as
  row * columns + column + 1, using zero-based row and column indices. Zero
  means the target is absent. Malformed shapes or out-of-range values return
  -1.
- Monotonic ordering and global uniqueness are input preconditions; behavior
  outside that matrix domain is unspecified. The scalar ordinal decodes to the
  normalized one-based pair
  ((ordinal - 1) / columns + 1, (ordinal - 1) % columns + 1).
- The staircase search takes O(rows + columns) comparisons and O(1) extra
  space.

The workload includes rectangular and one-dimensional matrices, hits at
different corners and interior positions, misses below, above, and between
matrix values, single-cell input, and malformed shapes and value ranges.

## Build and record

Build one port, record its results, and verify the available implementations:

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm saddleback_search --language rust
    python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/s/saddleback_search/rust/build.json
    python3 benchmarks/verify_i64_array_scalar.py --algorithms saddleback_search

## Pinned sources

- C++: https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/search/saddleback_search.cpp
- Duplicate C++ copy: https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/search/saddleback_search.cpp
- Java: https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/SaddlebackSearch.java
- Rust: https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/searching/saddleback_search.rs

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/saddleback_search.c](../../../c/s/saddleback_search.c) |
| C3 | [c3/s/saddleback_search.c3](../../../c3/s/saddleback_search.c3) |
| C++ | [cpp/s/saddleback_search.cpp](../../../cpp/s/saddleback_search.cpp) |
| Elisa | [elisa/s/saddleback_search.elisa](../../../elisa/s/saddleback_search.elisa) |
| Nim | [nim/s/saddleback_search.nim](../../../nim/s/saddleback_search.nim) |
| Odin | [odin/s/saddleback_search.odin](../../../odin/s/saddleback_search.odin) |
| Rust | [rust/s/saddleback_search.rs](../../../rust/s/saddleback_search.rs) |
| V | [v/s/saddleback_search.v](../../../v/s/saddleback_search.v) |
| Zig | [zig/s/saddleback_search.zig](../../../zig/s/saddleback_search.zig) |

# Table Compression: optimal contiguous partition

This package implements Problem 1 from Encyclopedia of Algorithms chapter DOI [`10.1007/978-1-4939-2864-4_418`](https://doi.org/10.1007/978-1-4939-2864-4_418): choose a partition of a fixed-record table into contiguous column intervals that minimizes the sum of interval compression costs. The source gives the dynamic program `E[i] = min_{0<=j<i}(E[j] + H_C(T[j+1..i]))`.

## Bounded profile

- ABI: `i64_array_bytes_output`; input is `[rows,columns,cell00,cell01,...]` with cells in row-major order.
- Rows and columns each range from 1 to 8. Cell symbols are integers 0–15, serialized as one byte each. This is a bounded fixed-record table.
- The source parameterizes the interval cost by a compressor `C`. This profile fixes `C` to a byte-pair RLE codec: flatten the chosen contiguous column interval in row-major order and encode each maximal equal-symbol run as `[run_length,symbol]`. Runs fit in one byte under the bounds; the interval cost is exactly two bytes per run and there is no header.
- The port applies the source DP to all possible contiguous intervals. Starts are considered in ascending order and equal costs retain the first cut. Output is `[minimum_compressed_bytes,group_count,cut_mask]`; bit `i-1` in `cut_mask` records a boundary after column `i-1` (equivalently, before zero-based column `i`). This compactly reconstructs every interval.
- Output is three little-endian signed 64-bit words (24 bytes). Invalid input returns `-1`; null or short output returns `-2` without writes.

This is the chapter's contiguous-partition optimizer for the explicitly selected RLE compressor. It does not claim the output partition is optimal for gzip, LZ, BWT, or another compressor. It is distinct from local symbol-stream codecs, which compress a stream but do not optimize a table's contiguous column partition, and from `columnar_transposition`, which performs a different column permutation.

## Provenance and rights

The source chapter is Raffaele Giancarlo and Adam L. Buchsbaum, “Table Compression,” DOI `10.1007/978-1-4939-2864-4_418`; it summarizes the 2003 work of Buchsbaum, Fowler, and Giancarlo. The ports are clean-room implementations of the recurrence and fixed RLE cost profile. No chapter prose, figure, or upstream code is copied. See [`RIGHTS.md`](RIGHTS.md).

## Package files

- [`workload.json`](workload.json)
- [`primary DP oracle`](../../table_compression_optimal_contiguous_partition_oracle.py)
- [`independent exhaustive verifier oracle`](../../table_compression_optimal_contiguous_partition_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/t/table_compression_optimal_contiguous_partition.c`](../../../c/t/table_compression_optimal_contiguous_partition.c) |
| C3 | [`c3/t/table_compression_optimal_contiguous_partition.c3`](../../../c3/t/table_compression_optimal_contiguous_partition.c3) |
| C++ | [`cpp/t/table_compression_optimal_contiguous_partition.cpp`](../../../cpp/t/table_compression_optimal_contiguous_partition.cpp) |
| Elisa | [`elisa/t/table_compression_optimal_contiguous_partition.elisa`](../../../elisa/t/table_compression_optimal_contiguous_partition.elisa) |
| Nim | [`nim/t/table_compression_optimal_contiguous_partition.nim`](../../../nim/t/table_compression_optimal_contiguous_partition.nim) |
| Odin | [`odin/t/table_compression_optimal_contiguous_partition.odin`](../../../odin/t/table_compression_optimal_contiguous_partition.odin) |
| Rust | [`rust/t/table_compression_optimal_contiguous_partition.rs`](../../../rust/t/table_compression_optimal_contiguous_partition.rs) |
| V | [`v/t/table_compression_optimal_contiguous_partition.v`](../../../v/t/table_compression_optimal_contiguous_partition.v) |
| Zig | [`zig/t/table_compression_optimal_contiguous_partition.zig`](../../../zig/t/table_compression_optimal_contiguous_partition.zig) |

# TSVC s343 Column-Major Compaction

This package implements the bounded positive-mask packing behavior of TSVC's s343 kernel. It scans a row-major data matrix and mask by columns, appending each data value whose corresponding mask is positive. The scan preserves source order and duplicates.

## Contract

The i64_array_bytes_output input is [rows, cols, data..., mask...]. Both matrices are row-major, each has rows*cols signed 64-bit elements, and dimensions are in 1..8. The exact input length is 2 + 2*rows*cols; values may be any signed 64-bit integers. The mask predicate is mask[row, col] > 0.

Visit col from left to right and, within each column, row from top to bottom. Append data[row, col] for each positive mask entry. Emit appended values as little-endian signed 64-bit integers. Return the number of values emitted; output bytes are exactly eight times that count. For an input with rows*cols cells, output capacity must be at least 8*rows*cols, even when fewer values are selected. A null output pointer or insufficient capacity returns -2 without writing. A null input pointer, invalid dimensions, or malformed packing returns -1; input validation takes precedence over output-capacity errors. The maximum input is 130 i64 values and maximum output workspace is 512 bytes.

## Source and rights

The behavior reference is the pinned [TSVC s343 source](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc), selected by [Packing-dbl/tsc.c](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Packing-dbl/tsc.c) and [Packing-dbl/info.sh](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Packing-dbl/info.sh). The launcher uses 50,000 iterations and 14 output digits; the selected C file defines the double-precision suite and enables the packing tests. The upstream [TSVC README](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/README) identifies the test suite for vectorizing compilers by Callahan, Dongarra, and Levine, and cites Maleki et al., “An Evaluation of Vectorizing Compilers,” PACT 2011, DOI [10.1109/PACT.2011.68](https://doi.org/10.1109/PACT.2011.68). No explicit upstream license grant was found in the pinned TSVC directory or repository root. These ports are clean-room implementations of the high-level scan-and-pack behavior; no upstream code or comments were reused, and no upstream license is inferred.

The bounded profile uses caller-provided matrices and performs one pass, rather than the launcher's repeated timing loop. The upstream default initializes the mask to positive values; varied masks here exercise the kernel's conditional packing behavior.

This operation is distinct from local matrix transposition or nested-list flattening because it conditionally selects by a separate mask while preserving the source's column-major scan order. It also differs from run-length packing, which collapses adjacent equal values rather than retaining selected payloads.

[workload.json](workload.json) covers the source scan order, positive/zero/negative mask values, no matches, duplicate data, signed 64-bit payload boundaries, maximum matrix dimensions, malformed and null input, null output, and insufficient output capacity. The independent oracle is [benchmarks/tsvc_s343_column_major_compaction_oracle.py](../../tsvc_s343_column_major_compaction_oracle.py).

## Ports

| Language | Source |
| --- | --- |
| C | [c/t/tsvc_s343_column_major_compaction.c](../../../c/t/tsvc_s343_column_major_compaction.c) |
| C3 | [c3/t/tsvc_s343_column_major_compaction.c3](../../../c3/t/tsvc_s343_column_major_compaction.c3) |
| C++ | [cpp/t/tsvc_s343_column_major_compaction.cpp](../../../cpp/t/tsvc_s343_column_major_compaction.cpp) |
| Elisa | [elisa/t/tsvc_s343_column_major_compaction.elisa](../../../elisa/t/tsvc_s343_column_major_compaction.elisa) |
| Nim | [nim/t/tsvc_s343_column_major_compaction.nim](../../../nim/t/tsvc_s343_column_major_compaction.nim) |
| Odin | [odin/t/tsvc_s343_column_major_compaction.odin](../../../odin/t/tsvc_s343_column_major_compaction.odin) |
| Rust | [rust/t/tsvc_s343_column_major_compaction.rs](../../../rust/t/tsvc_s343_column_major_compaction.rs) |
| V | [v/t/tsvc_s343_column_major_compaction.v](../../../v/t/tsvc_s343_column_major_compaction.v) |
| Zig | [zig/t/tsvc_s343_column_major_compaction.zig](../../../zig/t/tsvc_s343_column_major_compaction.zig) |

# VersaBench DIS R-tree key validity

This package profiles the pinned `validIndexKey` helper, which checks that each lower endpoint is strictly less than its corresponding upper endpoint in T, X, Y, and Z order.

## Contract

The scalar symbol `versabench_dbms_valid_index_key` accepts exactly eight signed i64 words carrying unsigned IEEE-754 binary32 bit patterns: lower `(T,X,Y,Z)`, then upper `(T,X,Y,Z)`. Each word must be in `0..4,294,967,295`. The routine returns 0 if any source comparison `lower[d] >= upper[d]` is true, otherwise 1. Invalid/null framing or a payload outside the binary32 bit domain returns -1.

The port compares binary32 bit encodings using an order-preserving integer rule, with explicit IEEE cases. Both signed zeros compare equal; infinities sort normally; any NaN operand makes the ordered `>=` comparison false, so a NaN endpoint passes that dimension exactly as it does in the pinned C comparison. This routine does not impose a finite-value restriction or coordinate range. It excludes key intersection, box union, and index traversal.

## Provenance and rights

Pinned source: [`validIndexKey` in `VersaBench/dbms/valid.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/dbms/valid.c), with the T/X/Y/Z key layout in [`indexKey.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/dbms/indexKey.h), at `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The source headers identify M. L. Rivas and `Copyright 1999, Atlantic Aerospace Electronics Corp.`; no explicit redistribution license was located in the pinned directory. The local implementation independently reproduces the bounded comparison behavior and copies no upstream code/comments; see [NOTICE.txt](NOTICE.txt).

Oracle: [`versabench_dbms_valid_index_key_oracle.py`](../../versabench_dbms_valid_index_key_oracle.py). Fixtures: [workload.json](workload.json). No runtime or compiler verification is claimed.

## Language ports

- C: [../../../c/d/versabench_dbms_valid_index_key.c](../../../c/d/versabench_dbms_valid_index_key.c)
- C3: [../../../c3/d/versabench_dbms_valid_index_key.c3](../../../c3/d/versabench_dbms_valid_index_key.c3)
- C++: [../../../cpp/d/versabench_dbms_valid_index_key.cpp](../../../cpp/d/versabench_dbms_valid_index_key.cpp)
- Elisa: [../../../elisa/d/versabench_dbms_valid_index_key.elisa](../../../elisa/d/versabench_dbms_valid_index_key.elisa)
- Nim: [../../../nim/d/versabench_dbms_valid_index_key.nim](../../../nim/d/versabench_dbms_valid_index_key.nim)
- Odin: [../../../odin/d/versabench_dbms_valid_index_key.odin](../../../odin/d/versabench_dbms_valid_index_key.odin)
- Rust: [../../../rust/d/versabench_dbms_valid_index_key.rs](../../../rust/d/versabench_dbms_valid_index_key.rs)
- V: [../../../v/d/versabench_dbms_valid_index_key.v](../../../v/d/versabench_dbms_valid_index_key.v)
- Zig: [../../../zig/d/versabench_dbms_valid_index_key.zig](../../../zig/d/versabench_dbms_valid_index_key.zig)

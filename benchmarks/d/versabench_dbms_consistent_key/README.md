# VersaBench DIS R-tree key intersection

This package isolates `consistentKey`, the four-dimensional bounding-box predicate used by the DIS R-tree benchmark's query and delete traversals. The source checks each dimension for strict separation and returns true only when no axis separates the closed hyperrectangles.

## Contract

Input is exactly 16 signed i64 values: box A lower `(T,X,Y,Z)`, box A upper `(T,X,Y,Z)`, box B lower `(T,X,Y,Z)`, box B upper `(T,X,Y,Z)`. Coordinates are integers in `[-8,8]`; each box must satisfy `lower[d] <= upper[d]`. Degenerate point/plane intervals are valid for this helper. The `i64_array_scalar` function returns 1 when the boxes intersect and 0 otherwise. Touching boundaries count as intersection because the source rejects only strict separation (`A.lower > B.upper` or `B.lower > A.upper`). Invalid framing or coordinates return `-1`.

The bounded predicate is used to filter branches during R-tree `query` and `deleteEntry`. It does not implement tree traversal, output matching, or non-key attribute substring checks.

## Source attribution and rights

Pinned operation: [`consistentKey` in `VersaBench/dbms/consistent.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/dbms/consistent.c), with 4D key layout from `indexKey.h` and call sites in `query.c` and `deleteEntry.c`, at `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The source headers identify M. L. Rivas and state `Copyright 1999, Atlantic Aerospace Electronics Corp.`. No explicit redistribution license was present in the pinned directory. This package independently implements the documented interval predicate and copies no upstream code or comments; see [NOTICE.txt](NOTICE.txt).

The independent oracle is [`versabench_dbms_consistent_key_oracle.py`](../../versabench_dbms_consistent_key_oracle.py); fixtures are in [`workload.json`](workload.json).

## Ports

- C: [`c/d/versabench_dbms_consistent_key.c`](../../../c/d/versabench_dbms_consistent_key.c)
- C3: [`c3/d/versabench_dbms_consistent_key.c3`](../../../c3/d/versabench_dbms_consistent_key.c3)
- C++: [`cpp/d/versabench_dbms_consistent_key.cpp`](../../../cpp/d/versabench_dbms_consistent_key.cpp)
- Elisa: [`elisa/d/versabench_dbms_consistent_key.elisa`](../../../elisa/d/versabench_dbms_consistent_key.elisa)
- Nim: [`nim/d/versabench_dbms_consistent_key.nim`](../../../nim/d/versabench_dbms_consistent_key.nim)
- Odin: [`odin/d/versabench_dbms_consistent_key.odin`](../../../odin/d/versabench_dbms_consistent_key.odin)
- Rust: [`rust/d/versabench_dbms_consistent_key.rs`](../../../rust/d/versabench_dbms_consistent_key.rs)
- V: [`v/d/versabench_dbms_consistent_key.v`](../../../v/d/versabench_dbms_consistent_key.v)
- Zig: [`zig/d/versabench_dbms_consistent_key.zig`](../../../zig/d/versabench_dbms_consistent_key.zig)

No runtime, compiler, or validator verification is claimed.

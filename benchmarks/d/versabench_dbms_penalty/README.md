# VersaBench DIS R-tree insertion penalty

This package isolates the directional `penalty(A, B)` helper used by the pinned DIS R-tree insertion and split logic. The penalty is the increase in bounding-box volume when key B is added to key A: `volume(union(A,B)) - volume(A)`. It is asymmetric because the subtracted volume belongs only to the first key.

## Contract

The `i64_array_scalar` symbol `versabench_dbms_penalty` accepts exactly 16 signed i64 values: A lower `(T,X,Y,Z)`, A upper `(T,X,Y,Z)`, B lower `(T,X,Y,Z)`, B upper `(T,X,Y,Z)`. Coordinates are in `[-8,8]`, and each box requires strict `lower[d] < upper[d]`, matching `validIndexKey`. Invalid/null input returns -1.

For each dimension the implementation takes the lower of the two lower bounds and the higher of the two upper bounds, multiplies the four spans, then subtracts A's four-dimensional volume. The result is exact and ranges from 0 through 65,535 in this bounded domain. The package measures this single directional enlargement calculation, not child selection, pair seeding, R-tree mutation, or database I/O.

## Provenance and rights

Pinned operation: [`penalty` in `VersaBench/dbms/penalty.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/dbms/penalty.c), using `keyUnion.c`, `volume.c`, `index.h`, and `indexKey.h`, at `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The source headers identify M. L. Rivas and `Copyright 1999, Atlantic Aerospace Electronics Corp.`; no explicit redistribution license was present in the pinned directory. The ports independently implement the documented bounded formula and contain no copied source code or comments; see [NOTICE.txt](NOTICE.txt).

The independent oracle is [`versabench_dbms_penalty_oracle.py`](../../versabench_dbms_penalty_oracle.py); fixtures are in [workload.json](workload.json). No runtime or compiler verification is claimed.

## Language ports

- C: [../../../c/d/versabench_dbms_penalty.c](../../../c/d/versabench_dbms_penalty.c)
- C3: [../../../c3/d/versabench_dbms_penalty.c3](../../../c3/d/versabench_dbms_penalty.c3)
- C++: [../../../cpp/d/versabench_dbms_penalty.cpp](../../../cpp/d/versabench_dbms_penalty.cpp)
- Elisa: [../../../elisa/d/versabench_dbms_penalty.elisa](../../../elisa/d/versabench_dbms_penalty.elisa)
- Nim: [../../../nim/d/versabench_dbms_penalty.nim](../../../nim/d/versabench_dbms_penalty.nim)
- Odin: [../../../odin/d/versabench_dbms_penalty.odin](../../../odin/d/versabench_dbms_penalty.odin)
- Rust: [../../../rust/d/versabench_dbms_penalty.rs](../../../rust/d/versabench_dbms_penalty.rs)
- V: [../../../v/d/versabench_dbms_penalty.v](../../../v/d/versabench_dbms_penalty.v)
- Zig: [../../../zig/d/versabench_dbms_penalty.zig](../../../zig/d/versabench_dbms_penalty.zig)

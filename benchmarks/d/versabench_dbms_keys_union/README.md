# VersaBench DIS R-tree `keysUnion`

This package isolates the list form of `keysUnion` in the pinned VersaBench DIS R-tree source. It computes the minimum 4D bounding rectangle containing all input keys by taking the minimum lower coordinate and maximum upper coordinate independently in T, X, Y, and Z.

## Contract

The `i64_array_bytes_output` symbol `versabench_dbms_keys_union` accepts `[count, box_0_lower_T_X_Y_Z, box_0_upper_T_X_Y_Z, ..., box_(count-1)_lower_T_X_Y_Z, box_(count-1)_upper_T_X_Y_Z]`. `count` is 1..16, each coordinate is an integer in [-8,8], and each lower coordinate must be <= its corresponding upper coordinate. The exact input length is `1 + 8*count` (maximum valid 129; maximum parseable 130).

On success, return 64 and write eight signed little-endian i64 values: union lower `(T,X,Y,Z)`, then union upper `(T,X,Y,Z)`. Invalid/null input returns -1. A null output pointer or capacity below 64 returns -2 after input validation, without writing output. The small coordinate domain makes all comparisons exact and avoids overflow.

This is the list-union helper only. It excludes linked-list mutation, R-tree insertion, node splitting, query, deletion, and database/launcher behavior. It is distinct from `consistentKey` (intersection predicate), `chooseEntry` (minimum enlargement selection), `partitionEntries` (seed/assignment), and 2D set-union-area algorithms.

## Provenance and rights

Pinned source: [`keysUnion` in `VersaBench/dbms/keyUnion.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/dbms/keyUnion.c), with layout in `indexKey.h`, launcher `info.sh`, at `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its header identifies M. L. Rivas and `Copyright 1999, Atlantic Aerospace Electronics Corp.`. No explicit redistribution license was found in the pinned directory. These ports are clean-room implementations of the bounded operation and do not copy upstream source text or comments. See [NOTICE.txt](NOTICE.txt).

The independent oracle is [`versabench_dbms_keys_union_oracle.py`](../../versabench_dbms_keys_union_oracle.py); fixtures are in [workload.json](workload.json). No runtime or compiler verification is claimed.

## Language ports

- C: [../../../c/d/versabench_dbms_keys_union.c](../../../c/d/versabench_dbms_keys_union.c)
- C3: [../../../c3/d/versabench_dbms_keys_union.c3](../../../c3/d/versabench_dbms_keys_union.c3)
- C++: [../../../cpp/d/versabench_dbms_keys_union.cpp](../../../cpp/d/versabench_dbms_keys_union.cpp)
- Elisa: [../../../elisa/d/versabench_dbms_keys_union.elisa](../../../elisa/d/versabench_dbms_keys_union.elisa)
- Nim: [../../../nim/d/versabench_dbms_keys_union.nim](../../../nim/d/versabench_dbms_keys_union.nim)
- Odin: [../../../odin/d/versabench_dbms_keys_union.odin](../../../odin/d/versabench_dbms_keys_union.odin)
- Rust: [../../../rust/d/versabench_dbms_keys_union.rs](../../../rust/d/versabench_dbms_keys_union.rs)
- V: [../../../v/d/versabench_dbms_keys_union.v](../../../v/d/versabench_dbms_keys_union.v)
- Zig: [../../../zig/d/versabench_dbms_keys_union.zig](../../../zig/d/versabench_dbms_keys_union.zig)

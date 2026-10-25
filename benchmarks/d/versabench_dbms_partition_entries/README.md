# VersaBench DIS R-tree node partitioning

This package isolates the pinned DIS Data Management benchmark's `partitionEntries` helper. When a node overflows, it partitions the `fan + 1` entries into two groups using the source's seed-pair and assignment rules.

## Contract

Input is `[fan, entries...]`, where `fan` is 2 through 8 and the entry count is exactly `fan + 1`, as passed by `splitNode` for an overflowing node. Each 4D box is encoded as lower `(T,X,Y,Z)` coordinates followed by upper `(T,X,Y,Z)` coordinates; every coordinate is an integer in `[-8,8]` and each lower bound is strictly less than its upper bound. The maximum valid input length is 73 i64 values; one additional value is parseable to detect trailing data. Invalid input returns `-1`.

The source enumerates pairs in input order and chooses the pair whose union has maximum 4D volume. It replaces the current pair only on a strictly greater volume, preserving the first pair on ties. Those entries seed groups A and B. Remaining entries are considered in original input order; while both groups have room, the entry joins the seed box with the smaller volume enlargement. Equal penalties go to B because the source tests only `penalty(A, entry) < penalty(B, entry)`. Once one group reaches `fan`, all remaining entries go to the other. The output is an i64 bitmask: bit `i` is one when input entry `i` belongs to A, otherwise it belongs to B.

Bounded integer coordinates make 4D volumes small exact integers that are exactly representable by the source's binary32 `Float`. This profile covers the split partition rule only; it does not model linked-list mutation, node allocation, parent-bound updates, recursive insertion, or database I/O.

## Source attribution and rights

The algorithm is `partitionEntries` in [`VersaBench/dbms/partitionEntries.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/dbms/partitionEntries.c), supported by `penalty.c`, `keyUnion.c`, `volume.c`, and `indexKey.h`, pinned at `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The source headers identify M. L. Rivas and state `Copyright 1999, Atlantic Aerospace Electronics Corp.`. No explicit redistribution license was present in the pinned directory. This package independently implements the documented split heuristic and copies no upstream code or comments; see [NOTICE.txt](NOTICE.txt) for the rights status.

The independent oracle is [`versabench_dbms_partition_entries_oracle.py`](../../versabench_dbms_partition_entries_oracle.py); fixtures are in [`workload.json`](workload.json).

## Ports

- C: [`c/d/versabench_dbms_partition_entries.c`](../../../c/d/versabench_dbms_partition_entries.c)
- C3: [`c3/d/versabench_dbms_partition_entries.c3`](../../../c3/d/versabench_dbms_partition_entries.c3)
- C++: [`cpp/d/versabench_dbms_partition_entries.cpp`](../../../cpp/d/versabench_dbms_partition_entries.cpp)
- Elisa: [`elisa/d/versabench_dbms_partition_entries.elisa`](../../../elisa/d/versabench_dbms_partition_entries.elisa)
- Nim: [`nim/d/versabench_dbms_partition_entries.nim`](../../../nim/d/versabench_dbms_partition_entries.nim)
- Odin: [`odin/d/versabench_dbms_partition_entries.odin`](../../../odin/d/versabench_dbms_partition_entries.odin)
- Rust: [`rust/d/versabench_dbms_partition_entries.rs`](../../../rust/d/versabench_dbms_partition_entries.rs)
- V: [`v/d/versabench_dbms_partition_entries.v`](../../../v/d/versabench_dbms_partition_entries.v)
- Zig: [`zig/d/versabench_dbms_partition_entries.zig`](../../../zig/d/versabench_dbms_partition_entries.zig)

No runtime, compiler, or validator verification is claimed.

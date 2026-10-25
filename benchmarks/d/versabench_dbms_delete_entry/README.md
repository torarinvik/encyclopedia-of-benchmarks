# VersaBench DIS R-tree deletion path

This package isolates a bounded `deleteEntry` traversal over a root with leaf children. It exercises key-based branch pruning, removal of every matching leaf record, removal of child nodes that become empty, and recomputation of the surviving child MBRs. The non-key search list is empty, so all leaf records whose keys intersect the query are accepted for deletion.

## Contract

ABI: `i64_array_bytes_output`; symbol: `versabench_dbms_delete_entry`.

Input is `[child_count, query_lower_TXYZ(4), query_upper_TXYZ(4), child_records...]`. Each child record is `[record_count, child_MBR(8), leaf_records...]`; each leaf record is `[lower_TXYZ(4), upper_TXYZ(4), record_id]`. There are 1–4 initial child nodes, each with 1–4 records. Coordinates are bounded to `[-8,8]`, with strict lower<upper in all four dimensions. IDs are unique in `[0,31]`; each supplied child MBR must exactly equal the union of its leaf record boxes. Key consistency uses closed interval intersection, including touching boundaries.

The output serializes the post-delete root child list as `[remaining_child_count, child_records...]`, with each child record encoded using the same child layout. Matching leaf entries are removed; an emptied child is unlinked; each surviving child's MBR is recomputed from its retained entries. Child and record order are stable. Maximum valid input is 189 words (190 parseable); maximum output is 181 signed-i64 elements (1,448 bytes), little-endian. Malformed input returns `-1`; null or insufficient output returns `-2`, after validation and without writing output.

This is the one-internal-level recursive deletion profile. Root-level conversion/collapse performed by the outer `delete()` routine, non-key attribute filters, object memory release, error messages, the larger database, and its command stream are excluded.

## Source and rights

Source: [`VersaBench/dbms/deleteEntry.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/dbms/deleteEntry.c), pinned to `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Related files are `delete.c`, `deleteIndexEntry.c`, `consistent.c`, `keysUnion.c`, `index.h`, and `indexKey.h`; launcher: `VersaBench/dbms/info.sh`. The source identifies M. L. Rivas and carries `Copyright 1999, Atlantic Aerospace Electronics Corp.` No explicit redistribution license was present in the pinned directory. This package is independently written and contains no copied source code or comments; the notice records the source provenance and license status.

Independent model: [`versabench_dbms_delete_entry_oracle.py`](../../versabench_dbms_delete_entry_oracle.py). No runtime, compiler, or validator verification is claimed.

## Ports

- C: [`c/d/versabench_dbms_delete_entry.c`](../../../c/d/versabench_dbms_delete_entry.c)
- C3: [`c3/d/versabench_dbms_delete_entry.c3`](../../../c3/d/versabench_dbms_delete_entry.c3)
- C++: [`cpp/d/versabench_dbms_delete_entry.cpp`](../../../cpp/d/versabench_dbms_delete_entry.cpp)
- Elisa: [`elisa/d/versabench_dbms_delete_entry.elisa`](../../../elisa/d/versabench_dbms_delete_entry.elisa)
- Nim: [`nim/d/versabench_dbms_delete_entry.nim`](../../../nim/d/versabench_dbms_delete_entry.nim)
- Odin: [`odin/d/versabench_dbms_delete_entry.odin`](../../../odin/d/versabench_dbms_delete_entry.odin)
- Rust: [`rust/d/versabench_dbms_delete_entry.rs`](../../../rust/d/versabench_dbms_delete_entry.rs)
- V: [`v/d/versabench_dbms_delete_entry.v`](../../../v/d/versabench_dbms_delete_entry.v)
- Zig: [`zig/d/versabench_dbms_delete_entry.zig`](../../../zig/d/versabench_dbms_delete_entry.zig)

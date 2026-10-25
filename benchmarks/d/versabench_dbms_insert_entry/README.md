# VersaBench DIS R-tree insertion path (no-split profile)

This package models the successful, no-split path of `insertEntry` in the pinned VersaBench DIS database benchmark. It includes recursive descent by minimum 4D volume enlargement, leaf insertion, and bottom-up bounding-key adjustment. It intentionally stops before overflow handling, node splitting, allocation, root growth, record I/O, and the database command stream.

## Contract

The ABI is `i64_array_bytes_output`; the exported symbol is `versabench_dbms_insert_entry`. Input words are:

`[depth, new_record_id, new_lower_TXYZ(4), new_upper_TXYZ(4), branch_node_records..., leaf_count, leaf_records...]`

Each branch record is `[child_count, child_box...]`, where each child box is eight coordinates: lower `(T,X,Y,Z)` followed by upper `(T,X,Y,Z)`. Branch records are supplied root-to-leaf. A leaf record is `[lower_TXYZ(4), upper_TXYZ(4), record_id]`. Depth is 0–2; each branch has 1–4 children; the leaf has 0–3 records (a non-root leaf must be nonempty). Coordinates are in `[-8,8]`, with strict lower<upper in each dimension. Existing IDs and the inserted ID are distinct members of `[0,31]`.

At each branch, the selected child minimizes `volume(union(child,incoming))-volume(child)`; a strict improvement replaces the current selection, so ties select the first child. Each selected child box must equal the next path node's pre-insertion MBR. The profile requires free space in the leaf, so no split is needed. The output is little-endian signed-i64 words: `[depth, new_record_id, chosen_child_index_at_each_level, updated_leaf_MBR(8), updated_internal_MBRs(8 each, bottom-up)]`. The MBRs are recomputed from the unchanged siblings and changed child. Maximum valid input is 104 words, maximum parseable input is 105 words, and maximum output is 224 bytes. Malformed input returns `-1`; null or insufficient output returns `-2`; validation precedes output-capacity handling and no output is written on error.

All arithmetic is exact integer arithmetic. On these bounds the volume products match the source's floating-point volume comparisons exactly. The workload includes depth-zero and recursive insertion cases, a malformed path, short output, null output, and null input.

## Source and rights

The source is [`VersaBench/dbms/insertEntry.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/dbms/insertEntry.c) at `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Related source paths are `chooseEntry.c`, `penalty.c`, `volume.c`, `keyUnion.c`, `splitNode.c`, `partitionEntries.c`, `index.h`, and `indexKey.h`; launcher: `VersaBench/dbms/info.sh`. The source headers identify M. L. Rivas and `Copyright 1999, Atlantic Aerospace Electronics Corp.` No explicit redistribution license was found in the pinned directory. These are independent clean-room implementations of the bounded behavior and contain no copied source text or comments; the notice preserves attribution and records the licensing limitation.

The independent oracle is [`versabench_dbms_insert_entry_oracle.py`](../../versabench_dbms_insert_entry_oracle.py). No runtime, compiler, or validator verification is claimed.

## Ports

- C: [`c/d/versabench_dbms_insert_entry.c`](../../../c/d/versabench_dbms_insert_entry.c)
- C3: [`c3/d/versabench_dbms_insert_entry.c3`](../../../c3/d/versabench_dbms_insert_entry.c3)
- C++: [`cpp/d/versabench_dbms_insert_entry.cpp`](../../../cpp/d/versabench_dbms_insert_entry.cpp)
- Elisa: [`elisa/d/versabench_dbms_insert_entry.elisa`](../../../elisa/d/versabench_dbms_insert_entry.elisa)
- Nim: [`nim/d/versabench_dbms_insert_entry.nim`](../../../nim/d/versabench_dbms_insert_entry.nim)
- Odin: [`odin/d/versabench_dbms_insert_entry.odin`](../../../odin/d/versabench_dbms_insert_entry.odin)
- Rust: [`rust/d/versabench_dbms_insert_entry.rs`](../../../rust/d/versabench_dbms_insert_entry.rs)
- V: [`v/d/versabench_dbms_insert_entry.v`](../../../v/d/versabench_dbms_insert_entry.v)
- Zig: [`zig/d/versabench_dbms_insert_entry.zig`](../../../zig/d/versabench_dbms_insert_entry.zig)

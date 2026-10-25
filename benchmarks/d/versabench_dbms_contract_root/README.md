# VersaBench DIS R-tree root contraction

This package isolates the root-normalization step in the pinned `delete()` routine. If an internal root has exactly one child, the root pointer is replaced by that child, repeatedly. If the remaining internal root is empty, its level is reset to the leaf level. This is the root contraction operation after deletion, distinct from `deleteEntry`'s recursive leaf filtering and empty-child unlinking.

## Contract

ABI: `i64_array_bytes_output`; symbol: `versabench_dbms_contract_root`.

Input is `[node_count, (level, entry_count)*]`. The list starts at the root and follows the sole child whenever an internal node has one entry. There are 1–5 nodes; levels are 0–4 and entry counts 0–4. Every non-terminal node must be internal, contain exactly one child, and be followed by a node one level lower. The terminal node is either a leaf with 0–4 records, an internal node with 2–4 children, or (only when it is the original root) an empty internal root. An internal terminal singleton is malformed because its child must be represented.

The output is three little-endian signed i64 values: `[number_of_promotions, final_root_level, final_root_entry_count]`. The outer source converts an empty internal root to level 0 with count 0. Malformed framing or levels return `-1`; null or short output returns `-2`, with validation first and no writes on errors. Maximum valid input is 11 words, maximum parseable input is 12, and output is 24 bytes.

Only the root normalization loop is modeled. The package does not allocate/free nodes, represent their data entries, perform deletion, or model the full database and command stream.

## Source and rights

Source: [`VersaBench/dbms/delete.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/dbms/delete.c), pinned to `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, especially the empty-root normalization and single-child promotion logic. Related paths: `deleteEntry.c`, `deleteIndexNode.c`, `index.h`, and `delete.h`; launcher: `VersaBench/dbms/info.sh`. Source headers identify M. L. Rivas and `Copyright 1999, Atlantic Aerospace Electronics Corp.` No explicit redistribution license was found in the pinned directory. This package is clean-room and contains no copied source text or comments; see [`NOTICE.txt`](NOTICE.txt).

Independent model: [`versabench_dbms_contract_root_oracle.py`](../../versabench_dbms_contract_root_oracle.py). No runtime, compiler, or validator verification is claimed.

## Ports

- C: [`c/d/versabench_dbms_contract_root.c`](../../../c/d/versabench_dbms_contract_root.c)
- C3: [`c3/d/versabench_dbms_contract_root.c3`](../../../c3/d/versabench_dbms_contract_root.c3)
- C++: [`cpp/d/versabench_dbms_contract_root.cpp`](../../../cpp/d/versabench_dbms_contract_root.cpp)
- Elisa: [`elisa/d/versabench_dbms_contract_root.elisa`](../../../elisa/d/versabench_dbms_contract_root.elisa)
- Nim: [`nim/d/versabench_dbms_contract_root.nim`](../../../nim/d/versabench_dbms_contract_root.nim)
- Odin: [`odin/d/versabench_dbms_contract_root.odin`](../../../odin/d/versabench_dbms_contract_root.odin)
- Rust: [`rust/d/versabench_dbms_contract_root.rs`](../../../rust/d/versabench_dbms_contract_root.rs)
- V: [`v/d/versabench_dbms_contract_root.v`](../../../v/d/versabench_dbms_contract_root.v)
- Zig: [`zig/d/versabench_dbms_contract_root.zig`](../../../zig/d/versabench_dbms_contract_root.zig)

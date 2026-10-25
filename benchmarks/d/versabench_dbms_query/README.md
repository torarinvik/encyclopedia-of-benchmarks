# VersaBench DIS R-tree key-only query

This package isolates the key-index traversal in the pinned `query` routine. Internal-node entries prune child subtrees when their 4D key does not intersect the search key; leaf entries are checked in list order and matching record IDs are emitted in depth-first entry order.

## Bounded contract

The `i64_array_bytes_output` symbol `versabench_dbms_query` accepts:

`[node_count, root_id, query_lower_T_X_Y_Z, query_upper_T_X_Y_Z, node records...]`

Each node record is `[level, entry_count, entries...]`; each entry is `[lower_T_X_Y_Z, upper_T_X_Y_Z, ref]`. Node IDs are their positions in the node-record sequence. For level>0, `ref` is a child node ID; for level 0, `ref` is a data-record ID in 0..31.

Bounds are strict nondegenerate 4D boxes with integer coordinates in [-8,8]. There are 1..7 nodes, levels are 0..2, each node has 1..4 entries, there are at most 16 leaf records, and record IDs are unique. The root has no parent; every other node has exactly one parent; each branch descends one level; branch keys must enclose every immediate child entry key. This bounded tree structure ensures an acyclic rooted R-tree whose branch bounds cannot prune away contained leaf keys. The maximum valid input has 276 words; at most 277 words are parsed.

Intersection is closed: touching faces count as consistent, matching `consistentKey`. The search key is validated before traversal. No non-key attributes are supplied, so this profiles key-only traversal with the source's empty non-key filter. Matching IDs are serialized as little-endian signed i64 values in source depth-first/list order. Return the byte count on success, -1 for malformed tree/input, and -2 for null output or insufficient capacity after validation; failures write no output. Maximum output is 128 bytes; a no-match query returns zero bytes but still requires a non-null output pointer.

The profile excludes database file parsing, recursive insert/delete, result formatting, and non-key string filtering. It measures tree traversal/pruning rather than merely the four-dimensional intersection predicate.

## Provenance and rights

Pinned source: [`query` in `VersaBench/dbms/query.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/dbms/query.c), with node/entry representation in [`index.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/dbms/index.h), key layout in `indexKey.h`, and intersection semantics in `consistent.c`; pinned commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Headers identify M. L. Rivas and `Copyright 1999, Atlantic Aerospace Electronics Corp.`; no explicit redistribution license was found in the pinned directory. These are clean-room ports of the bounded algorithm, without copied source text/comments. See [NOTICE.txt](NOTICE.txt).

Oracle: [`versabench_dbms_query_oracle.py`](../../versabench_dbms_query_oracle.py). Fixtures: [workload.json](workload.json). No runtime/compiler verification is claimed.

## Language ports

- C: [../../../c/d/versabench_dbms_query.c](../../../c/d/versabench_dbms_query.c)
- C3: [../../../c3/d/versabench_dbms_query.c3](../../../c3/d/versabench_dbms_query.c3)
- C++: [../../../cpp/d/versabench_dbms_query.cpp](../../../cpp/d/versabench_dbms_query.cpp)
- Elisa: [../../../elisa/d/versabench_dbms_query.elisa](../../../elisa/d/versabench_dbms_query.elisa)
- Nim: [../../../nim/d/versabench_dbms_query.nim](../../../nim/d/versabench_dbms_query.nim)
- Odin: [../../../odin/d/versabench_dbms_query.odin](../../../odin/d/versabench_dbms_query.odin)
- Rust: [../../../rust/d/versabench_dbms_query.rs](../../../rust/d/versabench_dbms_query.rs)
- V: [../../../v/d/versabench_dbms_query.v](../../../v/d/versabench_dbms_query.v)
- Zig: [../../../zig/d/versabench_dbms_query.zig](../../../zig/d/versabench_dbms_query.zig)

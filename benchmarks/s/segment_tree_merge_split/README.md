# Mergeable and splittable segment tree

This benchmark measures a sparse value-domain segment tree for multisets. It supports point insertion, destructive tree merge, range extraction into a fresh root, range-count queries, and 1-based kth queries. The algorithm is based on OI Wiki's merge and split chapter and uses only its description; the ports and bounded workload are clean-room materials.

## Contract

The byte-output ABI symbol is `segment_tree_merge_split`. Input is `[64, Q, (opcode, a, b, c)*Q]`, with exactly four signed 64-bit words per operation and `0<=Q<=32`. The value domain is inclusive `[1,64]`. Root `0` starts empty; every split allocates the next root ID, so root IDs remain stable and are never reused.

- `0, root, value, count`: add `count` copies of `value` to an existing root; `1<=value<=64`, `1<=count<=10`.
- `1, root, left, right`: move all copies in inclusive `[left,right]` from `root` into the next root ID. The original root retains values outside that interval. The new root ID is the previous root count.
- `2, destination, source, 0`: destructively merge `source` into `destination`, adding multiplicities; the roots must be distinct. `source` becomes empty but keeps its ID.
- `3, root, left, right`: append the inclusive range count to output.
- `4, root, k, 0`: append the value of the 1-based `k`th element, or `-1` if the root has fewer than `k` elements. `1<=k<=320`.

Every referenced root must already exist. Range endpoints must satisfy `1<=left<=right<=64`; unused fields must be zero. At most 32 roots can be created by splits and the total multiplicity is at most 320. Invalid framing or operations return `-1`. Each query writes one little-endian signed 64-bit answer. Valid output is at most 256 bytes. A null output or insufficient byte capacity returns `-2` without writes; the full input trace is validated and processed before output checks.

The ports use a fixed 1024-node arena. Insert and kth take O(log V); range counting and a contiguous range split take O(log V) for `V=64`. A merge visits overlapping nonempty nodes and reuses a nonempty subtree directly when the other side is empty. Destructive merges consume each source root once; across the bounded trace their work is charged to the nodes visited, while each insertion and split adds only O(log V) nodes. Declared fixed arrays total 17,796 bytes: a 16,516-byte node/root pool, a 1,024-byte parsed-operation buffer, and a 256-byte output stage. The suite's workspace field denotes the output stage; scalar locals are excluded from the fixed-array total.

## Distinctness and provenance

[`persistent_segment_tree`](../../p/persistent_segment_tree/README.md) and [`persistent_seg_tree_lazy_prop`](../../p/persistent_seg_tree_lazy_prop/README.md) preserve historical versions by path copying. This benchmark destructively merges frequency trees and splits an interval of values into a new multiset root; it is not a persistence workload.

OI Wiki describes sparse-node merge by recursively combining corresponding children and returning the nonempty subtree when the other side is absent. Its split procedure transfers fully covered nodes and allocates nodes only along partial-overlap boundaries. The article is licensed CC BY-SA 4.0/SATA. No upstream source code or examples are reused; see [`RIGHTS.md`](RIGHTS.md).

## Workload and oracles

- Workload: [`workload.json`](workload.json)
- Sparse-tree primary oracle: [`primary_oracle.py`](primary_oracle.py)
- Independent array-of-counts oracle: [`independent_oracle.py`](independent_oracle.py)
- Static inventory checker: [`check_segment_tree_merge_split_package.py`](../../check_segment_tree_merge_split_package.py)

## Ports

| Language | Source |
| --- | --- |
| C | [`c/s/segment_tree_merge_split.c`](../../../c/s/segment_tree_merge_split.c) |
| C3 | [`c3/s/segment_tree_merge_split.c3`](../../../c3/s/segment_tree_merge_split.c3) |
| C++ | [`cpp/s/segment_tree_merge_split.cpp`](../../../cpp/s/segment_tree_merge_split.cpp) |
| Elisa | [`elisa/s/segment_tree_merge_split.elisa`](../../../elisa/s/segment_tree_merge_split.elisa) |
| Mojo | [`mojo/s/segment_tree_merge_split.mojo`](../../../mojo/s/segment_tree_merge_split.mojo) |
| Nim | [`nim/s/segment_tree_merge_split.nim`](../../../nim/s/segment_tree_merge_split.nim) |
| Odin | [`odin/s/segment_tree_merge_split.odin`](../../../odin/s/segment_tree_merge_split.odin) |
| Rust | [`rust/s/segment_tree_merge_split.rs`](../../../rust/s/segment_tree_merge_split.rs) |
| V | [`v/s/segment_tree_merge_split.v`](../../../v/s/segment_tree_merge_split.v) |
| Zig | [`zig/s/segment_tree_merge_split.zig`](../../../zig/s/segment_tree_merge_split.zig) |

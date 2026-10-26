# Counting a family with a zero-suppressed decision diagram

This package builds a canonical zero-suppressed decision diagram (ZDD) for an explicitly supplied family of subsets, then counts the represented subsets by dynamic programming over the diagram. The chapter distinguishes ZDD reduction from ordinary BDD reduction: a ZDD node whose 1-edge points to the zero terminal is suppressed; equal low/high children are retained. Identical `(variable,low,high)` nodes are shared.

Input is `[n,m,mask[0..m))`, where `1<=n<=6`, `0<=m<=32`, each mask is a distinct integer in `[0,2^n)`, and bit `i` denotes item `i`. Variable order is item 0 through item n-1. The output is `[root_id,node_count,set_count,(variable,low_id,high_id)*]`, with terminals 0 and 1 and deterministic bottom-up postorder IDs. The bounds are 34 input words and 192 output words (1,536 bytes). Invalid frames return `-1`; null or short output returns `-2` without writes.

The profile covers the chapter’s ZDD representation and counting core for a finite family already materialized as masks. It does not implement the chapter’s frontier-based construction of all simple source-to-target paths or general graph-enumeration constraints. The package is distinct from [`binary_decision_graph`](../binary_decision_graph/README.md): ZDD zero suppression is not BDD equal-branch elimination.

## Implementations

| Language | Source |
|---|---|
| C | [`c/z/zdd_family_count.c`](../../../c/z/zdd_family_count.c) |
| C3 | [`c3/z/zdd_family_count.c3`](../../../c3/z/zdd_family_count.c3) |
| C++ | [`cpp/z/zdd_family_count.cpp`](../../../cpp/z/zdd_family_count.cpp) |
| Elisa | [`elisa/z/zdd_family_count.elisa`](../../../elisa/z/zdd_family_count.elisa) |
| Nim | [`nim/z/zdd_family_count.nim`](../../../nim/z/zdd_family_count.nim) |
| Odin | [`odin/z/zdd_family_count.odin`](../../../odin/z/zdd_family_count.odin) |
| Rust | [`rust/z/zdd_family_count.rs`](../../../rust/z/zdd_family_count.rs) |
| V | [`v/z/zdd_family_count.v`](../../../v/z/zdd_family_count.v) |
| Zig | [`zig/z/zdd_family_count.zig`](../../../zig/z/zdd_family_count.zig) |

Primary oracle: [`zdd_family_count_oracle.py`](../../zdd_family_count_oracle.py). Independent recursive verifier: [`zdd_family_count_verifier_oracle.py`](../../zdd_family_count_verifier_oracle.py).

## Attribution and rights

Based on Shin-ichi Minato, “Counting by ZDD,” *Encyclopedia of Algorithms* (2016), DOI [10.1007/978-1-4939-2864-4_734](https://doi.org/10.1007/978-1-4939-2864-4_734), which describes zero-suppressed BDDs and graph-solution families. All ports are independently written; no book prose, code, or figures are reproduced. The book remains copyrighted by Springer; this attribution does not grant rights to redistribute its contents.

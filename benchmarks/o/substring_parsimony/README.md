# Substring parsimony on a bounded rooted tree

This clean-room profile implements the chapter's tree dynamic program for
minimum parsimony over a finite metric state space. It uses a fixed rooted
binary tree with three leaves so the complete set of optimal labelings can be
returned within a small bound.

## Contract

- ABI: `i64_array_bytes_output`. Input is
  `[q, threshold, root_child_0, root_child_1, inner_child_0, inner_child_1,
  leaf_mask_2, leaf_mask_3, leaf_mask_4, distance_matrix...]`.
- The five vertices are numbered `0..4`; `0` is the root, `1` its internal
  child, and `2..4` are leaves. The root has child `1` and one leaf; vertex
  `1` has the other two leaves. The four parent-child edges are the supplied
  child pairs.
- The finite state space has `q` states, `1 <= q <= 4`. Each leaf mask is a
  nonempty subset of states `0..q-1`. The row-major `q*q` distance matrix must
  be a metric with integer distances in `0..9`. `threshold` is `0..36`.
- The output is little-endian signed 64-bit words
  `[minimum_score, optimal_labeling_count, labels_for_vertex_0_to_4...]`.
  If the minimum score exceeds the threshold, the count is zero and no
  labeling rows follow. Otherwise, every minimum-score labeling is included
  exactly once, sorted lexicographically by vertex order. The objective is
  the sum of the four edge distances.
- Invalid input returns `-1`. A null or undersized output returns `-2`, with
  no output bytes written. The valid input is at most 25 words (26 words are
  admitted to detect trailing data). At most `4^5` label assignments can be
  emitted, so the maximum output is 40,976 bytes.

The primary oracle uses the chapter's `W` recurrence and traces minimizing
child transitions. The independent verifier enumerates the bounded five-node
labelings and minimizes the edge sum directly.

## Source and implementation

Based on Mathieu Blanchette, “Substring Parsimony,” *Encyclopedia of
Algorithms* (2016), DOI
[10.1007/978-1-4939-2864-4_409](https://doi.org/10.1007/978-1-4939-2864-4_409).
The package ports the finite-metric tree dynamic program; it does not include
book prose, figures, or source code. See [RIGHTS.md](RIGHTS.md).

Primary oracle: [`substring_parsimony_oracle.py`](../../substring_parsimony_oracle.py).
Independent verifier: [`substring_parsimony_verifier_oracle.py`](../../substring_parsimony_verifier_oracle.py).

| Language | Source |
|---|---|
| C | [`c/o/substring_parsimony.c`](../../../c/o/substring_parsimony.c) |
| C3 | [`c3/o/substring_parsimony.c3`](../../../c3/o/substring_parsimony.c3) |
| C++ | [`cpp/o/substring_parsimony.cpp`](../../../cpp/o/substring_parsimony.cpp) |
| Elisa | [`elisa/o/substring_parsimony.elisa`](../../../elisa/o/substring_parsimony.elisa) |
| Nim | [`nim/o/substring_parsimony.nim`](../../../nim/o/substring_parsimony.nim) |
| Odin | [`odin/o/substring_parsimony.odin`](../../../odin/o/substring_parsimony.odin) |
| Rust | [`rust/o/substring_parsimony.rs`](../../../rust/o/substring_parsimony.rs) |
| V | [`v/o/substring_parsimony.v`](../../../v/o/substring_parsimony.v) |
| Zig | [`zig/o/substring_parsimony.zig`](../../../zig/o/substring_parsimony.zig) |

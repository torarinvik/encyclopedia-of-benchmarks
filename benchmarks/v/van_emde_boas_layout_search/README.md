# Van Emde Boas Layout Search

This package builds a cache-oblivious van Emde Boas (vEB) memory order for a perfect, static binary search tree, then records the array slots touched by each ordinary root-to-key search. The tree contains the sorted keys `0..N-1`, where `N = 2^h - 1` and `h` is the number of levels. The bounded height is `1..4`; each call carries zero to four query keys in `[-1,N]`.

For a subtree of height `h > 1`, split into a top subtree and equal-height bottom subtrees when `h` is a power of two. Otherwise the source assigns the bottom subtrees the largest power-of-two height no greater than `h-1` and puts the remaining levels in the top subtree. Within this profile (`h <= 4`), that gives `top_h = floor(h/2)` and `bottom_h = h - top_h`; a one-node subtree is the base case. Recursively lay out the top subtree, then each bottom subtree in left-to-right order. The four-level tree has heap-ID layout `[1,2,3,4,8,9,5,10,11,6,12,13,7,14,15]`.

Input is `[height_levels, query_count, query_keys...]`. The output is a little-endian signed-i64 byte vector:

`[node_count, veb_heap_ids..., query_count, (path_length, veb_slot_indices..., found_heap_id_or_minus_one)*]`

Each query follows the usual BST comparison rule. A hit stops at its node; a miss stops after the last existing node, so the path records only real node visits. The output includes zero-based physical array slots, and a miss reports `-1`. Malformed input returns `-1`; a null or undersized output buffer returns `-2`. Input validation precedes output-capacity handling. The largest valid input has 6 words, the largest parseable frame has 7, and the maximum output is 328 bytes. The fixed arrays and recursion frames fit the 2,048-byte workspace cap; caller output capacity is accounted separately.

The emitter runs in `O(N)` time, and queries take `O(h)` each. The independent reference instead computes the slot of each heap-indexed node directly and fills the resulting permutation, taking `O(Nh + qh)` time. Both use `O(N + output_words)` workspace. The workload is an exact functional trace of construction and search locations. It does not simulate a cache or claim a measured cache-transfer count.

The profile is distinct from [`veb_tree`](../veb_tree/README.md), which maintains a dynamic integer predecessor set, and from ordinary binary-tree traversal packages, which emit traversal orders without constructing the vEB storage permutation or returning physical search slots. It also excludes the dynamic cache-oblivious B-tree update structure.

## Source

The layout recurrence follows the static layout in Bender, Demaine, and Farach-Colton, “Cache-Oblivious B-Trees,” §2.1: recursively lay out the top recursive subtree followed by bottom recursive subtrees from left to right. [Paper](https://erikdemaine.org/papers/CacheObliviousBTrees_SICOMP/paper.pdf), DOI [10.1137/S0097539701389956](https://doi.org/10.1137/S0097539701389956). The paper is the algorithm source; its code, prose, figures, and test material are not reused.

## Files

The package contains ten native ports (C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig), a recursive primary reference, a direct-index independent reference, pinned workload fixtures, provenance and rights notes, and static inventory helpers. The byte-output runner, verifier, catalog, and Chapter 61 partial-coverage entry are registered.

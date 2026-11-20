# Package inventory

- Algorithm: static van Emde Boas layout plus physical-slot search trace.
- ABI: `i64_array_bytes_output`, symbol `van_emde_boas_layout_search`.
- Bounds: height 1..4 levels, 1..15 nodes, 0..4 queries, 6 maximum valid input words, 7 maximum parseable words, 328 output bytes, 2,048 workspace bytes.
- Primary reference: recursive top-subtree followed by left-to-right bottom-subtrees.
- Independent reference: direct heap-index-to-layout-slot calculation and permutation filling.
- Complexity: primary `O(N + qh)`; independent `O(Nh + qh)`; workspace `O(N + output_words)`.
- Duplicate review: distinct from dynamic predecessor `veb_tree`, ordinary traversal output, and update-capable cache-oblivious B-trees.
- Shared suite/catalog integration: registered in the byte-output runner, verifier, catalog, and Chapter 61 coverage table.
- Execution status: source-only authoring and static review; no programs, tests, scripts, helpers, builds, compilers, or benchmarks were run.

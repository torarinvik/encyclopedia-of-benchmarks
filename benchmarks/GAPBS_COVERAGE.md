# GAPBS kernel coverage

This crosswalk records bounded local packages derived from the pinned GAPBS
repository at commit
[`b5e3e19c2845f22fb338f4a4bc4b1ccee861d026`](https://github.com/sbeamer/gapbs/tree/b5e3e19c2845f22fb338f4a4bc4b1ccee861d026).
It documents package scope and suite registration; it does not claim runtime
verification.

| GAPBS kernel | Pinned source | Local profile | ABI | Scope |
|---|---|---|---|---|
| Ordered triangle count | [`src/tc.cc::OrderedCount`](https://github.com/sbeamer/gapbs/blob/b5e3e19c2845f22fb338f4a4bc4b1ccee861d026/src/tc.cc) | [`gapbs_ordered_triangle_count`](t/gapbs_ordered_triangle_count/README.md) | `i64_array_scalar` | Ordered neighbor-list intersections on simple undirected graphs; no degree relabeling heuristic. |
| Brandes betweenness | [`src/bc.cc`](https://github.com/sbeamer/gapbs/blob/b5e3e19c2845f22fb338f4a4bc4b1ccee861d026/src/bc.cc) | [`gapbs_betweenness_centrality`](b/gapbs_betweenness_centrality/README.md) | `i64_array_scalar` | Unweighted BFS and reverse dependency accumulation for caller-selected sources. |
| Delta-stepping SSSP | [`src/sssp.cc::RelaxEdges, DeltaStep`](https://github.com/sbeamer/gapbs/blob/b5e3e19c2845f22fb338f4a4bc4b1ccee861d026/src/sssp.cc) | [`gapbs_delta_step_sssp`](d/gapbs_delta_step_sssp/README.md) | `i64_array_bytes_output` | Deterministic single-worker bucket traversal and all-source distance vector. |
| Direction-optimizing BFS | [`src/bfs.cc`](https://github.com/sbeamer/gapbs/blob/b5e3e19c2845f22fb338f4a4bc4b1ccee861d026/src/bfs.cc) | No separate package: the unweighted frontier traversal core is represented by [`bfs_result_tree`](b/bfs_result_tree/README.md), [`breadth_first_search_shortest_path_distance`](b/breadth_first_search_shortest_path_distance/README.md), and [`breadth_first_search`](b/breadth_first_search/README.md). | — | Duplicate algorithm: GAPBS's direction-optimizing switching and graph-scale harness are profile details; its core remains breadth-first traversal. |
| PageRank pull Gauss–Seidel | [`src/pr.cc::PageRankPullGS`](https://github.com/sbeamer/gapbs/blob/b5e3e19c2845f22fb338f4a4bc4b1ccee861d026/src/pr.cc) | [`gapbs_pagerank_pull_gs`](p/gapbs_pagerank_pull_gs/README.md) | `i64_array_scalar` | In-place binary32 pull updates with source vertex order. |
| PageRank pull Jacobi (`pr_spmv`) | [`src/pr_spmv.cc::PageRankPull`](https://github.com/sbeamer/gapbs/blob/b5e3e19c2845f22fb338f4a4bc4b1ccee861d026/src/pr_spmv.cc) | No separate package: the Jacobi PageRank recurrence is represented by [`page_rank`](p/page_rank/README.md). | — | Duplicate algorithm: the local package uses a different damping value and redistributes dangling-node rank; this is a profile variation of the same PageRank iteration. |
| Afforest connected components | [`src/cc.cc::Link, Compress, SampleFrequentElement, Afforest`](https://github.com/sbeamer/gapbs/blob/b5e3e19c2845f22fb338f4a4bc4b1ccee861d026/src/cc.cc) | [`gapbs_afforest_components`](a/gapbs_afforest_components/README.md) | `i64_array_bytes_output` | Two sampled-neighbor rounds, pointer compression, frequent-sample selection, and guarded remaining-edge pass; outputs minimum-vertex labels. |
| Shiloach–Vishkin connected components | [`src/cc_sv.cc::ShiloachVishkin`](https://github.com/sbeamer/gapbs/blob/b5e3e19c2845f22fb338f4a4bc4b1ccee861d026/src/cc_sv.cc) | [`gapbs_shiloach_vishkin_components`](a/gapbs_shiloach_vishkin_components/README.md) | `i64_array_bytes_output` | Deterministic bounded min-max root hooking and parent compression; outputs minimum-vertex labels. |

The six added profiles retain the repository's BSD-3-Clause notice in their
package rights files. Their bounded workload contracts omit benchmark harness
behavior such as graph generation, random sample generation, OpenMP scheduling,
and timing where documented in each package README. BFS and Jacobi PageRank are
recorded as duplicate dispositions because their algorithm cores are already
represented locally.

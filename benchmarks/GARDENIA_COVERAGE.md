# GARDENIA kernel coverage

This inventory covers the application kernels in
[`chenxuhao/gardenia`](https://github.com/chenxuhao/gardenia), pinned to
[`5894df11cf47f8839945edadff43dc79e260216d`](https://github.com/chenxuhao/gardenia/tree/5894df11cf47f8839945edadff43dc79e260216d).
It maps recurrence families rather than counting host, OpenMP, or storage
variants as new algorithms. Source links below point to the pinned tree.

| GARDENIA source family | Local package or disposition | Coverage rationale |
|---|---|---|
| [`src/bc`](https://github.com/chenxuhao/gardenia/tree/5894df11cf47f8839945edadff43dc79e260216d/src/bc) | [`gapbs_betweenness_centrality`](b/gapbs_betweenness_centrality/README.md) | Both use unweighted Brandes BFS and dependency accumulation. |
| [`src/bfs`](https://github.com/chenxuhao/gardenia/tree/5894df11cf47f8839945edadff43dc79e260216d/src/bfs) | [`breadth_first_search`](b/breadth_first_search/README.md) | Direction-optimizing push/pull changes traversal scheduling, not the BFS distance recurrence. |
| [`src/cc`](https://github.com/chenxuhao/gardenia/tree/5894df11cf47f8839945edadff43dc79e260216d/src/cc) | [`connected_components`](c/connected_components/README.md), [`connected_components_with_dsu`](c/connected_components_with_dsu/README.md) | The source's Afforest and Shiloach–Vishkin variants map to the existing component-labeling family; dedicated exact Afforest and min-max hooking profiles are also registered. |
| [`src/mst`](https://github.com/chenxuhao/gardenia/tree/5894df11cf47f8839945edadff43dc79e260216d/src/mst) | [`boruvkas_minimum_spanning_tree`](b/boruvkas_minimum_spanning_tree/README.md) | Borůvka cut-minimum component merging is the same MST algorithm family. |
| [`src/pr`](https://github.com/chenxuhao/gardenia/tree/5894df11cf47f8839945edadff43dc79e260216d/src/pr) | [`page_rank`](p/page_rank/README.md), [`gapbs_pagerank_pull_gs`](p/gapbs_pagerank_pull_gs/README.md) | Synchronous and in-place pull PageRank schedules are already covered. |
| [`src/scc`](https://github.com/chenxuhao/gardenia/tree/5894df11cf47f8839945edadff43dc79e260216d/src/scc) | [`gardenia_fb_trim_scc`](g/gardenia_fb_trim_scc/README.md) | Forward–Backward–Trim repeatedly extracts trivial SCCs, then partitions the remaining graph by forward/backward reachability from a deterministic lowest-ID pivot; this differs from Tarjan's stack and low-link recurrence. |
| [`src/sgd`](https://github.com/chenxuhao/gardenia/tree/5894df11cf47f8839945edadff43dc79e260216d/src/sgd) | [`gardenia_sgd`](g/gardenia_sgd/README.md) | A bounded sequential per-rating profile updates latent factors immediately, so later ratings consume earlier updates. It is distinct from the synchronous GraphAIBench SGD sweep. |
| [`src/spmv`](https://github.com/chenxuhao/gardenia/tree/5894df11cf47f8839945edadff43dc79e260216d/src/spmv) | [`parboil_spmv_jds`](p/parboil_spmv_jds/README.md) | Both compute the same sparse matrix-vector product; CSR/JDS layouts are representation variants. |
| [`src/sssp`](https://github.com/chenxuhao/gardenia/tree/5894df11cf47f8839945edadff43dc79e260216d/src/sssp) | [`gapbs_delta_step_sssp`](d/gapbs_delta_step_sssp/README.md) | Both implement delta-stepping shortest paths. |
| [`src/symgs`](https://github.com/chenxuhao/gardenia/tree/5894df11cf47f8839945edadff43dc79e260216d/src/symgs) | [`gardenia_symgs`](g/gardenia_symgs/README.md) | Preserves CSR row order and forward/reverse color-class sweeps; differs from dense Gauss–Seidel and grid SOR/Seidel profiles. |
| [`src/tc`](https://github.com/chenxuhao/gardenia/tree/5894df11cf47f8839945edadff43dc79e260216d/src/tc) | [`gapbs_ordered_triangle_count`](t/gapbs_ordered_triangle_count/README.md) | Both count each unordered triangle once; source edge orientation and sixfold counting reduce to the same count. |
| [`src/vc`](https://github.com/chenxuhao/gardenia/tree/5894df11cf47f8839945edadff43dc79e260216d/src/vc) | [`gardenia_gm_vertex_coloring`](g/gardenia_gm_vertex_coloring/README.md) | Gebremedhin–Manne speculative first-fit rounds with conflict requeueing differ from degree-first greedy, BFS conflict repair, and Pannotia priority-extrema rounds. |

The selected profiles are clean-room ports across all nine supported languages.
GARDENIA's MIT notice is kept with each package. Their workload metadata
records the pinned revision, bounded input projection, and relevant source
schedule; this crosswalk is a static inventory, not a runtime correctness
claim.

# GraphAIBench source coverage

This crosswalk audits [chenxuhao/GraphAIBench](https://github.com/chenxuhao/GraphAIBench)
at commit [`17834cb29b7c542481c2e3740dc9664841b72f59`](https://github.com/chenxuhao/GraphAIBench/tree/17834cb29b7c542481c2e3740dc9664841b72f59), dated 2023-09-27. The repository carries an MIT license. It inventories both the README's advertised benchmark list and additional source families in `src/`; a README heading without a kernel implementation is marked accordingly. This is static source review only.

| GraphAIBench item | Pinned source location | Local overlap / disposition |
|---|---|---|
| GCN aggregation | `src/gnn/gconv/gcn_aggregator.cpp::GCN_Aggregator::update_all` | Implemented as [`graphai_gcn_aggregation`](g/graphai_gcn_aggregation/README.md): bounded CSR weighted neighbor-feature sum using caller-supplied per-vertex normalization factors. The binary64 slice profile excludes the source's binary32 rounding, degree-normalization setup, training, gradients, partitioned CSR, and GPU scheduling. |
| GraphSAGE aggregation | `src/gnn/gconv/sage_aggregator.cpp::SAGE_Aggregator::aggregate` | Implemented as [`graphai_sage_aggregation`](g/graphai_sage_aggregation/README.md): mean outgoing-neighbor feature vectors, with isolated rows mapped to zero. The bounded ABI uses binary64 in place of source binary32. |
| GAT aggregation | `src/gnn/gconv/gat_aggregator.cpp::GAT_Aggregator::aggregate, update_all` | Implemented as [`graphai_gat_aggregation`](g/graphai_gat_aggregation/README.md): leaky-ReLU edge scores from source/neighbor projections, per-row softmax, and weighted neighbor-feature sum. The bounded binary64 profile excludes training, dropout, weight initialization, and multi-head network setup. |
| GGNN aggregation | `src/gnn/gconv/ggnn_aggregator.cu::GGNN_Aggregator::aggregate` and `include/gnn/graph_operations.h` | Distinct recurrent graph-message update, but the pinned implementation depends on large CUDA matrix/gate kernels and graph-size-square weight matrices. Not selected for a compact portable contract in this pass. |
| Betweenness centrality | `src/centrality/{omp_base.cc,gpu_base.cu,gpu_twc.cu}` | Duplicate unweighted Brandes profile represented by [`gapbs_betweenness_centrality`](b/gapbs_betweenness_centrality/README.md); CPU/GPU traversal modes are execution variants. |
| Community detection / Louvain | `src/community/README.md` | README points to cuGraph APIs and documents the algorithm, but this pinned tree contains no GraphAIBench Louvain implementation source. No independent source kernel to port here. |
| Connected components | `src/components/{omp_base.cc,omp_afforest.cc,gpu_base.cu,gpu_afforest.cu,gpu_warp.cu}` | Duplicate component-labeling problem represented by local [`connected_components`](c/connected_components/README.md), [`gapbs_afforest_components`](a/gapbs_afforest_components/README.md), and [`gapbs_shiloach_vishkin_components`](a/gapbs_shiloach_vishkin_components/README.md). |
| Strongly connected components | README mention under components | No SCC implementation source is present in the pinned `src/components/` tree. Local [`tarjan_scc`](t/tarjan_scc/README.md) covers the algorithm family. |
| k-core / coreness | `src/coreness/{omp_base.cc,gpu_base.cu}`; `src/coreness/serial.cc::KCoreSolver` is a stub | Implemented once as [`gbbs_k_core_decomposition`](g/gbbs_k_core_decomposition/README.md), using GBBS's pinned MIT `KCore` degree-shell update for simple undirected graphs. It covers the same core-number peeling objective; GraphAIBench's serial stub has no separate operation, while its OpenMP/CUDA schedules are execution profiles. |
| Graph coloring (additional source family) | `src/coloring/{serial.cc,omp_base.cc}` | Duplicate proper-coloring task represented by [`greedy_graph_coloring`](g/greedy_graph_coloring/README.md) and [`graph_coloring`](g/graph_coloring/README.md); numeric vertex-order greedy CPU behavior is a profile variant. |
| Filtering: MST | `src/filtering/main.cu` | Duplicate MST objective represented by local Kruskal, Prim, and Borůvka packages. The pinned source's concrete implementation is topology-driven Borůvka-style MST. |
| Filtering: TMFG and PMFG | README headings in `src/filtering/README.md` | No separate TMFG or PMFG kernel appears in the pinned source tree; only the MST CUDA program is present. |
| Hungarian linear assignment | `src/linear_assignment/README-hungarian.md` | Duplicate assignment algorithm represented by [`hungarian_algorithm`](h/hungarian_algorithm/README.md); this repository contains documentation but no implementation source under `src/linear_assignment/`. |
| PageRank | `src/link_analysis/{omp_base.cc,omp_push.cc,gpu_base.cu,gpu_push.cu,gpu_warp.cu}` | Duplicate PageRank recurrence represented by [`page_rank`](p/page_rank/README.md) and [`gapbs_pagerank_pull_gs`](p/gapbs_pagerank_pull_gs/README.md); push/pull and precision are implementation profiles. |
| Node2vec / DeepWalk embedding | headings in `src/embedding/README.md` | No Node2vec or DeepWalk implementation is present in the pinned tree. The actual embedding kernel is collaborative-filtering matrix factorization, covered separately below. |
| Collaborative-filtering embedding SGD | `src/embedding/omp_base.cc::SGDSolver`, `src/embedding/main.cc::Initialize` | Implemented as [`graphai_cf_sgd_sweep`](g/graphai_cf_sgd_sweep/README.md): one synchronous residual/error pass over directed user-to-item rating edges followed by the source's regularization/update equation. The bounded profile supplies initial factors, reduces K=20 to k<=4, and runs one sweep instead of repeated training iterations. |
| Link prediction Jaccard | `src/link_prediction/README.md` | The README names Jaccard but no implementation source is present; local [`jaccard_similarity`](j/jaccard_similarity/README.md) covers the metric. |
| Triangle counting | `src/triangle/{omp_base.cc,gpu_base.cu,gpu_hindex.cu,...}` | Duplicate triangle-counting core represented by [`gapbs_ordered_triangle_count`](t/gapbs_ordered_triangle_count/README.md); CPU/GPU and orientation variants are execution profiles. |
| Clique finding | GraphAIBench README mining list; no dedicated clique source directory in the pinned tree | Related to local [`bron_kerbosch`](b/bron_kerbosch/README.md), which enumerates maximal cliques. No additional GraphAIBench clique kernel is present. |
| Motif counting / frequent subgraph mining | GraphAIBench README mining list; no motif/FSM implementation directory in the pinned tree | No benchmark kernel to port from this commit. |
| Sampling / random walk | `src/sampling/omp_base.cc::sample` | Implemented as [`graphai_frontier_sampler`](g/graphai_frontier_sampler/README.md): three ordered branching frontier rounds with explicit per-child CSR edge choices and full frontier output. Its bounded fanouts are 3/2/2 instead of source constants 15/10/10, and caller choices replace process-global `rand()`; it returns the sampled IDs rather than materializing the source's subgraph. |
| Graph coarsening | `src/structure/README.md` | The pinned `src/structure/` files implement graph compression and compressed BFS/triangle routines, not a graph-coarsening algorithm. No separate coarsening kernel source was found. |
| Compressed-graph BFS (additional source family) | `src/structure/bfs_main.cu`, `src/structure/gpu_kernels/bfs_gcgt*.cuh` | Duplicate BFS traversal core. Graph compression and CUDA decode scheduling are outside the local traversal result contract. |
| BFS and SSSP | `src/traversal/{omp_base.cc,omp_direction.cc,omp_dstep.cc,gpu_base.cu,gpu_dstep.cu,gpu_bellmanford.cu,...}` | BFS overlaps local BFS packages; SSSP overlaps Dijkstra, Bellman–Ford, and delta-stepping packages. Source frontier schedules are execution profiles. |
| Hierarchical agglomerative graph clustering (additional source family) | `src/clustering/{NNChainBased.h,HeapBased.h,ClusteredGraph.h}`; launcher defaults in `src/clustering/main.cc` | Implemented as [`graphai_hac_complete_linkage`](g/graphai_hac_complete_linkage/README.md): connected simple weighted graphs with at most eight vertices, unique integer edge similarities, maximum-similarity merge selection, min-linkage update for common neighbors, one-sided edge preservation, and source-shaped parent/merge-level output. Unique initial weights keep all active edge scores unique; a deterministic full scan replaces the source heap. |
| Approximate nearest-neighbor search (additional source family) | `src/nearest_neighbor_search/{omp_base.cc,gpu_base.cu,ann.h}` | Related to local exact nearest-neighbor and k-NN packages, but the index/search approximation profile is different. It depends on a large graph index and is not selected as a compact kernel. |
| Graph partitioning and conversion utilities | `src/partitioner/graph_partition.cc`, `src/converters/*` | Preprocessing/manipulation utilities, not separate listed graph algorithms. Their partition materialization depends on source graph layouts and is excluded from this bounded-kernel inventory. |

## Compact kernels and remaining candidates

`graphai_gcn_aggregation`, `graphai_sage_aggregation`,
`graphai_gat_aggregation`, `graphai_frontier_sampler`,
`graphai_cf_sgd_sweep`, and `graphai_hac_complete_linkage` are completed
compact profiles. GCN takes
caller-supplied normalization values instead of reproducing degree setup;
GraphSAGE preserves per-row mean aggregation; GAT computes attention scores,
row softmax, and weighted neighbor accumulation. They preserve CSR edge order
and declare the binary64 precision projection. The three-round sampler uses
smaller 3/2/2 fanouts than the source's 15/10/10 and returns every sampled
vertex. The CF profile captures one synchronous factor update using explicit
initial factors and bounded k, omitting random initialization and later
training iterations. HAC uses connected graphs and pairwise-distinct small
integer edge similarities to avoid source heap ties and disconnected-component
fallback behavior. Training,
optimizer, GPU scheduling, and random initialization are excluded from the
respective bounded profiles.

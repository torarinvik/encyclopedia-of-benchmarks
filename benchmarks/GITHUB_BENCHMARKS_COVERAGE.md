# GitHub algorithm source crosswalk

This page maps the 17 shortlisted kernels to the upstream source or algorithm
reference recorded in their local package documentation. The package links
point to the corresponding local `README.md`. This crosswalk records source
provenance and package scope; it does not claim runtime verification.

| Kernel | Upstream source or reference | Local package |
|---|---|---|
| `min_cost_max_flow` | AtCoder Library, [`atcoder/mincostflow.hpp`](https://github.com/atcoder/ac-library/blob/864245a00b00dd008d1abfdc239618fdb7d139da/atcoder/mincostflow.hpp), commit `864245a00b00dd008d1abfdc239618fdb7d139da`; successive shortest paths with potentials. | [README](m/min_cost_max_flow/README.md) |
| `sqrt_tree` | cp-algorithms, [Sqrt Tree article](https://cp-algorithms.com/data_structures/sqrt-tree.html). The local README records the article attribution and CC BY-SA 4.0 terms; it does not pin an article revision. | [README](s/sqrt_tree/README.md) |
| `seam_carving` | trekhleb/javascript-algorithms, [seam-carving explanation](https://github.com/trekhleb/javascript-algorithms/blob/85293e3e2b88f4d2ce330d956b139cf628aa1e82/src/algorithms/image-processing/seam-carving/README.md), commit `85293e3e2b88f4d2ce330d956b139cf628aa1e82`. | [README](s/seam_carving/README.md) |
| `morton_sort` | ParGeo, [repository](https://github.com/ParAlg/ParGeo). The local README describes this as an independent implementation of the Morton ordering workload; it does not record a source file or commit. | [README](m/morton_sort/README.md) |
| `number_theoretic_transform` | AtCoder Library, [`atcoder/convolution.hpp`](https://github.com/atcoder/ac-library/blob/864245a00b00dd008d1abfdc239618fdb7d139da/atcoder/convolution.hpp), commit `864245a00b00dd008d1abfdc239618fdb7d139da`; fixed-modulus forward NTT profile. | [README](n/number_theoretic_transform/README.md) |
| `rader_fft` | NyaanNyaan/library, [`ntt/rader-ntt.hpp`](https://github.com/NyaanNyaan/library/blob/b3981adc80a800b2584980b01821324ea6c77183/ntt/rader-ntt.hpp), commit `b3981adc80a800b2584980b01821324ea6c77183`; Rader permutation and convolution fold. | [README](r/rader_fft/README.md) |
| `relaxed_convolution` | NyaanNyaan/library, [`ntt/relaxed-convolution.hpp`](https://github.com/NyaanNyaan/library/blob/b3981adc80a800b2584980b01821324ea6c77183/ntt/relaxed-convolution.hpp), commit `b3981adc80a800b2584980b01821324ea6c77183`; online coefficient schedule. | [README](r/relaxed_convolution/README.md) |
| `beta_skeleton` | ParGeo, [`src/spatialGraph/betaSkeleton/betaSkeleton.cpp`](https://github.com/ParAlg/ParGeo/blob/4911408762c46b7c262f6d617d7adcb0cb0f219b/src/spatialGraph/betaSkeleton/betaSkeleton.cpp), commit `4911408762c46b7c262f6d617d7adcb0cb0f219b`; beta=2 lune rule. | [README](b/beta_skeleton/README.md) |
| `schoenhage_strassen_multiply` | NyaanNyaan/library, [`ntt/schoenhage-strassen-radix2.hpp`](https://github.com/NyaanNyaan/library/blob/b3981adc80a800b2584980b01821324ea6c77183/ntt/schoenhage-strassen-radix2.hpp), commit `b3981adc80a800b2584980b01821324ea6c77183`. | [README](s/schoenhage_strassen_multiply/README.md) |
| `wspd` | dmatijev/wspd_pip, [`src/findwsp.cpp`](https://github.com/dmatijev/wspd_pip/blob/6bbe228bb13993d8ee972671acde8e76c9330eda/src/findwsp.cpp), commit `6bbe228bb13993d8ee972671acde8e76c9330eda`; source-level well-separated-pair decomposition. | [README](w/wspd/README.md) |
| `batch_dynamic_kd_tree` | ParGeo, [`include/batchKdtree/log-tree/logtree.h`](https://github.com/ParAlg/ParGeo/blob/4911408762c46b7c262f6d617d7adcb0cb0f219b/include/batchKdtree/log-tree/logtree.h), commit `4911408762c46b7c262f6d617d7adcb0cb0f219b`; logarithmic batch-update levels with static k-d tree queries. | [README](b/batch_dynamic_kd_tree/README.md) |
| `smallest_enclosing_ball_3d` | Anton Semechko, [`ExactMinBoundSphere3D.m`](https://github.com/antonsemechko/Bounding-Spheres-And-Circles/blob/a6e9fe28d5239fdf72055a5ff7116bb08b2135de/ExactMinBoundSphere3D.m) and its `Auxiliary/FitMinSphere2Points.m`, commit `a6e9fe28d5239fdf72055a5ff7116bb08b2135de`; Welzl recursion with at most four support points. | [README](s/smallest_enclosing_ball_3d/README.md) |
| `delaunay_triangulation` | jbegaint/delaunay-cpp, [`delaunay.hpp`](https://github.com/jbegaint/delaunay-cpp/blob/a5735771621d889bd5b85ffc228ed358e4bf3c9b/delaunay.hpp), commit `a5735771621d889bd5b85ffc228ed358e4bf3c9b`. | [README](d/delaunay_triangulation/README.md) |
| `bentley_ottmann` | TheAlgorithms/Java, [`BentleyOttmann.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/geometry/BentleyOttmann.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`. | [README](b/bentley_ottmann/README.md) |
| `euclidean_t_spanner` | ParGeo, [`src/spatialGraph/spanner/spanner.cpp`](https://github.com/ParAlg/ParGeo/blob/4911408762c46b7c262f6d617d7adcb0cb0f219b/src/spatialGraph/spanner/spanner.cpp) and [`include/kdTree/wspdImpl.h`](https://github.com/ParAlg/ParGeo/blob/4911408762c46b7c262f6d617d7adcb0cb0f219b/include/kdTree/wspdImpl.h), commit `4911408762c46b7c262f6d617d7adcb0cb0f219b`; WSPD representative graph with a stretch-dependent separation constant. | [README](e/euclidean_t_spanner/README.md) |
| `fortune_voronoi` | JCash/voronoi, [repository at pinned commit](https://github.com/JCash/voronoi/tree/28bcb7b5d7c1bb0f1a74e97f233c67afb5b48179), commit `28bcb7b5d7c1bb0f1a74e97f233c67afb5b48179`; Fortune sweep and Voronoi diagram representation. | [README](f/fortune_voronoi/README.md) |
| `delaunay_mesh_refinement` | dtcc-platform/dtcc-mesher, [`src/core/cdt.c`](https://github.com/dtcc-platform/dtcc-mesher/blob/0bba17bbd0d5de4b3a65b0451c4e5db303e541ac/src/core/cdt.c), commit `0bba17bbd0d5de4b3a65b0451c4e5db303e541ac`; bounded one-step quality refinement. | [README](d/delaunay_mesh_refinement/README.md) |

## Distinct workload scopes

- `wspd` returns the decomposition pairs. `euclidean_t_spanner` uses accepted
  pairs to emit representative graph edges; the latter measures a graph
  construction profile rather than the pair decomposition output itself.
- `delaunay_triangulation` constructs a triangulation. `fortune_voronoi`
  constructs Voronoi cells with a Fortune-style sweep. `delaunay_mesh_refinement`
  takes a triangle mesh and performs a bounded quality-refinement step. These
  workloads exercise different outputs and operations.
- `bentley_ottmann` reports intersections across a set of segments. The
  existing two-segment intersection benchmark covers a single pair predicate,
  not the sweep-line event processing and multi-segment output workload.

# Additional Algorithm Source Coverage

This is the shared, incremental ledger for algorithms discovered outside the pinned TheAlgorithms catalog and the supplied *Encyclopedia of Algorithms*. It records equivalence decisions and in-flight ownership so independent ports do not collide. A source appearing below does not mean its entire catalog has been reviewed.

Static suite-path audit: `substring_parsimony` is stored under `o/`, while
`weighted_greedy_set_cover`, `counting_eulerian_circuits`, and
`chordal_graph_recognition` are stored under `g/`. Build, byte-output runner,
and verifier lookup tables now point to those directories. These registrations
have not been executed; other nonstandard package paths still need review.
The same static path correction covers `range_parallel_unionfind` (`u/`),
`dynamic_tree_vertex_set_path_composite` and `universal_sequencing_doubling`
(`t/`), and `hub_labeling_pruned`, `truthful_ufp_greedy1`, and
`truthful_multiunit_ca_greedy2` (`g/`). A later source-file inspection found
all ten language paths for the algorithms named in these two paragraphs;
this presence check does not establish compilation or correctness.
Additional static corrections map `three_dimensional_moment_curve`,
`approximate_matching_greedy`, and `extended_gs_general_stable_allocation` to
`g/`, and `characteristic_polynomial`, `srpt_flow_time`,
`submodular_ranking_greedy`, and `smith_weighted_completion_time` to `m/` in
the build and byte-output suite. These path changes remain unexecuted.
The path audit also corrected lookups for `open_knight_tour`, `hpcg_profile`,
`number_container_system`, `lsb_image_steganography`, `lac_adpcm`,
`idea_cfb64`, `beebs_fasta`, and scalar `embench_aha_mont64`. These are
existing profiles; missing language ports and runtime verification remain
separate work.
Further static lookup corrections cover `stanford_puzzle` (`p/`),
`max_jobs_before_deadlines` (`d/`), `cbench_automotive_qsort1` (`a/`),
`euclidean_mst` (`m/`), and `string_fibonacci` (`f/`) in their respective
scalar or byte-output suites and build lookup. These changes are untested.
The NPB FT spectral-step profile also uses `f/` for its source and workload;
build and float64 runner/verifier lookups now reflect that category. The
correction has not been executed.
Static path review also corrected the byte-output lookups for kinetic
tournament trees, convex-polygon Minkowski sums, Main–Lorentz repetitions,
indexed priority queues, F2-space intersection, and matrix hafnians. The
Steiner subset-DP scalar workload is under `p/` while its sources are under
`s/`; its build and suite lookups now account for that split. None of these
path changes has been run.
The existing `naive_knapsack_solver` input-order greedy profile is now
registered in the scalar verifier with its `k/` build/workload paths. Its
Mojo draft was already present; this is a coverage correction, not a new
algorithm. All checks remain unrun.
The existing `fourinarow_minimax` heuristic game-tree profile now also has a
Mojo draft, bringing its source coverage to ten languages. It remains distinct
from the exact `fhourstones_exact` solver. The draft and suite source-presence
checks have not been compiled or executed.
The existing `freebench_mason` alternating-permutation puzzle search now has a
Mojo draft. Its bounded iterative deepening and reachability pruning follow the
documented profile; the draft has not been compiled or run.
The existing `doe_simplemoc_quadratic_attenuation` transport kernel now has a
Mojo draft using binary32 calculations and the documented interpolation rule.
Its workload validator now recognizes the updated license wording and checks
for all ten source files. These changes are not compiled or run.
The existing `edn_jpeg_dct` fixed-point forward transform now also has a Mojo
draft that preserves its stage narrowing and row/column passes. The draft is
uncompiled and unrun.
The existing `batch_dynamic_kd_tree` profile now has a Mojo draft with
logarithmic component carries, tombstones, rebuilt k-d trees, and bounding-box
queries. The draft remains uncompiled and unrun.
Verifier source now checks ten language paths and specifies hand-derived
tombstone-reuse and 32-ID carry traces. These checks remain unexecuted.
The shortened `misc_reed_solomon` encoder and one-symbol correction profile now
also has a Mojo draft. It carries the source attribution and remains uncompiled
and unrun. The verifier source checks all ten source files and specifies
unchanged replacements at payload and parity boundaries; these checks are
unexecuted.
The existing single-block `idea_encrypt_decrypt` profile now has a Mojo draft
for its key expansion and both cipher directions. This is distinct from the
feedback-mode `idea_cfb64` profile. The draft is uncompiled and unrun.
The feedback-mode `idea_cfb64` profile now also has a Mojo draft and includes
that source in its existing package-presence check. Its block feedback and
partial-tail behavior remain unverified.
The existing `hint_area_bound_refinement` integer subdivision profile now has
a Mojo draft and a complexity note. It remains uncompiled and unrun.
The existing `gbbs_biconnectivity` Tarjan–Vishkin profile now has a Mojo draft
covering its forest, reachability, and component-label stages. It remains
uncompiled and unrun.
Verifier source now specifies CFB round trips for every supported payload length
and compares first-block output with the single-block IDEA reference. The new
checks have not been run.
The existing `nbench_resource_assignment` tableau-based assignment kernel now
has a Mojo draft and a documented complexity bound. It preserves the profile's
specific zero-selection order; the new source remains uncompiled and unrun.
Static comparison also found two missing output error fields that made the
resource-assignment workload disagree with its suite validator. Those fields
and a hand-derived tableau-adjustment case are now written but unexecuted.
The existing `benchmarkgame_puzzle` repeated duplicate-scan profile now has a
Mojo draft. Its generator tracks the low 48 state bits needed for the source's
shifted output and keeps the repeated scans. The draft remains uncompiled and
unrun.
The puzzle profile now also has a byte-output verifier registration and an
independent reference using affine RNG jumps and XOR invariance. Fixture,
cross-reference, and buffer-boundary probes are written but not executed.
The existing `benchmarkgame_nbody` five-body profile now has a Mojo draft and
documented fixed-size complexity. The port remains uncompiled and unrun.
Its previously missing byte-output verifier registration now includes the
existing floating-point reference, fixture tolerance, and step/buffer probes;
the verifier now uses a separate high-precision decimal numerical model and
compares it with the binary64 reference. The models share initial constants;
no checks ran.

## Source review status

| Source | Current evidence / coverage record | Review status |
| --- | --- | --- |
| TheAlgorithms repositories | [`CATALOG.md`](../CATALOG.md), pinned in [`catalog/algorithm-candidates.json`](../catalog/algorithm-candidates.json) | Existing inventory; continue resolving the remaining candidate records there. |
| *Encyclopedia of Algorithms* | [Chapter crosswalk](ENCYCLOPEDIA_COVERAGE.md) and its A–F, G–M, N–S, T–Z sections | Existing chapter-by-chapter review; preserve its explicit partial and excluded decisions. |
| ANSIbench, Embench-IoT, Rodinia, Parboil, GAPBS, GARDENIA, GBBS, GraphAI, Pannotia, SAGA-Bench, lac-dcc, and selected GitHub suites | Existing source-specific crosswalks, including [`ANSIBENCH_COVERAGE.md`](ANSIBENCH_COVERAGE.md), [`RODINIA_COVERAGE.md`](RODINIA_COVERAGE.md), and [`GITHUB_BENCHMARKS_COVERAGE.md`](GITHUB_BENCHMARKS_COVERAGE.md) | Existing partial suite inventories; continue from each crosswalk rather than duplicating its candidates. |
| Library Checker / Yosupo Judge | [Official problem index](https://judge.yosupo.jp/) and [upstream problem-category inventory](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/categories.toml) | The task taxonomy has been inspected. Graph, Tree, String, Geometry, Big Integer, and Other now have item-by-item crosswalks; Polynomial/Set Power Series and Enumerative Combinatorics have category audits; Data Structure, Convolution, Number Theory, and Linear Algebra have item-by-item first passes whose candidate contracts still need review. Static suite registrations cover the segment-add, range-mode, packed-bitset predecessor, set-XOR-min, additive and noncommutative potential DSU, range-parallel and persistent union-find, Eulerian-circuit counting, bipartite edge coloring, vertex-biconnected blocks, two-edge-connected components, chordal recognition, minimum-cost b-flow, per-edge C4 counting, complement-component traversal, weighted tree diameter, path-jump query, vertex-set path composition, batched prefix-substring LCS, arbitrary- and fixed-root point-set tree path-composite sums, minimum-diameter spanning tree, tree-distance frequency histogram, hafnian, GF(2) matrix product and determinant, arbitrary-modulus determinant, F2-space intersection, quotient-enumeration, floor-sum, modular-prefix-minimum, bounded-rational-neighbor, Stern–Brocot, square-free-counting, Bernoulli-number, integer-kth-root, two-square-representation, summatory-totient, large multiplicative-function, Gaussian-integer-GCD, 64-bit Nim-product, extended-discrete-log, generalized-tetration, and modular-kth-root profiles. The finite and infinite weighted power-sum packages and two distinct Geometry candidates are implemented. The upstream problem repository identifies its license as Apache-2.0; this project uses taxonomy and algorithm names only. |
| NAS Parallel Benchmarks | [NASA suite definition](https://www.nas.nasa.gov/software/npb.html); existing [`lac-dcc` NPB-serial crosswalk](LAC_DCC_BENCHMARKS_COVERAGE.md#npb-serial) | `npb_is`, `npb_serial_dc`, and EP are present. Bounded CG, FT, MG, BT, SP, LU SSOR core, UA, and smallest-parent data-cube profiles have ten language ports and static suite registration; LU uses supplied operators and omits the full CFD setup. The smallest-parent data-cube profile retains all views and derives each from its least-populated immediate superset. BT-IO, DT, multi-zone variants, and GridNPB compound tasks have been reviewed and excluded because they add I/O, communication, or orchestration rather than a distinct local numerical algorithm. |
| HPC Challenge | [Official suite description](https://www.hpcchallenge.org/hpcc/) and [FAQ](https://hpcchallenge.org/hpcc/faq/index.html) | Kernel-level comparison complete: HPL's pivoted LU solve is represented by `linpack_lu_solve`; DGEMM by `gemm`; STREAM's four vector loops by `stream_vector_kernels`; PTRANS's local transpose operation by `matrix_transpose`; RandomAccess by the distinct `hpcc_random_access` random-update profile; and 1-D FFT by the radix-2 FFT family. The RandomAccess package has ten ports, independent dense/sparse oracles, workload, provenance, and suite registration. PTRANS's simultaneous inter-node exchanges and b_eff's communication-latency/bandwidth patterns are excluded as distributed-runtime behavior outside the single-call ABI. This is algorithm coverage, not a claim of official HPCC result equivalence. |
| HPCG | [Official operation and solver description](https://www.hpcg-benchmark.org/) and [HPCG 3.1 specification](https://github.com/hpcg-benchmark/hpcg) | Confirmed distinct bounded profile: ten ports, sparse and dense independent oracles, workload, provenance, and byte-output suite wiring. The profile couples CSR SpMV, symmetric Gauss–Seidel pre/post-smoothing, one `PᵀAP` coarse correction, and preconditioned CG. Pair aggregation and a single coarse level are explicit profile choices; MPI, official scale classes, and tuning are excluded. |
| PARSEC | [Princeton technical report](https://www.cs.princeton.edu/techreports/2010/890.pdf) | The 13-application inventory received an initial name/domain comparison on 2026-10-29 and further static kernel reviews on 2026-11-12. Bodytrack, Fluidanimate, and Swaptions have bounded distinct profiles; Facesim remains under source review, and compound application behavior is not fully represented. |
| SPLASH-2 | [SPLASH-2 source mirror and core-program inventory](https://github.com/staceyson/splash2) | The 11-program inventory received an initial comparison on 2026-10-29 and further static kernel reviews on 2026-11-12. FFT, FMM, Ocean, Radiosity, Water-Nsquared, and Water-Spatial have bounded profiles; the multi-program application behaviors remain only partially represented. |
| CP-Algorithms | [Official navigation index](https://cp-algorithms.com/navigation.html) | Category-index comparison begun on 2026-10-29. The index spans algebra, data structures, dynamic programming, strings, geometry, graphs, linear algebra, combinatorics, numerical methods, and miscellaneous algorithms. Static package-name comparison confirms many covered items (including Li Chao, segment tree beats, Eertree, suffix structures, flows, geometry, and graph algorithms). The 2026-11-12 static pass compared the geometry and data-structure entries against local paths and their README contracts; the base structures, tree/query families, hull and pair-geometry methods are represented, while explicit operation/method candidates are recorded below. Online bridge finding and strong orientation have since been checked and registered as distinct packages; full article-by-article comparison remains open. |
| OI Wiki | [English site](https://en.oi-wiki.org/) and [Link-Cut Tree article](https://en.oi-wiki.org/ds/lct/) | A targeted 2026-11-12 pass compared remaining graph, number-theory, and data-structure entries against package paths and README contracts; the overall catalog review remains partial. The sampled graph entries for minimum arborescence, Stoer–Wagner, Gomory–Hu, min-diameter spanning tree, dynamic trees, and exact graph Steiner-tree subset DP are represented. Number-theory samples including Meissel–Lehmer, Du Jiao/totient summation, Min_25, and linear recurrences are represented. The major balanced/dynamic trees, segment-tree variants, Cat Tree, and kinetic tournament tree are represented. The Steiner solver differs from the local finite-family gain-greedy approximation profile. |
| Algorithm Archive | [Official project site](https://www.algorithm-archive.org/) and its [chapter summary](https://raw.githubusercontent.com/algorithm-archivists/algorithm-archive/main/SUMMARY.md) | Current table of contents and licensing reviewed on 2026-10-29. The executable algorithm chapters are compared with local packages below; conceptual, incomplete, and rendering-only chapters are recorded as exclusions. The project licenses examples as MIT and text under CC BY-SA 4.0; this repository uses descriptions for discovery and writes independent implementations. |
| Rosetta Code | [Official category index](https://rosettacode.org/wiki/Category:Algorithms) | The official category URL is inaccessible to the current web reader, so its membership could not be audited directly. A partial, representative task-page comparison was made through the Rosetta Code mirror at RosettaGit on 2026-11-12 (sorting, string, graph, number, and combinatorial tasks); it is not a full category review. Sattolo's cycle remains checked against primary correctness and algorithm descriptions, although its official task page was unavailable. Use task pages only to identify algorithms; do not copy implementations or task text. |
| Codewars and LeetCode | [Codewars kata-authoring guidelines](https://docs.codewars.com/authoring/guidelines/kata/) and [LeetCode terms](https://leetcode.com/terms/) | A title-only review began on 2026-11-12. LeetCode prohibits crawling/scraping/spidering and reuse of site content; use public titles/topic tags only for discovery, never problem text, tests, examples, or submissions. This is not a complete catalog audit. |

## Catalog and suite candidates added during reviews through 2026-11-12

**In progress — root:** `tree_min_cost_edge_coloring` reserves the
minimum-cost proper edge coloring of a tree with a shared cost per color.
[`tree_min_cost_proper_coloring`](t/tree_min_cost_proper_coloring/README.md)
colors vertices and enforces a different adjacency relation; the existing
matching and bipartite edge-coloring packages do not optimize costs over a
tree's incident edges. Static README and name searches found no matching
package. [Zhou and Nishizeki](https://doi.org/10.1023/B:JOCO.0000021940.40066.0c)
describe a bottom-up DP with simultaneous matching sensitivity, and
[Ito et al.](https://doi.org/10.1587/transinf.E94.D.190) give a distinct
global matching reduction. Reserve the former fast DP profile; do not replace
its requested matching sensitivity with the exponential reference. A bounded
contract, small independent references, and an unexecuted fast construction
draft and C, C++, Rust, Elisa, Nim, Zig, Odin and C3 port drafts using rectangular matching plus alternating exchanges and a workload are present; two other language ports and
suite wiring remain. Only mathematical ideas are used; no source prose or code
is copied. Nothing has been executed. Do not duplicate this reservation.

**Source clarification needed:** The [CP-Algorithms Hungarian-algorithm article](https://cp-algorithms.com/graph/hungarian-algorithm.html)
describes a weighted tree coloring with only adjacent vertices required to
differ, then proposes an assignment of distinct colors to all children.
Those are different constraints: siblings can share a color under ordinary
proper coloring. Do not attribute the stronger sibling-distinct problem to the
stated contract or use that recurrence for it. This lead is not yet an
implemented or confirmed missing benchmark; compare both explicitly defined
problems against the inventory before reserving either.

**In progress — root:** `tree_min_cost_proper_coloring` reserves the ordinary
proper vertex-coloring optimization with a separate cost for each vertex and
color. [`graph_coloring`](g/graph_coloring/README.md) counts colorings of small
general graphs rather than optimizing cost, while the Hungarian packages solve
assignment rather than tree dynamic programming. Static name and README
searches found no equivalent tree cost-coloring package. The tree-coloring
description in the [CP-Algorithms Hungarian article](https://cp-algorithms.com/graph/hungarian-algorithm.html)
is an idea index only; its sibling-distinct assignment recurrence is not used
for this ordinary proper-coloring contract. A bounded contract, independent
reference drafts, ten language drafts, workload, package checker, and scalar
suite wiring are present; all remain unverified. Nothing has been executed. Do not
duplicate this reservation.
The verifier draft includes maximum-size chains, stars and input-validation
precedence cases with directly derived expected results; they remain unrun.

**In progress — root:** `fixed_length_walk_count` reserves modular counting of
directed walks of exactly `k` edges by adjacency-matrix powers. The existing
[`matrix_exponentiation`](m/matrix_exponentiation/README.md) builds a companion
matrix for a linear recurrence rather than taking a general graph; the adjacent
`fixed_length_walk_minplus` uses minimum-plus weights, not counting arithmetic.
Static README and name searches found no matching general-graph exact-walk
counting profile. The [CP-Algorithms fixed-length paths article](https://cp-algorithms.com/graph/fixed_length_paths.html)
is an idea index only; all code, wording, and fixtures are independently
authored. A contract, two references, ten language drafts, workload, package
checker and scalar-suite wiring are present; all remain unverified. No code has run.
Do not duplicate this reservation.

**In progress — root:** `fixed_length_walk_minplus` reserves directed shortest
walks with an exact edge count, using binary powers over the min-plus semiring.
The existing `matrix_exponentiation` uses ordinary modular arithmetic;
`floyd_warshall` permits any walk length, and `minimum_mean_cycle_karp` uses
length-indexed dynamic programming to optimize a cycle mean. Subsequent static
review found [`apsp_min_plus_repeated_squaring`](a/apsp_min_plus_repeated_squaring/README.md),
which uses min-plus squaring for at-most-length all-pairs paths with positive
weights, and [`min_plus_distance_product`](m/min_plus_distance_product/README.md),
which computes a single product. The reserved profile differs through its
exact arbitrary edge count, negative cycles and selected-power vector updates;
it does not duplicate either contract. The
[CP-Algorithms fixed-length paths article](https://cp-algorithms.com/graph/fixed_length_paths.html)
is an algorithmic idea index; its prose and examples are not copied. A bounded
contract, two reference drafts, ten language drafts, workload, an inventory checker, and draft scalar
runner/verifier wiring are present. Integration remains unverified. Nothing has been run; do not
duplicate this reservation.
The verifier draft now includes full-size dense matrices with closed-form
results and explicit invalid boundary frames; it remains unexecuted.

**Inventory correction:** The earlier reservation snapshots immediately below
understate current coverage for `monotone_radix_heap`,
`minimum_area_enclosing_rectangle`, `closest_pair_sweep`,
`highest_label_push_relabel`, and `dinic_capacity_scaling`. Static inspection
now finds all ten language drafts, workloads, two reference models, package
checkers, and runner/verifier registrations for each. These entries remain
drafts pending execution and validation; do not assign duplicate ports. Their
earlier descriptions retain the algorithm-distinction and provenance decisions.

**In progress — root:** `monotone_radix_heap` is reserved for a monotone integer priority queue with XOR-prefix buckets and redistribution after the minimum advances. [`dial_bucket_shortest_paths`](d/dial_bucket_shortest_paths/README.md) uses a fixed ring of exact-distance buckets; ordinary heap packages use comparison-based ordering. Neither exposes this radix-bucket queue operation. The [Ahuja–Mehlhorn–Orlin–Tarjan paper](https://doi.org/10.1145/77600.77615) identifies radix heaps as monotone priority queues for shortest paths; mathematical ideas only, independently authored code and fixtures. The bounded operation contract, two references, ten language drafts, workload, package checker, and scalar suite registration are present. Compilation and runtime verification remain outstanding. Nothing has been executed. Do not duplicate this reservation.

C++, Rust, and Elisa drafts are also present. Six language drafts, workload, package checker, and scalar suite registration remain outstanding. None has been compiled or run.

C3, Nim, and Zig drafts are now present. Odin, V, Mojo, workload, package checker, and scalar suite registration remain outstanding. No code has been compiled or run.

Odin, V, and Mojo drafts are now present, bringing the package to ten language drafts. The workload, rights note, package checker, and scalar runner/verifier registration are written. Verifier source specifies short operation traces, boundary keys, maximum frames, and null inputs. No code or fixture has been executed; source-level review remains outstanding.

The radix-heap workload now includes reinsertion at the current minimum and a high-bit boundary pair, exercising bucket-zero and high-prefix redistribution. These fixtures and the updated checker remain unexecuted.

**In progress — root:** `minimum_area_enclosing_rectangle` is reserved for the minimum area of a rectangle enclosing a strictly convex polygon. The existing [`rotating_calipers`](r/rotating_calipers/README.md) computes the diameter via antipodal pairs, while [`minimum_diameter_spanning_tree`](m/minimum_diameter_spanning_tree/README.md) is a graph optimization. The rectangle operation uses four rotating supports and exact rational area comparisons, so its measured state transitions differ. [Toussaint's rotating-calipers paper](https://ptacts.uspto.gov/ptacts/public-informations/petitions/1536341/download-documents?artifactId=a4dYnzeXTQb2XDkU2Gq_sp88LLBLXNLPEaKi_yIOyyJP7zr_lAjz3iU) describes the method and attributes the edge-alignment theorem to Freeman and Shapira. Mathematical ideas only; independently authored contract and references. The contract, references, ten language drafts, workload, checker, and byte-output suite integration are present; compilation and runtime verification remain outstanding. Nothing has been executed. Do not duplicate this reservation.

C, C++, and Rust rotating-support drafts are now present. Seven language ports, workload, checker, and byte-output suite integration remain outstanding; none has been compiled or run.

An Elisa rotating-support draft is also present, using bounded input and output views. Six language ports, workload, checker, and byte-output suite integration remain outstanding; no code has been compiled or run.

C3, Nim, and Zig rotating-support drafts are now present. Odin, V, Mojo, workload, checker, and byte-output suite integration remain outstanding; no code has been compiled or run.

Odin, V, and Mojo rotating-support drafts are now present, bringing coverage to ten language drafts. A workload, rights note, package checker, and byte-output runner/verifier registration are written. Verifier source specifies rotated convex chains, maximum frames, and output/input error probes. No code or fixture has been executed; source-level review remains outstanding.

The rectangle workload now includes a nonintegral minimum area (`64/5`) and the package checker requires it. This fixture remains unexecuted.

**In progress — root:** `closest_pair_sweep` is reserved for the planar closest-pair sweep with a y-ordered active set. [`closest_pair_divide_and_conquer`](c/closest_pair_divide_and_conquer/README.md) recursively partitions and merges y-ordered strips; [`pargeo_bichromatic_closest_pair`](p/pargeo_bichromatic_closest_pair/README.md) searches two color-specific KD-trees. Neither implements this single-set sweep. The [Tulane computational-geometry lecture](https://www.cs.tulane.edu/~carola/teaching/cs6463/fall10/slides/sweepline.pdf) describes the sweep and balanced-tree active set; mathematical method only, no copied text or code. Contract, two references, ten language drafts, workload, package checker, and scalar suite integration are present. Compilation and runtime verification remain outstanding. No code has been run. Do not duplicate this reservation.

C and Rust drafts are also present. C uses an explicitly balanced AVL active set and merge sort; Rust uses its ordered set. Seven language drafts, workload, package checker, and scalar suite integration remain outstanding. None has been compiled or run.

An Elisa draft now uses a bounded input view, fixed arrays, merge sort, and an indexed AVL active set. Six language drafts and suite wiring remain outstanding; the new draft has not been compiled or run.

A Nim draft now uses an indexed AVL active set and standard sort. C3, Odin, V, Zig, and Mojo drafts, workload, checker, and scalar suite registration remain outstanding. No draft has been compiled or run.

A C3 draft now uses indexed AVL nodes and merge sort. The workload and rights note are also written. Odin, V, Zig, Mojo, the package checker, and scalar suite registration remain outstanding; none of this work has run.

A Zig draft now uses an indexed AVL active set and heap sort. Odin, V, Mojo, the package checker, and scalar suite registration remain outstanding. The draft has not been compiled or run.

An Odin draft now uses indexed AVL nodes and merge sort. V, Mojo, the package checker, and scalar suite registration remain outstanding; no execution was performed.

A V draft now uses indexed AVL nodes and merge sort. Mojo, the package checker, and scalar suite registration remain outstanding; the draft has not been compiled or run.

A Mojo draft now uses indexed AVL nodes and merge sort, bringing the package to ten language drafts. A package checker and scalar runner/verifier registration are written; verifier source specifies small grids, input reversal, maximum frames, and null inputs. Nothing has been compiled or run; source-level review remains outstanding.

The timed closest-pair workload now includes 64 horizontal points, exercising a maximum-length frame and repeated active-set expiry. The fixture and updated checker remain unexecuted.

**In progress — root:** `highest_label_push_relabel` is reserved for highest-active-height scheduling of preflow discharge. The existing [`push_relabel`](p/push_relabel/README.md) ports select active vertices by scan order on a multi-terminal contract; their pinned sources mention other schedules but the ports do not benchmark this highest-label policy. The [CP-Algorithms improved push–relabel article](https://cp-algorithms.com/graph/push-relabel-faster.html) describes the algorithmic distinction and credits Cheriyan and Maheshwari. Its text is CC BY-SA 4.0; use ideas only and independently author code and fixtures. The bounded contract, two references, ten language drafts, workload, package checker, and scalar suite registration are present. Compilation and runtime verification remain outstanding; no code has run. Do not duplicate this reservation.

C3, Nim, Zig, Odin, V, and Mojo drafts are now present too, bringing the total to ten languages. A workload, rights note, package checker, and scalar runner/verifier registration are written. The verifier source specifies small capacity combinations, transposed networks, maximum frames, null inputs, and comparisons with min-cut and scaled-Dinic references. None of the drafts or fixtures has been compiled or run; source-level review remains outstanding.

The highest-label workload now includes a nonfirst source and a constrained sink with antiparallel arcs and excess returning toward the source. The package checker requires these unexecuted fixtures.

**In progress — root:** `dinic_capacity_scaling` is reserved for thresholded blocking-flow phases. The existing [`dinic_maxflow`](d/dinic_maxflow/README.md) ports use ordinary positive-residual Dinic; its pinned Python source mentions a scaling variant but the timed ports do not implement it. A threshold limits BFS and blocking-flow traversal to residual arcs of at least the current power of two, changing the explored residual networks. The [MIT blocking-flow notes](https://courses.csail.mit.edu/6.854/21/Scribe/s7-blockingFlows/scribe7.html) describe capacity scaling; mathematical idea only, with independently authored code and fixtures. The initial contract matches the existing bounded directed graph input. The contract, two independent references, ten language drafts, workload, package checker, and scalar suite registration are present. Compilation and runtime verification remain outstanding. Nothing has been run. Do not duplicate this reservation.

C3, Nim, Zig, Odin, V, and Mojo drafts are also present, bringing the total to ten languages. The workload, rights note, package checker, and scalar runner/verifier registration are written. The verifier source specifies small capacity combinations, antiparallel arcs, maximum frames, and null inputs. No draft or fixture has been compiled or run; source-level review remains outstanding.

The scaled-flow verifier source also specifies transposing every arc while swapping terminals, and splitting each edge into equal-total parallel capacities. These invariants exercise antiparallel residuals and capacity aggregation; they have not been executed.

**In progress — root:** [`planted_3sat_clause_generator`](p/planted_3sat_clause_generator/README.md) implements the planted-assignment model described by [Feige and Vilenchik](https://www.wisdom.weizmann.ac.il/~feige/TechnicalReports/FeigeVilenchik.pdf). The existing `random_planted_3sat_majority_vote` and `random_planted_3sat_k_opt` consume formulas and search for assignments; they do not generate satisfying clauses. This profile takes a planted assignment and bounded choice tape, un-ranks each three-variable subset, and selects one of seven satisfied polarity patterns. Uniform independent choices yield the paper's fixed-clause-count model; the benchmark itself is deterministic. The contract, two reference drafts, workload, ten language drafts, package checker, and byte-output runner/verifier wiring are present. The verifier source specifies small exhaustive cases, satisfaction checks, maximum frames, and error probes. The empty-formula and error-handling contracts have received source-level review; compilation and runtime verification remain outstanding. Mathematical model only; no source code or examples copied. Do not duplicate this reservation. No code has been run.

**In progress — root:** [`divide_conquer_tangent_hull`](d/divide_conquer_tangent_hull/README.md) uses recursive splitting and common-tangent merging, distinct from monotone-chain scanning, Quickhull partitioning, and Chan's grouped wrapping. The book's Convex Hulls chapter and [Mount's geometry notes](https://www.cs.umd.edu/class/spring2026/cmsc754/Lects/lect02-hulls-1.pdf) identify the method; mathematical ideas only. The bounded contract, two reference drafts, workload, rights note, ten language drafts, package checker, and byte-output runner/verifier wiring are present. The verifier source specifies reflected convex chains, deterministic general-position sets, input permutations, malformed frames, and capacity probes. Static review remains outstanding; no code has been run. Do not duplicate this reservation.

**In progress — root:** [`chan_output_sensitive_hull`](c/chan_output_sensitive_hull/README.md) implements grouped hull construction, logarithmic tangent-search drafts, and repeated size guesses, distinct from Jarvis scan and monotone chain. Sources: [Chan's original paper](https://sites.cs.ucsb.edu/~suri/cs235/ChanCH.pdf) and [KIT tangent-search notes](https://i11www.iti.kit.edu/_media/teaching/sommer2018/compgeom/psession1.pdf); mathematical ideas only. The bounded contract, monotone-chain and linear-scan grouped references, tangent oracle and search draft, workload, rights note, ten language drafts, package checker, and byte-output runner/verifier wiring are present. The verifier source specifies convex chains, interior-point permutations, equal-x cases, generated sets, malformed frames, and capacity probes. The shared binary tangent-search invariant and ports still require static review. None has been compiled or run. Do not duplicate this reservation.

The Chan reference-check source now specifies comparisons of the binary tangent draft with the exhaustive supporting-vertex oracle across general-position five-point grid subsets, every global hull query, subgroup hulls, and cyclic rotations. These comparisons are unexecuted and do not establish correctness of the ports.

**In progress — root:** `functional_graph_cycle_brent` is reserved for Brent's power-of-two cycle detection on the same bounded successor-map contract as [`functional_graph_cycle_parameters`](f/functional_graph_cycle_parameters/README.md), whose ports use Floyd's two-speed method. [`pollard_rho_rust`](p/pollard_rho_rust/README.md) incorporates a Brent-style schedule inside factorization, but does not expose cycle parameters of an arbitrary supplied functional graph. Brent's schedule changes successor evaluations and state transitions, so this is a distinct method. Ten language drafts, two reference drafts, a workload, static package checker, and scalar runner/verifier registration are present; static review remains outstanding. Sources: [formal cycle-finding study](https://ticamore.logic.at/publications/ITP_2018_paper_16.pdf) and [CP-Algorithms factorization discussion](https://cp-algorithms.com/algebra/factorization.html); algorithm descriptions only. No code was executed. Do not duplicate this reservation.

Brent workload source now includes a nonzero starting vertex with a tail and a malformed successor outside the reachable component, covering whole-map validation. These fixtures and the checker change remain unexecuted.

Static review of the related Floyd cycle package found that its workload used the `algorithm` key twice, causing the descriptive object to overwrite the benchmark identifier when JSON is parsed. The descriptive object is now named `algorithm_details`, and the package checker requires it. This repair remains unexecuted.

The same static search found and corrected that duplicate top-level key in 25 additional workloads: planar face count, undirected Chinese postman, trapping rain water II, ISAP maxflow, tree edge painting, Johnson flow shop, circle-line intersection, connected labeled graphs, common circle tangents, convex polygon minimax triangulation, distinct palindromic subsequences, largest zero submatrix, logarithmic convex-polygon queries, Steiner subset DP, half-plane intersection, temporary task load balancing, prime-power binomial coefficients, Bostan–Mori recurrence, balanced ternary conversion, bishop placements, virtual tree, X-fast trie, disjoint sparse table composition, deadline scheduling, and dynamic MEX. Their description objects now use `algorithm_details`, preserving the benchmark names expected by their checkers and runners. A text search found no remaining workloads with the same indented object-key pattern. No parser, checker, program, or test was run.

The shared workload loader now rejects duplicate JSON object keys, and is wired into the build entry point plus scalar, byte-output, and float64-slice runner/verifier workload loads. This prevents silent overwrites at any object nesting level in those paths; other entry points have not been audited. Existing unknown duplicate keys may now surface as errors and require correction. The change remains unexecuted.

The same loader is now wired into the generic runner, binary-scalar runner, three tree runners, and the i32-array byte-output, i64-triple, i64-scalar byte-output, and i64-array/float64 runners. Many standalone verifier and package-checker loads still use their existing JSON parsing; this is not a claim that every workload entry point is covered. No code was executed.

The standalone checkers for planted 3-SAT generation, divide-and-conquer and Chan hulls, Brent cycle detection, and directed girth now also use the duplicate-key-checking workload loader. Other package checkers remain to be audited. This change has not been executed.

**In progress — root:** [`space_saving_frequent_items`](s/space_saving_frequent_items/README.md) is distinct from [`misra_gries_summaries`](m/misra_gries_summaries/README.md): a full Space-Saving summary replaces one least-count item and carries its minimum as error, rather than decrementing all counters. A bounded deterministic contract, primary and independent reference drafts, workload, ten language drafts, byte-output runner/verifier wiring, and provenance note are present; static review remains outstanding. Source: [Metwally, Agrawal and El Abbadi (2005)](https://dblp.dagstuhl.de/rec/conf/icdt/MetwallyAA05.html), algorithmic description only. Do not duplicate this reservation. Nothing has been executed.

**In progress — root:** [`directed_girth_bfs`](d/directed_girth_bfs/README.md) is reserved for shortest directed cycle length via BFS from each vertex. `check_cycle` only detects existence, and `minimum_mean_cycle_karp` minimizes weighted mean cost. A contract, two reference drafts, workload, ten language drafts, and scalar runner/verifier wiring are present; static review remains outstanding. The [CP-Algorithms BFS applications](https://cp-algorithms.com/graph/breadth-first-search.html) are used for method identification only. No code was executed.

Static review corrected the Elisa Space-Saving draft's return-type declarations and made the empty-summary sort loop explicit. This edit remains uncompiled and untested.

The Nim, V, and Mojo Space-Saving drafts now also use explicitly bounded sort loops when the stream is empty. These edits remain uncompiled and untested.

Static Zig review renamed the Space-Saving sort index to avoid shadowing later loop captures. The draft remains uncompiled and untested.

The corresponding Nim, V, and Mojo sort indices were also given distinct names to avoid collisions with later loop variables. These drafts remain uncompiled and untested.

The Space-Saving verifier source now specifies a closed-form alternating-stream invariant for every supported nonempty stream length when there is one counter. This check remains unexecuted.

The Elisa Walker–Vose, Melkman, and both HyperLogLog drafts had the same return-type declaration issue; their signatures now follow the surrounding Elisa ports. None has been compiled or tested.

**In progress — root:** [`hyperloglog_corrected_estimate`](h/hyperloglog_corrected_estimate/README.md) extends the separately registered raw core with the original small-range linear-counting and large-range hash-collision corrections. A full supplied-hash contract, primary and high-precision independent reference drafts, workload, ten language drafts, and byte-output suite wiring are present; static review remains outstanding. The workload includes each correction regime and explicitly expects `-3` when the large-range logarithm has no finite real value. Source: [Flajolet et al.'s original paper](https://algo.inria.fr/flajolet/Publications/FlFuGaMe07.pdf), Figure 3, mathematical description only. No source prose, code, or examples were copied. Do not duplicate this reservation. No code was executed.
The corrected workload and verifier source now cover scaled register sums of 22 and 21, the adjacent finite and saturated sides of the hash-space boundary. The verifier source also varies the number of nonempty buckets through the small-range transition. These cases remain unexecuted.
The corrected estimator now also has maximum-length repeated-bucket workload records; the verifier source checks that repeating the same hashes leaves the estimate unchanged. These additions remain unexecuted.
The verifier source also specifies a mixed-rank stream, compares both references, and checks invariance under reversing and duplicating its hashes. These checks have not been executed.
For uniform nonzero register ranks in the uncorrected range, the verifier source also compares the corrected profile against the separate exact-rational raw core. This cross-profile check remains unexecuted.

**In progress — root:** [`hyperloglog_raw_estimate`](h/hyperloglog_raw_estimate/README.md) records the original 16-bucket HyperLogLog register-update and raw-estimate core, which differs from local [`hyper_log_log`](h/hyper_log_log/README.md)'s source-specific identity-indexed, touched-register-only calculation. A bounded supplied-hash contract, two reference drafts, workload, ten language drafts, provenance note, and byte-output suite wiring are present. This profile omits the original small- and large-range corrections; the separate corrected-estimate draft above covers them, but remains unverified. Source: [Flajolet et al., 2007](https://dmtcs.episciences.org/en/articles/3545); mathematical description only. Do not duplicate this reservation. Nothing has been executed.
The raw-core workload includes a maximum-length stream with rank 29 in every bucket and a repeated-bucket trace that increases then retains a register. These records remain unexecuted.
The raw-core verifier source also specifies a mixed-rank stream, compares independent references, and checks order and duplicate invariance. These checks remain unexecuted.
The raw-core verifier also specifies the exact reduced estimate for uniform register ranks 1 through 29; this formula check remains unexecuted.

**In progress — root:** [`melkman_simple_polyline_hull`](m/melkman_simple_polyline_hull/README.md) is distinct from the unordered-point Graham and monotone-chain profiles: it maintains an online deque hull for a promised simple polyline in linear time. A bounded contract, workload, ten language drafts, deque and sorted-hull reference drafts, provenance note, and byte-output runner/verifier wiring are present; static review remains outstanding. The verifier source includes maximum-size parabola chains in both directions and reference comparisons. Source: [Melkman's 1987 publication record](https://www.bgu.ac.il/en/researcher/avraham-melkman/publications/317593075/); mathematical algorithm only, no copied text or code. Do not duplicate this reservation. No code was executed.
The workload now includes a 32-vertex simple parabola chain that fills both the input and output bounds, alongside its short-output variant. These records have not been executed.
Two additional simple-chain fixtures traverse a path with an interior vertex and an exterior extension in opposite directions, exercising hull removal and reinsertion beyond the all-convex maximum case. They remain unexecuted.
The Melkman workload also has forward and reverse x-monotone zigzags with alternating extreme vertices, to exercise both deque ends. These records remain unexecuted.
The verifier source also specifies translation-invariance checks for bounded parabola chains. These checks remain unexecuted.
Its malformed cases now include a short frame, too few points, and rejection of a collinear initial triple before considering a null output. These cases are unexecuted.

**In progress — root:** [`walker_vose_alias_sampling`](w/walker_vose_alias_sampling/README.md) is a distinct discrete sampler: linear preprocessing followed by constant-time draws, rather than the existing rejection loop or weighted subset selection. A bounded integer-tape contract, workload, ten language drafts, two reference drafts, and byte-output runner/verifier wiring are present; static review remains outstanding. The [SciPy method description](https://docs.scipy.org/doc/scipy/tutorial/stats/sampling_dau.html) and [Vose citation](https://commons.apache.org/proper/commons-rng/commons-rng-sampling/xref/org/apache/commons/rng/sampling/distribution/AliasMethodDiscreteSampler.html) are used only for algorithm identification. Do not duplicate this reservation. Nothing has been executed.
Static registration review removed an early return that bypassed the runner's shared fixture checks. The verifier source also specifies exact small-table distribution counts over every column and ticket; neither check has been executed.
The Walker–Vose workload now explicitly covers equal weights, multiple small columns, reclassification of a formerly large column, invalid weights, and invalid-input precedence over a null output. These fixtures are unexecuted.
Static language review renamed a C3 local that collided with its `alias` keyword and made the workload's numeric bounds and empty-draw behavior explicit. The C3 draft remains uncompiled.
The same keyword collision was removed from the Mojo draft during subsequent static review; that draft remains uncompiled as well.
The runner's package-specific metadata checks now pin the category, draw and weight bounds, zero-draw null-output behavior, no-write-on-error rule, and measurement model. These checks remain unexecuted.
The Elisa alias-sampling draft now accesses validated input and output through bounded views, retaining ABI references only at the boundary. This change is uncompiled.
The workload also specifies maximum-size uniform and sparse distributions, plus a short-output maximum frame. The sparse profile exercises alias-table construction as well as sampling; none has been executed.
An additional 32-draw trace alternates immediately below and at an alias threshold, exercising both outcomes in one full output frame. It has not been executed.
The verifier source also specifies proportional weight-and-ticket scaling checks, which remain unexecuted.

These are source-backed audit leads, not silently assumed omissions. Each row is checked against repository paths and the named operation; pending rows require a fuller contract comparison before implementation or duplicate decisions.

| Source candidate | Initial repository comparison | Decision / next action |
| --- | --- | --- |
| Karp minimum directed cycle mean (tracked Encyclopedia of Algorithms graph topic) | [`negative_cycle_detection`](n/negative_cycle_detection/README.md), Bellman–Ford, and Johnson packages detect negative cycles or compute shortest-path distances. None minimizes total edge weight divided by cycle length. | Implemented and registered as `minimum_mean_cycle_karp` in all ten languages: bounded strongly connected directed graph with unique ordered endpoint pairs (self-loops allowed), `1<=n<=8`, `1<=m<=min(16,n²)`, and edge weights in `[-1000,1000]`; maximum valid input is 50 i64 values. Primary uses Karp's exact-length path DP and min-max characterization; an independent simple-cycle enumeration oracle compares reduced rational means exactly. Byte output is `[numerator,positive_denominator]` as two little-endian i64 values (16 bytes), workspace is 2048 bytes, and malformed/null/short-output results are `-1`/`-2`. The maximum-input fixture is an 8-vertex bidirected ring with 16 edges. Source discovery is the tracked *Encyclopedia of Algorithms* “Negative Cycles in Weighted Digraphs” chapter; the distinct minimum-cycle-mean algorithm is attributed to Karp's original characterization, DOI [10.1016/0012-365X(78)90011-0](https://doi.org/10.1016/0012-365X(78)90011-0). Byte-output workload validation, static inventory review, and generated random, maximum, malformed, null, and capacity profiles are registered. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |
| [CP-Algorithms maximum-flow catalog](https://cp-algorithms.com/navigation.html) | Compare the listed Edmonds–Karp, Dinic, and push–relabel methods against [`edmonds_karp`](e/edmonds_karp/README.md), [`dinic_maxflow`](d/dinic_maxflow/README.md), and [`push_relabel`](p/push_relabel/README.md). | Already present: these names describe the same underlying flow methods as the existing packages, so no duplicate entries are reserved. This is a name-and-method crosswalk, not a claim that the entire catalog or every language port has been verified. The source's descriptions are used only for identification. |
| [CP-Algorithms negative-cycle search](https://cp-algorithms.com/graph/finding-negative-cycle-in-graph.html) | [`negative_cycle_detection`](n/negative_cycle_detection/README.md) uses global Bellman–Ford relaxation and extracts a cycle witness. | Already present as the same method; no duplicate package. A Mojo draft has been added to the original nine ports and remains unverified. The source is used for method identification only. |
| [CP-Algorithms Eulerian path](https://cp-algorithms.com/graph/euler_path.html) | [`eulerian_path`](e/eulerian_path/README.md) uses iterative Hierholzer traversal for directed graphs; [`eulerian_trail_undirected_simple`](e/eulerian_trail_undirected_simple/README.md) covers an undirected profile. | The same traversal family is already represented, so no additional package is reserved. Static review corrected the existing Mojo directed port to return zero for a valid graph without a trail; the fix remains unexecuted. The source is used for method identification only. |
| [CP-Algorithms articulation points](https://cp-algorithms.com/graph/cutpoints.html) | [`articulation_points`](a/articulation_points/README.md) applies DFS discovery and low-link values to every component; its bitset representation scans possible neighbors. | Already present as the same cut-vertex method, including an existing Mojo draft. No duplicate package is needed. The article is used solely to identify the method; no source text or code was copied. |
| [CP-Algorithms Prüfer code](https://cp-algorithms.com/graph/pruefer_code.html) | [`prufer_code`](p/prufer_code/README.md) already encodes and decodes labeled trees, using the largest leaf instead of the article's smallest-leaf convention. | Already present as the same leaf-removal method; the ordering convention alone does not justify a duplicate benchmark. A Mojo draft has been added to the existing package; it remains uncompiled and untested. The article is used for algorithm identification only. |
| [CP-Algorithms bipartite matching](https://cp-algorithms.com/graph/kuhn_maximum_bipartite_matching.html) | [`bipartite_matching_kuhn`](b/bipartite_matching_kuhn/README.md) uses single augmenting-path searches; `bipartite_matching_hopcroft_karp` and [`hopcroft_karp_cardinality`](h/hopcroft_karp_cardinality/README.md) shared the same bounded cardinality contract. | Kuhn and Hopcroft–Karp are distinct methods. Consolidated the duplicate Hopcroft–Karp names under `hopcroft_karp_cardinality`, preserving pinned-source provenance and the superset workload. Static review fixed the C port's queue initialization and added null guards to several ports. No code was run. |

Static Prüfer verifier review corrected the two-vertex decode frame used for capacity checks and added generated encode/decode round-trip checks. These source changes remain unexecuted.

An independent component-deletion oracle and verifier corpus have been drafted for `articulation_points`, including every simple graph through five vertices and output-buffer cases. Runtime verification remains outstanding; no code was executed.

Static review added null guards and bounded input/output views to the Elisa articulation-point and bridge ports. Their changes remain uncompiled and untested.

The Elisa Kosaraju and Two-SAT ports now likewise guard ABI references and index through bounded views. Both always emit at least one output byte, including empty inputs. These source edits have not been compiled or run.

The Elisa Tarjan SCC and 0–1 BFS ports have also received null guards and bounded input/output views. Their output is nonempty for every valid frame. These edits remain uncompiled and untested.

The Elisa directed Eulerian-path port now validates the maximum frame before constructing an input view and reuses a bounded output view after its capacity check. Empty or nonexistent paths continue to permit null output. This source change is uncompiled and untested.

Static review added null guards and bounded views to the Elisa Kahn and DFS topological-sort ports, preserving empty-order and cycle handling. Neither edit has been compiled or executed.

Elisa BFS path, DFS traversal, and both directed-cycle ports now guard their ABI input and use bounded views; the output-producing ports also guard nonempty output. These edits remain uncompiled and untested.

The Elisa breadth-first traversal and grid bidirectional-search ports now use bounded input/output views after ABI validation; nonempty traversal output also has a null guard. These edits are uncompiled and untested.

The Elisa connected-components and graph-coloring ports now use validated input views; connected components also rejects null input before reading its header. Graph coloring uses a bounded output view. These edits are uncompiled and untested.

The Elisa disjoint-set connected-components and bipartite DFS ports now read through bounded input views after validation; the former also checks null input. These edits remain uncompiled and untested.

The Elisa Dinic and Edmonds–Karp ports now guard null input and access bounded frame views after checking the maximum valid length. These source edits remain uncompiled and untested.

The Elisa push–relabel port now checks null input and reads its validated packed frame through a bounded view. This source edit remains uncompiled and untested.

Static review corrected variable scope and assignment syntax in the Elisa edge-connectivity draft, and mutable declarations, assignments, typed shifts, and input views in the vertex-connectivity draft. Both remain uncompiled and untested.

The edge-connectivity verifier source now checks the vertex-connectivity and minimum-degree bounds on generated simple graphs. This check has not been run.

The Elisa Gomory–Hu and dynamic-star global-cut ports now use bounded input views; Gomory–Hu also guards null input. Static review moved the dynamic-star candidate index into the scope where it is reused. These edits remain uncompiled and untested.

Static review moved a reused matrix index into the enclosing scope and added a bounded input view in the Elisa minimum-diameter spanning-tree draft. It also corrected the Steiner subset-DP helper declaration. Both edits remain uncompiled and untested.

The Elisa Manhattan and Euclidean MST ports now use bounded frame views; Manhattan also checks null input. Euclidean output uses a bounded view and its swapped root variables are mutable. These edits remain uncompiled and untested.

Both Elisa minimum-cost-flow profiles now use bounded input and 16-byte output views after their ABI checks. These source edits remain uncompiled and untested.

Static review also moved a minimum-cost-flow traversal variable into the scope where it is reused and made the blocking-path helper's array views explicit. These changes have not been compiled or run.

The Elisa minimum-cost b-flow port now uses validated input and output views throughout its ABI wrapper. This edit remains uncompiled and untested.

Elisa Kruskal and global negative-cycle detection now use bounded input views, and the negative-cycle output view is limited to the bytes actually emitted. Kruskal also rejects null input. These source edits are uncompiled and untested.

Elisa Prim and Gabow SCC now use bounded input views; Prim rejects null input and Gabow copies its staged result through a bounded output view. Static Gabow review also corrected mutable local declarations and its typed shift literal. None of these edits has been compiled or tested.

The Elisa fixed-point dominator port now reads and writes through bounded views after its existing ABI guards. Static review also converted the separate Lengauer–Tarjan draft's mixed declaration syntax to the local Elisa form and bounded its output view. Both remain uncompiled and untested. No code was run.

The Lengauer–Tarjan verifier source now specifies exhaustive directed graphs through three vertices and compares its semidominator and vertex-deletion references. This corpus has not been executed.

The Hopcroft–Karp port comparison found that all nine standard-language source pairs differed only in package/export identifiers after the C queue fix. The retained Mojo draft now explicitly restricts DFS to the shortest augmenting layer and imports its array type. The Rust candidate's catalog mapping points to `hopcroft_karp_cardinality`, whose README preserves the Rust source attribution. The redundant source files and workload were removed; the retained workload includes the earlier case IDs and a larger maximum case. None of these changes has been run.

**Duplicate audit, general matching:** [`edmonds_blossom_algorithm`](e/edmonds_blossom_algorithm/README.md) and the former `general_graph_maximum_matching` both implement Edmonds' cardinality blossom search. The latter used a byte-output wrapper and narrower simple-graph domain. Their implementations were consolidated under the broader scalar profile, preserving the book attribution and representative valid graph cases. The former byte-output registration and sources were removed. No code was run; all changes remain unverified.

**Ordered greedy matching comparison:** [`gbbs_maximal_matching`](g/gbbs_maximal_matching/README.md) and [`approximate_matching_greedy`](g/approximate_matching_greedy/README.md) accept an edge when both endpoints are unmatched in priority order. Static C-source review shows materially different measured work: direct indexing of a rank permutation versus repeated maximum-weight scans and a weight sum. Retain both as distinct computational profiles, and do not imply their shared acceptance rule is itself unique. Mojo drafts were added for both profiles; they remain unverified. The dynamic insertion profile additionally maintains state across updates. No code was run.

Static review of [`two_level_dynamic_maximal_matching_insertions`](t/two_level_dynamic_maximal_matching_insertions/README.md) found that its nine existing ports could read edge records before checking the declared frame length. Bounds checks have been added before those reads, and a Mojo draft has been added with the same check. The ports repair displaced mates in owner-then-selected order; both references previously sorted them. The contract and references now specify owner-then-selected order consistently. All edits remain unverified; no code was run.

The existing [`weighted_popular_matching`](w/weighted_popular_matching/README.md) profile now has a Mojo draft in addition to its nine ports. It enumerates bounded assignments and weighted voting margins like the existing profile; it is not a polynomial-time weighted-popularity algorithm. The draft remains unverified and no code was run.

The existing [`weak_stable_matching_ties_incomplete`](w/weak_stable_matching_ties_incomplete/README.md) profile also has an unverified Mojo draft. It uses the profile's deterministic tie refinement and deferred-acceptance order; no code was run.

The existing [`ranked_matching_popular_matching`](r/ranked_matching_popular_matching/README.md) profile now has a Mojo draft as well. Its alternating-class and bounded assignment search are distinct from weighted-majority popularity. The port and added last-resort fixtures remain unverified; no code was run.

Static review corrected loop-local state and a branch-local target in the ranked-matching Elisa draft, and moved ranked and weak-stable matching buffer indexing through bounded views after their ABI guards. These edits have not been compiled or executed.

The reserved `rabin_content_defined_chunking` profile now has drafts in all ten languages and byte-output runner/verifier registration, including generated rolling-versus-recomputed comparisons. All remain unexecuted.

The existing [`p2p_chord_finger_lookup`](p/p2p_chord_finger_lookup/README.md) has an unverified Mojo draft in addition to its nine original ports. Chord stabilization is a separate state-transition candidate: the [original protocol](https://pdos.csail.mit.edu/papers/ton%3Achord/paper-ton.pdf) updates successor and predecessor pointers, while the existing profile checks a fixed canonical ring and performs lookup only. [`chord_stabilization_trace`](c/chord_stabilization_trace/README.md) now has a deterministic sequential contract, two references, workload, ten language drafts and byte-output suite wiring. No source code or prose was copied and no code was executed.

The Chord lookup verifier source additionally specifies exhaustive small rings,
maximum-frame wraparound and malformed-finger precedence cases; its workload
now includes null-input and invalid-before-null-output records. These checks
remain unexecuted.

The [CP-Algorithms shortest non-appearing string application](https://cp-algorithms.com/string/suffix-automaton.html) is distinct from [`suffix_automaton`](s/suffix_automaton/README.md)'s membership/count interface: it uses automaton-state DP to reconstruct an absent word. [`shortest_absent_substring_sam`](s/shortest_absent_substring_sam/README.md) has a bounded contract, two reference drafts, workload, rights note, ten language drafts and byte-output suite wiring. The CC BY-SA article is used for method identification only; no source prose or code copied, and nothing was executed.

The existing [`frequency_count_list_update`](f/frequency_count_list_update/README.md) profile now has a Mojo draft alongside its nine ports. Its stable frequency-based exchanges remain distinct from transpose and move-to-front policies. The draft is unexecuted.
The [`online_list_update_transpose`](o/online_list_update_transpose/README.md) and [`timestamp_list_update`](t/timestamp_list_update/README.md) profiles also have unverified Mojo drafts. They preserve their respective paid-swap and prior-request rules.
The [`bit_list_update`](b/bit_list_update/README.md) and [`comb_list_update`](c/comb_list_update/README.md) profiles now have unverified Mojo drafts as well. Comb's nine existing ports are stored under `b`; its README links were corrected so the source resolver can locate them. Nothing was executed.
The transpose workload's malformed case keys and the frequency and timestamp workloads' malformed request traces were repaired. The suite now includes bounded exhaustive reference comparisons for all three deterministic list-update policies. These edits have not been executed.
Static documentation review also repaired the transpose profile's Move-to-Front cross-link and added time and space bounds for transpose and the direct-scan timestamp implementation.
Comb now has explicit empty-trace, duplicate-item, and out-of-range-request fixtures. The suite source also compares all-Timestamp Comb traces against the Timestamp profile, including unchanged initial bits. These additions are unexecuted.
Static workload inspection found a missing access-position word in both Bit and Comb maximum-output fixtures; each expected payload now includes the full 32-request trace. Their README files also state the bounds of their direct list implementations. No code was run.
Static review corrected a truncated Bit fixture whose initial bit vector was
missing one word. The suite source now specifies exhaustive small Bit and Comb
traces and cross-checks all-Bit Comb against Bit; these checks remain unexecuted.

The same [suffix-automaton application index](https://cp-algorithms.com/string/suffix-automaton.html) describes linear-time longest-common-substring scanning. [`longest_common_substring`](l/longest_common_substring/README.md) instead uses quadratic dynamic programming, so the method is distinct despite the same result. [`longest_common_substring_sam`](l/longest_common_substring_sam/README.md) matches the existing printable-ASCII contract and has two oracle drafts, workload, rights note, ten language drafts and scalar-suite wiring. Nothing was executed. The CC BY-SA page supplies the mathematical method only.

PARSEC Ferret's query-directed multi-probe LSH sequence is a distinct candidate from [`similarity_search`](s/similarity_search/README.md)'s exhaustive vector scan and [`nearest_neighbour_search`](n/nearest_neighbour_search/README.md)'s KD-tree traversal. [`multiprobe_lsh_probe_sequence`](m/multiprobe_lsh_probe_sequence/README.md) has a bounded one-table contract, heap-based and exhaustive reference drafts, workload, ten language drafts and byte-output suite registration. All remain unexecuted. The [original paper](https://www.cs.princeton.edu/cass/papers/mplsh_vldb07.pdf) is used for the algorithm description only; no code or prose is copied.
| [Turnstile one-sparse fingerprint recovery](https://dimacs.rutgers.edu/~graham/pubs/papers/l0journal.pdf) | [`ams_sketch`](a/ams_sketch/README.md) estimates a frequency moment, [`count_min_sketch_affine`](c/count_min_sketch_affine/README.md) estimates point frequencies, and [`graphai_frontier_sampler`](g/graphai_frontier_sampler/README.md) samples an explicit frontier. None is a signed-update singleton decoder with a polynomial fingerprint. | Confirmed distinct; reserved as `turnstile_one_sparse_fingerprint_recovery` for root. The bounded contract, rights note, streaming-counter primary oracle, final-vector reference, workload, package checker, drafts in all ten languages, and scalar-suite wiring are written. A caller-supplied fixed base can allow collisions; this is a recovery primitive, not the full ℓ0 sampler or graph connectivity sketch. All work remains unexecuted and requires verification. Source is used for the mathematical method only; no code or prose is copied. |
| LeetCode “Create Maximum Number” | No `create_maximum_number` package or equivalent contract was found. `longest_increasing_subsequence` returns a length; `maximum_subarray` optimizes a contiguous sum, and the catalog's `maximum_subsequence` is already classified as an alias of it. Local monotone-stack/string-merge packages cover different operations. None combines split-count enumeration, maximum digit-subsequence selection from two inputs, and lexicographic suffix-aware merge. | Implemented and registered as [`create_maximum_number`](c/create_maximum_number/README.md) in ten languages, with primary split/stack/merge oracle, independent memoized skip/take DP, workload, rights note, static package checker, byte-output suite bounds, and generated maximum-size, malformed, null-pointer, and capacity probes. Contract: input `[m,n,k,A...,B...]`, `0<=m,n<=6`, `0<=k<=m+n`, digits `0..9`, exact frame length `3+m+n`; output selected digits as raw bytes (maximum 12), `-1` malformed, `-2` null/short output. Only the catalog title/topic tags are used for discovery; no statement, examples, tests, submissions, or site code are reused. [LeetCode 321 title page](https://leetcode.com/problems/create-maximum-number/). |
| LeetCode title-index candidate: Count Different Palindromic Subsequences | [`longest_palindromic_subsequence`](l/longest_palindromic_subsequence/README.md) returns only the maximum subsequence length; [`eertree`](e/eertree/README.md) and [`palindromes_in_deque`](p/palindromes_in_deque/README.md) count distinct palindromic substrings, where positions must be contiguous. No package counts distinct palindrome sequences obtainable by deleting positions. Implemented and registered as `count_different_palindromic_subsequences`: bounded scalar input `[n,symbols...]`, `0<=n<=20`, symbols in `0..3`, with the number of distinct nonempty palindromic subsequences returned modulo 1,000,000,007. Ten language ports, O(n^2) duplicate-aware interval-DP primary oracle, independent mask-enumeration oracle, workload, README/RIGHTS, static inventory checker, and scalar runner/verifier registration are complete. Discovery uses the public title only. No LeetCode statement, examples, tests, submissions, or code are used. [LeetCode title page](https://leetcode.com/problems/count-different-palindromic-subsequences/). |
| LeetCode title-index candidate: Palindrome Pairs | No `palindrome_pairs` package or contract was found. [`eertree`](e/eertree/README.md), [`manacher`](m/manacher/README.md), and the subsequence-palindrome packages analyze one string; [`word_boggle`](w/word_boggle/README.md) matches dictionary words along board paths rather than pairing word values. No package enumerates ordered word-index pairs whose concatenation is palindromic. | Implemented and registered as `palindrome_pairs` in ten languages for a bounded byte-output profile: `0<=N<=8`, word lengths `0..8`, symbols `0..3`; empty words and duplicate values are valid. Emit all ordered distinct index pairs in lexicographic order using one byte `(left<<3)|right`, at most 56 bytes. Primary uses palindromic prefix/suffix split checks and a reversed-word multimap; independent oracle directly checks each ordered concatenation. Workload, README/RIGHTS, static inventory checker, and byte-output runner/verifier integration are complete. Discovery uses the public title only; no problem statement, examples, tests, constraints, submissions, or code are used. [LeetCode title page](https://leetcode.com/problems/palindrome-pairs/). |
| LeetCode title-index candidate: Trapping Rain Water II | [`trapped_rainwater`](t/trapped_rainwater/README.md) and [`trapped_rainwater_two_pointer`](t/trapped_rainwater_two_pointer/README.md) accept a one-dimensional height sequence and use prefix/suffix maxima or two pointers. [`flood_fill`](f/flood_fill/README.md) recolors an equal-valued connected region, not an elevation-dependent escape basin. [`npb_mg_vcycle`](n/npb_mg_vcycle/README.md) solves a bounded numerical correction cycle; [`splash2_water_nsquared`](s/splash2_water_nsquared/README.md) and [`water_spatial`](w/water_spatial/README.md) are molecular pair-interaction simulations. None computes retained volume in a two-dimensional terrain using minimax escape levels from the boundary. | Implemented and registered as [`trapping_rain_water_ii`](t/trapping_rain_water_ii/README.md) in all ten supported languages, with the bounded scalar contract `[R,C,heights row-major]`, `1<=R,C<=8`, heights in `0..1000`, exact length `2+R*C`, and `-1` for malformed input. The primary oracle and ports use a min-heap boundary flood; an independent per-cell oracle binary-searches elevation thresholds and tests boundary reachability by BFS. Includes workload, rights note, package-local static inventory checker, scalar-array workload validation, and generated random, maximum-volume, and malformed-input records. Discovery uses only the public title/topic labels; no statement, examples, tests, submissions, or site code are used. |
| CP-Algorithms Minkowski sum of convex polygons | Local `minkowski_distance` computes an Lp norm between two vectors; convex hull/layers, closest and furthest pair, enclosing circle, polygon containment, triangulation, and Euclidean MST packages do not construct the pointwise sum of two polygonal sets. | Confirmed distinct and implemented as [`minkowski_sum_convex_polygons`](p/minkowski_sum_convex_polygons/README.md): ten clean-room ports merge cyclic edge directions of strictly convex CCW integer polygons, with a pair-sum plus monotone-hull independent oracle, bounded workload, and static package checker. The byte-output suite includes maximum-size, translated/rotated, malformed, and capacity probes. CP-Algorithms describes the edge-merge method; the site is CC BY-SA 4.0. Only the algorithm description was used. [Algorithm article](https://cp-algorithms.com/geometry/minkowski.html). |
| CP-Algorithms half-plane intersection | No half-plane-intersection package or ledger entry was found. Existing line/segment intersection, point-in-polygon, convex hull/layers, polygon triangulation, and Minkowski-sum packages compute different operations; none constructs the feasible convex region shared by multiple oriented halfplanes. | Implemented as [`half_plane_intersection`](h/half_plane_intersection/README.md) with ten ports, exact-rational angle/deque and pair-intersection/convex-hull oracles, bounded workload, README/RIGHTS, static inventory checker, and shared byte-output suite registration. The profile accepts up to 12 primitive integer constraints `a*x+b*y<=c`, clips to an implicit `[-256,256]^2` square, and emits the exact-rational vertex cycle. Source: [CP-Algorithms half-plane intersection](https://cp-algorithms.com/geometry/halfplane-intersection.html), which describes the O(N log N) sorted-angle deque method; site license CC BY-SA 4.0. Clean-room algorithm description only. No programs, tests, scripts, checkers, builds, compilers, or benchmarks were run. |
| CP-Algorithms point-in-convex-polygon query | [`point_in_polygon_ray_casting`](p/point_in_polygon_ray_casting/README.md) supports arbitrary simple or self-intersecting polygons by a linear even–odd crossing scan. It does not use the convex polygon's sorted radial fan to answer queries by binary search. [`kirkpatrick_hierarchical_point_location`](k/kirkpatrick_hierarchical_point_location/README.md) queries a supplied planar triangulation hierarchy and is not a convex-polygon membership method. | Implemented and registered as [`point_in_convex_polygon_log_query`](p/point_in_convex_polygon_log_query/README.md): byte ABI input is `[N,Q,(x,y)*N,(qx,qy)*Q]`, with `3<=N<=32`, `0<=Q<=32`, coordinates in [-1,000,000,1,000,000], and a strictly convex CCW polygon at any cyclic start. Repeated vertices and all collinear vertices are invalid. Output is one i64 per query, `1` for inside or boundary and `0` for outside; Q=0 permits a null output. Ten language ports, primary fan-search oracle, independent linear edge-scan oracle, workload, README/RIGHTS, static package inventory checker, generated maximum-size polygon and query cases, malformed-input checks, and capacity probes are wired into the byte-output suite. This is a distinct O(log N) convex-specific query method. Source: [CP-Algorithms — Check if point belongs to the convex polygon in O(log N)](https://cp-algorithms.com/geometry/point-in-convex-polygon.html), CC BY-SA 4.0; clean-room algorithm description only. No programs, tests, scripts, checkers, builds, compilers, or benchmarks were run. |
| NPB EP (embarrassingly parallel random-number/statistical kernel) | `linear_congruential_generator` covers a generic bounded recurrence and `marsaglia_polar_normal` transforms a supplied draw tape; neither includes the EP stream-to-histogram-and-sums pipeline. | Confirmed distinct integrated profile: ten ports implement the NASA 46-bit stream, polar rejection, ten square-annulus bins, and coordinate sums; the bounded local profile takes a seed and caps candidates at 4,096. High-precision oracle, independent verifier, workload, and `float64_slice_io` registration are complete. |
| NPB CG (sparse generated-matrix inverse/eigenvalue workload) | Existing [`conjugate_gradient`](c/conjugate_gradient/README.md) is one dense SPD solve; it does not model the NPB sparse matrix-vector workload or repeated inverse-power eigenvalue estimate. | Confirmed distinct and implemented as a bounded CSR profile: ten ports use sparse CG inner solves within repeated inverse-power outer updates, with sparse and independent dense oracles, workload/checker, and `i64_array_bytes_output` integration. It supplies the matrix instead of reproducing NASA's `makea` generator, so it covers the specified sparse CG/eigenvalue core, not the full NPB matrix-generation cost or a class run. [NASA NPB specification, §2.2.3](https://www.nas.nasa.gov/assets/nas/pdf/techreports/1994/rnr-94-007.pdf). |
| NPB MG | [`doe_minigmg_restriction`](d/doe_minigmg_restriction/README.md) is a standalone 3-D restriction operator and [`splash2_ocean_rbgs`](o/splash2_ocean_rbgs/README.md) is one 2-D red-black relaxation sweep; neither is a 3-D multigrid V-cycle solver. | Confirmed distinct and implemented as a bounded periodic `npb_mg_vcycle`: ten ports use the 27-point operator, restriction/interpolation, recursive V-cycle, and `S(a)` correction, with direct and sparse-matrix independent oracles, workload/checker, and `float64_slice_io` integration. It does not claim canonical NPB class sizes or generated forcing. [NASA NPB specification, §2.2.4](https://www.nas.nasa.gov/assets/nas/pdf/techreports/1994/rnr-94-007.pdf). |
| NPB FT | [`fast_fourier_transform`](f/fast_fourier_transform/README.md) is a 1-D radix-2 transform and [`splash2_fft_six_step`](f/splash2_fft_six_step/README.md) is a 1-D transpose-aware transform; neither performs the NPB 3-D spectral time-step pipeline. | Confirmed distinct and implemented as `npb_ft_3d_spectral_step`: ten ports, direct and separable independent DFT oracles, workload/checker, and `float64_slice_io` integration. It preserves 3-D transform/evolve/checksum behavior while bounding the cube to side 4 and supplying the initial field. [NASA NPB specification, §2.2.5](https://www.nas.nasa.gov/assets/nas/pdf/techreports/1994/rnr-94-007.pdf). |
| NPB BT / SP / LU | NASA specifies 5×5 block-tridiagonal directional solves (BT), scalar pentadiagonal directional solves (SP), and regular seven-block-diagonal 5×5 SSOR triangular sweeps (LU). Local scalar Thomas, PolyBench ADI, direct LU factorization, dense Gauss–Seidel, and 2-D Ocean relaxation differ in block structure or sweep operation. | BT is implemented as a bounded block-Thomas solve with ten ports, exact dense independent oracle, static workload checker, and `i64_array_float64` integration; it omits coefficient generation and the full 3-D sweep schedule. SP is implemented as a bounded scalar pentadiagonal line solve with ten ports, a dense exact-arithmetic independent oracle, static workload checker, and `float64_slice_io` integration; it omits PDE-state construction and the three-dimensional sweep schedule. LU now has ten ports (nine standard plus Mojo), sparse and independent dense oracles, a bounded workload/static checker, and byte-output suite registration; supplied coefficients and state replace the CFD setup, so this is a bounded SSOR core profile, not a canonical NPB-LU run. No program or validation tool was run. [NASA NPB specification](https://www.nas.nasa.gov/assets/nas/pdf/techreports/1994/rnr-94-007.pdf), §§2.2.6–2.2.8 and §3.3. |
| NPB UA / BT-IO / DT, NPB-MZ, GridNPB | NASA NAS-04-006 specifies adaptive locally structured nonconforming hexahedra, isotropic eight-child refinement/coarsening, and a one-level neighbor constraint. Local Delaunay refinement is planar triangulation; miniAMR and miniGMG cover block grids and restriction. BT-IO uses the BT compute with periodic full-field MPI-I/O, DT measures data traffic, MZ runs the same per-zone BT/SP/LU methods with boundary exchange, and GridNPB composes communicating NPB-derived tasks. | UA is confirmed distinct and implemented as an adaptation-only bounded profile: ten ports, explicit-leaf refine/balance/coarsen contract, primary and independent oracles, workload, static package checker, and `i64_array_float64` suite registration. It omits the spectral-element heat equation, solution transfer, PCG, and canonical NPB classes. BT-IO, DT, MZ, and GridNPB are excluded as I/O, communication, or compound-task profiles that add no distinct local numerical algorithm. [NASA UA specification, NAS-04-006](https://www.nas.nasa.gov/assets/nas/pdf/techreports/2004/nas-04-006.pdf), [BT-IO report, NAS-03-002](https://www.nas.nasa.gov/assets/nas/pdf/techreports/2003/nas-03-002.pdf), [NPB-MZ report, NAS-03-010](https://www.nas.nasa.gov/assets/nas/pdf/techreports/2003/nas-03-010.pdf), [GridNPB report, NAS-02-005](https://www.nas.nasa.gov/assets/nas/pdf/techreports/2002/nas-02-005.pdf). |
| NPB Data Cube (DC) | NASA's [Arithmetic Data Cube report](https://www.nas.nasa.gov/assets/nas/pdf/techreports/2003/nas-03-005.pdf) specifies that each view be computed from its smallest immediate parent. The related [`npb_serial_dc`](n/npb_serial_dc/README.md) independently groups raw rows for each nonempty projection and does not implement that parent-selection strategy. | Confirmed distinct and implemented: `npb_dc_smallest_parent` includes all 2^d views, the empty aggregate, ten language ports, primary and independent oracles, static package metadata, and `i64_array_scalar` suite registration. Root and author statically reconciled parent selection, projection, tie-breaking, group ordering, and checksums; no programs, tests, builds, or checkers were run. [NASA NAS-03-005, §1](https://www.nas.nasa.gov/assets/nas/pdf/techreports/2003/nas-03-005.pdf); the report identifies Harinarayan, Rajaraman, and Ullman as the greedy algorithm source. |
| HPC Challenge HPL / DGEMM / STREAM / PTRANS / RandomAccess / FFT / b_eff | The [official test list](https://www.hpcchallenge.org/hpcc/) defines the operations and identifies PTRANS as pairwise simultaneous processor communication and b_eff as communication bandwidth/latency. Local algorithm matches are `linpack_lu_solve`, `gemm`, `stream_vector_kernels`, `matrix_transpose`, `hpcc_random_access`, and the radix-2 FFT family. | Already represented or intentionally excluded: HPL, DGEMM, STREAM, the local transpose operation, and 1-D FFT match existing algorithms and need no aliases; RandomAccess has its own distinct random-update profile because a standalone LFSR omits the measured table updates. Exclude distributed PTRANS exchanges and b_eff communication tests from the single-call benchmark ABI. |
| HPCG's complete PCG + multigrid + symmetric Gauss-Seidel workload | The [official specification](https://github.com/hpcg-benchmark/hpcg) defines fixed-count, double-precision multigrid-preconditioned CG; the [suite overview](https://www.hpcg-benchmark.org/index.html) identifies SpMV, vector updates, dot products, local symmetric Gauss-Seidel, sparse triangular solve, and nested coarse-grid levels. Local `parboil_spmv_jds` is a JDS kernel, `conjugate_gradient` is a dense one-level solve, and `gauss_seidel_method` is lexicographic scalar relaxation. | Covered by the already implemented [`hpcg_profile`](n/hpcg_profile/README.md): its ten ports and byte-output suite profile combine CSR SpMV, symmetric Gauss–Seidel pre/post-smoothing, one `PᵀAP` coarse correction, and preconditioned CG. Pair aggregation and a single coarse level are explicit bounded-profile choices; MPI, official scale classes, and tuning are excluded. This source-review entry does not reserve a second package. |
| CP-Algorithms D'Esopo–Pape shortest paths | Static filename and content search found Dijkstra, Bellman–Ford, 0–1 BFS, and a FIFO label-correcting MiBench profile, but no deque-based Pape implementation. | Confirmed distinct queue discipline; ten port drafts, README/workload, Bellman–Ford oracle, package-local static checker, byte-suite registration, strict package metadata validation, and generated verifier probes are present. No runtime validation was performed. |
| CP-Algorithms Dial bucket shortest paths | [`dijkstra`](d/dijkstra/README.md) uses a general minimum-selection frontier; [`gapbs_delta_step_sssp`](d/gapbs_delta_step_sssp/README.md) groups distances into delta-width buckets and closes each bucket over light edges; [`breadth_first_search_zero_one_shortest_path`](b/breadth_first_search_zero_one_shortest_path/README.md) uses a deque specialized to weights 0/1. No package uses exact-distance buckets for arbitrary small nonnegative integer weights. Implemented and registered as [`dial_bucket_shortest_paths`](d/dial_bucket_shortest_paths/README.md) across all ten languages. Its bounded directed graph profile has `1<=N<=16`, `0<=M<=64`, source in `0..N-1`, edge weights `0..8`, and allows self-loops, parallel edges, and zero weights. The primary uses a fixed nine-slot cyclic exact-distance bucket ring with stale-entry checks; the independent oracle uses Floyd–Warshall. Input `[N,M,source,(u,v,w)*M]` has maximum valid/parseable lengths 195/196 i64 words; output is one little-endian i64 distance per vertex (`-1` if unreachable), maximum 128 bytes; workspace is 4096 bytes. The bounded maximum finite distance is 120. Candidate distinction: exact integer buckets process one distance at a time in O(M+N*C), unlike the general frontier in Dijkstra or delta-range closure in delta-stepping. Package README/RIGHTS, workload, primary/independent oracles, static inventory checker, and byte-output suite registration are present. Source: [CP-Algorithms 0–1 BFS, Dial's algorithm section](https://cp-algorithms.com/graph/01_bfs.html), CC BY-SA 4.0; algorithm description only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |
| Hunt–Szymanski sparse longest common subsequence | [`longest_common_subsequence`](l/longest_common_subsequence/README.md) uses the one-row prefix-DP recurrence; [`rle_lcs_block_dp`](r/rle_lcs_block_dp/README.md) uses a compressed-run block recurrence. Neither processes only matching position pairs and reduces them to an LIS frontier. | Confirmed distinct and implemented as [`hunt_szymanski_lcs`](h/hunt_szymanski_lcs/README.md): ten language ports use descending right-position lists and a minimum-tail LIS frontier. The package has primary matching-pair and independent full-table DP oracles, workload, rights note, and static inventory checker; `i64_array_scalar` validates the workload, cross-checks random cases, and covers malformed frames. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. Source: Hunt and Szymanski, “A fast algorithm for computing longest common subsequences,” *Communications of the ACM* 20(5), 1977, [DOI 10.1145/359581.359603](https://doi.org/10.1145/359581.359603). |
| Hirschberg linear-space LCS reconstruction | [`longest_common_subsequence`](l/longest_common_subsequence/README.md) returns only the length using a one-row prefix recurrence; [`hunt_szymanski_lcs`](h/hunt_szymanski_lcs/README.md) returns only the length using matching-position/LIS processing; [`rle_lcs_block_dp`](r/rle_lcs_block_dp/README.md) is run-length block DP. No package reconstructs an LCS with forward/backward rows and divide-and-conquer midpoint traceback. Confirmed distinct and implemented as [`hirschberg_lcs`](h/hirschberg_lcs/README.md): ten ports reconstruct bytes with the deterministic smallest-split rule; the full-table verifier checks common-subsequence membership and optimal length independently. Workload, provenance/rights, and static package checker are present. The byte-output suite registers primary expected bytes, independent certificate validation, bounds, generated sequences, malformed frames, and output-capacity probes. Same LCS objective, but distinct output and linear-space divide-and-conquer algorithm. Source: Hirschberg, “A linear space algorithm for computing maximal common subsequences,” *Communications of the ACM* 18(6), 1975, [DOI 10.1145/360825.360861](https://doi.org/10.1145/360825.360861). |
| CP-Algorithms online bridge finding | Static bridge-finding and 2-edge-connected decomposition packages do not maintain bridge counts after each inserted edge. | Confirmed distinct: ten language ports, bounded independent edge-deletion oracle, README/workload, and byte-output suite registration are present. |
| CP-Algorithms strong orientation | Static bridge and connectivity routines do not orient every edge to minimize the number of resulting strongly connected components. | Confirmed distinct: ten language ports, deterministic DFS workload, independent edge-deletion minimum and Kosaraju certificate oracle, and byte-output suite registration are present. |
| CP-Algorithms faces of a planar graph | [`upward_planarity_angle_assignment`](u/upward_planarity_angle_assignment/README.md) assigns angles and tests a bounded st-planar embedding, while [`st_planar_leftmost_augmenting_flow`](s/st_planar_leftmost_augmenting_flow/README.md) uses a supplied st-planar embedding for flow; neither enumerates the face orbits of a planar straight-line graph. Voronoi/Delaunay and polygon packages also return different geometric objects. | Implemented and registered as [`planar_face_count`](p/planar_face_count/README.md) in ten languages: the bounded scalar profile accepts connected simple integer-coordinate planar straight-line graphs (`N<=16`, coordinates in `[-100,100]`, no crossings or collinear overlapping incident segments), sorts incident neighbors by polar angle, and counts directed-edge face orbits. The independent Euler-characteristic oracle computes `M-N+2`; workload, README/RIGHTS, package-local static inventory checker, and generated scalar-suite cases are present. Source: [CP-Algorithms — Finding faces of a planar graph](https://cp-algorithms.com/geometry/planar.html), CC BY-SA 4.0; use the algorithm description only. |
| CP-Algorithms vertex connectivity | [`articulation_points`](a/articulation_points/README.md) reports only single-vertex cuts; biconnected blocks, edge cuts, and generic max-flow benchmarks do not compute the minimum vertex separator cardinality of an undirected graph. | Confirmed distinct and implemented as [`vertex_connectivity`](v/vertex_connectivity/README.md): ten ports use vertex-split unit-capacity networks and augmenting-path max flow for nonadjacent terminal pairs; the independent oracle enumerates vertex-deletion subsets. The bounded scalar workload caps `n<=10`, `m<=45`, and is registered with deterministic generated graph probes in `i64_array_scalar`. CP-Algorithms article text is CC BY-SA 4.0; only its algorithm description was used. [Source article](https://cp-algorithms.com/graph/edge_vertex_connectivity.html). |
| OI Wiki virtual tree construction | Existing binary lifting, Tarjan offline LCA, and Farach–Colton–Bender packages answer ancestor queries; none builds the LCA-closed compressed tree for a selected marked-vertex set. | Confirmed distinct and implemented as [`virtual_tree`](v/virtual_tree/README.md): ten ports, bounded `N<=32`, `K<=N` contract, adjacent-mark LCA closure, and compressed edges annotated with original-tree distance. `K=0` encodes an empty tree as `[0]`; repeated marked IDs are invalid. Primary stack construction, direct root-path-union independent oracle, workload, rights note, and package-local static checker are present. The byte-output suite registers its oracle, bounds, workload validation, random trees, empty-mark case, maximum 776-byte output, malformed input, and capacity probes. Source: [OI Wiki Virtual Tree](https://oiwiki.net/graph/virtual-tree/), CC BY-SA 4.0 / SATA; clean-room algorithm description only. |
| OI Wiki exact Steiner tree on a weighted graph | [`steiner_tree_gain_greedy`](s/steiner_tree_gain_greedy/README.md) greedily selects from a supplied finite family of full components using a gain potential; it does not compute the exact minimum edge-weight tree connecting terminals in an explicitly supplied graph. | Implemented and registered as [`steiner_tree_subset_dp`](p/steiner_tree_subset_dp/README.md): scalar input `[N,M,K,terminals...,(u,v,w)*M]`, `1<=N<=8`, `0<=M<=14` and `M<=N(N-1)/2`, `1<=K<=min(5,N)`, distinct terminals, simple undirected edges with weights `0..1000`; invalid input returns `-1`, disconnected terminal sets return `-2`, and otherwise the result is the exact minimum cost (`0` for one terminal). Primary uses terminal-subset merging followed by multi-source shortest-path relaxation; an independent oracle enumerates edge subsets. Ten ports, package checker, scalar-array runner/verifier registration, generated graph cases, malformed inputs, and null-input coverage are included. Source: [OI Wiki Steiner Tree](https://oi-wiki.org/graph/steiner-tree/), CC BY-SA 4.0/SATA; clean-room algorithm description only. |
| CP-Algorithms games on arbitrary directed graphs | [`sprague_grundy_theorem`](s/sprague_grundy_theorem/README.md) computes mex values for one subtraction-game heap; [`fourinarow_minimax`](f/fourinarow_minimax/README.md) searches a board game, and [`game_of_life`](g/game_of_life/README.md) is a cellular automaton. None classifies all vertices of a cyclic directed graph as winning, losing, or drawing. | Implemented as [`games_on_arbitrary_graphs`](g/games_on_arbitrary_graphs/README.md): ten language ports use reverse-edge retrograde propagation; primary and independent synchronous fixed-point oracles, bounded workload, rights/provenance note, and package-local static checker are present. Contract is `V<=16`, `E<=32`, output statuses 0 draw / 1 win / 2 loss. The byte-output suite registers fixture bytes, generated cyclic graphs, duplicate edges, malformed endpoints, maximum frame/output, and capacity probes. Source description: [CP-Algorithms games on arbitrary graphs](https://cp-algorithms.com/game_theory/games_on_graphs.html), CC BY-SA 4.0; algorithm description only. |
| CP-Algorithms MEX with point updates | [`mex`](m/mex/README.md) computes one static MEX by sorting a copied input array. [`point_set_range_frequency`](p/point_set_range_frequency/README.md) supports dynamic point replacements and frequency queries, but does not maintain the first missing nonnegative value. | Implemented and registered as [`dynamic_mex_updates`](d/dynamic_mex_updates/README.md): byte input `[N,Q,A...,(index,new_value)*Q]`, `1<=N<=32`, `0<=Q<=32`, values in `[-1000,1000]`; after each replacement return the current MEX. Ten ports maintain candidate frequencies and segment-tree occupied counts over `[0,N+1)`; the independent oracle scans candidate values after each update. Workload, README/RIGHTS, static inventory checker, and byte-output runner/verifier registration include generated and maximum-output traces, malformed framing, null/capacity cases, and zero-update behavior. Source: [CP-Algorithms — MEX with array updates](https://cp-algorithms.com/sequences/mex.html), CC BY-SA 4.0; use algorithm description only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |
| Rosetta Code Sattolo cycle shuffle | Existing Fisher–Yates shuffles permit choosing the current position, while Sattolo restricts each descending swap to an earlier position. [The Cornell correctness report](https://www.cs.cornell.edu/gries/TechReports/86-786.pdf) and [INRIA algorithm overview](https://mathexp.eu/chyzak/Publications/RR-5542.pdf) describe the resulting single-cycle permutation. | Confirmed distinct algorithm: the nine standard language ports, optional Mojo port, deterministic workload, oracle, and byte-output suite registration are written. The deterministic PRNG fixes replay choices; no programs, tests, or benchmarks were run. |
| Rosetta Code representative task-page audit (RosettaGit mirror) | Compared [Pancake sort](https://rosettagit.org/tasks/sorting-algorithms-pancake-sort/), [Counting sort](https://rosettagit.org/tasks/sorting-algorithms-counting-sort/), [Sieve of Eratosthenes](https://rosettagit.org/tasks/sieve-of-eratosthenes/), [Dijkstra](https://rosettagit.org/tasks/dijkstras-algorithm/), [A* search](https://rosettagit.org/tasks/a-search-algorithm/), [Banker's algorithm](https://rosettagit.org/tasks/bankers-algorithm/), [Longest common subsequence](https://rosettagit.org/tasks/longest-common-subsequence/), [Longest common substring](https://rosettagit.org/tasks/longest-common-substring/), and [Zeckendorf representation](https://rosettagit.org/tasks/zeckendorf-number-representation/) with local README contracts. | Same-algorithm duplicates/covered kernels: `pancake_sort`, `counting_sort`, `sieve_of_eratosthenes`, `dijkstra`, `a_star_search`, `bankers_algorithm`, `longest_common_subsequence`, and `longest_common_substring` are already present. Rosetta Code's A* task permits weighted edges, while local `a_star_search` uses unit-cost edges; this is a workload-contract difference within the same algorithm, not a second A* package. Zeckendorf conversion is already a core step of [`fibonacci_integer_code`](f/fibonacci_integer_code/README.md); its table-format task does not justify another algorithm package. No aliases are proposed. |
| Rosetta Code Hash join | [`join`](j/join/README.md) concatenates byte strings; [`hash_map_open_addressing`](h/hash_map_open_addressing/README.md), `hashmap`, and the other hash-map packages expose container operations, not relational joins. No hash, merge, or nested-loop equijoin contract was found. | Implemented and registered as [`hash_join`](h/hash_join/README.md) in ten ports: bounded two-relation inner join on signed-i64 keys, with at most 8 rows per side; build the smaller side (tie chooses right), retain duplicate-row postings in input order, and probe the other side. Output is one byte per match encoding `(left_row_id<<4)|right_row_id`; order is probe-side input order followed by matching build-side input order, oriented back to left/right IDs. The primary uses open-addressed key slots with linked row postings; an independent nested-loop oracle follows the documented order. Input is `[left_count,right_count,left_keys...,right_keys...]` (max 18 i64 values, parseable max 19), output max 64 bytes, workspace 1024 bytes; invalid input returns `-1`, null/short output `-2`. Workload, README/RIGHTS, package-local static inventory checker, strict workload bounds, and generated verifier probes are wired into the byte-output suite. Source: [RosettaGit Hash join](https://rosettagit.org/tasks/hash-join/), GFDL-1.3-or-later; use task taxonomy and algorithm description only, with no copied task text/examples/code. |
| Rosetta Code Kahan summation | The repository has problem-specific floating-point accumulations and closed-form series sums, but no general compensated-summation routine. Those packages do not maintain Kahan's correction term while consuming an ordered floating-point sequence. | Confirmed distinct and implemented as `kahan_summation` in C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig. The bounded binary64 profile accepts 0..256 finite values with absolute magnitude at most `1e100`; it returns one ordered Kahan sum with `-1` invalid and `-2` output-capacity error. Primary recurrence and exact-rational step-rounding verifier, workload, rights note, README, package-local static inventory checker, and float64 slice suite registration are present. The RosettaGit task page is licensed GFDL-1.3-or-later; only its high-level operation and the algorithm description are used. Original attribution: William Kahan, “Further remarks on reducing truncation errors,” *Communications of the ACM* 8(1), 1965, [DOI 10.1145/363707.363723](https://doi.org/10.1145/363707.363723). |
| Rosetta Code ray-casting point-in-polygon | Local geometry contracts cover segment intersection, polygon area and lattice-point counts, but no package tests a query point against a general polygon by counting horizontal-ray crossings. | Confirmed distinct and implemented as `point_in_polygon_ray_casting`: ten clean-room language ports, exact-integer even–odd crossing, and a separately structured winding-parity verifier. The bounded contract explicitly treats boundary points as inside and accepts self-intersecting polygons under even–odd semantics. Workload, rights note, static inventory checker, and `i64_array_scalar` suite registration are complete. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. The [RosettaGit task](https://rosettagit.org/tasks/ray-casting-algorithm/) defines parity of horizontal-ray segment crossings; its page identifies GFDL-1.3-or-later. Only the high-level algorithm is used. |
| GraphAIBench GGNN gated graph-message update | Existing GCN, GraphSAGE, and GAT packages do not apply recurrent reset/update gates and a gated candidate to graph-aggregated states. | Confirmed distinct and implemented as [`graphai_ggnn_message_update`](g/graphai_ggnn_message_update/README.md): nine standard-language ports plus Mojo, primary and independent oracles, a bounded workload, retained MIT notice, static package inventory, and float64 slice suite registration. See the [pinned GraphAIBench source](https://github.com/chenxuhao/GraphAIBench/tree/17834cb29b7c542481c2e3740dc9664841b72f59). |
| Rosetta Code de Bruijn sequence generation | The [task](https://rosettagit.org/tasks/de-bruijn-sequences/) generates a cyclic sequence in which every length-`n` word over a `k`-symbol alphabet occurs once. A path search found only [`sequence`](s/sequence/README.md), which generates the unrelated Moser–de Bruijn integer sequence; no de Bruijn-cycle generator or equivalent contract appears in local README paths. | Confirmed distinct and implemented as `de_bruijn_sequences` in C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig. The bounded profile uses FKM generation for `2<=k<=10`, `1<=n<=16`, and `k^n<=10,000`, with primary FKM and independent cyclic-window oracles, workload, rights note, package-local static inventory checker, and shared byte-output suite registration. Keep separate from the Moser–de Bruijn numeric sequence. The official task URL returns 403 in the web reader; the reviewed description is from the RosettaGit mirror. |
| Rosetta Code Knuth power tree | The [task](https://rosettagit.org/tasks/knuths-power-tree/) uses a shared parent tree of addition chains to retrieve an exponent path and evaluate a power; the tree definition and first rows are independently recorded in [OEIS A114622](https://oeis.org/A114622). [`problem122`](p/problem122/README.md) searches minimum-length star addition chains separately for each target and sums their lengths. | Confirmed distinct and implemented as `knuth_power_tree` in C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig. The bounded profile returns the first-discovery path for `1<=target<=127`; ports use a shared FIFO/parent-map expansion, with a separate explicit path-frontier oracle, workload, rights note, package-local static inventory checker, and shared byte-output suite registration. The generated path is not guaranteed optimal (target 77 is included to expose that behavior). |
| Rosetta Code sorting/concurrency demonstrations | [Sort using a custom comparator](https://rosettagit.org/tasks/sort-using-a-custom-comparator/) applies a comparator to a host sort, while [Sleep sort](https://rosettagit.org/tasks/sorting-algorithms-sleep-sort/) orders by elapsed task sleeps. | Excluded as new algorithm packages: the comparator task does not define a sorting algorithm, and sleep sort is a timing/scheduling demonstration rather than a deterministic sorting kernel. |
| Library Checker `enumerate_quotients` | Existing `floor`, divisor enumeration, and divisor-count packages do not enumerate the distinct values of `floor(n/x)` by quotient blocks. | Confirmed distinct quotient-block enumeration: nine standard ports, optional Mojo, README/workload, independent oracle, and scalar byte-output runner/verifier integration are written. |
| Library Checker `sum_of_floor_of_linear` | Existing floor/ceiling and integer floor helpers do not sum `floor((A*i+B)/M)` over a range using the Euclidean recurrence. | Confirmed distinct Euclidean floor-sum recurrence: nine standard ports, optional Mojo, README/workload, direct/recursive oracle, and scalar runner/verifier registration are written. |
| Library Checker `min_of_mod_of_linear` | Existing modular arithmetic packages compute individual residues or exponentiation, not the minimum residue over a prefix of a linear modular sequence. | Confirmed distinct from floor sum: nine standard ports, optional Mojo, README/workload, Euclidean oracle, and scalar runner/verifier registration are written. |
| Library Checker `stern_brocot_tree` | Existing Farey approximation searches for a rational near a decimal; it does not implement the five compressed-path and tree-navigation operations. | Confirmed distinct: nine standard ports, README/workload, independent oracle, and byte-output runner/verifier registration are written. |
| Library Checker `counting_squarefrees` | `is_square_free` tests one integer but does not count square-free values in a prefix. | Confirmed distinct: nine standard ports and Mojo use Möbius inversion under a bounded `N <= 10^12` profile, with a scalar workload and oracle-backed verifier corpus. |
| Library Checker `bernoulli_number` | Local `power_sum` counts subsets of integer powers, while `randomized_rounding_bernoulli` replays rounding decisions; neither computes the Bernoulli-number sequence. The Library Checker task defines `B_0..B_N` modulo 998244353 with `B_1=-1/2`. | Confirmed distinct: nine standard ports and Mojo use a bounded quadratic recurrence through `N <= 32`, with exact-rational oracle, byte-output fixtures, capacity/null handling, and verifier corpus coverage. |
| Library Checker `kth_root_integer` | `square_root_binary_search` and `newton_square_root` handle degree 2; real-valued `nth_root` and geometric-mean packages do not return an exact floor for arbitrary integer degrees. | Confirmed distinct: nine standard ports and Mojo use an overflow-guarded candidate check in a bounded `i64_array_scalar` profile (`0 <= A <= I64_MAX`, `1 <= K <= 64`), with exact arbitrary-precision oracle, workload, and verifier corpus. |
| Library Checker `two_square_sum` | Existing Pythagoras computes a geometric distance; Pythagorean-triple algorithms solve `a²+b²=c²`, not representations of a supplied `N`. | Confirmed distinct: nine standard ports and Mojo enumerate every ordered representation for up to eight queries with `N <= 10,000`; a byte-output workload, integer-square-root oracle, and verifier corpus are registered. |
| Library Checker `sum_of_totient_function` | Local `problem72` sums totients from a direct table through one million; it uses a sieve-and-prefix method rather than the large-quotient recurrence. | Confirmed as a distinct summatory method: nine standard ports, optional Mojo, a modular oracle, bounded workload (`N <= 10^9`), and scalar verifier corpus are registered. |
| Library Checker `gcd_of_gaussian_integers` | No Gaussian-integer arithmetic or GCD package was found; real-valued Gaussian models and Pythagorean algorithms are different operations. | Confirmed distinct Euclidean GCD in `Z[i]`: nine standard ports plus Mojo, canonical-associate normalization, bounded workload, integer-arithmetic oracle, and byte-output verifier corpus are registered. |
| CP-Algorithms MPM maximum flow | [`dinic_maxflow`](d/dinic_maxflow/README.md), [`edmonds_karp`](e/edmonds_karp/README.md), and [`push_relabel`](p/push_relabel/README.md) use other maximum-flow methods; no MPM implementation was found. | Confirmed distinct blocking-flow method: ten language ports, an exhaustive source-side-cut oracle, workload (`N <= 8`, `M <= 24`, capacities `0..100`), and i64-array-scalar runner/verifier integration are registered. The Elisa port now uses a bounded input view; this edit remains uncompiled and untested. |
| OI Wiki Dinic-like minimum-cost maximum flow | [`min_cost_max_flow`](m/min_cost_max_flow/README.md) uses successive shortest augmenting paths with reduced-cost potentials and Dijkstra, sending one bottleneck path per phase; [`minimum_cost_b_flow`](m/minimum_cost_b_flow/README.md) uses feasibility flow followed by negative-cycle cancellation for arbitrary balances. Neither uses repeated shortest-distance labels followed by blocking-flow augmentation over the tight residual graph. | Implemented as [`min_cost_max_flow_blocking_paths`](m/min_cost_max_flow_blocking_paths/README.md) with ten ports and the same bounded source/sink, flow-limit, capacity, and nonnegative-cost contract/output as `min_cost_max_flow` (`V<=8`, `E<=16`, limit/capacity `<=16/5`, costs `0..20`, 16 output bytes). Ports and primary oracle use SPFA shortest distances, then layered blocking flow over residual arcs satisfying `dist[v]=dist[u]+cost`; the independent oracle uses Bellman–Ford successive shortest augmenting paths. Workload, rights/provenance, static package checker, and shared byte-output suite registration are present; no programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. Source: [OI Wiki minimum-cost flow, Dinic-like method](https://en.oi-wiki.org/graph/flow/min-cost/), which describes tight-edge blocking flow after shortest-distance computation; page is CC BY-SA 4.0/SATA. Clean-room algorithm description only. |
| SMAWK row minima in totally monotone matrices | Static filename/content and coverage-ledger search found no SMAWK package or active reservation. [`min_plus_convolution_convex_arbitrary`](m/min_plus_convolution_convex_arbitrary/README.md) uses monotone divide-and-conquer on a convolution-specific Monge matrix; it does not use SMAWK column reduction, odd-row recursion, and interpolation over a general totally monotone matrix. | Implemented as [`smawk_row_minima`](s/smawk_row_minima/README.md) with ten ports, SMAWK primary oracle, independent row-scan oracle, promise-checked fixtures, workload, provenance/rights, static package checker, and shared byte-output suite registration. The profile accepts a promised totally monotone matrix up to 16x16 and returns each row's leftmost minimum. Source: Aggarwal, Klawe, Moran, Shor, and Wilber, “Geometric applications of a matrix-searching algorithm,” *Algorithmica* 2, 1987, [DOI 10.1007/BF01840359](https://doi.org/10.1007/BF01840359). Clean-room algorithm description only. No programs, tests, scripts, checkers, builds, compilers, or benchmarks were run. |
| Library Checker Segment Add Get Min | [`li_chao_tree`](l/li_chao_tree/README.md) inserts lines over the full coordinate domain; no local package with interval-restricted line insertion was found in the path/content search. | Confirmed distinct range-insertion operation; the nine-port package and scalar-suite integration are complete. The oracle uses direct interval scans; no runtime validation was performed. |
| Library Checker Static Range Mode Query | [`mode`](m/mode/README.md) finds one mode of the entire input array; [`wavelet_tree`](w/wavelet_tree/README.md) supports rank, quantile, and value counting but not range-mode queries. | Confirmed distinct static range-query data structure; the nine-port package and byte-suite integration are complete. The official [problem proposal](https://github.com/yosupo06/library-checker-problems/issues/959) and [range-mode paper](https://cs.au.dk/~larsen/papers/linear_mode.pdf) provide taxonomy and algorithm descriptions; implementations are clean-room, and runtime validation was not performed. |
| CP-Algorithms second-best MST | Prim, Kruskal, and Borůvka packages return an MST; [`second_best_mst`](s/second_best_mst/README.md) searches fundamental-cycle exchanges with explicit tree-path walks. [`mst_edge_classification`](m/mst_edge_classification/README.md) classifies edges rather than finding the least heavier tree. | The edge-exchange operation is represented by ten ports, an exhaustive spanning-tree oracle, certificate, workload, and byte-output suite integration; do not add an identical path-walk benchmark. Static review fixed the oracle's graph validation, which incorrectly required the entire input graph to be a tree and rejected cyclic inputs. The [source](https://cp-algorithms.com/graph/second_best_mst.html) also describes binary lifting for path maxima. Existing binary-lifting LCA and ancestor-query packages do not aggregate the two largest distinct edge weights; the separate [`second_best_mst_binary_lifting`](s/second_best_mst_binary_lifting/README.md) package now drafts that method in ten languages with scalar-suite wiring. All drafts remain unverified. Source used for algorithm identification only. No code was run. |

**Reservation:** `second_best_mst_binary_lifting` is owned by root. It uses the same strict-heavier operation as `second_best_mst` but replaces a path walk per non-tree edge with binary-lifting path aggregates. The contract, primary reference, independent spanning-tree enumeration, workload, package checker, ten language drafts, and scalar-suite registration are present; validation remains outstanding. Static documentation distinguishes the `O(M log N)` path-query stage from insertion-sort and unranked disjoint-set costs in some drafts. Do not duplicate this reservation. No code has been run.

The second-MST verifier source also specifies uniform weight shifts and vertex relabelings for small graphs. These checks remain unexecuted.
| LeetCode title-index candidate: Find Critical and Pseudo-Critical Edges in Minimum Spanning Tree (public title/topic labels only) | MST packages return a tree/weight or a strictly heavier alternative; `bridges` and `two_edge_connected_components` classify unweighted edge-connectivity cuts; `kkt_mst_sampling_filter` classifies light/heavy edges relative to one sampled forest. None describes edge participation across all MSTs of the original graph. | Implemented and registered as `mst_edge_classification` in ten languages, with equal-weight Kruskal groups and edge-ID-preserving quotient bridge checks, an independent force/forbid Kruskal oracle, bounded workload, README/RIGHTS, package-local static inventory checker, byte-output workload validation, and generated connected, maximum-size, malformed, null, and capacity profiles. Contract: connected simple weighted graph, `N<=12`, `M<=24`, weights `0..20`; one input-order byte per edge (`0` in no MST, `1` in some but not all, `2` in every MST). Discovery used the public title metadata only. Clean-room algorithm references are CP-Algorithms Kruskal and bridge descriptions. Static source review only; no execution or checks were run. |
| LeetCode title-index candidate: Maximum Frequency Stack (title/topic metadata only) | [`min_stack`](s/min_stack/README.md), [`stack_tracking_min_max`](s/stack_tracking_min_max/README.md), and [`stack`](s/stack/README.md) use LIFO removal or track extrema; [`max_word`](m/max_word/README.md) and frequency-count packages compute static frequencies. None removes an online element by highest current multiplicity with most-recent insertion as the tie-break. | Implemented and registered as [`maximum_frequency_stack`](m/maximum_frequency_stack/README.md) in ten languages with frequency-indexed stacks and a current maximum frequency, plus an independent active-list rescan oracle. Contract: `Q<=64`, pushed values `-8..8`; output is little-endian i64 per pop and the scalar result is output byte count (8 per pop). A null output is accepted for zero output bytes and returns `-2` when pop results need writing. Workload, README/RIGHTS, package-local static inventory checker, and byte-output runner/verifier coverage include ties, malformed traces, null output, and capacity errors. Discovery used LeetCode public title/topic metadata only; no problem text, examples, tests, submissions, or site code was consulted. Source-only implementation; no programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |
| LeetCode title-index candidate: Word Ladder II (title/topic metadata only) | [`word_ladder`](w/word_ladder/README.md) returns only shortest length; [`word_ladder_dfs`](w/word_ladder_dfs/README.md) returns one first DFS path; [`all_paths_from_source_to_target`](a/all_paths_from_source_to_target/README.md) enumerates every simple path without shortest-distance pruning; [`yens_kshortest_paths`](y/yens_kshortest_paths/README.md) ranks a bounded prefix of loopless weighted paths using Yen's candidate-generation method. None uses a BFS predecessor DAG to enumerate all and only unweighted shortest paths. | Implemented and registered as [`all_shortest_paths_unweighted`](a/all_shortest_paths_unweighted/README.md) in ten ports. The undirected simple-graph profile has `N<=16`, `M<=64`, a 162-path / 1296-byte output cap, and 4096-byte workspace metadata. BFS predecessor-DAG enumeration is checked by an independent Floyd-Warshall distance-guided oracle; workload, README/RIGHTS, package-local static inventory checker, generated maximum-input and maximum-output cases, malformed frames, and output-capacity probes are wired into the byte-output suite. Discovery uses LeetCode title/topic metadata only; no problem text, examples, constraints, tests, submissions, or site code were used. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |
| OI Wiki Berlekamp–Massey / linear recurrence inference | [`linear_recurrence_matrix`](l/linear_recurrence_matrix/README.md) exponentiates a supplied transition matrix; no recurrence-inference package was found. | Confirmed distinct: ten ports infer the shortest predictive recurrence over a prime field; an independent Gaussian-elimination oracle, bounded workload, and byte-output suite integration are complete. |
| OI Wiki Link-Cut Tree | Heavy-light path query/decomposition packages are present, but no dynamic-tree/link-cut-tree implementation was found by path and content search. The [OI Wiki article](https://en.oi-wiki.org/ds/lct/) describes dynamic forest link/cut/path operations. | Confirmed distinct; ten port drafts, README/workload, BFS oracle, and byte-suite wiring are present. Elisa uses safe references and slices for fixed node storage; the Mojo draft remains unverified. No runtime validation was run. |
| OI Wiki Euler Tour Tree | [`link_cut_tree`](l/link_cut_tree/README.md) maintains dynamic paths; [`offline_dynamic_connectivity`](o/offline_dynamic_connectivity/README.md) uses a time segment tree and rollback DSU rather than an online dynamic forest. No Euler-tour-sequence forest was found. | Confirmed distinct: maintain component connectivity, size, and weight sum through balanced Euler-tour sequences under link/cut and vertex-weight updates, with a BFS component oracle. The bounded contract, ten language ports, README/rights note, and workload are complete; the shared byte-output suite and verifier corpus are registered. Static-only; no checks or benchmarks were run. The OI Wiki page is CC BY-SA 4.0/SATA; use its algorithm description only. [Algorithm chapter](https://oi-wiki.org/ds/ett/). |
| OI Wiki Top Tree / self-adjusting top tree | [`link_cut_tree`](l/link_cut_tree/README.md) uses preferred paths and [`dynamic_tree_vertex_add_subtree_sum`](d/dynamic_tree_vertex_add_subtree_sum/README.md) augments that structure with virtual-subtree totals; neither uses rake/compress clusters. No top-tree implementation was found in local package READMEs or language paths. | Confirmed distinct: a bounded fixed-topology rake/compress hierarchy maintains component diameter under edge-weight updates, with direct traversal and all-pairs tree-distance verification. Ten ports, workload, package metadata, and shared byte-output suite/verifier registration are complete. Static-only; no checks or benchmarks were run. Workspace is 16384 bytes to cover the fixed cluster arena and working tables across language representations. OI Wiki describes top trees and dynamic-diameter augmentation; its page is CC BY-SA 4.0/SATA. Use the algorithm description only. [Algorithm chapter](https://oi-wiki.org/ds/top-tree/). |
| OI Wiki Schreier–Sims algorithm | No Schreier–Sims, stabilizer-chain, or permutation-group order implementation was found in the local package names or README contracts. The [OI Wiki chapter](https://oi-wiki.org/math/algebra/schreier-sims/) describes orbit transversals, Schreier generators, and base-and-strong-generating-set methods. | Confirmed distinct bounded package implemented in ten languages and statically registered in the shared runner/verifier: incrementally sifted Schreier residues maintain a fixed-base stabilizer chain for group order and membership queries, with a separate full-closure oracle, bounded workload, rights notes, and static inventory checker. Degree is at most 6; implementation uses only the OI Wiki algorithm description under its recorded CC BY-SA 4.0/SATA terms. |
| OI Wiki Main–Lorentz tandem-repetition algorithm | [`approximate_tandem_squares`](a/approximate_tandem_squares/README.md) directly compares each adjacent block pair and counts mismatches; [`runenumerate`](r/runenumerate/README.md) reports maximal periodic runs rather than every repeated square. | Confirmed distinct and implemented as `main_lorentz_tandem_repetitions`: ten ports use divide-and-conquer Z comparisons to enumerate exact tandem squares; direct adjacent-block comparison is the independent oracle. The package has workload, README/RIGHTS, and static checker; the byte-output runner and verifier register its bounds, oracle, maximum repetition profile, and malformed/capacity cases. The OI Wiki page is CC BY-SA 4.0/SATA; only its algorithm description was used. [Algorithm chapter](https://oi-wiki.org/string/main-lorentz/). |
| OI Wiki minimum string representation | [`duval`](d/duval/README.md) returns a least cyclic-rotation index using Duval's Lyndon scan; the OI Wiki page describes a different linear two-candidate elimination algorithm for the same output contract. | Confirmed distinct and implemented as `minimum_string_representation`: ten ports, direct-rotation verifier, bounded workload, rights note, and static package inventory checker are present. The scalar runner/verifier now register the independent oracle, workload validation, exhaustive tiny alphabets, maximum-length profile, and malformed inputs. All work remains source-only. The page is CC BY-SA 4.0/SATA; use its algorithm description only. [Algorithm chapter](https://en.oi-wiki.org/string/minimal-string/). |
| OI Wiki suffix balanced tree | [`suffix_array`](s/suffix_array/README.md) uses rank doubling, and [`suffix_array_dc3`](s/suffix_array_dc3/README.md) uses DC3. The OI Wiki construction inserts suffixes from right to left into a scapegoat-style balanced search tree, using the first character and the already-ranked successor suffix to compare in constant time; in-order traversal yields the suffix array. | Confirmed distinct and implemented as `suffix_balanced_tree`: ten ports, workload, README/RIGHTS, primary tagged-tree oracle, and direct suffix-sort oracle are present. The byte-output runner and verifier register the workload, bounds, independent oracle, maximum text, empty input, malformed values, and output-capacity profiles. The article is CC BY-SA 4.0/SATA; only its algorithm description was used. [Algorithm chapter](https://oi-wiki.org/string/suffix-bst/). |
| OI Wiki SA-IS suffix-array construction | [`suffix_array`](s/suffix_array/README.md) uses rank doubling; [`suffix_array_dc3`](s/suffix_array_dc3/README.md) uses DC3 residue sorting; neither classifies L/S suffixes, names LMS substrings, and induces their order. No SA-IS or induced-sorting suffix-array package was found in local paths or contracts. | Confirmed distinct and implemented as [`suffix_array_sais`](s/suffix_array_sais/README.md): ten language ports, primary induced-sorting oracle, independent direct-suffix-sort oracle, workload, README/RIGHTS, and static package checker are present. The byte-output suite includes deterministic texts at every length, random byte strings, malformed frames, and output-capacity probes. OI Wiki and Nong, Zhang & Chan (DCC 2009) algorithm descriptions only. [OI Wiki suffix-array chapter](https://oi-wiki.org/string/sa/), [original paper DOI](https://doi.org/10.1109/DCC.2009.42). |
| OI Wiki Boyer–Moore string matching | [`boyer_moore`](b/boyer_moore/README.md) implements full Boyer–Moore with bad-character and good-suffix shifts. [`boyer_moore_horspool`](b/boyer_moore_horspool/README.md) and the Pratt–Boyer–Moore source-helper profile are separately named variants. | Already present; the OI Wiki full Boyer–Moore algorithm is covered by `boyer_moore`, so no duplicate package is planned. The page is CC BY-SA 4.0/SATA; use its algorithm description only. [Algorithm chapter](https://en.oi-wiki.org/string/bm/). |
| Crochemore–Perrin Two-Way exact string matching | [`prefix_function`](p/prefix_function/README.md) computes KMP border lengths, while [`horspool_search`](h/horspool_search/README.md), [`boyer_moore`](b/boyer_moore/README.md), [`string_match_finite_automata`](s/string_match_finite_automata/README.md), and [`substring_search`](s/substring_search/README.md) use skip tables, an automaton, or direct scanning. No local package uses critical factorization and the Two-Way memory/period shifts; no Two-Way, Crochemore–Perrin, or critical-factorization implementation was found by path/content search. | Confirmed distinct and implemented as [`crochemore_perrin_two_way`](c/crochemore_perrin_two_way/README.md): ten language ports, primary critical-factorization oracle, independent direct-comparison oracle, workload, README/RIGHTS, and static package checker are registered in the byte-output suite. Generated cases cover seeded alphabets, empty-pattern maximum output, invalid frames, and capacity errors. Only the original paper’s algorithm description was used. [Crochemore and Perrin, JACM 38(3), 1991, DOI 10.1145/116825.116845](https://doi.org/10.1145/116825.116845). |
| OI Wiki Old Driver Tree / Chtholly Tree | Local lazy segment trees and treaps can support interval updates, but no package stores maximal equal-value intervals in an ordered set and splits/coalesces them at update boundaries. | Confirmed distinct expected-time interval-map profile: ten language ports, workload and dual array/run oracles, README/RIGHTS, and static package review are present. The shared byte-output suite now has oracle, bounds, workload validation, and generated maximum-size/malformed profiles. The bounded implementation documents its construction-sensitive worst case and uses array-backed run records at its small cap. OI Wiki presents the technique as dependent on randomized data rather than a worst-case guarantee; its page is CC BY-SA 4.0/SATA. [Algorithm chapter](https://en.oi-wiki.org/ds/odt/). |
| OI Wiki Segment History Extreme | [`segment_tree_beats`](s/segment_tree_beats/README.md) handles current range chmin/chmax/add and aggregate queries, but its contract does not track historical extrema over updates. | Confirmed distinct and implemented as the CPU-monitoring historical-maximum profile: ten ports support range assignment/addition with current and historical maximum queries; direct-array and independent prefix-replay oracles, workload, README/RIGHTS, and static checker are present. The bounded ABI normalizes ranges to zero-based half-open intervals and preserves the source update/history ordering. The shared byte-output runner and verifier register the independent oracles, maximum-answer trace, mixed updates, empty-query case, malformed inputs, and capacity profiles. OI Wiki discusses historical extrema separately from persistence; the page is CC BY-SA 4.0/SATA. [Algorithm chapter](https://en.oi-wiki.org/ds/seg-beats/). |
| OI Wiki mergeable and splittable segment tree | [`persistent_segment_tree`](p/persistent_segment_tree/README.md) path-copies point assignments for historical range sums; [`persistent_seg_tree_lazy_prop`](p/persistent_seg_tree_lazy_prop/README.md) path-copies lazy range updates; [`persistent_range_affine_range_sum`](p/persistent_range_affine_range_sum/README.md) preserves versions with lazy affine tags and range-copy. None destructively merges sparse frequency trees or extracts a value interval into a new multiset root. | Implemented as `segment_tree_merge_split`: bounded dynamic multiset counts over a fixed value domain, with point insertion, destructive root merge, inclusive range split into a fresh root, range-count queries, and 1-based kth queries. Ten ports, primary sparse segment-tree and independent 64-bin count-array oracles, workload, README/RIGHTS, static package checker, and `i64_array_bytes_output` runner/verifier registration are present. Source: [OI Wiki segment-tree merge and split](https://oi-wiki.org/ds/seg-merge-split/), CC BY-SA 4.0/SATA; clean-room algorithm description only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |
| OI Wiki Kinetic Tournament Tree | [`li_chao_tree`](l/li_chao_tree/README.md) maintains a static set of lines queried at supplied coordinates; it does not maintain a tournament winner as linear functions evolve with time and certificates expire. | Confirmed distinct and implemented in ten languages: fixed-slope lines support range translations and winner queries using tournament certificates; direct evaluation is the independent oracle. The package workload, README/RIGHTS, static inventory checker, and byte-output runner/verifier registration include maximum-query, longest-valid-frame, malformed, and capacity profiles. Changes remain source-only; no benchmark, program, test, checker, build, or compiler was run. OI Wiki labels the article CC BY-SA 4.0/SATA; only the algorithm description was used. [Algorithm chapter](https://oi-wiki.org/ds/kinetic-tournament-tree/). |
| OI Wiki Garsia–Wachs algorithm | [`optimal_binary_search_tree`](o/optimal_binary_search_tree/README.md) handles successful-key frequencies with interval DP; no package builds a minimum-cost alphabetic full binary tree from ordered leaf weights by the Garsia–Wachs phase-and-reconstruction method. | Confirmed distinct and implemented in ten languages: bounded workload, primary phase-and-reconstruction oracle, independent interval-DP verifier, README/RIGHTS, and static inventory checker. Registered in the byte-output runner and verifier with generated maximum-size profiles. The OI Wiki article is CC BY-SA 4.0/SATA; algorithm description only. [Algorithm chapter](https://oi-wiki.org/misc/garsia-wachs/). |
| CP-Algorithms Farach–Colton–Bender LCA | [`lowest_common_ancestor_binary_lifting`](l/lowest_common_ancestor_binary_lifting/README.md) uses an ancestor table and [`lowest_common_ancestor_tarjan`](l/lowest_common_ancestor_tarjan/README.md) uses offline DSU; neither uses the Euler-tour ±1 RMQ microblock/macroblock method. | Confirmed distinct static LCA candidate, implemented by `/root/poly_composite_sps`: ten bounded ports use Euler-tour ±1 RMQ with microblock signatures and a macroblock sparse table, with O(N) preprocessing and O(1) queries. Parent-climb oracle, independent BFS/ancestor-set verifier, workload, README/RIGHTS, and static package checker are written. Shared runner/verifier now include the algorithm, workspace, maximum-size and malformed-input profiles; all changes remain source-only. CP-Algorithms article is CC BY-SA 4.0; algorithm description only. [Algorithm article](https://cp-algorithms.com/graph/lca_farachcoltonbender.html). |
| OI Wiki Mo's algorithm and heavy-light decomposition | `mos_algorithm`, `heavy_light_decomposition_metadata`, and path sum/max packages are present. | Already present; no duplicate additions planned for these names. |
| OI Wiki offline dynamic connectivity | [`persistent_unionfind`](p/persistent_unionfind/README.md) branches insertion-only versions; [`online_bridge_finding`](o/online_bridge_finding/README.md) handles insertions and tracks bridges. Neither handles arbitrary add/remove intervals with rollback over a time segment tree. | Confirmed distinct: ten ports use segment-tree-over-time and rollback DSU for edge-ID add/remove/query sequences, with a BFS oracle, bounded workload, and byte-output suite integration. |
| CP-Algorithms Garner's algorithm / mixed-radix CRT | [`convolution_mod_1000000007`](c/convolution_mod_1000000007/README.md) and [`convolution_mod_2_64`](c/convolution_mod_2_64/README.md) already use Garner reconstruction to combine auxiliary-prime residues; [`chinese_remainder_theorem`](c/chinese_remainder_theorem/README.md) retains the separate product-of-moduli formula. | Covered: a standalone Garner package would benchmark the same mixed-radix reconstruction already exercised by both CRT/NTT profiles, so no duplicate is added. |
| CP-Algorithms discrete root and Montgomery multiplication | [`kth_root_mod`](k/kth_root_mod/README.md) already computes arbitrary discrete roots through a primitive-root discrete logarithm. [`embench_aha_mont64`](a/embench_aha_mont64/README.md) already benchmarks Montgomery-domain REDC multiplication with fixed `R=2^64`. | Both operations are covered; reject a new `R=2^32` port as the same REDC algorithm under a narrower word profile. |
| CP-Algorithms divide-and-conquer DP optimization | [`min_plus_convolution_convex_arbitrary`](m/min_plus_convolution_convex_arbitrary/README.md) already uses monotone divide-and-conquer minima over a Monge cost matrix. | Covered: the bounded-optimum search is the same optimization core; a partition-cost recurrence would change the application and input shape, not the benchmarked algorithm, so no duplicate is added. |
| CP-Algorithms Knuth optimization | [`optimal_binary_search_tree`](o/optimal_binary_search_tree/README.md) uses the same successful-search recurrence but scans every possible root cubically. | Confirmed distinct computational profile: ten Knuth-bounded `O(N^2)` ports for `N<=64` retain the recurrence with monotone split windows and a leftmost tie rule. The bounded workload, independent cubic verifier, package checker, and scalar-suite runner/verifier registrations are present. See [Knuth optimization](https://cp-algorithms.com/dynamic_programming/knuth-optimization.html) and the [benchmark contract](k/knuth_optimized_optimal_binary_search_tree/README.md). |
| CP-Algorithms Disjoint Sparse Table / OI Wiki Cat Tree | [`sparse_table`](s/sparse_table/README.md) handles leftmost range minima by overlapping idempotent blocks; no disjoint sparse table or cat tree was found. Segment trees and tree-path composition packages do not provide static O(1) ordered array folds. | Package complete as [`disjoint_sparse_table_affine_composition`](d/disjoint_sparse_table_affine_composition/README.md): ten ports, bounded `N,Q<=32` affine-map range composition, primary disjoint half-fold table, independent direct application-at-0-and-1 oracle, workload, README/RIGHTS, and static inventory checker are present. The byte-output suite registers 130-word generated inputs, noncommutative range queries, all 32 query outputs, malformed frames, and capacity probes. Sources: [CP-Algorithms Sparse Table](https://cp-algorithms.com/data_structures/sparse-table.html) (CC BY-SA 4.0) and [OI Wiki Cat Tree](https://oiwiki.net/ds/cat-tree/) (CC BY-SA 4.0/SATA); algorithm descriptions only. All work remains static-only. |
| CP-Algorithms broken-profile DP | Existing subset/profile algorithms do not provide the frontier-mask row transition for domino tilings; the local 2×n recurrence and mixed-length tile packages solve different problems. | Confirmed distinct: ten ports count open H×W domino tilings modulo 998244353 with `min(H,W)<=8` and area<=512. The primary profile DP, small-board enumeration, independent row-transition oracle, bounded workload, and scalar-suite runner/verifier registration are present. See [CP-Algorithms](https://cp-algorithms.com/dynamic_programming/profile-dynamics.html) and the [benchmark contract](b/broken_profile_domino_tilings/README.md). |
| CP-Algorithms Burnside / Pólya enumeration | [`burnside_bracelets`](b/burnside_bracelets/README.md) counts color-orbits under the dihedral rotations-and-reflections action; graph-coloring inclusion-exclusion solves a different counting problem. | Confirmed distinct: ten clean-room ports use Burnside averaging over permutation cycle structures, with an exhaustive coloring-orbit oracle, bounded workload, and byte-output suite integration. |
| CP-Algorithms placing bishops on a chessboard | [`n_queens_solution_count`](n/n_queens_solution_count/README.md) and [`queens`](q/queens/README.md) count queen placements with row, column, and diagonal conflicts. No bishop-placement count package was found. The bishop problem has only the two diagonal attack families and uses a color-separated diagonal-size recurrence, not the row/column queen search. | Implemented and registered as [`bishop_placements_count`](b/bishop_placements_count/README.md): scalar input `[N,K]`, `1<=N<=8`, `0<=K<=16`; returns the exact number of nonattacking bishop placements, with zero when `K` exceeds the board maximum and `-1` for malformed/out-of-profile input. Primary uses the per-color diagonal-size recurrence; an independent oracle uses subset DP over one diagonal family and masks the other. Ten ports, bounded workload, README/RIGHTS, package inventory checker, exact scalar-suite bounds, and generated cross-oracle profiles are registered. Source: [CP-Algorithms — Placing Bishops on a Chessboard](https://cp-algorithms.com/combinatorics/bishops-on-chessboard.html), CC BY-SA 4.0; use its algorithm description only. |
| CP-Algorithms scheduling jobs on two machines | [`smith_weighted_completion_time`](m/smith_weighted_completion_time/README.md) minimizes weighted completion sum on one machine; [`assembly_line_scheduling`](a/assembly_line_scheduling/README.md) chooses a line at each station of a two-line process; [`optimal_job_scheduling`](o/optimal_job_scheduling/README.md) handles process-machine transfer costs. No package orders jobs in a two-machine flow shop to minimize makespan under a common job order. | Implemented as [`johnson_two_machine_flow_shop`](j/johnson_two_machine_flow_shop/README.md) in ten languages. It uses Johnson's partition-and-sort rule with deterministic index ties; an independent exhaustive permutation oracle checks the optimum. The `[N,(a_i,b_i)*N]` scalar workload, README/RIGHTS, static package checker, bounded random profiles, malformed-input probes, and scalar-suite registration are present. Source: [CP-Algorithms — Scheduling jobs on two machines](https://cp-algorithms.com/schedules/schedule_two_machines.html), CC BY-SA 4.0; use the high-level algorithm description only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |
| CP-Algorithms optimal schedule by deadlines and durations | [`minimizing_lateness`](m/minimizing_lateness/README.md) schedules every job by earliest deadline and reports lateness; [`job_scheduling_with_deadline`](j/job_scheduling_with_deadline/README.md) handles unit-duration jobs with profits and arrival windows; [`weighted_interval_scheduling`](w/weighted_interval_scheduling/README.md) selects fixed intervals with weights. None maximizes the number of arbitrary-duration jobs completed by their deadlines. Implemented and registered as [`max_jobs_before_deadlines`](d/max_jobs_before_deadlines/README.md): scalar input `[N,(deadline_i,duration_i)*N]`, `0<=N<=12`, deadlines `0..1000`, positive durations `1..1000`; returns maximum feasible job count. Ten ports use the reverse-deadline min-heap method; an independent subset/EDF oracle checks the optimum. Workload, README/RIGHTS, static inventory checker, maximum-size and generated profiles, malformed frames, and scalar-suite registration are present. Source: [CP-Algorithms — Optimal schedule of jobs given their deadlines and durations](https://cp-algorithms.com/schedules/schedule-with-completion-duration.html), CC BY-SA 4.0; algorithm description only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |
| CP-Algorithms connected labeled graph counting | [`graph_enumeration`](g/graph_enumeration/README.md) maps labeled adjacency rows to a dense representation; [`graph_coloring`](g/graph_coloring/README.md) counts proper colorings; [`counting_spanning_trees_undirected`](c/counting_spanning_trees_undirected/README.md) counts spanning trees. None counts all connected simple undirected graphs on a labeled vertex set. Implemented and registered as [`connected_labeled_graph_count`](c/connected_labeled_graph_count/README.md) in ten languages: scalar input `[N]`, `1<=N<=512`, output modulo 998244353. The primary uses the rooted-component recurrence; an independent oracle uses formal EGF inversion and coefficient extraction. Workload fixtures, README/RIGHTS, static package checker, scalar runner/verifier integration, and bounded valid/malformed profiles are present. Both oracle modules expose valid/parseable input-length bounds 1/2. Source: [CP-Algorithms — Counting labeled graphs](https://cp-algorithms.com/combinatorics/counting_labeled_graphs.html), CC BY-SA 4.0; algorithm descriptions only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |
| Bostan–Mori distant linear-recurrence term | [`linear_recurrence_matrix`](l/linear_recurrence_matrix/README.md) uses matrix exponentiation for a related recurrence output; [`berlekamp_massey`](b/berlekamp_massey/README.md) infers a recurrence from supplied sequence values. Neither uses numerator/denominator parity extraction to halve the target index. | Implemented and registered as [`bostan_mori_recurrence_term`](b/bostan_mori_recurrence_term/README.md): ten ports accept an order-at-most-eight recurrence over F_998244353 and index through 10^18. The primary forms the rational generating function and halves the target through parity extraction; independent companion-matrix exponentiation checks the answer. Workload, README/RIGHTS, static inventory checker, scalar runner/verifier registration, maximum-index and order profiles, random recurrences, and malformed frames are included. Based on Bostan and Mori, [A Simple and Fast Algorithm for Computing the N-th Term of a Linearly Recurrent Sequence](https://arxiv.org/abs/2008.08822); algorithm description only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |
| NIST Dictionary of Algorithms and Data Structures: undirected Chinese postman / route inspection | [`eulerian_path`](e/eulerian_path/README.md) constructs a trail only when odd-degree conditions allow it; [`eulerian_trail_undirected_simple`](e/eulerian_trail_undirected_simple/README.md) handles an already Eulerian simple graph. [`general_weighted_matching`](g/general_weighted_matching/README.md) optimizes edge weights on the supplied graph and does not build shortest-path distances among its odd-degree vertices. No package minimizes a closed walk that traverses every edge of a connected weighted undirected graph. | Implemented and registered as [`undirected_chinese_postman`](u/undirected_chinese_postman/README.md): ten language ports, primary Floyd–Warshall plus bitmask minimum-pairing DP, independent Dijkstra over `(current vertex, covered-edge mask)`, bounded workload, README/RIGHTS, and root-level static inventory checker. Contract: connected simple undirected graphs with `N<=8`, `M<=12`, positive weights `<=1000`; return base edge-weight sum plus minimum pairing cost, with the one-vertex empty graph returning zero and malformed input returning `-1`. Scalar-suite profiles include maximum-edge input, 48 deterministic generated graphs, malformed records, and cross-oracle checks. Source: [NIST DADS — Chinese postman problem](https://xlinux.nist.gov/dads/HTML/chinesePostman.html), which cites Edmonds and Johnson's matching/T-join formulation; see also [Berkeley IEOR 269 notes](https://hochbaum.ieor.berkeley.edu/files/ieor269-2010.pdf). Use the algorithm description only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |
| OI Wiki Meissel–Lehmer prime counting, Du Jiao summatory sieve, and Min_25 sieve | Prime sieve and factorization packages cover direct enumeration; `sum_of_multiplicative_function_large` already uses Min_25 for a different summatory function. | Meissel–Lehmer is confirmed distinct: ten ports, bounded workload, independent segmented-sieve oracle, and scalar-suite registration are present. Du Jiao is already covered by [`sum_of_totient_function`](s/sum_of_totient_function/README.md): its ten ports sieve a totient prefix, then memoize the exact quotient-block recurrence `S(n)=n(n+1)/2-Σ_{k=2..n}S(floor(n/k)) mod 998244353`. OI Wiki's Du Jiao article gives this recurrence as its Euler-totient example. The canonical Mertens-prefix variant would change the summed function, not the benchmarked sieve algorithm, so no duplicate package is added. `sum_of_multiplicative_function_large` is a separate Min_25 method; `counting_squarefrees` uses a direct Möbius sieve and weighted quotient sum, not Du Jiao. |
| OI Wiki polynomial transforms and linear basis | Number Theoretic Transform, Fast Walsh–Hadamard Transform, and subset convolution packages are present; none maintains a basis of inserted 63-bit vectors for maximum-subset-XOR and membership queries. | NTT/FWHT are already present. `xor_linear_basis` is confirmed distinct: ten ports use 63 highest-pivot entries, with exhaustive-subset oracles capped at 16 insertions, workload and rights notes, and byte-output suite registration. See [OI Wiki — Linear Basis](https://www.timothywang.ca/OI-wiki/math/linear-algebra/basis/). |
| Library Checker k-shortest walk | [`yens_kshortest_paths`](y/yens_kshortest_paths/README.md) computes loopless k-shortest paths; the new [`k_shortest_walk`](k/k_shortest_walk/README.md) ranks edge-distinct walks that may repeat vertices and edges. | Confirmed distinct; ten port drafts, workload, exact-length DP oracle and static source/workload checker, byte-suite registration, and independent suite oracle are present. The Mojo draft remains unverified. No runtime validation was run. |
| Library Checker minimum-diameter spanning tree | MST weight minimization and ordinary tree-diameter packages optimize different objectives from choosing a spanning tree with minimum diameter. | Confirmed distinct: ten ports enumerate vertex and half-integral edge centers, with a shortest-path-tree oracle, exhaustive bounded certificate checker, workload, and byte-output suite integration. |
| Library Checker bipartite edge coloring | Vertex matchings and edge coloring of general conflict graphs are present, but no bipartite edge-coloring package was found by path search. | Confirmed distinct: ten ports decompose bounded bipartite multigraphs into the minimum number of matchings, with an independent edge-coloring oracle, workload, and byte-output suite registration. |
| Library Checker dynamic graph vertex-add component-sum | [Official task](https://github.com/yosupo06/library-checker-problems/blob/master/graph/dynamic_graph_vertex_add_component_sum/task.md) includes edge insertion/removal, vertex-value addition, and component-sum queries. Existing offline dynamic connectivity handles edge lifetimes and connectivity answers but has no vertex weights or aggregate updates. | Implemented and registered as [`dynamic_graph_vertex_add_component_sum`](d/dynamic_graph_vertex_add_component_sum/README.md): ten ports, `n<=16`, `q<=32`, time-segment-tree intervals for edges and value deltas, rollback DSU with per-component sums, direct-graph oracle and independent rebuild-DSU verifier. This extends rollback state and query semantics; it is not a duplicate of connectivity-only offline dynamic connectivity. |
| Library Checker convolution family: GCD, LCM, multivariate, and min-plus variants | Ordinary one-dimensional FFT/NTT, Walsh–Hadamard, and subset convolution solve different algebraic products. | The named GCD, LCM, truncated/cyclic multivariate, and convex/concave min-plus operations each have separately compared contracts and tracked packages below. Do not merge different index monoids or feasible-region rules; remaining convolution and set-power-series tasks need task-level review. |
| Library Checker number-theory family: prime counting, quotient enumeration, floor sums, modular roots/tetration, and summatory functions | Sieve, factorization, primitive-root, and BSGS packages supply primitives but do not by themselves cover the named bounded queries. | The named prime-counting, quotient-enumeration, floor-sum, modular-prefix-minimum, modular-root/tetration, and summatory-function candidates have individual comparison records below. Review any remaining official task by its arithmetic domain and output contract before adding another package. |
| Library Checker polynomial and set-power-series operations | NTT/FWHT, subset convolution, and basic polynomial operations exist; upstream lists formal power-series inverse/log/exp/pow/sqrt, composition, compositional inverse, multipoint evaluation/interpolation, polynomial division/factorization, and set-power-series operations. | `inv_of_formal_power_series`, `exp_of_formal_power_series`, `log_of_formal_power_series`, `composition_of_formal_power_series`, `inv_of_polynomials`, [`sqrt_of_formal_power_series`](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/sqrt_of_formal_power_series/task.md), [`polynomial_taylor_shift`](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/polynomial_taylor_shift/task.md), [`division_of_polynomials`](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/division_of_polynomials/task.md), and [`pow_of_formal_power_series`](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/pow_of_formal_power_series/task.md) are confirmed distinct and implemented with ten ports each, bounded profiles, independent oracles, workloads, rights notes, package-local static checkers, and byte-output suite integration. Polynomial division returns quotient and remainder over F_998244353; it differs from CRC division over GF(2), and from polynomial inverse, which applies long division within the higher-level extended-Euclid algorithm. [`compositional_inverse_of_formal_power_series`](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/compositional_inverse_of_formal_power_series/task.md) inverts f under composition with a_0=0 and a_1≠0; it differs from direct composition and reciprocal inversion. Its ten ports, Lagrange-inversion oracle, workload, package checker, and byte-output suite integration are complete for the bounded profile. The power profile accepts arbitrary coefficients and exponents, including M=0 and positive powers of a zero-constant series; it uses truncated repeated squaring through degree 32 and differs from exp/log input constraints. [`factorization_of_polynomials`](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/factorization_of_polynomials/task.md) returns every distinct monic irreducible factor and multiplicity over an input prime field. Its bounded exhaustive-factor profile (p∈{2,3,5}, N<=8) is implemented in ten ports and registered in the byte-output suite. Other confirmed distinct operations and conditional geometric-method variants are listed in the full category crosswalk below. No programs, tests, checkers, builds, compilers, or benchmarks were run. |
| Library Checker enumerative combinatorics: factorials, binomial variants, partitions, Stirling numbers, and sequence counts | Local packages cover several related sequences, while q-binomial coefficients and constrained nondecreasing-sequence counts are distinct operations. | The 18-task category has an operation-level crosswalk below. A bounded q-binomial prime-mod profile is implemented in ten languages with recurrence and subset-enumeration oracles, workload, rights note, static checker, and byte-output suite registration. The Stirling-second-kind full row has ten ports, recurrence and inclusion-exclusion oracles, workload, and scalar-suite registration. Constrained increasing-sequence counting now has ten ports, dual oracles, a bounded workload, and scalar-suite integration. Both small-prime/large-n Stirling profiles have ten ports, dual oracles, bounded workloads, package-local static checkers, and scalar-suite registration. |
| Library Checker linear algebra: modular determinants/ranks, matrix inverse, adjugate, characteristic polynomial, Hafnian, and F2-space intersection | General elimination and determinant packages coexist with separate bit-packed and combinatorial operations. | Adjugate, characteristic polynomial, Hafnian, F2-space intersection, GF(2) product/determinant, arbitrary-modulus determinant, and sparse determinant have operation-level records below; verify each remaining official task before treating generic rank/inverse coverage as equivalent. |
| Library Checker string and geometry family: run enumeration, deque palindromes, furthest pair, and Euclidean MST; related geometry literature includes convex layers | Suffix structures, Eertree, Manacher, closest pair, convex hull, Manhattan MST, Euclidean MST, and enclosing-circle packages cover different operations in this family. | Run enumeration, bounded deque-palindrome operations, furthest pair, Euclidean MST, and convex layers each have distinctness and package records below. These bounded profiles state where they differ from the official asymptotic task. |
| Library Checker Big Integer and linear recurrence tasks | [`addition_of_big_integers`](a/addition_of_big_integers/README.md) adds canonical signed decimal integers with separate magnitude addition/subtraction; local binary addition and unsigned decimal multiplication do not implement that signed decimal operation. | Nine Big Integer and recurrence tasks have an operation-level crosswalk below. Signed decimal addition is confirmed distinct and complete with ten ports, dual oracles, workload and `i64_array_bytes_output` suite integration. |

## Library Checker Polynomial and Set Power Series audit (2026-11-12)

Compared the full official category inventory of 26 Polynomial tasks and 4 Set Power Series tasks in [`categories.toml`](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/categories.toml) against local package contracts. Sparse and large task variants are recorded as aliases where only input representation or maximum size changes; a different specialized method can be registered separately when it is actually implemented.

| Official task | Local comparison | Disposition |
| --- | --- | --- |
| `inv_of_formal_power_series` | [`inv_of_formal_power_series`](i/inv_of_formal_power_series/README.md) uses a coefficient recurrence in the ports; its independent oracle uses Newton doubling. | Operation covered by the recurrence profile. A separate Newton-reciprocal implementation is reserved below because its multiplication-based iteration is a distinct computational method; the existing Newton oracle alone is not a benchmark port. |
| `exp_of_formal_power_series` | [`exp_of_formal_power_series`](e/exp_of_formal_power_series/README.md) | Implemented; ten ports and byte suite. |
| `log_of_formal_power_series` | [`log_of_formal_power_series`](l/log_of_formal_power_series/README.md) | Implemented; ten ports and byte suite. |
| `pow_of_formal_power_series` | [`pow_of_formal_power_series`](p/pow_of_formal_power_series/README.md) | Implemented; ten ports, repeated-squaring oracle plus valuation/binomial independent oracle, and byte suite. |
| `sqrt_of_formal_power_series` | [`sqrt_of_formal_power_series`](s/sqrt_of_formal_power_series/README.md) | Implemented; ten ports and byte suite. |
| `composition_of_formal_power_series` | [`composition_of_formal_power_series`](c/composition_of_formal_power_series/README.md) | Implemented; ten ports and byte suite. |
| `compositional_inverse_of_formal_power_series` | [`compositional_inverse_of_formal_power_series`](c/compositional_inverse_of_formal_power_series/README.md) | Implemented; ten ports and byte suite. |
| `inv_of_formal_power_series_sparse` | Same reciprocal operation as the dense formal-series inverse profile. | Duplicate variant; sparse encoding alone does not change the algorithm. |
| `exp_of_formal_power_series_sparse` | Same formal-series exponential operation as its dense profile. | Duplicate variant; no distinct sparse recurrence is implemented. |
| `log_of_formal_power_series_sparse` | Same formal-series logarithm operation as its dense profile. | Duplicate variant; no distinct sparse recurrence is implemented. |
| `pow_of_formal_power_series_sparse` | Same arbitrary formal-series power operation as its dense profile. | Duplicate variant; sparse encoding alone does not change the algorithm. |
| `sqrt_of_formal_power_series_sparse` | Same formal-series square-root operation as its dense profile. | Duplicate variant; no distinct sparse recurrence is implemented. |
| `product_of_polynomial_sequence` | [`product_of_polynomial_sequence`](p/product_of_polynomial_sequence/README.md) uses balanced pairwise products; convolution packages only multiply one polynomial pair. | Implemented; ten ports, balanced product-tree oracle plus sequential independent oracle, workload, and byte-output suite. |
| `multipoint_evaluation` | [`multipoint_evaluation`](m/multipoint_evaluation/README.md) builds a product/remainder tree; local point-evaluation packages only process one point per call. | Implemented; ten ports use product/remainder trees, with an independent Horner oracle and byte-output suite registration. |
| `multipoint_evaluation_on_geometric_sequence` | [`multipoint_evaluation_on_geometric_sequence`](m/multipoint_evaluation_on_geometric_sequence/README.md) uses a Bluestein chirp-z transform and NTT convolution, distinct from the general product/remainder-tree profile. | Implemented; ten ports handle zero starts, zero ratios, and repeated points, with an independent Horner oracle and byte-output suite registration. |
| `polynomial_interpolation` | [`polynomial_interpolation`](p/polynomial_interpolation/README.md) | Implemented; ten ports use Lagrange basis construction, with an independent Vandermonde-elimination oracle and byte-output suite. |
| `polynomial_interpolation_on_geometric_sequence` | General interpolation uses direct Lagrange bases; no local q-Newton divided-difference profile was found. | Implemented; ten ports use q-Newton differences, with an independent Vandermonde-elimination oracle and byte-output suite registration. |
| `polynomial_taylor_shift` | [`polynomial_taylor_shift`](p/polynomial_taylor_shift/README.md) | Implemented; ten ports and byte suite. |
| `shift_of_sampling_points_of_polynomial` | [`shift_of_sampling_points_of_polynomial`](s/shift_of_sampling_points_of_polynomial/README.md) changes sample locations; `polynomial_taylor_shift` changes the coefficient vector. | Implemented; ten ports use forward differences and Newton evaluation, with an independent Lagrange oracle, workload, and byte-output suite. |
| `division_of_polynomials` | [`division_of_polynomials`](d/division_of_polynomials/README.md) | Implemented; ten ports and byte suite. |
| `inv_of_polynomials` | [`inv_of_polynomials`](i/inv_of_polynomials/README.md) | Implemented; ten ports and byte suite. |
| `factorization_of_polynomials` | [`factorization_of_polynomials`](f/factorization_of_polynomials/README.md) returns distinct monic irreducibles and multiplicities over finite fields; integer factorization and polynomial root finding are different operations. | Implemented; ten ports for p∈{2,3,5}, N<=8, exhaustive bounded factor search, workload and byte-output suite. |
| `conversion_from_monomial_basis_to_newton_basis` | [`conversion_from_monomial_basis_to_newton_basis`](c/conversion_from_monomial_basis_to_newton_basis/README.md) converts monomial coefficients to a supplied Newton basis; no prior package was found. | Implemented; ten ports use synthetic division, an independent basis-matrix elimination oracle, workload, and byte-output suite. |
| `polynomial_root_finding` | [`polynomial_root_finding`](p/polynomial_root_finding/README.md) enumerates distinct roots in F_998244353; local small-prime factorization returns full irreducible factors, and real cubic approximation is a different operation. | Implemented; ten ports use linear-part extraction and Cantor–Zassenhaus splitting, with an independent direct-evaluation oracle and byte-output suite registration. |
| `composition_of_formal_power_series_large` | Same operation and input semantics as `composition_of_formal_power_series`; the local package uses descending Horner composition. | Duplicate size variant; larger N alone is not distinct. The distinct method profile [`brent_kung_fps_composition`](b/brent_kung_fps_composition/README.md) is implemented and registered: it computes the same truncated `f(g) mod x^N` operation, with `g(0)=0`, over `F_998244353`, for `1<=N<=32`. Brent–Kung baby-step/giant-step composition splits outer coefficients into blocks of `m=ceil(sqrt(N))`, forms baby powers, evaluates each coefficient block against those powers, then combines blocks by Horner in `g^m`. Ten ports, Brent–Kung primary oracle, independent Horner oracle, workload/docs/rights, package-local static checker, byte-output suite bounds and generated maximum-size/capacity cases are present. Sources: [Brent and Kung, JACM 25 (1978)](https://doi.org/10.1145/322092.322099), [author-hosted paper](https://maths-people.anu.edu.au/~brent/pd/rpb045.pdf), and [FLINT's algorithm description](https://github.com/flintlib/flint/blob/main/doc/src/algorithms/polynomials/composition.md). |
| `compositional_inverse_of_formal_power_series_large` | Same operation and input semantics as `compositional_inverse_of_formal_power_series`, whose ports use an incremental coefficient recurrence. | Duplicate size variant; larger N alone is not distinct. The separately identified Newton-doubling reversion method is reserved below as a computationally distinct algorithm, not as a size alias. |
| `subset_convolution` | [`fast_subset_convolution`](f/fast_subset_convolution/README.md) uses ranked subset zeta and Möbius transforms. | Implemented; same operation and algorithm family. |
| `power_projection_of_set_power_series` | [`power_projection_of_set_power_series`](p/power_projection_of_set_power_series/README.md) | Implemented; ten ports compute successive weighted projections using submask convolution, with an independent assignment-enumeration oracle and byte-output suite. |
| `exp_of_set_power_series` | [`exp_of_set_power_series`](e/exp_of_set_power_series/README.md) computes the exponential in the square-zero subset algebra. | Implemented; ten ports, subset-cardinality recurrence, set-partition oracle, workload, and byte-output suite. |
| `polynomial_composite_set_power_series` | No univariate polynomial evaluation in the square-zero subset algebra was found. | Implemented; ten ports use Horner composition with subset convolution, with an independent ordered-factor assignment oracle and byte-output suite registration. |

### Newton-doubling formal series reversion (reserved 2026-11-13)

Owner: root. Candidate `newton_compositional_inverse_fps` solves the same mathematical operation as `compositional_inverse_of_formal_power_series` but uses precision-doubling Newton correction of the composition equation, instead of its incremental coefficient recurrence. A repository README/catalog search found no benchmark port using this method. [FLINT's algorithm overview](https://github.com/flintlib/flint/blob/main/doc/src/algorithms/polynomials/composition.md) distinguishes Newton reversion from Lagrange inversion and identifies composition and series division as its core steps. The [Library Checker source repository](https://github.com/yosupo06/library-checker-problems) is Apache-2.0; sources are used for algorithm ideas only, with independent code and fixtures. Contract: `2<=N<=16`, field F_998244353, `f[0]=0`, `f[1]!=0`, and the first N coefficients of the inverse as little-endian i64. No execution is permitted while profiling continues.

The [bounded contract](n/newton_compositional_inverse_fps/README.md), Newton-doubling drafts in all ten languages, workload, Newton primary oracle, reference to the existing independently structured Lagrange oracle, static package inventory, and byte-output suite registration are now written. All remain unexecuted and require further review.

The generated verifier corpus compares the Newton oracle with the Lagrange reference across every supported series length and includes malformed-input precedence and output-capacity cases. This coverage is specified in source only and has not been run.

### Newton-doubling formal series reciprocal (reserved 2026-11-13)

Owner: root. Candidate `newton_reciprocal_fps` computes the same truncated multiplicative inverse as [`inv_of_formal_power_series`](i/inv_of_formal_power_series/README.md), but updates an approximation by `g <- g*(2-f*g)` at doubled precision. The existing package's ten benchmark ports use a coefficient-by-coefficient recurrence; its Newton implementation is an oracle, not a timed language port. [`newton_compositional_inverse_fps`](n/newton_compositional_inverse_fps/README.md) solves a different composition equation and uses a coefficient recurrence for its internal reciprocal. [FLINT's inversion documentation](https://flintlib.org/doc/nmod_poly/inv_series.html) describes both recurrence and Newton approaches. Use the mathematical description only; independently write implementations and fixtures. Contract: `[N,f_0,...,f_(N-1)]`, `1<=N<=64`, F_998244353 coefficients, `f_0!=0`, and N little-endian i64 coefficients; invalid input -1, null/short output -2. All work remains unexecuted.

The [contract](n/newton_reciprocal_fps/README.md), drafts in all ten languages, workload, package inventory checker, byte-output suite registration, and references to the existing local Newton and coefficient-recurrence oracles are written. All remain unexecuted and require further review.

### Reciprocal square root of a formal power series (reserved 2026-11-13)

Owner: root. The [`sqrt_of_formal_power_series`](s/sqrt_of_formal_power_series/README.md) ports compute a square root with a coefficient recurrence; [`newton_reciprocal_fps`](n/newton_reciprocal_fps/README.md) computes a multiplicative reciprocal. A local README and catalog search found no operation returning a series `g` with `f*g²=1`. The [FLINT reciprocal-square-root documentation](https://flintlib.org/doc/acb_poly/index.html) describes a division-free Newton update distinct from computing a square root and then a separate reciprocal. The bounded `newton_inverse_sqrt_fps` profile uses F_998244353, `1<=N<=64`, `f[0]=1`, and outputs the unique `g` with `g[0]=1` and `f*g²=1 mod x^N`. Using unit constant avoids a separate modular-root selection policy and makes the Newton kernel's contract explicit. Source descriptions are used for mathematical ideas only; code and fixtures are independently written.

The [contract](n/newton_inverse_sqrt_fps/README.md), drafts in all ten languages, workload, package checker, suite registration, independently validating Newton and derivative-recurrence oracles, and rights note are now written. All remain unexecuted and require further review.

The verifier source now also includes deterministic maximum-precision alternating-series and highest-degree correction cases. Static review changed the Mojo arrays to explicit zero fills; neither the checks nor the port has been executed.

### Seidel unweighted all-pairs distances (reserved 2026-11-13)

Owner: root. [`floyd_warshall`](f/floyd_warshall/README.md) uses weighted intermediate-vertex relaxation, [`johnson_shortest_paths`](j/johnson_shortest_paths/README.md) combines Bellman–Ford and Dijkstra, and [`apsp_min_plus_repeated_squaring`](a/apsp_min_plus_repeated_squaring/README.md) repeatedly squares a distance matrix over the min-plus semiring. [`all_shortest_paths_unweighted`](a/all_shortest_paths_unweighted/README.md) enumerates shortest paths for one pair rather than a distance matrix. A local README search found no timed Seidel distance algorithm, which instead recursively squares an unweighted undirected adjacency matrix over ordinary integers and recovers original distances by degree-weighted neighbor sums. [Seidel's original paper](https://www.mimuw.edu.pl/~mucha/teaching/alp2006/seidel92.pdf) identifies this method and its connected-graph condition. The bounded `seidel_unweighted_apsp` profile uses schoolbook integer matrix multiplication and does not claim fast-matrix complexity. Source is for mathematical ideas only; contract, fixtures, oracles, and code are independently written. No execution is allowed while profiling continues.

The [bounded contract](s/seidel_unweighted_apsp/README.md), drafts in all ten languages, workload, package checker, suite registration, independently validated Seidel and BFS oracle calculations, and rights note are now written. All remain unexecuted and require further review.

### Karger contraction cut trial (reserved 2026-11-13)

Owner: root. [`stoer_wagner`](s/stoer_wagner/README.md) computes an exact global cut by deterministic maximum-adjacency phases, and [`randomized_contraction_edge_sampling`](r/randomized_contraction_edge_sampling/README.md) covers only an edge-sampling phase rather than complete contraction to two supervertices. [`karger_contraction_trial`](k/karger_contraction_trial/README.md) is a distinct bounded full contraction trial driven by supplied edge ranks; it does not guarantee a minimum cut. [Karger's original work](https://people.csail.mit.edu/karger/Papers/contract.pdf) supplies the mathematical idea only. Its ports and suite integration remain unexecuted and require verification.

The [CP-Algorithms Stoer–Wagner article](https://cp-algorithms.com/graph/stoer_wagner_mincut.html) describes the same maximum-adjacency contraction method as the existing package, so no duplicate is added. Static review of the Elisa port moved its reused vertex index into the enclosing phase and switched input access to a bounded view; the edit is uncompiled and untested.

The [bounded contract](k/karger_contraction_trial/README.md), drafts in all ten languages, workload, package checker, scalar suite wiring, independently validated disjoint-set and component-label oracle calculations, and rights note are written. All work remains unexecuted and needs verification.

Static review changed the Elisa Karger draft's fixed arrays to the syntax used by neighboring ports. The draft remains uncompiled and untested.
The scalar verifier source now also checks that reversing all undirected edge endpoints preserves each small-graph trial result. This check remains unexecuted.

## Library Checker Data Structure category crosswalk (first pass, 2026-10-29)

## Library Checker Geometry category crosswalk (2026-11-12)

Compared all eight entries in the official [Geometry category](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/categories.toml) with local geometry contracts. The Library Checker repository is Apache-2.0; this crosswalk uses task metadata and algorithm descriptions only.

| Official task | Local contract comparison | Decision / next action |
| --- | --- | --- |
| [`sort_points_by_argument`](https://github.com/yosupo06/library-checker-problems/blob/master/geo/sort_points_by_argument/task.md) | [`to_polar_angle_degrees`](t/to_polar_angle_degrees/README.md) converts one point to an angle; it does not sort points by exact polar order. Hull builders sort by other keys. | Confirmed distinct comparator-sort profile: ten ports use exact half-plane/cross-product ordering and deterministic collinear ties, with workload and dual exact-ordering oracles. Shared byte-output suite bounds, oracle, workload validation, and maximum/malformed profiles are registered. All ten ports and suite wiring received a source-only consistency review. |
| [`static_convex_hull`](https://github.com/yosupo06/library-checker-problems/blob/master/geo/static_convex_hull/task.md) | [`convex_hull_graham_scan`](c/convex_hull_graham_scan/README.md), [`monotone_chain`](m/monotone_chain/README.md), and [`convex_hull_quickhull`](c/convex_hull_quickhull/README.md) compute the static boundary with distinct construction algorithms. | Covered; keep materially distinct hull methods, and do not create an alias for the official output normalization. |
| Graham-named x-sorted hull versus Andrew monotone chain | The former `convex_hull_graham` sorted by x, classified points relative to the endpoint baseline, and updated two chains in one traversal; [`monotone_chain`](m/monotone_chain/README.md) sorts and deduplicates lexicographically and scans all points in each direction. The [CP-Algorithms monotone-chain description](https://cp-algorithms.com/geometry/convex-hull.html#monotone-chain-algorithm) identifies baseline classification and two-chain construction as Andrew's method, rather than the polar-angle Graham scan. The local C ports used the same sorted-chain and orientation-pop core; collinear policy, input restrictions, output representation, and whether each chain sees all points are profile choices. | Consolidated under `monotone_chain`. The catalog and canonical README preserve the JavaScript attribution and specify the shared general-position domain and output normalization; a mixed-side unsorted fixture was translated to the canonical coordinate-output contract. The redundant ports, workload, oracle, and runner/verifier registrations were removed. `convex_hull_graham_scan` remains distinct because it uses polar-angle ordering. No code was run. |
| [`count_points_in_triangle`](https://github.com/yosupo06/library-checker-problems/blob/master/geo/count_points_in_triangle/task.md) | No local package answers many strict-interior triangle queries over one fixed point set. Point-in-triangle predicates and triangle enumeration count different operations. | Confirmed distinct offline geometry-query profile: ten ports use per-anchor exact-angle sorting, Fenwick range counts, and strict-boundary inclusion-exclusion for `N,M<=24`, `Q<=128`. The direct point-containment oracle, workload, README/RIGHTS, and static package inventory review are present. The shared byte-output runner/verifier register workspace, dual oracles, maximum-query, malformed-input, and output-capacity profiles. |
| [`closest_pair`](https://github.com/yosupo06/library-checker-problems/blob/master/geo/closest_pair/task.md) | [`closest_pair_divide_and_conquer`](c/closest_pair_divide_and_conquer/README.md) already computes an exact bounded Euclidean closest pair by x/y divide-and-conquer; [`pargeo_bichromatic_closest_pair`](p/pargeo_bichromatic_closest_pair/README.md) covers a separate two-color KD-tree search. | Covered by the same-set divide-and-conquer algorithm; batching and larger upstream limits do not require a duplicate package. |
| [`furthest_pair`](https://github.com/yosupo06/library-checker-problems/blob/master/geo/furthest_pair/task.md) | [`rotating_calipers`](r/rotating_calipers/README.md) computes the point-set diameter with a convex hull and antipodal sweep. | Covered; the task's multi-case framing and pair witness do not change the diameter algorithm. |
| [`convex_layers`](https://github.com/yosupo06/library-checker-problems/blob/master/geo/convex_layers/task.md) | [`convex_layers`](c/convex_layers/README.md) repeatedly removes boundary layers and defines the duplicate/collinear-boundary policy. | Covered by ten ports and byte-output suite integration. |
| [`manhattanmst`](https://github.com/yosupo06/library-checker-problems/blob/master/geo/manhattanmst/task.md) | [`manhattan_mst`](m/manhattan_mst/README.md) constructs an L1 minimum spanning tree from points without materializing the complete graph. | Covered by its implicit Manhattan-distance MST profile. |
| [`euclidean_mst`](https://github.com/yosupo06/library-checker-problems/blob/master/geo/euclidean_mst/task.md) | [`euclidean_mst`](e/euclidean_mst/README.md) derives Delaunay candidate edges and runs Kruskal with exact orientation/incircle predicates. | Covered by the coordinate-derived Euclidean MST package and its byte-output suite integration. |

The two confirmed distinct geometry candidates were assigned to `/root/multipoint_evaluation`. `sort_points_by_argument` and `count_points_in_triangle` now each have ten source ports, workload, docs, independent oracles, and shared byte-output suite registration. Both received source-only review; the triangle profile includes generated maximum-query, malformed-input, and capacity cases. No programs, tests, checkers, scripts, builds, compilers, or benchmarks have been run.

The official [`categories.toml`](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/categories.toml) lists the following 44 Data Structure tasks. This first pass compared every item with local package paths and the relevant README contracts. “Candidate” means the exact operation or algorithm still needs a deeper source and ABI comparison before assignment; a filename search alone is not treated as proof of absence. Two same-algorithm pairs were consolidated under canonical `sparse_table` and `fenwick_tree` benchmarks. The `associative_array` contract received a task-level comparison on 2026-11-11 and was marked already covered by the existing hash-map family. The `segment_add_get_min` and `static_range_mode_query` packages and suite registrations are complete.

| Official task | Local comparison | First-pass disposition |
| --- | --- | --- |
| `associative_array` | The [official contract](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/associative_array/task.md) initializes a sparse array to zero and applies key assignment and lookup; its limits are 1,000,000 operations and keys/values through 10^18. Local `generic_hash_map`, `hash_map_open_addressing`, `hash_map_separate_chaining`, `hash_map_cuckoo_hashing`, and `double_hash_hash_table` already exercise mutable map lookup and update with separate-chaining, linear-probing, cuckoo, and double-hashing strategies. | Already present/duplicate: the task specifies the common map interface, not a new data structure or collision strategy. Its larger operation/key limits are a workload-scale difference, so keep the existing distinct hash-map algorithms and do not add an alias package. |
| `predecessor_problem` | The [official operation contract](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/predecessor_problem/task.md) has idempotent insert/delete, membership, successor, and predecessor operations on a bit-string set. `rank_select_bitstring` is static rank/select, and the local tree packages do not provide this packed-bitset workload. | Confirmed distinct: nine standard ports, optional Mojo, packed-word workload, set-based oracle, and byte-output runner/verifier integration are written. The bounded successor/predecessor scan is `O(N/64 + 64)` worst case; no programs, tests, or benchmarks were run. |
| `ordered_set` | `binary_search_tree`, `splay_tree`, and `treap_unique_key_set` already implement ordered-set insertion/deletion/search; their README contracts do not maintain subtree cardinalities for the complete kth/rank/predecessor/successor operation mix. | Implemented as [`ordered_set_avl_order_statistics`](o/ordered_set_avl_order_statistics/README.md), a distinct size-augmented AVL profile. The new package adds dynamic rank/select and inclusive neighbor queries; the existing set-only BST/treap profiles remain separate algorithm benchmarks without receiving aliases. |
| `double_ended_priority_queue` | `min_max_heap_double_ended` already implements insertion, min/max inspection and extraction, and duplicate retention. | Covered. |
| `unionfind` | `union_find` implements union, connectivity, and component reporting. | Covered. |
| `unionfind_with_potential` | Ordinary `union_find` has no relative-weight or potential constraints. | Confirmed distinct weighted modular-potential DSU: nine standard ports plus Mojo, fixed-width update/query workload, independent graph-traversal oracle, and byte-output suite registration are complete. |
| `unionfind_with_potential_non_commutative_group` | Ordinary `union_find` has no group-valued, order-sensitive potential composition; additive potentials commute and cannot represent `SL(2,F)` matrix order. | Confirmed distinct: nine standard ports plus Mojo, fixed-width matrix-update workload, independent graph oracle, and byte-output suite registration cover the bounded contract. |
| `range_parallel_unionfind` | Ordinary DSU handles single-edge unions, while persistent range-value trees do not maintain graph connectivity. | Confirmed distinct range-parallel DSU: ten language ports, explicit-graph BFS oracle, bounded workload, and byte-output suite registration are present. |
| `static_range_sum` | `prefix_sum` builds cumulative sums and answers inclusive range sums, though its current ABI handles one query per call. | Covered algorithmically by prefix sums; consider a batched-query workload only if it changes the measured profile, not a new algorithm name. |
| `staticrmq` | `sparse_table` and the former `range_minimum_query` package both built sparse tables and answered static RMQ in O(1) after O(n log n) preprocessing. | Duplicate removed: `sparse_table` is canonical; the Rust source remains alternate provenance, while duplicate ports, workload, and suite branch are removed. |
| `point_add_range_sum` | `fenwick_tree` and the former `binary_indexed_tree` package both implemented the same Fenwick point-add/range-sum algorithm; their APIs differed only in bounds/framing. | Duplicate removed: keep `fenwick_tree` canonical, remove the duplicate ports/workload/runner branch, and preserve the C# source as alternate provenance. |
| `point_set_range_composite` | `segment_tree` supports scalar sum/min/max aggregates, not ordered function composition. | Confirmed distinct: ten language drafts, workload, README, direct-scan oracle, package static checker, and scalar-suite registration are present. The large-array task remains the same algorithm family and does not receive a duplicate package. No program or test was run. |
| `point_set_range_composite_large_array` | Same point-set/range-composition operation as the preceding task, with a larger bound. | Alias the canonical `point_set_range_composite` profile unless a future implementation demonstrates materially different measured behavior. |
| `range_affine_point_get` | `segment_tree_apply` performs range multiplication and range-sum queries; it does not support general affine range updates with point observations. | Confirmed distinct Library Checker operation: ten language ports, bounded workload, direct-array oracle, package static checker, and byte-output suite registration are present. No runtime validation was performed. |
| `range_affine_range_sum` | Existing `lazy_segment_tree_range_add_sum` supports additive updates, not general affine transforms. | Confirmed distinct affine lazy-segment-tree operation: ten language ports, bounded workload, direct-array oracle, package static checker, and scalar suite registration are present. No runtime validation was performed. |
| `range_affine_range_sum_large_array` | Same affine-update/range-sum operation as the preceding task, with a larger bound. | Fold into one bounded affine lazy-segment-tree profile unless the source specifies a materially different algorithm. |
| `persistent_range_affine_range_sum` | `persistent_segment_tree` persists point assignments; `persistent_seg_tree_lazy_prop` persists additive range updates and sums. Neither supports branching historical affine updates, copying a range from another version, and querying sums on chosen versions. | Confirmed distinct: ten path-copying lazy segment-tree ports, direct and independent snapshot oracles, bounded workload/package checker, and byte-output suite registration are present. |
| `range_set_range_composite` | `point_set_range_composite` updates one function per operation; range assignment needs a lazy tag that represents repeated affine composition across a covered node. | Confirmed distinct: ten language ports, bounded workload, direct-array oracle, independent composition-scan verifier, package checker, and byte-output suite registration are present. No runtime validation was performed. |
| `range_chmin_chmax_add_range_sum` | `segment_tree_beats` implements range chmin, chmax, add, and range sum. | Covered. |
| `range_kth_smallest` | `wavelet_tree` provides range quantile (k-th value) along with rank and value-range counts. The persistent-segment-tree method builds path-copied prefix histograms and descends the difference of two roots; this is a different data structure and query traversal from the wavelet tree's stable value partitions. `persistent_segment_tree` itself persists point assignments for range sums, and `segment_tree_merge_split` destructively merges/splits mutable multisets; neither implements prefix-root difference selection. | The operation is already covered by `wavelet_tree`; the method-distinct `persistent_segment_tree_range_kth` is also implemented. Contract: scalar input `[N,Q,values[N],(L,R,K)*Q]`, `1<=N<=32`, `0<=Q<=32`, values in `[-1000,1000]`, inclusive zero-based `[L,R]`, and `1<=K<=R-L+1`; result is `sum((query_index+1)*answer)`, malformed sentinel `INT64_MIN`. Maximum valid/parseable input lengths are 130/131 i64 words; workspace is 4096 bytes and the persistent-node cap is 193. Ten ports, primary persistent-prefix-histogram oracle, independent direct-sort oracle, maximum and malformed workload, README/RIGHTS, static inventory checker, and `i64_array_scalar` runner/verifier registration are complete. Source: [CP-Algorithms, Segment Tree — finding the k-th smallest number in a range](https://cp-algorithms.com/data_structures/segment_tree.html), CC BY-SA 4.0; clean-room use of the algorithm description only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |
| [`point_set_range_sort_range_composite`](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/point_set_range_sort_range_composite/task.md) | `point_set_range_composite` handles point updates and ordered range composition; `range_set_range_composite` handles range assignment but has no sorting by per-item priority. Neither reorders affine-function records over a range before composition queries. | Confirmed distinct and implemented: ten language ports, bounded `N<=16`, `Q<=32` profile, list-simulation primary oracle, independent priority-ID/selection-sort oracle, workload including a 210-value maximum frame, and scalar-suite wiring. No programs, tests, builds, compilers, benchmarks, or checkers were run. |
| `range_reverse_range_sum` | `splay_tree` and `treap_unique_key_set` are key-ordered sets; neither exposes implicit-sequence reversal and range sum. | Confirmed distinct: ten implicit-treap ports, bounded workload, direct-list oracle, independent immutable-slice verifier, package checker, and byte-output suite registration are present. No runtime validation was performed. |
| `dynamic_sequence_range_affine_range_sum` | `range_reverse_range_sum` lacks insertion, deletion, and affine updates; `range_affine_range_sum` uses a fixed array and has no sequence edits. | Confirmed distinct; ten ports, direct-list and independent slice oracles, bounded workload, static package checker, and byte-output suite integration are complete. No programs or validation tools were run. |
| `range_linear_add_range_min` | No range-linear-update/range-min structure was found. | Confirmed distinct: ten square-root-decomposition ports with lazy block lines and lower hulls, bounded workload, direct-list oracle, package checker, and scalar suite registration are present. No runtime validation was performed. |
| `set_xor_min` | Local word trie stores strings, while XOR arithmetic helpers do not maintain an integer set for greedy minimum-XOR queries. | Confirmed distinct counted binary trie: ten language ports, bounded Python-set oracle, workload, and byte-output suite registration are present. |
| `line_add_get_min` | `li_chao_tree` supports online line insertion and minimum-at-coordinate queries. | Covered. |
| `segment_add_get_min` | Full-domain `li_chao_tree` does not restrict each line to a segment. | Confirmed distinct operation; ten language drafts, workload, README, direct-scan oracle, package-local verifier, and scalar-suite integration are present. The Mojo draft remains unverified; no runtime validation was performed. |
| `queue_operate_all_composite` | Existing queue packages expose FIFO operations but not an aggregate of ordered affine functions. | Confirmed distinct two-stack aggregate queue; ten language drafts, workload, README, direct-list oracle, package static checker, independent verifier oracle, and scalar-suite registration are present. The Mojo draft needs verification; no runtime validation was performed. |
| `deque_operate_all_composite` | Existing deque/queue packages do not expose both-end operations with aggregate composition. | Confirmed distinct two-ended affine-composition deque: ten language drafts, workload, direct-list oracle, package checker, independent verifier, and scalar-suite registration are present. The Mojo draft remains unverified. No runtime validation was performed. |
| `static_range_frequency` | `wavelet_tree` supports positional range counts over value intervals; `mos_algorithm` supports fixed-target frequency over arbitrary ranges. | Covered operationally by two materially different methods; retain those algorithm benchmarks and avoid a redundant frequency-only package absent a distinct method. |
| `static_range_count_distinct` | [`mos_algorithm`](m/mos_algorithm/README.md) supports range sums and fixed-target frequency, not distinct counting. An offline sweep by right endpoint keeps a Fenwick-tree marker at the latest occurrence of each value; its state and traversal differ from Mo ordering. | Distinct method reserved as `offline_range_distinct_fenwick`; see the reservation below. |
| `static_range_mode_query` | Whole-array `mode` and `wavelet_tree` do not provide arbitrary-subrange mode queries. | Confirmed distinct query; nine standard ports plus optional Mojo, workload, README, direct-scan oracle, package-local verifier, and byte-suite integration are complete. No runtime validation was performed. |
| `static_range_lis_query` | `longest_increasing_subsequence` computes one whole-array LIS length; it does not answer multiple subrange queries over a shared permutation. | Confirmed distinct bounded subarray query: ten ports, workload, tails-based primary oracle, independent quadratic-DP verifier, package metadata/source checker, and byte-output suite registration are present. The README identifies this as a bounded query baseline without claiming an optimized preprocessed range-LIS structure. No runtime validation was performed. |
| `static_range_inversions_query` | `inversions` and `count_inversions` count inversions over a whole input, not arbitrary subranges. `mos_algorithm` supports range sums and fixed-target frequencies, not order-pair counts. | Confirmed distinct bounded order-pair query: ten ports, workload, Mo/Fenwick primary oracle, independent direct pair-count verifier, package checker, and byte-output suite registration are present. No runtime validation was performed. |
| `point_set_range_frequency` | `wavelet_tree` is static and `frequency_count_list_update` reorders a list; neither supports point-set updates plus range frequency. | Confirmed distinct: ten ports, bounded workload, direct-array oracle, package checker, and byte-output suite registration are present. No runtime validation was performed. |
| `rectangle_sum` | `prefix_sum2_d` builds a summed-area table and answers an inclusive rectangle sum; `segment_tree2_d` handles dynamic point assignments and rectangle sums. | Covered at the static prefix-sum algorithm level; consider batching queries in the existing profile rather than adding the same summed-area algorithm again. |
| `point_add_rectangle_sum` | [`segment_tree2_d`](s/segment_tree2_d/README.md) uses point assignment on a bounded dense grid and nested segment trees; [`prefix_sum2_d`](p/prefix_sum2_d/README.md) is static. Neither handles online point additions over sparse 1e9-scale coordinates. | Confirmed distinct: ten ports use an offline coordinate-compressed 2D Fenwick-of-vectors for append-only weighted points and half-open rectangle sums, with direct point-scan oracle, bounded workload, and byte-output suite registration. |
| `rectangle_add_point_get` | No rectangle range-add/point-get data structure was found. | Confirmed distinct dynamic rectangle-add/point-get operation: ten language ports, workload, direct-scan oracle, package checker, independent direct-list suite oracle, and byte-output suite registration are present. No runtime validation was performed. |
| `static_rectangle_add_rectangle_sum` | Existing 2D prefix sums query a fixed matrix, while point-add/rectangle-sum and rectangle-add/point-get use different update/query pairs. | Confirmed distinct two-phase rectangle-add/rectangle-sum operation modulo 998244353: ten ports, workload, direct-overlap primary oracle, independent compressed-cell verifier, package metadata/source checker, and byte-output suite registration are present. No runtime validation was performed. |
| `dynamic_point_set_rectangle_affine_rectangle_sum` | `segment_tree2_d` uses dense-grid point assignment and rectangle sums; `point_add_rectangle_sum` is sparse append-only addition; neither supports appending points, assigning by point ID, and applying affine maps over spatial rectangles. | Confirmed distinct; ten kd-tree ports, direct-list oracle, bounded workload, static package checker, and byte-output suite registration are present. No programs or validation tools were run. |
| `area_of_union_of_rectangles` | `rectangle_union_area` computes union area. | Covered. |
| `persistent_queue` | `clojure_persistent_list_queue` implements FIFO behavior with an immutable-list representation but exposes no branching historical versions. | Confirmed distinct: ten persistent-segment-tree ports, bounded branching workload, copied-list oracle, package checker, and byte-output suite registration are present. No runtime validation was performed. |
| `persistent_unionfind` | Ordinary `union_find` processes one mutable history; persistent segment trees preserve values, not connectivity partitions. | Confirmed distinct versioned connectivity: ten language ports, explicit-graph-copy/BFS oracle, bounded workload, and byte-output suite registration are present. |

### Offline range-distinct Fenwick sweep (reserved 2026-11-13)

Owner: root. `offline_range_distinct_fenwick` answers static distinct-count queries by ordering them by right endpoint and maintaining a Fenwick tree of latest-occurrence markers. This differs from the window ordering in `mos_algorithm`; the latter currently lacks distinct-count queries altogether. `wavelet_tree` provides quantiles and frequency counts, not this operation. The [Library Checker task](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/static_range_count_distinct/task.md) identifies the operation; the [AtCoder editorial](https://atcoder.jp/contests/awc0122/editorial/22807?lang=ja) describes the sweep. Use mathematical ideas only, without reusing source text, code, or fixtures; the Library Checker problem repository is Apache-2.0. A bounded contract and two independently organized reference drafts are present. The ports bucket queries by right endpoint. No code has been run. Do not duplicate this reservation.

C3, Nim, Zig, Odin, V, and Mojo drafts are also present, for ten language drafts in total. A workload, rights note, package checker, and scalar runner/verifier registration are written. The verifier source specifies exhaustive small arrays and interval sets, maximum frames, and null inputs. All drafts and fixtures remain uncompiled and untested; source-level review remains outstanding.

The timed workload now also includes the maximum 194-word frame, with 64 full-range queries over distinct values; the package checker requires that case. This addition remains unexecuted.

The verifier source also specifies reverse query ordering and bijective value-renaming checks, to exercise original-index weighting and value-identity invariance. These checks have not run.

## Library Checker Convolution category crosswalk (first pass, 2026-10-29)

The official [`categories.toml`](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/categories.toml) lists 15 Convolution tasks. The current Judge also exposes `convolution_F_2_64` as a newer Convolution problem that is not yet listed in that file. This first pass compares category tasks and this newer judge entry with local README contracts and records likely coverage or candidate families. Before implementation, inspect each official task's exact algebra, input bounds, and intended algorithm; modulus-only variants should share a workload family unless the required multiplication method materially differs.

| Official task | Local comparison | First-pass disposition |
| --- | --- | --- |
| `convolution_mod` | `convolution` is direct exact-integer multiplication; `convolution_fft` is floating-point Cooley–Tukey; `number_theoretic_transform` emits a forward transform but does not multiply polynomials. | Confirmed distinct NTT-based polynomial product modulo 998244353. Bounded local lengths `1..=256` are implemented in ten ports with a direct `O(N*M)` oracle, workload, and byte-output suite probes; static review only. The official task requires `c[k]=sum(a[i]*b[j] where i+j=k)` and allows lengths through 524288. The 1,000,000,007 target uses auxiliary-prime CRT/NTT; the `2^64` profile uses unsigned word wraparound and a wider reconstruction method, so both remain separate algorithms. See the [task statement](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/convolution_mod/task.md) and [parameters](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/convolution_mod/info.toml). |
| `convolution_mod_1000000007` | `convolution_mod` computes modulo 998244353 using that target prime directly for its NTT. | Confirmed distinct auxiliary-prime CRT/NTT product modulo 1,000,000,007; ten clean-room ports, direct exact `O(N*M)` oracle, bounded `N,M<=64` workload, and `i64_array_bytes_output` suite wiring are present; static review only. Three NTT primes reconstruct every bounded unreduced coefficient exactly before target reduction. It is distinct from `convolution_mod_2_64`, whose output ring is wraparound modulo `2^64`. See the [official statement](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/convolution_mod_1000000007/task.md) and [parameters](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/convolution_mod_1000000007/info.toml). |
| `convolution_mod_2_64` | The `convolution_mod_1000000007` package computes residues over a prime field and uses three auxiliary NTT primes; it does not accept the full unsigned 64-bit coefficient ring or perform the wider exact reconstruction. | Materially distinct: output wraps modulo `2^64`, every signed ABI bit pattern represents a valid unsigned input word, and five-prime Garner reconstruction recovers each bounded exact coefficient before word wraparound. Ten clean-room ports, direct `O(N*M)` oracle, bounded `N,M<=64` workload, and strict byte-output suite integration are present; static review only. See the [official statement](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/convolution_mod_2_64/task.md) and [parameters](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/convolution_mod_2_64/info.toml). |
| `convolution_mod_large` | Existing linear convolution profiles cap both inputs at 64 values. | Larger input limit alone does not justify a second benchmark; fold into the canonical modular convolution if the algorithm is the same. |
| `bitwise_and_convolution` | `fast_walsh_hadamard_transform` implements the XOR forward/inverse transform only, not AND convolution. | Confirmed distinct; bounded `N<=8` clean-room superset-zeta/Möbius ports, direct oracle, strict workload validation, dense/sparse maximum-size and malformed/null/capacity verifier probes, and byte-output suite integration are present; static review only. Official contract: `c[k]=sum(a[i]*b[j] where (i & j)=k) mod 998244353`, with `N<=20`; see the [task statement](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/bitwise_and_convolution/task.md) and [parameters](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/bitwise_and_convolution/info.toml). |
| `bitwise_xor_convolution` | `fast_walsh_hadamard_transform` implements the XOR transform and inverse, but does not multiply transformed coefficient arrays. | Confirmed distinct: ten ports compute XOR-indexed convolution with two forward transforms, pointwise multiplication, inverse normalization, direct pair-enumeration and independent per-output oracles, a bounded workload, and byte-output suite registration. See the [official task](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/bitwise_xor_convolution/task.md) and [limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/bitwise_xor_convolution/info.toml). |
| `bitwise_or_convolution` | The existing bitwise AND and XOR convolutions combine coefficients under different index operations; subset convolution also adds a disjointness constraint that this union product does not use. | Confirmed distinct: ten clean-room ports use subset zeta transforms, pointwise multiplication, and Möbius inversion, with direct pair and independent per-output oracles, a bounded workload, rights notes, and byte-output suite registration. It is sourced from a general algorithm reference, not a Library Checker task. See [convolution variants](https://neelmishra.github.io/blog/cp/algebra/convolution-variants.html). |
| `gcd_convolution` | No divisor-zeta / Möbius convolution package was found. Ordinary GCD and divisor-sum routines do not compute pair-indexed convolution. | Confirmed distinct divisor-zeta/Möbius convolution; ten clean-room ports, direct O(N²) oracle, bounded `N<=128` workload, strict byte-output suite integration, and README are present; static review only. Official contract: `c[k]=sum(a[i]*b[j] where gcd(i,j)=k) mod 998244353`, with `N<=1,000,000`. See the [task statement](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/gcd_convolution/task.md) and [parameters](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/gcd_convolution/info.toml). |
| `lcm_convolution` | Existing [`gcd_convolution`](g/gcd_convolution/README.md) groups pair products by exact gcd with divisor zeta and reverse Möbius traversal; scalar `lcm_sum` computes a different single-argument totient identity. | Confirmed distinct dual divisor-lattice convolution: `c[k]=sum(a[i]*b[j] where lcm(i,j)=k)`; ten clean-room ports, direct O(N²) oracle, bounded `N<=128` workload, strict byte-output suite integration, and README are present; static review only. Official task: [Library Checker LCM convolution](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/lcm_convolution/task.md) and [limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/lcm_convolution/info.toml). |
| `multivariate_convolution` | Existing one-dimensional convolution and fast subset convolution do not implement truncated multi-index polynomial multiplication. | Confirmed distinct: ten ports, bounded direct pair enumeration, an independent output-index oracle, a workload, and byte-output suite registration are present. The cyclic task remains separate because it wraps each coordinate instead of truncating. See the [official task](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/multivariate_convolution/task.md) and [limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/multivariate_convolution/info.toml). |
| `multivariate_convolution_cyclic` | Truncated multiplication discards terms beyond per-axis degree limits; this task instead multiplies modulo `(1-x_i^{N_i})`, wraps every coordinate, and requires each `N_i` to divide `p-1` over an input prime field. | Confirmed algorithmically distinct: ten ports, bounded direct pair enumeration, an independent output-index oracle, a workload, and byte-output suite registration are present. See the [official task](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/multivariate_convolution_cyclic/task.md) and [limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/multivariate_convolution_cyclic/info.toml). |
| `mul_modp_convolution` | No convolution over the multiplicative monoid of Z/PZ was found; coefficient convolution modulo P uses addition of indices instead of multiplication. | Confirmed distinct: ten ports use primitive-root coordinates for the nonzero residues and bounded cyclic convolution, handling zero separately; the independent oracle enumerates residue pairs directly. Workload, README, rights note, package checker, and byte-output runner/verifier registration are present. No executable checks were run. See the [official task](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/mul_modp_convolution/task.md) and [limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/mul_modp_convolution/info.toml). |
| `mul_mod2n_convolution` | The prime-modulus multiplicative convolution has a cyclic group of nonzero residues; modulo `2^N`, nonunits and zero divisors create a different multiplicative structure. | Confirmed distinct: ten ports enumerate residue pairs in bounded `Z/2^N Z` for `N<=5`, with independent direct oracles, workload, README, rights note, package checker, and byte-output runner/verifier registration. No executable checks were run. See the [official task](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/mul_mod2n_convolution/task.md) and [limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/mul_mod2n_convolution/info.toml). |
| `min_plus_convolution_convex_arbitrary` | [`min_plus_distance_product`](m/min_plus_distance_product/README.md) and [`apsp_min_plus_repeated_squaring`](a/apsp_min_plus_repeated_squaring/README.md) operate on matrices, not one-dimensional sequences. | Implemented and registered in the byte suite: ten ports use monotone divide-and-conquer minima for the bounded 1-D convex/arbitrary profile, with a direct oracle and an independent direct-scan verifier. Concave/arbitrary uses a separate staircase-aware method. |
| `min_plus_convolution_convex_convex` | The convex/arbitrary profile also accepts convex/convex inputs, but it uses monotone divide-and-conquer minima rather than merging the discrete slopes. | Confirmed algorithmically distinct: ten ports use the `O(N+M)` merge of nondecreasing first-difference sequences; a direct `O(NM)` oracle, independent slope-merge checker, workload, README, rights note, package checker, and byte-suite registration are present. See the [official Library Checker task](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/min_plus_convolution_convex_convex/task.md) and [AtCoder Algorithm Lectures explanation](https://info.atcoder.jp/entry/algorithm_lectures/min_plus_convolution). |
| `min_plus_convolution_concave_arbitrary` | The convex/arbitrary one-dimensional row-minimum recursion does not cover this case: clipping the feasible indices to the convolution staircase can make minima increase (for example N=1 forces j=k). | Implemented and registered in the byte suite: ten ports use a staircase-aware rectangle decomposition, monotone minima on fully feasible blocks, and bounded direct scans around staircase boundaries. An independent brute-force verifier, workload, README, and rights note are present. |
| [`convolution_F_2_64`](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/convolution_F_2_64/task.md) (new Judge entry) | [`convolution_mod_2_64`](c/convolution_mod_2_64/README.md) computes in `Z/(2^64)` with ordinary integer multiplication and carry; [`nim_product_64`](n/nim_product_64/README.md) uses recursive nimber multiplication. Neither computes carryless polynomial multiplication reduced by the fixed irreducible polynomial `x^64+x^4+x^3+x+1`, nor XOR-adds those field products by convolution index. | Implemented and registered as `convolution_f2_64` in all ten languages: local bounded schoolbook convolution over `GF(2^64)` (`1<=N,M<=8`), with all signed-i64 bit patterns interpreted as unsigned field elements and little-endian u64 output bytes. Primary uses 64-step shift/reduce field multiplication; independent oracle forms unreduced carryless polynomial products and reduces them by polynomial long division. Workload, README/RIGHTS, and static package inventory checker are complete. Official limits allow `N,M<=524288`; this local profile is a small algorithm benchmark. The upstream repository is Apache-2.0; use task mathematics and bounds only, with clean-room code and fixtures. Static source review only; no programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## Library Checker Number Theory category crosswalk (first pass, 2026-10-29)

The official [`categories.toml`](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/categories.toml) lists 22 Number Theory tasks. This first pass checks local package names and README descriptions; tasks with a related family are marked for contract-level review rather than assumed covered.

| Official task | Local comparison | First-pass disposition |
| --- | --- | --- |
| `enumerate_quotients` | No package enumerating distinct floor quotients was found. | Confirmed distinct and implemented as a bounded quotient-block enumeration; the scalar byte-output suite includes fixture, range, random, capacity, and null-output cases. |
| `primality_test` | `prime_check`, `prime_check_naive`, `miller_rabin_primality_checker`, and `fermat_prime_checker` cover deterministic trial, probable-prime, and Fermat-style tests. | Covered by distinct primality-test algorithms; compare supported number ranges and pseudoprime handling before adding another profile. |
| `counting_primes` | `prime_pi_sequence` returns π(x) by incrementally trial-dividing through 1000; `meissel_lehmer_prime_count` returns the same function through 10^8 using Lehmer's formula and recursive φ plus prime/semiprime corrections; sieve packages enumerate primes directly. These provide the same operation but use materially different methods. | Implemented and scalar-suite registered as [`legendre_prime_count`](l/legendre_prime_count/README.md): returns π(x) for 0<=x<=10000 using Legendre's formula π(x)=φ(x,π(√x))+π(√x)−1, where φ is evaluated by recursive inclusion-exclusion over the first π(√x) primes. This is method-distinct from the Lehmer correction formula and direct sieves; the bounds keep the subset recurrence practical. Ten ports, Legendre primary oracle, independent direct-sieve oracle, boundary workload, provenance/rights, and package-local static inventory checker are present. Official task operation and bound are count primes <=N for 1<=N<=10^11; the package uses a bounded subrange. See [Library Checker](https://judge.yosupo.jp/problem/counting_primes) and [MathWorld, Legendre's Formula](https://mathworld.wolfram.com/LegendresFormula.html). No programs, tests, scripts, checkers, builds, compilers, or benchmarks were run. |
| `enumerate_primes` | [`prime_numbers`](p/prime_numbers/README.md) is canonical for candidate-by-candidate trial division. The TypeScript/Zig first-N generators and Python `get_primes_between` scan use the same primality-by-trial-division core; their count/range endpoints are contract profiles, not distinct algorithms. `primes_sequence` deliberately tests each candidate against all prior primes and remains distinct. | Duplicate packages `first_n_primes` and `get_primes_between` were removed and their sources mapped to `prime_numbers`; retain `primes_sequence` for its distinct all-prior-primes test. |
| `factorize` | `factorize`, `prime_factorization`, `trial_division_factorizer`, `pollards_rho_factorizing`, and `prime_factorization_sieve` provide factorization families. Their Pollard-rho variants use Floyd or Brent cycle search; none uses the smooth-order exponentiation criterion of Pollard p−1. | Trial division, sieve, and rho methods remain covered. Reserved the distinct [`pollard_p_minus_one_factorization`](p/pollard_p_minus_one_factorization/README.md) stage-1 method below. |
| `primitive_root` | `primitive_root` already computes a primitive root under its bounded prime-modulus contract. | Covered. |
| `sum_of_floor_of_linear` | No floor-sum package was found by the path/README search. | Confirmed distinct and implemented with the logarithmic Euclidean floor-sum recurrence; the scalar suite covers direct/recursive boundary cases and malformed input. |
| `min_of_mod_of_linear` | No minimum of a linear modular sequence package was found; `sum_of_floor_of_linear` computes a different sum. | Confirmed distinct; bounded search uses Euclidean floor sums and has workload fixtures plus deterministic boundary/random verifier inputs. |
| `rational_approximation` | [`farey_approximation`](f/farey_approximation/README.md) follows fixed one-step mediants for a decimal, and [`continued_fraction`](c/continued_fraction/README.md) serializes exact coefficients; neither returns both bounded-component neighbors. | Confirmed distinct quotient-jumped Stern–Brocot search: nine standard ports plus optional Mojo, an exact continued-fraction oracle, bounded workload, and byte-output verifier corpus are registered. |
| `stern_brocot_tree` | The existing `farey_approximation` package searches for a rational approximation and does not expose path, LCA, ancestor, or neighbor-interval operations. | Confirmed distinct; all five query operations have a bounded batch workload, oracle, ten port drafts, and byte-suite corpus coverage. The Mojo draft remains unverified. |
| `counting_squarefrees` | `is_square_free` tests one integer but does not count square-free values in a prefix. | Confirmed distinct: Möbius inversion counts positive square-free values through a bounded `N <= 10^12`; ten source drafts, scalar workload, and verifier corpus are registered. The Mojo draft has not been executed in this review. |
| `sum_of_totient_function` | `problem72` sums a directly sieved totient prefix only through 1,000,000; it does not use quotient grouping to extend the sum to larger values. `euler_totient` and `totients_linear_sieve` compute individual values or a sequence. | Confirmed distinct quotient-block summatory method: nine standard ports, optional Mojo, independent modular oracle, workload, and scalar-suite registration cover `1 <= N <= 10^9`. |
| `sum_of_multiplicative_function_large` | `lcm_sum` and divisor/totient packages cover specific sums, but no general large-n summatory multiplicative-function algorithm was found. | Confirmed distinct Min_25 sieve: for `f(p^e)=a*e+b*p`, nine standard ports plus optional Mojo, a bounded direct prime-power oracle, workload fixtures, and `i64_array_scalar` validation cover `N <= 10^8`. |
| `bernoulli_number` | Local `power_sum` and Bernoulli-rounding packages compute different quantities; the official modular task uses `B_1=-1/2`. | Confirmed distinct: exact-rational oracle, ten source drafts, bounded `N <= 32` recurrence, workload, and byte-output suite registration are present. |
| `sqrt_mod` | The official operation returns a modular square root or reports a non-residue; local `tonelli_shanks` already computes that result and chooses the smaller valid root. | Algorithm duplicate: keep `tonelli_shanks` canonical; its current profile has a narrower prime bound and excludes `P=2`, which are domain differences rather than a new algorithm. |
| `kth_root_mod` | `tonelli_shanks` solves only the K=2 case; primitive-root and discrete-log packages expose needed primitives but do not extract an arbitrary-K root. | Confirmed distinct prime-field extraction via a discrete logarithm and a linear congruence: nine standard ports plus Mojo, bounded workload, independent oracle, and byte-output corpus are registered. |
| `kth_root_integer` | `square_root_binary_search` and `newton_square_root` cover degree 2; approximate `nth_root` and geometric-mean routines do not match exact floor semantics for arbitrary K. The official task accepts unsigned 64-bit A and 1<=K<=64. | Confirmed distinct with a bounded signed-i64 contract: ten source drafts, arbitrary-precision oracle, boundary workload, and `i64_array_scalar` suite registration. |
| `discrete_logarithm_mod` | `baby_step_giant_step` handles only coprime base/modulus pairs and returns a least positive exponent; it does not perform repeated gcd reduction or return `k=0` for the minimum nonnegative solution. | Confirmed distinct generalized EBSGS: repeated gcd stripping plus coprime BSGS, with nine standard ports, optional Mojo, direct power-enumeration oracle, bounded workload, and `i64_array_scalar` suite corpus. |
| `tetration_mod` | [`problem188`](p/problem188/README.md) is a source-pinned Project Euler replay whose modulus is `10^digits` and whose height-one behavior returns the unmodded base; it does not implement a general-modulus tower contract. | Confirmed distinct generalized tetration: totient lifting with capped tower detection supports any bounded modulus, non-coprime bases, height zero, and `0^0=1`; nine standard ports, optional Mojo, oracle, workload, and `i64_array_scalar` suite corpus are registered. |
| `gcd_of_gaussian_integers` | No local Gaussian-integer GCD was found. Gaussian mixture/normal distribution, Gaussian elimination, and sums-of-squares routines use different number systems or operations. | Confirmed distinct Euclidean algorithm over `Z[i]`, with nearest-coordinate quotient rounding and canonical associates: nine standard ports, optional Mojo, oracle, bounded workload, and byte-output suite integration are registered. |
| `two_square_sum` | `pythagoras` computes a distance, and `pythagorean_triple` solves for a hypotenuse; neither enumerates representations of a supplied integer. | Confirmed distinct and implemented as bounded direct coordinate enumeration (`Q <= 8`, `N <= 10,000`): nine standard ports, optional Mojo, workload, independent integer-square-root oracle, and byte-output suite corpus are registered. |
| `nim_product_64` | No nim-product package was found; ordinary XOR, carryless polynomial multiplication, and finite-field routines do not implement the recursive nimber product. | Confirmed distinct: recursive nimber field-extension multiplication covers unsigned 64-bit operands via four-u32-limb input and an eight-byte result, with nine standard ports, optional Mojo, oracle, workload, and byte-output corpus. |

## Library Checker Linear Algebra category crosswalk (first pass, 2026-10-29)

The official [`categories.toml`](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/categories.toml) lists 17 Linear Algebra tasks. This first pass checks package paths and README contracts against each task's operation. The official task pages describe the arithmetic domains; domain-specific profiles are kept distinct only when the field operations, representation, or required output materially change the computation. This is a discovery crosswalk, not a claim that all upstream bounds are supported locally.

| Official task | Local comparison | First-pass disposition |
| --- | --- | --- |
| [`matrix_product`](https://judge.yosupo.jp/problem/matrix_product) | [`matrix_multiplication`](m/matrix_multiplication/README.md) uses the classical row-by-column product; [`strassen_matrix_multiplication`](s/strassen_matrix_multiplication/README.md) is a separate seven-product method. | Already represented by classical and Strassen multiplication. Do not add another classical product solely for rectangular dimensions or a modular output profile. |
| [`matrix_product_mod_2`](https://judge.yosupo.jp/problem/matrix_product_mod_2) | Existing classical, Strassen, and min-plus products use different arithmetic domains and representations. | Confirmed distinct: ten ports pack right-hand rows into bit words and XOR the selected rows; a scalar GF(2) oracle, bounded workload, and byte-output suite registration are present. |
| [`pow_of_matrix`](https://judge.yosupo.jp/problem/pow_of_matrix) | [`matrix_exponentiation`](m/matrix_exponentiation/README.md) raises a recurrence companion matrix using classical multiplication and exponentiation by squaring. | Duplicate algorithm: general matrix input broadens the contract but uses the same multiply-and-square kernel; no separate package planned. |
| [`matrix_det`](https://judge.yosupo.jp/problem/matrix_det) | [`determinant`](d/determinant/README.md) uses recursive cofactor expansion; the directed and undirected spanning-tree packages also compute determinants by modular Gaussian elimination as internal kernels. | Determinant computation is already represented by materially different cofactor and elimination methods. Treat the task as covered at the algorithm level; do not add another package that only renames the same modular elimination kernel. |
| [`matrix_det_arbitrary_mod`](https://judge.yosupo.jp/problem/matrix_det_arbitrary_mod) | No general arbitrary-composite-modulus determinant package was found. Current modular determinant kernels use a prime field, where nonzero pivots can be inverted. | Confirmed distinct: ten ports use Euclidean row-pair transformations without pivot division, with a cofactor-expansion oracle, bounded workload, and byte-output suite registration. |
| [`matrix_det_mod_2`](https://judge.yosupo.jp/problem/matrix_det_mod_2) | No bit-packed GF(2) determinant package was found; the existing binary-input rank package uses floating-point elimination over the reals. | Confirmed distinct: ten ports use packed XOR elimination, with a scalar Boolean-elimination oracle, bounded workload, and byte-output suite integration. |
| [`sparse_matrix_det`](https://judge.yosupo.jp/problem/sparse_matrix_det) | [`sparse_matrix`](s/sparse_matrix/README.md) only classifies density; generic determinant packages take dense matrices, and no sparse determinant solver was found. | Confirmed distinct: ten ports use sparse Wiedemann/Krylov projections, Berlekamp–Massey, seeded retries, and a bounded exact fallback, with a cofactor oracle, workload, and byte-output suite integration. |
| [`matrix_rank`](https://judge.yosupo.jp/problem/matrix_rank) | [`matrix_rank`](m/matrix_rank/README.md) computes rank by Gaussian elimination; the official task changes the arithmetic field and supported scale. | Same algorithm family: finite-field Gaussian elimination changes arithmetic but adds no new rank algorithm, so do not duplicate it under the current algorithm-level rule. |
| [`matrix_rank_mod_2`](https://judge.yosupo.jp/problem/matrix_rank_mod_2) | `matrix_det_mod_2` already performs the same packed XOR Gaussian elimination and counts pivot rows; the determinant is simply the full-rank predicate. | Duplicate algorithm: do not add a second package for the rank output; it is directly available from the determinant port's pivot count. |
| [`system_of_linear_equations`](https://judge.yosupo.jp/problem/system_of_linear_equations) | Real-valued elimination packages solve the same linear-system problem; `system_of_linear_equations_mod_2` already returns consistency, a particular solution, and a nullspace basis using Gaussian elimination over GF(2). | Duplicate algorithm family: changing GF(2) arithmetic to a general prime field does not add a distinct solving algorithm under the current algorithm-level rule; keep the existing packed GF(2) solver canonical rather than adding a field-only alias. |
| [`system_of_linear_equations_mod_2`](https://judge.yosupo.jp/problem/system_of_linear_equations_mod_2) | `matrix_det_mod_2` returns only the determinant/full-rank bit, while this solver returns consistency, a particular solution, and a nullspace basis. | Confirmed distinct: ten ports use packed XOR elimination on rectangular augmented systems; scalar Boolean oracle, bounded workload, and byte-output suite integration are complete. |
| [`inverse_matrix`](https://judge.yosupo.jp/problem/inverse_matrix) | [`gauss_jordan`](g/gauss_jordan/README.md) already performs pivoting, row normalization, and elimination above and below each pivot; `inverse_of_matrix` also exposes an inverse operation with different methods. | Covered by the existing Gauss–Jordan elimination family; finite-field arithmetic and returning the inverse instead of the reduced matrix change the domain/output, not the core algorithm. Do not create a duplicate package unless a materially different inversion method is selected. See the [official task](https://github.com/yosupo06/library-checker-problems/blob/master/linear_algebra/inverse_matrix/task.md) and [bounds](https://github.com/yosupo06/library-checker-problems/blob/master/linear_algebra/inverse_matrix/info.toml). |
| [`inverse_matrix_mod_2`](https://judge.yosupo.jp/problem/inverse_matrix_mod_2) | [`matrix_det_mod_2`](m/matrix_det_mod_2/README.md) uses bit-packed GF(2) pivoting and XOR elimination; [`gauss_jordan`](g/gauss_jordan/README.md) performs full elimination above and below pivots. | Covered by the existing GF(2) elimination and Gauss–Jordan families; the inverse output alone does not establish a new elimination algorithm. Do not create a separate package absent a materially different method. See the [official task](https://github.com/yosupo06/library-checker-problems/blob/master/linear_algebra/inverse_matrix_mod_2/task.md) and [bounds](https://github.com/yosupo06/library-checker-problems/blob/master/linear_algebra/inverse_matrix_mod_2/info.toml). |
| [`adjugate_matrix`](https://judge.yosupo.jp/problem/adjugate_matrix) | No adjugate/cofactor-matrix package was found; determinant and inverse packages return different outputs and the inverse does not define singular inputs. | Confirmed distinct: ten ports compute every modular cofactor with subset determinant DP, including singular inputs; a recursive exact-minor oracle, bounded workload, and byte-output suite integration are complete. |
| [`characteristic_polynomial`](https://judge.yosupo.jp/problem/characteristic_polynomial) | [`similar_matrices`](s/similar_matrices/README.md) computes small exact characteristic-polynomial data internally for classification, but does not expose polynomial coefficients as an operation. | Confirmed distinct: ten clean-room ports use upper-Hessenberg similarity reduction plus coefficient recurrence, with a bounded permutation-expansion oracle, workload, and byte-output suite integration. |
| [`hafnian_of_matrix`](https://judge.yosupo.jp/problem/hafnian_of_matrix) | No hafnian or weighted perfect-matching sum for symmetric matrices was found; maximum-cardinality matching and determinant packages return different quantities. | Confirmed distinct: ten language ports use subset DP for even-order symmetric zero-diagonal matrices, with a bounded oracle, workload, and byte-output suite integration. |
| [`intersection_of_f2_vector_spaces`](https://judge.yosupo.jp/problem/intersection_of_f2_vector_spaces) | No algorithm for producing a basis of the intersection of two XOR-spanned vector spaces was found. | Confirmed distinct: ten ports reduce quotient-space dependencies with coefficient masks and emit canonical RREF; an independent span-enumeration oracle, bounded workload, and byte-output suite integration are complete. |

## Library Checker Graph category crosswalk (2026-10-29)

This table compares every problem slug in the official [`categories.toml`](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/categories.toml) Graph list against local package names and the linked package contracts. “Covered” means the algorithmic operation is already represented; it does not certify the whole upstream input scale or suite workload. Rows marked “candidate” still need a fuller local-content comparison before implementation.

| Official problem | Local comparison | Decision / next action |
| --- | --- | --- |
| `cycle_detection` | [`check_cycle`](c/check_cycle/README.md) is the canonical directed three-state DFS profile; the Go `HasCycle` and C++ `isCyclicDFS` candidates alias it. [`cycle_check_directed_graph_kahn`](c/cycle_check_directed_graph_kahn/README.md) retains the distinct Kahn zero-indegree algorithm. | Covered by canonical DFS and Kahn variants. The common DFS profile accepts duplicate edges and bounds graphs to 32 vertices; the deleted 64-vertex DFS wrapper added no algorithmic distinction. |
| `cycle_detection_undirected` | [`undirected_cycle_check`](u/undirected_cycle_check/README.md) implements undirected cycle detection with parent-edge handling. [`check_cycle`](c/check_cycle/README.md) is directed and is not an equivalent replacement. | Covered by the separate undirected traversal profile; keep directed and undirected cycle semantics distinct. |
| `shortest_path` | The repository has single-source, all-pairs, constrained, negative-edge, and specialized shortest-path packages. | Covered as a family; no generic duplicate should be added without a distinct algorithm or contract. |
| `scc` | Static SCC packages include [`tarjan_scc`](t/tarjan_scc/README.md), [`kosaraju`](k/kosaraju/README.md), and [`gabow_scc`](g/gabow_scc/README.md); incremental SCC has its own insertion-only contract. | The separate Gabow profile has ten language drafts and suite wiring, in addition to Tarjan and Kosaraju. These are materially distinct DFS methods; the drafts remain unverified. |
| `incremental_scc` | [`incremental_scc`](i/incremental_scc/README.md) maintains SCC counts after each inserted arc. | Confirmed distinct from static SCC packages; ten language drafts, independent prefix-recomputation oracle, bounded workload, and scalar-suite maximum/random/malformed input coverage are present. The Mojo draft remains unverified; no runtime validation was run. |
| `k_shortest_walk` | [`yens_kshortest_paths`](y/yens_kshortest_paths/README.md) enumerates loopless paths, which cannot repeat vertices; [`k_shortest_walk`](k/k_shortest_walk/README.md) permits repeated vertices and edges and counts parallel arcs separately. | Confirmed distinct; ten language drafts, README/workload, independent exact-length DP oracle and static checker, byte-suite registration, and independent suite oracle are present. No runtime validation was run. |
| `two_edge_connected_components` | [`bridges`](b/bridges/README.md) returns cut edges, and [`two_edge_connected_spanning_subgraph_greedy`](t/two_edge_connected_spanning_subgraph_greedy/README.md) returns a minimal edge-connected subgraph; neither returns 2-edge-connected component classes. | Confirmed distinct: ten ports use edge-ID low-link bridge detection followed by component flooding; a brute-force edge-removal oracle, multigraph workload, and byte-suite registration are present. |
| `three_edge_connected_components` | [`three_edge_connected_components`](t/three_edge_connected_components/README.md) computes classes surviving removal of up to two edge IDs. | Ten language drafts and scalar-suite integration are present; the Mojo draft remains unverified. |
| `biconnected_components` | `gbbs_biconnectivity` uses Tarjan–Vishkin edge labels on a simple-graph profile; `bridges` and `articulation_points` return only cut sets. | Confirmed distinct: classical DFS low-link plus edge-ID stack returns maximal vertex blocks, handles parallel edges and isolated vertices, and has ten ports with bounded oracle, workload, and byte-suite registration. |
| `connected_components_of_complement_graph` | Local component packages operate on the supplied graph itself. | Confirmed distinct implicit-complement traversal: ten language ports, direct complement-BFS oracle, canonical bounded workload, and byte-output suite registration are present. |
| `eulerian_trail_directed` | [`eulerian_path`](e/eulerian_path/README.md) and the former `hierholzer_eulerian_path` package both implement directed Hierholzer traversal. | Duplicate removed: retain `eulerian_path` as the canonical benchmark with the wider bounds and normalized vertex-sequence output; preserve the Java implementation as an alternate provenance reference. |
| `eulerian_trail_undirected` | [`eulerian_trail_undirected_simple`](e/eulerian_trail_undirected_simple/README.md) is canonical for undirected Hierholzer traversal, returning the full route and supporting open trails. The Java multigraph-circuit source is mapped to the same algorithm family. | The duplicate `hierholzer_algorithm` package was removed. The canonical contract remains simple-graph-only; Java parallel-edge/self-loop behavior and hashed circuit output are source-profile differences, not a second traversal algorithm. |
| `st_numbering` | [`st_numbering`](s/st_numbering/README.md) implements Even–Tarjan numbering, and the byte-suite checker validates the certificate independently. | Ten language drafts, bounded workload, package oracle, byte-suite registration, and independent certificate validation are present; the Mojo draft remains unverified. No runtime validation was run. |
| `min_cost_b_flow` | [`min_cost_max_flow`](m/min_cost_max_flow/README.md) handles a source/sink flow limit and nonnegative forward costs; it does not support arbitrary vertex balances, signed lower bounds, negative costs, or circulation optimization. | Confirmed distinct general b-flow: ten language ports, bounded primal/dual certificate workload, independent feasible-flow/certificate oracle, and byte-output suite registration are present. |
| `bipartitematching` | [`hopcroft_karp_cardinality`](h/hopcroft_karp_cardinality/README.md) and [`bipartite_matching_kuhn`](b/bipartite_matching_kuhn/README.md) implement Hopcroft–Karp and Kuhn augmenting paths. | Covered; retain these materially different matching algorithms. |
| `general_matching` | [`edmonds_blossom_algorithm`](e/edmonds_blossom_algorithm/README.md) handles non-bipartite maximum-cardinality matching. | Covered. |
| `general_weighted_matching` | Local `edmonds_blossom_algorithm` maximizes cardinality, while stable/popular matching uses preference models. | Confirmed distinct maximum-total-weight general-graph matching: ten ports use bounded N<=16 bitmask DP with a deterministic certificate, a bottom-up DP oracle, recursive exhaustive checker, workload, README, rights note, static package checker, and byte-output runner/verifier registration. This does not claim the official N<=500 weighted-blossom scale. No executable checks were run. See the [official task](https://github.com/yosupo06/library-checker-problems/blob/master/graph/general_weighted_matching/task.md) and [limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/general_weighted_matching/info.toml). |
| `bipartite_edge_coloring` | Local Hopcroft–Karp and Kuhn packages produce one vertex matching; vertex-coloring packages color vertices rather than all bipartite edges. | Confirmed distinct: ten language ports, bounded deterministic matching workload, independent coloring oracle, and byte-output suite registration are present. |
| `assignment` | [`hungarian_algorithm`](h/hungarian_algorithm/README.md) implements minimum-cost rectangular assignment; [`assignment_using_bitmask`](a/assignment_using_bitmask/README.md) is a separate subset-DP algorithm. | Covered; retain the Hungarian and bitmask algorithms as distinct implementations. |
| `minimum_spanning_tree` | Kruskal/Prim-style packages and [`boruvkas_minimum_spanning_tree`](b/boruvkas_minimum_spanning_tree/README.md) provide explicit-edge MST algorithms. | Covered; Borůvka is a distinct algorithm from edge-sorting and cut-growth variants. |
| `directedmst` | [`edmonds`](e/edmonds/README.md) implements Chu–Liu/Edmonds rooted minimum arborescence. | Covered. |
| `minimum_diameter_spanning_tree` | MST weight minimization and ordinary tree-diameter packages do not optimize the diameter of the selected spanning tree. | Confirmed distinct combined optimization problem; ten ports, a bounded center-enumeration oracle, exhaustive certificate checker, workload, and byte-output suite registration are present. |
| `dominatortree` | [`dominator_tree`](d/dominator_tree/README.md) computes immediate dominators for a directed flow graph. | Ten language drafts and byte-suite integration are present; the Mojo draft remains unverified. |
| `maximum_independent_set` | [`list_ranking_independent_set_contraction`](l/list_ranking_independent_set_contraction/README.md) selects independent positions on list paths; the local clique packages enumerate maximal/all cliques and do not optimize a graph's independent-set cardinality. | Confirmed distinct; ten ports, a branch-and-bound oracle, an independent subset-enumeration fixture oracle, bounded workload, package static checker, and scalar-suite registration are present. No programs or validation tools were run. Source: [Encyclopedia of Algorithms chapter 514](https://doi.org/10.1007/978-1-4939-2864-4_514). |
| `chromatic_number` | [`exact_graph_coloring_inclusion_exclusion`](e/exact_graph_coloring_inclusion_exclusion/README.md) computes the chromatic number using subset counts and inclusion–exclusion. | Covered by a materially distinct exact algorithm; other greedy/backtracking coloring profiles remain separate. |
| `chromatic_polynomial` | Exact chromatic number and graph-coloring assignments do not return the polynomial coefficients. | Confirmed distinct from chromatic-number-only inclusion–exclusion: ten deletion–contraction ports, an independent spanning-subgraph inclusion–exclusion oracle, bounded workload, and byte-output suite registration are present. |
| `enumerate_triangles` | The official task returns the sum of `x_a*x_b*x_c` over all triangles modulo its prime; it does not emit triples. [`gapbs_ordered_triangle_count`](t/gapbs_ordered_triangle_count/README.md) already enumerates every unordered triangle once through ordered-neighbor intersections. | Covered by the existing exact triangle-enumeration algorithm: accumulating the vertex product during the same intersection traversal changes the aggregate, not the algorithm. No duplicate package is needed. [Official task](https://github.com/yosupo06/library-checker-problems/blob/master/graph/enumerate_triangles/task.md). |
| `enumerate_cliques` | [`clique_reverse_search_enumeration`](r/clique_reverse_search_enumeration/README.md) emits every clique, including nonmaximal cliques; [`bron_kerbosch`](b/bron_kerbosch/README.md) emits maximal cliques. | Covered; these enumeration targets are distinct and should not be collapsed. |
| `counting_c4` | Triangle and fixed four-clique counters return aggregate counts for different subgraphs; no per-edge C4 counter was found. | Confirmed distinct per-edge multigraph count: ten language ports, edge-subset oracle, bounded workload, and byte-output suite registration are present. |
| `tree_decomposition_width_2` | [`treewidth_exact_elimination_order`](t/treewidth_exact_elimination_order/README.md) returns an optimal elimination order for small graphs, while greedy treewidth packages return heuristics; neither constructs a width-2 tree-decomposition certificate. | Confirmed distinct: ten ports use degree-at-most-two elimination with fill edges and return a certificate; independent bitset and certificate checks, a bounded workload, and byte-output suite registration are present. See the [official task](https://github.com/yosupo06/library-checker-problems/blob/master/graph/tree_decomposition_width_2/task.md) and [limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/tree_decomposition_width_2/info.toml). |
| `global_minimum_cut_of_dynamic_star_augmented_graph` | [`gomory_hu_tree`](g/gomory_hu_tree/README.md) constructs all-pairs min-cut values for a static undirected graph; it does not model updates to supernode-star edges or emit one global min-cut after each update. | Confirmed distinct: ten ports recompute each bounded update with Stoer–Wagner; an exhaustive cut oracle, corrected workload, and byte-output suite registration are present. Local bounds are `N<=16`, `M<=64`, `Q<=32` and do not claim official dynamic scale. See the [official task](https://github.com/yosupo06/library-checker-problems/blob/master/graph/global_minimum_cut_of_dynamic_star_augmented_graph/task.md) and [limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/global_minimum_cut_of_dynamic_star_augmented_graph/info.toml). |
| `chordal_graph_recognition` | Treewidth elimination packages test fill and width, but no chordality recognition/certificate package was found. | Confirmed distinct: ten ports use maximum cardinality search and return a PEO or induced-hole certificate, with independent checks and byte-output suite wiring. |
| `dynamic_graph_vertex_add_component_sum` | [Library Checker task](https://github.com/yosupo06/library-checker-problems/blob/master/graph/dynamic_graph_vertex_add_component_sum/task.md): edge add/remove, vertex-value add, component-sum query. Unlike connectivity-only offline dynamic connectivity, component aggregates must track rollback-safe vertex deltas. | Implemented and registered: [`dynamic_graph_vertex_add_component_sum`](d/dynamic_graph_vertex_add_component_sum/README.md) has ten ports, a 114-word maximum valid frame, 256-byte output bound, time-segment-tree edge/value intervals, rollback DSU, direct-graph primary oracle, and rebuild-per-query independent verifier. |
| `counting_eulerian_circuits` | Eulerian trail packages construct one route; the directed Matrix–Tree package counts arborescences but not full edge-labeled Euler circuits. | Confirmed distinct BEST-theorem count: nine standard ports plus Mojo, a bounded edge-order oracle, workload, and byte-output verifier corpus are registered. |
| `counting_spanning_tree_undirected` | [`counting_spanning_trees_undirected`](c/counting_spanning_trees_undirected/README.md) implements Matrix–Tree counting. | Ten language drafts and byte-suite integration are present; the Mojo draft remains unverified. |
| `counting_spanning_tree_directed` | [`counting_spanning_trees_directed`](c/counting_spanning_trees_directed/README.md) counts rooted outward arborescences, treating parallel arcs as distinct. | Ten language drafts, an independent edge-parent oracle, Matrix–Tree implementation, and a byte-suite corpus with exhaustive small digraphs plus capacity, null, malformed, and max-bound cases are present. The Mojo draft remains unverified; no programs or validation tools were run. |

## Library Checker Tree category crosswalk (2026-10-29)

The official [`categories.toml`](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/categories.toml) Tree list contains the following 20 operation families. This is a static local-package comparison; candidate rows require an algorithm-level contract review before assignment.

| Official problem | Local comparison | Decision / next action |
| --- | --- | --- |
| `tree_diameter` | [`diameter_of_binary_tree`](d/diameter_of_binary_tree/README.md) accepts unweighted binary trees and does not return a path; no weighted arbitrary-tree diameter package was found. | Confirmed distinct: ten language ports, direct weighted-tree oracle, bounded workload, and byte-output suite registration are present. |
| `lca` | [`lowest_common_ancestor_binary_lifting`](l/lowest_common_ancestor_binary_lifting/README.md) and [`lowest_common_ancestor_tarjan`](l/lowest_common_ancestor_tarjan/README.md) handle batched queries on an undirected tree with different algorithms; other LCA packages use different input models. | Covered; retain binary lifting and Tarjan offline as distinct algorithms, while auditing aliases with the same method. |
| `jump_on_tree` | LCA packages return a common ancestor; the existing binary-lifting package does not expose a kth vertex on an arbitrary path. | Confirmed distinct: ten ports return the kth path vertex or `-1` when out of range, with a bounded workload, BFS oracle, and byte-output suite registration. |
| `frequency_table_of_tree_distance` | [`centroid_decomposition`](c/centroid_decomposition/README.md) constructs centroid-parent links; all-pairs packages return distance rows or matrices rather than a pair-distance histogram. | Confirmed distinct: ten ports use centroid decomposition to count unordered pairs at each distance, with a bounded all-sources BFS oracle, workload, and byte-suite registration. |
| `rooted_tree_isomorphism_classification` | [`rooted_tree_isomorphism_classification`](r/rooted_tree_isomorphism_classification/README.md) canonicalizes a batch of rooted unlabeled trees. | Covered by ten ports, exact-signature oracle, and byte-suite registration. |
| `tree_path_composite_sum` | Heavy-light packages expose path sums/maxima; none of the inspected README contracts computes the sum of affine compositions over every possible root. | Confirmed distinct rerooting DP: ten ports use directed component messages and affine edge transforms, with direct path-reconstruction and independent composition-traversal oracles, a bounded workload, and byte-output suite registration. The dense local profile is `O(N^2)` for `N <= 32`; it does not claim the official large-tree scale. It is distinct from [`tree_path_value`](t/tree_path_value/README.md), a source-specific greedy DAG walk. See the [official task](https://github.com/yosupo06/library-checker-problems/blob/master/tree/tree_path_composite_sum/task.md) and [limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/tree/tree_path_composite_sum/info.toml). |
| `vertex_add_path_sum` | [`heavy_light_path_sum`](h/heavy_light_path_sum/README.md) uses heavy-light decomposition and a segment tree for point updates and inclusive path sums. The official task changes the point update from assignment to addition. | Duplicate algorithm profile; addition can be translated to a point assignment using the stored current value, while the HLD decomposition, segment-tree update, and path-query recurrence are unchanged. No separate package is needed. [Official task](https://judge.yosupo.jp/problem/vertex_add_path_sum). |
| `vertex_set_path_composite` | Local [`vertex_set_path_composite`](v/vertex_set_path_composite/README.md) covers point-set affine vertex maps and ordered path-composition queries. | Confirmed distinct and implemented in ten languages. The Library Checker arbitrary-root `point_set_tree_path_composite_sum` is now implemented separately with a dynamic top tree; its fixed-root HLD variant is also present. Both update vertex values and edge maps and return an aggregate over all root-to-vertex paths, while this package returns a single endpoint-path composition. |
| `vertex_add_subtree_sum` | [`fenwick_tree`](f/fenwick_tree/README.md) operates on a flat array without tree preprocessing or subtree semantics; [`heavy_light_path_sum`](h/heavy_light_path_sum/README.md) handles path queries with point-set updates and a segment tree. | Confirmed distinct: ten ports flatten rooted subtrees to Euler intervals and answer point-add/subtree-sum traces with a Fenwick tree, using a direct child-traversal oracle, bounded workload, and byte-output suite registration. |
| `vertex_add_range_contour_sum_on_tree` | No contour-distance range-sum package was found; the existing Euler-tour subtree-sum and HLD path-sum packages answer different geometric subsets. | Confirmed distinct and implemented in ten languages with centroid-decomposition distance buckets, direct BFS oracle, bounded workload, and byte-output suite registration. The inverse range-add/point-get operation remains a separate duplicate audit. |
| `vertex_get_range_contour_add_on_tree` | The task is the update/query dual of [`vertex_add_range_contour_sum_on_tree`](v/vertex_add_range_contour_sum_on_tree/README.md). | Duplicate algorithm profile: both use centroid decomposition and per-centroid Fenwick distance buckets; swapping point-add/range-sum for range-add/point-get is an operation dual, not a separate core algorithm. Exclude it from the canonical algorithm inventory. See the [official task](https://github.com/yosupo06/library-checker-problems/blob/master/tree/vertex_get_range_contour_add_on_tree/task.md) and [limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/tree/vertex_get_range_contour_add_on_tree/info.toml). |
| `point_set_tree_path_composite_sum_fixed_root` | Existing [`tree_path_composite_sum`](t/tree_path_composite_sum/README.md) uses static rerooting DP; no package supports point updates with HLD-maintained fixed-root aggregates. | Confirmed distinct HLD + segment-tree profile: ten ports, bounded workload and dual oracles, README/RIGHTS, and static package review are present. The byte-output runner/verifier now register the workload, independent oracle, workspace, and generated maximum/malformed profiles. Bounded updates cover vertex values and edge affine maps, rooted at 0; keep separate from static rerooting because the maintained HLD summaries and update propagation are a different algorithm. [Official task](https://github.com/yosupo06/library-checker-problems/blob/master/tree/point_set_tree_path_composite_sum_fixed_root/task.md). |
| `point_set_tree_path_composite_sum` | Existing [`tree_path_composite_sum`](t/tree_path_composite_sum/README.md) computes static directed rerooting messages; fixed-root HLD maintains only root 0; `vertex_set_path_composite` answers one endpoint path; and `link_cut_tree` aggregates additive path weights. | Confirmed distinct and implemented as a balanced rake/compress top tree: ten language ports maintain forward/reverse affine maps and boundary-rooted `(sum,count)` summaries, propagate updates through cluster ancestors, and answer each chosen-root aggregate through outside contexts. A maintained-cluster primary oracle and direct path-reconstruction oracle, workload, rights note, static package checker, and byte-output suite registration are present. No programs or checkers were run. Recomputing all directed messages after updates remains excluded as a duplicate. [Official task](https://github.com/yosupo06/library-checker-problems/blob/master/tree/point_set_tree_path_composite_sum/task.md). |
| `dynamic_tree_vertex_add_path_sum` | The official task supports edge replacement, point addition, and path-sum queries. Local [`link_cut_tree`](l/link_cut_tree/README.md) already uses the same link-cut tree and additive path aggregate for dynamic edge replacement and path queries; local [`dynamic_tree_vertex_add_subtree_sum`](d/dynamic_tree_vertex_add_subtree_sum/README.md) also maintains additive vertex values under dynamic topology. | Duplicate algorithm profile: point addition is supported by exposing the vertex, changing its stored weight, and pulling the same splay aggregate; it does not introduce a new dynamic-tree structure or path-aggregate algorithm. Do not add a separate package. If broader operation coverage is wanted later, fold point-add events into the canonical `link_cut_tree` contract. [Official task](https://github.com/yosupo06/library-checker-problems/blob/master/tree/dynamic_tree_vertex_add_path_sum/task.md). |
| `dynamic_tree_vertex_set_path_composite` | [`vertex_set_path_composite`](v/vertex_set_path_composite/README.md) uses HLD and a segment tree on fixed topology; [`link_cut_tree`](l/link_cut_tree/README.md) maintains additive path sums on dynamic topology. | Confirmed distinct and implemented in ten languages: the bounded profile uses a Link-Cut Tree with forward/reverse affine-composition summaries, edge cut/link, vertex map updates, and oriented path queries. Its dynamic topology and ordered noncommutative aggregate differ from both fixed-tree HLD composition and dynamic additive sums. The primary Link-Cut oracle and independent direct-path oracle are registered in the byte-output runner/verifier, with generated maximum-input and maximum-output traces. See [`dynamic_tree_vertex_set_path_composite`](t/dynamic_tree_vertex_set_path_composite/README.md) and the [official task](https://github.com/yosupo06/library-checker-problems/blob/master/tree/dynamic_tree_vertex_set_path_composite/task.md). |
| `dynamic_tree_vertex_add_subtree_sum` | [`link_cut_tree`](l/link_cut_tree/README.md) supports dynamic link/cut and path sums but not virtual-subtree aggregates; [`vertex_add_subtree_sum`](v/vertex_add_subtree_sum/README.md) uses Euler intervals on a fixed topology and cannot replace tree edges. The official operation removes one edge, inserts another while preserving a tree, adds to one vertex, or sums the side of an adjacent parent edge containing a selected vertex. | Confirmed distinct dynamic-tree profile: [`dynamic_tree_vertex_add_subtree_sum`](d/dynamic_tree_vertex_add_subtree_sum/README.md) uses a link-cut tree with virtual-subtree totals and path reversal, bounded to `N<=32`, `Q<=64`; ten clean-room ports, direct edge-excluded traversal oracle, independent adjacency-matrix verifier, workload, rights notes, and static package checker are written. Registered in the byte-output runner and verifier. See the [official task](https://github.com/yosupo06/library-checker-problems/blob/master/tree/dynamic_tree_vertex_add_subtree_sum/task.md). |
| `dynamic_tree_subtree_add_subtree_sum` | [`dynamic_tree_vertex_add_subtree_sum`](d/dynamic_tree_vertex_add_subtree_sum/README.md) supports point additions and side sums through virtual-subtree aggregates, but it does not lazily add to every vertex on a selected rooted side. | Confirmed distinct: an implicit Euler-tour treap applies lazy addition to vertex-marker ranges for one edge-oriented side, maintains sums, and supports edge replacement. Ten source ports, README/RIGHTS, workload, direct-edge traversal oracle, independent adjacency-matrix verifier, and static package checker are present; the author's static pass is complete. I wired its oracle, 16 KiB workspace, workload check, and maximum/malformed profiles into the shared byte-output suite. Static-only; no checks or benchmarks were run. |
| `cartesian_tree` | Treaps and binary-search trees support ordered or dynamic operations but do not construct the array's Cartesian tree. | Confirmed distinct: ten ports use a linear monotonic stack over the right spine, with a stable leftmost tie rule, recursive interval-minimum oracle, bounded workload, and byte-output suite integration. The local tie extension broadens the official distinct-key input profile. |
| `common_interval_decomposition_tree` | No local common-interval decomposition, strong-interval tree, or permutation-tree package was found; Cartesian-tree construction and permutation enumerators have different operations and output. | Implemented and registered in the byte suite: ten ports build a bounded exhaustive strong-interval decomposition (connected intervals, overlap filtering, inclusion tree, linear/prime labels), with an independent oracle, certificate checker, and workload. The `O(n^4)` profile does not claim the official-scale linear-time construction. |
| `rooted_tree_topological_order_with_minimum_inversions` | Generic topological sorting and rooted-tree routines do not minimize the weighted objective `sum_{i>j} c[p_i]*d[p_j]` over ancestor-respecting permutations. | Confirmed distinct: ten ports use ratio-ordered DSU component contractions; an independent subset DP checks optimum certificates, and the bounded workload is registered in the byte-output suite. The package uses `N<=12` and does not claim the official `N<=200,000` scale. See the [official task](https://github.com/yosupo06/library-checker-problems/blob/master/tree/rooted_tree_topological_order_with_minimum_inversions/task.md) and [limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/tree/rooted_tree_topological_order_with_minimum_inversions/info.toml). |

## Library Checker String category crosswalk (2026-10-29)

The official [`categories.toml`](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/categories.toml) String list was compared with local string packages and their documented operations.

| Official problem | Local comparison | Decision / next action |
| --- | --- | --- |
| `zalgorithm` | [`z_algorithm`](z/z_algorithm/README.md) returns the complete Z-array; the former search wrapper case-folded input, computed the same array, and filtered match positions. | The former `z_function` and `z_algorithm_search` packages were consolidated into `z_algorithm`, whose bound is now 4,095, enough for the largest prepared search sequence. The search-specific case folding and position-output interface is no longer provided by the suite. All changes are unexecuted. |
| `enumerate_palindromes` | [`manacher`](m/manacher/README.md) already runs the linear radius-reuse algorithm; its benchmark returns the selected longest palindrome rather than the full radii array. | Same underlying Manacher algorithm; keep `manacher` canonical and do not add a duplicate package solely for emitting its radius array. |
| `suffixarray` | [`suffix_array`](s/suffix_array/README.md) uses rank doubling; [`suffix_array_dc3`](s/suffix_array_dc3/README.md) implements DC3. | Covered by two materially different suffix-array construction algorithms. |
| `number_of_substrings` | [`suffix_automaton`](s/suffix_automaton/README.md) already exposes `count_distinct_substrings()` on the built automaton. | Covered by the existing suffix-automaton operation; do not add a duplicate count-only package. |
| `runenumerate` | [`duval_algorithm`](d/duval_algorithm/README.md) computes Lyndon factors, not maximal periodic runs. | Confirmed distinct: [`runenumerate`](r/runenumerate/README.md) has ten ports, an independent exhaustive interval verifier, `n<=24` fixtures, and byte-output runner/verifier registration. The exact `O(n^4)` bounded period-block profile does not claim the official asymptotic solution. |
| `prefix_substring_lcs` | The current [official task](https://github.com/yosupo06/library-checker-problems/blob/master/string/prefix_substring_lcs/task.md) asks for many LCS lengths between a prefix of one fixed string and a substring of another. Local [`longest_common_subsequence`](l/longest_common_subsequence/README.md) computes one full-string LCS with a single-row DP; [`rle_lcs_block_dp`](r/rle_lcs_block_dp/README.md) handles compressed input with the same pairwise recurrence. | Confirmed distinct batched query algorithm: ten bounded ports compute semi-local prefix boundary values and use a Fenwick sweep; direct per-query LCS is the independent oracle. Workload, rights note, package-local static checker, and shared byte-output suite registration are complete. The official task is in the current category inventory and defines lowercase strings, prefix/substring ranges, and up to 500,000 queries. |
| `lyndon_factorization` | Same Duval scan as [`duval_algorithm`](d/duval_algorithm/README.md). | Narrower duplicate removed; source provenance and applicable verifier cases are retained with the wider profile. |
| `longest_common_substring` | [`longest_common_substring`](l/longest_common_substring/README.md) computes the longest common contiguous substring length by dynamic programming. | Covered; this is substring, not subsequence, matching the repository contract. |
| `eertree` | [`eertree`](e/eertree/README.md) maintains the online palindromic tree and distinct-palindrome prefix counts. | Covered by ten ports, including the new Mojo implementation, and scalar-suite registration. The source inventory now includes all supported benchmark languages. |
| `palindromes_in_deque` | The local `eertree` is insertion-only at the right and reports a distinct-palindrome prefix-count checksum; `manacher` is static. Neither implements the official operation/output contract. | Added a bounded, clean-room snapshot-rebuild Eertree profile in ten languages. It handles front/back insertion and deletion and emits distinct-palindrome count plus longest palindromic prefix/suffix after every operation (`Q <= 32`, `O(Q*N)` for fixed alphabet size 26). This deliberately does not claim to implement the official amortized double-ended tree. See the [official task](https://github.com/yosupo06/library-checker-problems/blob/master/string/palindromes_in_deque/task.md), [reference solution](https://github.com/yosupo06/library-checker-problems/blob/master/string/palindromes_in_deque/sol/correct.cpp), and [bounded profile README](p/palindromes_in_deque/README.md). |
| `wildcard_pattern_matching` | [`wildcard_matching`](w/wildcard_matching/README.md) implements full-string `?` and `*` matching with dynamic programming. | Covered for the documented wildcard language; retain separate regex matching because its `*` semantics differ. |

## Algorithm Archive chapter crosswalk (2026-10-29)

The [official chapter summary](https://raw.githubusercontent.com/algorithm-archivists/algorithm-archive/main/SUMMARY.md) was compared against local package names and README contracts. The Archive is an educational collection and several sections are introductions or incomplete notes rather than executable algorithms; these are marked separately so they do not become speculative benchmark requests.

| Archive chapter / algorithm | Local comparison | Decision / next action |
| --- | --- | --- |
| Iterated Function Systems / Barnsley Fern | [`barnsley_fern`](b/barnsley_fern/README.md) implements the four affine maps with an explicit deterministic sample tape. | Covered; the random source is projected into supplied choices to make the algorithm trace reproducible. |
| Data Structures; Stacks and Queues | The repository has stacks, queues, priority queues, trees, heaps, and persistent/dynamic structures with individual operation contracts. | Covered broadly; the chapter is a topic overview, not one additional data-structure algorithm. |
| Affine Transformations | [`affine_image_rotation`](a/affine_image_rotation/README.md), [`affine_converter`](a/affine_converter/README.md), and other geometry transforms cover selected affine operations. | No standalone named algorithm in the chapter; compare concrete transforms only when they specify a distinct operation. |
| Bit Logic | Bitwise operations and bitset-based algorithms are already represented across local packages. | Excluded as a language/representation tutorial rather than one benchmark procedure. |
| Taylor Series Expansion | [`maclaurin_series`](m/maclaurin_series/README.md) approximates sine and cosine, but the Archive chapter is explicitly marked incomplete and gives no bounded function/derivative input procedure. | Do not claim coverage of a general Taylor-series evaluator; await a complete algorithm contract or select a separately sourced series kernel. |
| Convolutions, 1D/2D Convolutions, Convolution Theorem | [`convolution`](c/convolution/README.md), [`convolution_fft`](c/convolution_fft/README.md), [`image_convolution`](i/image_convolution/README.md), and related convolution variants cover direct and transform-based workloads. | Covered at the operation level; retain direct, FFT, circular, image, and specialized convolution algorithms where their computational behavior differs. |
| Box–Muller Transform: Cartesian form | No normal-sample transform package was found in the name/path inventory. | Confirmed distinct direct transform with no rejection loop; ten language ports, 90-digit Decimal oracle, bounded draw-tape workload, independent verifier oracle, and `float64_slice_io` suite registration are complete. |
| Box–Muller Transform: Marsaglia polar form | No polar or Cartesian normal-sampling transform package was found. | Confirmed distinct rejection-based normal transform; ten language ports, high-precision Decimal oracle, bounded deterministic tape workload, independent verifier oracle, and `float64_slice_io` suite registration are complete. |
| Rejection sampling: finite discrete target with supplied proposal | No general discrete rejection-sampling package or reservation was found. [`marsaglia_polar_normal`](m/marsaglia_polar_normal/README.md) uses a fixed two-dimensional polar proposal and circle test to return Gaussian pairs; [`weighted_random_sampling`](w/weighted_random_sampling/README.md) uses rational priority keys to select a weighted subset; neither samples a caller-supplied finite target distribution through a caller-supplied proposal/envelope. | Implemented and byte-output suite registered as [`discrete_rejection_sampling`](d/discrete_rejection_sampling/README.md): bounded finite-support rejection sampling with integer target/proposal weights, a computed integer envelope, and a fixed supplied draw tape. The Archive chapter motivates rejection/cost but is not a full sampler contract; the general accept/reject construction follows Devroye, *Non-Uniform Random Variate Generation*, Chapter II §3 (1986, DOI [10.1007/978-1-4613-8643-8_2](https://doi.org/10.1007/978-1-4613-8643-8_2)). Ten ports use exact category-specific integer acceptance ranges, so the conditional acceptance law preserves the target probabilities without quantizing the draw threshold. An independent cumulative-table oracle, maximum-input/output fixtures, valid exhaustion case, malformed-tape checks, and capacity probes are included. Its state transition differs from the specialized Marsaglia polar transform and weighted-priority subset selection. Clean-room implementation only. No programs, tests, scripts, checkers, builds, compilers, or benchmarks were run. |
| Probability Distributions | The chapter covers several distribution concepts rather than a single sampling algorithm. | No single benchmark candidate; assess a specific sampler separately, with supplied random tapes where needed. |
| Tree Traversal | Local DFS and BFS packages cover recursive/iterative and queue/stack traversals for binary trees and general graphs. | Covered as a family; retain distinct traversal order and data-structure variants already present. |
| Euclidean Algorithm | Greatest-common-divisor and extended-Euclidean packages are present. | Covered; no duplicate subtraction/division variant unless it has a materially different measured procedure. |
| Monte Carlo | [`monte_carlo_integration`](m/monte_carlo_integration/README.md), [`monte_carlo_simulation`](m/monte_carlo_simulation/README.md), and pi-estimation packages cover bounded random-sample estimators. | Covered by distinct sampling/estimation profiles; a source-specific estimator should be compared before adding another Monte Carlo name. |
| Metropolis Algorithm | [`simulated_annealing`](s/simulated_annealing/README.md) changes temperature while searching for a low-scoring solution; it does not produce a fixed-temperature MCMC state trace. | Confirmed distinct fixed-temperature sampler: ten clean-room ports replay symmetric proposals and supplied uniform draws, with an independent accept/reject oracle, bounded trace workload, and `float64_slice_io` registration. The profile returns the initial state plus every post-proposal state and makes no burn-in or convergence claim. |
| Matrix Methods; Gaussian Elimination | [`gaussian_elimination`](g/gaussian_elimination/README.md) covers no-pivot elimination on symmetric tridiagonal systems; [`gaussian_elimination_pivoting`](g/gaussian_elimination_pivoting/README.md) covers dense partial-pivot elimination. | The separate `gauss_elimination` package was removed as a duplicate C partial-pivot implementation; its source is cross-referenced to the retained dense pivoting package. The no-pivot and partial-pivot methods remain distinct. |
| Thomas Algorithm (tridiagonal matrix solver) | The existing [`gaussian_elimination`](g/gaussian_elimination/README.md) has a tridiagonal input restriction but uses generic dense elimination and back substitution. | Confirmed distinct: ten ports use the O(N) Thomas recurrence, with exact dense-rational oracle, residual validation, float64 byte-suite integration, and bounded diagonally dominant workloads. |
| Computational Geometry overview | Local geometric packages cover hull, closest/furthest pair, enclosing circle, MST, Voronoi/Delaunay, and related operations. | No single procedure from the overview; compare each algorithm chapter separately. |
| Gift Wrapping / Jarvis March | [`jarvis_scan`](j/jarvis_scan/README.md) implements the gift-wrapping convex hull and catalogs matching source aliases. | Covered; gift-wrapping and Jarvis March are synonyms for the same algorithm here, so no second package. |
| Graham Scan | [`convex_hull_graham_scan`](c/convex_hull_graham_scan/README.md) implements Graham scan. | Covered; retain separately from Jarvis scan as a different hull algorithm. |
| Cooley–Tukey FFT | [`fast_fourier_transform`](f/fast_fourier_transform/README.md) and [`convolution_fft`](c/convolution_fft/README.md) use radix-2 Cooley–Tukey butterflies. | Covered; no additional transform port for the same radix-2 algorithm. |
| Decision Problems / Hungarian Algorithm | [`hungarian_algorithm`](h/hungarian_algorithm/README.md) solves rectangular minimum-cost assignment; bitmask assignment is a distinct subset-DP method. | Covered; the chapter is an overview, and the Hungarian algorithm is already present. |
| Stable Marriage Problem | [`stable_matching`](s/stable_matching/README.md) implements men-proposing deferred acceptance. | Covered; retain other preference/choice models only when they use materially different algorithms. |
| Physics Solvers; Verlet Integration | [`verlet`](v/verlet/README.md) ports a bounded velocity-Verlet recurrence. | Covered. |
| Quantum Systems; Quantum Information overviews | These chapters introduce quantum domains and survey possible operations but do not define one bounded, language-independent classical procedure suitable for this ABI. | Excluded as survey/background material; revisit a named classical algorithm only if the Archive adds complete steps and an executable chapter contract. |
| Cryptography overview | The chapter lists Caesar/ROT13, XOR, and a permutation cipher; local [`caesar_cipher`](c/caesar_cipher/README.md), [`rot13`](r/rot13/README.md), [`xor_cipher`](x/xor_cipher/README.md), and [`permutation_cipher`](p/permutation_cipher/README.md) already implement those operations. The RSA chapter candidate is only described at a high level; local [`rsa_cipher`](r/rsa_cipher/README.md) encrypts using caller-supplied public-key parameters and does not generate keys. | No new candidate: the Archive states that the symmetric and asymmetric methods are works in progress and that corresponding algorithm chapters will be added later; the page gives no executable RSA key-generation contract. Do not duplicate the existing cipher operations or infer a new implementation from an overview. See the [official Cryptography chapter](https://www.algorithm-archive.org/contents/cryptography/cryptography.html). |
| Split-Operator Method | [`split_operator_imaginary_time`](s/split_operator_imaginary_time/README.md) already implements the imaginary-time Strang-split position/momentum/position recurrence, with radix-2 FFT ports in all ten supported languages and a direct-DFT oracle. | Covered by the existing package; keep it as the canonical split-operator benchmark and do not add a duplicate. |
| Data Compression; Huffman Encoding | [`nbench_huffman_compression`](n/nbench_huffman_compression/README.md) implements full Huffman tree construction, bitstream encoding, and round-trip decoding. | The weighted-cost-only package was removed as a duplicate projection of this same greedy Huffman construction; no further Huffman implementation is needed. |
| Flood Fill | [`flood_fill`](f/flood_fill/README.md) implements bounded region filling. | Covered. |
| Computus / Gauss's Easter Algorithm | [`easter`](e/easter/README.md) and [`gauss_easter`](g/gauss_easter/README.md) implement Gregorian Easter-date algorithms; [`julian_easter`](j/julian_easter/README.md) uses the Julian calendar formula. | Covered; retain calendar/formula variants as distinct only where the calendar or algorithm actually differs. |
| Approximate Counting Algorithm (Morris counter) | No approximate counter was found; exact counters and `morrisinorder` are unrelated (tree traversal). | Confirmed distinct; ten ports, deterministic draw-tape oracle/workload, strict metadata and fixture validation, boundary/malformed/null/max-tape verifier probes, byte-output runner/verifier registration, and README entry are present. The workload reports compressed state and decoded estimate without a deterministic error guarantee. |
| Plotting, Domain Coloring, Computer Graphics | These chapters focus on rendering/visualization and do not specify a single portable algorithmic kernel for the benchmark ABI. | Excluded as output/environment-oriented material unless a concrete rasterization or geometry algorithm is separately selected. |

## PARSEC and SPLASH-2 application crosswalk (updated 2026-11-12)

These are algorithm-level dispositions, not claims that a bounded local kernel reproduces a parallel suite's full application, input set, or score. PARSEC's 13 application names are listed in its [suite characterization](https://www.cs.princeton.edu/techreports/2010/890.pdf); the SPLASH-2 source mirror lists Barnes, Cholesky, FFT, FMM, LU, Ocean, Radiosity, Radix, Raytrace, Water-Nsquared, and Water-Spatial.

| Source candidate | Repository comparison | Decision |
| --- | --- | --- |
| PARSEC `blackscholes` | [`black_scholes_option_price`](b/black_scholes_option_price/README.md) computes the European call/put Black–Scholes formulas. | Already present/duplicate at the algorithm level; no second option-pricing package for the same closed-form formula. |
| PARSEC `bodytrack` | [`rodinia_particlefilter_naive`](r/rodinia_particlefilter_naive/README.md) benchmarks one ordinary likelihood/normalization/resampling transition; PARSEC uses a multi-layer annealed particle filter for articulated 3-D pose tracking. | Confirmed distinct: [`bodytrack_annealed_particle_filter`](b/bodytrack_annealed_particle_filter/README.md) implements bounded likelihood annealing, weighted resampling, supplied pose-shock transitions, and a final weighted estimate in ten languages. Two independently structured oracles, a static package checker, and `i64_array_bytes_output` registration are present; image-feature extraction and parallel scheduling remain outside the profile. See the [PARSEC characterization](https://www.cs.princeton.edu/techreports/2010/890.pdf) and [annealed-particle-filter paper](https://www.robots.ox.ac.uk/~lav/Papers/deutscher_etal_cvpr2000/deutscher_etal_cvpr2000.html). |
| PARSEC `canneal` | [`simulated_annealing`](s/simulated_annealing/README.md) already covers the simulated-annealing search algorithm. | Already present/duplicate at the algorithm level; objective and input graph are profile data. |
| PARSEC `dedup` | No single package represents the complete chunking, hashing, compression, and storage pipeline. The report identifies content-defined fragmentation as a separable kernel. [`rabin_karp`](r/rabin_karp/README.md) searches for a pattern rather than returning fingerprint-selected chunk boundaries; fixed-size chunking and the turnstile singleton fingerprint also perform different operations. | The compound parallel pipeline remains outside the single-call ABI. **Distinct profile in progress:** [`rabin_content_defined_chunking`](r/rabin_content_defined_chunking/README.md) has a bounded four-byte GF(2) sliding fingerprint contract, two oracle drafts, workload, rights note, ten language drafts and suite wiring. None has been executed. The [PARSEC report](https://www.cs.princeton.edu/techreports/2010/890.pdf) identifies the kernel and its low-bit boundary trigger; the [USENIX storage study](https://www.usenix.org/legacy/events/usenix04/tech/general/full_papers/policroniades/policroniades_html/index.html) explains the sliding-window polynomial method. Sources supply algorithm ideas only; no text, examples, fixtures, or code are copied. |
| PARSEC `facesim` | The source metadata names Verlet position updates and a model-specific Newton solve for quasistatic constraints; local [`verlet`](v/verlet/README.md), [`damped_oscillator`](d/damped_oscillator/README.md), and [`conjugate_gradient`](c/conjugate_gradient/README.md) cover adjacent reusable procedures. | Excluded from implementation for now: the source metadata gives no constraint residual, Jacobian, material law, or element-update contract for a faithful bounded Newton kernel. The Newton system is model-specific, and inventing mechanics equations would not be an honest port. Its source tree has a BSD-style license, but no upstream code is reused. See the [PARSEC characterization](https://www.cs.princeton.edu/techreports/2010/890.pdf), [Facesim metadata](https://github.com/cirosantilli/parsec-benchmark/blob/master/pkgs/apps/facesim/src/README), and [source license](https://github.com/cirosantilli/parsec-benchmark/blob/master/pkgs/apps/facesim/src/LICENSE). |
| PARSEC `ferret` | The application combines image-feature extraction, indexing, similarity search, and query processing. [`intensity_based_segmentation`](i/intensity_based_segmentation/README.md) assigns labels using independent intensity thresholds rather than adjacency-ordered merges. Existing [`min_cost_max_flow`](m/min_cost_max_flow/README.md) and [`minimum_cost_b_flow`](m/minimum_cost_b_flow/README.md) cover general flow methods; earth mover distance is a transport objective, not by itself a separate solver. | The compound pipeline is excluded from the single-call ABI. **Distinct kernel in progress:** [`statistical_region_merging_table`](s/statistical_region_merging_table/README.md) has a grayscale supplied-bound contract, two oracle drafts, workload, ten language drafts, rights note and byte-output suite registration. This parameterized profile implements ordered merging with a size-bound predicate; statistical guarantees require a caller-supplied table derived from the source formula. Source: [Nock and Nielsen's paper](https://www.lix.polytechnique.fr/~nielsen/pdf/2004-StatisticalRegionMerging-PAMI.pdf); [PARSEC report](https://www.cs.princeton.edu/techreports/2010/890.pdf). No code or source prose copied; nothing executed. |
| PARSEC `fluidanimate` | [`splash2_water_nsquared`](s/splash2_water_nsquared/README.md) models a molecular pair potential; it is not smoothed-particle hydrodynamics. | Confirmed distinct: [`fluidanimate_sph`](f/fluidanimate_sph/README.md) adds a bounded one-step SPH density/pressure/viscosity acceleration profile with ten ports, pairwise and target-wise oracles, package rights/checker, and `i64_array_bytes_output` runner/verifier registration. See the [PARSEC characterization](https://www.cs.princeton.edu/techreports/2008/811.pdf) and [source mirror](https://gem5.googlesource.com/public/gem5-resources/+/refs/heads/develop/src/parsec/disk-image/parsec/parsec-benchmark/pkgs/apps/fluidanimate/src/). |
| PARSEC `freqmine` | [`frequent_pattern_growth`](f/frequent_pattern_growth/README.md) implements FP-tree conditional-pattern growth and counts frequent itemsets. | Already present/duplicate at the algorithm level; PARSEC's larger transaction workload and parallel schedule are profile differences. |
| PARSEC `raytrace` | [`freebench_distray`](f/freebench_distray/README.md) already covers ray generation, intersections, shading, shadows, and reflections in a bounded scene. | Already present/duplicate ray-tracing algorithm; PARSEC's full scene and parallel renderer are not a separate algorithm. |
| PARSEC `streamcluster` | [`rodinia_streamcluster_pgain`](s/rodinia_streamcluster_pgain/README.md) implements the same squared-distance facility-opening `pgain` step: evaluate reassignment savings and center-closing costs, then commit only when the objective decreases. | Covered/duplicate: PARSEC's `pgain` is the same measured local-search move. Stream input, initialization, and repeated scheduling change the surrounding application workload, not the benchmarked algorithm, so do not add a second package. See the [PARSEC characterization](https://www.cs.princeton.edu/techreports/2010/890.pdf). |
| PARSEC `swaptions` | [`black_scholes_option_price`](b/black_scholes_option_price/README.md) is a closed-form European-option formula; it does not price a swaption under a simulated LIBOR market model. | Confirmed distinct: [`hjm_forward_path`](m/hjm_forward_path/README.md) implements bounded triangular HJM path generation from explicit shocks in ten languages, with primary and independent drift oracles and `float64_slice_io` runner/verifier wiring. The portfolio scheduler and payoff aggregation remain outside this algorithm profile; see the [PARSEC characterization](https://www.cs.princeton.edu/techreports/2010/890.pdf) and [source mirror](https://github.com/cirosantilli/parsec-benchmark/tree/master/pkgs/apps/swaptions/src). |
| PARSEC `vips` | VIPS is an image-processing library/runtime carrying out a composed image graph. | Excluded as a runtime/application pipeline; individual image operations already have separate local packages. |
| PARSEC `x264` | H.264 encoding is a multi-stage codec with motion estimation, transforms, quantization, and entropy coding. | Excluded as a whole application; select a named codec kernel only after a separate source-level comparison. |
| SPLASH-2 `Barnes` | [`olden_bh`](o/olden_bh/README.md) implements the Barnes–Hut octree and monopole approximation; [`benchmarkgame_nbody`](b/benchmarkgame_nbody/README.md) is direct pairwise N-body. | Already present/duplicate Barnes–Hut algorithm; suite-scale time integration and parallel partitioning are profiles. |
| SPLASH-2 `Cholesky` | [`cholesky_decomposition`](c/cholesky_decomposition/README.md) and [`polybench_cholesky`](p/polybench_cholesky/README.md) factor dense matrices. Neither describes sparse symbolic structure or supernodal block updates. | Distinct bounded [`sparse_supernodal_cholesky`](s/sparse_supernodal_cholesky/README.md) profile: supplied filled pattern and supernodes, ten source drafts, two oracle calculations, workload, provenance, and byte-output suite wiring. It excludes symbolic ordering and the SPLASH scheduler. The package remains unexecuted and requires review. See the [SPLASH-2 inventory](https://github.com/staceyson/splash2) and [right-looking supernodal factorization study](https://escholarship.org/uc/item/5n39j9sr). |
| SPLASH-2 `FFT` | [`fast_fourier_transform`](f/fast_fourier_transform/README.md) uses iterative radix-2 Cooley–Tukey butterflies; SPLASH-2 uses a radix-√N six-step 1-D FFT with row transforms, twiddle multiplication, and three matrix transposes. | Confirmed distinct data-movement algorithm: [`splash2_fft_six_step`](f/splash2_fft_six_step/README.md) implements the bounded transpose-aware profile in ten languages with direct DFT and independent matrix-form oracles, package checking, and `float64_slice_io` registration. Parallel synchronization and launcher behavior remain outside the profile. See the [SPLASH-2 characterization](https://www.cs.princeton.edu/techreports/2010/890.pdf) and [program source mirror](https://github.com/staceyson/splash2). |
| SPLASH-2 `FMM` | [`olden_bh`](o/olden_bh/README.md) is Barnes–Hut and uses a different hierarchical approximation. | Confirmed distinct: [`splash2_fmm`](f/splash2_fmm/README.md) adds a bounded clean-room 2-D multipole profile with P2M, M2L, local evaluation, and direct near-field interactions, plus ten ports, two direct oracles, package checking, and `float64_slice_io` registration. See the [SPLASH-2 paper](https://pages.cs.wisc.edu/~markhill/restricted/isca95_splash2.pdf) and [Greengard–Rokhlin FMM paper](https://doi.org/10.1016/0021-9991(87)90140-9). |
| SPLASH-2 `LU` / blocked right-looking LU | [`lu_decompose`](l/lu_decompose/README.md) is scalar no-pivot Doolittle, [`lu_pivot_decomposition`](l/lu_pivot_decomposition/README.md) is scalar partial-pivot elimination, and [`linpack_lu_solve`](l/linpack_lu_solve/README.md) solves supplied factors; [`npb_lu_block_ssor`](n/npb_lu_block_ssor/README.md) is a sparse 3-D iterative solver. None uses the blocked panel/diagonal-tile factorization, row and column block solves, and trailing Schur updates. | Implemented and registered as [`blocked_lu_factorization`](b/blocked_lu_factorization/README.md) in all ten languages and the float64-slice suite. It has a B=2 serial right-looking primary, scalar Doolittle independent oracle, bounded workload, rights/provenance, and static inventory checker. The profile uses even `N<=8` and strictly row-diagonally-dominant positive-diagonal input to guarantee safe no-pivot elimination. This is a distinct blocked data-movement/update profile with the same mathematical LU result, motivated by SPLASH-2's block-locality baseline and specified from FLAME's blocked-LU equations; it is not a reproduction of SPLASH-2's parallel BLAS-1 update schedule. Processor assignment, barriers, and parallel scheduling are outside the ABI. Sources: SPLASH-2 characterization, DOI [10.1145/223982.223990](https://doi.org/10.1145/223982.223990), and [FLAME blocked right-looking LU](https://www.cs.utexas.edu/~flame/laff/alaff/chapter05-blocked-lu-factorization.html). Clean-room algorithm descriptions only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |
| SPLASH-2 `Ocean` | [`scimark2_sor`](s/scimark2_sor/README.md) is row-major weighted SOR, `gauss_seidel_method` is a generic coordinate sweep, and local multigrid transfers use different grids/transfer operators. | Confirmed distinct: [`splash2_ocean_rbgs`](o/splash2_ocean_rbgs/README.md) implements a bounded red-then-black Gauss-Seidel relaxation sweep with Ocean's screened-Poisson update and max-correction metric. Ten ports, two independently structured oracles, a static package checker, and `float64_slice_io` registration are present; the W-cycle scheduler and parallel decomposition are outside the profile. The source has non-commercial-only terms; the ports are clean-room implementations based on published algorithm descriptions. No execution. |
| SPLASH-2 `Radiosity` | No hierarchical radiosity form-factor or interaction-link refinement package was found in the local inventory. | Confirmed distinct: [`splash2_radiosity_refine`](f/splash2_radiosity_refine/README.md) provides one bounded adaptive patch-pair refinement and gather profile in ten languages, with recursive and explicit-stack oracles, a static package checker, and `float64_slice_io` registration. Its coarse-versus-fine probe is explicitly heuristic, not the paper's certified precision guarantee. The upstream source carries restrictive Stanford non-commercial terms; no source code or problem text was reused. See the [published algorithm](https://doi.org/10.1145/122718.122740) and [source rights record](f/splash2_radiosity_refine/RIGHTS.md). |
| SPLASH-2 `Radix` | [`radix_sort`](r/radix_sort/README.md) and [`msd_radix_sort`](m/msd_radix_sort/README.md) cover radix-based sorting. | Already present/duplicate sorting family; no separate port for the parallel launcher profile. |

### Sparse supernodal Cholesky contract work (2026-11-13)

Reserved candidate: [`sparse_supernodal_cholesky`](s/sparse_supernodal_cholesky/README.md). The bounded contract specifies an SPD matrix, a supplied filled lower-triangular bitmask pattern, and a partition of consecutive columns into supernodes for `n<=8`. It requires update closure, dense diagonal blocks, and rectangular off-diagonal panels. The right-looking block/panel oracle and dense scalar reference now validate frames separately; the primary uses dense scratch for its oracle model. A workload, sparse-storage ports in all ten languages, and byte-output suite registration are present. The supplied pattern must contain every location needed by updates; fill is not silently dropped. All work remains unexecuted and requires further static review.

This profile isolates sparse numerical factorization with supplied symbolic analysis. It does not claim to reproduce SPLASH-2's ordering, symbolic analysis, scheduling, or performance results. The published [right-looking supernodal study](https://arxiv.org/html/2409.13090v1) describes these numerical stages and identifies its article as CC BY-NC-ND 4.0; use mathematical ideas only and independently write the contract, fixtures, and code. The [SPLASH-2 repository](https://github.com/staceyson/splash2) is used for suite identification, not as a code or fixture source. Owner: root; other agents should not edit this candidate without coordination.

The suite corpus now also specifies generated positive-definite dense factors under singleton and full-block partitions, sparse chain factors with absent structural slots, comparisons between the two oracle calculations, capacity boundaries, and invalid-input precedence cases. This is source-level coverage only; none of the corpus or ports has been executed.
| SPLASH-2 `Raytrace` | [`freebench_distray`](f/freebench_distray/README.md) covers the ray-tracing operation at one-pixel scope. | Already present/duplicate ray-tracing algorithm. |
| SPLASH-2 `Water-Nsquared` | No molecular-water direct all-pairs interaction kernel was found; gravity N-body packages use a different force law. | Confirmed distinct bounded pair-scan profile: ten ports use a clean-room rational potential/force contract, strict cutoff, and signed fixed-point accumulation. It is registered in the byte-output suite with a direct-pair oracle and independent target-wise oracle. This is an algorithmic projection, not a physical force-field or timestep reproduction. See [SPLASH-2](https://github.com/staceyson/splash2) and the [benchmark contract](s/splash2_water_nsquared/README.md). |
| SPLASH-2 `Water-Spatial` | Rodinia LavaMD supplies particles already grouped into neighboring boxes and uses an exponential screened force; local N-body packages use other force laws and do not construct this grid. | Confirmed distinct traversal profile: ten ports build uniform 3-D linked cells and search each current cell plus the clipped 26 neighbors using the shared bounded pair law. It is registered in the byte-output suite with direct and target-wise independent oracles. This is a bounded spatial-index projection, not the full Water-Spatial simulation. See [SPLASH-2](https://github.com/staceyson/splash2) and the [benchmark contract](w/water_spatial/README.md). |

## Resolved Library Checker candidates and duplicates

| Candidate | Decision | Repository comparison / owner |
| --- | --- | --- |
| Li Chao tree (dynamic line insertion and minimum query) | Confirmed distinct; ten port drafts and scalar-suite wiring present | No Li Chao tree or equivalent line-container package was found in the initial static filename/content search. Static review of the original nine ports covered the bounded integer-domain contract, midpoint insertion and path query, parser bounds, node capacity, and checksum framing; the new Mojo draft remains unverified. The workload, direct-scan oracle, package validator, and scalar-suite registration are present. No checker, program, test, build, compiler, or benchmark was run. [Yosupo line-add/get-min problem](https://judge.yosupo.jp/problem/line_add_get_min). |
| Dominator tree | Confirmed distinct; ten port drafts and byte-output suite wiring present | `dominator_tree` uses bitset fixed-point data-flow equations and an independent vertex-removal oracle; it is not a Lengauer–Tarjan implementation. Existing connected dominating-set benchmarks and Tarjan offline LCA/SCC are also different algorithms. The original nine ports received static review; the Mojo draft remains unverified. No programs, tests, checkers, builds, compilers, or benchmarks were run. [Yosupo dominator-tree problem](https://judge.yosupo.jp/problem/dominatortree). |
| [Pfaffian of Matrix](https://github.com/yosupo06/library-checker-problems/blob/master/linear_algebra/pfaffian_of_matrix/task.md) | [`hafnian_of_matrix`](h/hafnian_of_matrix/README.md) computes an unsigned matching sum by subset DP; determinant packages compute a different polynomial invariant. No Pfaffian operation or signed perfect-matching sum was found. | Implemented and scalar-suite registered as [`pfaffian_of_matrix`](p/pfaffian_of_matrix/README.md): bounded alternating matrices of order `2N<=16` over `F_998244353`, with ten ports, workload, README/RIGHTS, two oracles, static inventory checker, and scalar runner/verifier integration. Primary uses pivoted Pfaffian elimination; the independent oracle uses a subset recurrence over pairings. Official task bound is `N<=300`. Source task and limits only; clean-room code and fixtures. |
| [Dirichlet Convolution and Prefix Sums](https://github.com/yosupo06/library-checker-problems/blob/master/number_theory/dirichlet_convolution_and_prefix_sums/task.md) | [`gcd_convolution`](g/gcd_convolution/README.md) and [`lcm_convolution`](l/lcm_convolution/README.md) combine finite-array coefficients by index GCD/LCM; [`sum_of_multiplicative_function_large`](s/sum_of_multiplicative_function_large/README.md) handles a specified multiplicative-function family. None computes prefix Dirichlet convolution of two arbitrary inputs represented on the floor-quotient set. | Implemented and registered in the shared byte-output suite as `dirichlet_convolution_and_prefix_sums`: bounded `N<=64`, `Q_N={floor(N/x)}` in ascending order, and prefix arrays `F(q),G(q)` for each quotient. Emit all `H(q)=sum_{ij<=q} f(i)g(j) mod 998244353` in the same order. Ten ports, 1024-byte workspace, 120-byte maximum output, workload, README/RIGHTS, structurally independent grouped-f/g oracles, static inventory checker, generated profiles, malformed frames, and capacity probes are present. This is a clean-room bounded O(|Q_N|^2) profile; official task allows `N<=10^12` and requires each supplied prefix residue to lie in `[1,998244353)`. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |
| Lengauer–Tarjan immediate dominators | Implemented as [`lengauer_tarjan_dominator_tree`](l/lengauer_tarjan_dominator_tree/README.md): ten ports use DFS numbering, semidominator buckets, and simple path-compression `LINK`/`EVAL`; the independent oracle finds dominators with vertex-removal reachability. The bounded I/O profile matches `dominator_tree` (`V<=63`, `E<=2047`) so the measured difference is the algorithm: the existing port is a bitset fixed-point data-flow solver, not semidominator/path-compression. Workload, rights/provenance, package-local static checker, and shared byte-output suite registration are present; no programs, tests, checkers, builds, compilers, or benchmarks were run. Source: Lengauer and Tarjan, “A fast algorithm for finding dominators in a flowgraph,” TOPLAS 1(1), 1979, [DOI 10.1145/357062.357071](https://doi.org/10.1145/357062.357071); [author-hosted paper](https://www.cs.princeton.edu/courses/archive/fall03/cs528/handouts/a%20fast%20algorithm%20for%20finding.pdf). Clean-room algorithm description only; no paper code or prose reproduced. |
| Segment tree beats (range chmin, chmax, add, and sum) | Confirmed distinct; ten port drafts and scalar-suite wiring present | Existing point-update segment trees, lazy range structures, and wavelet trees do not implement this same operation set. The original nine ports received static review; the Mojo draft remains unverified. The direct-array oracle, workload, suite-generated maximum and malformed traces, and source inventory validation are registered. No programs, tests, checkers, builds, compilers, or benchmarks were run. [Yosupo range chmin/chmax/add/sum problem](https://judge.yosupo.jp/problem/range_chmin_chmax_add_range_sum). |
| Directed minimum spanning arborescence (Chu–Liu/Edmonds), including [OI Wiki's directed spanning-tree entry](https://en.oi-wiki.org/graph/mdst/) | Already present; no new package | Covered by [`edmonds`](e/edmonds/README.md), with a rooted directed graph contract and minimum-incoming-edge cycle contraction. The OI Wiki entry describes the same algorithm; its description was used for identification only. |
| Minimum enclosing circle | Already present; no new package | [`smallest_circle`](s/smallest_circle/README.md) uses exhaustive support-circle candidates and covers the bounded enclosing-circle task. Ten source drafts are present, including Mojo; the Mojo source has not been verified in this review. |
| Global minimum cut (Stoer–Wagner) | Already present; no new package | Covered by [`stoer_wagner`](s/stoer_wagner/README.md). |
| Convex layers (onion decomposition) | A convex-hull package computes one boundary and does not repeatedly peel the remaining set. | Confirmed distinct; ten language ports, an independent supporting-line oracle, bounded workload, README, and i64-array-scalar runner/verifier registration are present. The package treats duplicate coordinates as one point and removes all collinear boundary points together. Static review only; no program was run. [Algorithm reference](https://arxiv.org/abs/1702.06829). |

## Library Checker candidates in review or implementation

These names appear in the [official Library Checker problem index](https://judge.yosupo.jp/) and had no same-name package in the initial static filename search. Decisions and active package ownership are updated as their contracts are compared against related local algorithms.

| Candidate | Initial local comparison | Status |
| --- | --- | --- |
| Three-edge-connected components | Existing bridges and two-edge-connected-subgraph packages do not compute 3-edge-connected components. | Confirmed distinct; ten drafts, workload, README, oracle, static checker, and scalar-suite wiring are present. Its bounded multigraph contract preserves parallel edge IDs and loops; the Mojo draft remains unverified. [Problem](https://judge.yosupo.jp/problem/three_edge_connected_components). |
| Incremental strongly connected components | Static SCC packages compute a decomposition of a fixed graph; no insertion-only SCC package was found. | Confirmed distinct; ten drafts, workload/oracle, static checker, and scalar-suite integration are present; the Mojo draft remains unverified and no runtime validation was run. |
| st-numbering | No package matching an st-numbering of a biconnected graph was found. | Confirmed distinct; ten drafts, README/workload, deterministic Even–Tarjan oracle, byte-suite wiring, and an independent certificate check are present; the Mojo draft remains unverified and no runtime validation was run. |
| Counting Eulerian circuits | Eulerian path/trail packages construct a traversal; they do not count tours with a fixed first edge. | A ten-port package, independent oracle, workload, and suite registrations are already present in the working tree; `/root/thomas_algorithm` is statically reviewing its contract and coverage. No runtime validation was performed. |
| Counting spanning trees (undirected) | Existing minimum spanning tree algorithms optimize a tree's weight; no spanning-tree counting package was found. | Confirmed distinct; ten drafts, Matrix-Tree implementation, README/workload, static checker, and byte-output suite integration are present; the Mojo draft remains unverified. |
| Counting spanning trees (directed) | Existing [`edmonds`](e/edmonds/README.md) optimizes arborescence weight; the official directed-count task counts outward rooted spanning trees modulo 998244353 and permits parallel edges. No counting package was found. | Confirmed distinct; ten drafts, README/workload, subset-enumeration oracle, static checker, and byte-suite integration are present; the Mojo draft remains unverified and no programs or validation tools were run. |
| Minimum-cost b-flow | `min_cost_max_flow` handles source/sink flow limits, not arbitrary vertex balances and lower bounds. | Confirmed distinct bounded b-flow package with ten ports, primal/dual certificate oracle, and byte-output suite integration. |
| Rooted tree isomorphism classification | Tree traversal, LCA, and centroid packages do not classify rooted trees up to isomorphism. | Confirmed distinct; ten ports, exact-signature primary oracle, recursive independent oracle, workload, and byte-output suite registration complete. Root static review complete; no program, build, test, or checker was run. [Problem](https://judge.yosupo.jp/problem/rooted_tree_isomorphism_classification). |
| Euclidean / Manhattan MST | Generic graph MST packages accept explicit edge lists; [`manhattan_mst`](m/manhattan_mst/README.md) uses implicit L1 Prim, while [`euclidean_mst`](e/euclidean_mst/README.md) generates Delaunay candidates and applies Kruskal. | Both are distinct coordinate-derived MST workloads with different metrics and candidate-generation algorithms. Manhattan MST has scalar-suite coverage; Euclidean MST has ten ports, an exact-predicate workload, complete-graph cycle-property oracle, and byte-suite integration. [Euclidean MST problem](https://judge.yosupo.jp/problem/euclidean_mst), [Manhattan MST problem](https://judge.yosupo.jp/problem/manhattanmst). |
| Eertree / palindromic tree | Existing palindrome and Manacher packages do not expose the online palindromic-tree data structure. | Confirmed distinct and implemented in ten languages, including Mojo; workload and scalar-suite registration are complete. Static-only; no runtime validation was performed. [EERTREE paper](https://arxiv.org/abs/1506.04862). |
| Static Range Mode Query | [`mode`](m/mode/README.md) queries the whole array and cannot answer arbitrary subrange queries; [`wavelet_tree`](w/wavelet_tree/README.md) has range-frequency/quantile operations but no range-mode operation. | Confirmed distinct and implemented with a bounded static block-mode/range-frequency structure, nine standard ports plus optional Mojo, deterministic tie handling, workload, and byte-suite registration; see the [benchmark guide](s/static_range_mode_query/README.md). Static-only; no runtime validation was performed. |
| Gabow path-based strongly connected components | [`tarjan_scc`](t/tarjan_scc/README.md) uses low-link values and one component stack; [`kosaraju`](k/kosaraju/README.md) uses two DFS passes on the graph and its transpose. Neither uses Gabow's preorder boundary stack alongside the active path stack. | Confirmed distinct and implemented in ten clean-room language ports. The package includes primary mutual-reachability and independent Kosaraju oracles, bounded fixtures, rights notes, and a static inventory checker; byte-suite workload validation and deterministic graph probes are wired. Static review only; no programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. [Gabow, 2000](https://doi.org/10.1016/S0020-0190(00)00051-X). |

## Implementation and attribution rules

- Compare the mathematical operation, input/output contract, and relevant behavior before calling two names duplicates. Keep different algorithms or materially different computational tasks separate.
- Write clean-room implementations from algorithm descriptions. Do not copy submissions, tests, problem statements, or other source text. Link the discovery source and record applicable license or terms before reusing any material.
- Record each new candidate here before assigning it. Mark a candidate implemented only after all ten current language ports and suite registration are present; static presence is not runtime validation.
- While compiler profiling is underway, all work remains static. Do not run programs, tests, builds, compilers, benchmarks, or repository scripts.

## Library Checker Enumerative Combinatorics category crosswalk (2026-11-12)

The [official category inventory](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/categories.toml) lists 18 tasks. The task statements specify factorial, derangement, Bell, binomial-prefix, partition, Stirling, subset-count, subsequence-count, and constrained increasing-sequence outputs; matching a number name alone is not treated as algorithm coverage.

| Official task | Local contract comparison | Disposition |
| --- | --- | --- |
| [factorial](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/factorial/task.md), [many_factorials](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/many_factorials/task.md) | The official tasks return n! modulo a shared fixed modulus, with one or many n queries. Local factorial returns exact n! for 0..20. | Same factorial operation; modular reduction and batching are contract changes. |
| [montmort_number_mod](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/montmort_number_mod/task.md) | The official task returns D1 through DN modulo an input modulus. Local derangement returns one exact bounded Dn; it uses D0=D1=0. | Same derangement recurrence; arbitrary-modulus prefix output is not a new algorithm. |
| [bell_number](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/bell_number/task.md) | The official task returns B0 through BN modulo a fixed prime. Local bell_numbers uses Bell's triangle for one exact value. | Same Bell sequence and triangle update; prefix/modulus are output-profile changes. |
| [binomial_coefficient](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/binomial_coefficient/task.md), [binomial_coefficient_prime_mod](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/binomial_coefficient_prime_mod/task.md) | The official tasks compute C(n,k) modulo a fixed arbitrary modulus or prime modulus. Local binomial_coefficient computes exact C(n,k) by Pascal updates on a bounded row. | Same ordinary binomial operation; modular domain differences alone do not establish a distinct algorithm. |
| [prefix_sum_of_binomial_coefficient](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/prefix_sum_of_binomial_coefficient/task.md) | The official task returns `Σ C(N,i)` for `0<=i<=K` modulo 998244353. Local `sum_of_binomial_coefficient` returns only the full-row identity `2^N`; `binomial_coefficient` and `binomial_calculate` return one exact coefficient, and the Pascal-row packages construct or hash bounded rows with addition updates. None implements modular arbitrary-prefix accumulation. | Confirmed distinct and implemented as a bounded prefix operation: ten ports use `C(N,i+1)=C(N,i)*(N-i)/(i+1)` modulo 998244353 and accumulate through K, with `T<=16`, `N<=128`, independent exact-binomial and modular-recurrence oracles, workload/fixtures, rights note, static package checker, and `i64_array_bytes_output` integration. Official limits are T<=200,000 and N<=200,000; the local cap is explicit. No programs, tests, checkers, builds, compilers, or benchmarks were run. |
| [q_binomial_coefficient_prime_mod](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/q_binomial_coefficient_prime_mod/task.md) | No local Gaussian/q-binomial package was found. Ordinary binomial packages do not account for the q-weight on subsets. | Confirmed distinct and implemented as a bounded direct recurrence profile; ten language ports, an independent k-subset oracle, a workload/static checker, and byte-output suite coverage are present. The package caps the official large bounds to T<=16, m<=31, and n,k<=16. |
| [partition_function](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/partition_function/task.md) | The official task returns p0 through pN modulo a fixed prime. Local partitions and integer_partition compute the same integer partition numbers with exact outputs and bounded scalar domains. | Same partition sequence; returning a modular prefix does not by itself add an algorithm. |
| [stirling_number_of_the_second_kind](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/stirling_number_of_the_second_kind/task.md) | The official task returns every S(N,k) modulo 998244353. The new local package computes the complete row for N<=16 and encodes it as a checksum. Local bell_numbers returns only B_N, the sum of the row; partitions and integer_partition count unordered integer-sum partitions, not partitions of a labeled set into exactly k blocks. | Confirmed distinct complete-row recurrence: ten ports compute the modular row and return a documented cubic-weight checksum through i64_array_scalar. Recurrence and independent inclusion-exclusion oracles, workload, rights note, static checker, and suite wiring are present. Root static review complete; no programs, tests, builds, compilers, or checkers were run. |
| [stirling_number_of_the_first_kind](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/stirling_number_of_the_first_kind/task.md), [stirling_number_of_the_first_kind_fixed_k](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/stirling_number_of_the_first_kind_fixed_k/task.md), and [stirling_number_of_the_second_kind_fixed_k](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/stirling_number_of_the_second_kind_fixed_k/task.md) | The first-kind full row uses the signed coefficient recurrence; its fixed-k task and the second-kind fixed-k task return prefixes of the same respective row recurrences. The new S2 profile already builds the complete second-kind row. Local Bell and integer-partition packages compute related numbers but do not return Stirling coefficients. | Duplicate algorithm kernels: sign/multiplier changes and fixed-column output reuse the same triangle DP. No additional package is warranted for these tasks. |
| [stirling_number_of_the_first_kind_small_p_large_n](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/stirling_number_of_the_first_kind_small_p_large_n/task.md), [stirling_number_of_the_second_kind_small_p_large_n](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/stirling_number_of_the_second_kind_small_p_large_n/task.md) | Both official tasks allow n up to 10^18 and batch queries under a shared prime p<=5000. Their info files list only `naive.cpp` with `allow_tle=true`; the task sources define outputs and bounds but do not present efficient kernels. Bell, integer-partition, and full-row S2 packages do not cover large-n fixed-k evaluation. | Both are distinct from bounded row construction. The second-kind task has a bounded matrix-exponentiation profile; the first-kind task has a bounded residue-block coefficient profile. Each has ten ports, workload, dual oracles, rights note, and package-local static checker, preserving n<=10^18 with T<=8 and k<=8. The S2 profile uses primes 11..97; the signed first-kind profile uses primes 11..97 so p-1>k, proving all non-lowest block-power terms are above the requested degree. Both profiles are wired into the `i64_array_scalar` runner/verifier. No programs, tests, builds, compilers, benchmarks, or checkers were run. |
| [sharp_p_subset_sum](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/sharp_p_subset_sum/task.md) | The official task counts indexed subsets of positive values for all target totals. Local subset_sum_count counts indexed subsets for one target by dynamic programming and allows signed values. | Same indexed-subset counting DP family; all-target output and positive bounds are profile differences. |
| [number_of_subsequences](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/number_of_subsequences/task.md) | The official task counts distinct nonempty subsequences of an integer sequence modulo a fixed prime. Local unique_subsequences_count counts distinct nonempty subsequences of an ASCII string. | Same distinct-subsequence recurrence over a different alphabet; domain/output changes alone do not establish a new method. |
| [number_of_increasing_sequences_between_two_sequences](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/number_of_increasing_sequences_between_two_sequences/task.md) | The official task counts nondecreasing x with 0 <= x0 <= ... < M and A_i <= x_i < B_i, modulo a fixed prime. No local package has this per-position constrained-sequence contract. | Confirmed distinct and implemented: bounded `n,m<=64`, ten ports, prefix-sum DP primary oracle, memoized-DFS independent oracle, workload and `i64_array_scalar` runner/verifier integration. Root statically connected suite dispatch and null-input handling; no programs, tests, builds, compilers, benchmarks, or checkers were run. [Official constraints](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/number_of_increasing_sequences_between_two_sequences/info.toml). |

The q-binomial task statement fixes T cases with shared prime m and q, requires 0 <= q < m and 0 <= n,k < min(m,N_MAX), and asks for the Gaussian binomial coefficient modulo m. This local profile caps T at 16, m at 31, and n,k at 16; it retains the prime and range rules while using G(n,k)=G(n-1,k)+q^(n-k)G(n-1,k-1) modulo m. The bounded profile is not a claim to meet the official large-N limits. See [the official q-binomial task](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/q_binomial_coefficient_prime_mod/task.md) and [its bounds](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/q_binomial_coefficient_prime_mod/info.toml).

## Library Checker Big Integer and linear recurrence crosswalk (2026-11-12)

The [official category inventory](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/categories.toml) lists six Big Integer tasks and seven tasks under Other. This crosswalk compares the big-integer operations, the three linear-recurrence tasks, and two weighted power-sum tasks by operation rather than name; `two_sat` and `longest_increasing_subsequence` are already covered locally. The new signed decimal addition profile is bounded to 32 decimal digits per operand and is not a claim to cover the official multi-million-digit limits.

| Official task | Local contract comparison | Disposition |
| --- | --- | --- |
| [addition_of_big_integers](https://github.com/yosupo06/library-checker-problems/blob/master/big_integer/addition_of_big_integers/task.md) | `binary_addition` adds unsigned bit strings; `big_integer_multiply` multiplies canonical unsigned decimal strings; neither parses signed decimal magnitudes or selects between addition and subtraction. | Confirmed distinct and implemented: bounded canonical signed decimal addition, ten language ports, digit-array primary oracle, arbitrary-precision independent oracle, workload/fixtures, rights note, package-local static checker, and `i64_array_bytes_output` integration. Suite wiring was statically reviewed; no programs, tests, builds, compilers, benchmarks, or checkers were run. |
| [multiplication_of_big_integers](https://github.com/yosupo06/library-checker-problems/blob/master/big_integer/multiplication_of_big_integers/task.md) | `big_integer_multiply` already performs canonical decimal digit-array multiplication; the official task's signed operands and much larger bounds alter domain/scale, not the core multiplication algorithm family. | Covered at algorithm-family level; do not add a radix/sign alias package. |
| [division_of_big_integers](https://github.com/yosupo06/library-checker-problems/blob/master/big_integer/division_of_big_integers/task.md) | `long_division` performs decimal digit-by-digit quotient extraction by repeated subtraction; it is bounded to machine integers and returns quotient only, while the official task has arbitrary-length nonnegative operands and also returns remainder. | Existing division algorithm family; quotient/remainder and size are contract extensions, not a separate method for this inventory decision. |
| [addition_of_hex_big_integers](https://github.com/yosupo06/library-checker-problems/blob/master/big_integer/addition_of_hex_big_integers/task.md) | Binary string addition uses a positional carry pass. Changing the alphabet/radix to hexadecimal preserves the same carry-propagation operation. | Same carry algorithm family; no radix-only package. |
| [multiplication_of_hex_big_integers](https://github.com/yosupo06/library-checker-problems/blob/master/big_integer/multiplication_of_hex_big_integers/task.md) | `big_integer_multiply` implements schoolbook digit-array multiplication in base ten. Hexadecimal changes the digit alphabet and carry radix, not the multiplication algorithm. | Same multiplication algorithm family; no radix-only package. |
| [division_of_hex_big_integers](https://github.com/yosupo06/library-checker-problems/blob/master/big_integer/division_of_hex_big_integers/task.md) | `long_division`'s repeated-subtraction long-division procedure is the same digit-quotient algorithm after changing the radix; its local contract is much smaller and returns quotient only. | Same long-division family; no radix-only package. |
| [find_linear_recurrence](https://github.com/yosupo06/library-checker-problems/blob/master/other/find_linear_recurrence/task.md) | `berlekamp_massey` uses the same minimum-order recurrence inference over modulus 998244353; the local profile supplies exactly 2K terms with K<=8, while the official task allows N<=10,000. | Covered by the Berlekamp–Massey algorithm family; bounds and corpus shape do not create a new operation. |
| [kth_term_of_linearly_recurrent_sequence](https://github.com/yosupo06/library-checker-problems/blob/master/other/kth_term_of_linearly_recurrent_sequence/task.md) | `linear_recurrence_matrix` computes a requested recurrence term by exponentiating a transition matrix. Companion-matrix construction and larger official order/index bounds do not introduce a different algorithm family. | Covered by matrix exponentiation for a supplied recurrence. |
| [consecutive_terms_of_linear_recurrent_sequence](https://github.com/yosupo06/library-checker-problems/blob/master/other/consecutive_terms_of_linear_recurrent_sequence/task.md) | Repeated application of the supplied recurrence after computing the starting term extends the local kth-term operation with a contiguous output window. | Same recurrence-evaluation family; no separate algorithm package. |
| [sum_of_exponential_times_polynomial](https://github.com/yosupo06/library-checker-problems/blob/master/other/sum_of_exponential_times_polynomial/task.md) | Local `power_sum` counts subsets of integer powers, while polynomial power-sum packages evaluate unweighted sums; none computes a finite geometric-weighted moment `Σ r^i i^d` for huge `n`. | Confirmed distinct and implemented: ten ports use binary composition of weighted-moment blocks in O(d² log n), with an independent rational-tail/Faulhaber oracle, workload, rights note, and static package checker. The scalar runner/verifier register fixture agreement, random and boundary profiles, null input, and malformed frames. The bounded profile has `d<=32`, `n<=10^18`, and includes both `r=0` and `r=1`; keep it separate from the infinite-limit formula below. [Task limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/other/sum_of_exponential_times_polynomial/info.toml). |
| [sum_of_exponential_times_polynomial_limit](https://github.com/yosupo06/library-checker-problems/blob/master/other/sum_of_exponential_times_polynomial_limit/task.md) | No local package evaluates the convergent limit `Σ r^i i^d` for the rational lift `|r|<1`; this is not an unweighted power sum. Its Eulerian-polynomial formula omits the finite-`n` correction used by the previous task. | Confirmed distinct and implemented as a bounded Eulerian-row profile: ten ports, independent Stirling-number verifier, workload, rights note, and static package checker are present. The scalar runner/verifier now register the oracle, workload validation, Eulerian/Stirling comparison cases, maximum degree, and malformed inputs. `r` is in `[0,998244353)\{1}`, `d<=256`; keep separate from finite geometric sums because the evaluated formula and work scale differ. [Task limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/other/sum_of_exponential_times_polynomial_limit/info.toml). |

The signed-addition workload derives from the official statement's mathematical operation, while its byte ABI, validation rules, and 32-digit cap are local benchmark choices. The upstream problem repository is Apache-2.0; this project uses task metadata only for discovery and writes independent code and fixture data. See the [official repository license](https://github.com/yosupo06/library-checker-problems/blob/master/LICENSE), [addition task](https://github.com/yosupo06/library-checker-problems/blob/master/big_integer/addition_of_big_integers/task.md), and [limits](https://github.com/yosupo06/library-checker-problems/blob/master/big_integer/addition_of_big_integers/info.toml).

## CP-Algorithms miscellaneous additions (2026-11-12)

| Algorithm | Local contract comparison | Disposition |
| --- | --- | --- |
| [Tortoise and Hare cycle finding](https://cp-algorithms.com/others/tortoise_and_hare.html) | `floyd_warshall` computes all-pairs shortest paths in a weighted graph; `negative_cycle_detection` detects negative-weight cycles by relaxation. Neither follows one successor function to recover its preperiod and cycle lengths with constant auxiliary storage. No Floyd/Brent functional-graph cycle-parameter package was found. | Implemented and registered as [`functional_graph_cycle_parameters`](f/functional_graph_cycle_parameters/README.md) in ten ports. Bounded scalar input `[N,start,next[0..N))`, `1<=N<=64`, every successor in `[0,N)`; result `65*mu+lambda` encodes the preperiod and eventual cycle length. The primary uses constant-space tortoise/hare; the independent oracle records first-seen positions. Workload, README/RIGHTS, package static checker, scalar runner/verifier integration, and catalog entry are present. CP-Algorithms is CC BY-SA 4.0; algorithm description only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## CP-Algorithms tree additions (2026-11-12)

| Algorithm | Local contract comparison | Disposition |
| --- | --- | --- |
| [Tree painting](https://cp-algorithms.com/graph/tree_painting.html) | No local package paints tree edges idempotently and then answers the number of painted edges on arbitrary vertex-to-vertex paths. Existing dynamic-tree profiles update vertex/path aggregates; LCA and HLD packages answer different queries. | Implemented and registered as [`tree_edge_paint_path_count`](t/tree_edge_paint_path_count/README.md). Bounded scalar input `[N,Q,(u,v)^(N-1),(op,a,b)^Q]`, `1<=N<=16`, `0<=Q<=32`; valid/parseable input lengths are 128/129 words and checksum range is 0..255. Type 0 paints edge ID `a` (with `b=0`), type 1 queries vertices `(a,b)`. Return the sum of query answers. Primary uses the two directional DFS-tour edge arrays and segment trees described by CP-Algorithms; the independent oracle uses BFS to reconstruct each query path directly. Ten language ports, workload, docs/rights, static package checker, and scalar runner/verifier integration are present. The article is CC BY-SA 4.0; clean-room algorithm description only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## CP-Algorithms geometry additions (2026-11-12)

| Algorithm | Local contract comparison | Disposition |
| --- | --- | --- |
| [Pick's theorem for lattice polygons](https://cp-algorithms.com/geometry/picks-theorem.html) | [`polygon_points`](p/polygon_points/README.md) already returns strictly interior lattice-point count from polygon area and boundary lattice points; [`area_of_polygon`](a/area_of_polygon/README.md) supplies the related shoelace area and is not the canonical count package. | Covered: `polygon_points` already implements Pick's theorem as `interior = area + 1 - boundary/2` for simple nonzero-area lattice polygons, with ten language ports and an independent oracle. A second package would benchmark the same theorem and operation; no new candidate is added. CP-Algorithms provides an independent description of the same Pick formula; no new source code is needed. |
| [Circle-circle intersection](https://cp-algorithms.com/geometry/circle-circle-intersection.html) | [`circle_line_intersection_count`](c/circle_line_intersection_count/README.md) classifies one supplied line against one circle, while [`common_tangents_two_circles`](c/common_tangents_two_circles/README.md) counts lines tangent to two circles. Neither constructs the radical axis from two circle equations or classifies their shared circumference points, including coincident circles. | Implemented and registered as [`circle_circle_intersection_count`](c/circle_circle_intersection_count/README.md) in ten languages. Scalar input is `[x1,y1,r1,x2,y2,r2]`, with center coordinates in `[-1000,1000]`, radii in `[1,1000]`, exact length 6 and parseable length 7. Return 0 for disjoint circles, 1 for tangency, 2 for two intersection points, and 3 when the circles coincide (infinitely many common points); malformed input returns `-1`. The primary subtracts the circle equations to form the radical-axis line and classifies its intersection with the first circle using an exact integer discriminant. An independent squared-distance oracle, ten ports, workload, README/RIGHTS, package-local static inventory checker, scalar runner/verifier registration, generated threshold-boundary and random profiles, malformed frames, and null-input handling are present. Center/radius limits keep all arithmetic in signed 64-bit range. CP-Algorithms is CC BY-SA 4.0; clean-room algorithm description only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |
| [Common tangents to two circles](https://cp-algorithms.com/geometry/tangents-to-two-circles.html) | Existing circle area/perimeter, rasterization, smallest-enclosing-circle, and Voronoi/Delaunay packages produce different results. The separately reserved circle-line intersection profile handles one line against one circle, not tangent lines shared by two circles. No package counts the distinct common tangent lines for a circle pair. | Implemented as [`common_tangents_two_circles`](c/common_tangents_two_circles/README.md) in ten languages. Contract: scalar input `[x1,y1,r1,x2,y2,r2]`, integer coordinates in `[-100000,100000]`, radii in `[0,100000]`, distinct centers; return 0..4 distinct tangent lines. The primary enumerates four signed-radius discriminants and collapses coincident candidates at tangency; an independent oracle compares exact squared-distance thresholds. Workload, README/RIGHTS, static package checker, and shared scalar-suite integration are present. Source: [CP-Algorithms — Common tangents to two circles](https://cp-algorithms.com/geometry/tangents-to-two-circles.html), CC BY-SA 4.0; algorithm description only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |
| [Circle-line intersection](https://cp-algorithms.com/geometry/circle-line-intersection.html) | [`circle`](c/circle/README.md) computes perimeter/area; [`line_intersection`](l/line_intersection/README.md) intersects two lines or segments; [`smallest_circle`](s/smallest_circle/README.md) encloses a point set, and [`voronoi_delaunay_empty_circle`](v/voronoi_delaunay_empty_circle/README.md) constructs Delaunay adjacency. None classifies a line against a supplied circle. The separate `common_tangents_two_circles` algorithm counts lines tangent to both circles. | Implemented and registered as [`circle_line_intersection_count`](c/circle_line_intersection_count/README.md): byte input `[cx,cy,r,Q,(a,b,c)*Q]`, `0<=Q<=32`, center coordinates in `[-1000,1000]`, radius `0..1000`, line coefficients `a,b` in `[-100,100]` (not both zero), `c` in `[-200000,200000]`; return 0/1/2 real intersection points per line. Ten ports compare the exact translated line-distance discriminant; an independent oracle parameterizes each line and checks its quadratic discriminant, with an explicit vertical-line branch. Workload, README/RIGHTS, static inventory checker, byte-output runner/verifier integration, generated line batches, max-output trace, malformed frames, and output-capacity profiles are included. Source: [CP-Algorithms — Circle-Line Intersection](https://cp-algorithms.com/geometry/circle-line-intersection.html), CC BY-SA 4.0; algorithm description only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## CP-Algorithms dynamic programming additions (2026-11-12)

| Algorithm | Local contract comparison | Disposition |
| --- | --- | --- |
| [Finding the largest zero submatrix](https://cp-algorithms.com/dynamic_programming/zero_matrix.html) | [`largest_rectangle_histogram`](l/largest_rectangle_histogram/README.md) accepts a precomputed one-dimensional height vector and returns its largest rectangle; it does not update nearest-blocker heights for each binary-matrix row. [`set_matrix_zeroes`](s/set_matrix_zeroes/README.md) mutates rows/columns that contain zeros and does not search for a rectangle. | Implemented and registered as [`largest_zero_submatrix`](l/largest_zero_submatrix/README.md): scalar input `[R,C,row_major_binary_cells...]`, `1<=R,C<=16`, cells in `{0,1}`, exact length `2+R*C`; return the maximum area of an all-zero axis-aligned submatrix, including zero if the matrix has no zero cell. Ten ports maintain the last-one row per column and use left/right monotone-stack blocker scans for each row; the independent exhaustive rectangle oracle checks each candidate directly. Workload, README/RIGHTS, static inventory checker, scalar runner/verifier registration, generated matrices, maximum all-zero input, malformed frames, and null-input profile are included. The one-dimensional monotone-stack primitive is shared with the histogram benchmark, but the row-wise 2-D update and rectangle search are the distinct workload. Source: [CP-Algorithms — Finding the largest zero submatrix](https://cp-algorithms.com/dynamic_programming/zero_matrix.html), CC BY-SA 4.0; algorithm description only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## CP-Algorithms combinatorics additions (2026-11-12)

| Algorithm | Local contract comparison | Disposition |
| --- | --- | --- |
| [Binomial coefficient modulo a prime power](https://cp-algorithms.com/combinatorics/binomial-coefficients.html#binomial-coefficient-modulo-prime-power) | [`ncr_modulo_p`](n/ncr_modulo_p/README.md) builds a factorial table and attempts an ordinary modular inverse; for composite moduli, the denominator may be noninvertible and the source contract returns `-1` rather than the true coefficient. Exact `binomial_coefficient` and Pascal-row packages do not handle modular prime-power cancellation. | **Package and byte-output suite registration complete** as `binomial_coefficient_prime_power`. The bounded contract is `[p,e,Q,(n,k)*Q]`, where `p` is prime in `2..31`, `1<=e<=8`, `p^e<=1,000,000,000`, `0<=Q<=32`, and `0<=k<=n<=128`; emit one little-endian u32 residue modulo `p^e` per query and return the output byte count. The primary precomputes p-adic factorial valuations and p-free factorial parts, then inverts only p-free units; an independent Pascal recurrence computes the same bounded coefficients without modular division. Maximum valid input is 67 i64 words, maximum parseable input is 68 words, output is 128 bytes, and reserved workspace is 2560 bytes. Ten language ports, workload, package README/RIGHTS, and static inventory checker are present. Source: [CP-Algorithms — Binomial coefficient modulo prime power](https://cp-algorithms.com/combinatorics/binomial-coefficients.html#binomial-coefficient-modulo-prime-power), CC BY-SA 4.0; use the algorithm description only. Root README/CATALOG suite entries are handled by the root agent. |

## CP-Algorithms number-system additions (2026-11-12)

| Algorithm | Local contract comparison | Disposition |
| --- | --- | --- |
| [Balanced ternary](https://cp-algorithms.com/algebra/balanced-ternary.html) | [`any_base_to_any_base`](a/any_base_to_any_base/README.md) and [`decimal_to_any_base`](d/decimal_to_any_base/README.md) use ordinary nonnegative digits in radix 2 through 36. [`base_neg2_conversion`](b/base_neg2_conversion/README.md) uses radix -2 and digits 0/1. None represents signed integers in radix +3 with digits -1,0,1 and carry normalization. | Implemented and registered as [`balanced_ternary_conversion`](b/balanced_ternary_conversion/README.md): byte-output input `[value]` for any signed i64; output canonical ASCII balanced-ternary digits most-significant first, using `Z` for -1, `0`, and `1` (maximum 41 bytes). Invalid input returns `-1`; null or insufficient output capacity returns `-2`. Ten ports, workload, README/RIGHTS, package-local static inventory checker, byte-output runner/verifier integration, and generated signed values plus capacity/malformed-input profiles are included. The primary uses signed quotient/remainder normalization; the independent oracle converts the magnitude to ordinary ternary, propagates carries from each `2`, and inverts digits for a negative value. Source: [CP-Algorithms — Balanced Ternary](https://cp-algorithms.com/algebra/balanced-ternary.html), CC BY-SA 4.0; algorithm description only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## Encyclopedia of Algorithms scheduling additions (2026-11-12)

| Algorithm | Local contract comparison | Disposition |
| --- | --- | --- |
| [Online Load Balancing of Temporary Tasks](https://doi.org/10.1007/978-1-4939-2864-4_206) | [`list_scheduling`](l/list_scheduling/README.md) assigns permanent jobs by the least-current-load rule; it has no task arrivals, durations, or load departures. The Encyclopedia chapter's identical-machine temporary-task variant preserves that greedy choice at each arrival but changes the load state to the sum of currently active tasks and reports peak load over time. This is a distinct bounded event-trace contract, not a claim that the selection rule itself differs. | Package complete and registered as [`online_temporary_task_load_balancing`](o/online_temporary_task_load_balancing/README.md): byte-output input `[machine_count,task_count,(arrival,weight,duration)*task_count]`, sorted nondecreasing arrival times, task order breaks simultaneous-arrival ties, and a task is active on `[arrival,arrival+duration)`. Tasks completing at a time are removed before arrivals at that time. The deterministic online rule assigns each task irrevocably to a currently least-loaded identical machine, breaking machine ties by lowest ID; output is `[peak_active_load,assigned_machine_ids...]`. Ten ports, primary expiration-heap oracle, independent history-replay verifier, workload, README/RIGHTS, static package checker, and byte-output runner/verifier registration are complete. Source: Leah Epstein, *Encyclopedia of Algorithms*, DOI [10.1007/978-1-4939-2864-4_206](https://doi.org/10.1007/978-1-4939-2864-4_206); algorithm description only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## Encyclopedia of Algorithms geometry additions (2026-11-12)

| Algorithm | Local contract comparison | Disposition |
| --- | --- | --- |
| [Optimal Triangulation — min-max length objective](https://doi.org/10.1007/978-1-4939-2864-4_715) | [`delaunay_triangulation`](d/delaunay_triangulation/README.md) optimizes the max-min-angle/Delaunay outcome, while [`ear_clipping_polygon_triangulation`](e/ear_clipping_polygon_triangulation/README.md) emits a triangulation without minimizing its longest edge. No local contract optimizes the maximum edge length of a triangulation. | Implemented and scalar-suite registered as [`convex_polygon_minimax_length_triangulation`](c/convex_polygon_minimax_length_triangulation/README.md): input `[N,(x,y)*N]`, `3<=N<=12`, vertices in strict convex boundary order, integer coordinates in `[-1000,1000]`, exact length `1+2N` (25 maximum valid, 26 parseable). It returns the minimum possible maximum squared Euclidean edge length. Ten ports, interval minimax primary oracle, independent exhaustive triangulation oracle, workload, README/RIGHTS, static package checker, scalar runner/verifier integration, and generated convex inputs plus malformed-frame profiles are included. This bounded convex-position profile addresses the chapter's min-max-length objective without claiming its cited general point-set O(n²) algorithm. Source: Tiow-Seng Tan, *Encyclopedia of Algorithms*, DOI [10.1007/978-1-4939-2864-4_715](https://doi.org/10.1007/978-1-4939-2864-4_715); use algorithm objective/description only. |

## Encyclopedia of Algorithms predecessor-structure additions (2026-11-12)

| Algorithm | Local contract comparison | Disposition |
| --- | --- | --- |
| [Predecessor Search, String Algorithms and Data Structures](https://doi.org/10.1007/978-1-4939-2864-4_632) — Willard x-fast trie | [`veb_tree`](v/veb_tree/README.md) is a recursive van Emde Boas set with updates and strict successor/predecessor; [`predecessor_problem`](p/predecessor_problem/README.md) is a mutable packed-bitset set. Neither uses the x-fast trie’s per-prefix directories and longest-existing-prefix search. | Package complete and scalar-suite registered as [`x_fast_trie_static_predecessor`](x/x_fast_trie_static_predecessor/README.md). Input `[N,Q,keys[N],queries[Q]]`, `0<=N,Q<=24`, distinct keys and queries in `[0,65535]`; return `Σ(i+1)*(pred(query[i])+1)`, with missing predecessor `-1` contributing zero and exact hits returning the key. Empty key sets and zero-query batches return zero. Ten ports, primary per-prefix-directory oracle, independent sorted-array upper-bound oracle, workload, README/RIGHTS, static inventory checker, and runner/verifier integration are present. The bounded implementation uses sorted prefix directories in place of hash tables and does not claim the original expected O(log log U) query bound. Source: Djamal Belazzougui, *Encyclopedia of Algorithms*, DOI [10.1007/978-1-4939-2864-4_632](https://doi.org/10.1007/978-1-4939-2864-4_632), which surveys predecessor structures and cites Willard's x-fast/y-fast trie; clean-room algorithm description only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## CP-Algorithms miscellaneous additions (2026-11-12)

| Algorithm | Local contract comparison | Disposition |
| --- | --- | --- |
| [15 Puzzle Game: Existence Of The Solution](https://cp-algorithms.com/others/15-puzzle.html) | [`a_star_search`](a/a_star_search/README.md) provides a general graph-search path API and uses a sliding-puzzle state only as one example; it does not classify arbitrary 4×4 puzzle permutations by the invariant preserved by legal moves. No local package returns reachability parity for the standard 15-puzzle goal state. | Implemented and scalar-suite registered as [`fifteen_puzzle_solvability`](f/fifteen_puzzle_solvability/README.md). `i64_array_scalar` input is exactly 16 row-major cells containing a permutation of `0..15` (`0` is blank); return `1` iff the goal `[1,2,...,15,0]` is reachable, else `0`, and `-1` for a malformed/non-permutation frame. Ten clean-room ports, workload, README/RIGHTS, static inventory checker, primary inversion/row oracle, and independent full-permutation-cycle/blank-color oracle are present. Maximum valid/parseable input lengths are 16/17 i64 values. Source: [CP-Algorithms — 15 Puzzle Game: Existence Of The Solution](https://cp-algorithms.com/others/15-puzzle.html), CC BY-SA 4.0; use the high-level invariant only and implement independently. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## CP-Algorithms data-structure additions (2026-11-12)

| Algorithm | Local contract comparison | Disposition |
| --- | --- | --- |
| [Minimum Stack / Minimum Queue — queue modification, method 3](https://cp-algorithms.com/data_structures/stack_queue_modification.html#queue-modification-method-3) | [`queue_using_two_stacks`](q/queue_using_two_stacks/README.md) implements FIFO enqueue/dequeue/peek but stores no per-stack minima or minimum query. [`min_stack`](s/min_stack/README.md) and [`min_stack_using_two_stacks`](m/min_stack_using_two_stacks/README.md) provide LIFO minimum queries, not a queue. [`monotonic_queue`](m/monotonic_queue/README.md) computes sliding-window maxima with a candidate deque, which is a different operation and state invariant. No package implements amortized FIFO minimum queries by combining two minimum-augmented stacks. | Implemented as [`minimum_queue_two_stacks`](m/minimum_queue_two_stacks/README.md), registered in the `i64_array_scalar` suite. Input is `[Q,(opcode[,value])...]`, with `0<=Q<=32`, queue capacity 16, and enqueued values in `[-1000,1000]`; opcode 0 enqueues one value, opcode 1 dequeues and reports the removed value, and opcode 2 reports the current minimum. Empty dequeue/minimum query, overflow, unknown opcode, malformed framing, or out-of-range values return `-1`. The scalar checksum weights each dequeue/minimum result by operation position and remaining FIFO values by queue position, using offset 1001. The primary uses input/output stacks augmented with prefix minima; the independent oracle simulates a direct FIFO list and scans it for each minimum query. Maximum valid/parseable input lengths are 57/65 i64 values; fixed stack/value/minimum arrays declare 512 bytes of workspace. Source: [CP-Algorithms — Minimum Stack / Minimum Queue](https://cp-algorithms.com/data_structures/stack_queue_modification.html), CC BY-SA 4.0; use the high-level method description only. Work was source-only; no programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## OI Wiki numerical-integration additions (2026-11-12)

| Algorithm | Local contract comparison | Disposition |
| --- | --- | --- |
| [Adaptive Simpson quadrature](https://en.oi-wiki.org/math/integral/#245) | Local [`simpson_integration`](s/simpson_integration/README.md), [`simpson_rule`](s/simpson_rule/README.md), [`composite_simpson_rule`](c/composite_simpson_rule/README.md), and [`integration_by_simpson_approx`](i/integration_by_simpson_approx/README.md) use predetermined uniform sample counts. None estimates local error from a whole-interval Simpson estimate versus its two half-interval estimates and recursively refines only intervals that exceed a requested tolerance. | Complete and registered as [`adaptive_simpson_quadrature`](a/adaptive_simpson_quadrature/README.md) in `float64_slice_io`. Input `[function_id,a_micro,b_micro,tolerance_exponent,max_depth]` uses five exact integer-valued finite float64 fields, with a 6-value parseable cap; endpoint scale is 1,000,000 and endpoints lie in `[-2,000,000,2,000,000]`; functions are `x^4`, `sin(x)`, and `1/(1+x^2)`; tolerance is `10^-e` for `7<=e<=8`, depth is `8..12`, and output is one corrected estimate with `delta/15`, checked at absolute/relative `1e-7`. Ten ports, recursive primary oracle, closed-form independent oracle, workload, README/RIGHTS, static inventory checker, and float64_slice_io runner/verifier wiring are present. Source: [OI Wiki — Numerical Integration, Adaptive Simpson section](https://en.oi-wiki.org/math/integral/#245); algorithm description only. The default terms are CC BY-SA 4.0 and SATA ([FAQ](https://www.timothywang.ca/OI-wiki/intro/faq/)); no code or task prose copied. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## OI Wiki offline-search additions (2026-11-12)

| Algorithm | Local contract comparison | Disposition |
| --- | --- | --- |
| [Overall / parallel binary search](https://en.oi-wiki.org/misc/parallel-binsearch/) | [`fenwick_tree`](f/fenwick_tree/README.md) supports online point-add/range-sum operations and [`lazy_segment_tree_range_add_sum`](l/lazy_segment_tree_range_add_sum/README.md) supports online range-add/range-sum operations; neither batches many monotone first-threshold-time searches offline. [`mos_algorithm`](m/mos_algorithm/README.md) answers static ranges, while [`range_parallel_unionfind`](u/range_parallel_unionfind/README.md) uses a time segment tree and rollback DSU for connectivity. No `parallel_binary_search` or `overall_binary_search` package or ledger entry was found. | Implemented and registered as [`parallel_binary_search_range_threshold`](p/parallel_binary_search_range_threshold/README.md) in `i64_array_scalar`. Input `[N,M,Q,(L,R,delta)*M,(L,R,target)*Q]`; `1<=N<=16`, `0<=M,Q<=32`, all ranges are inclusive and zero-based with `0<=L<=R<N`, deltas are nonnegative in `0..1000`, and thresholds are in `1..512000`. For each query, find the earliest prefix length `t in [0,M]` whose accumulated range sum reaches its threshold, or return `M+1` if no prefix reaches it. The scalar result is `sum((i+1)*(answer_i+1))`; the maximum valid/parseable input lengths are 195/196 i64 values, result range is 0..17952, and workspace is 4096 bytes. Ten language ports, workload, primary batched midpoint/Fenwick oracle, independent per-query replay-and-scan oracle, README/RIGHTS, package-local static inventory checker, and `i64_array_scalar` runner/verifier registration are complete. Source: [OI Wiki — Overall / Parallel Binary Search](https://en.oi-wiki.org/misc/parallel-binsearch/); the default article terms are CC BY-SA 4.0 and SATA ([FAQ](https://www.timothywang.ca/OI-wiki/intro/faq/)). Clean-room method description only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## OI Wiki divide-and-conquer additions (2026-11-12)

| Algorithm | Local contract comparison | Disposition |
| --- | --- | --- |
| [CDQ divide and conquer — 3D partial order](https://www.timothywang.ca/OI-wiki/misc/cdq-divide/) | [`pareto_optimization`](p/pareto_optimization/README.md) removes rows dominated on an arbitrary set of criteria and emits the surviving frontier in input order; it does not count, for each point, every other input point dominated across three ordered coordinates. [`fenwick_tree`](f/fenwick_tree/README.md) is only the underlying point-add/prefix-sum structure. No CDQ or three-dimensional dominance-count package/reservation was found. | Implemented and registered as [`cdq_three_dimensional_dominance`](c/cdq_three_dimensional_dominance/README.md) in `i64_array_scalar`. Input `[N,(x,y,z)*N]`, `1<=N<=64`, each coordinate in `[-1000,1000]`, exact length `1+3*N` (maximum valid/parseable lengths 193/194 i64 values). For each original point i, count other input indices j with `x[j]<=x[i]`, `y[j]<=y[i]`, and `z[j]<=z[i]`; exact coordinate duplicates count with multiplicity except the point itself. Return `sum((i+1)*count[i])`, with range `0..131040`; invalid input returns `-1`; workspace is 8192 bytes. Ten language ports use lexicographically grouped points and CDQ cross-pair merging on y with a multiplicity-weighted Fenwick prefix sum on compressed z. The primary oracle uses CDQ/Fenwick; the independent oracle checks every ordered point pair directly. Source: [OI Wiki — CDQ Divide and Conquer](https://www.timothywang.ca/OI-wiki/misc/cdq-divide/), specifically its 3D partial-order example; default terms are CC BY-SA 4.0 and SATA ([FAQ](https://www.timothywang.ca/OI-wiki/intro/faq/)). Clean-room algorithm description only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## Encyclopedia of Algorithms SVM addition (2026-11-12)

| Algorithm | Local contract comparison | Disposition |
| --- | --- | --- |
| [Support Vector Machines — SMO pair update](https://doi.org/10.1007/978-1-4939-2864-4_415) | Local [`support_vector_classifier`](s/support_vector_classifier/README.md) trains with a projected-gradient coefficient solver and returns classifier predictions. It does not perform SMO's analytic two-variable dual subproblem update or update the bias from the selected pair. No local `smo`/pair-step profile was found. | Complete as [`smo_dual_pair_update`](s/smo_dual_pair_update/README.md), registered in `float64_slice_io`. The call performs one Platt SMO pair update for a supplied feasible dual state, linear feature vectors, bias, and selected distinct indices. Input `[N,D,C_milli,b_milli,labels[N],alpha_milli[N],X[N*D],i,j]` uses exact integer-valued finite float64 entries; `2<=N<=8`, `1<=D<=3`, `1<=C_milli<=5000`, `|b_milli|<=1000000`, labels are ±1 with both classes present, `0<=alpha_milli[k]<=C_milli`, and `sum(labels[k]*alpha_milli[k])=0`; integer features lie in `[-32,32]`, indices are distinct and in range. Exact input length is `6+2*N+N*D` (maximum valid/parseable lengths 46/47). Output is `[alpha'[0..N), b']` with up to 9 float64 values and 1e-12 absolute/relative tolerance; malformed input returns -1 and a valid input with null/short output returns -2. The primary follows SMO's eta/clipping and endpoint handling; the independent oracle maximizes the pair-restricted dual objective directly over feasible interval candidates. The ten ports, workload, README/RIGHTS, static package checker, and float64_slice_io runner/verifier registration are present. This package benchmarks one pair-update step only, not the full SMO training loop. Source discovery: Cristianini and Ricci, *Support Vector Machines*, DOI [10.1007/978-1-4939-2864-4_415](https://doi.org/10.1007/978-1-4939-2864-4_415), and John C. Platt, [“Sequential Minimal Optimization: A Fast Algorithm for Training Support Vector Machines,” MSR-TR-98-14](https://www.microsoft.com/en-us/research/publication/sequential-minimal-optimization-a-fast-algorithm-for-training-support-vector-machines/). Clean-room algorithm description only; no code or prose copied. Source-only static work; no programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## Exact linear algebra algorithm reservation (2026-11-12)

| Algorithm | Local contract comparison | Reservation |
| --- | --- | --- |
| Bareiss fraction-free determinant | [`determinant`](d/determinant/README.md) recursively expands cofactors, while modular determinant packages use field elimination, Euclidean row transformations, packed GF(2) elimination, or sparse Wiedemann/Krylov processing. No package uses Bareiss's Sylvester-identity recurrence to compute an exact integer determinant with fraction-free cubic elimination. The existing Library Checker matrix-determinant crosswalk covers cofactor and modular elimination, and explicitly leaves room only for a materially different method; this exact integer-preserving recurrence qualifies. | Implemented and `i64_array_scalar` suite registered as [`bareiss_determinant`](b/bareiss_determinant/README.md). Input `[N,row-major N*N entries]`, `1<=N<=8`, entries in `[-4,4]`; return the exact signed determinant or `INT64_MIN` for malformed framing/domain. Maximum valid/parseable lengths are 65/66 i64 values, determinant magnitude is at most 268435456 by Hadamard's bound, and declared workspace is 4096 bytes. The primary uses pivoted Bareiss fraction-free elimination with exact division by the preceding pivot; the independent oracle uses signed Leibniz permutation expansion. All ten language ports, workload, README/RIGHTS, static package checker, and scalar runner/verifier registration are complete. Source: Erwin H. Bareiss, “Sylvester's identity and multistep integer-preserving Gaussian elimination,” *Mathematics of Computation* 22(103), 1968, [official AMS paper](https://www.ams.org/mcom/1968-22-103/S0025-5718-1968-0226829-0/S0025-5718-1968-0226829-0.pdf), DOI [10.1090/S0025-5718-1968-0226829-0](https://doi.org/10.1090/S0025-5718-1968-0226829-0). Algorithm description only; implementations and workloads are clean-room. Static source review only; no programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## Ridders root-finding reservation (2026-11-12)

| Algorithm | Local contract comparison | Reservation |
| --- | --- | --- |
| [Ridders' method](https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.ridder.html) | `brent_method` uses inverse-quadratic/secant interpolation with bisection safeguards; `false_position` uses a chord intercept, while the bisection, secant, and Newton packages use their respective interval-halving, two-point, and derivative-based updates. No local package or reservation uses Ridders' midpoint-based exponential interpolation formula. These packages share the broad objective of scalar root finding, but the iterative methods and required per-step computations are distinct. | Implemented and registered as [`ridders_root_finding`](r/ridders_root_finding/README.md) in `float64_slice_io`. The five exact integer-valued finite float64 fields are `[function_id,left_milli,right_milli,tolerance_micro,max_iterations]`; fixed polynomial callbacks are `x^2-2`, `x^3-2`, `x^3+x-1`, and `x`; endpoints are scaled by 1,000 and bounded to `[-3000,3000]`, tolerance is `tolerance_micro/1,000,000`, and the iteration limit is 24..32. Endpoint roots return directly; a midpoint root returns immediately; otherwise each step uses the Ridders radicand and rejects a nonpositive/nonfinite radicand, zero/nonfinite denominator, or out-of-bracket candidate as numerical failure. The sign-changing bracket is preserved, and its midpoint is returned once its width reaches tolerance. Malformed/unbracketed input returns -1, output capacity errors return -2, and a valid bracket that misses tolerance by the cap returns -3; errors write no output. Ten ports, binary64 primary oracle, independent 80-digit Decimal-bisection verifier, bounded workload, README/RIGHTS, static package inventory checker, and float64_slice_io runner/verifier wiring are complete. Source: SciPy's official [`ridder` reference](https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.ridder.html), which cites C. F. J. Ridders, “A New Algorithm for Computing a Single Root of a Real Continuous Function,” *IEEE Transactions on Circuits and Systems* 26 (1979), 979–980; algorithm descriptions only, clean-room implementation. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## Romberg integration reservation (2026-11-12)

| Algorithm | Local contract comparison | Reservation |
| --- | --- | --- |
| [Romberg integration](https://www.gnu.org/software/gsl/doc/html/integration.html#romberg-integration) | Local `area_under_curve` uses one composite trapezoidal grid; midpoint/Simpson/Weddle packages use their fixed formulas; `gaussian_legendre` uses fixed Gaussian nodes, and `adaptive_simpson_quadrature` recursively refines local Simpson estimates. No local package or reservation computes a sequence of successively halved trapezoidal grids and Richardson-extrapolates each row to cancel successive even-power error terms. | Implemented and registered as [`romberg_integration`](r/romberg_integration/README.md) in `float64_slice_io`: four exact integer-valued finite float64 inputs `[function_id,a_micro,b_micro,levels]`; callbacks are `exp(x)`, `x^5`, `1/(1+x^2)`, and `cos(x)`; endpoints are divided by 1,000,000, lie in `[-1,1]`, and satisfy `a<=b`; `3<=levels<=8`. The primary builds the nested trapezoid sequence and triangular Romberg recurrence through `R[levels,levels]`; the independent oracle uses closed-form antiderivatives for all four fixed functions. Equal endpoints return zero; malformed input returns -1; a valid input with a null output or capacity below one returns -2 without writes. Maximum valid/parseable input lengths are 4/5 values; the external output workspace is one float64 and the two fixed tableau rows use 144 bytes of local scratch plus scalar temporaries. Ten language ports, workload, README/RIGHTS, static package checker, and float64_slice_io runner/verifier fixture and ABI registration are present. Source: [GNU Scientific Library — Romberg integration](https://www.gnu.org/software/gsl/doc/html/integration.html#romberg-integration), algorithm description only; clean-room ports and workloads. Static review only; no programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## Dormand–Prince adaptive ODE solver reservation (2026-11-12)

| Algorithm | Local contract comparison | Reservation |
| --- | --- | --- |
| [Dormand–Prince RK45](https://docs.scipy.org/doc/scipy/reference/generated/scipy.integrate.RK45.html) | [`runge_kutta_fehlberg_45`](r/runge_kutta_fehlberg_45/README.md) uses a Fehlberg 4(5) tableau with a caller-specified fixed step; [`runge_kutta`](r/runge_kutta/README.md) and [`runge_kutta_gills`](r/runge_kutta_gills/README.md) are fixed-step one-step methods. None uses Dormand–Prince's different embedded 5(4) tableau, local-error-controlled accept/reject loop, and FSAL derivative reuse. The target is a distinct method and adaptive stepping strategy within the ODE-solver family. | Complete as [`dormand_prince_54_adaptive_ode`](d/dormand_prince_54_adaptive_ode/README.md), registered in `float64_slice_io`. Exact six-field input `[function_id,y0_milli,x0_milli,x_end_milli,tolerance_exponent,max_attempts]`; all six fields must be finite exact integers represented as float64. IDs 0..3 select `y'=y`, `y'=x+y`, `y'=sin(x)`, and `y'=1`; state and endpoints are scaled by 1,000 and lie in `[-1,1]`, with `x_end>x0`; `8<=tolerance_exponent<=9` uses equal absolute and relative tolerances `10^-exponent`; `64<=max_attempts<=128`. Initial step is `min((x_end-x0)/4,0.25)`, max step is 0.25, and the profile uses the Dormand–Prince 5(4) embedded error estimate, fifth-order accepted state, safety factor 0.9, bounded step factor `[0.2,5]`, and FSAL reuse. Output is one final state value with 2e-7 absolute/relative comparison tolerance, looser than either internal tolerance; malformed input returns -1, null/short output returns -2, exhausted valid attempts returns -3, with no writes on errors. Maximum valid/parseable input lengths are 6/7 values, output capacity is one float64, and declared workspace is 8 bytes. Primary is the adaptive DOPRI stepper; the independent oracle uses closed-form solutions for all four fixed right-hand sides. Ten language ports, workload, README/RIGHTS, static package checker, and float64_slice_io runner/verifier registration are present. Source: SciPy's official [RK45 reference](https://docs.scipy.org/doc/scipy/reference/generated/scipy.integrate.RK45.html), which cites Dormand and Prince, “A family of embedded Runge-Kutta formulae,” JCAM 6(1), 1980, DOI [10.1016/0771-050X(80)90013-3](https://doi.org/10.1016/0771-050X(80)90013-3). Clean-room use of the algorithm description. Static source review only; no programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## CP-Algorithms monotone convex-hull-trick reservation (2026-11-12)

| Algorithm | Local contract comparison | Reservation |
| --- | --- | --- |
| [Monotone convex hull trick](https://cp-algorithms.com/geometry/convex_hull_trick.html) | [`li_chao_tree`](l/li_chao_tree/README.md) answers the same lower-envelope query but supports arbitrary line insertion order using a segment tree over a bounded x-domain. [`range_linear_add_range_min`](r/range_linear_add_range_min/README.md) uses static block hulls with binary-search queries and supports arbitrary lazy slopes. No local package uses a strictly monotone-slope lower hull with nondecreasing x queries and amortized front pops. These are distinct data-structure algorithms under a shared line-minimum operation. | Implemented as `monotone_convex_hull_trick` in `i64_array_scalar`, with ten language ports, the package workload, a primary deque oracle, an independent all-lines oracle, and scalar-suite registration. Bounded input `[L,Q,(slope,intercept)*L,x[Q]]`, `1<=L<=32`, `0<=Q<=32`, strictly decreasing distinct slopes in `[-1000,1000]`, intercepts in `[-10000,10000]`, and nondecreasing queries in `[-1000,1000]`. Return `sum((i+1)*min_j(slope[j]*x[i]+intercept[j]))`; Q=0 returns zero, malformed input returns `INT64_MIN`. The primary uses exact integer cross-products to prune a deque lower hull and pops its front as sorted queries advance; the independent oracle scans all lines per query. Maximum valid/parseable lengths are 98/99 i64 words. Source: [CP-Algorithms — Convex hull trick and Li Chao tree](https://cp-algorithms.com/geometry/convex_hull_trick.html), specifically its monotone-slope convex-hull-trick section; CC BY-SA 4.0, algorithm description only. |

## Aho–Corasick failure-tree occurrence-count reservation (2026-11-12)

| Algorithm | Local contract comparison | Reservation |
| --- | --- | --- |
| [Aho–Corasick algorithm](https://cp-algorithms.com/string/aho_corasick.html) | [`aho_corasick`](a/aho_corasick/README.md) uses the automaton to follow terminal failure links during each text step and emits per-pattern occurrence counts. This profile instead records visits to automaton states while scanning, then propagates those counts once from deeper states to failure parents in reverse BFS order. It preserves the per-pattern count operation while measuring the offline failure-tree aggregation method, whose scan cost is independent of the number of reported matches. | Implemented as `aho_corasick_failure_tree_counts` in `i64_array_bytes_output`, with ten language ports, two independent-method oracles, package documentation, workload fixtures, a static package checker, and byte-suite registration. Input `[P,T,pattern_lengths[P],pattern_symbols...,text_symbols...]`, `1<=P<=16`, `0<=T<=256`, each pattern length `1..32`, and symbols in `1..4`; patterns are distinct. Maximum trie size is 513 states. Emit one little-endian i64 occurrence count per pattern, in input order, counting overlaps; maximum output is 128 bytes and the scalar result is output byte count. Maximum valid/parseable input lengths are 786/787 i64 words; workspace is 49,152 bytes to cover the i64-backed Elisa and Mojo fixed tables. Malformed input returns `-1`, insufficient/null output returns `-2`, and errors write no bytes. Primary method: BFS construction of sparse-trie failure links, one visit increment per scanned state, then reverse-BFS failure-parent accumulation. Independent oracle: direct substring scan for each pattern. Sources: [CP-Algorithms Aho–Corasick article](https://cp-algorithms.com/string/aho_corasick.html), count-only suffix aggregation; [OI Wiki Aho–Corasick article](https://oi-wiki.org/string/ac-automaton/), explicit reverse failure-tree occurrence propagation. Both are cited for algorithm descriptions only (CC BY-SA 4.0; OI Wiki also records SATA). |

## CP-Algorithms multiple-knapsack monotone-queue reservation (2026-11-12)

| Algorithm | Local contract comparison | Reservation |
| --- | --- | --- |
| [Multiple knapsack — monotone queue optimization](https://cp-algorithms.com/dynamic_programming/knapsack.html#monotone-queue-optimization) | [`knapsack_zero_one_tabulation`](k/knapsack_zero_one_tabulation/README.md) permits each item once and updates capacity in descending order. [`unbounded_knapsack`](u/unbounded_knapsack/README.md) permits unlimited reuse and follows an unbounded recurrence. Local FPTAS and greedy packages implement approximation or policy profiles; no bounded-multiplicity exact DP or residue-class monotone queue is present. | Implemented as `bounded_knapsack_monotone_queue` in `i64_array_scalar`, with ten language ports, two oracles, package docs, bounded fixtures, and scalar-suite registration. Input `[capacity,type_count,(weight,value,count)*type_count]`, `0<=capacity<=64`, `0<=type_count<=16`, weights `1..16`, values `0..100`, and multiplicities `0..16`; exact valid/parseable lengths are 50/51 i64 values. Return the maximum value under the capacity limit, or `-1` for malformed input. The primary snapshots the previous capacity DP for each item type and processes each residue class modulo its weight with a sliding maximum deque over `old[r+x*w]-x*value`, expiring candidates older than the multiplicity window; complexity is O(type_count*capacity) time and O(capacity) space. The independent oracle directly enumerates each permitted copy count in a two-row DP. Bounds keep results within signed 64-bit range. Source: CP-Algorithms, “Knapsack Problem,” Multiple Knapsack / Monotone Queue Optimization, CC BY-SA 4.0; algorithm description only, clean-room implementations. |

## CP-Algorithms Pollard p−1 factorization reservation (2026-11-13)

| Algorithm | Local contract comparison | Reservation |
| --- | --- | --- |
| [Integer factorization — Pollard's p−1 method](https://cp-algorithms.com/algebra/factorization.html#pollards-p-1-method) | Local [`pollard`](p/pollard/README.md), [`pollard_rho_python`](p/pollard_rho_python/README.md), [`pollard_rho_java`](p/pollard_rho_java/README.md), [`pollard_rho_rust`](p/pollard_rho_rust/README.md), and [`pollards_rho_factorizing`](p/pollards_rho_factorizing/README.md) use polynomial walks and Floyd/Brent cycle detection. Trial division and sieve packages test divisibility directly. No package exploits a prime factor whose predecessor is smooth by modular exponentiation and a gcd. | Implemented as [`pollard_p_minus_one_factorization`](p/pollard_p_minus_one_factorization/README.md) in `i64_array_scalar`, registered in the shared scalar runner and verifier. Input `[N,B,A]` with `2<=N<=1,000,000,000`, `2<=B<=64`, and `1<=A<N`; exact valid length is 3 and parseable length is 4. If `gcd(A,N)>1`, return that proper divisor. Otherwise, for each prime `q<=B` in increasing order, let `e=q^floor(log_q B)`, update `x=x^e mod N`, and compute `g=gcd(|x-1|,N)`: continue for `g=1`, return `g` for `1<g<N`, and return 0 on `g=N` or after all stages. Malformed input returns `-1`; valid failure returns 0. Modular products fit signed 64-bit because `N<=10^9`; workspace is 1024 bytes. Primary uses successive maximal-prime-power modular exponentiation; independent oracle uses a direct big-integer cumulative exponent and Python modular powers at each stage. Ten ports, workload, README/RIGHTS, and package-local static inventory checker are present. Source: [CP-Algorithms — Pollard's p−1 method](https://cp-algorithms.com/algebra/factorization.html#pollards-p-1-method), CC BY-SA 4.0; algorithm description only. Clean-room implementation. |

## CP-Algorithms all-pairs flow edge-connectivity reservation (2026-11-13)

| Algorithm | Local contract comparison | Reservation |
| --- | --- | --- |
| [Edge connectivity using maximum flow](https://cp-algorithms.com/graph/edge_vertex_connectivity.html#edge-connectivity-using-maximum-flow) | [`stoer_wagner`](s/stoer_wagner/README.md) computes the same global minimum-cut value using its phase-contraction algorithm, while [`global_minimum_cut_of_dynamic_star_augmented_graph`](g/global_minimum_cut_of_dynamic_star_augmented_graph/README.md) recomputes that cut for a changing supernode-star profile. [`vertex_connectivity`](v/vertex_connectivity/README.md) uses vertex splitting and computes vertex separators. Generic max-flow packages solve one supplied source/sink network. No package runs the CP-Algorithms all-terminal-pairs, unit-capacity max-flow method for undirected edge connectivity. Implemented as [`edge_connectivity_all_pairs_maxflow`](e/edge_connectivity_all_pairs_maxflow/README.md) in `i64_array_scalar`, registered in the shared scalar runner and verifier. Input `[N,M,(u,v)*M]`, `2<=N<=10`, `0<=M<=45`, simple undirected graph with no loops or repeated edges; disconnected graphs are valid and return 0. Return the minimum unit-capacity s-t maximum flow over all unordered vertex pairs, equivalent to the global edge connectivity. Invalid input returns `-1`; maximum valid/parseable lengths are 92/93 i64 words; declared workspace is 4096 bytes. Primary runs bounded Edmonds–Karp flows for terminal pairs; independent oracle enumerates nontrivial vertex cuts and counts crossing edges. Ten language ports, workload, README/RIGHTS, and static inventory checker are present. Source: [CP-Algorithms — Edge connectivity / Vertex connectivity](https://cp-algorithms.com/graph/edge_vertex_connectivity.html), CC BY-SA 4.0; use the algorithm description only. |

## GSL adaptive Gauss–Kronrod quadrature reservation (2026-11-13)

| Algorithm | Local contract comparison | Reservation |
| --- | --- | --- |
| [Adaptive Gauss–Kronrod 7/15 pair](https://www.gnu.org/software/gsl/doc/html/integration.html) | [`gaussian_legendre`](g/gaussian_legendre/README.md) applies fixed Gauss–Legendre tables of orders 1 through 5 to a cubic input; it has no embedded estimate or interval scheduler. [`adaptive_simpson_quadrature`](a/adaptive_simpson_quadrature/README.md) refines from the whole-versus-two-half Simpson difference, while [`romberg_integration`](r/romberg_integration/README.md) builds a nested trapezoid/Richardson table. No local float64 contract uses an embedded Gauss 7 / Kronrod 15 pair and repeatedly bisects the interval with the largest estimated error. The Encyclopedia-of-Algorithms chapter inventory currently has no numerical-quadrature candidate row to map to this method. | Completed and registered as `adaptive_gauss_kronrod_15_quadrature` in `float64_slice_io`. Input `[function_id,a_micro,b_micro,tolerance_exponent,interval_limit]`, exactly five integer-valued finite float64 fields; `function_id` is 0..3 for `exp(4x)`, `sin(10x)`, `1/(1+9x^2)`, and `x^14`; endpoints are ordered micro-units in `[-1_000_000,1_000_000]`; tolerance exponent is 6..8 and interval limit 1..16. Primary evaluates the embedded 7/15 pair on a bounded interval list and repeatedly splits the interval with largest `abs(K15-G7)`, breaking ties by smaller left endpoint. It returns the sum of Kronrod estimates once summed local error meets tolerance; exhausting the interval cap returns -3 without output. Equal endpoints return 0. The independent oracle uses closed-form antiderivatives for successful inputs and an independently organized error-priority queue to recognize cap exhaustion; output is one float64 with 2e-7 absolute/relative comparison tolerance. Malformed input returns -1; a valid frame with null/short output returns -2 before numerical work; no errors write output. Maximum valid/parseable input lengths are 5/6 values; output/workspace capacity is 1 element / 8 bytes, with 16 fixed interval records in local storage. Ten ports, two oracles, workload, README/RIGHTS, static inventory checker, and float64-suite registration are complete. Source: [GNU Scientific Library — Numerical Integration](https://www.gnu.org/software/gsl/doc/html/integration.html), algorithm descriptions only; clean-room implementations. |

## CP-Algorithms factoring exponentiation reservation (2026-11-13)

| Algorithm | Local contract comparison | Reservation |
| --- | --- | --- |
| [Binary Exponentiation by Factoring](https://cp-algorithms.com/algebra/factoring-exp.html) | Local [`binary_exponentiation`](b/binary_exponentiation/README.md), [`modular_exponentiation`](m/modular_exponentiation/README.md), and [`modular_binary_exponentiation_recursive`](m/modular_binary_exponentiation_recursive/README.md) use standard repeated-squaring recurrences; [`power_for_huge_numbers`](p/power_for_huge_numbers/README.md) handles a decimal exponent string. No local package uses the 2-adic logarithm representation of odd units to compute `a*x^y mod 2^d`. | Confirmed distinct and implemented as `factoring_exponentiation` in `i64_array_scalar`. Input `[a,x,y,d]`: `0<=a<2^d`, odd `1<=x<2^d`, `0<=y<=2^32-1`, and `3<=d<=32`; exact valid/parseable lengths are 4/5. Return `a*x^y mod 2^d`; malformed input returns -1. The primary normalizes units congruent to 3 modulo 4, extracts a 2-adic logarithm, scales by `y`, and reconstructs with the published mathematical log constants, in O(d) time and O(1) space. The independent oracle uses ordinary modular repeated squaring in O(log y). Ten clean-room language ports, primary/independent oracles, workload, README/RIGHTS, static source inventory, and scalar runner/verifier registration are complete. Implementations and fixtures were reviewed statically; no programs, tests, builds, compilers, benchmarks, or checkers were run. Source: [CP-Algorithms — Binary Exponentiation by Factoring](https://cp-algorithms.com/algebra/factoring-exp.html), CC BY-SA 4.0; algorithm and mathematical constants only. |

## OI Wiki ISAP maximum-flow addition (2026-11-13)

| Algorithm | Local contract comparison | Disposition |
| --- | --- | --- |
| [Improved shortest augmenting path (ISAP)](https://oi-wiki.org/graph/flow/max-flow/#isap) | Local [`dinic_maxflow`](d/dinic_maxflow/README.md) uses level graphs and blocking flows; [`edmonds_karp`](e/edmonds_karp/README.md) uses BFS shortest augmenting paths; [`mpm_maxflow`](m/mpm_maxflow/README.md) uses vertex potentials and blocking preflows; [`push_relabel`](p/push_relabel/README.md) uses preflow excess. No package uses reverse-BFS sink labels with dynamic relabeling, current arcs, and gap termination. | Implemented as [`isap_maxflow`](i/isap_maxflow/README.md) in `i64_array_scalar`. Input `[N,M,s,t,(u,v,c)*M]`, `2<=N<=8`, `0<=M<=24`, capacities `0..100`, no self-loops, with parallel and antiparallel arcs allowed; valid/parseable lengths are 76/77 i64 words and the maximum flow is 2400. The primary uses reverse-BFS labels followed by admissible-arc DFS, relabeling, and the gap rule; the independent oracle enumerates all source-containing, sink-excluding vertex cuts. Ten language ports, workload, README/RIGHTS, static inventory checker, and shared scalar runner/verifier registration are complete. Source: [OI Wiki — Maximum Flow, ISAP section](https://oi-wiki.org/graph/flow/max-flow/#isap), CC BY-SA 4.0/SATA; algorithm description only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## Library Checker ECM stage-one addition (2026-11-13)

| Algorithm | Local contract comparison | Disposition |
| --- | --- | --- |
| [Elliptic-curve method stage 1](https://github.com/yosupo06/library-checker-problems/issues/1395) | Local Pollard-rho packages use polynomial maps and cycle detection; [`pollard_p_minus_one_factorization`](p/pollard_p_minus_one_factorization/README.md) uses smooth exponents in the multiplicative group. Neither uses smooth scalar multiplication in a curve group to expose a factor. The Library Checker item is an in-progress proposal, not a solved official task. | Implemented as [`elliptic_curve_method_stage1`](e/elliptic_curve_method_stage1/README.md) in `i64_array_scalar` as a bounded subroutine profile. Input `[N,A,X,Y,B1]` uses odd square-free `3<=N<=10000`, a nonsingular Montgomery curve `y²=x³+A*x²+x mod N`, an on-curve point, and `2<=B1<=32`; valid/parseable lengths are 5/6. Return 1 when a stage checkpoint exposes a proper gcd factor, 0 when a checkpoint reaches infinity modulo every prime factor or no factor appears, and -1 for malformed input. Ten ports use Montgomery X:Z ladders; the independent oracle uses affine arithmetic after trial-factorization of N. Workload, README/RIGHTS, static source checker, and scalar runner/verifier registration are complete. The algorithm references are Lenstra's original [ECM paper](https://annals.math.princeton.edu/1987/126-3/p09) and Montgomery's [x-only factorization arithmetic](https://doi.org/10.1090/S0025-5718-1987-0866113-7); the Library Checker proposal is used for algorithm discovery only. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## Library Checker dynamic ordered-set addition (2026-11-13)

| Algorithm | Local contract comparison | Disposition |
| --- | --- | --- |
| [Dynamic `ordered_set`](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/ordered_set/task.md) | [`avltree_unique_key_ops`](a/avltree_unique_key_ops/README.md) provides unique-key insert/search/delete and a final sorted snapshot; [`binary_search_tree`](b/binary_search_tree/README.md) exposes extrema and size; [`treap_unique_key_set`](t/treap_unique_key_set/README.md) reports the final set. None maintains subtree cardinalities for dynamic kth/rank queries together with inclusive predecessor and successor operations. Static [`wavelet_tree`](w/wavelet_tree/README.md) and [`veb_tree`](v/veb_tree/README.md) do not supply this update/query combination. | Implemented as [`ordered_set_avl_order_statistics`](o/ordered_set_avl_order_statistics/README.md) in `i64_array_scalar`. Input `[N,Q,initial[N],(opcode,key)*Q]` uses `0<=N,Q<=32`, strictly increasing initial keys, and keys in `0..1000`; opcodes are idempotent insert/delete, one-based kth, count `<=x`, predecessor `<=x`, and successor `>=x`. The scalar result weights query answers in order, with missing results contributing zero. Maximum valid/parseable frames are 98/99 i64 values and maximum live set size is 64. Ten ports use AVL rotations with subtree sizes; the independent oracle simulates a sorted list. Workload, README/RIGHTS, static package inventory checker, and scalar runner/verifier integration are complete. The OI Wiki [`block list`](https://oi-wiki.org/ds/block-list/) candidate is tracked separately because it covers arbitrary indexed sequence insertion/lookup with interior block splitting, unlike the local append-only unrolled list. Source task semantics only; all implementations are clean-room. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

## CP-Algorithms prime-modulus inverse-table addition (2026-11-13)

| Algorithm | Local contract comparison | Reservation |
| --- | --- | --- |
| [All modular inverses for a prime modulus](https://cp-algorithms.com/algebra/module-inverse.html#finding-the-modular-inverse-for-prime-moduli-using-euclidean-division) | [`modular_inverse`](m/modular_inverse/README.md), [`modular_inverse_fermat_little_theorem`](m/modular_inverse_fermat_little_theorem/README.md), and related packages compute one requested inverse using extended Euclid, exponentiation, or linear search. No package builds the linear recurrence table for every positive integer up to the largest queried value. | Implemented as [`prime_modulus_inverse_table`](p/prime_modulus_inverse_table/README.md): ten ports, dual oracles, bounded workload, package inventory, and byte-output suite registration. The input has up to 32 operands in 1..256, and the output contains little-endian u32 inverses modulo 1,000,000,007. The primary builds the recurrence table through the largest operand; the independent oracle uses extended Euclid. Source: [CP-Algorithms](https://cp-algorithms.com/algebra/module-inverse.html), CC BY-SA 4.0; algorithm description only. No programs or checks were run. |

## OI Wiki indexed block-list addition (2026-11-13)

| Algorithm | Local contract comparison | Reservation |
| --- | --- | --- |
| [Block list](https://oi-wiki.org/ds/block-list/) | [`unrolled_linked_list`](u/unrolled_linked_list/README.md) models append-only tail chunks, a source-specific overflow split, and final flattening. The OI Wiki structure supports indexed insertion and lookup and splits oversized interior blocks by moving a fixed-size suffix. This exercises locating an index through block lengths, shifting within one block, and maintaining the linked block chain after interior splits. | Implemented as [`indexed_block_list`](i/indexed_block_list/README.md) in `i64_array_bytes_output`. The bounded profile uses B=4, up to 16 initial values, 64 operations (at most 32 insertions and 32 accesses), and signed values in `[-1,000,000,1,000,000]`; inserts and indexed reads use a linked chain of fixed arrays and split an oversized block by moving its last B values into a new successor. Each read emits one little-endian i64. Maximum valid/parseable inputs are 178/179 i64 words and maximum output is 256 bytes. Ten ports, primary linked-block and independent flat-list oracles, workload/fixtures, README/RIGHTS, static source checker, and byte-output runner/verifier registration are present. The package is distinct from the append-only local list profile. The OI Wiki page uses CC BY-SA 4.0 and SATA terms ([FAQ](https://www.timothywang.ca/OI-wiki/intro/faq/)); algorithm description only, clean-room implementation. No programs, tests, checkers, scripts, builds, compilers, or benchmarks were run. |

The indexed block-list suite source additionally specifies every insertion position for initial sizes around its split threshold, followed by reads across the entire resulting list and a comparison of both references. These checks remain unexecuted.

## Bitap duplicate audit and BNDM candidate (2026-11-13)

The former `bitap_exact_match_31` and [`bitap_string_match`](b/bitap_string_match/README.md) packages used the same first-match shift-OR recurrence and lowercase-ASCII input format. The latter accepts patterns up to 63 characters, covering the former's 31-character domain. The narrower duplicate was removed, and its C# source remains recorded against the retained package. The 31-character rejection boundary is no longer a separate benchmark contract.

[Backward Nondeterministic DAWG Matching (BNDM)](https://users.dcc.uchile.cl/~gnavarro/abstracts/cpm98.html) is a distinct candidate: it scans each alignment backward with a bit-parallel suffix automaton and skips alignments, unlike the retained forward shift-OR Bitap and the existing Horspool and Two-Way searches. A path and content search found no previous BNDM package. [`backward_nondeterministic_dawg_match`](b/backward_nondeterministic_dawg_match/README.md) has a contract, two references, workload, ten language drafts, source inventory checker, and scalar runner/verifier integration. Verifier source covers exhaustive short binary inputs, 31/32/63-bit boundaries, maximum frame, and null pointers. The drafts and integration remain uncompiled and unexecuted.

## Backward oracle matching reservation (2026-11-13)

The [factor oracle](https://citeseerx.ist.psu.edu/document?doi=4799c88ba0bd0626f9e4916ef3f530e2c8e677bf&repid=rep1&type=pdf) of Allauzen, Crochemore, and Raffinot supplies a compact automaton for backward oracle matching (BOM). It differs from BNDM's bit-parallel nondeterministic suffix automaton and from the bad-character, prefix-function, and critical-factorization matchers already in the catalog. The catalog's Go `bom` source contains only commented-out code and is not an implementation. A local path/content search found no implemented factor-oracle matcher. [`backward_oracle_match`](b/backward_oracle_match/README.md) has a contract, two references, ten language drafts, workload, package inventory checker, and scalar runner/verifier integration. Source-specified cases include exhaustive short binary inputs, long patterns, maximum frames and null pointers. All drafts and integration remain uncompiled and unexecuted; no upstream code or prose was copied.

Static source review corrected the initial suffix-state shifting draft to the factor-oracle BOM rule: when a transition is missing, shift the window past the failed text position. The missing transition proves the examined substring is not a pattern factor, so no skipped window can match. This rule and the distinction from suffix-oracle matching follow Raffinot's [factor-oracle seminar description](https://algo.inria.fr/seminars/sem99-00/raffinot.html). The Go source remains excluded as source code despite the independent algorithm mapping. Verifier source now also specifies exhaustive short ternary inputs and checks long-pattern and maximum-frame agreement between references; those checks remain unexecuted.

## Wavelet matrix reservation (2026-11-13)

The existing [`wavelet_tree`](w/wavelet_tree/README.md) partitions each node's value interval separately and stores node-local prefix counts. Claude and Navarro's [wavelet matrix](https://users.dcc.uchile.cl/~gnavarro/ps/spire12.4.pdf) instead stable-partitions each complete level globally and remaps positions through level-wide zero counts and rank arrays. This is a materially different representation and construction despite supporting the same queries. A local filename/content search found no wavelet-matrix package. [`wavelet_matrix`](w/wavelet_matrix/README.md) has the same bounded rank, quantile, and range-count contract as the existing tree. Ten language drafts, two references, workload, inventory checker, and scalar runner/verifier wiring are present. Verifier source specifies exhaustive small sequences, prefix ranks, maximum frames and null inputs; workload source includes extreme values and ignored fields. The paper supplies algorithmic ideas only; code and fixtures are independently authored. All drafts and checks remain uncompiled and unexecuted.

## XOR filter reservation (2026-11-13)

Graf and Lemire's [XOR filter](https://arxiv.org/abs/1912.08258) builds a static approximate-membership structure by peeling a three-way hash graph and assigning XOR fingerprints in reverse peel order. Local [`bloom_filter`](b/bloom_filter/README.md) sets bits online, while [`hash_map_cuckoo_hashing`](h/hash_map_cuckoo_hashing/README.md) is an exact relocation-based map. A local path/content search found no XOR filter. [`xor_filter_peeling`](x/xor_filter_peeling/README.md) uses caller-supplied slot triples and fingerprints, deterministic queue order, explicit peel failure, and membership queries; supplied hashes isolate construction without claiming randomized error guarantees. Ten language drafts, two references, workload, inventory checker, and scalar runner/verifier wiring are present. Verifier source specifies small graphs, slot permutations, no-false-negative checks, maximum frames, and null inputs. The research description supplies algorithmic ideas only. All drafts and checks remain uncompiled and unexecuted.

## Enumerative bitvector reservation (2026-11-13)

The local [`rank_select_bitstring`](r/rank_select_bitstring/README.md) stores plain 8-bit blocks with prefix counts and scans the bits. The RRR family, described by Raman, Raman and Rao in [succinct indexable dictionaries](https://arxiv.org/abs/0705.0552), represents each block by its one-count class and its rank among same-class bit patterns. [`rrr_class_offset_rank_select`](r/rrr_class_offset_rank_select/README.md) is a bounded class/offset construction and rank/select workload preserving the existing bitstring query contract. Ten language drafts, two references, workload, inventory checker, and byte-output runner/verifier integration are present; verifier source covers all byte patterns, partial blocks, maximum frames, capacity errors, and null pointers. The fixed-size representation and decoding scans do not claim the original succinct-space or constant-time bounds. A local path/content search found no prior RRR profile. Algorithm descriptions only; independently authored code and fixtures. All drafts and checks remain uncompiled and unexecuted.

## Reservoir sampling without replacement reservation (2026-11-13)

The catalog excluded Java `reservoir_sampling` because its unseeded RNG cannot be replayed directly. That does not prevent an independent bounded profile with explicit draws. [`counting_triangles_stream_reservoir`](c/counting_triangles_stream_reservoir/README.md) instead maintains independent size-one samples and permits repeated records; Algorithm R maintains one fixed-size sample without replacement and replaces at most one slot per arriving record. [`reservoir_sampling_algorithm_r`](r/reservoir_sampling_algorithm_r/README.md) uses caller-supplied integer draws and byte output of the final slot order. Ten language drafts, two references, workload, inventory checker, and byte-output runner/verifier integration are present. Verifier source specifies exhaustive small draw tapes, equal subset frequencies, maximum frames, capacity errors and null pointers. [Vitter's description](https://doi.org/10.1145/3147.3165) supplies the algorithmic idea; no source code or tests copied. All drafts and checks remain uncompiled and unexecuted.

## Lossy Counting reservation (2026-11-13)

Manku and Motwani's [Lossy Counting](https://www.vldb.org/conf/2002/S10P03.pdf) tracks each retained item's estimated count and bucket-based error and prunes at bucket boundaries. Local [`misra_gries_summaries`](m/misra_gries_summaries/README.md) decrements all counters on overflow, and [`space_saving_frequent_items`](s/space_saving_frequent_items/README.md) replaces a minimum counter; neither uses this bucket pruning. No local Lossy Counting package was found by path/content search. [`lossy_counting_summary`](l/lossy_counting_summary/README.md) uses an explicit integer bucket width, finite item IDs, and a canonical snapshot of retained `(item,count,error)` tuples. Ten language drafts, two references, workload, inventory checker, and byte-output runner/verifier integration are present; verifier source specifies small streams, frequency bounds, maximum output, capacity errors, and null inputs. Algorithm descriptions only; no source prose, code, or fixtures copied. All drafts and checks remain uncompiled and unexecuted.

The workload also specifies repeated deletion and reinsertion, a full bucket at maximum width, and an inconsistent declared stream length. The verifier source asserts that items exceeding the `n/width` frequency threshold are retained. These additions remain unexecuted.

The package checker additionally specifies the schema identity, input and output encodings, error results, workspace type, and signed-64-bit fixture values, so malformed metadata cannot silently pass the inventory check. This checker change is also unexecuted.

## Duval factorization duplicate identified (2026-11-13)

The CP-Algorithms [Lyndon factorization description](https://cp-algorithms.com/string/lyndon_factorization.html) led to a comparison of [`duval_algorithm`](d/duval_algorithm/README.md) and the former `lyndon_factorization`. Both used the same Duval scan. The narrower duplicate and its suite registration were removed; the retained profile supports ASCII sequences through length 4096 and emits factor lengths, with both Java and Rust source histories preserved. The separate [`duval`](d/duval/README.md) computes a least cyclic rotation and remains a different workload.

Static registration review originally found a verifier branch only for the narrower profile. The wider profile now has its own verifier branch and retains the applicable coverage.

An independently structured direct-comparison factorization reference is drafted for inputs up to 16 items. The retained verifier source compares it against all binary-alphabet inputs through length eight and separately specifies a known 4096-item boundary result. All checks remain unexecuted.

The direct reference now lives with the wider Duval package, which is the intended survivor of consolidation.

The verifier source registers `duval_algorithm`, compares short binary inputs with the direct reference, and specifies the full 4096-character repeated-input boundary and capacity/error probes. The duplicate package has been removed and the reference resides with the retained package. These changes are unexecuted.

Static framing review added the 4097-word parseable limit, recorder and verifier workspace registration, and null-input/null-output corpus probes for the wider profile. The checker harness source accepts these input and output sizes. The full suite path remains unexecuted.

The wider profile's verifier source now also carries over the former profile's 256 deterministic lowercase random cases and short-capacity probes, and specifies ASCII endpoint cases against the direct reference. The distinct length-prefixed framing errors of the narrower profile do not apply to the retained raw-array contract. None of these checks has run.

The retained guide now explicitly records empty-input and null-output behavior and lists its Mojo draft alongside the other nine ports. Harness constants statically accommodate the largest specified frame and output; runtime behavior remains unverified.

The [Sticky Sampling](https://www.vldb.org/conf/2002/S10P03.pdf) frequent-item algorithm was identified as a distinct streaming profile. The initial filename and coverage-ledger search found no package by that name; its changing sampling rate and counter thinning differ from deterministic Lossy Counting and from reservoir sampling. The subsequent reservation and current draft coverage are recorded below.

The original paper's section 4.1 describes sampling absent items at a changing rate and, at each rate change, reducing existing counters using independent fair coin tosses until a success or counter deletion. Its phase lengths grow geometrically. A replayable benchmark must specify draw consumption and ordering for both admission and thinning, including deletion and exact phase boundaries; arbitrary supplied draws do not by themselves establish the paper's probabilistic guarantee. The paper's first page permits certain noncommercial copying under conditions and reserves other copying, so use mathematical ideas only and independently author all code, fixtures, and prose.

Reserved [`sticky_sampling_summary`](s/sticky_sampling_summary/README.md): the bounded contract specifies a finite alphabet, an explicit draw tape, ascending-item thinning order, exact draw consumption and a sorted counter snapshot. The current package has two reference drafts, fixtures, ten language drafts, an inventory checker, and byte-output runner/verifier wiring. These are unexecuted drafts; static and runtime verification remain outstanding. Do not duplicate the ports.

The package now also has a phase-oriented independent reference and a C implementation draft. The two references and C port are unexecuted; nine ports, fixtures, inventory checker, and suite integration remain outstanding.

C++, Elisa, and Rust drafts are now present as well. The Elisa algorithm uses bounded views and a fixed array after its ABI boundary. Six ports, fixtures, checker, and suite integration remain outstanding; all drafts remain unexecuted.

C3 and Zig drafts are now present too. Nim, Odin, V, and Mojo ports remain outstanding, as do fixtures and suite integration. Nothing has been run.

Nim and Odin drafts have been added. V and Mojo ports, fixtures, the checker, and suite integration remain outstanding. All remain unexecuted.

V and Mojo drafts complete the ten-language source set. Workload fixtures, the package checker, and suite integration remain outstanding; no draft has been compiled or run.

An independently authored workload and inventory checker are now drafted, including phase thinning, deletion and reinsertion, tape shortage/surplus, validation precedence, null pointers, and short output. The fixtures and checker remain unexecuted; suite integration is outstanding.

Byte-output runner and verifier wiring is now drafted. The verifier source specifies exhaustive short binary streams and tapes, a full 16-item output, and null/capacity probes. All ports, fixtures, and checks remain uncompiled and unexecuted.

The root README and catalog now link to the profile and explicitly identify it as unexecuted. Static review also expanded the V draft's compact statements for clarity. This does not establish that any port compiles.

The fixture set now specifies ascending-item thinning explicitly. Verifier source adds 64-item streams at both ends of the phase-unit range, including short-output and malformed-length probes. These checks remain unexecuted.

## Exponential histogram window reservation (2026-11-13)

[Datar et al.'s sliding-window counting](https://www.cs.princeton.edu/courses/archive/spr04/cos598B/bib/DatarGIM.pdf) maintains power-of-two buckets of one-bits and estimates the partial oldest bucket. The local [`adwin`](a/adwin/README.md) uses exponential buckets for variance-sensitive adaptive drift detection, with a different update and output contract. A local path/content search found no fixed-window DGIM counting package. Reserved [`exponential_histogram_window`](e/exponential_histogram_window/README.md) now has two reference drafts, fixtures, ten language drafts, a checker, and byte-output runner/verifier wiring. These are unexecuted drafts; static and runtime verification remain outstanding. Do not duplicate the ports. Only algorithmic ideas are used.

The package now includes a per-size-queue independent reference and a C draft. Nine language ports, fixtures, checker, and suite wiring remain outstanding; all are unexecuted.

C++, Elisa, and Rust drafts are also present. Elisa uses fixed arrays and bounded views after the ABI boundary. Six ports, fixtures, checker, and suite wiring remain outstanding; none has been compiled or executed.

C3 and Zig drafts are now present. Nim, Odin, V, and Mojo ports, fixtures, checker, and suite wiring remain outstanding; all remain uncompiled and unexecuted.

Nim and Odin drafts are now present. V and Mojo ports, fixtures, checker, and suite wiring remain outstanding; no code has run.

V and Mojo drafts complete the ten-language source set. Fixtures, checker, and suite wiring remain outstanding; all drafts are uncompiled and unexecuted.

The workload and package checker are now drafted, with bucket-merge/expiry, single-bit window, invalid input, and capacity/null cases. Suite wiring remains outstanding; fixtures and checker have not run.

The byte-output runner and verifier are now wired to the package. Verifier source specifies exhaustive short bit streams and windows, frequency-error bounds, maximum-size streams, and capacity/null probes. The wiring, drafts, and checks remain uncompiled and unexecuted.

The root README and catalog now link the profile, and verifier source also specifies maximum-length all-zero streams for the minimum and maximum windows. These checks remain unexecuted.

## CP-Algorithms sqrt-tree coverage audit (2026-11-13)

The [sqrt-tree catalog item](https://cp-algorithms.com/data_structures/sqrt-tree.html) is already represented by [`sqrt_tree`](s/sqrt_tree/README.md); it is not a new algorithm. Static inventory found its Mojo port missing. A Mojo draft now builds the same recursive block-prefix, block-suffix, and between-block minimum structure using bounded lists and answers the existing packed queries. The source records the package's CC BY-SA attribution. The draft has not been compiled or run.

The verifier source now specifies range-minimum probes around square-root block boundaries through 256 items, a maximum 770-word frame, short output, null output, and an overlength frame. The independent expected values use direct range scans. These checks remain unexecuted.

## AMS sketch language coverage (2026-11-13)

Static comparison of registered Rust and Mojo filenames found that [`ams_sketch`](a/ams_sketch/README.md) lacked a Mojo source. A Mojo draft now implements the same explicit-hash signed bucket updates and median squared-row estimate. The existing algorithm and suite entry are retained; no duplicate benchmark was created. The draft has not been compiled or run.

## Best Fit bin-packing language coverage (2026-11-13)

The existing [`best_fit_bin_packing`](b/best_fit_bin_packing/README.md) suite entry lacked a Mojo source. A Mojo draft now implements the same input-order best-fit placement, earliest-bin tie-breaking, and little-endian assignments. This closes a source-coverage gap without adding a duplicate algorithm; the draft has not been compiled or run.

The existing [`best_fit_decreasing_bin_packing`](b/best_fit_decreasing_bin_packing/README.md) entry also lacked Mojo. Its new draft performs a stable decreasing-size order before Best Fit and returns assignments in original item order. It remains distinct from the online ordering profile and has not been compiled or run.

The separate [`bounded_space_best_fit_bin_packing`](b/bounded_space_best_fit_bin_packing/README.md) profile now has a Mojo draft implementing its two-open-bin closure policy and deterministic ties. This distinct constrained behavior was retained; the draft has not been compiled or run.

## Approximate substring language coverage (2026-11-13)

The registered [`agrep_approx_substring_count`](a/agrep_approx_substring_count/README.md) profile lacked a Mojo source. A Mojo draft now follows its free-restart streaming Levenshtein row and counts qualifying endpoints, preserving the existing source-rights distinction. The draft has not been compiled or run.

Static review of the distinct [`approximate_regex_matching`](a/approximate_regex_matching/README.md) NFA profile found seven ports returning -2 for null input despite the documented -1 invalid-input contract, plus missing null guards in V and Elisa. Those guards and return codes were corrected; Elisa also now checks null nonempty output. A Mojo draft is now present. No checks were executed.

A Mojo draft now implements the same bounded NFA edit-distance profile. The changes across all ten ports remain uncompiled and unexecuted.

The suite verifier source now specifies null input at zero and maximum parseable lengths, null output for empty and nonempty text, and malformed-input precedence over output errors. Those checks remain unexecuted.

## Bottom-k ADS frame-bound correction (2026-11-13)

Static review of [`all_distances_sketch_bottom_k`](a/all_distances_sketch_bottom_k/README.md) found that its declared simple directed graphs allow 90 edges at ten vertices, requiring 194 input words, but the two references, nine ports, and workload imposed 104. The bounds now use 194 valid and 195 parseable words, preserving the full documented graph domain; the suite bounds derive from the primary reference constant. A Mojo draft and a complete directed-graph verifier case are also present. The draft and verifier case remain unexecuted; no code or checks were run.

A Mojo draft now covers the same BFS and bottom-k prefix rules. Dense-graph verifier probes remain outstanding; all changes remain uncompiled and unexecuted.

Verifier source now specifies the full 90-edge directed graph, checks all ten output vertices and distances, and includes 167-byte capacity, null output, overlength, and null-input boundary probes. These checks remain unexecuted.

## Approximate tandem squares language coverage (2026-11-13)

The existing [`approximate_tandem_squares`](a/approximate_tandem_squares/README.md) profile lacked a Mojo source. A Mojo draft now enumerates start/period pairs in contract order, counts Hamming mismatches, and emits the existing bounded output. It is an additional port of the existing algorithm, not a new benchmark; it has not been compiled or run.

The related [`approximate_tandem_k_repetitions`](a/approximate_tandem_k_repetitions/README.md) profile also now has a Mojo draft. It enumerates factors longer than two periods and computes Hamming mismatches in the documented order; this profile's interval domain differs from the square-only workload. The draft has not been compiled or run.

The existing [`approximate_tandem_k_runs`](a/approximate_tandem_k_runs/README.md) profile now has a Mojo draft as well. It measures the maximum mismatch count of every contained two-period window, which differs from the repetition profile's total mismatch count. The draft has not been compiled or run.

The distinct edit-distance [`approximate_tandem_k_edit_repeats`](a/approximate_tandem_k_edit_repeats/README.md) profile now has a Mojo draft, using bounded partition enumeration and unit-cost edit distances. It has not been compiled or run.

## Bitmap allocation language coverage (2026-11-13)

The existing [`bitmap_block_allocation`](b/bitmap_block_allocation/README.md) NBench-derived profile lacked a Mojo source. A Mojo draft now applies the same alternating initial bits and cyclic set, clear, and complement runs, then packs the final bitmap. The source profile remains unchanged; the draft has not been compiled or run.

## BFS diameter-estimate language coverage (2026-11-13)

The existing [`approximating_diameter_bfs`](a/approximating_diameter_bfs/README.md) profile lacked a Mojo source. A Mojo draft now validates the simple undirected graph and connectivity, then emits the eccentricity of vertex zero. It is an additional port of the registered approximation, not a new algorithm; it has not been compiled or run.

## Min-plus APSP language coverage (2026-11-13)

The registered [`apsp_min_plus_repeated_squaring`](a/apsp_min_plus_repeated_squaring/README.md) benchmark lacked a Mojo source. Its new draft retains the repeated min-plus square and unreachable-distance sentinel; it has not been compiled or run.

## BEEBS bit-compress language coverage (2026-11-13)

The existing [`beebs_bit_compress`](b/beebs_bit_compress/README.md) entry already consolidates four upstream variants with the same bit-gather contract. A Mojo draft now implements that retained profile without copying upstream code. The pre-existing workload describes source-derived test vectors; the new draft does not reproduce additional upstream material. It has not been compiled or run.

## Binary decision graph language coverage (2026-11-13)

The registered [`binary_decision_graph`](b/binary_decision_graph/README.md) profile lacked a Mojo source. A Mojo draft now builds the same reduced ordered graph using deterministic level order and node sharing. It is an additional port, not a new graph benchmark; it has not been compiled or run.

## Shootout ary3 language coverage (2026-11-13)

The registered [`ary3`](a/ary3/README.md) workload lacked a Mojo source. Its new draft retains 1,000 reverse traversal passes and the existing ASCII output contract; it does not replace the loop with its arithmetic result. The draft has not been compiled or run.

## Automotive bit-count language coverage (2026-11-13)

The existing [`automotive_bitcount`](a/automotive_bitcount/README.md) workload lacked Mojo coverage. A Mojo draft retains seven selected bit-count paths and their separate deterministic streams and weighted checksum. It represents the nibble lookup table as a packed constant; the draft has not been compiled or run.

## GAPBS Shiloach–Vishkin language coverage (2026-11-13)

The registered [`gapbs_shiloach_vishkin_components`](a/gapbs_shiloach_vishkin_components/README.md) profile lacked a Mojo source. Its new draft keeps the deterministic min-max hooking and grandparent compression sweeps, distinct from the local Afforest profile. It has not been compiled or run.

The distinct [`gapbs_afforest_components`](a/gapbs_afforest_components/README.md) profile now has a Mojo draft preserving its two sampled-neighbor rounds, supplied samples, safe-skip check, and remaining-edge linking. It has not been compiled or run.

Static integration review confirmed that the build resolver can find these nonstandard `mojo/a` paths through the package README links. The runner's inventory checks now include both Mojo sources; this does not verify their compilation or behavior.

## PolyBench BiCG language coverage (2026-11-13)

The registered [`bicg`](b/bicg/README.md) workload lacked a Mojo source. Its new draft retains the initialized matrix, ordered `s` and `q` updates, and ordered checksum. The existing PolyBench license notice remains in the package. The draft has not been compiled or run.

The distinct [`atax`](a/atax/README.md) workload now has a Mojo draft retaining its row-by-row matrix-vector and transpose-contribution order. It has not been compiled or run.

The existing [`2mm`](0-9/2mm/README.md) matrix-chain workload now has a Mojo draft preserving its two multiplication phases, scalar factors, loop order, and row-major checksum. It has not been compiled or run.

The separate [`3mm`](0-9/3mm/README.md) workload now has a Mojo draft retaining its three matrix multiplications and ordered checksum. It has not been compiled or run.

## Recursive workload language coverage (2026-11-13)

The existing [`benchmarkgame_recursive`](b/benchmarkgame_recursive/README.md) combined workload lacked a Mojo source. The draft retains direct uncached integer and floating recursion and stages the five-line output. It has not been compiled or run.

## BEEBS seven-segment language coverage (2026-11-13)

The existing [`beebs_lcdnum`](l/beebs_lcdnum/README.md) lookup profile lacked a Mojo source. Its new draft applies the existing documented nibble-to-mask mapping. It has not been compiled or run.

## Color-coding path language and null-contract coverage (2026-11-13)

The registered [`color_coding_k_path`](c/color_coding_k_path/README.md) profile lacked Mojo. Its new draft retains the supplied-color subset/endpoint dynamic program. Static review also corrected seven existing ports that returned -2 for null input and added input and output null guards to V and Elisa. These changes follow the existing malformed-input and output-error contract; none has been compiled or run.

The verifier source now specifies null-input, output-capacity, validation-precedence, and complete 12-vertex graph probes, including the 147-word maximum frame. These checks remain unexecuted.

The distinct [`color_coding_random_k_path`](c/color_coding_random_k_path/README.md) trial-replay profile now has a Mojo draft. It retains subset/endpoint DP, the first successful supplied coloring, and lexicographically smallest witness selection. It has not been compiled or run.

## Closest-string center language and null-contract coverage (2026-11-13)

The registered [`closest_string_center`](c/closest_string_center/README.md) profile lacked Mojo. Its new draft retains exhaustive lexicographic center enumeration and Hamming-radius minimization. Static review also corrected seven ports that returned -2 for null input and added missing input/output null guards to V and Elisa. All changes remain uncompiled and unexecuted.

Verifier source now specifies the maximum frame, short and null output, malformed-input precedence, and null-input boundaries for closest-string center. These checks remain unexecuted.

The distinct [`closest_substring_center`](c/closest_substring_center/README.md) profile now has a Mojo draft that compares each candidate against every length-L window per string. Static review corrected the same seven null-input error codes and missing V/Elisa input and output null guards. The profile remains distinct from whole-string centers; changes are uncompiled and unexecuted.

The verifier source now specifies maximum-frame, null-input, short/null-output, and malformed-input precedence probes for the substring profile. These checks remain unexecuted.

The suite runner's static source inventory now includes the Mojo port. The build resolver's existing package-path override and README-link fallback locate this nonstandard `mojo/l` source; runtime behavior remains unverified.

## BST interleave-bound language coverage (2026-11-13)

The registered [`bst_interleave_bound`](b/bst_interleave_bound/README.md) profile lacked a Mojo source. A Mojo draft now validates the supplied BST, follows parent links to test subtree membership, and counts left/right access alternations. It has not been compiled or run.

## Clique reverse-search language coverage (2026-11-13)

The registered [`clique_reverse_search_enumeration`](r/clique_reverse_search_enumeration/README.md) profile lacked Mojo. Its new draft retains the empty-root reverse-search tree and ascending child traversal. Static review also found that build, recorder, and verifier defaulted to `c` although the package and all ports reside under `r`; their path mappings now point to `r`. These changes have not been compiled or run.

## Almost-C1P set-cover language coverage (2026-11-13)

The registered [`almost_c1p_set_cover_enumeration`](a/almost_c1p_set_cover_enumeration/README.md) profile lacked a Mojo source. The draft retains row-wise feasible-mask expansion and minimum-weight selection with numeric-mask ties. It has not been compiled or run.

## GAPBS betweenness language coverage (2026-11-13)

The registered [`gapbs_betweenness_centrality`](b/gapbs_betweenness_centrality/README.md) profile lacked a Mojo source. Its draft uses ordered BFS, reverse-depth Brandes accumulation, explicit binary32 stores, and the specified normalized checksum. It has not been compiled or run.

The four distinct Ghostscript ROP3 profiles under [`g`](g/cbench_ghostscript_rop3/README.md) now have independently written Mojo drafts. They respectively evaluate a pixel, inspect idempotence, inspect operand usage, and transform a truth table. Their bundled AFPL v5 notices and distribution restrictions remain applicable. Build, recorder, and verifier directory mappings now locate their existing `g` packages, and the array-scalar verifier accepts Mojo as an explicitly selected optional language. None of these changes has been built or executed.

The existing [`count_min_sketch_affine`](c/count_min_sketch_affine/README.md) now includes a Mojo draft with deterministic supplied hashes, update and point-query operations, and the existing byte-output contract. It has not been compiled or run.

Static review of [`counting_triangles_stream_reservoir`](c/counting_triangles_stream_reservoir/README.md) found that the existing nine ports checked for half the bytes they wrote. Corrected all nine capacity checks and return lengths, both reference limits, the contract and a truncated fixture; added a Mojo draft. Two edges per prefix require 32 bytes, up to 896 bytes. These changes have not been compiled or run.

The distinct [`coremark_crc`](c/coremark_crc/README.md) helper workload now has a Mojo draft, retaining its tagged widths, reflected recurrence, and source attribution. It has not been compiled or run.

The existing [`coremark_matrix_manipulation`](m/coremark_matrix_manipulation/README.md) now has a Mojo draft preserving the ordered matrix stages, clip and CRC operations, and restored matrix output. Its build source and output directory mapping now points to `m`, where the existing package and ports reside. No code was compiled or run.

The registered [`cbench_ispell_hash`](c/cbench_ispell_hash/README.md) profile now has a Mojo draft for its ASCII uppercasing, packed prefix, 32-bit rotation and bucket reduction. The package retains its source license and conditions. The draft has not been compiled or run.

The separate [`cbench_ispell_lookup_chain`](i/cbench_ispell_lookup_chain/README.md) benchmark now has a Mojo draft for validated hash-bucket chain traversal. Its build, runner, and verifier paths now select its existing `i` directory, and its link to the hash primitive is corrected. No builds or execution were performed.

The [`cbench_lame_mid_side`](m/cbench_lame_mid_side/README.md) stereo transform now has a Mojo draft and corrected build path; the float64-slice verifier accepts explicitly selected optional Mojo. Its GPL notice and conditional source scope remain documented. No build or execution was performed.
The Elisa draft now uses bounded ABI views, and the V draft detects NaN
directly while retaining range checks for infinities. These edits are uncompiled.

The [`asci_purple_smg2000_residual`](a/asci_purple_smg2000_residual/README.md) structured 7-point residual now has a Mojo draft, with validated integral fields and the documented exact-tenths arithmetic. The package's independent-implementation rights note remains in place. It has not been compiled or run.

The source-specific [`cbench_office_pratt_boyer_moore`](c/cbench_office_pratt_boyer_moore/README.md) endpoint-skip search now has a Mojo draft and a documented worst-case complexity. Its source attribution remains recorded. It has not been compiled or run.

The distinct [`cbench_rsynth_f0_flutter`](m/cbench_rsynth_f0_flutter/README.md) three-sine profile now has a Mojo draft. Its build, scalar runner and verifier paths point to its `m` package, and the source rights note remains in place. It has not been compiled or run.
Its Elisa draft now uses the unsigned ABI length type and a bounded input
view after null and exact-length validation. This correction is uncompiled.
The verifier draft checks the zero-perturbation identities for zero flutter,
zero time, and an initial frequency quotient of zero; it has not been run.

The [`cbench_rsynth_natural_glottal`](m/cbench_rsynth_natural_glottal/README.md) recurrence has a Mojo draft. Static review found that both natural and impulsive glottal symbols end in `_sample` while their source and package names do not; build, float runner and verifier now resolve both explicit aliases. No build or execution was performed.

The separate [`cbench_rsynth_impulsive_glottal`](m/cbench_rsynth_impulsive_glottal/README.md) resonator now also has a Mojo draft. Both RSynth glottal drafts are listed in the float suite's port inventory; neither has been compiled or run.
Static review corrected the Elisa impulsive helper declaration, changed both
Elisa ports to bounded ABI views, and replaced uncertain V finite-method calls
with direct NaN checks plus existing range checks. These edits remain uncompiled.
The float verifier draft checks the first closed-phase sample for every natural
open duration and zero initial output for the impulsive source; it is unrun.

The existing [`beta_skeleton`](b/beta_skeleton/README.md) beta=2 lune graph has a Mojo draft and explicit complexity documentation. Its source attribution and MIT notice remain in the package. The draft has not been compiled or run.

The existing [`concave_gap_alignment_global`](l/concave_gap_alignment_global/README.md) direct gap-length dynamic program now has a Mojo draft and documented complexity. Its build, byte runner, and verifier paths now locate the existing `l` package. The draft and path fixes have not been executed.

The PolyBench [`covariance`](c/covariance/README.md) workload has a Mojo draft preserving the ordered centering, symmetric covariance reduction, and row-major checksum. Its complexity is documented, and the integer-array/float verifier accepts optional Mojo explicitly. No code was compiled or run.

The existing PolyBench [`doitgen`](d/doitgen/README.md) tensor contraction now has a Mojo draft preserving the staged slice update and reduction order, plus documented complexity. It has not been compiled or run.

The PolyBench [`durbin`](d/durbin/README.md) recurrence now has a Mojo draft preserving its ordered temporary updates, with complexity documented. It has not been compiled or run.

The existing [`distributed_coupon_collection_replay`](d/distributed_coupon_collection_replay/README.md) workload now has a Mojo draft and complexity documentation. It replays supplied bin-opening outcomes and has not been compiled or run.

The sampled [`dense_graph_bipartiteness_tester`](d/dense_graph_bipartiteness_tester/README.md) has a Mojo draft preserving explicit sample draws, complete induced-pair queries, and BFS coloring. Complexity is documented; the draft has not been compiled or run.

The existing [`deterministic_line_search`](d/deterministic_line_search/README.md) alternating doubling strategy has a Mojo draft and a documented complexity bound. It has not been compiled or run.

The [`domination_local_reduction`](d/domination_local_reduction/README.md) graph transformation now has a Mojo draft using bounded adjacency masks and staged output, with its complexity documented. It has not been compiled or run.

The [`directed_perfect_phylogeny`](d/directed_perfect_phylogeny/README.md) binary-character decision has a Mojo draft using the documented compatibility criterion. Complexity is recorded; the draft has not been compiled or run.

The cardinality-constrained [`first_fit_cardinality_bin_packing`](f/first_fit_cardinality_bin_packing/README.md) benchmark now has a Mojo draft and documented complexity. It has not been compiled or run.

The distinct online [`first_fit_bin_packing`](f/first_fit_bin_packing/README.md) and sorted [`first_fit_decreasing_bin_packing`](f/first_fit_decreasing_bin_packing/README.md) workloads now have Mojo drafts and complexity notes. Neither has been compiled or run.

The existing [`fibonacci_integer_code`](f/fibonacci_integer_code/README.md) profile has a Mojo draft that stages its greedy Zeckendorf codewords and retains the documented sentinel. Complexity is documented; it has not been compiled or run.

The [`exact_graph_coloring_inclusion_exclusion`](e/exact_graph_coloring_inclusion_exclusion/README.md) benchmark has a Mojo draft and complexity note. Static review corrected seven ports' null-input error codes and missing input/output null guards in V and Elisa. No code was compiled or run.

The existing [`fast_subset_convolution`](f/fast_subset_convolution/README.md) benchmark now has a Mojo ranked-zeta, rank-product, and Möbius-inversion draft with complexity documented. It has not been compiled or run.

The existing [`facility_location_add_delete_swap`](f/facility_location_add_delete_swap/README.md) benchmark has a Mojo draft with metric validation, deterministic neighborhood selection, and staged assignments. It has not been compiled or run.

The [`felsenstein_substitution_likelihood`](s/felsenstein_substitution_likelihood/README.md) postorder likelihood recurrence now has a Mojo draft. Build, byte runner, and verifier directory mappings now point to the existing `s` package. It has not been compiled or run.

The existing [`fm_index_count`](f/fm_index_count/README.md) backward-search workload now has a Mojo draft preserving suffix sorting, BWT construction, and direct rank scans. It has not been compiled or run.

The separate [`fm_index_locate`](f/fm_index_locate/README.md) sampled-LF locate operation has a Mojo draft retaining suffix-array order and supplied sample stride. It has not been compiled or run.

The third FM-index operation, [`fm_index_display`](f/fm_index_display/README.md), now has a Mojo draft using the sampled inverse-suffix position and LF reconstruction. It has not been compiled or run.

The existing BitBench [`five11`](f/five11/README.md) packet decoder now has a Mojo draft retaining the 10,000-pass workload, with bounded framing and complexity documented. It has not been compiled or run.

The [`frequent_itemset_delivery`](f/frequent_itemset_delivery/README.md) one-level occurrence delivery now has a Mojo draft and complexity documentation. It has not been compiled or run.

The related [`frequent_itemset_conditional_db_reduction`](f/frequent_itemset_conditional_db_reduction/README.md) transform now has a Mojo draft preserving support pruning, row merging, and sorted masks. Complexity is documented; it has not been compiled or run.

The full [`frequent_itemset_backtrack`](f/frequent_itemset_backtrack/README.md) tail-extension enumeration now has a Mojo draft with an explicit DFS stack and projected row sets. Its complexity is documented; it has not been compiled or run.

The existing [`gardenia_fb_trim_scc`](g/gardenia_fb_trim_scc/README.md) profile now has a Mojo draft preserving iterative trim, forward/backward reachability, and three-way subgraph splitting. It has not been compiled or run.

The distinct [`gardenia_gm_vertex_coloring`](g/gardenia_gm_vertex_coloring/README.md) worklist coloring has a Mojo draft with snapshot first-fit and conflict requeue phases. It has not been compiled or run.

Static review of [`gardenia_symgs`](g/gardenia_symgs/README.md) found that all nine original ports tested symmetry before later CSR rows had been loaded, potentially reading uninitialized C data or rejecting valid matrices. Each original port now loads and validates column indices before symmetry checks. A Mojo draft is also present. These changes have not been compiled or run.

The SymGS Mojo draft is now present and loads the entire CSR column/value arrays before symmetry validation. It retains the forward/reverse color schedule and has not been compiled or run.

The existing [`gbbs_shiloach_vishkin_spanning_forest`](g/gbbs_shiloach_vishkin_spanning_forest/README.md) witness-edge workload now has a Mojo draft preserving synchronous hooks and first-edge witnesses. It has not been compiled or run.

The [`gbbs_k_core_decomposition`](g/gbbs_k_core_decomposition/README.md) shell-peeling workload now has a Mojo draft, included in the suite's port inventory. It has not been compiled or run.

The distinct [`gbbs_k_clique_count`](g/gbbs_k_clique_count/README.md) fixed four-clique workload now has a Mojo draft preserving degree filtering and oriented-neighborhood intersections. It has not been compiled or run.

The [`gbbs_charikar_densest_subgraph`](g/gbbs_charikar_densest_subgraph/README.md) workload now has a Mojo draft preserving clamped shell order and induced-suffix density scoring. It has not been compiled or run.

The distinct [`gbbs_five_cycle_count`](g/gbbs_five_cycle_count/README.md) canonical undirected five-cycle workload now has a Mojo draft. It has not been compiled or run.

The separate [`gbbs_greedy_plus_plus_densest_subgraph`](g/gbbs_greedy_plus_plus_densest_subgraph/README.md) workload has a Mojo draft preserving twenty load-updating peeling rounds. It has not been compiled or run.

The distinct [`gbbs_bkv12_densest_subgraph`](g/gbbs_bkv12_densest_subgraph/README.md) threshold-batch peeling workload now has a Mojo draft. It has not been compiled or run.

The [`gbbs_label_propagation_clustering`](g/gbbs_label_propagation_clustering/README.md) asynchronous one-sweep profile now has a Mojo draft. It has not been compiled or run.

The [`gbbs_cosimrank_pair_similarity`](g/gbbs_cosimrank_pair_similarity/README.md) bounded dyadic pair query now has a Mojo draft retaining the walk and discounted dot-product recurrence. It has not been compiled or run.

The [`gbbs_approximate_set_cover`](g/gbbs_approximate_set_cover/README.md) bucketed priority-acquisition workload now has a Mojo draft. It has not been compiled or run.

The [`gbbs_barenboim_elkin_degeneracy_order`](g/gbbs_barenboim_elkin_degeneracy_order/README.md) density-guided batch ordering now has a Mojo draft. It has not been compiled or run.

The distinct [`gbbs_goodrich_pszona_degeneracy_order`](g/gbbs_goodrich_pszona_degeneracy_order/README.md) single-vertex minimum-degree ordering now has a Mojo draft. It has not been compiled or run.

The [`gbbs_low_diameter_decomposition`](g/gbbs_low_diameter_decomposition/README.md) deterministic center-batch and frontier-growth workload now has a Mojo draft. It has not been compiled or run.

The [`gbbs_ss_widest_path`](w/gbbs_ss_widest_path/README.md) max-min path workload now has a Mojo draft and is included in the suite port inventory. It has not been compiled or run.

The [`gapbs_ordered_triangle_count`](t/gapbs_ordered_triangle_count/README.md) sorted-neighbor intersection workload now has a Mojo draft. It has not been compiled or run.

The [`gapbs_delta_step_sssp`](d/gapbs_delta_step_sssp/README.md) bucketed shortest-path workload now has a Mojo draft preserving same-bucket processing and stale-event handling. It has not been compiled or run.

The [`gapbs_pagerank_pull_gs`](p/gapbs_pagerank_pull_gs/README.md) asynchronous pull PageRank workload now has a Mojo draft with binary32 state and ordered updates. It has not been compiled or run.

Static review of [`graphai_frontier_sampler`](g/graphai_frontier_sampler/README.md) corrected all nine original ports to validate sampling choices before reporting output-capacity errors. A Mojo draft is also present. These changes have not been compiled or run.

The frontier sampler now also has a Mojo draft; it validates and stages all
three sampled frontiers before checking output capacity. It has not been
compiled or run.

The [`graphai_gcn_aggregation`](g/graphai_gcn_aggregation/README.md) normalized CSR neighbor aggregation now has a Mojo draft retaining edge and feature accumulation order. It has not been compiled or run.

The distinct [`graphai_sage_aggregation`](g/graphai_sage_aggregation/README.md) mean-neighbor workload now has a Mojo draft. Its documentation clarifies scaled-neighbor accumulation order; it has not been compiled or run.

The [`graphai_hac_complete_linkage`](g/graphai_hac_complete_linkage/README.md) connected graph HAC workload now has a Mojo draft preserving maximum-edge merges and source-shaped dendrogram output. It has not been compiled or run.

The [`graphai_cf_sgd_sweep`](g/graphai_cf_sgd_sweep/README.md) synchronous collaborative-filtering update now has a Mojo draft. It has not been compiled or run.

The distinct [`graphai_gat_aggregation`](g/graphai_gat_aggregation/README.md) attention-softmax workload now has a Mojo draft. It has not been compiled or run.

The [`geometric_greedy_compass_routing`](g/geometric_greedy_compass_routing/README.md) two-mode local-routing workload now has a Mojo draft. It has not been compiled or run.

The [`greedy_dual_weighted_caching`](g/greedy_dual_weighted_caching/README.md) hit-reset credit algorithm now has a Mojo draft. It has not been compiled or run.

The [`harmonic_k_bin_packing`](h/harmonic_k_bin_packing/README.md) class-local Next-Fit workload now has a Mojo draft. It has not been compiled or run.

The [`lex_bfs`](l/lex_bfs/README.md) explicit-label ordering workload has a Mojo draft. The ports and primary oracle were subsequently corrected to prioritize earlier neighbors, matching the partition-refinement verifier; previously they instead selected by newest neighbors. These edits have not been compiled or run.

The LexBFS workload metadata and two expected orderings were also corrected to match that earlier-neighbor rule; the old fixtures encoded newest-neighbor behavior. These fixture edits have not been run.

The [`gbbs_scan_structural_clustering`](g/gbbs_scan_structural_clustering/README.md) deterministic core-component and border-attachment profile now has a Mojo draft. It has not been compiled or run.

The [`ldfs_ordering_certificate`](l/ldfs_ordering_certificate/README.md) bounded ordering and witness-certificate workload now has a Mojo draft. It has not been compiled or run.

The LDFS primary oracle now compares visitation positions rather than vertex IDs, matching the ordering rule used by its ports and independent verifier. The contract includes a distinguishing example; this correction has not been run.

The LDFS workload now includes that nonzero-start graph as a concrete ordering-and-witness fixture, and explicitly describes labels in terms of visitation positions. The fixture has not been run.

The [`landlord_file_caching`](l/landlord_file_caching/README.md) variable-size cache-credit workload now has a Mojo draft, distinct from the equal-size hit-reset Greedy Dual profile. It has not been compiled or run.

The [`list_ranking_independent_set_contraction`](l/list_ranking_independent_set_contraction/README.md) weighted contraction and restoration workload now has a Mojo draft. It has not been compiled or run.

The [`lz77_infinite_rightmost`](l/lz77_infinite_rightmost/README.md) overlapping infinite-window parser now has a Mojo draft, retaining its rightmost tie rule. It has not been compiled or run.

The [`lz78_flexible_parsing`](l/lz78_flexible_parsing/README.md) non-greedy one-lookahead parser now has a Mojo draft, distinct from ordinary greedy LZ78. It has not been compiled or run.

The [`llubenchmark_list_traversal_growth`](l/llubenchmark_list_traversal_growth/README.md) index-linked traversal and fractional-growth workload now has a Mojo draft. It has not been compiled or run.

The [`min_sum_set_cover_greedy`](m/min_sum_set_cover_greedy/README.md) first-hit scheduling workload now has a Mojo draft; its objective differs from minimum-cardinality set cover. It has not been compiled or run.

The [`min_hash_k_partition`](m/min_hash_k_partition/README.md) supplied-bucket MinHash sketch now has a Mojo draft; it differs from independent-rank and bottom-k sketches. It has not been compiled or run.

The distinct [`min_hash_k_mins`](m/min_hash_k_mins/README.md) independent-rank and [`min_hash_bottom_k`](m/min_hash_bottom_k/README.md) without-replacement workloads now also have Mojo drafts. They have not been compiled or run.

Static review of [`mmpfh_compacted_trie_rank`](m/mmpfh_compacted_trie_rank/README.md) found and corrected a missing node-array argument in its Rust rank lookup; a Mojo draft was also added. Neither has been compiled or run.

The distinct [`mmpfh_bucketing`](m/mmpfh_bucketing/README.md) equal-size bucket and explicit distributor workload now has a Mojo draft. It has not been compiled or run.

The [`mibench_network_dijkstra`](m/mibench_network_dijkstra/README.md) FIFO label-correcting shortest-path workload now has a Mojo draft; it retains queued distance snapshots and is distinct from label-setting Dijkstra. It has not been compiled or run.

The [`mccat_qbsort`](m/mccat_qbsort/README.md) repeated bubble-sort/first-pivot quicksort workload now has a Mojo draft using bounded arrays for partitioning. It has not been compiled or run.

Static review found an off-by-one in the Elisa McCat bubble pass and an immutable loop variable in its quicksort; both were corrected, and the upper partition is now processed first. The README now records that the existing array-based quicksort ports do not preserve the source's linked-list representation. These edits have not been compiled or run.

The McCat Rust quicksort draft now uses allocated linked-list partitions, prepends each element, and recursively processes the upper list first, following the pinned source's structure. Other ports still use arrays and need the same fidelity review. The Rust change has not been compiled or run.

The McCat C++ quicksort draft now likewise uses singly linked allocated partitions, prepending entries and recursing on the upper list first. It has not been compiled or run; the remaining ports still use arrays.

The McCat C quicksort draft now uses separately allocated singly linked partitions and upper-first recursion, including cleanup on allocation failure. It has not been compiled or run; C3, Elisa, Mojo, Nim, Odin, V, and Zig remain array-based.

The McCat Nim quicksort draft now uses reference-linked allocated nodes, prepended partitions, and upper-first recursion. It has not been compiled or run; C3, Elisa, Mojo, Odin, V, and Zig remain array-based.

The McCat Mojo draft now models the linked partition traversal using index-linked node pools and upper-first recursion. Its pooled allocation differs from the source's per-node allocation. It has not been compiled or run; C3, Elisa, Odin, V, and Zig remain array-based.

The McCat Elisa draft now uses an index-linked node pool for the same partition traversal and upper-first recursion without additional raw pointers. Its pool differs from the source's per-node allocation. It has not been compiled or run; C3, Odin, V, and Zig remain array-based.

The McCat Zig draft now uses individually allocated linked nodes, prepended partitions, upper-first recursion, and allocation-failure cleanup. It has not been compiled or run; C3, Odin, and V remain array-based.

The McCat Odin draft now uses index-linked partition nodes with upper-first recursion; the bounded pool differs from the source's per-node allocations. It has not been compiled or run. C3 and V remain array-based.

The McCat C3 draft now uses index-linked partitions and upper-first recursion; its bounded pool differs from source allocation. A bubble-pass off-by-one was also corrected. It has not been compiled or run; V remains array-based.

The McCat V draft now uses index-linked partitions and upper-first recursion. Its bounded pool differs from the source's per-node allocations; it has not been compiled or run.

The [`max_cut_sahni_gonzalez`](m/max_cut_sahni_gonzalez/README.md) deterministic greedy half-approximation now has a Mojo draft. It is distinct from supplied-hyperplane Goemans–Williamson rounding and has not been compiled or run.

The [`max_cut_gw_rounding`](m/max_cut_gw_rounding/README.md) supplied-hyperplane rounding workload now also has a Mojo draft. It has not been compiled or run.

The [`metric_tsp_tree_doubling`](m/metric_tsp_tree_doubling/README.md) deterministic Kruskal and preorder shortcutting workload now has a Mojo draft. It has not been compiled or run.

The distinct [`metric_tsp_christofides`](m/metric_tsp_christofides/README.md) odd-vertex matching and Eulerian shortcut workload now has a Mojo draft. It has not been compiled or run.

The [`next_fit_increasing_bin_packing`](n/next_fit_increasing_bin_packing/README.md) shared increasing-order First/Best/Next Fit profile now has a Mojo draft; those names remain consolidated as one algorithm. It has not been compiled or run.

The [`online_interval_coloring`](o/online_interval_coloring/README.md) arrival-ordered level and First-Fit workload now has a Mojo draft. It has not been compiled or run.

The [`orthogonal_range_reporting_2d`](o/orthogonal_range_reporting_2d/README.md) static range-tree reporting workload now has a Mojo draft. It has not been compiled or run.

The [`substring_parsimony`](o/substring_parsimony/README.md) finite-metric tree dynamic program and optimal-label enumeration now has a Mojo draft. It has not been compiled or run.

The [`optimal_stable_marriage`](o/optimal_stable_marriage/README.md) minimum-regret thresholded deferred-acceptance workload now has a Mojo draft. It differs in objective from men-optimal stable matching and has not been compiled or run.

The [`private_noisy_power_iteration`](p/private_noisy_power_iteration/README.md) fixed-point supplied-noise workload now has a Mojo draft. Static review also corrected Rust negative-comparison token spacing. Neither edit has been compiled or run.

Static review also corrected Rust negative-comparison token spacing in `mean_absolute_percentage_error`, `mean_squared_logarithmic_error`, `parboil_spmv_jds`, and `pow`; these edits have not been compiled or run.

The Rust `p2_quantile_estimator` draft also had a negative-comparison token and leading-dot floating literals corrected during static review. It has not been compiled or run.

The [`ppsz_k_sat_trace`](p/ppsz_k_sat_trace/README.md) bounded clause-implication and supplied-guess trace now has a Mojo draft. It has not been compiled or run.

The [`pannotia_local_minimum_mis`](p/pannotia_local_minimum_mis/README.md) synchronous priority-round workload now has a Mojo draft; the equivalent GBBS RandomGreedy profile remains consolidated with it. It has not been compiled or run.

The [`pannotia_priority_coloring`](p/pannotia_priority_coloring/README.md) maximum and maximum/minimum coloring-round workload now has a Mojo draft. It has not been compiled or run.

The [`point_pattern_translation_lex_scan`](p/point_pattern_translation_lex_scan/README.md) ordered exact-translation workload now has a Mojo draft. It remains distinct from translation voting and has not been compiled or run.

The [`point_pattern_translation_voting`](p/point_pattern_translation_voting/README.md) largest-common-point translation-voting workload now also has a Mojo draft. It has not been compiled or run.

The [`parboil_stencil_laplacian`](p/parboil_stencil_laplacian/README.md) ordered Float32 seven-point update now has a Mojo draft. Its floating-point contraction behavior remains unverified; it has not been compiled or run.

The [`parboil_sad`](p/parboil_sad/README.md) 4×4 motion-search SAD and hierarchical larger-block aggregation workload now has a Mojo draft. It has not been compiled or run.

The [`parboil_spmv_jds`](p/parboil_spmv_jds/README.md) preconverted jagged-diagonal Float32 sparse matrix-vector workload now has a Mojo draft. Its floating-point contraction behavior remains unverified; it has not been compiled or run.

The [`parboil_mri_q`](p/parboil_mri_q/README.md) two-pass Float32 magnitude and direct Fourier accumulation workload now has a Mojo draft. Its math-library and floating-point contraction behavior remain unverified; it has not been compiled or run.

The [`polybench_symm`](p/polybench_symm/README.md) lower-triangle symmetric matrix update now has a Mojo draft. Its floating-point contraction behavior remains unverified; it has not been compiled or run.

The [`polybench_ludcmp`](p/polybench_ludcmp/README.md) source-initialized LU and triangular-solve workload now has a Mojo draft. Its floating-point contraction behavior remains unverified; it has not been compiled or run.

The [`polybench_cholesky`](p/polybench_cholesky/README.md) source-initialized Cholesky workload now has a Mojo draft. Its floating-point contraction behavior remains unverified; it has not been compiled or run.

The [`polybench_gramschmidt`](p/polybench_gramschmidt/README.md) modified Gram–Schmidt QR workload now has a Mojo draft. Its floating-point contraction behavior remains unverified; it has not been compiled or run.

The [`polybench_adi`](p/polybench_adi/README.md) alternating-direction implicit sweep workload now has a Mojo draft. Its floating-point contraction behavior remains unverified; it has not been compiled or run.

The [`queens`](q/queens/README.md) McGill count-only owner-array search and text-output workload now has a Mojo draft. It has not been compiled or run.

The [`ring_exact_covering_protocol`](r/ring_exact_covering_protocol/README.md) serial asynchronous sensor-movement workload now has a Mojo draft. It has not been compiled or run.

The [`rodinia_leukocyte_gicov`](r/rodinia_leukocyte_gicov/README.md) seven-ellipse Float32 Welford scoring workload now has a Mojo draft. Its floating-point contraction behavior remains unverified; it has not been compiled or run.

The [`rodinia_pathfinder`](r/rodinia_pathfinder/README.md) chunked row-frontier grid dynamic program now has a Mojo draft. It has not been compiled or run.

The [`rodinia_heartwall_template_match`](r/rodinia_heartwall_template_match/README.md) masked normalized template-scoring workload now has a Mojo draft. Its floating-point contraction behavior remains unverified; it has not been compiled or run.

The [`rodinia_dwt2d`](r/rodinia_dwt2d/README.md) integer 5/3 lifting and linear band-layout workload now has a Mojo draft. It has not been compiled or run.

The [`rodinia_srad_v2`](r/rodinia_srad_v2/README.md) mixed-precision diffusion coefficient and update workload now has a Mojo draft. Its floating-point contraction behavior remains unverified; it has not been compiled or run.

The [`rodinia_hybridsort`](r/rodinia_hybridsort/README.md) Float32 histogram scatter and per-bucket merge workload now has a Mojo draft. Its floating-point behavior remains unverified; it has not been compiled or run.

The [`rodinia_particlefilter_naive`](r/rodinia_particlefilter_naive/README.md) supplied-noise weighting and systematic resampling workload now has a Mojo draft. Its math-library and floating-point contraction behavior remain unverified; it has not been compiled or run.

The [`random_3sat_greedy_dpll`](r/random_3sat_greedy_dpll/README.md) no-backtracking unit-first greedy trace now has a Mojo draft, distinct from backtracking DPLL. It has not been compiled or run.

The [`randomized_marking_page_caching`](r/randomized_marking_page_caching/README.md) supplied-victim-tape Marking cache workload now has a Mojo draft. It has not been compiled or run.

The [`randomized_contraction_edge_sampling`](r/randomized_contraction_edge_sampling/README.md) supplied-edge contraction phase now has a Mojo draft. It does not claim to implement the chapter's full algorithm and has not been compiled or run.

The distinct run-length-native [`rle_lcs_block_dp`](r/rle_lcs_block_dp/README.md) and [`rle_levenshtein_block_dp`](r/rle_levenshtein_block_dp/README.md) boundary-propagation workloads now have Mojo drafts. They have not been compiled or run.

The [`robust_scheduling_single_arrival_migration`](r/robust_scheduling_single_arrival_migration/README.md) exact-OPT checked migration transition now has a Mojo draft. It has not been compiled or run.

The [`sum_of_squares_bin_packing`](s/sum_of_squares_bin_packing/README.md) online occupancy-score placement workload now has a Mojo draft. It has not been compiled or run.

The [`streaming_triangles`](s/streaming_triangles/README.md) edge-and-wedge reservoir trace now has a Mojo draft, preserving the documented retained-sample limitation. It has not been compiled or run.

The [`suffix_tree_pattern_occurrences`](s/suffix_tree_pattern_occurrences/README.md) compressed-edge construction and descendant-leaf query now has a Mojo draft. It has not been compiled or run.

The [`sublinear_bipartiteness_walk_tester`](s/sublinear_bipartiteness_walk_tester/README.md) supplied-draw lazy-walk parity-collision kernel now has a Mojo draft. It has not been compiled or run.

Static registration review confirms the streaming-triangle, suffix-tree query, and sublinear bipartiteness profiles appear in the byte-output runner and verifier, and that the build resolver can follow the latter's nonstandard Mojo source-directory link. Their implementations remain uncompiled and unrun. Complexity bounds and two broken cross-reference links were corrected in their package documentation.

Static review of [`technology_mapping_minimum_area_tree_cover`](t/technology_mapping_minimum_area_tree_cover/README.md) found that all nine existing ports pushed primary-input leaves during reconstruction and then interpreted them as gates, risking invalid indexing and corrupt output. Each now skips leaves before reading their gate choice. These changes have not been compiled or run.

The tree-cover workload now also has a Mojo draft with leaf-safe reconstruction and ascending-ID tie breaking. It has not been compiled or run.

The tree-cover independent verifier incorrectly required an absorbed inverter to have a standalone cover for the left- and right-inverter patterns. That precondition has been removed, and a fixture now describes a valid combined pattern with standalone INV disabled. The correction and fixture have not been executed.

The combined-pattern fixture's serialized output was also shorter than its declared five i64 words; both combined-pattern cases now encode the full output.

The [`timetable_earliest_arrival_dijkstra`](t/timetable_earliest_arrival_dijkstra/README.md) FIFO scheduled-arc workload now has a Mojo draft. It has not been compiled or run.

The [`undirected_feedback_vertex_set`](u/undirected_feedback_vertex_set/README.md) bounded iterative-compression workload now has a Mojo draft. It has not been compiled or run.

The [`vertex_cover_kernelization`](v/vertex_cover_kernelization/README.md) deterministic degree-reduction workload now has a Mojo draft. It has not been compiled or run.

The [`vertex_cover_search_trees`](v/vertex_cover_search_trees/README.md) exact maximum-degree branch-and-search workload now has a Mojo draft. It has not been compiled or run.

The [`vector_bin_packing`](v/vector_bin_packing/README.md) multidimensional input-order First Fit workload now has a Mojo draft. It has not been compiled or run.

The [`vector_scheduling`](v/vector_scheduling/README.md) supplied-random-assignment workload now has a Mojo draft. It has not been compiled or run.

The [`voronoi_delaunay_empty_circle`](v/voronoi_delaunay_empty_circle/README.md) exact determinant and exhaustive empty-circle workload now has a Mojo draft. It has not been compiled or run.

The [`wspd`](w/wspd/README.md) median-split well-separated pair decomposition now has a Mojo draft. Floating-point boundary behavior remains unverified; it has not been compiled or run.

The [`zdd_family_count`](z/zdd_family_count/README.md) zero-suppressed family construction and counting workload now has a Mojo draft. Static review also corrected its documented root-to-terminal variable order and a cross-reference link. The draft has not been compiled or run.

The [`yds_speed_scaling`](y/yds_speed_scaling/README.md) exact-rational critical-interval workload now has a Mojo draft. It has not been compiled or run.

The [`doe_xsbench_unionized_macro_xs`](x/doe_xsbench_unionized_macro_xs/README.md) validated union-grid lookup and interpolation workload now has a Mojo draft with the upstream MIT notice retained. Floating-point behavior is unverified; it has not been compiled or run.

The [`xgboost`](x/xgboost/README.md) synthetic bounded forest-inference workload now has a Mojo draft. It has not been compiled or run.

Static review adjusted the XGBoost Mojo draft to retain the encoded-node traversal used by the workload. It remains uncompiled and unrun.

The [`npb_is`](n/npb_is/README.md) full class-W integer-sort workload now has a Mojo draft preserving generation, warm-up, bucket scatter, partial ranks, and full-order verification. It has not been compiled or run.

The [`nsichneu`](n/nsichneu/README.md) source-ordered bounded Petri-net transition workload now has a Mojo draft. It has not been compiled or run.

The [`nbench_fourier_coefficients`](n/nbench_fourier_coefficients/README.md) source-order transcendental integration workload now has a Mojo draft. Its documentation explicitly records the source loop's 198 interior samples. Math-library and floating-point behavior are unverified; no code was compiled or run.

The [`nbench_neural_network`](n/nbench_neural_network/README.md) bounded back-propagation workload now has a Mojo draft. Its floating-point and truncation behavior remain unverified; it has not been compiled or run.

The [`nbench_huffman_compression`](n/nbench_huffman_compression/README.md) Float32-frequency tree, bit encoding, and decoding workload now has a Mojo draft. It has not been compiled or run.

The [`npb_serial_dc`](n/npb_serial_dc/README.md) bounded multidimensional grouping workload now has a Mojo draft. The NBench Huffman oracle link was also corrected. No code was compiled or run.

The [`nussinov`](n/nussinov/README.md) PolyBench RNA-folding recurrence now has a Mojo draft. It has not been compiled or run.

The [`next_fit_decreasing_bin_packing`](n/next_fit_decreasing_bin_packing/README.md) stable-sort and next-fit workload now has a Mojo draft. It has not been compiled or run.

The [`olden_em3d`](o/olden_em3d/README.md) sequential electric/magnetic node-update workload now has a Mojo draft. Floating-point behavior remains unverified; it has not been compiled or run.

The [`olden_power`](o/olden_power/README.md) constrained leaf optimizer and network voltage recurrence now has a Mojo draft. Its floating-point and rounding behavior remain unverified; it has not been compiled or run.

The [`olden_bh`](o/olden_bh/README.md) octree monopole gravity query now has a Mojo draft. Floating-point behavior remains unverified; it has not been compiled or run.

The [`olden_tsp`](o/olden_tsp/README.md) closest-point insertion and Karp cycle merge now have a Mojo draft. Floating-point tie and rounding behavior remain unverified; it has not been compiled or run.

Additional catalog cross-check: [OI Wiki's dominator-tree article](https://oi-wiki.org/graph/dominator-tree/) describes semidominator-based immediate dominators, already represented by [`lengauer_tarjan_dominator_tree`](l/lengauer_tarjan_dominator_tree/README.md). Its iterative data-flow alternative is separately represented by [`dominator_tree`](d/dominator_tree/README.md). The article is therefore an additional provenance lead, not a new benchmark; no article code or text is copied. The Olden Barnes–Hut README's n-body comparison link was corrected.

The [`parboil_lbm`](p/parboil_lbm/README.md) D3Q19 collision, streaming, and obstacle-bounce workload now has a Mojo draft. Mixed-precision and contraction behavior remain unverified; it has not been compiled or run.

The [`parboil_cutcp`](p/parboil_cutcp/README.md) cell-hashed cutoff-potential lattice workload now has a Mojo draft. Float32 arithmetic and output rounding remain unverified; it has not been compiled or run.

The [`parboil_tpacf_cross_correlation`](p/parboil_tpacf_cross_correlation/README.md) angular pair-histogram workload now has a Mojo draft. Math-library and Float32 boundary behavior remain unverified; it has not been compiled or run.

The [`parboil_histo`](p/parboil_histo/README.md) repeated-clear saturating histogram workload now has a Mojo draft. It has not been compiled or run.

The [`parboil_mri_gridding`](p/parboil_mri_gridding/README.md) Kaiser–Bessel sample-scatter workload now has a Mojo draft. Mixed-precision and rounding behavior remain unverified; it has not been compiled or run.

The [`ptrdist_yacr2_maze1_dogleg`](p/ptrdist_yacr2_maze1_dogleg/README.md) bounded source-order routing decision now has a Mojo draft. It has not been compiled or run.

The [`pcompress2`](p/pcompress2/README.md) cyclic-rotation, run-packet, and adaptive arithmetic-coding pipeline now has a Mojo draft. It has not been compiled or run.

The [`picojpeg`](p/picojpeg/README.md) restricted baseline JPEG block decoder now has a Mojo draft. It has not been compiled or run.

Static review of [`prolangs_c_cdecl`](p/prolangs_c_cdecl/README.md) found that Rust, Zig, Elisa, Nim, Odin, and V skipped whitespace inside identifier scans; all except Zig also did so inside decimal scans. Those scans now stop at whitespace, matching the bounded grammar and the C-family ports. These edits have not been compiled or run.

The cdecl workload now records two whitespace-separated token regression cases, with matching suite metadata. Static review also corrected its launcher metadata key to the one required by both suite readers. No code or checks were run.

The bounded [`prolangs_c_cdecl`](p/prolangs_c_cdecl/README.md) declarator parser now has a Mojo draft, including whitespace-separated token handling. It has not been compiled or run.

The [`prolangs_c_numeric_token`](p/prolangs_c_numeric_token/README.md) bounded source-order numeric lexer now has a Mojo draft. Float32 behavior remains unverified; it has not been compiled or run.

The [`prolangs_c_gnugo_liberty_count`](p/prolangs_c_gnugo_liberty_count/README.md) group and distinct-liberty traversal now has a Mojo draft. It has not been compiled or run.

The [`prolangs_c_gnugo_suicide`](p/prolangs_c_gnugo_suicide/README.md) source-specific move and Ko predicate now has a Mojo draft. It has not been compiled or run.

The [`ptrdist_sim_local_affine_alignment`](p/ptrdist_sim_local_affine_alignment/README.md) first-best affine-gap local alignment workload now has a Mojo draft. It has not been compiled or run.

The [`ptrdist_ks`](p/ptrdist_ks/README.md) balanced greedy paired-swap partition workload now has a Mojo draft. It has not been compiled or run.

The [`rna_mfe_loop_energy_dp`](r/rna_mfe_loop_energy_dp/README.md) bounded loop-energy dynamic program now has a Mojo draft. Static review also corrected the Rust helper's unsafe pointer declaration. Neither change has been compiled or run.

The [`reverse_search_permutation_enumeration`](r/reverse_search_permutation_enumeration/README.md) first-descent reverse-search traversal now has a Mojo draft. It has not been compiled or run.

The [`rodinia_euler3d_flux`](r/rodinia_euler3d_flux/README.md) four-face finite-volume flux workload now has a Mojo draft. Its Float32 operation ordering and contraction remain unverified; it has not been compiled or run.

The [`rate_monotonic_scheduling`](r/rate_monotonic_scheduling/README.md) critical-instant discrete scheduling simulation now has a Mojo draft; its comparison link was corrected. It has not been compiled or run.

The [`signed_permutation_reversal_sequence`](s/signed_permutation_reversal_sequence/README.md) bounded breadth-first shortest-reversal sequence now has a Mojo draft. It has not been compiled or run.

The [`single_parameter_truthful_payment`](s/single_parameter_truthful_payment/README.md) exact step-allocation payment workload now has a Mojo draft. It has not been compiled or run.

The [`slre`](s/slre/README.md) bounded ordered-alternation regex-search workload now has a Mojo draft. It has not been compiled or run.

The [`statemate`](s/statemate/README.md) fixed no-stimulus state-settlement workload now has a Mojo draft. It has not been compiled or run.

The [`string_heap_sort`](s/string_heap_sort/README.md) fixed-width lexicographic heapsort workload now has a Mojo draft. It has not been compiled or run.

The [`scimark2_sor`](s/scimark2_sor/README.md) fixed-point in-place weighted grid relaxation now has a Mojo draft; its Gauss–Seidel comparison link was corrected. It has not been compiled or run.

The same static token audit corrected negative-comparison spacing in nine additional Rust ports: `word_frequency_functions`, `gardenia_symgs`, `random_3sat_greedy_dpll`, `quaternions`, `cbench_ispell_lookup_chain`, `beta_skeleton`, `symmetric_mean_absolute_percentage_error`, `rodinia_streamcluster_pgain`, and `lamberts_ellipsoidal_distance`. These edits have not been compiled or run.

The [`stanford_queens`](s/stanford_queens/README.md) repeated first-solution search now has a Mojo draft. It has not been compiled or run.

The [`shootout_random`](s/shootout_random/README.md) repeated linear congruential generator workload now has a Mojo draft. It has not been compiled or run.

The [`shootout_strcat`](s/shootout_strcat/README.md) bounded string-append and length-scan workload now has a Mojo draft. It has not been compiled or run.

The [`shootout_hello`](s/shootout_hello/README.md) fixed-output launcher workload now has a Mojo draft. It has not been compiled or run.

The [`shootout_hash`](s/shootout_hash/README.md) chained hexadecimal-insertion and decimal-lookup workload now has a Mojo draft. It has not been compiled or run.

The [`shootout_lists`](s/shootout_lists/README.md) circular doubly linked list workload now has a Mojo draft. It has not been compiled or run.

Static contract review added time and space descriptions to `shootout_hash`, `shootout_lists`, and `shootout_strcat`, and documented the workload distinctions that justify retaining them. No project code was executed.

The [`sequential_lut_k_cut_enumeration`](s/sequential_lut_k_cut_enumeration/README.md) bounded delayed-cut DAG recurrence now has a Mojo draft. It has not been compiled or run.

The [`sensor_energy_balance_estimator_trace`](s/sensor_energy_balance_estimator_trace/README.md) exact rational estimator trace now has a Mojo draft. It has not been compiled or run.

The [`secretary_1e_threshold`](s/secretary_1e_threshold/README.md) bounded secretary threshold rule now has a Mojo draft. It has not been compiled or run.

The [`single_source_dynamic_reachability_rebuild`](s/single_source_dynamic_reachability_rebuild/README.md) traversal-after-update workload now has a Mojo draft. It has not been compiled or run.

The [`ski_rental_deterministic`](s/ski_rental_deterministic/README.md) bounded rent-then-buy policy now has a Mojo draft. It has not been compiled or run.

The [`shortest_elapsed_time_first`](s/shortest_elapsed_time_first/README.md) bounded attained-service scheduling trace now has a Mojo draft. It has not been compiled or run.

The [`spatial_motif_same_type_contact_pmf`](s/spatial_motif_same_type_contact_pmf/README.md) exact contact-distribution calculation now has a Mojo draft. It has not been compiled or run.

Static review found that `square_free_factor_list` could return a duplicate result before checking a later invalid element. C, Rust, and Mojo now validate all values first, and the workload records this precedence case. The other language ports and suite oracle still need the same audit and any necessary fixes; no checks were run.

The same validation-order correction has now been applied to C3, C++, Elisa, Nim, Odin, V, and Zig. The contract states the precedence explicitly; the suite oracle still needs review. These changes remain uncompiled and untested.

Static inspection found no algorithm-specific `square_free_factor_list` registration in the shared i64-array scalar runner or verifier. A set-based oracle draft now encodes full-input validation, but runner and verifier integration remain outstanding and untested.

Subsequent static inspection confirms runner and verifier wiring is now present. The Elisa, V, and Zig drafts lacked the nonempty-null guard used by the other ports; those guards are now added, and Elisa uses a bounded view internally. These changes remain uncompiled and unexecuted.

Draft runner and verifier wiring now checks `square_free_factor_list` against that oracle and includes duplicate-before-invalid and length-boundary cases. It has not been executed; build and harness integration still require validation.

Static tracing confirmed that the shared build selects the workload's declared scalar model and resolves the matching source by name. The verifier now checks fixture metadata and oracle results and defines additional bounded generated cases. All integration remains unexecuted.

Duplicate review compared `square_free_factor_list` with `contains_duplicate`: their results are complementary, but their pairwise-scan and heapsort-and-scan implementations have materially different computational behavior. Both are retained with reciprocal contract links and complexity notes.

Static contract review added complexity descriptions to `sum_of_squares_bin_packing`, `shortest_elapsed_time_first`, `ski_rental_deterministic`, and `sensor_energy_balance_estimator_trace`. No project code was executed.

Static review found a `slicing_floorplan_stockmeyer` orientation tie bug: a dominated child can become dimension-equal at an ancestor, losing a lexicographically better mask. Added a concrete expected-output fixture and documented that the primary oracle and ports require a tie-preserving fix. Also corrected the SPLASH-2 water V source link. No code or tests were run.

The nine existing `slicing_floorplan_stockmeyer` ports and primary oracle now retain dimension-dominated candidates when their orientation mask is lexicographically better. The contract and workload describe this tie-preserving pruning. The change and regression fixture remain uncompiled and untested.

Static review added the transposed floorplan tie case, updated the oracle-method metadata, and documented bounded merge complexity. Neither fixture nor any implementation was executed.

The `slicing_floorplan_stockmeyer` profile now also has a Mojo draft implementing the tie-preserving candidate recurrence. It has not been compiled or run.

Static review documented complexity and scope for `secretary_1e_threshold`, `spatial_motif_same_type_contact_pmf`, and `sequential_lut_k_cut_enumeration`; the secretary profile's runner and verifier registrations were also located. Nothing was executed.

The `sugiyama_barycentric_crossing_reduction` bounded down-up sweep now has a Mojo draft. It has not been compiled or run.

The `spectral_norm` implicit-matrix power iteration now has a Mojo draft, and its contract records time and space complexity. Floating-point behavior remains unverified; the draft has not been compiled or run.

The `st_planar_leftmost_augmenting_flow` bounded ordered residual-DFS workload now has a Mojo draft. It has not been compiled or run.

The `suffix_tree_from_sa_lcp` rightmost-path construction now has a Mojo draft. It has not been compiled or run.

CP-Algorithms crosswalk: its [2-SAT implication-graph and Kosaraju method](https://cp-algorithms.com/graph/2SAT.html) is already represented by [`two_sat`](t/two_sat/README.md), so no duplicate package was added. Its [undirected Euler trail construction](https://cp-algorithms.com/graph/euler_path.html) is already represented on simple graphs by [`eulerian_trail_undirected_simple`](e/eulerian_trail_undirected_simple/README.md); its multigraph input scope remains a coverage gap, while the directed traversal is separately represented by [`eulerian_path`](e/eulerian_path/README.md). These references were used as algorithm indexes; no source text or code was reused.

The `truthful_multicast_pmst_tree` Kruskal-and-prune workload now has a Mojo draft. It has not been compiled or run.

The `treewidth_exact_elimination_order` exhaustive elimination-order workload now has a Mojo draft. It has not been compiled or run.

The `treewidth_min_fill_elimination` greedy minimum-fill workload now has a Mojo draft. It has not been compiled or run.

The `treewidth_min_degree_elimination` greedy minimum-degree workload now has a Mojo draft; its stale uniqueness claim was replaced with a link to the related minimum-fill profile. It has not been compiled or run.

The `tsvc_s331_last_negative_index` full-scan workload now has a Mojo draft and a complexity note. It has not been compiled or run.

The `tsvc_s312_array_product` bounded product reduction now has a Mojo draft. It has not been compiled or run.

The `tsvc_s3111_positive_value_sum` bounded conditional reduction now has a Mojo draft. It has not been compiled or run.

The `tsvc_s4115_indexed_gather_product_sum` indexed gather reduction now has a Mojo draft. It has not been compiled or run.

The `trimaran_enc_pc1` bounded Pukall Cipher 1 workload now has a Mojo draft, retaining the source author's attribution. It has not been compiled or run.

The `tsvc_s423_antidependence_offset64` aliased-array sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s424_alias_overlap_feedback` ordered feedback sweep now has a Mojo draft. It has not been compiled or run.

The `trimaran_netbench_url_internet_checksum` source-specific checksum helper now has a Mojo draft. Its wrapping arithmetic remains unverified; it has not been compiled or run.

The `tsvc_s258_wrapped_scalar_expansion` carried-scalar workload now has a Mojo draft. It has not been compiled or run.

The `tsvc_s332_first_above_threshold` early-exit search now has a Mojo draft. It has not been compiled or run.

The `tsvc_s1281_elementwise_dual_update` repeated dual-vector update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s1221_lag4_add_recurrence` four-chain recurrence now has a Mojo draft. It has not been compiled or run.

The `tsvc_s322_second_order_recurrence` two-lag in-place recurrence now has a Mojo draft. It has not been compiled or run.

The `tsvc_s323_coupled_recurrence` coupled in-place recurrence now has a Mojo draft. It has not been compiled or run.

The `tsvc_s212_next_element_dependency` ordered dual-vector sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s243_ordered_lookahead_update` three-statement sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s241_cross_coupled_product_map` two-statement sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s271_positive_branch_axpy` conditional repeated update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s2711_nonzero_branch_axpy` nonzero-conditional repeated update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s272_threshold_dual_accumulate` thresholded dual update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s273_dependent_conditional_update` data-dependent branch and checksum now has a Mojo draft. It has not been compiled or run.

The `tsvc_s274_dependent_conditional_overwrite` branch-dependent overwrite now has a Mojo draft. It has not been compiled or run.

The `tsvc_s275_column_conditional_axpy_recurrence` column-guarded matrix recurrence now has a Mojo draft. It has not been compiled or run.

The `tsvc_s276_index_split_axpy` index-selected repeated update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s278_branch_recompute` repeated branch-and-recompute workload now has a Mojo draft. It has not been compiled or run.

The `tsvc_s279_nested_branch_recompute` nested-branch state update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s291_cyclic_neighbor_average` cyclic two-point stencil now has a Mojo draft. It has not been compiled or run.

The `tsvc_s293_first_element_broadcast` source-order broadcast now has a Mojo draft. It has not been compiled or run.

The `tsvc_s343_column_major_compaction` column-ordered masked packing workload now has a Mojo draft. It has not been compiled or run.

The `tsvc_s342_conditional_unpack` sequential masked expansion now has a Mojo draft. It has not been compiled or run.

The `tsvc_s351_direct_unrolled_saxpy` grouped direct-index update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s353_unrolled_sparse_saxpy` grouped indexed-gather update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s442_indexed_square_accumulate` four-way selected square update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s452_index_weighted_vector_map` position-weighted vector map now has a Mojo draft. It has not been compiled or run.

The `tsvc_s471_ordered_two_vector_map` repeated ordered two-vector update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s111_odd_index_neighbor_update` odd-destination sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s1112_reverse_constant_offset_map` descending elementwise map now has a Mojo draft. It has not been compiled or run.

The `tsvc_s1113_feedback_anchor_add` ascending feedback-anchor sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s114_transposed_lower_triangle_update` matrix sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s115_upper_triangular_saxpy_elimination` ordered triangular sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s118_triangular_convolution_recurrence` ordered coefficient recurrence now has a Mojo draft. It has not been compiled or run.

The `tsvc_s126_matrix_column_recurrence` induction-indexed matrix sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s125_matrix_flattened_fma` row-major matrix map now has a Mojo draft. It has not been compiled or run.

The `tsvc_s127_fixed_pair_expansion` ordered two-output expansion now has a Mojo draft. It has not been compiled or run.

The `tsvc_s128_strided_coupled_update` even-stride coupled update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s113_invariant_anchor_add` invariant-anchor sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s131_forward_neighbor_update` repeated right-neighbor sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s132_shifted_row_update` shifted cross-row sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s152_three_factor_accumulate` repeated three-factor update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s161_mutually_exclusive_updates` ordered conditional sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s162_guarded_shifted_fma` guarded neighbor sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s171_stride_indexed_accumulate` affine-stride update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s123_conditional_pair_expansion` variable-length expansion now has a Mojo draft. It has not been compiled or run.

The `tsvc_s124_conditional_fma_map` conditional multiply-add map now has a Mojo draft. It has not been compiled or run.

The `tsvc_s122_reverse_strided_gather_add` reverse gather and strided update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s116_unrolled_product_chain` five-way product sweep now has a Mojo draft. Its README also corrects the direction of the within-pass dependency. Neither change has been validated by execution.

The `tsvc_s119_diagonal_matrix_recurrence` ordered diagonal matrix sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s1119_same_column_matrix_prefix` column prefix sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s1111_stride_two_polynomial_map` even-index polynomial map now has a Mojo draft. It has not been compiled or run.

The `tsvc_s1251_per_element_dual_update` floating-point dual update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s1244_polynomial_neighbor_sum` ordered polynomial and neighbor sum now has a Mojo draft. It has not been compiled or run.

The `tsvc_s1213_ordered_neighbor_array_map` coupled neighbor sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s1279_nested_conditional_accumulation` repeated conditional update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s141_packed_symmetric_update` packed triangular accumulation now has a Mojo draft. It has not been compiled or run.

The `tsvc_s252_adjacent_product_pair_sum` adjacent-product map now has a Mojo draft. It has not been compiled or run.

The `tsvc_s251_scalar_square_expansion` repeated scalar-square map now has a Mojo draft. It has not been compiled or run.

The `tsvc_s253_conditional_affine_update` repeated conditional state update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s256_array_expansion` column-wise recurrence now has a Mojo draft. It has not been compiled or run.

The `tsvc_s257_column_coupled_update` matrix and scalar recurrence now has a Mojo draft. It has not been compiled or run.

The `tsvc_s261_shifted_cross_array_update` shifted coupled sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s277_guarded_carry_update` conditional next-element carry now has a Mojo draft. It has not been compiled or run.

The `tsvc_s281_reverse_coupled_update` reverse-index coupled sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s211_ordered_neighbor_rewrite` coupled neighbor sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s2111_wavefront_add_recurrence` two-dimensional wavefront now has a Mojo draft. It has not been compiled or run.

The `tsvc_s2102_identity_matrix_initialize` column-wise initialization now has a Mojo draft. It has not been compiled or run.

The `tsvc_s2101_diagonal_matrix_fma` diagonal matrix update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s221_partial_recursive_fused_update` coupled prefix recurrence now has a Mojo draft. It has not been compiled or run.

The `tsvc_s222_interleaved_square_recurrence` nonlinear recurrence now has a Mojo draft. Its README also corrects the binary32 underflow claim. Neither change has been validated by execution.

The `tsvc_s2251_carried_scalar_expansion` scalar carry sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s232_triangular_row_square_recurrence` nonlinear triangular sweep now has a Mojo draft. It has not been compiled or run.

The `tsvc_s233_s2233_matrix_prefix` paired matrix prefixes now have a Mojo draft. It has not been compiled or run.

The `tsvc_s235_fused_vector_matrix_recurrence` fused vector and matrix sweep now has a Mojo draft. It has not been compiled or run.

Static review of `tsvc_s242_fused_prefix_update` found B/C/D offsets shifted by one array in all nine existing ports, including an out-of-frame D read. The offsets were corrected and a Mojo draft added; none has been executed.

The `tsvc_s244_false_dependence_cycle_break` transient-store trace now has a Mojo draft. It has not been compiled or run.

The `tsvc_s2275_matrix_vector_axpy_interleave` interleaved matrix and vector update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s2710_nested_scalar_vector_branch_update` nested branch workload now has a Mojo draft. It has not been compiled or run.

The `tsvc_s2712_comparison_gated_axpy` changing-mask update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s313_dot_product_reduction` now has a Mojo draft. Its README also corrects the binary32 exactness claim; neither change has been validated by execution.

The `tsvc_s315_maximum_with_index` first-maximum scan now has a Mojo draft. It has not been compiled or run.

The `tsvc_s318_strided_absolute_maximum_with_index` strided magnitude scan now has a Mojo draft. It has not been compiled or run.

The `tsvc_s319_coupled_reductions` dual-map reduction now has a Mojo draft. It has not been compiled or run.

The `tsvc_s321_first_order_recurrence` ascending recurrence now has a Mojo draft. It has not been compiled or run.

The `tsvc_s3251_forward_shifted_array_expansion` forward-dependent update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s4117_pair_replicated_gather_map` half-rate gather now has a Mojo draft. It has not been compiled or run.

The `tsvc_s4114_reverse_index_gather_fma` reverse-index gather now has a Mojo draft. It has not been compiled or run.

The `tsvc_s441_s443_d_sign_branch_updates` paired sign-dependent updates now have a Mojo draft. It has not been compiled or run.

The `tsvc_s453_recurrence_weighted_scale` induction-weighted map now has a Mojo draft. It has not been compiled or run.

The `tsvc_s482_break_after_update` early-exit update now has a Mojo draft. It has not been compiled or run.

The `tsvc_s451_sincos_vector_map` transcendental vector map now has a Mojo draft. It has not been compiled or run.

The `tsvc_vpvpv_three_vector_add` repeated three-vector update now has a Mojo draft. It has not been compiled or run.

The `tsvc_vtvtv_triple_product_map` pointwise triple product now has a Mojo draft. It has not been compiled or run.

The `tsvc_vif_masked_assignment` positive-mask copy now has a Mojo draft. It has not been compiled or run.

The `tsvc_vag_indexed_gather_copy` indirect gather now has a Mojo draft. It has not been compiled or run.

The `tsvc_vbor` nested-product reduction now has a Mojo draft. It has not been compiled or run.

The `tsvc_indexed_gather_scatter` ordered indirect update modes now have a Mojo draft. It has not been compiled or run.

The FreeBench `analyzer` trace-conflict scan now has a Mojo draft. It has not been compiled or run.

The `doe_pathfinder_signature_search` ordered-label backtracking search now has a Mojo draft. It has not been compiled or run.

The `doe_minigmg_restriction` three-dimensional coarsening kernel now has a Mojo draft. It has not been compiled or run.

The EDN `edn_vec_mpy1` Q15 vector update now has an independent Mojo draft based on the documented operation. It has not been compiled or run; upstream GPL provenance is recorded in the package.

The EDN `edn_lattice_synthesis` fixed-point recurrence now has an independent Mojo draft. It has not been compiled or run; upstream GPL provenance is recorded in the package.

The EDN `edn_iir_cascade` Q15 cascade now has an independent Mojo draft. It has not been compiled or run; upstream GPL provenance is recorded in the package.

The `evalloop` bounded opcode-dispatch profile now has a Mojo draft. It has not been compiled or run.

The Shootout `fib2` uncached recursion now has a Mojo draft. It has not been compiled or run.

The Benchmark Game `fannkuch` counter-driven permutation traversal now has a Mojo draft. It has not been compiled or run.

The PolyBench `fdtd_2d` stencil now has an independent Mojo draft. It has not been compiled or run; the package records the upstream license.

The `doe_miniamr_stencil_average` seven- and 27-point profiles now have an independent Mojo draft. It has not been compiled or run; the package records Sandia attribution and LGPL provenance.

The PolyBench `gesummv` two-matrix vector reduction now has an independent Mojo draft. It has not been compiled or run; the package records the upstream license.

The `weighted_greedy_set_cover` exact-ratio greedy selection now has a Mojo draft. It has not been compiled or run.

The PolyBench `gemver` matrix-vector kernel now has an independent Mojo draft. It has not been compiled or run; the package records the upstream license.

The PolyBench `gemm` matrix multiplication now has an independent Mojo draft. It has not been compiled or run; the package records the upstream license.

The `gardenia_sgd` sequential matrix-factorization sweep now has an independent Mojo draft. It has not been compiled or run; the package records the upstream MIT license.

The `three_dimensional_moment_curve` graph-drawing construction now has a Mojo draft. It has not been compiled or run.

The `truthful_multiunit_ca_greedy2` allocation loop now has a Mojo draft. It has not been compiled or run.

The PolyBench `heat_3d` two-field stencil now has an independent Mojo draft. It has not been compiled or run; the package records the upstream license.

The `hospitals_residents_rgs` resident-proposing allocation now has a Mojo draft. It has not been compiled or run.

The PolyBench `jacobi_1d` two-field stencil now has an independent Mojo draft. It has not been compiled or run; the package records the upstream license.

The PolyBench `jacobi_2d` two-field stencil now has an independent Mojo draft. It has not been compiled or run; the package records the upstream license.

The `johnson_trotter_adjacent_gray_code` adjacent-swap enumeration now has a Mojo draft. It has not been compiled or run.

The `knapsack_profit_scaling_fptas` scaled-profit dynamic program now has a Mojo draft. It has not been compiled or run.

The `knapsack_profit_scaling_small_large_fptas` large-item DP and small-item fill now have a Mojo draft. It has not been compiled or run.

The `misc_lowercase` ASCII case-mapping helper now has a Mojo draft. It has not been compiled or run.

Static inventory review recorded existing Mojo drafts for `liouville_lambda` and `local_binary_pattern`, corrected the latter's C++ link, and retained the distinct-factor `liouville` benchmark because repeated prime factors produce different results.

The existing Graham `list_scheduling` suite now has a Mojo draft. It has not been compiled or run.

The `linpack_lu_solve` pivoted factorization and solve now has a Mojo draft. It has not been compiled or run.

The source-initialized `polybench_lu` factorization now has a Mojo draft. It has not been compiled or run; the package records the upstream license.

The bounded Rodinia `rodinia_lavamd` particle-interaction profile now has a Mojo draft. It has not been compiled or run; the package records the upstream license.

The `max_minimum_machine_load_lpt` decreasing-job scheduling profile now has a Mojo draft. It has not been compiled or run.

The fixed-input `matmul_f64_4x4` profile now has a Mojo draft. It has not been compiled or run; the package notes the possibility of compiler optimization of repeated work.

The `min_plus_distance_product` matrix operation now has a Mojo draft. It has not been compiled or run.

The `mdp_value_iteration_deterministic` synchronous Bellman sweeps now have a Mojo draft. It has not been compiled or run.

The `max_sum_length_bounded_segment` monotone-deque profile now has a Mojo draft. It has not been compiled or run.

The MiBench `mibench_automotive_basicmath_isqrt` fixed-point root recurrence now has a Mojo draft. It has not been compiled or run.

The `misra_gries_summaries` cancellation profile now has a bounded-alphabet Mojo draft. It has not been compiled or run.

The PolyBench `mvt` matrix-vector updates now have a Mojo draft. It has not been compiled or run; the package records the upstream license.

The MiBench `mibench_jpeg_ycbcr_to_rgb` color conversion now has a Mojo draft. It has not been compiled or run; the package records the upstream license.
Its V draft had non-V local declaration syntax and a mixed signed/unsigned
capacity comparison; both are corrected in source. The package's V and Zig
links now point to their actual `m/` paths. These edits remain unexecuted.
Its Elisa draft now uses bounded views after ABI checks; this change remains
uncompiled and unexecuted.
The MiBench JPEG README now contains the full IJG attribution required by its
suite validator, and the validator's source-presence list includes Mojo. These
source-level corrections remain unexecuted.
The MiBench JPEG verifier also specifies exhaustive neutral-chroma brightness
preservation and out-of-range channel probes. These checks have not been run.

The `smith_weighted_completion_time` ordering profile now has a Mojo draft. It has not been compiled or run.

The `srpt_flow_time` preemptive scheduling profile now has a Mojo draft. It has not been compiled or run.

The `morton_sort` stable spatial ordering profile now has a Mojo draft. It has not been compiled or run.

The `misc_fp_convert` mixed-precision dot-product profile now has a Mojo draft. It has not been compiled or run.

The MediaBench `mediabench_mpeg2_motion_vector_component` update now has a Mojo draft. It has not been compiled or run.
Its suite source-presence check now includes that Mojo draft. The updated
validator has not been run.
The Elisa port now uses exact-length ABI views and declares the output
reference mutable; this source change has not been compiled or run.
The verifier source now specifies modular-wrap identity checks across every
motion code and scale size at predictor and residual boundaries; these checks
have not been run.

The MediaBench `mediabench_gsm_rpe_grid_selection` profile now has a Mojo draft. It has not been compiled or run; its package retains the upstream notice.
Static review corrected an out-of-scope loop variable in the Elisa selection
draft, converted its input access to a bounded view, and added Mojo to the
suite's source-presence check. These changes remain uncompiled and unexecuted.

The `misc_dt` repeated division profile now has a Mojo draft. It has not been compiled or run.

The cBench `cbench_consumer_jpeg_h2v2_fancy_upsample` profile now has a Mojo draft. It has not been compiled or run; the package retains the IJG notice.
The suite's source-presence check now includes Mojo, and the Elisa draft uses
bounded input/output views after ABI checks. These changes remain unexecuted.
Its verifier draft also checks constant-plane preservation at every 8-bit
sample value; those checks remain unexecuted.
Static port review added the missing Mojo `InlineArray` import; compilation
and correctness remain unverified.

The MediaBench `mediabench_gsm_rpe_grid_positioning` scatter now has a Mojo draft. It has not been compiled or run; its package retains the upstream notice.
Its Elisa input now uses a bounded view, and its suite source-presence check
includes Mojo; these changes remain uncompiled and unexecuted.
The verifier draft composes the selection and positioning references on
generated sample vectors and checks scatter placement. It has not been run.
The V grid drafts now mark helper pointer indexing as unsafe locally; the
16-bit serializer also masks signed samples before narrowing. These source
changes remain uncompiled and unexecuted.

The `max_average_length_bounded_segment` exact-search profile now has a Mojo draft. It has not been compiled or run.

The `manhattan_mst` implicit complete-graph Prim profile now has a Mojo draft. It has not been compiled or run.

The `minimal_dominating_sets_interval` pair-state DAG profile now has a Mojo draft. It has not been compiled or run.

The `submodular_ranking_greedy` explicit-table profile now has a Mojo draft. It has not been compiled or run.

The cBench `cbench_consumer_lame_mdct_short` profile now has a Mojo draft. It has not been compiled or run; its package records upstream license terms.
Static review updated the Elisa draft to use bounded ABI views, fixed a V
mutable accumulator and finite-value check, and included Mojo in the suite's
source-presence check. The changes remain uncompiled and unexecuted.

The MiBench `mibench_lame_mdct_long` transform now has a Mojo draft. It has not been compiled or run; its package records upstream license terms.
The package port list now includes Mojo, and the Elisa draft uses bounded
input/output views after ABI checks. These edits remain uncompiled and unrun.
The float64 workload validator now includes the Mojo draft in its source
presence check; this change remains unexecuted.
The V draft now rejects NaN explicitly and infinities through its range check,
without relying on a floating-point method whose availability was unclear.
This source correction is uncompiled.

The cBench `cbench_consumer_mad_alias_reduce` fixed-point profile now has a Mojo draft. It has not been compiled or run; the package retains upstream license terms.

The cBench `cbench_consumer_mad_imdct36` transform now has a Mojo draft. It has not been compiled or run; the package records upstream license terms.
The Elisa draft now uses bounded ABI views, the V draft rejects NaN explicitly,
and the float64 suite checks for the Mojo source. These changes remain
uncompiled and unexecuted.

The `next_fit_bin_packing` online placement profile now has a Mojo draft. It has not been compiled or run.

The `netbench_crc` table-driven update now has a Mojo draft. It has not been compiled or run; the package retains the upstream notice.

The `nestedloop` six-level loop profile now has a Mojo draft. It has not been compiled or run.

The `non_shared_edges` canonical phylogeny-split comparison now has a Mojo draft. It has not been compiled or run.

The `number_theoretic_transform` forward radix-2 transform now has a Mojo draft. It has not been compiled or run.

The CoreMark-derived `numeric_token_state_machine` profile now has a Mojo draft. It has not been compiled or run; the package records upstream license terms.

The `olden_perimeter` implicit quadtree traversal now has a Mojo draft. It has not been compiled or run.

The `partialsums` nine-series profile now has a Mojo draft. It has not been compiled or run.

The `prolangs_c_simulator_shiftr` arithmetic-shift profile now has a Mojo draft. It has not been compiled or run; the package retains the source notice.

The `prolangs_c_loader_relocation_add` bounded field update now has a Mojo draft. It has not been compiled or run; the package retains the source notice.

The `pfr_local_forward_decision` deterministic draw profile now has a Mojo draft. It has not been compiled or run.

The `packet_routing_work_conserving_schedule` profile now has a Mojo draft. It has not been compiled or run.

The `packet_switching_sgr_multi_queue` profile now has a Mojo draft. It has not been compiled or run.

The `parameterized_pattern_matching` predecessor-encoding profile now has a Mojo draft. It has not been compiled or run.

The `psi_suffix_array_access` sampled suffix-array profile now has a Mojo draft. It has not been compiled or run.

The `prolangs_c_simulator_format3_4` address decoder now has a Mojo draft. It has not been compiled or run; the package retains the source notice.

The `permutation_shortcut_index` inverse-query profile now has a Mojo draft. It has not been compiled or run.

The `randomized_rounding_bernoulli` draw-tape profile now has a Mojo draft. It has not been compiled or run.

The `rank_select_bitstring` block-index profile now has a Mojo draft. It has not been compiled or run.

The `random_planted_3sat_majority_vote` initialization now has a Mojo draft. It has not been compiled or run.

The `randomized_ray_search` supplied-sample profile now has a Mojo draft. It has not been compiled or run.

The `relaxed_convolution` dyadic schedule now has a Mojo draft. It has not been compiled or run.

The `revert_bits` 32- and 64-bit reversal profile now has a Mojo draft. It has not been compiled or run.

The bounded integer `stream_vector_kernels` variant now has a Mojo draft. It has not been compiled or run and is not an official STREAM result.

The `polybench_seidel_2d` in-place stencil now has a Mojo draft. It has not been compiled or run; the package records upstream license terms.

The `packet_switching_single_buffer` FIFO policy profile now has a Mojo draft. It has not been compiled or run.

The PolyBench `syrk` symmetric rank-k update now has a Mojo draft. It has not been compiled or run; the package records upstream license terms.

The PolyBench `syr2k` symmetric rank-2k update now has a Mojo draft. It has not been compiled or run; the package records upstream license terms.

The `weighted_greedy_spanner` incremental graph profile now has a Mojo draft. It has not been compiled or run.

The `seam_carving` vertical-seam profile now has a Mojo draft. It has not been compiled or run; the package records the upstream license.

The uncached `takeuchi` recursion now has a Mojo draft. It has not been compiled or run.

The `tsvc_vtv_elementwise_product` repeated vector update now has a Mojo draft. It has not been compiled or run.

The PolyBench `trisolv` forward substitution now has a Mojo draft. It has not been compiled or run; the package records the upstream license.

The PolyBench `trmm` triangular matrix multiplication now has a Mojo draft. It has not been compiled or run; the package records the upstream license.

The `two_interval_precedence_chain` dynamic program now has a Mojo draft. It has not been compiled or run.

The `universal_sequencing_doubling` knapsack-level profile now has a Mojo draft. It has not been compiled or run.

The `two_dimensional_string_matching` row-matching and KMP profile now has a Mojo draft. It has not been compiled or run.

The `two_dimensional_scaled_pattern_matching` rational-scale profile now has a Mojo draft. It has not been compiled or run.

The `transit_node_routing_table_query` far-query profile now has a Mojo draft. It has not been compiled or run.

The `two_edge_connected_spanning_subgraph_greedy` deletion profile now has a Mojo draft. It has not been compiled or run.

The `table_compression_optimal_contiguous_partition` dynamic program now has a Mojo draft. It has not been compiled or run.

The BitBench `uuencode` byte-stream profile now has a Mojo draft. It has not been compiled or run; the package retains upstream notices.

The BitBench `uudecode` byte-stream profile now has a Mojo draft. It has not been compiled or run; the package retains upstream notices.

The `weighted_random_sampling` exact-priority profile now has a Mojo draft. It has not been compiled or run.

The `weighted_connected_dominating_set` exact subset profile now has a Mojo draft. It has not been compiled or run.

The Embench `depthconv` quantized depthwise profile now has a Mojo draft. It has not been compiled or run; the package retains upstream attribution and license.

The `radio_network_decay_phase` supplied-coin profile now has a Mojo draft. It has not been compiled or run.

The `versabench_dbms_valid_attributes` ordered-validation profile now has a Mojo draft. It has not been compiled or run.

The `versabench_dbms_valid_index_key` binary32 comparison profile now has a Mojo draft. It has not been compiled or run.

The `versabench_dbms_keys_union` bounding-box profile now has a Mojo draft. It has not been compiled or run.

The `versabench_dbms_consistent_key` bounding-box intersection profile now has a Mojo draft. It has not been compiled or run.

The `versabench_dbms_penalty` directional enlargement profile now has a Mojo draft. It has not been compiled or run.

The `versabench_dbms_choose_entry` minimum-enlargement child-selection profile now has a Mojo draft. It has not been compiled or run.

Static review of `versabench_dbms_contract_root` corrected all nine existing ports to validate each next level directly from input, rather than reading the next local array element before it was populated. A Mojo draft now covers the same contract. The changes have not been compiled or run.

The suite package checks now include the Mojo drafts for the VersaBench attribute, key validation, key union, intersection, penalty, child selection, partitioning, and root-contraction profiles. These are static source-presence checks, not evidence of compilation or execution.

The VersaBench key-only R-tree query profile now has a Mojo draft with bounded validation and depth-first traversal. It has not been compiled or run.

The VersaBench one-level R-tree deletion profile now has a Mojo draft and a suite source-presence check. Static review also corrected a missing Mojo `InlineArray` import in key union and array initialization in query. None of these changes has been compiled or run.

The VersaBench no-split R-tree insertion profile now has a Mojo draft and a suite source-presence check. The draft has not been compiled or run.

Static review corrected the missing `InlineArray` import in the VersaBench binary32 index-key validation Mojo draft. It has not been compiled or run.

The root-contraction workload now includes the longest supported promotion chain and a malformed transition with short output capacity, recording the expected validation precedence. The workload and its suite metadata change have not been executed.

The `dc_tree_k_server_path` simultaneous-movement profile now has a Mojo draft. It has not been compiled or run.

The BitBench `drop3` fixed 20-pass bitstream profile now has a Mojo draft. It has not been compiled or run.

The PolyBench `deriche` recursive image filter now has a Mojo draft. It has not been compiled or run; its package retains the upstream license.

Static review corrected the Rust `euclidean_t_spanner` output header write: the previous one-element slice copy targeted the entire variable-length output and would panic on valid nonempty graphs. Existing two-point and larger workload cases cover that output shape. A Mojo draft now constructs the same deterministic split tree and representative-edge traversal. Neither port has been compiled or run.

The `frt_tree_metric` bounded hierarchical-partition profile now has a Mojo draft. It has not been compiled or run.

The FreeBench bounded repeated-pattern Hopfield profile now has a Mojo draft. It has not been compiled or run; the package records the upstream rights status.

The Lua `uint53_is` range predicate now has a Mojo draft. Static review also corrected builder and scalar-runner lookup of its existing `benchmarks/i/is` workload and connected its canonical symbol name to the existing oracle check. These changes have not been run.

The bounded `k_median_p1_local_search` best-improvement profile now has a Mojo draft. It has not been compiled or run.

The KKT sampled-forest heavy-edge filter now has a Mojo draft. It has not been compiled or run.

The nonadaptive stochastic-knapsack greedy policy now has a Mojo draft. Static review also corrected builder, byte runner, and verifier workload lookup for its `k`-directory package. These changes have not been run.

Static source review added explicit `std.collections.InlineArray` imports to nine Mojo drafts: `merge_find_set`, `berlekamp_massey`, `bitwise_and_convolution`, `bitwise_or_convolution`, `depthconv`, `radio_network_decay_phase`, `gcd_convolution`, `hash_map_open_addressing`, and `3sum`. A text search still finds 974 Mojo files using `InlineArray` without an explicit named import; that is an audit queue, not proof of compilation failures, because other imports and compiler prelude behavior have not been checked. No compiler or validator was run.
Four additional media drafts now explicitly import `InlineArray`: MiBench JPEG
color conversion, MiBench long-block MDCT, and MediaBench GSM grid selection
and positioning. Prelude availability and compilation remain unverified.

Subsequent static coverage work added Mojo drafts for `polybench_correlation`,
`himenobmtxpa`, `maximum_fenwick_tree`, `median_of_matrix`, `median_search2`,
`merge_intervals`, `merge_sorted_singly_linked_list`, `merge_sort_linked_list`,
`merge_ksorted_linked_list`, `subtract`, `memory_management_algorithms`, and
`merge_find_set`, `gbbs_yoshida_query_mis`, `maskwords`, and
`kmp_slp_jump_output`, `spigotpi`, `mibench_security_sha0`, and
`extended_gs_general_stable_allocation`, `freebench_pifft`, and
`fhourstones_exact`. Their package guides record the drafts and contracts. These
are existing algorithm profiles, so they add language coverage rather than new
candidate entries; the drafts and suite wiring have not been compiled or run.

Static build-path review found that `build_abi.py` only looked for categorized
workloads even though older packages such as `merge_find_set`,
`maximum_fenwick_tree`, and `merge_intervals` keep their workload directly
under `benchmarks/<algorithm>`. The builder now falls back to that flat layout
when the categorized workload is absent. This path change has not been run.
The scalar, byte-output, integer-to-float, and float-slice runners and
verifiers now use the same categorized-then-flat fallback; explicitly supplied
runner workload paths are preserved. These changes also remain unrun.

CP-Algorithms cross-check: [tree painting](https://cp-algorithms.com/graph/tree_painting.html)
is already mapped to `tree_edge_paint_path_count` above, and
[centroid decomposition](https://cp-algorithms.com/graph/centroid_decomposition.html)
is already represented by `centroid_decomposition`. These descriptions do not
justify duplicate packages. The pages were used as algorithm indexes; their
prose and code were not copied. The existing packages and their ports still
require the separate completeness and runtime audit.
The Algorithm Archive's gift-wrapping chapter corresponds to the existing
`jarvis_scan` package, as recorded in the chapter table above. Static source
inspection also found Mojo drafts for both `jarvis_scan` and
`centroid_decomposition` that their guides did not list; the guides now link
them. This is an inventory correction, not a compilation or correctness check.

Confirmed distinct, implementation drafts unverified: [CP-Algorithms' ascending tree traversal](https://github.com/cp-algorithms/cp-algorithms-aux/blob/7a28ec7ac05eabf2ceeed1778e2b2110a1e1c022/cp-algo/tree/ascending_dfs.hpp)
uses degree-based leaf removal and an XOR of incident edge IDs to recover each
remaining parent edge. Existing `depth_first_search` explores from the root;
`prufer_code` removes leaves in priority order to emit a Prüfer code. The
[`xor_leaf_tree_traversal`](x/xor_leaf_tree_traversal/README.md) package records
this different representation and child-before-parent workload. C, C++, Rust,
Nim, Mojo, Odin, Zig, C3, V, and Elisa drafts, two references,
workload fixtures, and byte-output suite registration are present; none has
been run. The upstream repository publishes
a [CC BY-SA license](https://github.com/cp-algorithms/cp-algorithms-aux/blob/main/LICENSE);
the source was used for the algorithm idea only.

The McCat Sturm-sequence eigenvalue bisection profile now has a Mojo draft. It has not been compiled or run; the package preserves the upstream notice.

The distinct `mccat_05_eks` symmetric eigensolver, which uses band reduction
and shifted QR instead of Sturm bisection, now also has a Mojo draft and a
documented complexity bound. The draft is uncompiled and unrun.

The McCat recursive binary-tree membership profile now has a Mojo draft. It has not been compiled or run; the port and package retain the upstream copyright notice.

The McCat insertion-order character trie now has a Mojo draft. It has not been compiled or run; the port and package retain the upstream copyright notice.

The existing `mccat_08_main` hierarchical 3D transform profile now has a Mojo
draft and documented complexity. The suite source checks all ten ports and
specifies hand-derived composition and deduplication cases. These changes
remain uncompiled and unrun.

The existing `smallest_enclosing_ball_3d` Welzl profile now has a Mojo draft
using a Gram-system support fit. It has not been compiled or run; numerical
behavior on near-degenerate supports remains to be validated.
The package guide now records its distinction from `smallest_circle`, satisfying
an existing validator requirement. The suite source checks ten language paths
and specifies collinear, coplanar, and repeated-point cases; none has run.

The distinct `suffix_array_dc3` residue-sampling profile now has a Mojo draft.
Verifier source now checks all ten source paths and compares the DC3 and direct
suffix references on bounded binary and patterned texts. Its recursion, merge,
and new checks are uncompiled and unrun.

The existing `stanford_puzzle` fixed 3D packing search now has a Mojo draft.
It retains the source orientation order and call-count observation; it is
uncompiled and unrun.

The existing `procedure_s_general_cnf_sat` bounded branching profile now has
a Mojo draft, including its exact-subroutine and branch counters. It remains
uncompiled and unrun. Verifier source checks the ten port paths and compares
both references on generated two-variable formulas; the checks are unexecuted.

**Duplicate consolidated:** Trimaran's `enc-rc4` and [`rc4`](r/rc4/README.md)
both perform RC4 key scheduling and stream XOR. The Trimaran profile added
fixed vectors and repetitions rather than a different cipher algorithm. Its
duplicate package, language ports, and suite registration have been removed;
the source notice and GPL text are preserved with `rc4`. The retained verifier
source includes independently generated one-block and multi-block shapes and
stream round trips. The consolidation has not been executed or tested.
An earlier filename review found Mojo source gaps for [`beebs_fasta`](f/beebs_fasta/README.md), [`shootout_methcall`](s/shootout_methcall/README.md), and [`shootout_objinst`](s/shootout_objinst/README.md). All three now have unexecuted Mojo drafts. The [`integer_sequence_codes`](i/integer_sequence_codes/README.md), [`huffbench`](h/huffbench/README.md), [`ansibench_dhrystone`](a/ansibench_dhrystone/README.md), [`ansibench_whetstone`](a/ansibench_whetstone/README.md), and [`improved_perlin_noise_3d`](i/improved_perlin_noise_3d/README.md) profiles also have Mojo drafts, uncompiled and unexecuted. These are existing algorithms with missing or unverified language coverage, not new candidate packages; their documented computation and licensing need to be preserved when ported. This inventory is static and no programs or checks were run.

Update: `beebs_fasta` now has an independently written Mojo draft and its
source is included in the existing package-presence check. It has not been
compiled or run; the binary32 selection and output framing remain unverified.

Further static filename review across the entire Mojo tree found no matching
source for these existing profiles: `almabench`, `beebs_nettle_cast128`,
`versabench_beamformer`, `embedded_list_stress`, `mallocbench_espresso`,
`freebench_distray`, `freebench_fbench`, `mediabench_g721_encode`,
`nbench_emulated_float_arithmetic`, `paq8p_context_mixer`, and
`prolangs_football_tiebreaks`. C sources exist for these names. This records
missing language coverage, not a decision that any is a new algorithm, and
does not establish the status of their other language ports or registrations.
Their individual contracts and provenance need review before adding a port.
Matching by basename across the whole tree matters: for example,
`mibench_network_dijkstra` and `rat_maze` have Mojo sources in different
letter directories from their C sources and are not gaps on that basis.

Update: `versabench_beamformer` now has a Mojo draft for the 12-channel
binary32 complex accumulation, and its suite validator checks for the source.
The draft has not been compiled or run; contraction and numerical agreement
remain unverified.

Update: `embedded_list_stress` now also has a Mojo draft using indexed links,
plus source-presence and boundary probes in the existing suite. The draft and
checks have not been compiled or run.

Update: `nbench_emulated_float_arithmetic` now has a Mojo draft for all four
bounded arithmetic operations and a suite source-presence check. Unsigned
wraparound, output bytes, and compilation remain unverified.

The existing `kiraly_max_smt_i_approx` profile now has a Mojo draft, and its
build, byte-output runner, and verifier lookups use its actual `s/` package
location. These drafts and path corrections have not been executed.

The existing `mcgill_misr` profile now has a Mojo draft and suite
source-presence check. Its random stream, ASCII output, and compilation have
not been verified by execution.

Static review of the existing `qrduino` profile corrected finite-field carry
handling in C, C++, and C3, plus a Zig syntax error. Its returned unmasked
prefix does not establish that parity or discarded mask selection is correct
or retained by optimization; the package still lacks a Mojo port. No checks
were executed.

Static review of [`indexed_block_list`](i/indexed_block_list/README.md) found that all ten drafts skipped list construction and insertions whenever a valid trace had no reads. The early returns were moved past the operations, retaining null-output acceptance for zero-byte results; both references now process those operations too, and a corresponding verifier case is written. The Mojo block-size array is explicitly zero-initialized and signed outputs are bitcast before byte encoding; a negative-value workload case was added. None of these changes has been executed.
The Elisa draft now confines input and nonempty output references to ABI
boundaries and uses bounded views in the algorithm. The zero-output return
still follows list construction and operations. This edit is uncompiled.
Static storage review bounds the number of indexed-block descriptors at 12:
after a split, each insertion-only block contains at least four of the at most
48 elements; before any split there is only one block. The ports reserve 16.
The Nim, Odin, and Mojo capacity checks now compare unsigned ABI sizes without
narrowing the caller's capacity to a signed integer; this fix is uncompiled.
The V draft's operation-count declaration was also corrected to V syntax; it
has not been compiled.

The former `zblock_substring_search` profile computed the same prepared Z-array as [`z_algorithm`](z/z_algorithm/README.md) and filtered it to a count. It was consolidated into the latter; its separate count-output interface is removed and a search-shaped input plus C# source attribution remain. The retained package now has verifier registration with an independent Z-array reference, capacity and null checks, and a maximum-length case. Static review also added missing input/output null guards to the Elisa, V, and Zig drafts; Elisa uses bounded views internally after checking its ABI references. Changes are unexecuted.

The existing [IMA/DVI ADPCM](i/lac_adpcm/README.md) profile now has a Mojo draft for both encoding and decoding, with the required copyright and permission notice. It is uncompiled and unexecuted.

The [improved 3D Perlin](i/improved_perlin_noise_3d/README.md) Mojo draft initializes the fixed table inside the function, unlike static-table ports. Compiler folding or hoisting remains unverified, and this may affect its benchmark comparability.

The existing [Misc FLOPS family](m/misc_flops/README.md) now has an unverified Mojo draft covering all eight bounded numerical modules. Static review aligned the integration step-size calculation with the source evaluation order. The package records that the pinned source has no explicit license grant; no source text was reused. Nothing has been compiled or run.

The [IDA* graph candidate](i/ida_star_graph/README.md) is distinct from the existing depth-limited `iddfs` and best-first `astar`: it repeats depth-first searches with a cost-plus-heuristic threshold. Ten clean-room language drafts, a bounded directed-graph contract, workload, independent BFS reference, static source inventory, provenance note, and scalar suite registration are written. Nothing has been executed. Discovery: [Korf, IJCAI 1985](https://ijcai.org/proceedings/1985/208), algorithm description only.

The existing [VersaBench blocked matrix multiply](b/bmm/README.md) profile now has a Mojo draft preserving the seeded input stream, tile order, and binary32 accumulations. Static suite review found the normal source path and added verifier inputs for multiple tile sizes and non-power-of-two dimensions. The package retains its restrictive upstream license notice. The draft and added cases have not been compiled or run.

The existing [VersaBench 8b/10b](0-9/8b10b/README.md) profile now has a Mojo draft preserving the direct table lookup, running disparity across passes, and sampled output. Verifier cases enumerate all packed words with two additional prefixes, and the upstream MIT notice is retained. Neither the draft nor the cases have been compiled or run.

Static review of the retained RC4 Mojo draft also corrected its missing
`InlineArray` import and added its package link; compilation remains unverified.

Static review of `mccat_09_vor` found that its nine existing ports indexed the
triangle side lengths in an order inconsistent with their opposite-vertex
indices. The side ordering now matches the documented longest-side diameter
rule; verifier source includes obtuse triangles for the different positions.
These fixes and probes remain uncompiled and unexecuted. A Mojo draft is now
present and follows the corrected longest-side mapping; it is also unverified.

The McGill iterative-deepening expression-tree search now has a Mojo draft. It has not been compiled or run; the package records the source's license status.

The bounded planted 3-SAT k-OPT profile now has a Mojo draft. It has not been compiled or run.

The five-point Rader FFT convolution profile now has a Mojo draft. It has not been compiled or run; the package retains the upstream CC0 license.

The optimistic flow-control scheduler and rate-update profile now has a Mojo draft. It has not been compiled or run.

The greedy rumor-blocking supplied-world profile now has a Mojo draft. It has not been compiled or run.

The LCP-accelerated suffix-array search profile now has a Mojo draft. It has not been compiled or run.

The Embench `tarfind` first-match filename scan now has a Mojo draft. It has not been compiled or run; the package retains source attribution and the MIT notice.

The few-inner-points TSP permutation and dynamic-programming profile now has a Mojo draft. It has not been compiled or run.

The bounded unit-disk graph metric WSPD profile now has a Mojo draft. It has not been compiled or run.

The finite-metric work-function k-server profile now has a Mojo draft. It has not been compiled or run.

The bounded wire-sizing support-enumeration profile now has a Mojo draft. It has not been compiled or run.

The bounded WikiSort run-and-block-rotation profile now has a Mojo draft. It has not been compiled or run; the package retains the pinned source license.

The Prolangs-C fixed cubic all-roots profile now has a Mojo draft. Static review also corrected builder, byte-runner, and verifier lookup of its `a`-directory sources and workload. These changes have not been run.

The Crust pole-adjacency triangle filter now has a Mojo draft. Static review also corrected builder, byte-runner, and verifier lookup of its `s`-directory workload. These changes have not been run.

### Library Checker catalog recheck

**In progress — root:** `effective_resistance_unit_graph` is reserved for an
exact two-terminal effective-resistance calculation on a bounded connected
unit-resistance graph. [`counting_spanning_trees_undirected`](c/counting_spanning_trees_undirected/README.md)
computes only the single Laplacian cofactor, while this profile also computes
the two-terminal forest cofactor and returns their reduced ratio. The
[CP-Algorithms matrix-tree discussion](https://cp-algorithms.com/graph/kirchhoff-theorem.html)
identifies the resistance/cofactor relationship; use mathematical ideas only,
with independent code and fixtures. A static search for resistance names in
the benchmark READMEs and catalog found no matching profile. Reservation does
not claim complete catalog coverage. Do not duplicate this work.
The contract, independent edge-subset reference, workload, ten language
drafts, and scalar-suite registration are written. The verifier source covers
all simple graphs through four vertices and a maximum-edge graph. Nothing has
been compiled or run.
The Elisa draft now uses a bounded input view after its ABI null and length
checks; this static edit is also uncompiled and unexecuted.

The current [Library Checker problem list](https://judge.yosupo.jp/) includes several newer candidate names. A static name search of `benchmarks` and `catalog` produced the following leads; absence by name is not proof that an equivalent implementation is missing. The catalog is used as an idea index, and no problem text, code, or tests have been copied.

| Candidate | Current inventory evidence and next comparison |
| --- | --- |
| Incremental Minimum Spanning Forest | Confirmed distinct insertion/replacement trace from static MST and sampled-forest filtering. A [package draft](i/incremental_minimum_spanning_forest/README.md), workload, two independent models, ten language drafts, and byte-suite runner/verifier registration exist. The source is pinned at `73876f1cbcf082d2b22722924b924d3d65a2f00e`; nothing has been compiled or run. |
| Static Range Sum with Upper Bound | The [source contract](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/static_range_sum_with_upper_bound/task.md) asks for both count and sum under a value threshold. Existing [`wavelet_matrix`](w/wavelet_matrix/README.md) supports counts but no value sums. A distinct [augmented wavelet-matrix draft](s/static_range_sum_with_upper_bound/README.md), ten language drafts, direct-scan reference, workload, and byte-output suite registration are present. Nothing has been executed. |
| All Furthest Neighbors of a Convex Polygon | Confirmed distinct output and workload from [`rotating_calipers`](r/rotating_calipers/README.md): that package reports only the global diameter, whereas this operation selects a farthest vertex for each polygon vertex. [CGAL's reference](https://doc.cgal.org/5.4.5/Polytope_distance_d/group__PkgPolytopeDistanceDRef.html) documents the per-vertex operation. The distinct [`all_farthest_neighbors_convex`](a/all_farthest_neighbors_convex/README.md) package has ten language drafts using the implicit totally monotone distance matrix from [Aggarwal et al.](https://doi.org/10.1007/BF01840359), an independent direct-scan reference, workload, and byte-output suite wiring. Nothing has been executed. |
| Majority Voting | The [source contract](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/majority_voting/task.md) interleaves point updates and subrange-majority queries. Existing [`boyer_moore_majority_vote`](b/boyer_moore_majority_vote/README.md) handles one static whole sequence, while [`point_set_range_frequency`](p/point_set_range_frequency/README.md) counts a specified value. The distinct [`dynamic_range_majority`](m/dynamic_range_majority/README.md) package has ten cancellation-tree/bitmap language drafts, a direct reference, workload, and byte-output suite wiring. Nothing has been executed. |
| Aho Corasick | Existing [`aho_corasick`](a/aho_corasick/README.md) and [`aho_corasick_failure_tree_counts`](a/aho_corasick_failure_tree_counts/README.md) already construct the trie and failure links. The [catalog task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/string/aho_corasick/task.md) exposes those links and pattern endpoints instead of scanning text; it is the same core construction, so do not add a duplicate algorithm. Its output contract is not currently exposed. |
| Dirichlet Inverse and Prefix Sums | Confirmed distinct from [`dirichlet_convolution_and_prefix_sums`](d/dirichlet_convolution_and_prefix_sums/README.md), which combines two supplied functions. The [new draft](d/dirichlet_inverse_and_prefix_sums/README.md) solves for the inverse with a quotient-group recurrence; ten language drafts, an independent coefficient-level reference, workload, and byte-output suite wiring are present. Nothing was executed. |
| Prefix Sum of Polynomial | The [source task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/prefix_sum_of_polynomial/task.md) requests coefficients of a discrete antiderivative for a general polynomial. Existing Bernoulli-number and weighted power-sum profiles compute ingredients or evaluated sums, not that coefficient transform. The distinct [`polynomial_discrete_antiderivative`](p/polynomial_discrete_antiderivative/README.md) draft has ten triangular-solve language drafts, an independent Newton-difference reference, workload, and byte-output suite registration. Nothing has been executed. |
| Inv of Bivariate Formal Power Series | The [catalog task](https://judge.yosupo.jp/problem/inv_of_formal_power_series_2d) requests a rectangular two-variable reciprocal. Existing univariate inversion and multivariate multiplication do not implement this operation. The distinct [`inv_of_formal_power_series_2d`](i/inv_of_formal_power_series_2d/README.md) draft has ten coefficient-recurrence language drafts, an independent Newton reference, workload, and byte-output suite wiring. Nothing has been executed. |
| Log of Set Power Series | [`exp_of_set_power_series`](e/exp_of_set_power_series/README.md) computes the inverse operation, while [`polynomial_composite_set_power_series`](p/polynomial_composite_set_power_series/README.md) uses generic Horner composition. The specialized [`log_of_set_power_series`](l/log_of_set_power_series/README.md) package uses a pivot-subset recurrence and has ten language drafts, an independent truncated-series reference, workload, and byte-output suite registration. Nothing has been executed. |
| Range Add Range Min | The [catalog task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/range_add_range_min/task.md) combines range additions and minimum queries. [`lazy_segment_tree_range_add_sum`](l/lazy_segment_tree_range_add_sum/README.md) answers sums; [`range_linear_add_range_min`](r/range_linear_add_range_min/README.md) uses block hulls for a broader update. The distinct [`range_add_range_min`](r/range_add_range_min/README.md) lazy-minimum tree draft has ten language ports, a flat-array reference, workload, and suite wiring. Nothing has been executed. |
| Static Range Mode Query | The [catalog operation](https://judge.yosupo.jp/problem/static_range_mode_query) asks for a mode and its count in a subrange. Already represented by [`static_range_mode_query`](s/static_range_mode_query/README.md), whose block-mode structure also defines a deterministic tie rule. Do not add a second package for the catalog name. |
| Static Range LIS Query | The [catalog operation](https://judge.yosupo.jp/problem/static_range_lis_query) is already represented by [`static_range_lis_query`](s/static_range_lis_query/README.md). The local profile uses bounded per-query patience sorting rather than claiming a large-scale preprocessed range-LIS data structure; no duplicate package is needed for the same operation. |
| Deque | The [catalog task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/deque/task.md) combines indexed lookup with insertion and removal at both ends. [`linked_deque`](l/linked_deque/README.md) lacks indexed lookup; [`indexed_block_list`](i/indexed_block_list/README.md) lacks removal; [`ring_buffer`](r/ring_buffer/README.md) supports indexed reads but only FIFO insertion and removal. The distinct [`indexed_deque`](i/indexed_deque/README.md) circular-array draft has ten language ports, a list reference, workload, and suite wiring. Nothing has been executed. |
| Discrete Logarithm (Fixed Mod) | The [catalog task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/number_theory/discrete_logarithm_fixed_mod/task.md) batches targets for one prime and primitive root. [`discrete_logarithm_mod`](d/discrete_logarithm_mod/README.md) handles individual general-modulus queries. Shared precomputation materially changes the workload: a bounded direct-table [`discrete_logarithm_fixed_mod`](d/discrete_logarithm_fixed_mod/README.md) draft has ten language ports, a direct-search reference, workload, and suite wiring. Nothing was executed. |

The repository root declares [Apache-2.0](https://github.com/yosupo06/library-checker-problems/blob/master/LICENSE). Catalog material is used only for algorithm and workload ideas; no source code, problem text, or fixtures have been copied. The source revision and remaining candidates still require review.

Static review of the existing [`kirkpatrick_hierarchical_point_location`](k/kirkpatrick_hierarchical_point_location/README.md)
ports found that truncated coordinate frames could be read before validation.
All nine existing ports now check the coordinate-frame length first; verifier
source includes a truncated-frame probe. A Mojo draft and ten-language source
check are now present. No code or checks have been run.

The existing [`nni_phylogeny_distance`](n/nni_phylogeny_distance/README.md)
profile now has a Mojo draft and ten-language source check. A verifier case
specifies one interchange between four-leaf topologies. These changes have not
been compiled or run.

### Remaining Mojo leads from static filename comparison

An earlier C-to-Mojo filename comparison identified `almabench` as a missing
port. A draft now exists, though it is not validated. Filename comparisons also surfaced
false positives where a Mojo source exists in another category, including
`comb_list_update`, `two_edge_connected_components`, `rat_maze`, and
`mibench_network_dijkstra`. No project code was executed for this review.

A subsequent basename comparison found further C filenames without matching
Mojo filenames: `cbench_automotive_susan_c`, `cbench_automotive_susan_e`,
`cbench_blowfish_cbc`, `cbench_consumer_lame_window_subband`,
`cbench_security_rijndael_decrypt`, `doe_rsbench_doppler_xs`,
`mallocbench_cfrac`, `mallocbench_espresso`, `mediabench_g721_encode`,
`mibench_automotive_susan`, `mibench_security_blowfish`,
`mibench_security_rijndael`, `qrduino`, `rodinia_mummergpu`,
`rodinia_myocyte_cam_rhs`, `schoenhage_strassen_multiply`,
`trimaran_enc_3des`, and `tripforce_tripcode`. These are coverage leads, not
proof of missing implementations or unique algorithms: compare contracts,
alternate symbols and locations, ownership, and rights before assigning work.
The comparison was static; no project code or checks were run.

Static follow-up across Mojo source paths found drafts for the listed SUSAN,
LAME, RSBench, Espresso, QRduino, MUMmerGPU, Myocyte, and Schönhage–Strassen
profiles. Three leads still have no matching Mojo source by name:
[`cbench_blowfish_cbc`](c/cbench_blowfish_cbc/README.md),
[`trimaran_enc_3des`](t/trimaran_enc_3des/README.md), and
[`tripforce_tripcode`](t/tripforce_tripcode/README.md). These are existing
registered workloads requiring language-coverage review, not new algorithms.
The Mojo [`des_ecb`](../mojo/d/des_ecb.mojo) draft provides a related DES
implementation, but it does not by itself implement three-key EDE or the
salt-modified repeated DES used by tripcode. Source-name inspection does not
establish correctness or exclude an implementation under another name.

The `trimaran_enc_3des` Mojo gap now has a draft using the local DES tables
and three forward/reverse key schedules; its package documentation and
verifier source-presence check are updated. It remains uncompiled and unrun.

Root reserves the `tripforce_tripcode` Mojo port, using its existing fixed
candidate contract and independently written local DES primitives. Do not
duplicate this port; no implementation or verification is claimed yet.

The reserved tripcode Mojo draft is now present with salted expansion, 25 DES
transforms, and ten-byte encoding. The existing byte-output suite registration
applies; the new source and its results remain uncompiled and unexecuted.
The verifier source now checks for that Mojo export. Static review also masked
the low 32-bit half before conversion in the separate Mojo `des_ecb` draft;
this avoids relying on narrowing a 64-bit permuted block directly. These
changes have not been compiled or run.

Static C-to-Mojo basename comparison now leaves two real source-name leads:
`cbench_blowfish_cbc` and `mibench_security_blowfish`. Root reserves both
Mojo ports. They share Blowfish key expansion but have distinct CBC and ECB
contracts; preserve the existing Eric Young license and attribution in each
source. The comparison also returned a directory artifact and a C header,
which are not missing benchmark implementations. Nothing was executed.

The CBC Mojo draft now includes key expansion, block rounds, both chaining
directions, and the retained license notice. It has not been compiled or run;
the MiBench ECB Mojo port remains outstanding.

The reserved MiBench ECB Mojo draft is now present, using the same key
expansion and block primitive as the CBC draft with the ECB-specific ABI and
retained license notice. Both ports remain uncompiled and unexecuted.
The byte-output verifier source also checks both Mojo exports and key notice
markers; that check has not been executed.

A static basename comparison found no Rust or Elisa `.rs`/`.elisa` source name
missing from the C or Mojo `.c`/`.mojo` source names respectively, and no C
source basename missing from C3 or Zig. A C++-to-Mojo comparison returned only
header filenames. This is a filename inventory only: it does not establish
matching contracts, suite registration, correctness, or completeness of the
broader source catalog. No project code was run for this comparison.

The [`mediabench_g721_encode`](g/mediabench_g721_encode/README.md) Mojo
port has a draft implementation and byte-output ABI, with a suite source
presence check. It has not been compiled or executed; codec correctness and
Mojo compatibility remain unverified.

The [`mallocbench_cfrac`](m/mallocbench_cfrac/README.md) profile now has a
Mojo draft for its bounded continued-fraction recurrence and GF(2) relation
search, plus a suite source-presence check. The implementation has not been
compiled or run, so compatibility and arithmetic results remain unverified.

The [`mibench_security_rijndael`](m/mibench_security_rijndael/README.md)
AES-256 block profile now has an algebraic Mojo draft and a suite source
presence check. Compilation and ciphertext correctness remain unverified.

The distinct inverse-block profile
[`cbench_security_rijndael_decrypt`](c/cbench_security_rijndael_decrypt/README.md)
now has a Mojo draft and a suite source-presence check. Its compilation and
inverse-block output remain unverified.

The [`cbench_consumer_lame_window_subband`](m/cbench_consumer_lame_window_subband/README.md)
profile now has a Mojo draft of the fixed analysis filterbank and a suite
source-presence check. Compilation, floating-point ordering, and byte output
remain unverified.
Its Elisa ABI now rejects null or incorrectly sized input before constructing
the bounded view, then uses that view throughout the filterbank. This static
correction has not been compiled or run.
The V draft's fixed-array literals and helper pointer access were corrected
in source; this draft also remains uncompiled and unexecuted.
The verifier draft now includes an independently chosen constant window with
zero PCM, for which all 32 output bands must be zero. It has not been run.
It also specifies signed central impulses with hand-derived cosine outputs;
these checks have not been run.
Static arithmetic review derives a conservative bound below 33.6 million per
band, so Q1000 conversion remains within signed 64-bit range for the documented
input bounds; floating-point equivalence remains unverified.

The [`schoenhage_strassen_multiply`](s/schoenhage_strassen_multiply/README.md)
Mojo draft now includes the recursive products, transforms and output ABI,
with a suite source-presence check. Nothing has been compiled or executed.

Static review of the existing Schönhage–Strassen ports found missing inverse
normalization in all nine ports, inverse-rotation direction errors in six,
and overlapping reconstruction storage in Zig. The corresponding source
edits are drafted; all require later compilation and oracle comparison.

The [`mallocbench_espresso`](m/mallocbench_espresso/README.md) bounded cover
profile has a Mojo bitset draft and a suite source-presence check. Compilation
and agreement with the independent oracle remain unverified.

The [`qrduino`](q/qrduino/README.md) Mojo draft includes framing,
Reed–Solomon parity, placement, mask scoring and the output ABI, with a suite
source-presence check. Nothing has been compiled or executed; the selected
mask remains unobservable in the existing output contract.

The research-only [`mibench_automotive_susan`](m/mibench_automotive_susan/README.md)
smoothing profile now has a Mojo draft and a suite source-presence check.
Its compilation, floating-point table values and filtered output remain
unverified.

The research-only [`cbench_automotive_susan_c`](c/cbench_automotive_susan_c/README.md)
corner detector now has a Mojo draft and a suite source-presence check. Its
compilation, table rounding, and detected corners remain unverified.

The research-only [`cbench_automotive_susan_e`](c/cbench_automotive_susan_e/README.md)
profile has a Mojo draft including response, thinning, drawing and the ABI,
with a suite source-presence check. Nothing has been compiled or executed;
topology and numerical behavior remain unverified.

### Library Checker proposal crosswalk, November 2026

These open proposals are used only as indexes of algorithm ideas; no issue
text, tests, or code is incorporated into the implementations.

| Candidate | Static inventory comparison | Status |
| --- | --- | --- |
| [Enumerate minimum prime factors](https://github.com/yosupo06/library-checker-problems/issues/1408) | [`linear_sieve`](l/linear_sieve/README.md) already constructs a smallest-prime-factor table using the cited linear sieve recurrence; [`smallest_prime_factor`](s/smallest_prime_factor/README.md) instead uses trial division for one integer. | Already present by algorithm: the proposed checksum and sampled table output are different workloads for the existing linear sieve, not a separate sieve kernel. |
| [Minimize DFA](https://github.com/yosupo06/library-checker-problems/issues/1387) | [`string_match_finite_automata`](s/string_match_finite_automata/README.md) builds a pattern matcher and [`hopcroft_karp_cardinality`](h/hopcroft_karp_cardinality/README.md) solves matching; neither performs DFA partition refinement. No matching minimization alias appeared in the static inventory search. | In progress — root: [`hopcroft_dfa_minimization`](h/hopcroft_dfa_minimization/README.md) has a bounded contract, ten language drafts, signature-refinement reference, fixtures, validator and scalar-suite registration. Nothing was executed; do not duplicate this reservation. |
| [Polynomial resultant](https://github.com/yosupo06/library-checker-problems/issues/1407) | The proposal computes a polynomial resultant over a finite field; static name searches did not identify an equivalent local package. General determinant and the special Vandermonde product are related operations, not the same kernel. | In progress — root: [`polynomial_resultant_half_gcd`](p/polynomial_resultant_half_gcd/README.md) reserves a scalable half-GCD/NTT profile with small references, fixtures, a validator, draft scalar-suite registration, and unverified drafts in all ten languages. Elisa's recursion-frame budget and Zig's arena peak workspace need review. Nothing has been executed; do not duplicate this reservation. |
| Zig resultant workspace follow-up | Static review found call-wide retention of temporary allocations. NTT, dot-product, division, inverse-iteration and recursive half-GCD scratch now use short-lived arenas; top-level batches alternate arenas while retaining the current pair. | Reduced retention in source; lifetimes, maximum-size peak space and correctness remain unverified. No compilation or profiling was performed. |
| [Sequence automaton](https://oi-wiki.org/string/seq-automaton/) | [`is_subsequence`](i/is_subsequence/README.md) and [`validate_subsequence`](v/validate_subsequence/README.md) scan the main sequence for a single query. A static README search for next-occurrence and subsequence automata found no other matching package. | In progress — root: [`subsequence_automaton`](s/subsequence_automaton/README.md) reserves the preprocessed next-occurrence method. Contract, workload including repeated queries over a shared text, table and scan references, ten language drafts, and scalar-suite registration are present but unverified. Algorithm description only; no external code or examples copied. Nothing has been executed; do not duplicate this reservation. |
| [Slope trick bounded-change fitting](https://oi-wiki.org/dp/opt/slope-trick/) | Median and isotonic methods do not maintain a two-sided bound on adjacent fitted values. Static searches found no matching bounded-change L1 or slope-trick profile. | In progress — root: [`slope_trick_lipschitz_l1`](s/slope_trick_lipschitz_l1/README.md) reserves the dual-heap, lazy-shift method. Contract, independent bounded-domain dynamic-programming reference, rights note, workload, ten language drafts, and scalar-suite registration exist but remain unverified. Nothing has been executed; do not duplicate this reservation. |
| [Weighted binary search for path selection](https://oi-wiki.org/dp/opt/wqs-binary-search/) | [`max_non_adjacent_sum`](m/max_non_adjacent_sum/README.md) has no exact selection count; [`maximum_independent_set`](m/maximum_independent_set/README.md) is an unweighted graph problem. Static searches found no matching exact-cardinality path profile using penalty search. | In progress — root: [`wqs_path_independent_set`](w/wqs_path_independent_set/README.md) reserves the penalty-search method. Contract, independent exact-count dynamic-programming oracle, rights note, workload, ten language drafts, and scalar-suite registration exist but remain unverified. Nothing has been executed; do not duplicate this reservation. |
| [OI Wiki Chirp Z transform](https://oi-wiki.org/math/poly/czt/) | [`fft_bluestein`](f/fft_bluestein/README.md) and [`multipoint_evaluation_on_geometric_sequence`](m/multipoint_evaluation_on_geometric_sequence/README.md) already use the chirp/Bluestein transform family. | Already present; no duplicate benchmark reserved for the same method. |
| [OI Wiki Cartesian tree](https://en.oi-wiki.org/ds/cartesian-tree/) | [`cartesian_tree`](c/cartesian_tree/README.md) already constructs an array Cartesian tree with the same monotonic-stack right-spine method. | Construction already present; no duplicate construction benchmark reserved. Its histogram application is method-distinct from the direct stack scan and is reserved separately below. |
| [Cartesian-tree histogram area](https://en.oi-wiki.org/ds/cartesian-tree/) | [`largest_rectangle_histogram`](l/largest_rectangle_histogram/README.md) calculates areas during stack pops, while [`cartesian_tree`](c/cartesian_tree/README.md) emits the tree without calculating its subtree-area maximum. | In progress — root: [`cartesian_histogram_area`](c/cartesian_histogram_area/README.md) reserves explicit tree construction and postorder subtree aggregation. Contract, independent interval reference, rights note, workload, ten language drafts, and scalar-suite registration exist but remain unverified. Nothing has been executed; do not duplicate this reservation. |
| [CP-Algorithms minimum-diameter spanning tree](https://lib.cp-algorithms.com/verify/graph/minimum_diameter_spanning_tree.test.cpp) | [`minimum_diameter_spanning_tree`](m/minimum_diameter_spanning_tree/README.md) already covers the graph objective and has a center-enumeration profile. | Already present; the catalog task identifies an existing benchmark, so no duplicate is reserved. This crosswalk does not assert that the two implementations use identical internal optimizations. |
| [Quadratic form over GF(2)](https://github.com/yosupo06/library-checker-problems/issues/1398) | Static searches found no obvious quadratic-form canonicalization package. Binary matrix elimination and quadratic-equation solvers do not establish equivalence to a characteristic-two quadratic-form change of basis. | Candidate: review aliases and the normal-form/output contract before reservation. |
| [Range-constraint topological ordering](https://github.com/yosupo06/library-checker-problems/issues/1428) | The existing [`topological_sort`](t/topological_sort/README.md) consumes explicit directed edges. [`two_interval_precedence_chain`](t/two_interval_precedence_chain/README.md) solves a different scheduling-chain problem. The existential predecessor condition is not an ordinary conjunction of edges; no matching compressed-range package was found in the static alias search. | In progress — root: [`range_constraint_topological_feasibility`](r/range_constraint_topological_feasibility/README.md) has ten language drafts, an expanded-range reference, fixtures, a validator and scalar-suite registration. Nothing has been compiled or executed; do not duplicate the reservation. |
| [Weighted two-vertex cuts](https://github.com/yosupo06/library-checker-problems/issues/1427) | Existing biconnectivity and [`vertex_connectivity`](v/vertex_connectivity/README.md) cover related connectivity questions, but the proposal aggregates component counts after every vertex pair and points to triconnected decomposition. The encyclopedia crosswalk records SPQR support as incomplete. | Candidate: investigate SPQR/triconnected aliases and a scalable decomposition before reservation; repeated vertex-pair deletion is useful as a small oracle but does not substitute for that kernel. |
| [Lexicographically minimal concatenation](https://github.com/yosupo06/library-checker-problems/issues/1414) | [`string_heap_sort`](s/string_heap_sort/README.md) sorts fixed-width keys directly, while [`largest_of_very_large_numbers`](l/largest_of_very_large_numbers/README.md) compares powers. Neither orders variable strings by their virtual pairwise concatenations; no equivalent was found in the static alias search. | In progress — root: [`lexicographically_minimal_concatenation`](l/lexicographically_minimal_concatenation/README.md) has ten suffix-array/LCP drafts, independent references, fixtures, a validator and byte-suite registration. Nothing has been compiled or executed; do not duplicate this reservation. |
| [Convolution on the symmetric group](https://github.com/yosupo06/library-checker-problems/issues/1432) | The proposal asks for convolution of two functions indexed by permutations, under permutation composition modulo 998244353, and suggests a symmetric-group Fourier method for degrees up to nine. A static README and catalog search found no symmetric-group convolution or nonabelian Fourier profile; existing cyclic, XOR, subset, and multiplicative convolutions use different index operations. | Confirmed distinct candidate; a scalable symmetric-group Fourier implementation and its field/representation constraints need research before reservation. The proposal notes its bounds are tentative. A direct factorial-squared implementation is suitable as a small independent oracle, not a substitute for the proposed scalable kernel. The [SnFFT paper](https://jmlr.csail.mit.edu/beta/papers/v16/plumb15a.html) identifies Fourier transforms and convolution on permutation groups; use source material for ideas only. No code, problem text, or fixtures were copied, and no program was run. |
| [Suffix array over a linear integer alphabet](https://github.com/yosupo06/library-checker-problems/issues/1419) | Existing [`suffix_array_sais`](s/suffix_array_sais/README.md) uses SA-IS on a bounded byte alphabet. The proposed wider alphabet changes the input range, not the construction method. | Already present by algorithm; a larger-alphabet workload remains a possible coverage improvement, not a separate algorithm. |
| [Hook-length count for Young tableaux](https://github.com/yosupo06/library-checker-problems/issues/1418) | No matching Young-tableau/hook-length package found in the static inventory search. Integer partition packages enumerate different objects. | Drafted: [`hook_length_tableaux`](h/hook_length_tableaux/README.md) has ten language drafts, a row-oriented oracle, fixtures, and scalar-suite registration. None has been executed or verified. |
| [Pairwise difference product](https://github.com/yosupo06/library-checker-problems/issues/1417) | The [`polynomial_interpolation`](p/polynomial_interpolation/README.md) oracle builds a Vandermonde system but solves interpolation; [`multipoint_evaluation`](m/multipoint_evaluation/README.md) exposes individual values, not the ordered difference product. | In progress: [`difference_product`](d/difference_product/README.md) has ten language drafts, an independent oracle, fixtures, and scalar runner/verifier registration. The sources and suite changes are unexecuted; correctness, compilation, and Elisa workspace/stack bounds remain unverified. Do not duplicate this reservation. |
| [Maximum-area triangle in a convex polygon](https://github.com/yosupo06/library-checker-problems/issues/1397) | The existing [`triangle`](t/triangle/README.md) computes centers for three fixed vertices, while [`rotating_calipers`](r/rotating_calipers/README.md) computes diameter. No matching maximum-triangle package was found in the static alias search. | In progress — root: [`maximum_area_triangle_convex`](m/maximum_area_triangle_convex/README.md) has a bounded contract, ten language drafts, an exhaustive reference, fixtures, a package validator and scalar-suite registration. Nothing has been executed or verified. Do not duplicate this reservation. |

**In progress — root:** `quadratic_form_gf2_normal_form` reserves a
characteristic-two quadratic-form reduction, including an invertible change
of coordinates and a canonical form. Static README and catalog searches for
quadratic forms, Arf invariants, symplectic bases, and hyperbolic planes found
no matching package; scalar quadratic solvers and GF(2) matrix operations do
not perform this reduction. The [Library Checker proposal](https://github.com/yosupo06/library-checker-problems/issues/1398)
is an idea index; no proposal text, implementation, or examples are copied.
The planned degree range reaches 100. Symbolic result-validator and direct
construction-reference drafts are present. The ABI and all ten language
construction drafts are written. A small workload, ABI reference adapter, and byte-output
runner/verifier registration are drafted, including generated forms through
degree 100 and symbolic validation. The integration remains unexecuted.
The package now explicitly records the deterministic basis-selection policy
required by the byte-exact harness; the independent validator also accepts
other valid bases. The verifier source specifies exhaustive forms through
degree four and cross-chunk boundary cases. Port-by-port agreement remains unverified.
The Rust inversion draft now copies pivot rows before mutating other rows,
avoiding simultaneous indexed borrows. This change has not been compiled.
Static review also repaired missing closing braces in its quadratic and polar
evaluation loops. This syntax correction has not been compiled.
Do not duplicate this reservation. Nothing has been run.

This crosswalk is a partial search, not proof that every alias has been found.
The proposals are open ideas, not necessarily accepted Library Checker tasks.
The Elisa drafts for `subsequence_automaton`, `slope_trick_lipschitz_l1`, and
`wqs_path_independent_set` now use bounded frame views after their ABI input
checks. These edits have not been compiled or run.
The Elisa drafts for `cartesian_histogram_area`,
`range_constraint_topological_feasibility`, `maximum_area_triangle_convex`,
and `hook_length_tableaux` also use bounded views for their inputs after
the relevant ABI and framing checks; these edits remain unexecuted.
The same static input-view cleanup was applied to the Elisa drafts of
`hopcroft_dfa_minimization`, `polynomial_resultant_half_gcd`,
`difference_product`, and `lexicographically_minimal_concatenation`. Their
existing workspace and correctness questions remain unverified.

For the symmetric-group convolution lead, [Maslen and Rockmore's group-FFT
overview](https://library2.msri.org/books/Book46/files/11maslen.pdf) describes
subgroup-chain factorization and partition-indexed representation blocks.
Its orthogonal basis is presented over complex numbers; the proposed finite
field implementation still needs a basis and inverse transform valid in the
specified field, an explicit permutation-composition convention, and a
factorial-scaled workspace plan. The paper is used as mathematical guidance,
not as a source of copied code or fixtures. Direct noncommutative convolution
on small groups can serve as an independent reference once the convention is
fixed. Root now reserves `symmetric_group_convolution_fft` for the full
degree-1-through-9 transform profile. A small direct reference is for
validation only; it must not replace the fast transform. No production kernel
or suite integration is claimed, and nothing has been run.
The draft now has pair-oriented and target-oriented small references, explicit
noncommutative S3 probes, and notes fixing composition, Fourier block order,
and subgroup cosets. A tableau enumerator and proposed sparse seminormal
generators are now drafted; their relations and the scalable inverse remain
unverified. None of these references or probes has been executed.
Static review changed tableau order to group restriction blocks by their last
cell and added unexecuted reference checks for Coxeter relations and subgroup
block boundaries through degree five. This is not a production FFT.
A research forward-transform draft now uses the subgroup recurrence and has
unexecuted convolution-theorem checks against the small references. An inverse
draft uses the transposed recurrence and an invariant diagonal form; both
transforms and round-trip checks remain unexecuted. Scalable workspace,
language ports and suite wiring remain.
An unexecuted research convolution now connects the forward transform,
ordered block multiplication, and inverse transform; it is not a production
port and its scaling and results remain unverified.
The generic byte-output C runner and checker now support compile-time bounds;
the builder selects the degree-nine limits for this reserved symbol while
retaining existing defaults for other algorithms. Python runner/verifier
integration and a streaming path for paired comparison remain outstanding.
The harness and builder changes have not been compiled or run.
The Python runner now has algorithm-specific input and output size guards and
permits a zero-length null case for the reserved symbol. Oracle dispatch and
verifier integration remain outstanding; these edits have not been executed.
Closed-form identity and constant-function corpus cases are drafted through
degree nine, including an extra-word rejection. They have not been generated
or run and do not substitute for dense independent reference cases.
The ABI reference now supports constant and single-support inputs throughout
the full proposed degree range, with lexicographic permutation translation;
other inputs above degree five remain explicitly unsupported by the reference.
Source-only small-case comparisons are drafted but have not been run.
An independently written C++ tableau/generator plan scaffold now exists for
degrees through nine, with restriction embeddings, forward and inverse
subgroup transforms, and a C++ ABI draft. These are uncompiled; exception
handling, dependency tracking, other language ports and suite registration
remain outstanding.
The C++ ABI now maps internal logic errors to `-4`, and the builder records
its three header hashes. The byte-output runner now validates those hashes and
includes them in records; the verifier source compares the recorded list with
the manifest. Runtime verification and suite registration remain outstanding;
the edits have not been executed.
A separate Rust tableau/generator/restriction plan and forward subgroup
transform are now drafted, along with an inverse recurrence and ABI entry
point. The builder and runner record and check the three Rust module hashes.
The plan, forward transform, inverse, and block products now use fallible vector
reservation in the source draft; allocation handling still needs verification.
The byte runner now has draft oracle dispatch and a small hand-derived workload.
The paired C harness has an uncompiled full-size stdin path and an unexecuted
driver for selected structured cases. A verifier draft checks an existing build,
the checker corpus, and recorder provenance; it has not been executed. The
other language ports and end-to-end verification remain outstanding. None of the
drafts has been compiled or run.
The C port now has uncompiled tableau, generator and restriction planning,
subgroup forward and inverse transforms, and an ABI entry point. The builder,
runner and verifier sources record or check its three header dependencies;
the port and provenance handling remain unverified.
The small byte-output workload now also specifies dense modular products and
invalid-input precedence, including null inputs with nonzero declared length;
these fixture additions have not been executed.
Uncompiled Nim tableau, generator and restriction planning, forward and inverse
subgroup transforms, and an ABI entry point are drafted. The builder, runner and
verifier sources record or check the three module hashes; allocation-failure
behavior remains unresolved and all of these drafts remain unverified.
The Nim build draft selects ARC for this sequence-heavy kernel rather than the
default `--mm:none`; runtime initialization and reclamation are unverified.
Uncompiled Zig representation planning, forward and inverse subgroup transforms,
and ABI entry point now have builder, runner and verifier source-dependency
handling. Correctness, allocation handling and peak scratch use remain
unverified.
An uncompiled Odin representation plan, forward and inverse transforms, and ABI
entry point are drafted. The entry initializes a default Odin context before
allocation; initialization and allocation-failure behavior remain unverified.
An uncompiled V representation plan, forward and inverse transforms, and ABI
entry point are drafted; memory handling under `-gc none` and recoverable
allocation-failure behavior remain outstanding.
An uncompiled C3 representation plan, forward and inverse transforms, and ABI
entry point now cover tableaux, generators, restrictions and error statuses.
Correctness and failure handling remain unverified.
Uncompiled Elisa drafts use caller-owned views for tableau, restriction and
generator planning, forward subgroup recursion, inverse weighting and transpose
recursion, an ordered block-product kernel, and an ABI allocation wrapper. The
build source composes the four helper files and provenance checks their hashes;
compilation, workspace bounds, allocation handling and correctness remain open.
An uncompiled Mojo draft uses caller-owned lists for tableau, restriction and
generator planning, forward subgroup recursion, inverse weighting, transpose
recursion and an ABI entry point. Recoverable allocation handling and all
runtime behavior remain unverified.
Static review also added singleton field-boundary and degree-three identity
fixtures to the shared byte-output workload; they remain unexecuted.
The structured full-range corpus now drafts dense sign-character and
even-subgroup cases in addition to identity, constant, and sparse cases; the
paired driver recognizes their names. These cases have not been generated or run.
The ABI reference source now recognizes exact sign-character and even-subgroup
operands over the full range, so the byte runner can reference those shapes;
its recognition and formulas remain unexecuted.
The structured corpus and ABI reference also draft dense coordinate-function
cases in both product orders, using counts of constrained permutations rather
than the transform. The paired driver recognizes them; none has been run.

The existing [`doe_rsbench_doppler_xs`](r/doe_rsbench_doppler_xs/README.md)
profile now has an MIT-attributed Mojo draft with both complex approximation
branches and the existing scalar-float ABI. A ten-language source-presence
check is drafted. Nothing has been compiled or run.

The existing [`rodinia_myocyte_cam_rhs`](m/rodinia_myocyte_cam_rhs/README.md)
profile now has a Mojo mixed-precision draft and suite source-presence check.
Its binary32 rounding and expression ordering remain unverified; no code has
been compiled or run.

The existing [`rodinia_mummergpu`](m/rodinia_mummergpu/README.md) suffix-trie
profile now has a Mojo draft and suite source-presence check. The draft has not
been compiled or run.
Verifier source now also specifies a repeated-prefix case that distinguishes
the required terminator-last suffix order. The probe remains unexecuted.
Static comparison with the independent reference corrected two constant
promotion points in the Mojo and Rust drafts: both now round the stored
binary32 constant before promoting it for division. These edits are unexecuted.

The existing [`richards_benchmark`](r/richards_benchmark/README.md) scheduler
now has a Mojo draft and ten-language source-presence check. Static review also
corrected missing README markers required by its workload validator. The draft
and suite changes have not been compiled or run.
The Richards workload and validator now use a port-count-independent provenance
note, and the package describes cost in terms of scheduler dispatches. These
documentation and metadata changes are also unexecuted.

The [`olden_voronoi`](o/olden_voronoi/README.md) Mojo draft now includes the
quad-edge topology, bounded merge, dual traversal, and ABI entry point. It uses
the existing scalar suite registration and independent empty-circle oracle.
The draft has not been compiled or run; static and runtime verification remain
outstanding.
The Olden Voronoi verifier source now generates ordered three- and five-point
frames and their vertical reflections, addressing the previous generator's
low chance of reaching a valid merge. These probes have not been run.

The existing [`shootout_methcall`](s/shootout_methcall/README.md) profile now
has a Mojo callback-field draft. Its runtime function values and preservation
of indirect dispatch have not been compiled, inspected in generated code, or
executed; do not treat the draft as validated.
Verifier source also specifies consecutive counts through four counter-reset
cycles. Those cases and the draft remain unexecuted.

The existing [`shootout_objinst`](s/shootout_objinst/README.md) profile now has
a Mojo allocation, callback, and external-observation draft with distinct
Toggle and NthToggle layouts. C ABI and function-value syntax, object
lifecycle, and retained allocation and dispatch behavior remain unverified;
no code has been compiled or run.
Static inspection confirms the build entry point includes the separate observer
source for this benchmark. The verifier source now checks for that source and
the helper symbols used by the Mojo and Elisa drafts; it has not been run.

The `fortune_voronoi` Mojo draft now includes the bounded site/circle event
sweep, beachline neighbor collection, rational cell clipping, input validation,
serialization, and ABI entry point. It has not been compiled or run and needs
static and runtime verification, including rational intermediate bounds.
Its Mojo fraction operations now cancel common factors before multiplication;
this reduces intermediate sizes but is not a proof that all bounded inputs fit
signed 64-bit arithmetic. The change remains uncompiled and unexecuted.

**In progress — root:** Static comparison of the existing
[`beebs_nettle_cast128`](b/beebs_nettle_cast128/README.md) key schedule against
[RFC 2144 section 2.4](https://www.rfc-editor.org/rfc/rfc2144) found that the
old reference and reviewed ports reused stale intermediate bytes and repeated
the wrong subkey selection pattern. The primary oracle is corrected; all
existing ports and fixtures require review and repair. All nine existing language drafts have now received the two schedule
fixes; Odin's subkey buffer type was also corrected. The package must not be treated as verified. No
code has been run.
The Mojo CAST-128 draft now contains the bounded Feistel rounds, standard
substitution tables, key expansion, and ABI entry point. Existing ciphertext
fixtures need review after the schedule repair; all drafts and the reference
remain unexecuted.
Static follow-up corrected the Rust draft's conflicting access to the mutable
key-schedule array during calls and clarified that key expansion is included
in the timed operation. Neither correction has been compiled or run.
Static follow-up also added the missing Elisa export and explicit byte masks
before Nim narrowing conversions. Those changes remain uncompiled and
unexecuted.
The V schedule draft now copies the newly generated bytes into its mutable
input slice element by element. This correction is also uncompiled and
unexecuted.
The package rights note no longer gives a stale port count, and its guide now
states the fixed-size time and space costs. This is documentation review, not
evidence of cipher correctness.
Static source review found that the BEEBS first-block ciphertext occurs only in
a commented-out upstream value; upstream's active check verifies decrypted
plaintext. The RFC-derived known-answer fixture and derived error probes were
removed in favor of independently chosen error inputs. The source-derived
successful case was also replaced by an independently chosen input; its output
is computed by the local reference during suite operation. That reference has
not been executed or independently validated, so correctness remains unproven.

The `almabench` Mojo draft now contains the orbital coefficients, daily model,
six-decimal formatter, and ABI. Floating-point equivalence and retention of
the daily and velocity calculations under optimization require verification.
Its angle reduction calls the C `fmod` function rather than reconstructing the
remainder with rounded arithmetic. The draft and ten-language source check
have not been compiled or run.

The existing [`freebench_fbench`](f/freebench_fbench/README.md) ray-trace
profile now has a Mojo draft retaining its origin attribution. The draft is
uncompiled and unexecuted.

The existing [`olden_health`](o/olden_health/README.md) village and hospital
queue simulation now has a Mojo draft. It has not been compiled or run.

The existing [`delaunay_triangulation`](d/delaunay_triangulation/README.md)
profile now has a Mojo Bowyer–Watson draft, ten-language source check, and
single-triangle insertion-order verifier cases. These are uncompiled and
unexecuted.

The existing [`phylogenetic_tree_from_distance_matrix`](p/phylogenetic_tree_from_distance_matrix/README.md)
profile now has a Mojo additive-tree draft, ten-language source check, and
verifier probes for half-unit branches and null-tree handling. These are
uncompiled and unexecuted.

The existing [`prolangs_football_tiebreaks`](p/prolangs_football_tiebreaks/README.md)
profile now has a Mojo draft with source attribution and complete-group score
comparisons. It has not been compiled or run.

Static review of [`steiner_tree_gain_greedy`](s/steiner_tree_gain_greedy/README.md)
found that the C and C++ ports narrowed the vertex count before validating it.
Both now validate the original 64-bit value; verifier source includes large
counts that could narrow to valid ones. A Mojo draft and ten-language source
check are now present. No code or checks have been run.

The existing [`thorup_zwick_distance_oracle`](t/thorup_zwick_distance_oracle/README.md)
profile now has a Mojo draft and a ten-language source check. These have not
been compiled or run.

The existing [`pargeo_bichromatic_closest_pair`](p/pargeo_bichromatic_closest_pair/README.md)
profile now has a Mojo dual-KD-tree draft; it retains the package's MIT
provenance and has not been compiled or run.

The existing [`upward_planarity_angle_assignment`](u/upward_planarity_angle_assignment/README.md)
profile now has a Mojo draft and ten-language source check. Neither has been
compiled or run.

Static follow-up corrected that workload's runner field names and the primary
oracle's rejection of the documented two-vertex single-edge graph. A
single-edge fixture and malformed-frame fixture now document those boundaries;
the reference and suite changes remain unexecuted.
Verifier source also specifies both orientations of the single edge, short and
null output buffers, malformed walks, and null input. These probes are written
but have not been run.

The existing [`ptrdist_anagram`](p/ptrdist_anagram/README.md) packed-count
search now has a Mojo draft with source attribution. It checks packed fields
before subtraction to avoid unsigned underflow and remains uncompiled and
unexecuted.

The existing [`freebench_distray`](f/freebench_distray/README.md) one-pixel
ray-tracing profile now has a Mojo draft retaining its source attribution and a
ten-language source-presence check. These are uncompiled and unexecuted.

The existing [`delaunay_mesh_refinement`](d/delaunay_mesh_refinement/README.md)
profile now has a Mojo draft, a ten-language source-presence check, and a
verifier case with a directly specified circumcenter. These changes have not
been compiled or run.

The existing GPL-2.0-or-later [`paq8p_context_mixer`](p/paq8p_context_mixer/README.md)
profile now has a Mojo draft and suite source-presence check. The draft retains
the package's attribution and has not been compiled or run.

The existing [`mafft_falign_fft_lag_correlation`](m/mafft_falign_fft_lag_correlation/README.md)
profile now has a Mojo FFT draft and a suite source-presence check. It has not
been compiled or run; its BSD notice remains with the package.

Static review of the existing [`saga_incremental_analytics`](s/saga_incremental_analytics/README.md)
drafts found unchecked addition of two input edge counts. Nine ports now bound
both counts before adding, and verifier source includes extreme malformed
counts. A ten-language source set now includes a Mojo draft; no code or checks
have been run.

Static inspection of the four Mojo array-rotation drafts found signed 32-bit
values serialized through a direct unsigned narrowing conversion. Their byte
writers now take the low four bytes of a bitcast 64-bit value, preserving the
specified two's-complement representation for negative inputs. The drafts have
not been compiled or run.

# Encyclopedia of Algorithms coverage: G–M

Static chapter inventory from the supplied EPUB. DOI suffixes below are the
chapter identifiers. “Package” means a clean-room bounded profile was added.
“Partial” means the package covers a clearly scoped source algorithm/profile
but omits other chapter behavior. “Existing” maps an operation to a local
package or records an algorithm-core duplicate. “Not ported” gives the
chapter-specific model, variant, or output reason that prevents a single
bounded deterministic profile from representing the source entry. No code
was run for this audit.

| Chapter | DOI suffix | Disposition | Benchmark or static reason |
|---|---:|---|---|
| Gate Sizing | 159 | not a bounded benchmark | Physical VLSI sizing model; no self-contained input/output kernel. |
| General Equilibrium | 160 | not a bounded benchmark | Economic model and equilibrium notion vary by application. |
| Generalized Steiner Network | 161 | not a bounded benchmark | Broad network-design problem with several approximation frameworks. |
| Generalized Two-Server Problem | 162 | not a bounded benchmark | Online competitive-analysis family, not one fixed service rule. |
| Generalized Vickrey Auction | 163 | not a bounded benchmark | Mechanism-design model depends on valuation and incentive assumptions. |
| Geographic Routing | 164 | Partial: [geometric_greedy_compass_routing](g/geometric_greedy_compass_routing/README.md) covers the chapter's same bounded Greedy and Compass local-forwarding cores as DOI 352. Its Face Routing/GOAFR+ modes need planarization and face-marker/fallback details absent from the chapter's bounded procedure; other modes are mapped in DOI 352's crosswalk. |
| Geometric Approaches to Answering Queries | 553 | not a bounded benchmark | Survey of geometric query structures and workloads. |
| Geometric Dilation of Geometric Networks | 166 | not a bounded benchmark | Continuous-geometry network construction family. |
| Geometric Object Enumeration | 727 | not a bounded benchmark | Enumeration problem class without one finite canonical object family. |
| Geometric Shortest Paths in the Plane | 509 | not a bounded benchmark | Polygonal-obstacle geometry and exact path representation are outside the current bounded graph ABI. |
| Geometric Spanners | 167 | not a bounded benchmark | Multiple spanner constructions and stretch/density contracts. |
| Global Minimum Cuts in Surface-Embedded Graphs | 683 | not a bounded benchmark | Requires surface embedding/topology contracts beyond ordinary graph input. |
| Global Routing | 741 | not a bounded benchmark | VLSI routing problem with layout-specific constraints. |
| Gomory-Hu Trees | 168 | existing | [Gomory-Hu tree](g/gomory_hu_tree/README.md). |
| Grammar Compression | 635 | not a bounded benchmark | Grammar-compression family; no canonical grammar/encoding profile selected. |
| Graph Bandwidth | 169 | not a bounded benchmark | NP-hard graph-labeling problem with multiple approximation approaches. |
| Graph Coloring | 170 | partial | [Greedy coloring](g/greedy_graph_coloring/README.md), [graph coloring](g/graph_coloring/README.md), [backtracking](g/graph_coloring_backtracking/README.md), and [Pannotia priority-extrema coloring](p/pannotia_priority_coloring/README.md) remain distinct bounded profiles. DOI 170 states Karger–Motwani–Sudan's vector-coloring/SDP result and summarizes Wigderson and later small-χ results by theorem, but does not specify the SDP solver/rounding, vector-to-independent-set threshold or selection rule, or Wigderson's recursive degree-threshold procedure. The high-level statements therefore do not define a source-faithful additional coloring implementation; specialized algorithms are not claimed covered. |
| Graph Connectivity | 171 | partial | [Greedy 2-edge-connected spanning subgraph](t/two_edge_connected_spanning_subgraph_greedy/README.md) implements the chapter's simple critical-edge deletion algorithm at fixed k=2 for edge connectivity; input edge order is the deterministic consideration order, and the profile requires an initially 2-edge-connected simple graph. It is distinct from the local bridge/connected-components helpers, which do not perform ordered reverse deletion to construct an inclusion-minimal 2-edge-connected spanning subgraph. Connected components, bridges, [GBBS biconnectivity](g/gbbs_biconnectivity/README.md), [GBBS spanning forest](g/gbbs_shiloach_vishkin_spanning_forest/README.md), and dynamic connectivity packages cover additional selected operations. Other k values, vertex-connectivity variants, and the chapter's DFS/matching-based approximation algorithms remain uncovered. |
| Graph Isomorphism | 172 | partial | [Graph isomorphism](i/is_isomorphic/README.md) gives a bounded pairwise decision profile. DOI 172 focuses on nauty's practical canonical-labeling/automorphism-group interface, but does not give its partition-refinement/search steps; the stated canonical-form property and experimental timings alone do not define a portable source-faithful implementation. The chapter does specify two input reductions—edge colors to layered vertex colors, and hypergraph incidence to a two-colored graph—but these are representation transforms, not the nauty canonical-labeling core. Specialized bounded-genus/degree/tree-width algorithms are named without construction procedures. |
| Graph Sketching | 796 | not ported | The entry gives a connectivity-emulation outline for dynamic graph streams and simultaneous row communication, but its central ℓ0-sampling step is delegated to a cited distribution over random matrices; it does not specify the sampler's matrix construction or recovery decoder. A fixed random tape alone cannot make that missing sketch primitive source-faithful. The local count-min sketch is a different primitive. |
| Greedy Approximation Algorithms | 174 | not a bounded benchmark | Broad algorithm-design survey rather than one algorithm. |
| Greedy Set-Cover Algorithms | 175 | partial | [Weighted Chvátal greedy set cover](g/weighted_greedy_set_cover/README.md) selects the minimum exact weight/new-coverage ratio with deterministic set-ID ties. GBBS approximate set cover remains a distinct unweighted bucket/priority algorithm. |
| Hamilton Cycles in Random Intersection Graphs | 176 | not a bounded benchmark | Probabilistic graph model and existence/threshold results rather than a single deterministic kernel. |
| Haplotype Inference on Pedigrees Without Recombinations | 802 | not a bounded benchmark | Specialized biological model and data semantics. |
| Hardness of Proper Learning | 177 | not a bounded benchmark | Complexity/hardness results. |
| Harmonic Algorithm for Online Bin Packing | 490 | package | [Parameterized HARM(k)](h/harmonic_k_bin_packing/README.md) implements the chapter-defined reciprocal classes and independent class-local Next Fit for bounded k=3..8, including the former HARM-4 profile at k=4. The bounded fixtures do not claim the asymptotic competitive ratio. |
| Hierarchical Self-Assembly | 667 | not a bounded benchmark | Self-assembly model and theoretical constructions. |
| Hierarchical Space Decompositions for Low-Density Scenes | 590 | not a bounded benchmark | Geometry/data-structure family requiring scene representations. |
| High Performance Algorithm Engineering for Large-Scale Problems | 178 | not a bounded benchmark | Engineering methods and case studies, not one algorithm. |
| Holant Problems | 748 | not a bounded benchmark | Complexity framework for counting problems. |
| Holographic Algorithms | 746 | not a bounded benchmark | Complexity-theoretic algorithm framework. |
| Hospitals/Residents Problem | 180 | package | [Resident-oriented Gale–Shapley](h/hospitals_residents_rgs/README.md) covers hospital capacities, incomplete mutually acceptable lists, and resident-optimal deferred acceptance. [Stable matching](s/stable_matching/README.md) remains the complete one-to-one special case. |
| Hospitals/Residents Problems with Quota Lower Bounds | 675 | not ported | The entry defines three lower-quota stability objectives, including minimizing blocking pairs; the feasibility/stability contract changes by variant, so standard Hospitals/Residents stability does not select one source profile. |
| Hub Labeling (2-Hop Labeling) | 580 | Partial: [hub_labeling_pruned](g/hub_labeling_pruned/README.md) covers canonical labels for a supplied high-to-low order using pruned BFS; [hub_labeling_greedy_order](h/hub_labeling_greedy_order/README.md) adds the chapter's distinct greedy order-selection rule, repeatedly choosing the vertex covering the most uncovered ordered shortest paths (self-pairs included, lowest-ID ties), then emits canonical labels. Both are bounded to connected undirected unit graphs with unique shortest paths. The general-labeling maximum-density/parametric-flow approximation, directed forward/backward labels, weighted path variants, and RXL sampling heuristics remain outside these profiles. |
| Huffman Coding | 633 | existing | [Huffman weighted cost](h/huffman_weighted_cost/README.md), with additional compressor/table profiles. |
| I/O-Model | 190 | not a bounded benchmark | Abstract machine model and asymptotic analysis. |
| Implementation Challenge for Shortest Paths | 181 | not ported | This entry is an experimental challenge comparing implementations and instance sets, not a single shortest-path algorithm. |
| Implementation Challenge for TSP Heuristics | 182 | not ported | This entry is an experimental challenge over several TSP heuristics and instance generators; no one heuristic is the chapter's benchmark kernel. |
| Implementing Shared Registers in Asynchronous Message-Passing Systems | 183 | not a bounded benchmark | Distributed protocol and asynchronous execution model. |
| Incentive Compatible Selection | 186 | not a bounded benchmark | Mechanism-design assumptions determine the operation. |
| Independent Sets in Random Intersection Graphs | 187 | not a bounded benchmark | Probabilistic graph-model results; no single deterministic kernel. |
| Indexed Approximate String Matching | 188 | not ported | The entry covers both k-mismatch and k-difference queries and multiple text-index structures; choosing the index, edit model, and query interface changes the algorithm profile. |
| Indexed Regular Expression Matching | 339 | not ported | The source problem is retrieval over a dynamic disk-resident database of regular expressions; index construction and update strategy are not represented by the local string-matching engine contracts. |
| Indexed Two-Dimensional String Matching | 442 | not a bounded benchmark | Specialized multidimensional index and query semantics. |
| Inductive Inference | 189 | not a bounded benchmark | Learning-theory model without a single finite deterministic algorithm. |
| Influence and Profit | 624 | not a bounded benchmark | Network-economic objective depends on the influence/profit model. |
| Influence Maximization | 710 | not a bounded benchmark | Randomized diffusion model and estimator choices do not yield one canonical bounded profile. |
| Intersections of Inverted Lists | 628 | partial | [Three-way sorted arrays intersection](s/sorted_arrays_intersection/README.md) matches the chapter's uncompressed simultaneous DAAT core for three strictly increasing postings lists: one cursor per list, ascending common IDs. The two-list case is covered by [intersection of two arrays](i/intersection_of_two_arrays/README.md). Arbitrary-arity DAAT, compressed-list probing/bitvectors/wavelet trees, adaptive query planning, ranking/top-k, and document reordering are not represented. |
| Intrinsic Universality in Self-Assembly | 661 | not a bounded benchmark | Theoretical universality constructions. |
| Jamming-Resistant MAC Protocols for Wireless Networks | 593 | not a bounded benchmark | Distributed wireless protocol and adversary model. |
| k-Best Enumeration | 733 | not a bounded benchmark | Multiple k-best problem families and ordering contracts. |
| Kernelization, Bidimensionality and Kernels | 526 | not a bounded benchmark | Parameterized-complexity framework and problem-dependent reductions. |
| Kernelization, Constraint Satisfaction Problems Parameterized above Average | 524 | not a bounded benchmark | Problem-specific parameterized reductions. |
| Kernelization, Exponential Lower Bounds | 521 | not a bounded benchmark | Lower-bound theory. |
| Kernelization, Matroid Methods | 523 | not a bounded benchmark | Framework spanning multiple problems and reductions. |
| Kernelization, Max-Cut Above Tight Bounds | 531 | not a bounded benchmark | Parameterized kernelization theory, distinct from a Max-Cut solution profile. |
| Kernelization, MaxLin Above Average | 532 | not a bounded benchmark | Parameterized reduction family. |
| Kernelization, Partially Polynomial Kernels | 530 | not a bounded benchmark | Kernel-size theory across problem classes. |
| Kernelization, Permutation CSPs Parameterized above Average | 525 | not a bounded benchmark | Problem-specific parameterized reductions. |
| Kernelization, Planar F-Deletion | 527 | not a bounded benchmark | Planar kernelization theory. |
| Kernelization, Polynomial Lower Bounds | 522 | not a bounded benchmark | Lower-bound theory. |
| Kernelization, Preprocessing for Treewidth | 529 | not a bounded benchmark | Multiple treewidth preprocessing rules and parameter contracts. |
| Kernelization, Turing Kernels | 528 | not a bounded benchmark | Parameterized-complexity framework. |
| Kinetic Data Structures | 191 | not a bounded benchmark | Event-driven geometric data-structure family. |
| Knapsack | 192 | partial | Existing exact 0/1, bounded, unbounded, and stochastic profiles cover other variants. [Profit-scaling FPTAS](k/knapsack_profit_scaling_fptas/README.md) implements the chapter's base Ibarra–Kim DP-Profits scheme at fixed ε=1/2. [Small/large profit-scaling FPTAS](k/knapsack_profit_scaling_small_large_fptas/README.md) implements its distinct enhancement: partition at εU_LP/2, run scaled-profit DP over large items, and greedily fill each residual capacity with ratio-ordered small items. Both profiles use bounded inputs and deterministic tie refinements; Lawler and later schemes remain unrepresented. |
| Knowledge in Distributed Systems | 606 | not a bounded benchmark | Distributed-systems theory. |
| Large-Treewidth Graph Decompositions | 691 | not ported | The output is a partition into `h` disjoint subgraphs, each with treewidth at least `r`, for a graph of treewidth `k`; the entry studies guarantees and running times across these parameter regimes rather than one fixed decomposition rule or certificate format. |
| Layout Decomposition for Multiple Patterning | 745 | not a bounded benchmark | VLSI layout optimization with manufacturing constraints. |
| Layout Decomposition for Triple Patterning | 744 | not a bounded benchmark | VLSI layout optimization with manufacturing constraints. |
| Learning Automata | 194 | not a bounded benchmark | Learning dynamics depend on stochastic feedback and chosen automaton variant. |
| Learning Constant-Depth Circuits | 195 | not a bounded benchmark | Learning-theory model and oracle assumptions. |
| Learning DNF Formulas | 196 | not a bounded benchmark | Learning model and query/sample assumptions. |
| Learning Heavy Fourier Coefficients of Boolean Functions | 197 | not a bounded benchmark | Fourier-learning algorithms require a chosen access/oracle model. |
| Learning Significant Fourier Coefficients over Finite Abelian Groups | 199 | not a bounded benchmark | Group-specific learning/query model. |
| Learning with Malicious Noise | 198 | not a bounded benchmark | Statistical learning model with adversarial noise assumptions. |
| Learning with the Aid of an Oracle | 193 | not a bounded benchmark | Oracle model rather than a single executable algorithm. |
| LEDA: a Library of Efficient Algorithms | 200 | not a bounded benchmark | Library overview, not one algorithm. |
| Lempel-Ziv Compression | 634 | partial | [Lempel-Ziv compression](l/lempel_ziv/README.md), [LZ78](l/lz78/README.md), and LZ77 source profiles cover selected dictionary coders. [Rightmost infinite-window LZ77](l/lz77_infinite_rightmost/README.md) implements the chapter-defined full-history longest match with largest-prior-position tie rule on bounded printable ASCII; it is a clean-room parser, not a compressed-file format. The cited efficient suffix-array/next- and previous-smaller-value parser implementations, non-greedy parsing, and accelerated compressed matching/alignment algorithms are not included. |
| Leontief Economy Equilibrium | 201 | not ported | The entry's output is a real-valued Arrow–Debreu price and market-clearing allocation for a chosen endowment/utility market; no fixed market encoding, numerical tolerance, or exact-arithmetic contract is common to its variants. |
| LexBFS, Structure, and Algorithms | 687 | package | [LexBFS](l/lex_bfs/README.md). |
| Linearity Testing/Testing Hadamard Codes | 202 | not a bounded benchmark | Randomized property-testing query model and soundness parameters. |
| Linearizability | 203 | not a bounded benchmark | Concurrent history semantics and memory-model assumptions. |
| List Decoding near Capacity: Folded RS Codes | 204 | not a bounded benchmark | Coding-theory construction and decoding model. |
| List Ranking | 592 | partial | [Deterministic independent-set contraction](l/list_ranking_independent_set_contraction/README.md) implements the chapter's serial 3-color/popular-class variant of successor bridging, weight aggregation, recursive ranking, and rank restoration. LLUBenchmark traversal only covers the separate internal-memory baseline. |
| List Scheduling | 205 | package | [Graham list scheduling](l/list_scheduling/README.md). |
| Local Alignment (with Affine Gap Weights) | 207 | existing | [Affine local alignment](p/ptrdist_sim_local_affine_alignment/README.md). |
| Local Alignment (with Concave Gap Weights) | 208 | package | [Global concave-gap alignment recurrence](l/concave_gap_alignment_global/README.md). The chapter's problem definition is global alignment despite its title; bounded profile states this directly. |
| Local Approximation of Covering and Packing Problems | 209 | not a bounded benchmark | Local approximation framework with problem-dependent operations. |
| Local Computation in Unstructured Radio Networks | 210 | not a bounded benchmark | Distributed randomized network model. |
| Local Reconstruction | 698 | not a bounded benchmark | Property-testing/reconstruction query model. |
| Local Search for K-medians and Facility Location | 212 | partial | [`k_median_p1_local_search`](k/k_median_p1_local_search/README.md) covers the fixed-k one-swap k-median profile. [`facility_location_add_delete_swap`](f/facility_location_add_delete_swap/README.md) separately implements uncapacitated facility-location opening costs with the Kuehn–Hamburger add/delete/swap neighborhood, deterministic best improvement, and fixed epsilon=0.1 stopping on a bounded supplied metric. The randomized add-one/delete-many heuristic and capacitated variants remain uncovered; Rodinia `streamcluster_pgain` is only its own opening-move helper. |
| Locality in Distributed Graph Algorithms | 608 | not a bounded benchmark | Distributed locality framework. |
| Locally Decodable Codes | 708 | not a bounded benchmark | Coding-theory objects and oracle access model. |
| Locally Testable Codes | 707 | not a bounded benchmark | Coding-theory constructions and query model. |
| Low Stretch Spanning Trees | 215 | not ported | The source entry primarily analyzes worst-case average stretch and a probability distribution over spanning trees; it does not specify one deterministic tree-construction output to compare across ports. |
| Lower Bounds Based on the Exponential Time Hypothesis: Edge Clique Cover | 777 | not a bounded benchmark | Complexity lower bounds. |
| Lower Bounds for Dynamic Connectivity | 214 | not a bounded benchmark | Complexity lower bounds. |
| Lower Bounds for Online Bin Packing | 493 | not a bounded benchmark | Competitive-analysis lower bounds. |
| Lowest Common Ancestors in Trees | 630 | existing | LCA and binary-lifting packages cover the query behavior. |
| LP Based Parameterized Algorithms | 778 | not a bounded benchmark | General design framework; algorithms depend on target problem. |
| LP Decoding | 216 | not a bounded benchmark | Coding-theory optimization model. |
| Majority Equilibrium | 217 | not a bounded benchmark | Game-theoretic equilibrium model. |
| Manifold Reconstruction | 714 | not a bounded benchmark | Continuous geometry and sampling assumptions. |
| Market Games and Content Distribution | 218 | not a bounded benchmark | Market/game model varies by application. |
| Matching in Dynamic Graphs | 567 | partial | [Two-level insertion-only maximal matching](t/two_level_dynamic_maximal_matching_insertions/README.md) starts empty and uses the chapter's level-0 insertion/promotion rule with an explicit random-rank tape. It does not claim expected amortized bounds from one realization. Deletions are excluded because the chapter leaves selected-neighbor pre-existing-mate repair unspecified; static Edmonds maximum matching is a separate profile. |
| Matching Market Equilibrium Algorithms | 788 | not a bounded benchmark | Market-specific equilibrium algorithms and assumptions. |
| Matroids in Parameterized Complexity and Exact Algorithms | 783 | not a bounded benchmark | Survey/framework across multiple matroid problems. |
| Max Cut | 219 | partial | [Sahni–Gonzalez deterministic half-approximation](m/max_cut_sahni_gonzalez/README.md) and [Goemans–Williamson hyperplane rounding](m/max_cut_gw_rounding/README.md) cover two distinct source algorithms. The latter takes a feasible vector solution and one hyperplane direction as input; it does not solve the SDP, generate random hyperplanes, or claim the expected 0.87856 guarantee. Later better-than-half methods remain unrepresented. |
| Max Leaf Spanning Tree | 228 | not ported | The entry spans FPT decision/branching, kernelization, local search, and polynomial-time approximation objectives; it does not prescribe one construction algorithm and output contract. |
| Maximizing the Minimum Machine Load | 503 | partial | [Identical-machine LPT max–min profile](m/max_minimum_machine_load_lpt/README.md) covers the explicit decreasing-job-order/least-loaded-machine procedure. The chapter states that Woeginger's PTAS exists and gives its running-time dependence, but provides no construction steps (only a citation); the online randomized and semi-online algorithms are likewise summarized by guarantees rather than operational rules. |
| Maximum Agreement Subtree (of 2 Binary Trees) | 220 | not a bounded benchmark | Phylogenetic tree agreement with source-specific tree semantics. |
| Maximum Agreement Subtree (of 3 or More Trees) | 221 | not a bounded benchmark | Multi-tree phylogenetic optimization. |
| Maximum Agreement Supertree | 222 | not a bounded benchmark | Phylogenetic supertree construction. |
| Maximum Cardinality Stable Matchings | 677 | not ported | The entry covers incomplete lists, ties, approximation algorithms, and multiple upper/lower bounds; these change feasibility and stability, so no single maximum-cardinality stable-matching variant is selected. |
| Maximum Compatible Tree | 223 | not a bounded benchmark | Phylogenetic compatibility model. |
| Maximum Lifetime Coverage | 617 | not a bounded benchmark | Sensor geometry, energy, and coverage model. |
| Maximum Matching | 225 | package | [Deterministic Edmonds general-graph maximum-cardinality matching](g/general_graph_maximum_matching/README.md), simple undirected n<=12; randomized algebraic and weighted/perfect variants remain outside this profile. |
| Maximum-Average Segments | 224 | package | [Bounded exact ratio scan](m/max_average_length_bounded_segment/README.md); distinct from max-sum. |
| Maximum-Sum Segments | 226 | package | [Length-bounded maximum-sum segment](m/max_sum_length_bounded_segment/README.md). |
| Max-Min Allocation | 539 | not a bounded benchmark | Fair-allocation model and valuation assumptions. |
| Mechanism Design and Differential Privacy | 548 | not a bounded benchmark | Mechanism/privacy framework rather than one kernel. |
| Mellor-Crummey and Scott Mutual Exclusion Algorithm | 605 | not a bounded benchmark | Requires concurrent atomic operations and memory-order behavior. |
| Memory-Constrained Algorithms | 586 | not a bounded benchmark | Model/space tradeoff survey, not one operation. |
| Memoryless Gathering of Mobile Robotic Sensors | 595 | not a bounded benchmark | Distributed physical robot model. |
| Meshing Piecewise Smooth Complexes | 718 | not a bounded benchmark | Continuous geometric meshing with complex input structures. |
| Message Adversaries | 609 | not a bounded benchmark | Distributed-system adversary model. |
| Metric TSP | 230 | partial | [`metric_tsp_tree_doubling`](m/metric_tsp_tree_doubling/README.md) and [`metric_tsp_christofides`](m/metric_tsp_christofides/README.md) implement the chapter's two stated approximations: tree doubling (2-approximation) and Christofides (3/2-approximation). Both use bounded integral complete metrics. The bounded Christofides profile computes its odd-set minimum perfect matching by exact subset DP at n<=8; the chapter cites a general O(n^3) matching routine, whose implementation is not included. |
| Metrical Task Systems | 229 | not a bounded benchmark | Online problem family with metric/task input and multiple algorithms. |
| Min-Hash Sketches | 573 | partial | [k-mins](m/min_hash_k_mins/README.md) selects one minimum under each of k independent rank assignments. [Bottom-k](m/min_hash_bottom_k/README.md) uses one supplied rank assignment and retains the k smallest `(rank,item_id)` records without replacement, with the chapter's threshold-replacement insertion rule. [k-partition](m/min_hash_k_partition/README.md) uses one supplied bucket/rank assignment and retains one minimum per bucket; it is distinct from both independent-rank sampling and global bottom-k. All three are explicit supplied-choice profiles: hash/bucket generation, coordinated randomness, and cardinality/similarity estimator guarantees remain outside. |
| Minimal Dominating Set Enumeration | 721 | Partial | [`minimal_dominating_sets_interval`](m/minimal_dominating_sets_interval/README.md) implements the chapter's interval-graph pair-state DAG and counts source-to-sink paths, including singleton dominating intervals. DOI 721's general-graph problem is equivalent to hypergraph dualization and remains open. It says the interval DAG can be adapted to permutation graphs but does not specify its states/arcs from the permutation model; output enumeration (rather than path counting) is also outside this profile. |
| Minimal Perfect Hash Functions | 794 | not a bounded benchmark | Hash-family construction depends on the selected key universe and collision model. |
| Minimum Bisection | 231 | not a bounded benchmark | NP-hard cut optimization; no single source-matched bounded profile selected. |
| Minimum Congestion Redundant Assignments | 232 | not a bounded benchmark | Assignment/robustness model is specialized and multi-constraint. |
| Minimum Connected Sensor Cover | 616 | not a bounded benchmark | Geometric sensor coverage and connectivity constraints. |
| Minimum Energy Broadcasting in Wireless Geometric Networks | 233 | not a bounded benchmark | Geometric wireless energy model. |
| Minimum Energy Cost Broadcasting in Wireless Networks | 234 | not a bounded benchmark | Wireless network cost model and topology assumptions. |
| Minimum Flow Time | 235 | partial | [`srpt_flow_time`](m/srpt_flow_time/README.md) includes the chapter's optimal preemptive single-machine SRPT case as `m=1`, generalized to bounded identical machines. |
| Minimum Geometric Spanning Trees | 236 | not a bounded benchmark | Geometric constraints and objective differ from graph MST. |
| Minimum k-Connected Geometric Networks | 237 | not a bounded benchmark | Geometric survivable-network optimization. |
| Minimum Spanning Trees | 239 | existing | Kruskal, Prim, and Borůvka MST packages. |
| Minimum Weight Triangulation | 241 | not a bounded benchmark | Continuous planar triangulation optimization. |
| Minimum Weighted Completion Time | 240 | partial | [Smith-rule single-machine profile](m/smith_weighted_completion_time/README.md) covers the source's exact no-release single-machine special case. For release-date PTASs, DOI 240 sketches geometric rounding, time stretching, job shifting, then DP, but explicitly says the precise steps and analysis are subtle and directs readers to Afrati et al.; it does not provide enough detail for a source-faithful bounded port. Its unrelated-machine, precedence-constrained, and online variants are also only stated by result/citation. |
| Min-Sum Set Cover and Its Generalizations | 806 | partial | [`min_sum_set_cover_greedy`](m/min_sum_set_cover_greedy/README.md) covers unweighted MSSC. [`submodular_ranking_greedy`](m/submodular_ranking_greedy/README.md) implements the chapter's distinct SR normalized-marginal rule on explicit bounded monotone submodular tables (n<=5, values in eighths); DOI 806 states GMSSC embeds as `f_i(A)=min(|S_i∩A|/κ_i,1)`, so only requirement profiles whose exact values fit the table scale are representable there. The LP/randomized-rounding algorithms are described by LP/rounding families and cited results, not the full finite rounding choices; broader GMSSC requirements remain unrepresented. |
| Misra-Gries Summaries | 572 | package | [Misra–Gries summaries](m/misra_gries_summaries/README.md). |
| Mobile Agents and Exploration | 242 | not a bounded benchmark | Distributed agent/environment model. |
| Model Checking with Fly-Automata | 692 | not a bounded benchmark | Specialized symbolic model-checking framework. |
| Modularity Maximization in Complex Networks | 614 | not a bounded benchmark | NP-hard clustering objective with multiple approximation/exact methods. |
| Monotone Minimal Perfect Hash Functions | 639 | Partial: [mmpfh_bucketing](m/mmpfh_bucketing/README.md) implements the chapter's equal-size bucket distributor for sorted fixed-width keys: bucket size three, longest-common-prefix delimiters, explicit d0/d1 mappings, local ordinal, and queries for present keys. [mmpfh_compacted_trie_rank](m/mmpfh_compacted_trie_rank/README.md) adds the separately illustrated compacted-trie distributor primitive: explicit MSB-first Patricia nodes and exact ranks of arbitrary fixed-width queries against delimiter keys, including skipped-prefix exit ordering. The chapter's z-fast relative-ranking option is not packaged because it only names the structure and correction storage, without enough construction/encoding detail to reproduce that data structure. Neither profile implements the succinct per-bucket hash functions or claims their space/time tradeoffs. |
| Monotonicity Testing | 699 | not a bounded benchmark | Randomized property-testing model and query complexity. |
| Multi-armed Bandit Problem | 768 | not a bounded benchmark | Stochastic feedback model and competing policy families; no single contract selected. |
| Multicommodity Flow, Well-linked Terminals and Routing Problems | 244 | not a bounded benchmark | Broad approximation framework over multicommodity instances. |
| Multicut | 245 | not a bounded benchmark | Multiple variants (directed/undirected, edge/vertex) and approximation contracts. |
| Multidimensional Compressed Pattern Matching | 246 | not a bounded benchmark | Specialized compressed-text and multidimensional input representation. |
| Multidimensional String Matching | 247 | partial | [Bounded 2D Bird–Baker row reduction with KMP](t/two_dimensional_string_matching/README.md) implements the chapter's explicit exact-match two-phase algorithm. The higher-dimensional version is stated as repeated row reduction, but no multidimensional package is present. The chapter names Amir–Benson–Farach dueling/periodicity, Hamming/KS/RC approximate matching, and scale/rotation-invariant variants chiefly through results and citations; it does not specify their operational steps, distance/tie details, or continuous-parameter search procedure sufficiently for a faithful bounded port. |
| Multilevel Feedback Queues | 249 | existing | [MLFQ scheduler](m/mlfqscheduler/README.md). |
| Multilinear Monomial Detection | 784 | not a bounded benchmark | Randomized algebraic detection with field and probability parameters. |
| Multiple String Matching | 366 | existing | Aho–Corasick and other multi-pattern matching packages. |
| Multiple Unit Auctions with Budget Constraint | 251 | not a bounded benchmark | Auction/strategic budget model. |
| Multiplex PCR for Gap Closing (Whole-Genome Assembly) | 252 | not a bounded benchmark | Bioinformatics experiment and sequence-specific model. |
| Multitolerance Graphs | 684 | not a bounded benchmark | Specialized graph recognition/model representation. |
| Multiway Cut | 253 | not a bounded benchmark | NP-hard cut optimization with approximation variants. |
| Musite: Tool for Predicting Protein Phosphorylation Sites | 600 | not a bounded benchmark | Application/model-specific prediction pipeline. |

## Suite integration

The shared byte-output runner and verifier register `hub_labeling_pruned`, `hub_labeling_greedy_order`, `srpt_flow_time`, `general_graph_maximum_matching`, `k_median_p1_local_search`, `facility_location_add_delete_swap`, `minimal_dominating_sets_interval`, `metric_tsp_christofides`, `harmonic_k_bin_packing`, `knapsack_profit_scaling_fptas`, the small/large-item `knapsack_profit_scaling_small_large_fptas`, `submodular_ranking_greedy`, `max_cut_gw_rounding`, `geometric_greedy_compass_routing`, the rightmost infinite-window `lz77_infinite_rightmost`, `mmpfh_bucketing`, `mmpfh_compacted_trie_rank`, and the partial insertion-only profile `two_level_dynamic_maximal_matching_insertions`. These are static registration observations, not runtime verification.

DOI 171's partial `two_edge_connected_spanning_subgraph_greedy` profile is registered for the source's fixed-k=2 edge-connectivity deletion heuristic.

DOI 573's partial `min_hash_k_mins`, `min_hash_k_partition`, and `min_hash_bottom_k` profiles are registered for supplied-rank independent minima, supplied bucket/rank minima, and global bottom-k selection with threshold replacement, respectively.

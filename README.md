# Encyclopedia of Benchmarks

A cross-platform collection for comparing algorithm implementations across programming languages. TheAlgorithms repositories are an initial discovery source; the supplied *Encyclopedia of Algorithms* is another. Its chapter-by-chapter coverage and the disposition of distinct candidates are tracked in the [Encyclopedia crosswalk](benchmarks/ENCYCLOPEDIA_COVERAGE.md). When an algorithm has no implementation in one of our target languages, we will write one and record it as a port.

## Goals

- Catalog algorithms and implementations across languages.
- Compare implementations only when they solve the same problem with the same input and output semantics.
- Keep a portable baseline for every benchmark. Default code must not depend on Intel-only instructions or x86-only compiler flags.
- Record enough source, build, machine, and workload details to reproduce a result.
- Preserve attribution and license information for any code taken from an upstream project.

## Layout

The current language folders are `c`, `c3`, `cpp`, `elisa`, `mojo`, `nim`, `odin`, `rust`, `v`, and `zig`. Algorithms are grouped by the first letter of the algorithm name, for example `rust/l/linear_search.rs`; names beginning with a digit go under `0-9/`. Numeric source filenames stay as catalog candidate IDs; a reviewed candidate can use an alphabetic `benchmark_name` for its algorithm folder. Workloads and result files use the same organization, such as `benchmarks/l/linear_search/` and `results/l/linear_search/`.

The new [Rosetta Code and CP-Algorithms profiles](benchmarks/ALGORITHM_EXPANSION_COVERAGE.md#rosettacodedata-popular-title-scores-17-16-reviewed-candidates-2026-11-20) include JSON Pointer evaluation, minimum bounded s–t flow, ECDSA signature verification, and algebraic DFA-to-regex conversion. Their suite registrations and coverage status are recorded in the ledger and [catalog](CATALOG.md).

[PARSEC Ferret multi-probe LSH](benchmarks/m/multiprobe_lsh_probe_sequence/README.md) adds bounded best-first generation of query-directed signed bucket perturbations, with an independent ternary-vector reference and byte-output suite registration.

[Simple-Tiled Wave Function Collapse](benchmarks/w/wave_function_collapse_simple_tiled/README.md) adds weighted tile observation and deterministic FIFO adjacency propagation over caller-supplied domains, with no-backtracking contradiction behavior and scalar-suite registration.

[Multidimensional Newton-Raphson](benchmarks/m/multidimensional_newton_raphson/README.md) adds a bounded coupled two-variable Jacobian update with binary64 arithmetic, ties-away quantization, independent Cramer reference, and byte-output suite registration.

[Brace range expansion](benchmarks/b/brace_range_expansion/README.md) adds a bounded parser and expander for integer or letter ranges embedded in printable patterns, with two references and byte-output suite registration.

[Snake-case to camelCase/PascalCase](benchmarks/s/snake_case_to_camel_pascal_case/README.md) is registered in the byte-output runner and verifier, with bounded references and native ports in all ten language folders.

[BK-tree Levenshtein radius search](benchmarks/b/bk_tree_edit_distance_search/README.md) and [Minkowski question-mark values on rationals](benchmarks/m/minkowski_question_mark_rational/README.md) add distinct metric-search and exact-number-theory workloads, each with two references and ten language ports.

[Inverted-list SvS intersection](benchmarks/i/inverted_list_svs_binary_search/README.md) adds shortest-list-first candidate filtering with monotone binary searches to the byte-output suite; its Encyclopedia chapter record distinguishes it from existing DAAT, threshold, and bitvector intersections.

[Consistent overhead byte stuffing](benchmarks/c/consistent_overhead_byte_stuffing/README.md) adds basic COBS encoding with 254-byte blocks, zero-free output, and the exact-full-block terminal rule across ten languages.

[de Boor B-spline evaluation](benchmarks/b/de_boor_bspline_curve_evaluation/README.md) adds a bounded float64 profile with local de Boor recurrence, an independent Cox–de Boor basis reference, and ten language ports.

[Muthukrishnan document listing](benchmarks/m/muthukrishnan_document_listing/README.md) adds suffix-array interval document reporting with previous-occurrence RMQ, an independent direct-scan reference, and ten language ports.

[Landau–Vishkin k-difference endpoint matching](benchmarks/l/landau_vishkin_k_difference_pattern_matching/README.md) adds the furthest-reaching diagonal/LCE kernel for bounded approximate substring matching, with an independent streaming-DP reference, endpoint-mask output, and ten language ports.

[Time-based one-time password with HMAC-SHA-1](benchmarks/t/time_based_one_time_password_algorithm/README.md) adds a deterministic six-digit TOTP profile with local SHA-1/HMAC kernels, RFC-derived known-answer coverage, and ten language ports.

[Fast minimal triangulation](benchmarks/f/fast_minimal_triangulation/README.md) adds the bounded recursive separator-saturation kernel, with a deterministic singleton pivot, independent graph references, and ten language ports; it does not claim the paper's fast pivot or matrix-multiplication bound.

[Static van Emde Boas layout and search](benchmarks/v/van_emde_boas_layout_search/README.md) adds the recursive top-subtree/bottom-subtree memory permutation and records ordinary binary-search slots, with an independent heap-index reference and ten language ports; it does not measure cache transfers.

[General directed planar s-t flow](benchmarks/p/planar_directed_general_st_flow_borradaile_klein/README.md) adds the bounded Borradaile–Klein dual-potential preprocessing and right-first residual-search profile, with an independent directed-cut oracle and ten language ports.

[Exact posit8 rational encoding](benchmarks/p/posit8_rational_encoder/README.md) adds nearest-codeword encoding with exact integer rounding and a full-code-space rational reference in ten languages.

[Cactus stack branch traces](benchmarks/c/cactus_stack_branch_trace/README.md) adds bounded branch, notch, top, and pop operations with node-arena and copied-vector references across ten languages.
[Smarandache–Wellin prime-prefix scanning](benchmarks/s/smarandache_wellin_prime_prefix_scan/README.md) adds a bounded consecutive-prime concatenation scan with Miller–Rabin and trial-division references across ten languages.
[JuntaTest partition binary-search replay](benchmarks/j/junta_test_partition_binary_search/README.md) records a bounded supplied-partition and sample-tape replay, with mask-based and explicit-coordinate references across ten languages.
[Moore DFA minimization](benchmarks/m/moore_dfa_minimization/README.md) adds synchronous partition refinement with an independent pair-distinguishability reference across ten languages.
[Lexicographic combinations with repetition](benchmarks/c/combinations_with_repetition_lexicographic/README.md) enumerates bounded nondecreasing tuples, with successor and recursive references across ten languages.
[Gregorian day-count to ordinal date](benchmarks/g/gregorian_daycount_to_ordinal_date/README.md) adds a bounded 400-year inverse date mapping with era decomposition and year-start binary-search references across ten languages.
[Shannon–Fano–Elias symbol codes](benchmarks/s/shannon_fano_elias_symbol_codes/README.md) adds exact cumulative-midpoint prefix codes, with integer and rational bit-expansion references across ten languages.
[Bounded Goodstein sequence prefixes](benchmarks/g/goodstein_sequence_bounded_prefix/README.md) cover hereditary-base rebasing and bounded transitions, with numeric and symbolic-expression references across ten languages.
[Greedy order-preserving Huffman traces](benchmarks/o/order_preserving_huffman_greedy_trace/README.md) report ordered merge-tree depths and weighted path cost, with tree and interval-weight references across ten languages.
[GPSR perimeter recovery](benchmarks/g/gpsr_perimeter_recovery_trace/README.md) replays bounded face traversal and strict-crossing recovery on a supplied planar embedding across ten languages.
[Powerful-number square/cube enumeration](benchmarks/p/powerful_numbers_square_cube_enumeration/README.md) emits the sorted powerful-number sequence using its unique squarefree-`b` representation, with an independent factorization scan across ten languages.
[Triangle-mesh faces from an edge graph](benchmarks/f/triangle_mesh_faces_from_edge_graph/README.md) profiles bounded candidate-triangle enumeration, edge-incidence propagation, and a documented fallback heuristic across ten languages.

[Discrete interval encoding tree](benchmarks/d/discrete_interval_encoding_tree/README.md) adds point-set insert, delete, and membership traces over maximal integer intervals in a BST, with a bitmap reference and ten language ports.

[Wulff–Nilsen constant-query distance refinement](benchmarks/w/wulff_nilsen_distance_refinement/README.md) adds the fixed-parameter Figure 4 refinement kernel over a supplied hierarchy and coarse estimate, with Floyd–Warshall and simple-path references and ten language ports.

[Erdős–Selfridge prime classification](benchmarks/e/erdos_selfridge_prime_class/README.md) computes the plus or minus class of a supplied rational prime from the distinct prime factors of `p+1` or `p-1`, with recursive and sieve/SPF references and ten language ports.

[Sibling-distinct tree cost coloring](benchmarks/t/tree_sibling_distinct_cost_coloring/README.md) drafts a bounded subtree and subset-assignment benchmark in all ten language directories, including Mojo. Compilation and execution remain outstanding.

[Weighted unit-job scheduling](benchmarks/u/unit_job_release_deadline_weighted_matching/README.md) drafts an exact release-window scheduler using weighted greedy selection and augmenting paths in all ten languages. Compilation and execution remain outstanding.

The latest static audit of the pinned TheAlgorithms inventory records 2,506 distinct mapped benchmark names, with 2,463 complete across all nine target languages and 43 still incomplete; see [CATALOG.md](CATALOG.md) for the full counts and audit limits. These are file-presence results, not evidence of runtime correctness. ANSIbench additions are tracked in the [ANSIbench coverage crosswalk](benchmarks/ANSIBENCH_COVERAGE.md), Embench-IoT kernels in the [Embench-IoT source crosswalk](benchmarks/EMBENCH_IOT_COVERAGE.md), Rodinia kernels in the [Rodinia source crosswalk](benchmarks/RODINIA_COVERAGE.md), the 17-kernel GitHub shortlist and its deduplication notes are in the [GitHub source crosswalk](benchmarks/GITHUB_BENCHMARKS_COVERAGE.md), Parboil kernels are tracked in the [Parboil source crosswalk](benchmarks/PARBOIL_COVERAGE.md), and the 273-launcher lac-dcc inventory is in the [lac-dcc coverage crosswalk](benchmarks/LAC_DCC_BENCHMARKS_COVERAGE.md). New source discovery and duplicate decisions are recorded in the [additional algorithm coverage ledger](benchmarks/ALGORITHM_EXPANSION_COVERAGE.md). Alias and benchmark-name mappings are documented in [CATALOG.md](CATALOG.md) and [`catalog/algorithm-candidates.json`](catalog/algorithm-candidates.json). See each algorithm guide under [`benchmarks/`](benchmarks/) and the [benchmarking instructions](BENCHMARKING.md).

[External merge sorter](benchmarks/e/external_merge_sorter/README.md) follows the pinned C# bottom-up merge passes over sequential stores, modeled with bounded buffers across all nine target languages.

[Sattolo cycle shuffle](benchmarks/s/sattolo_cycle/README.md) restricts each descending swap to an earlier position, generating a single-cycle permutation with a shared deterministic stream across the nine standard languages and the optional Mojo port.

[Dynamic predecessor problem](benchmarks/p/predecessor_problem/README.md) maintains a bounded set in packed 64-bit words and answers membership, successor, and predecessor queries alongside idempotent updates.

[Packed bitset XOR-shift trace](benchmarks/b/bitset_xor_shift_trace/README.md) applies repeated signed shifts in place across a bounded packed vector and reports each population count; zero shift clears the vector, and cross-word shifts have dedicated fixtures.

[Belady optimal paging](benchmarks/b/belady_optimal_paging/README.md) replays a bounded page-reference sequence and evicts the resident page whose next use is farthest in the known future, with deterministic ID ties.

[Minimum refueling stops with a max-heap](benchmarks/m/minimum_refueling_stops_heap/README.md) delays station choices until more reach is needed, then selects the largest fuel amount among reachable stations.

[Fenwick binary-lifting selection](benchmarks/f/fenwick_kth/README.md) supports point frequency updates and selects the zero-based index containing a one-based occurrence rank.

[FKS static perfect hashing](benchmarks/f/fks_static_perfect_hash/README.md) builds a deterministic two-level collision-free table for a small static set and answers membership queries with an exact bit mask.

[Segment-tree max_right boundary search](benchmarks/s/segment_tree_max_right/README.md) combines point assignments with an O(log n) search for the largest prefix endpoint accepted by a monotone sum predicate.

[Lazy range-add segment tree with max_right](benchmarks/l/lazy_segment_tree_range_add_max_right/README.md) combines deferred range additions with a sum-threshold boundary search that pushes tags while descending.

[Weighted two-vertex cuts by SPQR decomposition](benchmarks/t/two_vertex_cuts_spqr/README.md) builds bounded split components, reduces S/P skeletons, and aggregates component counts for separating vertex pairs.

[Incremental three-dimensional convex hull](benchmarks/i/incremental_convex_hull_3d/README.md) updates outward triangular faces over an exact integer point set and returns six times the hull volume.

[Ternary search trie](benchmarks/t/ternary_search_trie/README.md) uses left/right character comparisons and middle links for symbol-table, prefix, and wildcard queries, distinct from the existing 26-way trie.

[Greedy minimum interval cover](benchmarks/i/interval_cover/README.md) repeatedly extends the covered frontier with the supplied interval that reaches furthest, or reports an uncovered gap.

[Dynamic interval container](benchmarks/i/interval_container/README.md) maintains the union of half-open intervals as add and remove operations merge, split, and rejoin covered ranges.

[64-ary bitmap predecessor set](benchmarks/w/w_ary_predecessor_set/README.md) maintains an ordered set over a fixed universe with summary-word successor and predecessor jumps.

[Range union-find](benchmarks/r/range_union_find/README.md) merges all adjacent vertices covered by an interval while skipping components already joined at its right boundary.

[Arbitrary-order line container](benchmarks/a/arbitrary_order_line_container/README.md) maintains a min or max envelope with integer intersection breakpoints while lines and query coordinates arrive in any order.

[Offline sweep-line point location](benchmarks/p/point_location_sweep/README.md) answers a batch of vertical-ray queries by maintaining the height order of planar edges as the sweep crosses endpoint events.

[Stochastic visibility walk in a triangulation](benchmarks/p/triangulation_stochastic_visibility_walk/README.md) replays face-adjacency point location from a supplied initial face, using exact separating-edge predicates and a deterministic choice tape at ambiguous branches.

[Weighted set-cover domination reductions](benchmarks/s/set_cover_domination_reduction/README.md) applies row, simple-column, and advanced-column presolve rules while preserving minimum cover cost.

[Ruf–Schöbel set-cover branch-and-bound](benchmarks/r/ruf_schobel_set_cover/README.md) branches on one consecutive block for each multi-block row and solves interval relaxations exactly for bounded weighted instances.

[Strong-C1P weighted set cover by shortest path](benchmarks/s/strong_c1p_set_cover_shortest_path/README.md) applies Schöbel's strict-monotone row reduction and column-interval DAG to solve bounded weighted instances whose rows are already intervals in the supplied column order.

[Union-find component enumeration](benchmarks/u/union_find_enumerate/README.md) splices circular member lists on successful unions so any component can be enumerated without scanning the whole universe.

[SPLASH-2-inspired bounded volume ray marching](benchmarks/s/splash2_volrend_raymarch/README.md) builds an opacity-support pyramid, samples voxel fields with fixed-point trilinear interpolation, composites front-to-back, and stops at full opacity.

[Counting Eulerian circuits](benchmarks/g/counting_eulerian_circuits/README.md) applies the BEST theorem with a directed Matrix–Tree determinant to count edge-labeled circuits modulo 998244353.

[Morris approximate counter](benchmarks/m/morris_approximate_counter/README.md) replays a supplied discrete uniform draw tape through the base-2 probabilistic counter and returns its compressed state and decoded estimate.

[Bitwise AND convolution](benchmarks/b/bitwise_and_convolution/README.md) uses superset zeta and Möbius transforms to compute the modular convolution over index bitwise AND.

[Modular polynomial convolution](benchmarks/c/convolution_mod/README.md) multiplies coefficient sequences modulo 998244353 with radix-2 number theoretic transforms.

[Palindromes in Deque](benchmarks/p/palindromes_in_deque/README.md) exercises two-ended insertions and deletions, reporting distinct-palindrome, longest-prefix, and longest-suffix summaries after each operation with bounded snapshot Eertree rebuilds.

[Modular polynomial convolution modulo 1,000,000,007](benchmarks/c/convolution_mod_1000000007/README.md) uses three auxiliary-prime NTTs and CRT reconstruction for the target modulus.

[Convolution modulo 2^64](benchmarks/c/convolution_mod_2_64/README.md) uses five auxiliary-prime NTTs and mixed-radix CRT to reconstruct each coefficient before unsigned word wraparound.

[GCD convolution](benchmarks/g/gcd_convolution/README.md) uses divisor-zeta and Möbius transforms to compute pair-indexed modular convolution grouped by the exact gcd.

[LCM convolution](benchmarks/l/lcm_convolution/README.md) uses multiple-zeta and Möbius transforms to compute pair-indexed modular convolution grouped by the exact least common multiple.

[Weighted modular union-find](benchmarks/u/unionfind_with_potential/README.md) maintains accepted additive difference constraints and answers relative-potential queries.

[Noncommutative potential union-find](benchmarks/u/unionfind_with_potential_non_commutative_group/README.md) maintains order-sensitive `SL(2, F_998244353)` potentials and returns relative matrices.

[Online bridge finding](benchmarks/o/online_bridge_finding/README.md) maintains the bridge count as undirected edges are inserted, using connected-component and 2-edge-connected-component structures.

[Range-parallel union-find](benchmarks/u/range_parallel_unionfind/README.md) merges aligned edge ranges through a hierarchy of disjoint sets and reports weighted component-pair sums.

[Meissel–Lehmer prime counting](benchmarks/m/meissel_lehmer_prime_count/README.md) uses Lehmer's formula to count primes through a bounded upper limit, with an independent segmented-sieve oracle.

[Per-edge C4 counting](benchmarks/c/counting_c4/README.md) counts edge-ID triples completing each edge to a four-cycle in a bounded undirected multigraph.

[Degree-ordered four-cycle counting](benchmarks/c/undirected_four_cycle_count_degree_order/README.md) returns the number of distinct simple-graph four-cycle edge sets using degree-rank orientation and two-path counts. It is distinct from the per-edge multigraph profile; ten ports and scalar-suite registration are included.

[Persistent union-find](benchmarks/p/persistent_unionfind/README.md) answers connectivity queries across branching graph versions with rollback DSU traversal.

[Strong orientation](benchmarks/s/strong_orientation/README.md) directs every edge to minimize the number of strongly connected components and emits the orientation certificate.

[Set XOR-min](benchmarks/s/set_xor_min/README.md) uses a counted binary trie to maintain a 30-bit integer set and answer minimum-XOR queries.

[Complement-graph components](benchmarks/c/connected_components_of_complement_graph/README.md) finds components in the implicit complement using neighbor marking and an unvisited-vertex traversal.

[Bipartite edge coloring](benchmarks/b/bipartite_edge_coloring/README.md) decomposes a multigraph into the minimum number of matchings by regularization and repeated perfect matchings.

[Minimum-cost b-flow](benchmarks/m/minimum_cost_b_flow/README.md) handles signed vertex balances, lower and upper bounds, negative costs, and a primal/dual optimality certificate.

[Minimum-cost circulation by cost scaling](benchmarks/m/minimum_cost_circulation_cost_scaling/README.md) repeatedly refines an epsilon-optimal pseudoflow with negative reduced-cost pushes and price relabels; ten language ports passed static review.

[Berlekamp–Welch Reed–Solomon decoding](benchmarks/b/berlekamp_welch_rs_decode/README.md) recovers a low-degree polynomial from noisy finite-field evaluations through a homogeneous interpolation system; its contract, two oracles, workload, scalar-suite wiring, and all ten statically reviewed language ports are present.

[Gao Reed–Solomon decoding](benchmarks/g/gao_rs_decode/README.md) interpolates received values, applies partial extended Euclid, and divides to recover the message polynomial, adding a distinct polynomial-arithmetic decoder alongside Berlekamp–Welch; ten ports passed static review.

[Kruskal reconstruction tree bottleneck queries](benchmarks/k/kruskal_reconstruction_tree_bottleneck/README.md) builds a merge forest during Kruskal and answers minimax path queries by LCA.

[Johnson elementary circuit enumeration](benchmarks/j/johnson_elementary_circuit_enumeration/README.md) uses SCC restriction and blocked/dependency sets to enumerate every directed elementary circuit once.

[Average Rate (AVR) speed scaling](benchmarks/a/avr_speed_scaling/README.md) sums each active job's average-rate contribution and schedules the resulting speed profile by EDF.

[Top Trading Cycles housing exchange](benchmarks/h/housing_top_trading_cycles/README.md) repeatedly trades favorite remaining houses through ownership cycles in a strict-preference housing market.

[Optimal Available speed scaling](benchmarks/o/oa_speed_scaling/README.md) replans a YDS schedule for remaining work at each arrival, then follows critical intervals by EDF until the next release.

[Subset Sum bin-packing heuristic](benchmarks/s/subset_sum_bin_packing/README.md) repeatedly packs a maximum-total feasible subset using suffix subset-sum reachability.

[Weighted tree diameter](benchmarks/t/tree_diameter/README.md) returns a maximum-weight path from an arbitrary positively weighted tree with deterministic endpoint ties.

[Biconnected components](benchmarks/b/biconnected_components/README.md) uses DFS low links and an edge stack to return vertex blocks, including singleton blocks and multigraph support.

[Cactus graph recognition](benchmarks/c/cactus_graph_recognition/README.md) assigns each DFS cycle exclusive edge ownership, classifies edge and vertex cacti, and counts cycles. Ten language ports, dual references, fixtures, and `i64_array_scalar` suite registration are included.

[Entringer number](benchmarks/e/entringer_number/README.md) computes one cell of the down-up alternating-permutation triangle by a row recurrence. A subset-state reference and tiny direct enumerator provide independent checks; ten language ports and scalar-suite registration are included.

[Batched small-k Josephus](benchmarks/j/josephus_batched_small_k/README.md) removes complete sweeps at once for bounded small steps, then unwinds the recurrence to recover the zero-based survivor. It is distinct from the local one-size recurrence and list simulation; ten language ports, independent references, and scalar-suite registration are included.

[Buddy system allocator](benchmarks/b/buddy_system_allocator/README.md) rounds requests to power-of-two blocks, splits larger free blocks, and recursively coalesces equal-sized buddies on release. The bounded allocation trace has ten language ports, free-list and dyadic-interval references, and byte-output suite registration.

[Blelloch parallel prefix scan](benchmarks/b/blelloch_parallel_prefix_scan/README.md) computes exclusive prefixes with a padded, level-synchronous upsweep and downsweep tree. Ten language ports, a serial reference, bounded fixtures, and byte-output suite registration are included.

[Hashbelt aging hash table](benchmarks/h/hashbelt_aging_hash_table/README.md) rotates fixed hash-table generations, expires the oldest generation, and promotes older lookup hits to the newest generation. Ten language ports, independent bucket-chain and map references, bounded fixtures, and byte-output suite registration are included.

[Multiply-shift universal hash trace](benchmarks/m/multiply_shift_universal_hash_trace/README.md) applies caller-supplied odd 32-bit multipliers and extracts the high bits of each modular product. Ten language ports, independent widened-product and add-and-double references, bounded fixtures, and byte-output suite registration are included.

[Brzozowski DFA minimization](benchmarks/b/brzozowski_dfa_minimization/README.md) reverses and determinizes a small binary automaton twice to obtain the accessible minimal DFA. Ten language ports, an independent table-filling reference, bounded fixtures, and scalar-suite registration are included.

[BLR linearity test](benchmarks/b/blr_linearity_test/README.md) replays the three-query test over a supplied Boolean truth table and explicit `(x,y)` tape, stopping at the first violation. Ten language ports, an independent violation-trace reference, bounded fixtures, and byte-output suite registration are included.

[Hypercube edge monotonicity tester](benchmarks/h/hypercube_edge_monotonicity_tester/README.md) replays supplied vertex-coordinate samples against a Boolean truth table, rejecting at the first downward edge. Ten language ports, an independent full-trace reference, bounded fixtures, and byte-output suite registration are included; the fixed tape makes no randomized soundness claim.

[Felzenszwalb–Huttenlocher 1D squared distance transform](benchmarks/f/felzenszwalb_huttenlocher_1d_squared_distance_transform/README.md) builds the lower envelope of sampled parabolas in linear time and emits both each distance and its lowest-index minimizing site. Ten language ports, an independent all-sites reference, bounded fixtures, and byte-output suite registration are included.

[Levcopoulos–Lingas planar geometric spanner](benchmarks/l/levcopoulos_lingas_planar_geometric_spanner/README.md) prunes a supplied Delaunay triangulation by expanding a doubled Euclidean-MST contour and absorbing exposed faces with a deterministic LIFO stack. Ten language ports, independent references, bounded fixtures, and byte-output suite registration are included.

[Kanj–Perković modified-Yao spanner](benchmarks/k/kanj_perkovic_modified_yao_spanner/README.md) applies fixed-14-cone edge selection, empty-cone gap rules, and mutual endpoint selection to a bounded supplied plane graph. Ten language ports, an independent rotation-scan reference, pinned fixtures, and scalar-suite registration are included; it measures the selection pass, not Delaunay construction or the stretch proof.

[Distinct subarray aggregates](benchmarks/d/distinct_subarray_aggregates/README.md) compresses equal GCD, bitwise OR, or bitwise AND values into contiguous suffix-start ranges. All three operations share one ten-language benchmark and scalar-suite profile, with a direct quadratic reference.

[Burnside bracelet counting](benchmarks/b/burnside_bracelets/README.md) counts dihedral coloring orbits by summing the colorings fixed by each rotation and reflection.

[Berlekamp–Massey](benchmarks/b/berlekamp_massey/README.md) infers a shortest finite-field recurrence from a supplied sequence.

[Cartesian tree construction](benchmarks/c/cartesian_tree/README.md) builds the min-heap, in-order tree with a monotonic stack along its right spine.

[Convex layers](benchmarks/c/convex_layers/README.md) repeatedly peels every point on the convex-hull boundary, including collinear edge points, to compute onion depth.

[Thomas tridiagonal solver](benchmarks/t/thomas_algorithm/README.md) solves diagonally dominant tridiagonal systems with a linear forward sweep and back substitution.

[Euclidean minimum spanning tree](benchmarks/m/euclidean_mst/README.md) generates Delaunay candidates with exact predicates, then selects the tree with Kruskal.

[Sort points by argument](benchmarks/s/sort_points_by_argument/README.md) orders integer vectors by exact half-plane and cross-product comparisons, including the angle seam, zero vector, and collinear ties.

[Count points in triangle](benchmarks/c/count_points_in_triangle/README.md) answers strict-interior point counts for batches of indexed triangle queries using angular Fenwick sweeps and inclusion-exclusion.

[Minimum-diameter spanning tree](benchmarks/m/minimum_diameter_spanning_tree/README.md) enumerates graph-metric centers and builds a shortest-path tree around the best center.

[Strict second-best MST](benchmarks/s/second_best_mst/README.md) finds the least strictly heavier spanning tree and reports its one-edge exchange certificate.

[Frequency table of tree distances](benchmarks/f/frequency_table_of_tree_distance/README.md) uses centroid decomposition to count unordered vertex pairs at every edge distance.

[Tree-path distinct colors with Mo's algorithm](benchmarks/t/tree_path_distinct_mo/README.md) uses a doubled Euler walk and an LCA correction for offline path queries.

[Tree-subtree distinct colors with the sack method](benchmarks/t/tree_subtree_distinct_sack/README.md) retains the largest child state and replays light subtrees to count colors in every subtree.

[Small-to-large subtree color-mode sums](benchmarks/s/small_to_large_subtree_color_mode_sum/README.md) merge each subtree's color-frequency map into its largest child map and sum tied modal labels.

[Tree random-walk edge hitting costs](benchmarks/t/tree_random_walk_edge_hitting_cost/README.md) uses a postorder recurrence and rerooting pass to compute both directed expected traversal costs for every weighted tree edge.

[Triangle-union area by vertical decomposition](benchmarks/t/triangle_union_area_vertical_decomposition/README.md) partitions up to three small integer-coordinate triangles into vertical stripes and integrates their merged intervals exactly.

[External-point tangents to a convex polygon](benchmarks/e/external_point_tangents_convex_polygon/README.md) preprocesses the two x-monotone chains and uses binary searches to find both supporting tangent vertices for each exterior point.

[PQ tree for consecutive ones](benchmarks/p/pq_tree_consecutive_ones/README.md) incrementally reduces the family of column orders satisfying each consecutive-ones row and serializes the full canonical P/Q representation.

[Measured finger-tree sequence](benchmarks/m/measured_finger_tree_sequence/README.md) keeps persistent sequence roots in a measured 2–3 finger tree and supports end operations, concatenation, index splits, and prefix-sum splits.

[Tetrahedral element force kernel](benchmarks/t/tetrahedral_element_force_kernel/README.md) evaluates exact scaled nodal force contributions for small-strain linear-elastic tetrahedra.

[Jump on tree](benchmarks/j/jump_on_tree/README.md) answers kth-vertex-on-path queries using shared binary-lifting preprocessing.

[Long-chain k-th ancestor](benchmarks/l/long_chain_kth_ancestor/README.md) combines a highest-set-bit binary-lifting jump with the OI Wiki long-chain offset table; it is separately benchmarked from ordinary binary lifting.

[Long-chain dominant-depth indices](benchmarks/l/long_chain_dominant_depth_index/README.md) reuses the deepest child’s depth-count state and merges the light subtrees to find each subtree’s most frequent depth.

[BGI radio-network broadcast](benchmarks/r/radio_network_bgi_broadcast/README.md) replays bounded repeated Decay phases from supplied coin tapes, reporting the first informed slot for each processor without generating randomness.

[Vertex-set path composite](benchmarks/v/vertex_set_path_composite/README.md) combines point-updated affine maps along a tree path while preserving traversal direction.

[Dynamic tree vertex add and subtree sum](benchmarks/d/dynamic_tree_vertex_add_subtree_sum/README.md) maintains a link-cut tree with virtual-subtree totals while replacing edges, adding vertex weights, and querying one side of an edge.

[Dynamic tree subtree add and subtree sum](benchmarks/d/dynamic_tree_subtree_add_subtree_sum/README.md) uses a lazy Euler-tour treap to add to one edge-oriented component and query its sum while replacing edges in a tree.

[Euler Tour Tree](benchmarks/e/euler_tour_tree/README.md) maintains a dynamic forest with implicit-treap Euler tours, supporting link, cut, vertex-weight assignment, and component size/weight queries.

[Dynamic top-tree component diameter](benchmarks/d/dynamic_top_tree_component_diameter/README.md) builds a balanced rake/compress hierarchy once for a fixed tree, then updates edge weights through cluster ancestors and answers diameter queries from the root summary.

[Dynamic tree maximum-weight independent set](benchmarks/d/dynamic_tree_maximum_weight_independent_set/README.md) updates vertex weights and reports the tree's optimum after each change using heavy-light decomposition and max-plus matrix products; an independent oracle replays the ordinary tree DP.

[Dynamic tree vertex-set path composite](benchmarks/t/dynamic_tree_vertex_set_path_composite/README.md) maintains forward and reverse affine-composition summaries in a link-cut tree for edge replacement, vertex-map updates, and oriented path queries.

[Garsia–Wachs alphabetic tree](benchmarks/g/garsia_wachs_alphabetic_tree/README.md) computes minimum weighted external path length for ordered leaf weights and returns an ordered depth certificate.

[Schreier–Sims](benchmarks/s/schreier_sims/README.md) builds a fixed-base stabilizer chain for bounded permutation-group order and membership queries, checked against full group closure.

[Hafnian of a matrix](benchmarks/l/hafnian_of_matrix/README.md) computes the weighted sum over perfect pairings with bounded subset dynamic programming modulo 998244353.

[Binary matrix product over GF(2)](benchmarks/m/matrix_product_mod_2/README.md) packs rows of the right operand and XORs the selected rows to multiply over the two-element field.

[Binary matrix determinant over GF(2)](benchmarks/m/matrix_det_mod_2/README.md) uses packed Gaussian elimination with XOR row operations to test full rank over the two-element field.

[Determinant modulo an arbitrary integer](benchmarks/m/matrix_det_arbitrary_mod/README.md) uses Euclidean row transformations that work even when composite-modulus pivots are not invertible.

[Characteristic polynomial over a prime field](benchmarks/m/characteristic_polynomial/README.md) reduces matrices to upper Hessenberg form and applies a leading-principal-submatrix recurrence to return every coefficient.

[Samuelson–Berkowitz characteristic polynomial](benchmarks/b/berkowitz_characteristic_polynomial/README.md) computes `det(xI-A)` by a division-free Toeplitz recurrence over any supplied modulus, including composite moduli.

[Crust opposite-pole selection](benchmarks/c/crust_opposite_pole_selection/README.md) chooses the farthest Voronoi-cell vertex and its farthest strictly opposite pole from supplied cell vertices, with deterministic row-local ties.

[Keys-only IBLT set reconciliation](benchmarks/i/invertible_bloom_lookup_table_reconciliation/README.md) peels a fixed signed difference table to recover keys present in one supplied set but not the other; fixed placements make no probability claim.

[Taxicab minimum representations](benchmarks/t/taxicab_number_minimum_representations/README.md) uses a min-heap merge of monotone positive-cube-sum rows to find Taxicab(2) or Taxicab(3).

[Wieferich prime count](benchmarks/w/wieferich_prime_count_up_to_limit/README.md) sieves odd primes through a bounded inclusive limit, then tests `2^(p-1) ≡ 1 (mod p²)` by binary modular powering.

[Wolstenholme numbers](benchmarks/w/wolstenholme_numbers/README.md) returns the reduced numerator of `H_n^(2)` for `1 <= n <= 22`. Ten language ports use a reduced-fraction recurrence, with an independent common-denominator reference and `i64_array_scalar` suite registration.

[Frobenius number by residue shortest paths](benchmarks/f/frobenius_number_apery/README.md) computes the greatest nonrepresentable amount for a small coprime denomination set using an Apéry residue graph.

[Motzkin number](benchmarks/m/motzkin_number/README.md) returns an exact sequence term using the bottom-up convolution recurrence, with a separate binomial–Catalan reference.

[Riordan number](benchmarks/r/riordan_number/README.md) returns an exact sequence term using the Riordan recurrence, with a separate central-trinomial-difference reference.

[Numbers with prime divisor count other than two](benchmarks/n/numbers_with_prime_divisor_count_not_two/README.md) emits ascending positive integers below an exclusive bound whose divisor count is prime but not two; its independent reference counts divisor pairs per value.

[Cube root of proper-divisor product sequence](benchmarks/c/cube_root_proper_divisor_product/README.md) returns the indexed term of 1 followed by numbers with exactly eight divisors, using prime-signature counting and a separate divisor-count sieve.

[Star quadtree for fat triangulations](benchmarks/s/star_quadtree_fat_triangulation/README.md) builds a bounded Star subdivision using the common-incident-vertex stopping rule and emits Morton-keyed cell/triangle pairs.

[Convex polygon minimum-weight triangulation](benchmarks/c/convex_polygon_minimum_weight_triangulation/README.md) applies additive interval DP to supplied integer weights on internal diagonals, with a Catalan-enumeration reference.

[Deterministic linear-threshold spread](benchmarks/d/deterministic_linear_threshold_spread/README.md) computes synchronous activation rounds for fixed thresholds and a supplied seed set. This is distinct from randomized triggering-parent sampling and greedy seed selection; ten language ports and byte-output suite registration are included.

[Wilson uniform spanning tree](benchmarks/w/wilson_uniform_spanning_tree/README.md) replays rooted loop-erased random walks from a supplied neighbor-choice tape. The deterministic trace makes no probability claim for a fixed tape; ten language ports and byte-output suite registration are included.

[Yellowstone permutation prefix](benchmarks/y/yellowstone_permutation_prefix/README.md) returns a bounded term from the greedy sequence whose next value shares a factor with the term two places back and is coprime to the previous term. Ten language ports, independent Euclid-GCD and factor-set references, and scalar-suite registration are included.

[Ruth–Aaron number predicate](benchmarks/r/ruth_aaron_number_predicate/README.md) checks whether adjacent positive integers have equal prime-factor sums counting multiplicity. Ten language ports use trial division, with an independent least-prime-factor sieve reference and `i64_array_scalar` suite registration.

[Arithmetic derivative](benchmarks/a/arithmetic_derivative/README.md) computes the integer derivation defined by the product rule, using a grouped prime-factor formula and an independent recursive reference. Ten language ports and scalar-suite registration are included.

[Euclid–Mullin sequence](benchmarks/e/euclid_mullin_sequence/README.md) returns the bounded one-based term formed by taking the least prime factor of one plus the product of previous terms; this differs from the primorial-based Euclid-number sequence.

[2-left hashing operation trace](benchmarks/t/two_left_hashing_operation_trace/README.md) measures asymmetric two-choice chain placement, lookup, and deletion with caller-supplied bucket indices; equal chain lengths choose the left table.

[Modular adjugate matrix](benchmarks/a/adjugate_matrix/README.md) computes every signed minor directly, including for singular matrices.

[Marsaglia polar normal transform](benchmarks/m/marsaglia_polar_normal/README.md) produces a deterministic normal pair from a bounded integer tape using rejection inside the unit disk.

[Metropolis MCMC](benchmarks/m/metropolis_mcmc/README.md) replays a fixed-temperature accept/reject chain from symmetric proposals and supplied uniform values.

[Cartesian Box–Muller normal transform](benchmarks/b/box_muller_cartesian_normal/README.md) maps supplied radial and angular draws directly to standard-normal pairs without rejection.

[NAS Parallel Benchmarks EP kernel](benchmarks/n/npb_ep/README.md) combines the specified 46-bit LCG, polar rejection transform, square-annulus histogram, and coordinate-sum reductions.

[NAS Parallel Benchmarks sparse CG profile](benchmarks/n/npb_cg_sparse_inverse_power/README.md) runs CSR conjugate-gradient inner solves inside bounded inverse-power eigenvalue iterations.

[NAS Parallel Benchmarks CG matrix assembly](benchmarks/n/npb_cg_sparse_outer_product_assembly/README.md) forms the weighted sparse-vector outer products, anchored entries, diagonal shift, and coalesced CSC matrix from supplied deterministic vectors.

[HPCG bounded profile](benchmarks/n/hpcg_profile/README.md) couples CSR SpMV, symmetric Gauss–Seidel smoothing, one coarse-grid correction, and preconditioned CG.

[NAS Parallel Benchmarks 3-D FT profile](benchmarks/f/npb_ft_3d_spectral_step/README.md) applies a cubic complex transform, spectral evolution, inverse transform, and per-step checksums.

[NAS Parallel Benchmarks MG profile](benchmarks/n/npb_mg_vcycle/README.md) applies recursive periodic multigrid V-cycle corrections on a bounded 4³ grid.

[NAS Parallel Benchmarks BT block-line profile](benchmarks/n/npb_bt_5x5_block_tridiagonal/README.md) solves a bounded 5×5 block-tridiagonal system with block elimination and back-substitution.

[NAS Parallel Benchmarks SP line-solve profile](benchmarks/n/npb_sp_pentadiagonal_line_solve/README.md) solves a bounded scalar pentadiagonal system with banded elimination and back-substitution.

[NAS Parallel Benchmarks LU block SSOR profile](benchmarks/n/npb_lu_block_ssor/README.md) applies bounded five-component symmetric successive over-relaxation sweeps over a regular seven-block 3-D operator.

[NAS Parallel Benchmarks UA mesh-adaptation profile](benchmarks/n/npb_ua_mesh_adaptation/README.md) refines and safely coarsens a bounded explicit-leaf octree while balancing face and edge neighbors around a moving source.

[NAS Parallel Benchmarks smallest-parent data-cube profile](benchmarks/n/npb_dc_smallest_parent/README.md) builds every grouped view from its least-populated immediate superset and includes the empty aggregate.

[Prime-modulus q-binomial coefficient](benchmarks/q/q_binomial_coefficient_prime_mod/README.md) evaluates bounded Gaussian binomial coefficients by recurrence, with an independent subset-enumeration oracle.

[Small-prime, large-n Stirling numbers of the second kind](benchmarks/s/stirling_number_of_the_second_kind_small_p_large_n/README.md) uses transition-matrix exponentiation for fixed small k and n up to 10^18, with an independent inclusion-exclusion oracle.

[Signed first-kind Stirling numbers for small primes and large n](benchmarks/s/stirling_number_of_the_first_kind_small_p_large_n/README.md) extracts fixed low-degree coefficients using residue-block factorization modulo p.

[Constrained nondecreasing sequence count](benchmarks/n/number_of_increasing_sequences_between_two_sequences/README.md) uses prefix-sum dynamic programming to count integer sequences inside per-position intervals.

[Mian–Chowla sequence](benchmarks/m/mian_chowla_sequence/README.md) constructs the greedy B₂ sequence by rejecting candidate terms whose unordered pair sums collide.

[EKG sequence](benchmarks/e/ekg_sequence/README.md) extends the prefix by choosing the least unused positive integer that shares a factor with the previous term; it can decrease as well as increase.

[Hofstadter Figure–Figure sequences](benchmarks/h/hofstadter_figure_figure_sequences/README.md) generate paired prefixes in which each Figure term is the sum of the previous pair and each Space term is the least unused integer above its predecessor.

[Point-set range sort and affine composition](benchmarks/p/point_set_range_sort_range_composite/README.md) combines point replacement, ascending or descending priority sorts over ranges, and ordered affine evaluation.

[Signed decimal big integer addition](benchmarks/a/addition_of_big_integers/README.md) compares magnitudes, then performs carry addition or borrow subtraction with canonical sign handling.

[Knuth Algorithm D big-integer division](benchmarks/k/knuth_big_integer_division/README.md) divides bounded canonical decimal operands with normalized limbs, corrected quotient estimates, multiply-subtract, and add-back, returning both quotient and remainder.

[Divide-and-conquer optimized partition DP](benchmarks/d/divide_conquer_dp_partition/README.md) minimizes squared group sums using monotone leftmost split positions, with a full quadratic transition scan as its independent reference.

[American flag string sort](benchmarks/a/american_flag_string_sorter/README.md) performs in-place MSD byte-bucket cycles, distinct from the stable buffered MSD string sorter.

[Burstsort](benchmarks/b/burstsort/README.md) sorts variable-length strings through a burst trie whose small leaf buckets expand into prefix nodes at a fixed threshold.

[Ukkonen online suffix tree](benchmarks/u/ukkonen_suffix_tree/README.md) builds the compressed suffix tree one symbol at a time with an active point and suffix links, distinct from suffix insertion and suffix-array/LCP construction.

[Lawler knapsack profit-scaling FPTAS](benchmarks/l/lawler_knapsack_profit_scaling_fptas/README.md) uses a fractional lower bound, dyadic profit scales, equal-q groups, and a small-item completion step, distinct from uniform-scaling FPTAS profiles.

[Reverse Cuthill–McKee ordering](benchmarks/r/reverse_cuthill_mckee/README.md) degree-orders each component's BFS neighbors, reverses the concatenated ordering, and reports graph bandwidth.

[Floyd–Rivest SELECT](benchmarks/f/floyd_rivest_select/README.md) estimates a pivot by recursively selecting the requested rank in a rank-centered sample window, distinct from median-of-three quickselect and groups-of-five median-of-medians.

[Free polyomino enumeration](benchmarks/f/free_polyomino_enumeration/README.md) counts connected square-lattice shapes while identifying translations, rotations, and reflections through D4-canonical growth.

[Abelian sandpile stabilization](benchmarks/a/abelian_sandpile_stabilization/README.md) resolves a bounded open-boundary grid by deterministic legal topplings, returning the unique stable height configuration as a base-four scalar.

[Sum-over-subsets zeta transform](benchmarks/s/sum_over_subsets_zeta_transform/README.md) computes each mask's sum over all its submasks; it is distinct from fast subset convolution, which combines two functions over disjoint submasks.

[Powerful-number summatory sieve](benchmarks/p/powerful_number_summatory_sieve/README.md) evaluates a multiplicative prefix sum by enumerating only powerful numbers in the support of its Möbius convolution.

[Boykov–Kolmogorov max-flow](benchmarks/b/boykov_kolmogorov_maxflow/README.md) reuses source and sink trees across augmentations and repairs them through orphan adoption, complementing the local Dinic, Edmonds–Karp, and push-relabel profiles.

[Length-limited Huffman package-merge](benchmarks/l/length_limited_huffman_package_merge/README.md) finds the minimum weighted code length under a maximum codeword depth, complementing ordinary Huffman and alphabetic coding.

[Elias–Fano monotone-sequence encoding](benchmarks/e/elias_fano_monotone_sequence/README.md) packs a bounded sorted integer sequence into low bits and a unary-positioned high bitvector, then accesses values through select positions.

[Multi-root hollow heap](benchmarks/m/multi_root_hollow_heap/README.md) uses hollow nodes and lazy item relocation for decrease-key, with rank-based consolidation during minimum deletion.

[Type-1 rank-pairing heap](benchmarks/r/rank_pairing_heap/README.md) cuts one half-tree on decrease-key and repairs ranks along ancestors, distinct from the pairing heap's two-pass delete-min and the hollow heap's lazy item relocation.

[Skew binomial queue](benchmarks/s/skew_binomial_queue/README.md) uses singleton-assisted three-tree skew links to make insertion worst-case constant time, distinct from both ordinary binomial heaps and self-adjusting skew heaps.

[DSATUR greedy graph coloring](benchmarks/d/dsatur_greedy_coloring/README.md) dynamically selects vertices by saturation degree, then residual degree and vertex ID, distinguishing it from the fixed-order greedy and exact coloring profiles.

[Wigderson 3-colorable graph coloring](benchmarks/w/wigderson_3_colorable_graph_coloring/README.md) uses the promised 3-colorability to 2-color maximum-degree neighborhoods above a square-root threshold, remove each closed neighborhood, and greedily finish the residual graph. It preserves Algorithm A's two-color stride and is distinct from the local greedy and DSATUR profiles.

[Apostolico–Crochemore string search](benchmarks/a/apostolico_crochemore_search/README.md) reuses comparison state with KMP-next shifts to find every pattern occurrence in linear time.

[Alpha Skip Search](benchmarks/a/alpha_skip_search/README.md) samples text factors and verifies candidate alignments from small-alphabet factor buckets.

[Colussi string search](benchmarks/c/colussi_search/README.md) orders comparisons through KMP-derived hole and nohole tables, with remembered prefix comparisons to limit the worst-case work.

[Interpolation-sequential search](benchmarks/i/interpolation_sequential_search/README.md) makes one estimate from the endpoint values and then scans toward the target, distinct from repeated interpolation and interval narrowing. Ten language ports, a bounded workload, independent references, and scalar-suite registration are present.

[Bond Sequential Search](benchmarks/b/bond_sequential_search/README.md) combines two keys into an OR mask, filters candidate values during a shared scan, and returns each key's first index. Ten language ports, independent references, bounded fixtures, and scalar-suite registration are included.

[Matroid intersection](benchmarks/m/matroid_intersection/README.md) uses an exchange graph to find a maximum-cardinality rainbow forest under per-color quotas. This generic graphic/partition matroid profile is distinct from specialized matching and spanning-tree algorithms. Ten language ports, an exchange-graph reference, an exhaustive subset oracle, bounded fixtures, and scalar-suite registration are included.

[Remove Boxes](benchmarks/r/remove_boxes/README.md) uses compressed-run interval DP with a carry count for same-colored boxes that can merge after intervening runs are cleared. It differs from Burst Balloons' last-item interval recurrence. Ten language ports, an independent legal-removal oracle, bounded fixtures, and scalar-suite registration are included.

[Strange Printer](benchmarks/s/strange_printer/README.md) minimizes overwrite turns with a two-index interval recurrence that merges equal-symbol print turns. Its independent reference searches complete printer-tape states; this is distinct from the carry-state removal score in Remove Boxes. Ten language ports and `i64_array_scalar` suite registration are included.

[Strange Printer II](benchmarks/s/strange_printer_ii/README.md) decides whether a color grid can be made by printing each color's bounding rectangle once. It builds a precedence DAG and checks it with Kahn's topological elimination, distinct from Strange Printer's interval-DP minimum-turn problem. Ten language ports, an independent print-order oracle, and scalar-suite registration are included.

[LCFS hashing](benchmarks/l/lcfs_hashing/README.md) inserts each new key into its home slot and forwards displaced residents through the probe sequence, recording the total resident displacements. Ten language ports and a bounded scalar workload are included.

[Hopscotch hashing](benchmarks/h/hash_map_hopscotch_hashing/README.md) tracks a four-slot home neighborhood with a bitmap and relocates the empty slot backward to preserve bounded lookup. It is distinct from cuckoo displacement, Robin Hood swaps, LCFS resident forwarding, and ordinary linear probing. Ten language ports, independent references, a bounded trace workload, and byte-output suite registration are included.

[Not So Naive string search](benchmarks/n/not_so_naive_search/README.md) chooses between two constant-time shifts from the first two pattern bytes and compares the second byte before the rest of the window.

[Commentz–Walter multiple-pattern matching](benchmarks/c/commentz_walter/README.md) scans alignments against a reversed pattern trie and advances with algorithm B's good-suffix and bad-character shifts.

[Irving stable roommates](benchmarks/s/stable_roommates/README.md) decides whether one even-sized population admits a stable pairing, using proposal reduction followed by rotation elimination.

[SUPER2 super-stable matching](benchmarks/s/super_stable_matching_ties_incomplete/README.md) handles ties and mutually unacceptable partners with proposal and list-reduction rules; it is distinct from weak stability on strict refinements.

[Maximum-cardinality popular matching](benchmarks/m/maximum_cardinality_popular_matching/README.md) uses a strict one-sided preference reduction and maximizes real-post assignments among popular matchings.

[Tied-list maximum-cardinality popular matching](benchmarks/t/ties_maximum_cardinality_popular_matching/README.md) uses the E/O/U reduced graph and augmentation phases to maximize real-post assignments with tied applicant preferences.

[Trie-built generalized suffix automaton](benchmarks/g/generalized_suffix_automaton_union/README.md) counts the union of distinct substrings across several strings, unlike the single-text and pairwise profiles.

[Distinct substring count by collision-checked hashing](benchmarks/d/distinct_substring_count_hashing/README.md) groups each substring length by a polynomial hash and compares bytes inside equal-hash groups, preserving an exact count even on deliberate collisions. It differs from the suffix-automaton and suffix-array counting kernels.

[Schorr–Waite graph marking](benchmarks/s/schorr_waite_graph_marking/README.md) marks root-reachable nodes through pointer reversal and restores the graph edges without an explicit traversal stack.

[Size Balanced Tree ordered set](benchmarks/s/size_balanced_ordered_set/README.md) uses subtree-size inequalities to choose balancing rotations for insertion and order-statistic queries.

[Weight-Balanced Leaf Tree ordered multiset](benchmarks/w/weight_balanced_leaf_tree_order_statistics/README.md) uses leaf weights and alpha-ratio cut/merge repair (`alpha=1/4`), distinct from the Size Balanced Tree's grandchild-size rotations.

[Mo's algorithm with modifications](benchmarks/m/mo_with_modifications/README.md) adds a time dimension so offline range-distinct queries can cross reversible point assignments.

[Lindström–Gessel–Viennot nonintersecting paths](benchmarks/l/lgv_nonintersecting_paths/README.md) counts ordered, vertex-disjoint grid paths through a path-count matrix determinant.

[Weak-heapsort](benchmarks/w/weak_heapsort/README.md) sorts with a max weak heap whose reverse bits control its distinguished-ancestor joins and restoration paths.

[JSort](benchmarks/j/jsort/README.md) uses a min-heap pass, a reversed max-heap pass, and a final insertion sort to order signed 64-bit arrays in place.

[Adaptive Heapsort](benchmarks/a/adaptive_heap_sort/README.md) builds a min Cartesian tree and sorts by repeatedly extracting the smallest root from the frontier of unreported subtrees. Its bounded `sort_call` profile uses a stable index tie-break and is distinct from ordinary heap sort and adaptive merge sort. Ten language ports and a dedicated sort verifier are present.

[UnShuffle sort](benchmarks/u/unshuffle_sort/README.md) distributes values into ordered endpoint piles and combines their heads with a priority queue, taking advantage of existing order in the input. Ten ports and a dedicated scratch `sort_call` profile distinguish it from strand sort and linear-probing sort.

[Hash heap priority-queue trace](benchmarks/h/hash_heap_priority_queue_trace/README.md) distributes keys through an order-preserving bucket map and maintains a binary min-heap per bucket; this queue structure is distinct from the repository's ordinary heap and hash-table traces. Ten native ports and byte-output suite integration are included.

[Polyphase Merge Sort](benchmarks/p/polyphase_merge_sort/README.md) creates short sorted runs, distributes them unevenly over two logical input tapes, then rotates the exhausted input tape into the output role across Fibonacci-shaped merge phases.

[Oscillating Merge Sort](benchmarks/o/oscillating_merge_sort/README.md) recursively combines fixed-size runs in alternating directions over a four-tape profile, reading each child run backward during the merge. It has a dedicated in-place sort verifier.

[External Quicksort](benchmarks/e/external_quicksort/README.md) partitions with a fixed sorted buffer fed from both ends, then recurses on the smaller partition and iterates on the larger one. Ten language ports and a dedicated in-place sort verifier are present.

[FGK adaptive Huffman coding](benchmarks/f/fgk_adaptive_huffman/README.md) and [Vitter Algorithm A](benchmarks/v/vitter_adaptive_huffman/README.md) encode bounded symbol streams with separate sibling-property update rules and byte-output suite profiles.

[Alphabetic Anagrams](benchmarks/a/alphabetic_anagrams/README.md) ranks one word among the distinct permutations of its multiset using multinomial block sizes. Its independent reference enumerates distinct permutations; ten language ports and `i64_array_scalar` suite registration are included.

[Infinite Knight Distance](benchmarks/i/infinite_knight_distance/README.md) computes the exact distance on an unbounded integer grid with the Das–Chatterji constant-time formula, including its parity correction and two local exceptions. Ten language ports, a small-offset BFS reference, and scalar-suite registration are included.

[Fabergé Egg Drop by Moves](benchmarks/e/egg_drop_max_floors_by_moves/README.md) computes the maximum floor count distinguishable for a given egg and move budget with the move-major coverage recurrence. Its independent reference uses partial binomial sums; ten language ports and scalar-suite registration are included.

[General Rectangle Union Area Sweep](benchmarks/g/rectangle_union_area_sweep/README.md) sweeps x-events for up to 64 rectangles and maintains covered y-length in a compressed segment tree. It is distinct from the fixed two-rectangle overlap formula; ten language ports, a unit-cell reference, and scalar-suite registration are included.

[HsaDelta Differential Compression](benchmarks/h/hsadelta_differential_compression/README.md) encodes a byte version against a reference using fixed-block fingerprints, suffix-array match lookup, and insert/copy commands. Its independent reference scans aligned blocks directly; ten language ports and byte-output suite registration are included.

[Lucky Number Sieve](benchmarks/l/lucky_number_sieve/README.md) generates bounded odd-started or even-started survivors by deleting positions in repeated rank-based rounds. Ten language ports, independent list-filter and alive-bitmap references, and byte-output suite registration are included.

[Inverted-list bitvector intersection](benchmarks/i/inverted_list_bitvector_intersection/README.md) intersects arbitrary-arity dense posting bitmaps with word-wise AND and emits ascending document IDs. Ten language ports, independent references, fixtures, and byte-output suite registration are included.

[Three-list t-threshold intersection](benchmarks/t/t_threshold_three_sorted_lists/README.md) reports values present in at least two of three strictly increasing lists using the bounded Barbay–Kenyon color/search procedure. It differs from full three-list intersection. Ten language ports, two references, maximum-output fixtures, and byte-output suite registration are included.

[Greedy Linear Threshold influence maximization](benchmarks/i/influence_maximization_greedy_linear_threshold/README.md) runs greedy seed selection over supplied discrete triggering-world draws, with weighted incoming-edge intervals and deterministic tie breaking. Ten language ports, queue and closure references, bounded fixtures, and byte-output suite registration are included; the finite tape is an empirical objective, not an expected-spread guarantee.

[Maximum matching word segmentation](benchmarks/m/maximum_matching_word_segmentation/README.md) applies left-to-right MaxMatch by selecting the longest dictionary word at each position and advancing one character on a miss. It is a greedy tokenizer, distinct from global `word_break` dynamic programming and delimiter-based splitting. Ten language ports, scan and trie references, bounded fixtures, and byte-output suite registration are included.

[Hajiaghayi–Sorkin random 3-SAT Algorithm A](benchmarks/r/random_3sat_hajiaghayi_sorkin_algorithm_a/README.md) prioritizes pure variables, ranks other unset variables by polarity discrepancy and total degree, then unit-propagates without backtracking. It preserves the paper’s printed `True iff positive_degree < negative_degree` rule and is distinct from the repository’s unit-first Greedy DPLL trace. Ten language ports, mutable-clause and rebuilt-residual references, bounded fixtures, and byte-output suite registration are included.

[Linear Probing Sort](benchmarks/l/linear_probing_sort/README.md) interpolates each byte-valued key to a table slot, probes forward on collisions, then compacts occupied slots in order. Its bounded workload exercises duplicate-key probe chains, including a maximum-key run in the overflow region; it is distinct from bucket sort and flash sort.

[Persistent leftist heap](benchmarks/p/persistent_leftist_heap/README.md) uses path copying during meld and pop, so historical heap versions remain available for branching operations.

[Prefix sum of binomial coefficients](benchmarks/p/prefix_sum_of_binomial_coefficient/README.md) advances across a bounded modular binomial row and accumulates an arbitrary prefix.

[Prime-modulus p-free factorial](benchmarks/p/prime_modulus_p_free_factorial/README.md) computes the factorial unit modulo a small prime for n up to `INT64_MAX` using Wilson blocks; the binomial prime-power profile uses p-free factorials internally but returns a different result.

[Lucas binomial coefficient](benchmarks/b/binomial_coefficient_lucas/README.md) evaluates `C(n,k) mod p` for signed-64-bit `n` and a small prime using base-`p` digits and factorial tables.

[Fundamental Pell solution](benchmarks/p/pell_fundamental_solution/README.md) finds the least positive solution of `x² − D y² = 1` by continued-fraction convergents for nonsquare `D` in `2..31`.

[Penney pattern-game probability](benchmarks/p/penney_game_pattern_probability/README.md) solves the exact first-arrival probability of two distinct equal-length binary patterns in a fair-coin stream by a finite suffix-prefix automaton and modular linear system. Ten language ports and `i64_array_scalar` suite coverage are registered.

[Formal power-series inverse](benchmarks/i/inv_of_formal_power_series/README.md) computes the reciprocal coefficients modulo x^N with a bounded quadratic recurrence and an independent Newton-iteration oracle.

[Polynomial inverse modulo a polynomial](benchmarks/i/inv_of_polynomials/README.md) uses extended Euclid over F_998244353 to find an inverse representative modulo an arbitrary polynomial, or reports when no inverse exists.

[Formal power-series exponential](benchmarks/e/exp_of_formal_power_series/README.md) computes exp(f) modulo x^N from the derivative recurrence g'=f'g, with an independent truncated-power oracle.

[Formal power-series square root](benchmarks/s/sqrt_of_formal_power_series/README.md) uses Tonelli–Shanks and a quadratic coefficient recurrence, with an independent Cipolla/binomial-series oracle and a deterministic root choice.

[Cipolla modular square root](benchmarks/c/cipolla_modular_square_root/README.md) finds a finite-field square root by exponentiating in a quadratic extension; it is a method-distinct companion to Tonelli–Shanks.

[Binomial-divisibility primality test](benchmarks/b/binomial_divisibility_primality_test/README.md) checks the interior Pascal row modulo `n`; the Rosetta task's historical “AKS” label is not used because the method is distinct from the AKS algorithm.

[Erdős–Gallai graphical-sequence test](benchmarks/e/erdos_gallai_graphical_sequence/README.md) checks whether a degree sequence is realizable as a simple graph, using sorted inequalities and a prefix-sum binary search.

[Perfect-shuffle order](benchmarks/p/perfect_shuffle_order/README.md) returns the least number of repeated out-shuffles needed to restore an even deck, with an independent multiplicative-order reference.

[Three-prime Carmichael enumeration](benchmarks/t/three_prime_carmichael_enumerator/README.md) follows a bounded parameter search for Carmichael triples; the independent oracle checks Korselt's criterion.

[Chernick Carmichael least multiplier](benchmarks/c/chernick_carmichael_least_multiplier/README.md) searches a restricted universal-form family and returns the least multiplier without forming the very large product.

[Carmichael lambda function](benchmarks/c/carmichael_lambda_function/README.md) returns the exponent of the unit group modulo `n`, using prime-power decomposition and an LCM. It differs from Euler's totient, which counts the units, and from the Carmichael-number predicate.

[Lucas–Carmichael number predicate](benchmarks/l/lucas_carmichael_number_predicate/README.md) classifies squarefree composites whose every prime divisor `p` satisfies `p + 1 | n + 1`; this differs from the ordinary Carmichael `p - 1 | n - 1` condition.

[Unordered rooted-tree enumeration](benchmarks/r/list_rooted_trees/README.md) emits each rooted unlabeled shape once by combining child shapes as multisets; ordered Dyck-tree generation and supplied-tree isomorphism classification remain separate profiles.

[Formal power-series logarithm](benchmarks/l/log_of_formal_power_series/README.md) computes log(f) modulo x^N from the recurrence f'=f·g', with an independent truncated-power oracle.

[Formal power-series composition](benchmarks/c/composition_of_formal_power_series/README.md) computes f(g(x)) modulo x^N by descending Horner composition, with an independent sum-of-powers oracle.

[Polynomial Taylor shift](benchmarks/p/polynomial_taylor_shift/README.md) computes the coefficients of f(x+c) using descending Horner updates, with an independent binomial-expansion oracle.

[Polynomial division](benchmarks/d/division_of_polynomials/README.md) returns a quotient and remainder over F_998244353 using long division, with an independent reciprocal-and-convolution oracle.

[Compositional inverse of a formal power series](benchmarks/c/compositional_inverse_of_formal_power_series/README.md) finds g such that f(g(x))=x modulo x^N, using a triangular coefficient recurrence and an independent Lagrange-inversion oracle.

[Power of a formal power series](benchmarks/p/pow_of_formal_power_series/README.md) returns the first N coefficients of f(x)^M using truncated repeated squaring and an independent valuation/binomial-series oracle.

[Exponential of a set power series](benchmarks/e/exp_of_set_power_series/README.md) computes exp(f) in the square-zero subset algebra with a cardinality recurrence and an independent set-partition oracle.

[Product of a polynomial sequence](benchmarks/p/product_of_polynomial_sequence/README.md) builds a balanced product tree over a bounded polynomial sequence, with an independent left-to-right multiplication oracle.

[Finite-field polynomial factorization](benchmarks/f/factorization_of_polynomials/README.md) extracts monic irreducibles and multiplicities over small prime fields by exhaustive candidate enumeration, with an independent recursive-splitting oracle.

[Monomial-to-Newton basis conversion](benchmarks/c/conversion_from_monomial_basis_to_newton_basis/README.md) derives Newton coefficients through repeated synthetic division, with an independent basis-matrix elimination oracle.

[Shift of polynomial sampling points](benchmarks/s/shift_of_sampling_points_of_polynomial/README.md) evaluates the polynomial at consecutive shifted points from supplied samples using forward differences, with an independent Lagrange oracle.

[Polynomial interpolation](benchmarks/p/polynomial_interpolation/README.md) reconstructs coefficients from distinct modular points and values using Lagrange bases, with an independent Vandermonde-elimination oracle.

[Power projection of a set power series](benchmarks/p/power_projection_of_set_power_series/README.md) returns weighted projections of successive powers in the square-zero subset algebra, with an independent assignment-enumeration oracle.

[Multipoint polynomial evaluation](benchmarks/m/multipoint_evaluation/README.md) evaluates one polynomial at a batch of supplied points using product and remainder trees, with an independent Horner oracle.

[Chebyshev Clenshaw evaluation](benchmarks/c/chebyshev_clenshaw_evaluation/README.md) evaluates coefficients in the Chebyshev basis with a backward recurrence over a prime field. Ten language ports and scalar-suite registration are present; no programs or checks were run.

[Polynomial root finding over a finite field](benchmarks/p/polynomial_root_finding/README.md) isolates and splits every base-field linear factor using Cantor–Zassenhaus, with an independent direct-evaluation oracle.

[Multipoint evaluation on a geometric sequence](benchmarks/m/multipoint_evaluation_on_geometric_sequence/README.md) uses the Bluestein chirp-z identity and NTT convolution, with repeated Horner evaluation as an independent oracle.

[Polynomial interpolation on a geometric sequence](benchmarks/p/polynomial_interpolation_on_geometric_sequence/README.md) reconstructs coefficients from geometric sample points using q-Newton divided differences, with an independent Vandermonde-elimination oracle.

[Polynomial composition in a set power series](benchmarks/p/polynomial_composite_set_power_series/README.md) evaluates a univariate polynomial in the square-zero subset algebra using Horner composition and subset convolution, with an independent ordered-factor assignment oracle.

[Farach–Colton–Bender lowest common ancestor](benchmarks/l/lowest_common_ancestor_farach_colton_bender/README.md) answers batched tree queries with Euler-tour ±1 RMQ microblocks and a macroblock sparse table; parent climbing and BFS/ancestor-set oracles are kept independent.

[Schieber–Vishkin lowest common ancestor](benchmarks/l/schieber_vishkin_lca/README.md) preprocesses preorder inlabels, ascendant masks, and path-parent jumps for constant-time queries. Its independent binary-lifting reference, ten language ports, and byte-output suite integration are included.

[Fixed-root HLD path-composite sum](benchmarks/p/point_set_tree_path_composite_sum_fixed_root/README.md) maintains affine path aggregates after vertex-value and edge-map updates with heavy-light decomposition and a segment tree; a full postorder recomputation provides the independent oracle.

[Arbitrary-root point-set tree path-composite sum](benchmarks/p/point_set_tree_path_composite_sum/README.md) maintains affine maps and vertex values in a balanced rake/compress top tree, then propagates outside summaries to answer each chosen-root aggregate; direct path reconstruction is the independent oracle.

[De Bruijn sequence generation](benchmarks/d/de_bruijn_sequences/README.md) uses FKM necklace concatenation to emit a bounded k-ary cycle; cyclic-window validation is independent of the generator.

[Knuth's power tree](benchmarks/k/knuth_power_tree/README.md) finds first-discovery exponent paths in one shared addition-chain tree using breadth-first parent expansion; an explicit path-frontier oracle checks the result.
[Unrestricted addition-chain enumeration](benchmarks/a/addition_chain_enumeration/README.md) counts all shortest chains and separates Brauer from non-Brauer chains, with iterative-deepening and breadth-first references.

[Prefix-substring LCS](benchmarks/p/prefix_substring_lcs/README.md) batches prefix/substring longest-common-subsequence queries with semi-local boundary values and Fenwick sweeps; direct per-query LCS is the independent oracle.

[Main–Lorentz tandem repetitions](benchmarks/p/main_lorentz_tandem_repetitions/README.md) enumerates every tandem square using divide-and-conquer Z comparisons, with direct adjacent-block comparison as an independent oracle.

[Suffix balanced tree](benchmarks/s/suffix_balanced_tree/README.md) constructs a suffix array by reverse insertion into a scapegoat-style tree whose comparisons use successor suffix ranks, with direct suffix sorting as an independent oracle.

[Bidirectional FM-index extension](benchmarks/b/bidirectional_fm_index/README.md) maintains synchronized suffix-array intervals as symbols are prepended or appended to an exact pattern. Ten ports, paired-BWT and direct-scan references, and scalar-suite registration are included.

[Old Driver Tree / Chtholly Tree](benchmarks/o/old_driver_tree/README.md) stores a bounded array as maximal constant-value runs for range updates, kth-order queries, and modular power sums. The workload describes its construction-sensitive worst case.

[Segment History Extreme](benchmarks/s/segment_history_extreme/README.md) maintains current and historical range maxima under range assignment and addition, with independent direct-array and prefix-replay oracles.

[Segment Tree Beats](benchmarks/s/segment_tree_beats/README.md) supports range chmin, chmax, addition, and sum queries using second extrema and lazy propagation; a direct-array oracle backs the nine-port scalar suite.

[Point in polygon by ray casting](benchmarks/p/point_in_polygon_ray_casting/README.md) uses exact integer crossings with even–odd fill semantics and explicitly classifies boundary points as inside.

[Kinetic Tournament Tree](benchmarks/p/kinetic_tournament_tree/README.md) tracks changing winners of fixed-slope lines under range translations using certificate deadlines, with direct line evaluation as an independent oracle.

[Minimum string representation](benchmarks/m/minimum_string_representation/README.md) finds the earliest lexicographically least cyclic rotation with linear two-candidate elimination; direct rotation comparison is the independent oracle.

[Infinite geometric-weighted power sum](benchmarks/s/sum_of_exponential_times_polynomial_limit/README.md) evaluates `Σ r^i i^d` modulo 998244353 through an Eulerian-polynomial identity, with an independent Stirling-number oracle.

[Finite geometric-weighted power sum](benchmarks/s/sum_of_exponential_times_polynomial/README.md) evaluates `Σ r^i i^d` for `0 <= i < n` using binary composition of moment blocks, with a rational-tail/Faulhaber oracle.

[Baswana–Sen weighted spanner Algorithm II](benchmarks/s/baswana_sen_weighted_spanner/README.md) replays bounded vertex-clustering rounds from supplied sample masks and joins residual edges to sampled clusters.

[HJM forward-rate path generation](benchmarks/m/hjm_forward_path/README.md) replays PARSEC Swaptions' triangular interest-rate path from explicit factor shocks, with bounded drift and yield-curve inputs.

[SPLASH-2 fast multipole evaluation](benchmarks/f/splash2_fmm/README.md) computes a bounded 2-D logarithmic potential with fixed-order multipole-to-local translations and direct near-field interactions.

[SPLASH-2 six-step FFT](benchmarks/f/splash2_fft_six_step/README.md) applies two dimensions of radix-2 row transforms around twiddle multiplication and three square-matrix transposes.

[SPLASH-2 Ocean red-black relaxation](benchmarks/o/splash2_ocean_rbgs/README.md) runs one screened-Poisson Gauss-Seidel sweep with a complete red phase followed by a black phase.

[SPLASH-2 Radiosity link refinement](benchmarks/f/splash2_radiosity_refine/README.md) recursively refines a bounded patch interaction and gathers the accepted diffuse-link estimates.

[PARSEC Fluidanimate SPH update](benchmarks/f/fluidanimate_sph/README.md) computes one bounded particle density, pressure, and symmetric pressure/viscosity acceleration step.

[PARSEC Bodytrack annealed particle filter](benchmarks/b/bodytrack_annealed_particle_filter/README.md) replays bounded likelihood annealing, weighted resampling, pose perturbation, and a final weighted estimate from supplied tapes.

[HPCC RandomAccess](benchmarks/r/hpcc_random_access/README.md) applies a fixed 64-bit LFSR stream to randomized table XOR read-modify-writes, distinct from the standalone configurable LFSR transition.

[GF(2) linear-system solver](benchmarks/s/system_of_linear_equations_mod_2/README.md) returns a particular solution and a basis for the complete nullspace.

[Intersection of F2 vector spaces](benchmarks/l/intersection_of_f2_vector_spaces/README.md) tracks quotient-space dependencies and returns a canonical basis for the intersection of two XOR-spanned spaces.

[Chordal graph recognition](benchmarks/g/chordal_graph_recognition/README.md) uses maximum cardinality search and returns either a perfect elimination ordering or an induced-hole certificate.

[Cograph cotree decomposition](benchmarks/c/cograph_cotree_decomposition/README.md) recognizes bounded cographs by recursively splitting connected components and complement components, then serializes the canonical union/join cotree. It emits a full recursive certificate, unlike the single complement-component partition benchmark.

[Two-edge-connected components](benchmarks/c/two_edge_connected_components/README.md) removes bridge edges from an undirected multigraph and returns its vertex partition.

[Enumerate quotients](benchmarks/e/enumerate_quotients/README.md) jumps across constant-quotient blocks to list each distinct value of `floor(n/x)` in increasing divisor order.

[Sum of floor of linear](benchmarks/s/sum_of_floor_of_linear/README.md) uses the Euclidean floor-sum recurrence to total `floor((A*i+B)/M)` over a bounded range.

[Minimum of a linear modular prefix](benchmarks/m/min_of_mod_of_linear/README.md) finds the smallest residue `(A*x+B) mod M` for `0 <= x < N` using a Euclidean floor-sum search.

[Stern–Brocot tree queries](benchmarks/s/stern_brocot_tree/README.md) batches compressed path encoding and decoding, lowest common ancestors, fixed-depth ancestors, and descendant intervals.

[Bounded rational neighbors](benchmarks/r/rational_approximation/README.md) uses quotient-jumped Stern–Brocot search to find the nearest feasible lower and upper fractions under numerator and denominator limits.

[Count square-free integers](benchmarks/c/counting_squarefrees/README.md) uses Möbius inversion and a bounded sieve to count square-free values through `N`.

[Modular Bernoulli numbers](benchmarks/b/bernoulli_number/README.md) generates `B_0` through `B_N` modulo 998244353 with a bounded quadratic recurrence.

[Integer k-th root](benchmarks/k/kth_root_integer/README.md) finds the exact floor of `A^(1/K)` for signed 64-bit `A` and degrees 1 through 64.

[Represent a number as a sum of two squares](benchmarks/t/two_square_sum/README.md) enumerates every ordered nonnegative `(a, b)` with `N = a² + b²` for up to eight bounded queries.

[Summatory Euler totient](benchmarks/s/sum_of_totient_function/README.md) uses a sieved prefix and memoized quotient-block recurrence to compute `sum(phi(i), i=1..N) mod 998244353` through `N = 10^9`.

[Large summatory multiplicative function](benchmarks/s/sum_of_multiplicative_function_large/README.md) uses a Min_25 sieve to sum the family `f(p^e)=a*e+b*p` modulo 469762049 through `N = 10^8`.

[Gaussian-integer GCD](benchmarks/g/gcd_of_gaussian_integers/README.md) uses nearest-coordinate Euclidean division in `Z[i]` and canonicalizes each result to a fixed unit associate.

[64-bit Nim product](benchmarks/n/nim_product_64/README.md) multiplies unsigned nimbers using recursive field-extension identities over `GF(2^64)`.

[Discrete logarithm modulo an integer](benchmarks/d/discrete_logarithm_mod/README.md) extends baby-step giant-step with repeated GCD reduction for non-coprime bases and returns the minimum nonnegative exponent.

[Tetration modulo an integer](benchmarks/t/tetration_mod/README.md) evaluates bounded power towers through totient lifting and capped exponent detection, including non-coprime bases and the `0^0 = 1` convention.

[Kth root modulo a prime](benchmarks/k/kth_root_mod/README.md) extracts modular roots for arbitrary exponents by reducing the problem to a discrete logarithm and a linear congruence.

[Primitive root by order factorization](benchmarks/p/primitive_root_factorization/README.md) finds the least generator by factoring `p-1` and checking modular orders, a different kernel from the local primitive-root profile's full residue-cycle search.

The Rust `finance_ratios` module maps to four all-language scalar benchmarks: [return on investment](benchmarks/r/return_on_investment/README.md), [debt to equity](benchmarks/d/debt_to_equity/README.md), [gross profit margin](benchmarks/g/gross_profit_margin/README.md), and [earnings per sale](benchmarks/e/earnings_per_sale/README.md).

[Flatten multilevel linked list](benchmarks/f/flatten_multilevel_linked_list/README.md) ports the Java child-column merge to all nine languages over up to eight sorted chains of eight signed-i64 values; it returns the merged little-endian i64 sequence and its element count.

[Flip augmentation](benchmarks/f/flip_augmentation/README.md) ports the Python horizontal and vertical image transforms and matching normalized box-center reflection to all nine languages.

[Linked list from sequence](benchmarks/f/from_sequence/README.md) preserves the pinned Python constructor's node order and printable linked-list representation.

[Gaussian-Legendre quadrature](benchmarks/g/gaussian_legendre/README.md) ports the Fortran orders 1–5 node and weight tables to all nine languages; it is separate from the Java π iteration.

[Gaussian filter](benchmarks/g/gaussian_filter/README.md) ports the pinned Python valid convolution for its 3×3 and 5×5 demo kernels to all nine languages with fixed-point weights for portable byte results.

[Gabor filter kernel](benchmarks/g/gabor_filter/README.md) ports the pinned Python rotated Gaussian-cosine kernel to all nine languages and emits row-major binary32 coefficients.

[Geo location](benchmarks/g/geo_location/README.md) preserves the pinned C# Haversine radius of 6371.01 km and meter-valued output across all nine languages; it has a separate contract from `haversine_distance`.

[Gravitational force](benchmarks/g/gravitational_force/README.md) ports the pinned Java `Gravitation.java` two-dimensional force-vector formula to all nine languages.
[Greedy minimum vertex cover](benchmarks/g/greedy_min_vertex_cover/README.md) preserves the pinned Python maximum-current-degree heuristic and smallest-ID tie rule across all nine languages.
[Greedy best-first grid search](benchmarks/g/greedy_best_first/README.md) preserves stable Manhattan-priority expansion and ordered path output.
[Greedy graph coloring](benchmarks/g/greedy_graph_coloring/README.md) ports the pinned Go degree-first coloring with a deterministic vertex-ID tie rule.
[Greedy item selection by value](benchmarks/g/greedy_item_selection_by_value/README.md) preserves the pinned Python stable value sort and whole-item capacity scan.
[Greedy unbounded knapsack by value](benchmarks/g/greedy_unbounded_knapsack_by_value/README.md) ports the pinned Julia routine that repeatedly reuses items in stable descending-value order.
[Grow-only set](benchmarks/g/grow_only_set/README.md) models the pinned Java GSet add, lookup, subset, and replica-merge operations.

[Two-phase set](benchmarks/t/two_pset/README.md) models two replicas with additions and permanent removal tombstones, including directional comparison and merge operations.

[Observed-remove set](benchmarks/o/observed_remove_set/README.md) uses unique value tags and tombstones only what a replica observed, preserving concurrent re-adds across merge.

[Token bucket rate limiter with virtual time](benchmarks/t/token_bucket_rate_limiter_virtual_time/README.md) replays refill and admission from explicit integer elapsed ticks, with no wall clock or concurrency.

[Gomory–Hu tree](benchmarks/g/gomory_hu_tree/README.md) ports the pinned Java parent-update construction with bounded Edmonds–Karp flows; its result hashes the represented all-pairs minimum-cut matrix.

[MPM maximum flow](benchmarks/m/mpm_maxflow/README.md) uses BFS level graphs and minimum vertex potentials to compute a directed maximum flow, with bounded ten-language ports and an exhaustive-cut oracle.

[Gradient boosting regressor](benchmarks/g/gradient_boosting_regressor/README.md) ports the custom R squared-error model with bounded one-feature stump trees. The separate Python candidate delegates to scikit-learn and is cataloged as an application demo.

[Gaussian Mixture Model](benchmarks/g/gaussian_mixture_model/README.md) ports the pinned Python EM training and prediction core to all nine languages for a deterministic one-dimensional, two-component contract.

[Fresnel diffraction](benchmarks/f/fresnel_diffract/README.md) uses a bounded four-sample complex field and equivalent direct DFT across all nine languages.

[Frequent pattern growth](benchmarks/f/frequent_pattern_growth/README.md) counts frequent itemsets through weighted conditional-pattern growth in all nine languages.

[Gauss optimization](benchmarks/g/gauss_optimization/README.md) ports the pinned C# coordinate search with a fixed, parameterized objective across all nine languages.

[Longest Consecutive Characters](benchmarks/l/longest_consecutive_characters/README.md) ports the pinned C# longest equal-character run scan to all nine languages and preserves the first-run tie rule.


[Directed simple cycles](benchmarks/d/directed_simple_cycles/README.md) ports the pinned Java DFS enumerator to all nine languages, preserving directed-cycle contents and source traversal order.

[Negative log-likelihood](benchmarks/n/negative_log_likelihood/README.md) ports the pinned Rust binary loss function to all nine languages with ordered averaging and a finite fixed-point probability domain.

The pinned Julia naive-pattern-search source aliases [naive search](benchmarks/n/naive_search/README.md), which uses the same brute-force window scan and returns the full match list.

[Meter to feet conversion](benchmarks/m/meter_to_feet_conversion/README.md) ports both conversions from the pinned JavaScript module to all nine target languages using bounded milliunit inputs.

[Power factor correction](benchmarks/p/power_factor_correction/README.md) ports the pinned Python shunt-capacitor and shunt-inductor formulas to all nine target languages with a bounded power-factor grid.

[Peak signal-to-noise ratio](benchmarks/p/peak_signal_to_noise_ratio/README.md) ports the shared nonzero-MSE PSNR formula across all nine languages, bounding pairwise pixel differences to preserve agreement with Python's uint8 arithmetic.

The pinned MATLAB-Octave `blobDetection.m` and `BlobUsingVideo.m` demos share an HSV-thresholding, morphological-opening, and area-filtered component pipeline with different tuned thresholds. The portable benchmark selects the source threshold profile and passes the displayed object count across all nine languages; see the [guide](benchmarks/b/blob_detection/README.md) and [verifier](benchmarks/verify_blob_detection.py).

[CPU scheduling algorithms](benchmarks/c/cpu_scheduling_algorithms/README.md) covers all six modes from the pinned Python scheduler in nine portable implementations, with process statistics and an oracle verifier.

[BM25 Inverted-Index Ranking](benchmarks/b/bm25_inverted_index/README.md) ports the pinned Java one-term search to all nine languages with a query-specific postings vector and exact rational score ordering. All ports passed 7,779 oracle cases and 16 workload cases; see the [verifier](benchmarks/verify_bm25_inverted_index.py) and [source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/BM25InvertedIndex.java).

[Byte-Pair Encoding Tokenizer](benchmarks/b/bpe_tokenizer/README.md) ports the pinned Python BPE merge loop to all nine languages with first-seen tie-breaking and portable token output. All ports passed 7,020 oracle cases and 19 workload cases; see the [verifier](benchmarks/verify_bpe_tokenizer.py) and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/bpe_tokenizer.py).

[Change brightness](benchmarks/c/change_brightness/README.md) ports the pinned Python per-channel point transform to all nine languages. The shared contract uses integer levels and byte clipping; all ports passed 529 oracle inputs and 12 workload cases.

[Change contrast](benchmarks/c/change_contrast/README.md) ports the pinned Python contrast factor and truncation behavior to all nine languages using exact bounded integer arithmetic. All ports passed 529 oracle inputs and 13 workload cases.

[Circular orbit velocity](benchmarks/c/circular_orbit_velocity/README.md) ports the pinned Java `Gravitation.java` circular-orbit speed formula to all nine languages.

[Conjugate Gradient](benchmarks/c/conjugate_gradient/README.md) ports the pinned Python solver to all nine languages for bounded symmetric positive-definite systems, with an exact rational oracle.

[Convolutional Neural Network Inference](benchmarks/c/convolution_neural_network/README.md) ports the pinned Python prediction path to all nine languages with explicit model parameters and a bounded float-vector oracle.

[Image Convolution](benchmarks/i/image_convolution/README.md) ports the pinned Python edge-padded image-window filter to all nine languages, preserving kernel orientation and restricting the domain to the source's well-defined square-image, odd-kernel cases.

[Matrix Copy](benchmarks/m/matrix_copy/README.md) ports the pinned Go matrix deep-copy result to all nine languages, including the source's empty-dimension behavior.

[Combination Sum](benchmarks/c/combination_sum/README.md) follows the pinned Java and Python depth-first search over ascending positive candidates, including candidate reuse. All nine ports passed 5,621 oracle inputs each and recorded 13 workload cases; see the [verifier](benchmarks/verify_combination_sum.py).

[Constrained shortest path](benchmarks/c/constrained_shortest_path/README.md) follows the pinned Java resource-layer dynamic program with positive resource use per edge. All nine ports passed 270 oracle inputs each and recorded 9 workload cases; see the [verifier](benchmarks/verify_i64_array_scalar.py) and [pinned Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/ConstrainedShortestPath.java).

[Dijkstra's two-stack expression evaluation](benchmarks/d/dijkstras_two_stack_algorithm/README.md) implements the Python expression evaluator across all nine target languages; this is a parenthesized arithmetic algorithm, separate from graph Dijkstra.

[Undirected cycle check](benchmarks/u/undirected_cycle_check/README.md) uses stack-based parent tracking on an adjacency matrix. A separate [breadth-first draft](benchmarks/u/undirected_cycle_check_bfs/README.md) uses a queue; both have ten language drafts.

[Directed Eulerian path](benchmarks/e/eulerian_path/README.md) ports the pinned Rust Hierholzer traversal to ten languages, preserving its start-vertex and adjacency-consumption order while handling parallel edges and self-loops.

[Horizontal projectile motion](benchmarks/h/horizontal_projectile_motion/README.md) ports the pinned Python range, height, and flight-time formulas with fixed gravity and two-decimal ties-to-even rounding.

[Dark sort](benchmarks/d/dark_sort/README.md) ports the pinned Java nonnegative-key histogram sort with a bounded key range. [Floor and ceiling](benchmarks/f/floor_and_ceiling/README.md) returns both nearest values from one strict-BST search path. [Frequency Finder](benchmarks/f/frequency_finder/README.md) preserves the pinned Python English frequency score and ETAOIN reverse tie ordering.

[Solve a quadratic equation](benchmarks/s/solve_quadratic_equation/README.md) preserves the pinned Lua p-q formula, minus-root then plus-root order, and zero/one/two-root return behavior.

[Jarvis scan](benchmarks/j/jarvis_scan/README.md) ports the pinned Rust gift-wrapping hull order with bounded integer cross products.

[String comparison](benchmarks/c/comparison/README.md) ports the pinned AArch64 Assembly case-sensitive and ASCII-insensitive lexicographic routines to portable byte-array contracts. All nine ports passed 285 oracle inputs each and recorded 27 workload cases; see the [verifier](benchmarks/verify_i64_array_scalar.py) and [source](https://github.com/TheAlgorithms/AArch64_Assembly/blob/cb138a856a3af14d3d3dfcd2743d43841eec566f/string/comparison.s).

[Lipogram](benchmarks/l/lipogram/README.md) follows the pinned Rust missing-letter set check on bounded ASCII text and explicit whitespace. All nine ports passed 26 oracle inputs each and recorded 10 workload cases; see the [verifier](benchmarks/verify_i64_array_scalar.py) and [source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a939ec5163648458a8c2b46fd4c/src/string/lipogram.rs).

[Hampel filter](benchmarks/h/hampel_filter/README.md) ports the pinned Java streaming filter with a three-sample causal window and the default threshold 3.0. All nine implementations passed 266 oracle inputs each and recorded 8 workload cases; see the [verifier](benchmarks/verify_i64_array_bytes_output.py) and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/streaming/HampelFilter.java) under MIT.

[Nearest-neighbor interpolation](benchmarks/n/nearest_neighbor_interpolation/README.md) extracts the pinned MATLAB demo's fixed 1.5× resampling loop into a portable grayscale contract. All nine ports passed 273 oracle inputs each and recorded 9 workload cases; see the [verifier](benchmarks/verify_i64_array_bytes_output.py) and pinned [MATLAB source](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/ImageProcessing/Nearest%20Neighbhor%20Interpolation/zoomimg.m) under MIT.

[Partition problem](benchmarks/p/partition_problem/README.md) follows the pinned bottom-up subset-sum decision for equal-sum subsets. All nine ports passed 1,727 subset-mask oracle inputs each and recorded 13 workload cases; see the [verifier](benchmarks/verify_partition_problem.py) and pinned sources under MIT.

[Composite LFSR majority clock](benchmarks/c/composite_lfsr_majority_clock/README.md) isolates the pinned Java A5/1 majority-clock state step over explicit register masks. All nine ports passed 275 independent register-bit oracle inputs each and recorded 14 workload cases; see the [byte-output verifier](benchmarks/verify_i64_array_bytes_output.py) and pinned Java source under MIT.

[Compress Consecutive Runs](benchmarks/c/compress/README.md) follows all three pinned Clojure variants, retaining the first item from each run of equal adjacent values. All nine ports passed 277 oracle inputs each and recorded 18 workload cases.

[Chaos machine](benchmarks/c/chaos_machine/README.md) ports the pinned Python logistic-map and xorshift generator to all nine languages. Its deterministic per-call contract preserves ten-place ties-to-even rounding and passed 329 oracle inputs plus 14 workload cases per port.

[Convert to negative](benchmarks/c/convert_to_negative/README.md) ports the pinned Python OpenCV channel complement to all nine languages. The flattened byte contract passed all 256 channel values and the maximum-size, invalid-input, and capacity cases.

[Braikenridge–Maclaurin Conic Construction](benchmarks/b/braikenridge_maclaurin_construction/README.md) ports the pinned Python five-point determinant method to all nine languages over bounded integer coordinates, returning exact coefficients before display formatting. All ports passed 1,300 oracle cases and 13 workload cases; see the [verifier](benchmarks/verify_braikenridge_maclaurin_construction.py) and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/geometry/braik_mac_construction.py).

[Brainfuck interpreter](benchmarks/b/brainfuck/README.md) ports the pinned Lua bytecode interpreter to all nine languages. The contract defines printable program bytes, byte-cell wrapping, input EOF, and portable tape, step, and output limits. All ports passed the independent 10,146-case oracle and 22 workload cases; see the [verifier](benchmarks/verify_brainfuck.py) and pinned [Lua source](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/esolang/brainfuck.lua).

[Branch-and-bound 0/1 knapsack](benchmarks/b/branch_and_bound_knapsack_solver/README.md) ports the pinned C# breadth-first search to all nine languages. The benchmark corrects the source’s ascending density sort so its fractional bound remains an upper bound. The first five ports passed 3,101 cases each against exhaustive subset checks; see the [verifier](benchmarks/verify_branch_and_bound_knapsack_solver.py) and pinned [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Knapsack/BranchAndBoundKnapsackSolver.cs).

[Brightness](benchmarks/b/brightness/README.md) ports the pinned MATLAB-Octave RGB nearest-neighbor classifier to all nine languages. It preserves the source’s 11 labeled samples and earliest-row tie rule while using squared integer distances. All nine ports passed 3,150 oracle cases each and recorded 35 workload cases; see the [array-scalar verifier](benchmarks/verify_i64_array_scalar.py) and pinned [MATLAB source](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/machine_learning/Nearest-Neighbor/brightness.m).

[Bron–Kerbosch maximal cliques](benchmarks/b/bron_kerbosch/README.md) ports the pinned Java pivoted enumeration to all nine languages. It encodes the complete set of maximal cliques in a bounded undirected graph, independent of source set iteration order. All nine ports passed 1,117 oracle cases each, including every simple graph through five vertices, and recorded 19 workload cases; see the [array-scalar verifier](benchmarks/verify_i64_array_scalar.py) and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/BronKerbosch.java).

[BST from sorted array](benchmarks/b/bst_from_sorted_array/README.md) ports the pinned Java lower-midpoint construction to all nine languages. It encodes the resulting tree shape in an implicit heap-index bitset. Each port passed 317 oracle arrays and recorded all 13 workload cases; see the [array-scalar verifier](benchmarks/verify_i64_array_scalar.py) and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/BSTFromSortedArray.java).

[Butterfly pattern](benchmarks/b/butterfly_pattern/README.md) ports the pinned Python symmetric star layout to all nine languages, returning the same newline-separated ASCII pattern without a trailing newline. Each port passed 4,621 oracle values and all seven workload cases; see the [scalar byte-output verifier](benchmarks/verify_i64_scalar_bytes_output.py) and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphics/butterfly_pattern.py).

[Car pool](benchmarks/c/car_pool/README.md) ports the pinned Dart difference-timeline algorithm to all nine languages and fixes its missed-capacity check on trips starting at stop zero. Each port passed 925 oracle arrays and all 11 workload cases; see the [array-scalar verifier](benchmarks/verify_i64_array_scalar.py) and pinned [Dart source](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/array/car_pool.dart).

[Ceiling in a binary search tree](benchmarks/c/ceil_in_binary_search_tree/README.md) follows the executable branches of the pinned Java implementation, whose prose and example disagree with its code. All nine ports passed 2,673 oracle arrays and 14 workload cases; see the [array-scalar verifier](benchmarks/verify_i64_array_scalar.py) and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/CeilInBinarySearchTree.java).

[Chaining](benchmarks/c/chaining/README.md) ports the pinned C++ separate-chaining table to all nine languages. It preserves bucket-tail insertion scans and records lookup results in a bounded bit mask; each port passed 4,631 oracle arrays and 15 workload cases. See the [guide](benchmarks/c/chaining/README.md) and [verifier](benchmarks/verify_i64_array_scalar.py).

[Centroid Decomposition](benchmarks/c/centroid_decomposition/README.md) builds a deterministic centroid-parent tree for bounded undirected trees. The shared contract normalizes vertex numbering and chooses the lowest vertex ID when a component has multiple centroids; all nine ports passed 408 oracle inputs and 21 workload cases.

[Burkes dithering](benchmarks/b/burkes_dithering/README.md) ports the pinned Python BGR image algorithm to all nine languages. The portable contract uses exact integer grayscale weights and truncates diffusion error toward zero. Each port passed 806 oracle arrays and recorded 17 workload cases; see the [array-scalar verifier](benchmarks/verify_i64_array_scalar.py) and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/dithering/burkes.py).

[N-in-a-row board status](benchmarks/n/n_in_a_row_board_status/README.md) ports the pinned Swift Minimax board check to all nine languages. Each port passed 40,053 board cases, including every 2×2 and 3×3 state for both players, plus 16 workload cases; see the [verifier](benchmarks/verify_n_in_a_row_board_status.py) and pinned [Swift source](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/algorithms/AI/minimax/Sources/Minimax.playground/Sources/Model/Board/Board.swift).

C LeetCode candidate `567` uses the alphabetic benchmark name `permutation_in_string`; JavaScript candidate `permutationin_string` aliases it.

C LeetCode candidate `189` uses the alphabetic benchmark name `rotate_array`.

The Python `rotate_array` source uses the separate `rotate_array_reversal` algorithm benchmark.

C LeetCode candidate `160` uses the alphabetic benchmark name `intersection_of_two_linked_lists`.

The pinned Python `basic_graphs.py` bundles BFS, DFS, Dijkstra, topological sort, Floyd–Warshall, Prim, Kruskal, and isolated-node detection. The first seven map to their shared algorithm contracts; `find_isolated_nodes` has a separate nine-language port. Interactive graph constructors and input parsers are helpers, not benchmark algorithms. See the [isolated-node guide](benchmarks/f/find_isolated_nodes/README.md) and [verifier](benchmarks/verify_find_isolated_nodes.py).

The pinned Python `basic_maths.py` maps prime factors, divisor counting, and Euler totient to existing contracts; its divisor-sum routine omits a leftover prime factor, so `sum_of_divisors` uses the conventional corrected sigma algorithm. See the [sum-of-divisors guide](benchmarks/s/sum_of_divisors/README.md). The Python `basic_string.py` genetic search now has a seeded, bounded, nine-language contract; it corrects the source’s elite-selection mistake by retaining the highest-scoring candidates. See the [string genetic algorithm guide](benchmarks/s/string_genetic_algorithm/README.md) and [verifier](benchmarks/verify_string_genetic_algorithm.py).


Run `python3 catalog/coverage.py` to audit the full pinned candidate inventory against the actual language files, guides, workloads, and documented aliases. [`benchmarks/verify_msd_radix_sort.py`](benchmarks/verify_msd_radix_sort.py) checks all short signed-integer order and duplicate patterns, signed boundaries, deterministic random arrays, and every published workload length in all nine languages. [`benchmarks/verify_quick_sort_3.py`](benchmarks/verify_quick_sort_3.py) checks three-way partitioning on all short order and duplicate patterns, signed boundaries, deterministic random arrays, and every published workload length in all nine languages. [`benchmarks/verify_dual_pivot_quick_sort.py`](benchmarks/verify_dual_pivot_quick_sort.py) checks dual-pivot partitioning on all short order and duplicate patterns, signed boundaries, deterministic random arrays, and every published workload length in all nine languages. [`benchmarks/verify_quick_sort_iterative.py`](benchmarks/verify_quick_sort_iterative.py) checks iterative Lomuto quicksort on exhaustive short-array patterns, signed boundaries, deterministic random arrays, and each published workload length in all nine languages. [`benchmarks/verify_reverse_selection.py`](benchmarks/verify_reverse_selection.py) checks prefix-reversal selection sort on exhaustive short-array patterns, signed boundaries, deterministic random arrays, and each published workload length in all nine languages. [`benchmarks/verify_random_pivot_quick_sort.py`](benchmarks/verify_random_pivot_quick_sort.py) checks reproducible randomized-pivot quicksort on exhaustive short-array patterns, signed boundaries, deterministic random arrays, and each published workload length in all nine languages. [`benchmarks/verify_circle_sort.py`](benchmarks/verify_circle_sort.py) checks recursive mirrored-pair circle sort on exhaustive short patterns, signed boundaries, deterministic random arrays, and each published workload length in all nine languages. [`benchmarks/verify_bogo_sort.py`](benchmarks/verify_bogo_sort.py) checks all relative-order and duplicate patterns through length six, plus signed boundaries and deterministic random arrays, in all nine languages. [`benchmarks/verify_insertion_sort_recursive.py`](benchmarks/verify_insertion_sort_recursive.py) checks recursive insertion sort on exhaustive short-array order patterns, signed boundaries, deterministic random arrays, and each published workload length in all nine languages. [`benchmarks/verify_patience_sort.py`](benchmarks/verify_patience_sort.py) checks patience-sort order patterns, signed boundaries, deterministic random arrays, and each published workload length in all nine languages. [`benchmarks/verify_slow_sort.py`](benchmarks/verify_slow_sort.py) checks bounded recursive SlowSort arrays and workload lengths in all nine languages. [`benchmarks/verify_shell_sort2.py`](benchmarks/verify_shell_sort2.py) checks the fixed-gap Shell sort variant against short-array patterns, boundaries, and workload lengths in all nine languages. [`benchmarks/verify_tree_sort.py`](benchmarks/verify_tree_sort.py) checks binary-search-tree sort, including duplicates, signed boundaries, and workload lengths in all nine languages. [`benchmarks/verify_merge_sort_nr.py`](benchmarks/verify_merge_sort_nr.py) checks bottom-up merge sort on short-array patterns, signed boundaries, and workload lengths in all nine languages. [`benchmarks/verify_bubble_sort_recursive.py`](benchmarks/verify_bubble_sort_recursive.py) checks early-exit recursive bubble sort on short-array patterns, signed boundaries, and workload lengths in all nine languages. [`benchmarks/verify_cocktail_selection_sort.py`](benchmarks/verify_cocktail_selection_sort.py) checks two-ended selection sort on duplicate-heavy arrays, signed boundaries, and workload lengths in all nine languages. [`benchmarks/verify_heap_sort_2.py`](benchmarks/verify_heap_sort_2.py) checks repeated-insertion heap sort on short-array patterns, signed boundaries, and workload lengths in all nine languages. [`benchmarks/verify_merge_sorter.py`](benchmarks/verify_merge_sorter.py) checks stable recursive top-down merge sort, signed boundaries, and workload lengths in all nine languages. [`benchmarks/verify_merge_insertion_sort.py`](benchmarks/verify_merge_insertion_sort.py) checks pair-based merge-insertion sorting on short-array patterns, signed boundaries, and workload lengths in all nine languages. [`benchmarks/verify_bingo_sort.py`](benchmarks/verify_bingo_sort.py) checks Bingo sort on duplicate-heavy arrays, signed boundaries, and workload lengths in all nine languages.  [`benchmarks/verify_scalar.py`](benchmarks/verify_scalar.py) checks twenty-four unary scalar algorithms, including `abundant_number`, LCM sum, Leonardo number, signum, `is_even`, double factorial, power of two, prime check, `perfect_number`, `catalan_number`, `number_of_digits`, `happy_number`, and `automorphic_number`, `palindrome_number`, `power_of_four`, and fast Fibonacci, and iterative/direct-recursive Lucas numbers; [`benchmarks/verify_abs.py`](benchmarks/verify_abs.py) checks signed 64-bit absolute value; [`benchmarks/verify_sum_of_digits.py`](benchmarks/verify_sum_of_digits.py) checks sum of digits; [`benchmarks/verify_perfect_square.py`](benchmarks/verify_perfect_square.py) checks perfect squares; [`benchmarks/verify_binary_scalar.py`](benchmarks/verify_binary_scalar.py) checks Hamming distance, GCD, and LCM; [`benchmarks/verify_binary_to_decimal.py`](benchmarks/verify_binary_to_decimal.py) checks binary digit conversion; [`benchmarks/verify_base16.py`](benchmarks/verify_base16.py) checks uppercase Base16 encoding and decoding; [`benchmarks/verify_base32.py`](benchmarks/verify_base32.py) checks padded and unpadded Base32 byte encoding and decoding; [`benchmarks/verify_base64.py`](benchmarks/verify_base64.py) checks padded and unpadded Base64 byte encoding and decoding; [`benchmarks/verify_floyd_warshall.py`](benchmarks/verify_floyd_warshall.py) checks all-pairs Floyd–Warshall results through the graph ABI; [`benchmarks/verify_binary_base_conversions.py`](benchmarks/verify_binary_base_conversions.py) checks binary-to-octal and binary-to-hexadecimal output; [`benchmarks/verify_octal_base_conversions.py`](benchmarks/verify_octal_base_conversions.py) checks octal-to-binary and octal-to-hexadecimal output; [`benchmarks/verify_hexadecimal_base_conversions.py`](benchmarks/verify_hexadecimal_base_conversions.py) checks hexadecimal-to-binary and hexadecimal-to-octal output; [`benchmarks/verify_i64_scalar_bytes_output.py`](benchmarks/verify_i64_scalar_bytes_output.py) checks decimal-to-binary, octal, hexadecimal, and Roman numeral conversions; [`benchmarks/verify_i64_array_scalar.py`](benchmarks/verify_i64_array_scalar.py) checks LCM of N numbers; [`benchmarks/verify_josephus_problem.py`](benchmarks/verify_josephus_problem.py) checks three Josephus survivor strategies in all nine languages; [`benchmarks/verify_maximum_subarray.py`](benchmarks/verify_maximum_subarray.py) checks Kadane and divide-and-conquer maximum-subarray implementations against exhaustive and generated cases in all nine languages; [`benchmarks/verify_swap_sort.py`](benchmarks/verify_swap_sort.py) checks minimum swaps for distinct signed 64-bit arrays; [`benchmarks/verify_palindrome.py`](benchmarks/verify_palindrome.py) checks exact ASCII palindrome sequences; [`benchmarks/verify_postfix_evaluation.py`](benchmarks/verify_postfix_evaluation.py) checks bounded integer postfix evaluation; [`benchmarks/verify_stack.py`](benchmarks/verify_stack.py) checks bounded LIFO operation traces; [`benchmarks/verify_queue.py`](benchmarks/verify_queue.py) checks bounded FIFO operation traces; [`benchmarks/verify_queue_using_two_stacks.py`](benchmarks/verify_queue_using_two_stacks.py) checks the two-stack queue strategy; [`benchmarks/verify_two_sum.py`](benchmarks/verify_two_sum.py) checks deterministic first-pair Two Sum results; [`benchmarks/verify_octal_to_decimal.py`](benchmarks/verify_octal_to_decimal.py) and [`benchmarks/verify_hexadecimal_to_decimal.py`](benchmarks/verify_hexadecimal_to_decimal.py) check digit-array conversions; [`benchmarks/verify_decimal_to_any_base.py`](benchmarks/verify_decimal_to_any_base.py) checks decimal-to-radix, stack-based conversion, base-to-base conversion, and base -2 encoding; [`benchmarks/verify_any_base_to_decimal.py`](benchmarks/verify_any_base_to_decimal.py) checks general radix decoding; [`benchmarks/verify_negative_binary_base_to_int.py`](benchmarks/verify_negative_binary_base_to_int.py) checks base -2 decoding; [`benchmarks/verify_knapsack_zero_one_tabulation.py`](benchmarks/verify_knapsack_zero_one_tabulation.py) checks 0/1 knapsack tabulation; [`benchmarks/verify_longest_increasing_subsequence.py`](benchmarks/verify_longest_increasing_subsequence.py) checks strict LIS length; [`benchmarks/verify_coin_change.py`](benchmarks/verify_coin_change.py) checks minimum-coin change; [`benchmarks/verify_longest_common_subsequence.py`](benchmarks/verify_longest_common_subsequence.py) checks LCS length; [`benchmarks/verify_rabin_karp.py`](benchmarks/verify_rabin_karp.py) checks Rabin–Karp pattern presence; [`benchmarks/verify_sieve_of_eratosthenes.py`](benchmarks/verify_sieve_of_eratosthenes.py) checks prime counts from the Eratosthenes sieve; [`benchmarks/verify_linear_sieve.py`](benchmarks/verify_linear_sieve.py) checks prime counts from the linear sieve; [`benchmarks/verify_sieve_of_atkin.py`](benchmarks/verify_sieve_of_atkin.py) checks prime counts from the Atkin sieve; [`benchmarks/verify_next_prime_number.py`](benchmarks/verify_next_prime_number.py) checks the smallest prime strictly greater than each input; [`benchmarks/verify_perfect_cube.py`](benchmarks/verify_perfect_cube.py) checks exact signed integer cubes; [`benchmarks/verify_binomial_coefficient.py`](benchmarks/verify_binomial_coefficient.py) checks exact binomial coefficients against `math.comb`; [`benchmarks/verify_find_min_max.py`](benchmarks/verify_find_min_max.py) checks array minimum and maximum; [`benchmarks/verify_levenshtein_distance.py`](benchmarks/verify_levenshtein_distance.py) checks Levenshtein distance; [`benchmarks/verify_float64_triple.py`](benchmarks/verify_float64_triple.py) checks LERP; [`benchmarks/verify_i64_array_bytes_output.py`](benchmarks/verify_i64_array_bytes_output.py) checks phone letter combinations; [`benchmarks/verify_next_greater_nodes.py`](benchmarks/verify_next_greater_nodes.py) checks all nine next-greater-node ports against exhaustive short arrays and a monotonic-stack oracle, including the 4,096-node case and output-capacity failures. [`benchmarks/verify_symmetric_tree.py`](benchmarks/verify_symmetric_tree.py) checks all nine recursive mirror-check ports against exhaustive ordered tree shapes, seeded random trees, and a 511-level comparison. [`benchmarks/verify_tree_level_order.py`](benchmarks/verify_tree_level_order.py) checks level-order traversal; and [`benchmarks/verify_prim.py`](benchmarks/verify_prim.py) checks Prim’s minimum spanning tree against Kruskal; [`benchmarks/verify_modular_exponentiation.py`](benchmarks/verify_modular_exponentiation.py) checks modular powers against Python’s three-argument `pow`; [`benchmarks/verify_binary_exponentiation.py`](benchmarks/verify_binary_exponentiation.py) checks exact nonnegative integer powers and overflow behavior; [`benchmarks/verify_kruskal.py`](benchmarks/verify_kruskal.py) checks Kruskal against an independent Prim oracle; the graph verifiers check Bellman–Ford and Dijkstra in all nine languages. Each verifier accepts the custom Elisa compiler through `--elisa-compiler`. [`benchmarks/verify_doubly_linked_list.py`](benchmarks/verify_doubly_linked_list.py) checks doubly linked list traces, including both traversal directions, across all nine languages. [`benchmarks/verify_linked_list.py`](benchmarks/verify_linked_list.py) checks singly linked list operation traces across all nine languages. [`benchmarks/verify_binary_search_tree.py`](benchmarks/verify_binary_search_tree.py) checks bounded BST operation traces across all nine languages. [trie verifier](benchmarks/verify_trie.py) checks trie insertions, deletions, exact and prefix queries, and malformed variable-width word traces across all nine languages. [fractional-knapsack verifier](benchmarks/verify_fractional_knapsack.py) checks fractional selection and fixed-point results against an exact rational oracle in all nine languages. [segment-tree verifier](benchmarks/verify_segment_tree.py) checks point assignments and inclusive sum, minimum, and maximum queries against a direct-array oracle in all nine languages. [Pascal-triangle verifier](benchmarks/verify_pascal_triangle.py) checks generated coefficients against exact binomial coefficients in all nine languages; [union-find verifier](benchmarks/verify_union_find.py) checks set-union traces, connectivity, component counts, and final partitions in all nine languages; [Fenwick-tree verifier](benchmarks/verify_fenwick_tree.py) checks point additions and inclusive range sums against a direct-array oracle in all nine languages; [ceiling verifier](benchmarks/verify_ceil.py) checks exact rational ceiling results against integer arithmetic in all nine languages; [polygon-area verifier](benchmarks/verify_area_of_polygon.py) checks exact integer-coordinate shoelace results in all nine languages; [shape-area verifier](benchmarks/verify_area.py) checks 22 shape and surface-area formulas in all nine languages; [absolute-extrema verifier](benchmarks/verify_abs_extrema.py) checks first-tie and signed-tie absolute extrema in all nine languages; [recursive knapsack verifier](benchmarks/verify_01knapsack_recursive.py) checks direct recursive 0/1 knapsack in all nine languages; [regular-expression verifier](benchmarks/verify_regex_match.py) checks full-string `.` and `*` matching in all nine languages; [single-number verifier](benchmarks/verify_single_number.py) checks signed 32-bit XOR reduction in all nine languages; [stock-profit verifier](benchmarks/verify_best_time_to_buy_and_sell_stock.py) checks one-transaction profit in all nine languages; [ROT13 verifier](benchmarks/verify_rot13.py) checks both case-preserving and lowercase-only ASCII ROT13 variants in all nine languages; [`benchmarks/verify_caesar_cipher.py`](benchmarks/verify_caesar_cipher.py) checks ASCII Caesar shifts, signed shift boundaries, and output capacity in all nine languages. [`benchmarks/verify_run_length_encoding.py`](benchmarks/verify_run_length_encoding.py) checks count-prefixed run encoding, repeated symbols, multi-digit counts, invalid bytes, and output capacity in all nine languages. [`benchmarks/verify_vigenere_cipher.py`](benchmarks/verify_vigenere_cipher.py) checks repeating-key ASCII encryption, key cycling, case preservation, invalid keys, and output capacity in all nine languages. [`benchmarks/verify_atbash_cipher.py`](benchmarks/verify_atbash_cipher.py) checks every one-byte and two-byte ASCII sequence, seeded longer inputs, invalid values, and output capacity in all nine languages. [`benchmarks/verify_xor_cipher.py`](benchmarks/verify_xor_cipher.py) checks byte-wise XOR with repeating keys, binary payloads, invalid lengths and values, and output capacity in all nine languages. [`benchmarks/verify_a1z26.py`](benchmarks/verify_a1z26.py) checks A1Z26 encoding and decoding, invalid values, and output capacity in all nine languages. [`benchmarks/verify_container_with_most_water.py`](benchmarks/verify_container_with_most_water.py) checks the two-pointer container-area algorithm against exhaustive pair enumeration in all nine languages. [`benchmarks/verify_valid_palindrome.py`](benchmarks/verify_valid_palindrome.py) checks ASCII alphanumeric palindrome behavior against an independent oracle in all nine languages. [`benchmarks/verify_max_consecutive_ones.py`](benchmarks/verify_max_consecutive_ones.py) checks binary-array run lengths against a run-group oracle in all nine languages. [`benchmarks/verify_maximum_unique_subarray.py`](benchmarks/verify_maximum_unique_subarray.py) checks maximum sums over distinct-value windows against a set-based oracle in all nine languages. [`benchmarks/verify_minimum_deletions_to_make_string_balanced.py`](benchmarks/verify_minimum_deletions_to_make_string_balanced.py) checks binary strings against an independent split-point oracle in all nine languages. [`benchmarks/verify_minimum_operations_to_move_all_balls.py`](benchmarks/verify_minimum_operations_to_move_all_balls.py) checks per-box move counts, little-endian output, invalid inputs, and output capacity in all nine languages. [`benchmarks/verify_maximum_ice_cream_bars.py`](benchmarks/verify_maximum_ice_cream_bars.py) checks budget-limited greedy purchases and malformed costs against a sorted-cost oracle in all nine languages. [`benchmarks/verify_maximum_frequency_after_increments.py`](benchmarks/verify_maximum_frequency_after_increments.py) checks the sorted sliding window against an independent target-value oracle in all nine languages. [`benchmarks/verify_gcd_of_n_numbers.py`](benchmarks/verify_gcd_of_n_numbers.py) checks positive signed 32-bit GCD reductions in all nine languages. [`benchmarks/verify_gale_shapley.py`](benchmarks/verify_gale_shapley.py) checks stable proposer-optimal matchings against brute-force enumeration, seeded preference profiles, and output-capacity failures in all nine languages.

Median is now tracked as a shared benchmark: its six pinned TheAlgorithms candidates are reviewed, and all nine target-language ports use the exact doubled-median contract. See [the median guide](benchmarks/m/median/README.md) and [`benchmarks/verify_median.py`](benchmarks/verify_median.py).
The Morse code encoder is reviewed across six pinned TheAlgorithms repositories and implemented in all nine target languages. Its benchmark contract covers the shared ASCII alphanumeric subset and canonical dot/dash encoding. See [the Morse code guide](benchmarks/m/morse_code/README.md) and [`benchmarks/verify_morse_code.py`](benchmarks/verify_morse_code.py).

The extended Euclidean algorithm is reviewed across five pinned TheAlgorithms repositories and implemented in all nine target languages. It returns the GCD and Bézout coefficients under a shared positive-input contract. See [the guide](benchmarks/e/extended_euclidean_algorithm/README.md) and [verifier](benchmarks/verify_extended_euclidean_algorithm.py).


[Search Insert Position](benchmarks/s/search_insert_position/README.md) ports the iterative LeetCode 35 binary search to all nine languages; its verifier exhausts small sorted arrays and checks signed boundaries. See [the verifier](benchmarks/verify_search_insert_position.py).


[Plus One](benchmarks/p/plus_one/README.md) ports decimal carry propagation to all nine languages with an ASCII output buffer; [its verifier](benchmarks/verify_plus_one.py) covers exhaustive short digits, long carries, malformed digits, and capacity failures.


[Valid Parentheses](benchmarks/v/valid_parentheses/README.md) checks bounded ASCII bracket nesting in all nine languages. The ports passed 56,506 oracle arrays each and recorded 14 workload cases. See the [verifier](benchmarks/verify_valid_parentheses.py).


[Find Minimum in Rotated Sorted Array](benchmarks/f/find_min_rotated_sorted_array/README.md) ports the binary-search algorithm to all nine languages. The ports passed 981 oracle arrays each and recorded 13 workload cases. See the [verifier](benchmarks/verify_find_min_rotated_sorted_array.py).


[Boyer–Moore Majority Vote](benchmarks/b/boyer_moore_majority_vote/README.md) is implemented in all nine languages. The ports passed 20,574 oracle arrays each and recorded 14 workload cases. The C LeetCode 169 and Python generalized vote candidates are cataloged as aliases of the C-Sharp candidate. See the [verifier](benchmarks/verify_boyer_moore_majority_vote.py).


[Hamming Weight](benchmarks/h/hamming_weight/README.md) counts set bits in unsigned 32-bit inputs across all nine languages. The ports passed 66,104 oracle cases each and recorded 10 workload cases. C LeetCode 191 is the canonical candidate; C++ `count_of_set_bits` and JavaScript `binary_count_set_bits` share its contract. See the [verifier](benchmarks/verify_scalar.py).

[Count Bits Flip](benchmarks/h/hamming_distance/README.md) is cataloged as an alias of Hamming distance: both count set bits in the XOR of two values. The alias uses the shared nonnegative signed 64-bit input domain.

[Prime Numbers](benchmarks/p/prime_numbers/README.md) returns comma-separated primes through an inclusive limit in all nine languages. The ports passed 175 oracle cases each and recorded 11 workload cases. See the [verifier](benchmarks/verify_prime_numbers.py).


[Contains Duplicate](benchmarks/c/contains_duplicate/README.md) ports the C LeetCode 217 sort-and-scan algorithm to all nine languages using a private copy and portable heapsort. The ports passed 20,168 oracle arrays each and recorded 11 workload cases. See the [verifier](benchmarks/verify_contains_duplicate.py).

[Max Consecutive Answers](benchmarks/m/max_consecutive_answers/README.md) ports the C LeetCode 2024 sliding-window algorithm to all nine languages. It checks both answer values and passed 9,740 oracle arrays per language with 12 workload records. See the [verifier](benchmarks/verify_max_consecutive_answers.py).

C LeetCode candidates 461 and 485 are reviewed aliases of hamming_distance and max_consecutive_ones, respectively.

[Missing Number](benchmarks/m/missing_number/README.md) ports C LeetCode 268 to all nine languages, passing 8,990 oracle arrays each with 13 workload cases. [Missing Number in Consecutive Range](benchmarks/m/missing_number_in_range/README.md) ports the Python and Rust XOR cancellation algorithm to all nine languages, passing 39,619 oracle arrays each with 13 workload cases.

[Single Non-Duplicate](benchmarks/s/single_non_duplicate/README.md) ports C LeetCode 540 pair-alignment binary search to all nine languages. The ports passed 972 oracle arrays each and recorded 13 workload cases. See the [verifier](benchmarks/verify_single_non_duplicate.py).

[First Unique Character](benchmarks/f/first_unique_character/README.md) ports C LeetCode 387 to all nine languages; the JavaScript candidate is reviewed as an alias on lowercase ASCII input. The ports passed 10,356 oracle arrays each and recorded 12 workload cases. See the [verifier](benchmarks/verify_first_unique_character.py).

[Longest Substring Without Repeating Characters](benchmarks/l/longest_substring_without_repeating_characters/README.md) implements the O(n) sliding-window algorithm in all nine languages. The ports passed 22,370 oracle inputs each, including 21,844 exhaustive short strings, randomized and boundary inputs, and 13 workload cases. C LeetCode candidate `3` is cataloged as an alias of this alphabetic benchmark name. See the [verifier](benchmarks/verify_longest_substring_without_repeating_characters.py).

[Three Sum Closest](benchmarks/t/three_sum_closest/README.md) ports C LeetCode 16 to all nine languages. The ports use a private heapsorted copy and a two-pointer scan, passed 16,740 independent nearest-third oracle inputs each, and recorded 13 workload cases. See the [verifier](benchmarks/verify_three_sum_closest.py).

[Valid Anagram](benchmarks/v/valid_anagram/README.md) ports C LeetCode 242 to all nine languages. The ports passed 15,170 oracle inputs each and recorded 14 workload cases. See the [verifier](benchmarks/verify_valid_anagram.py).

[To Lower Case](benchmarks/t/to_lower_case/README.md) ports C LeetCode 709 to all nine languages with an explicit ASCII mapping and a separate output buffer. The ports passed 16,780 oracle inputs each and recorded 12 workload cases, including an output-capacity failure. See the [verifier](benchmarks/verify_to_lower_case.py).

[Remove Nth Node From End of List](benchmarks/r/remove_nth_node_from_end_of_list/README.md) combines C LeetCode 19 and TheAlgorithms/Python implementations under the same removal semantics. All nine ports passed 6,800 oracle inputs each and recorded 13 workload cases. The numeric source candidate `19` remains an alias of the alphabetic algorithm name. See the [verifier](benchmarks/verify_remove_nth_node_from_end_of_list.py).

[Merge Two Sorted Lists](benchmarks/m/merge_two_sorted_lists/README.md) reviews C LeetCode 21, Dart, Python, and JavaScript implementations and provides nine portable ports. All nine passed 5,690 oracle inputs each and recorded 14 workload cases. See the [verifier](benchmarks/verify_merge_two_sorted_lists.py).

[Remove Duplicates From Sorted Array](benchmarks/r/remove_duplicates_from_sorted_array/README.md) ports C LeetCode 26 to all nine languages. The ports passed 1,570 oracle inputs each and recorded 10 workload cases, including 4,096-element arrays. See the [verifier](benchmarks/verify_remove_duplicates_from_sorted_array.py).

[Remove Element](benchmarks/r/remove_element/README.md) ports C LeetCode 27 to all nine languages and reviews Ruby `remove_elements` as a semantic alias. All nine ports passed 20,315 oracle inputs each and recorded 10 workload cases, including maximum-length arrays and output-capacity failure. See the [verifier](benchmarks/verify_remove_element.py).

[Divide Two Integers](benchmarks/d/divide_two_integers/README.md) ports C LeetCode 29 to all nine languages with truncation toward zero and signed 32-bit saturation. All nine passed 42,512 oracle inputs each and recorded 12 workload cases, including signed-boundary and divide-by-zero inputs. See the [verifier](benchmarks/verify_divide_two_integers.py).

[String Search by Brute Force](benchmarks/s/str_str_brute_force/README.md) captures the first direct-scan implementation in C LeetCode 28. Its second implementation uses KMP and aliases the existing KMP benchmark. All nine ports passed 4,504 oracle inputs each and recorded 10 workload cases, including a maximum-length near-match. See the [verifier](benchmarks/verify_str_str_brute_force.py).

[Swap Nodes in Pairs](benchmarks/s/swap_pairs/README.md) ports C LeetCode 24 to all nine languages. The bounded array contract passed 20,309 oracle inputs per language and recorded 10 workload cases, including odd and maximum-length lists. See the [verifier](benchmarks/verify_swap_pairs.py).


[Longest Valid Parentheses](benchmarks/l/longest_valid_parentheses/README.md) ports C LeetCode 32 to all nine languages. The bottom-up endpoint recurrence passed the independent stack-oracle corpus and recorded all 14 workload cases. C LeetCode candidate 42 and the pinned Python `trapped_water` candidate are reviewed as aliases of `trapped_rainwater`.


[Reverse Integer](benchmarks/r/reverse_integer/README.md) ports C LeetCode 7 to all nine languages with checked signed 32-bit digit reversal. The ports passed 70,046 oracle inputs each and recorded all 18 workload cases.


[Count Segments in a String](benchmarks/c/count_segments/README.md) ports C LeetCode 434 to all nine languages. The explicit-length byte contract passed 8,722 oracle arrays per language and recorded all 15 workload cases.


[Data normalization and standardization](benchmarks/d/data_normalization_standardization/README.md) ports the pinned R min-max and sample-standardization functions to all nine languages, preserving the sample-SD denominator.
[Data transformations](benchmarks/d/data_transformations/README.md) ports the pinned Python min-max and sample-standardization functions to all nine languages, including the source's three-decimal ties-to-even rounding.
[Dimensionality reduction PCA](benchmarks/d/dimensionality_reduction_pca/README.md) tracks the bounded one-component PCA path from the Python umbrella module across all nine languages; LDA and t-SNE remain separate uncovered methods.
[Davis–Putnam–Logemann–Loveland](benchmarks/d/davis_putnam_logemann_loveland/README.md) implements the intended DPLL decision procedure across all nine languages and documents branch-search defects in the pinned Python source.
[Double-Ended Selection Sort](benchmarks/d/double_ended_selection_sort/README.md) maps the pinned Python `unknown_sort.py` source to its actual min/max extraction algorithm across all nine languages.
[Double-point crossover](benchmarks/d/double_point_crossover/README.md) ports the pinned MATLAB-Octave parent splice to all nine languages with explicit, deterministic cut positions.
[Deep clone graph](benchmarks/d/deep_clone_graph/README.md) models node identity and clones the root-reachable component, preserving duplicate values, cycles, and self-loops across all nine languages.
[DES in ECB mode](benchmarks/d/des_ecb/README.md) ports the pinned DES block transform to all nine languages using a shared fixed-key, ASCII-byte contract.
[Detecting English Programmatically](benchmarks/d/detecting_english_programmatically/README.md) ports the pinned Python dictionary-hit and retained-letter threshold detector to all nine languages with an explicit shared dictionary input.

[Detect Capital Usage](benchmarks/d/detect_capital_usage/README.md) captures both C LeetCode 520 implementations: uppercase counting and repeated whole-word scans. Both variants passed 33,295 oracle arrays per language across all nine languages and recorded 17 workload cases each.


[Find the Difference](benchmarks/f/find_the_difference/README.md) ports C LeetCode 389 to all nine languages with the source’s character-sum method. The ports passed 2,060 oracle arrays per language and recorded all 16 workload cases. [Jewels and Stones](benchmarks/j/jewels_and_stones/README.md) ports C LeetCode 771’s lookup-table method; all nine passed 9,271 oracle arrays and recorded 17 workload cases.

[Remove Linked List Elements](benchmarks/r/remove_linked_list_elements/README.md) ports C LeetCode 203’s recursive link-rewrite algorithm to all nine languages. The ports passed 20,318 oracle inputs each and recorded nine workload cases, including maximum recursion depth, signed boundaries, malformed values, and output-capacity failure. See the [verifier](benchmarks/verify_remove_linked_list_elements.py).

[Delete Middle Node](benchmarks/d/delete_middle_node/README.md) ports C LeetCode 2095’s count, fast/slow traversal, and unlink algorithm to all nine languages. The ports passed 20,312 oracle inputs each and recorded nine workload cases, including empty, singleton, even and odd lengths, signed boundaries, malformed values, and output-capacity failure. See the [verifier](benchmarks/verify_delete_middle_node.py).

[Move Zeroes](benchmarks/m/move_zeroes/README.md) combines C LeetCode 283 and Dart `move_zeroes`, which share stable nonzero compaction followed by zero-fill. All nine ports passed 10,622 oracle inputs each and recorded nine workload cases, including signed boundaries and maximum-length arrays. See the [verifier](benchmarks/verify_move_zeroes.py).

[Add Two Numbers](benchmarks/a/add_two_numbers/README.md) combines C LeetCode 2 and JavaScript `AddTwoNumbers`, adding reverse-order digit lists with carry propagation. All nine ports passed 8,009 oracle inputs each and recorded nine workload cases, including empty lists, unequal lengths, carry chains, maximum digits, malformed inputs, and output-capacity failure. See the [verifier](benchmarks/verify_add_two_numbers.py).

[Reverse String In Place](benchmarks/r/reverse_string_in_place/README.md) ports C LeetCode 344’s inward two-pointer byte swaps to all nine languages. The ports passed 6,243 oracle inputs each and recorded nine workload cases, including embedded zero bytes, the full byte range, malformed values, and output-capacity failure. See the [verifier](benchmarks/verify_reverse_string_in_place.py).

[Jump Game II](benchmarks/j/jump_game_ii/README.md) ports C LeetCode 45’s breadth-first search over reachable indices to all nine languages. The ports passed 9,253 oracle arrays each and recorded eight workload cases, including shortest paths, unreachable inputs, and a long one-step-at-a-time path. See the [verifier](benchmarks/verify_jump_game_ii.py).

[Same-value teleport BFS](benchmarks/s/same_value_teleport_bfs/README.md) groups equal-valued positions and performs BFS while expanding each value class once. It is distinct from the existing jump-length and backward-reachability profiles and has ten native ports plus two references. Static integration is complete; no programs or checks were run.

[Jump Game](benchmarks/j/jump_game/README.md) ports the pinned C++ backward reachability scan. All nine ports passed 284 oracle arrays each and recorded 10 workload cases.

[Maximum Consecutive Ones III](benchmarks/m/max_consecutive_ones_iii/README.md) ports the intended bounded sliding-window algorithm to all nine languages, with its upstream pointer-check defect documented.
[Pairs with a given sum](benchmarks/p/pairs_with_given_sum/README.md) ports the pinned Python enumeration of all two-position combinations, preserving duplicate-value multiplicity. All nine ports passed 280 oracle arrays each and recorded 16 workload cases.

[Remove All Duplicates from Sorted List](benchmarks/r/remove_all_duplicates_from_sorted_list/README.md) ports C LeetCode 82’s recursive duplicate-run removal and suffix relinking to all nine languages. The ports passed 1,246 oracle inputs each and recorded nine workload cases, including empty and singleton lists, duplicate runs, sortedness errors, signed boundaries, maximum length, and output-capacity failure. See the [verifier](benchmarks/verify_remove_all_duplicates_from_sorted_list.py).

[Remove Duplicates from Sorted List](benchmarks/r/remove_duplicates_from_sorted_list/README.md) ports C LeetCode 83’s current/next-node unlink loop to all nine languages. The ports passed 1,244 oracle inputs each and recorded nine workload cases, including empty and singleton lists, long duplicate runs, sortedness errors, signed boundaries, maximum length, and output-capacity failure. See the [verifier](benchmarks/verify_remove_duplicates_from_sorted_list.py).

## Ways to Split Array

C LeetCode candidate 2270 counts the split positions where the left sum is at least the right sum. The shared contract accepts signed values from -100,000 through 100,000 and arrays of 2 through 100,000 values. All nine portable ports passed 20,046 independent oracle inputs each and recorded seven workload cases. See the [benchmark guide](benchmarks/w/ways_to_split_array/README.md) and [verifier](benchmarks/verify_ways_to_split_array.py). Upstream reference: [C LeetCode 2270](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2270.c).

## Maximum Bags With Full Capacity

C LeetCode candidate 2279 computes each bag’s remaining capacity, sorts those deficits, and fills the smallest gaps first. The shared ABI packs the budget, bag count, capacities, and rocks, with up to 8,191 bags so the fixed work array stays below C3’s 64 KiB stack-object limit. All nine portable ports passed 10,373 independent oracle inputs each and recorded thirteen workload cases. See the [benchmark guide](benchmarks/m/maximum_bags_with_full_capacity/README.md) and [verifier](benchmarks/verify_maximum_bags_with_full_capacity.py). Upstream reference: [C LeetCode 2279](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2279.c).

## Minimum Path Cost in a Grid

C LeetCode candidate 2304 uses row-by-row dynamic programming to minimize each next-column path cost, then adds the final cell value. The shared contract packs a rectangular grid and its complete move-cost table, with dimensions up to 32 by 32. All nine portable ports passed 959 independent oracle inputs each and recorded thirteen workload cases. See the [benchmark guide](benchmarks/m/minimum_path_cost_in_grid/README.md) and [verifier](benchmarks/verify_minimum_path_cost_in_grid.py). Upstream reference: [C LeetCode 2304](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2304.c).


[Longest Palindromic Substring](benchmarks/l/longest_palindromic_substring/README.md) ports center expansion to all nine languages, preserving leftmost tie behavior and output-buffer checks. The ports passed 1,038 oracle inputs and recorded 15 workload cases each. See [the verifier](benchmarks/verify_longest_palindromic_substring.py).
[Longest Word in a Sentence](benchmarks/l/longest_word_in_sentence/README.md) returns the first longest whitespace-delimited ASCII word, preserving tie order from the pinned Python source. All nine ports passed 9,866 oracle inputs each and recorded 10 workload cases; see [the verifier](benchmarks/verify_longest_word_in_sentence.py).
[Wave String](benchmarks/w/wave_string/README.md) emits one ASCII copy per letter, uppercasing only that position. All nine ports passed 9,861 oracle inputs and recorded 11 workload cases, including the maximum output size; see [the verifier](benchmarks/verify_wave_string.py).

[Collatz Sequence Length](benchmarks/c/collatz/README.md) counts transitions to 1 for inputs from 1 through 1,000,000. The nine ports passed 66,022 oracle inputs and recorded 14 workload cases per language. The full supported range was traced; the longest sequence takes 524 transitions and the largest intermediate is 56,991,483,520.

[Factorial Trailing Zeroes](benchmarks/f/factorial_trailing_zeroes/README.md) counts factors of five in n! across all nine languages. The ports passed 10,545 oracle inputs and recorded 16 workload cases per language. C++ `count_of_trailing_ciphers_in_factorial_n` is cataloged as a semantic alias.

[Composite Factorial Divisor Power](benchmarks/f/factorial_divisor_composite_k/README.md) returns the largest exponent `x` such that composite `k^x` divides `n!`, combining trial factorization of `k` with Legendre valuations. Ten language ports and independent quotient-sum and prime-factor/digit-sum references are drafted and registered in the binary-scalar suite; no executable checks were run.

[Binary Count Trailing Zeros](benchmarks/b/binary_count_trailing_zeros/README.md) counts low-order zero bits across all nine languages. The ports passed 66,197 oracle inputs and recorded 13 workload cases per language; the benchmark defines zero as 0 and negative values as invalid. Ruby `binary_count_trailing_zeroes` is cataloged as a spelling alias.

[Trailing Zeroes](benchmarks/t/trailing_zeroes/README.md) counts zero digits at the end of a nonnegative integer, separately from zeroes in a factorial. All nine ports passed 11,585 oracle inputs and recorded 11 workload cases per language.

[3Sum](benchmarks/0-9/3sum/README.md) returns unique zero-sum triplets using sorting and a two-pointer scan. All nine ports passed 4,175 oracle inputs each and recorded 12 workload cases.

[Count and Say](benchmarks/c/count_and_say/README.md) generates terms 1 through 19 into bounded byte output, starting from `1` and describing each equal-digit run by its length and digit.

[Zigzag Conversion](benchmarks/z/zigzag_conversion/README.md) maps bounded ASCII text into row order with alternating diagonal gaps for interior rows. The C LeetCode 6 candidate is implemented in all nine target languages.

[Longest Continuous Increasing Subsequence](benchmarks/l/longest_continuous_increasing_subsequence/README.md) returns the length of the longest strictly increasing contiguous run. The C LeetCode 674 candidate and matching Rust filename alias share the nine-language benchmark; ports passed 10,114 oracle inputs and recorded 15 workload cases.

[Peak Index in a Mountain Array](benchmarks/p/peak_index_in_mountain_array/README.md) uses binary search on the slope of a strict mountain array. All nine ports passed 1,373 oracle inputs each and recorded 13 workload cases.

[Sort Array by Parity](benchmarks/s/sort_array_by_parity/README.md) places even values first and odd values second, preserving even order and reversing odd order to match the pinned C source. All nine ports passed 5,985 oracle inputs each and recorded 12 workload cases.

[Squares of a Sorted Array](benchmarks/s/squares_of_a_sorted_array/README.md) squares a sorted input with a two-pointer scan and emits values in sorted order. All nine ports passed 3,949 oracle inputs each and recorded 13 workload cases.

[Middle of Linked List](benchmarks/m/middle_of_linked_list/README.md) applies the fast/slow pointer method to successor-index input and returns the second middle for even-length lists. The C LeetCode 876 candidate is implemented in all nine target languages.

[Reverse Only Letters](benchmarks/r/reverse_only_letters/README.md) ports C LeetCode 917's two-pointer scan, reversing ASCII letters while keeping every other printable ASCII byte in place. Its nine ports and workload are in the benchmark guide; run [`benchmarks/verify_reverse_only_letters.py`](benchmarks/verify_reverse_only_letters.py) to check the implementation.

[Find All Duplicates in an Array](benchmarks/f/find_all_duplicates_in_array/README.md) sorts the input, then emits each value that occurs twice in ascending order. All nine ports passed 32,482 oracle inputs each and recorded 12 workload cases.

[Unique Paths II](benchmarks/u/unique_paths_with_obstacles/README.md) counts right/down paths while treating blocked cells as unavailable, using a one-row dynamic-programming recurrence. All nine ports passed 1,196 oracle inputs each and recorded 20 workload cases.

[String to Integer](benchmarks/s/string_to_integer/README.md) parses a bounded ASCII byte array using the LeetCode 8 rules: skip leading spaces, accept one sign, parse the initial digit run, and clamp to signed 32-bit limits. Nine language ports share the explicit input contract.

[Find the Town Judge](benchmarks/f/find_the_town_judge/README.md) counts incoming and outgoing trust edges and returns the unique person trusted by everyone who trusts nobody. The flattened edge-list contract is implemented in all nine target languages.

[Redundant Connection](benchmarks/r/redundant_connection/README.md) uses disjoint sets to return the unique edge that closes the cycle in a tree plus one edge. All nine ports passed 632 prefix-BFS oracle inputs each and recorded 11 workload cases.

[Minimum Falling Path Sum](benchmarks/m/minimum_falling_path_sum/README.md) uses row dynamic programming to choose the lowest path through a square matrix. All nine ports passed 19,973 oracle cases each and recorded six workload cases; see [the verifier](benchmarks/verify_minimum_falling_path_sum.py).

[Palindromic Substrings](benchmarks/p/palindromic_substrings/README.md) counts every palindrome occurrence by expanding around odd and even centers. All nine ports passed 3,542 interval-oracle inputs each and recorded 13 workload cases.

[Range Sum of BST](benchmarks/r/range_sum_bst/README.md) sums values in an inclusive interval using the pinned source's full recursive tree traversal. All nine ports passed 801 tree/range oracle inputs each and recorded 19 workload cases.

[Max Increase to Keep City Skyline](benchmarks/m/max_increase_keeping_skyline/README.md) computes row and column maxima, then sums the allowable increase for each cell. All nine ports passed 20,302 oracle grids each and recorded 14 workload cases.

[Kth Smallest in BST](benchmarks/k/kth_smallest_bst/README.md) uses in-order traversal and stops as soon as it reaches the requested rank. All nine ports passed 4,295 inorder-oracle inputs each and recorded 15 workload cases.

[Keys and Rooms](benchmarks/k/keys_and_rooms/README.md) explores rooms reachable from room zero with an explicit stack. All nine ports passed 1,028 oracle graphs each and recorded 15 workload cases.

[Lowest Common Ancestor of a Binary Tree](benchmarks/l/lowest_common_ancestor/README.md) builds paths to both target nodes and returns their longest shared prefix. The nine source ports, guide, and workload are present; runtime compilation and verifier execution remain pending.

[Validate Binary Search Tree](benchmarks/v/validate_bst/README.md) checks every node against the strict bounds inherited from its ancestors. All nine ports passed 2,820 in-order-oracle inputs each and recorded 14 workload cases.

[Binary Tree Inorder Traversal](benchmarks/b/binary_tree_inorder_traversal/README.md) recursively visits left child, node, then right child into caller-owned output storage. All nine ports passed 690 tree-oracle inputs each and recorded 13 workload cases.

[Binary Tree Boundary Traversal](benchmarks/b/boundary_traversal/README.md) emits the root, nonleaf left boundary, leaves from left to right, and nonleaf right boundary in reverse. All nine ports passed 688 independent tree-oracle inputs and recorded ten workload cases; see [the verifier](benchmarks/verify_boundary_traversal.py).

[Verifying an Alien Dictionary](benchmarks/v/verifying_an_alien_dictionary/README.md) ranks lowercase letters by a supplied alphabet and checks adjacent words in nondecreasing order, including the shorter-prefix rule. All nine ports passed 5,733 oracle cases each and recorded 11 workload cases; see [the verifier](benchmarks/verify_online_stock_span.py).

[Sum of Even Numbers After Queries](benchmarks/s/sum_even_after_queries/README.md) applies point updates in order and emits the even sum after each update, maintaining the sum incrementally. All nine ports passed 7,967 recomputing-oracle inputs each and recorded 16 workload cases.

[Online Stock Span](benchmarks/o/online_stock_span/README.md) uses a monotone stack to calculate the number of consecutive prior days with prices no greater than each current price. All nine ports passed 5,733 oracle cases each and recorded 11 workload cases; see [the verifier](benchmarks/verify_online_stock_span.py).

[Merge Two Binary Trees](benchmarks/m/merge_two_binary_trees/README.md) recursively combines matching nodes and copies values from nonoverlapping branches, using a bounded heap-slot encoding for the result. The nine ports, workload, and oracle verifier are present; runtime compilation and verifier execution remain pending.

[Search in a BST](benchmarks/s/search_in_bst/README.md) follows the unique BST branch to find a target and returns the matching subtree root as a node-table index. The C LeetCode 700 candidate is implemented in all nine target languages; see [the verifier](benchmarks/verify_search_in_bst.py).

[Sudoku Solver](benchmarks/s/sudoku_solver/README.md) uses row-major recursive backtracking with row, column, and box occupancy masks. All nine ports passed 106 oracle inputs each and recorded nine workload cases; see [the verifier](benchmarks/verify_sudoku_solver.py).

[Adaptive Merge Sort](benchmarks/a/adaptive_merge_sort/README.md) uses top-down merge sort and skips merging already ordered runs. Nine portable language ports, a shared contract, and workload are present.

[Adler-32](benchmarks/a/adler32/README.md) computes the byte-array checksum with the two modulo-65521 sums. Nine portable ports, a shared workload, and an independent verifier are present.

[Distribute Coins in Binary Tree](benchmarks/d/distribute_coins/README.md) computes subtree coin excesses in postorder and sums absolute edge flows. All nine ports passed 5,221 independent oracle inputs each and recorded 18 workload cases.

[Pow(x, n)](benchmarks/p/powx_n/README.md) uses repeated squaring for a binary64 base and signed 32-bit exponent in all nine target languages; see the benchmark guide for its shared workload and contract.

[Triangular Number](benchmarks/t/triangular_number/README.md) computes `n(n + 1) / 2` for a zero-based position with bounded signed 64-bit output. Nine language ports, a shared contract, and workload are present.


[Buzz Number](benchmarks/b/buzz_number/README.md) returns whether a signed integer is divisible by seven or ends in decimal digit seven, preserving the source behavior for negative inputs. Nine ports, a shared workload, and source notes are present.


[Compute Totient](benchmarks/c/compute_totient/README.md) uses a sieve to emit Euler totients from 1 through the inclusive limit. The nine ports share a bounded byte-output contract and workload.


[Almost Palindrome Checker](benchmarks/a/almost_palindrome_checker/README.md) accepts a lowercase ASCII string if it is already a palindrome or can become one after deleting at most one character. Nine ports and a shared workload are present.


[Binary Addition](benchmarks/b/binary_addition/README.md) adds packed binary-string operands with a right-to-left carry pass and preserves leading zeroes from the longer operand. Nine ports and a shared workload are present; `add_binary` is cataloged as an alias.

[Affine Cipher](benchmarks/a/affine_cipher/README.md) applies the affine modular transform to a supplied ASCII alphabet. Nine ports passed 1,772 oracle inputs and recorded 19 workload cases.

[Alternate Harmonic Series](benchmarks/a/alternate_harmonic_series/README.md) checks alternating signs and arithmetic progression of reciprocal magnitudes; [Alternating Harmonic Series](benchmarks/a/alternating_harmonic_series/README.md) checks a finite prefix of the canonical alternating harmonic sequence. Both have nine ports, workloads, and Fraction-based verifiers; verification is pending.

[Spy Number](benchmarks/s/spy_number/README.md) checks whether a positive integer's decimal digit sum equals its digit product. Nine scalar ports and a shared workload are present; runtime verification is pending.

[Leap Year](benchmarks/l/leap_year/README.md) applies the Gregorian divisibility rule to positive signed-64-bit years and rejects nonpositive values. Nine scalar ports and a workload are present; runtime verification is pending.

[Stack-Based Depth-First Search](benchmarks/d/depth_first_search_with_stack/README.md) preserves the C++ source's push-time marking and stack-pop traversal order in nine portable ports. All nine passed 2,113 checker cases, including the declared workload, exhaustive small directed graphs, deterministic random graphs, malformed inputs, and capacity failure.

[Iterative Depth-First Search Order](benchmarks/d/depth_first_search_iterative_order/README.md) ports the pinned JavaScript graph traversal to all nine languages, preserving adjacency insertion order, push-time marking, and LIFO visitation. Its contract and workload are in place.

[False Position](benchmarks/f/false_position/README.md) implements the bracket-preserving root-finding update on the pinned `x² - x` function across all nine languages. All nine ports compiled and passed 966 root checks; the contract documents and corrects the C++ helper's bracket-update issue.

[First-Come, First-Served Scheduling](benchmarks/f/fcfs_scheduling/README.md) ports the pinned non-preemptive FCFS scheduler to all nine languages, with arrival-time ordering, process-ID tie-breaking, bounded inputs, and completion/turnaround/waiting output. The Julia `fcfs`, Java `FCFSScheduling`, and Python `first_come_first_served` sources are cataloged as aliases for already ordered, initially available jobs. A checker-only verifier covers exhaustive small schedules and boundary cases.

[Fair-Share Scheduling](benchmarks/f/fair_share_scheduling/README.md) aggregates each user's task weights, then assigns the floor of that user's proportional resource share in all nine target languages. The bounded contract preserves ignored unknown users and unallocated rounding remainder; a checker-only verifier covers 5,997 oracle cases per language.

[Faraday–Lenz Law](benchmarks/f/faraday_lenz_law/README.md) ports the induced-emf calculation to all nine languages with milli-unit fixed-point inputs and exact ties-to-even output rounding. A checker-only verifier covers 1,621 cases per language.

[Fletcher-16](benchmarks/f/fletcher16/README.md) computes the two modulo-255 accumulators for bounded ASCII byte arrays in all nine languages, including empty input and embedded NUL bytes. The Rust `fletcher` candidate aliases this contract on the ASCII domain. Its verifier checks the ports against an independent weighted-sum oracle.

[Floyd's Triangle](benchmarks/f/floyd_triangle/README.md) generates consecutive values in increasing row lengths and emits them as flattened little-endian 16-bit output in all nine languages.

[Conway's Game of Life](benchmarks/g/game_of_life/README.md) computes one B3/S23 generation on a finite square board, with dead cells beyond the edges and row-major byte output in all nine languages.

[Autocomplete Using Trie](benchmarks/a/autocomplete_using_trie/README.md) returns sorted, unique lowercase-ASCII matches for each prefix, accepting and deduplicating repeated inserted words. All nine ports passed 404 oracle cases each and recorded nine workload cases; see [the verifier](benchmarks/verify_autocomplete_using_trie.py).

[Bitap String Match](benchmarks/b/bitap_string_match/README.md) uses a 64-bit shift-OR mask to return the first lowercase-ASCII substring match, with a shared 63-byte pattern bound. All nine ports passed 8,541 independent oracle inputs each and recorded 17 workload cases; see [the verifier](benchmarks/verify_bitap_string_match.py).

[Backward Nondeterministic DAWG Matching](benchmarks/b/backward_nondeterministic_dawg_match/README.md) uses bit-parallel backward scans and skips candidate windows. Ten language drafts and scalar-suite integration are present; they have not been compiled or run.

[Backward Oracle Matching](benchmarks/b/backward_oracle_match/README.md) searches backward using a factor oracle for the reversed pattern. Ten language drafts and scalar-suite integration are present; they have not been compiled or run.

[Wavelet Matrix](benchmarks/w/wavelet_matrix/README.md) builds levelwise stable partitions for rank, quantile, and range-count queries, using the same bounded contract as the existing wavelet tree. Ten language drafts and scalar-suite integration are present; they have not been compiled or run.

[XOR Filter Peeling](benchmarks/x/xor_filter_peeling/README.md) builds a static approximate-membership filter from caller-supplied slot triples and fingerprints. Ten language drafts and scalar-suite integration are present; they have not been compiled or run.

[RRR-style Rank and Select](benchmarks/r/rrr_class_offset_rank_select/README.md) encodes bit blocks by their one-count class and within-class offset. Ten language drafts and byte-output suite integration are present; they have not been compiled or run.

[Reservoir Sampling Algorithm R](benchmarks/r/reservoir_sampling_algorithm_r/README.md) replays supplied draws to maintain a fixed-size sample without replacement. Ten language drafts and byte-output suite integration are present; they have not been compiled or run.

[Lossy Counting](benchmarks/l/lossy_counting_summary/README.md) maintains approximate frequency counters with bucket-based pruning. Ten language drafts and byte-output suite integration are present; they have not been compiled or run.

[Sticky Sampling](benchmarks/s/sticky_sampling_summary/README.md) maintains sampled frequency counters with a changing admission rate and counter thinning. Ten language drafts, replayable workloads, and byte-output suite integration are present; they have not been compiled or run.

[Exponential histogram](benchmarks/e/exponential_histogram_window/README.md) estimates the number of one-bits in a fixed sliding window using power-of-two buckets. Ten language drafts and byte-output suite integration are present; they have not been compiled or run.

[Minimum-weight tree edge domination](benchmarks/t/tree_weighted_edge_dominating_set/README.md) selects a minimum-cost set of edges that touches every tree edge. Ten language drafts and scalar-suite integration are present; they have not been compiled or run.

[Minimum tree path partition](benchmarks/t/tree_minimum_path_partition/README.md) minimizes the number of vertex-disjoint paths covering a tree. Ten language drafts and scalar-suite integration are present; they have not been compiled or run.

[Chordal-graph optimal coloring](benchmarks/c/chordal_graph_optimal_coloring/README.md) uses maximum cardinality search and greedy coloring to determine the minimum color count. Ten language drafts and scalar-suite integration are present; they have not been compiled or run.

[Linear Prüfer decoding](benchmarks/p/prufer_decode_linear/README.md) reconstructs a tree from its Prüfer sequence with a monotone leaf cursor. Ten language drafts and byte-output suite integration are present; they have not been compiled or run.

[Calkin–Wilf indexing](benchmarks/c/calkin_wilf_index/README.md) maps a breadth-first tree index to a positive reduced rational. Ten language drafts and byte-output suite integration are present; they have not been compiled or run.

[Bit-parallel LCS length](benchmarks/b/bit_parallel_lcs/README.md) updates a dynamic-programming row with multiword bit operations. Ten language drafts and scalar-suite integration are present; they have not been compiled or run.

[Suffix-automaton minimum rotation](benchmarks/s/suffix_automaton_minimum_rotation/README.md) constructs an automaton over a doubled byte sequence and walks its smallest transitions. Ten language drafts and byte-output suite wiring are present; they have not been compiled or run.

[Karger–Stein recursive contraction](benchmarks/k/karger_stein_recursive_contraction/README.md) explores two independently contracted branches using a supplied rank tape. Ten language drafts and scalar-suite wiring are present; they have not been compiled or run.

[Karger–Klein–Tarjan recursive minimum spanning forest](benchmarks/k/kkt_recursive_mst/README.md) alternates two Borůvka contractions with sampled-forest heavy-edge pruning and recursive subproblems, complementing the local one-stage KKT filter.

[Incremental minimum-enclosing-circle boundary flags](benchmarks/m/minimum_enclosing_circle_incremental_boundary/README.md) uses a supplied point order and exact integer predicates. Ten language drafts and byte-output suite wiring are present; they have not been compiled or run.

[Suffix-automaton k-th distinct substring](benchmarks/s/suffix_automaton_kth_distinct_substring/README.md) uses path counts to select a lexicographically ranked substring. Ten language drafts and byte-output suite wiring are present; they have not been compiled or run.

[Myers bit-vector edit distance](benchmarks/m/myers_bitvector_edit_distance/README.md) computes global edit distance with word-parallel dynamic programming. Ten language drafts and scalar-suite integration are present; they have not been compiled or run.

[Zhang–Shasha ordered tree edit distance](benchmarks/o/ordered_tree_edit_distance_zhang_shasha/README.md) computes unit-cost insertion, deletion, and relabel distance between rooted ordered labeled trees using keyroot forest dynamic programming.

[Myers O(ND) shortest edit script](benchmarks/m/myers_ond_shortest_edit_script/README.md) reconstructs a deterministic minimum insert/delete script with furthest-reaching edit-graph frontiers. Ten language ports, an independent replay/optimality reference, and byte-output suite registration are present; nothing has been run.

[Count distinct longest common subsequences](benchmarks/c/count_distinct_lcs/README.md) counts distinct optimal subsequence strings using dynamic programming. Ten language drafts and scalar-suite integration are present; they have not been compiled or run.

[Reversort](benchmarks/r/reversort/README.md) repeatedly reverses the current prefix through its minimum to sort the remaining suffix; [Reversort Cost](benchmarks/r/reversort_cost/README.md) sums those segment lengths. All nine sort ports passed 5,681 arrays and four workload lengths each; all nine cost ports passed 1,620 oracle arrays and 12 workload records each. See [the sort verifier](benchmarks/verify_reversort.py) and [the cost verifier](benchmarks/verify_reversort_cost.py).

[Excess-3 Code](benchmarks/e/excess_3_code/README.md) converts each decimal digit to its four-bit value after adding three, preserving the pinned `0b` output prefix and negative-input clamp. All nine ports passed 7,183 oracle/capacity cases each and recorded 10 workload inputs; see [the verifier](benchmarks/verify_excess_3_code.py).

[Remove Duplicate Words](benchmarks/r/remove_duplicate/README.md) implements the pinned split, unique-set, lexicographic-sort, and join behavior on a bounded lowercase-ASCII contract. All nine ports passed 3,816 independent oracle inputs each and recorded 12 workload cases; see [the verifier](benchmarks/verify_remove_duplicate.py).
[Cyclic Sort](benchmarks/c/cyclic_sort/README.md) preserves the 1..n permutation requirement and cyclic-placement swaps. All nine ports passed 6,425 independent oracle inputs and recorded 10 workload cases each; see [the verifier](benchmarks/verify_cyclic_sort.py).

[Triplet Sum](benchmarks/t/triplet_sum/README.md) preserves the pinned permutation-search function, while [Triplet Sum Two Pointer](benchmarks/t/triplet_sum_two_pointer/README.md) preserves the separately optimized sort-and-search function. All nine ports for each algorithm passed more than 43,000 independent oracle inputs, including capacity checks; see [the verifier](benchmarks/verify_triplet_sum.py).

[Turkish-to-Latin Conversion](benchmarks/t/turkish_to_latin_conversion/README.md) ports the pinned Java letter map over validated UTF-8, preserving other Unicode scalars. All nine ports passed 10,254 oracle inputs, including malformed UTF-8 and capacity cases; see [the verifier](benchmarks/verify_turkish_to_latin_conversion.py).

[Graph Coloring by Backtracking](benchmarks/g/graph_coloring_backtracking/README.md) preserves Go’s ascending vertex and color order. The source allows as many colors as vertices, so on loopless graphs the search never backtracks and returns a first-fit coloring rather than a minimum coloring. All nine ports passed 1,355 graph and ABI cases each and recorded ten workload cases; see [the verifier](benchmarks/verify_graph_coloring_backtracking.py).

[Graph adjacency list](benchmarks/g/graph_adjacency_list/README.md) preserves the Python graph ADT’s mutation results, insertion order, directedness, and undirected self-loop behavior across all nine languages.

[Graph adjacency matrix](benchmarks/g/graph_adjacency_matrix/README.md) ports the Python graph ADT’s directed and undirected matrix mutations, vertex reindexing, membership queries, and final row-major matrix across all nine languages.

[Graph peripherality](benchmarks/g/graph_peripherality/README.md) ports the Python all-pairs shortest paths and maximum eccentricity/farness selections to all nine languages, including its disconnected-node infinity behavior.

[Graph centrality](benchmarks/g/graph_centrality/README.md) ports weighted directed all-pairs shortest paths and returns the minimum-eccentricity and harmonic-closeness nodes.

[Bondy–Chvátal Hamiltonian closure](benchmarks/b/bondy_chvatal_hamiltonian_closure/README.md) adds degree-sum eligible edges and reports only whether the resulting closure is complete; a complete closure certifies Hamiltonicity, while an incomplete one is inconclusive. Ten native ports and byte-output suite registration are integrated.


[Ascon Digest](benchmarks/a/ascon_digest/README.md) ports both variants from the pinned C# class using portable scalar operations. The ports preserve its fixed 12-round finalization behavior and passed all 433 source-vector, boundary, randomized, invalid-input, and capacity cases in each of the nine languages; see [the verifier](benchmarks/verify_ascon_digest.py).


[Automatic Differentiation (Reverse Mode)](benchmarks/a/automatic_differentiation/README.md) ports the pinned Python gradient rules over a bounded scalar operation tape. All nine ports passed 281 cases against an independent forward-mode dual-number oracle, including shared nodes, repeated operands, and disconnected-source behavior; see [the verifier](benchmarks/verify_automatic_differentiation.py).


[Back Propagation Neural Network](benchmarks/b/back_propagation_neural_network/README.md) extracts the deterministic single-sample update from the pinned Python `DenseLayer` demo into a supplied 1→1→1 network, preserving `weight * input - bias` and reverse-layer updates. All nine ports passed 535 oracle/ABI cases each and recorded 16 workload cases; see [the verifier](benchmarks/verify_back_propagation_neural_network.py).


[Bag](benchmarks/b/bag/README.md) maps the C# and Java multiset sources to common size, empty, and membership operations. Iteration order and node representation differ by source; C# membership is checked by iteration. All nine ports passed 546 oracle/ABI cases each and recorded 16 workload cases; see [the verifier](benchmarks/verify_bag.py).


[Bandwidth Allocation](benchmarks/b/bandwidth_allocation/README.md) ports Java’s stable descending value-per-demand greedy routine, including truncation of its final fractional allocation. Its code returns 42 for the pinned source comment’s example, which claims 40. All nine ports passed 33,084 oracle/ABI cases each and recorded 16 workload cases; see [the verifier](benchmarks/verify_bandwidth_allocation.py).


[Barnsley Fern](benchmarks/b/barnsley_fern/README.md) accepts a shared trace of map-selection samples and returns each point from the pinned affine transforms using portable fixed-point arithmetic. All nine ports passed 22,306 oracle/ABI cases each and recorded 16 workload cases; see [the verifier](benchmarks/verify_barnsley_fern.py).


[Orbital Capture Radii](benchmarks/o/orbital_capture_radii/README.md) preserves the pinned gravitational-focusing equation and whole-metre nearest-even rounding. [Orbital Capture Area](benchmarks/o/orbital_capture_area/README.md) preserves the circular cross-section calculation and whole-square-metre rounding. All nine ports passed 29 combined workload cases per language; see [the verifier](benchmarks/verify_orbital_capture.py).


[Binary Tree Is Full](benchmarks/b/binary_tree_is_full/README.md) checks the recursive zero-or-two-children predicate. All nine ports passed 728 generated oracle inputs and recorded 17 workload cases; see [the verifier](benchmarks/verify_binary_tree_is_full.py). The pinned Python/Dart basic-tree implementations also map to the existing [Binary Tree Inorder Traversal](benchmarks/b/binary_tree_inorder_traversal/README.md) contract.

The Python `bezier_curve.py` source evaluates Bernstein-weighted points and tangents; the new [`bezier_curve`](benchmarks/b/bezier_curve/README.md) contract includes both outputs and excludes plotting. All nine ports passed 410 oracle cases and 16 workload records.

The pinned Python bilateral filter now has a bounded grayscale contract and nine portable implementations; all passed 187 oracle cases and 16 workload records. See the [guide](benchmarks/b/bilateral_filter/README.md) and [verifier](benchmarks/verify_bilateral_filter.py).

[BLAKE2b 512 Digest](benchmarks/b/blake2b/README.md) specializes the pinned Rust function to an empty key and a 64-byte digest over bounded byte arrays. The C `hash_blake2b` source maps to the same contract as an alias. Nine portable ports, a block-boundary workload, and independent verifier support are present.

[Project Euler Problem 551](benchmarks/p/problem551/README.md) returns the digit-sum sequence term a(n) with cached decimal-prefix jumps, for indices 1 through 10^15. The pinned default result is 73,597,483,551,591,773; see the [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_551/sol1.py).

[Sum Multiples with Inclusion-Exclusion](benchmarks/s/sum_multiples_inclusion_exclusion/README.md) ports the pinned C and Dart arithmetic-series formula to all nine target languages. Each implementation passed 2,557 direct-scan oracle inputs and recorded 15 workload cases.

[Range in Sorted Array](benchmarks/r/range_in_sorted_array/README.md) follows the pinned Java pair of iterative boundary searches. All nine ports passed 277 oracle inputs each and recorded 12 workload cases.


[Union of Two Arrays](benchmarks/u/union_of_two_arrays/README.md) merges sorted arrays and emits each value once. All nine ports passed 280 oracle inputs and 21 workload cases, including duplicate values, empty arrays, and maximum-size output.

[Uniform Crossover](benchmarks/u/uniform_crossover/README.md) ports the pinned MATLAB-Octave per-locus parent selection with an explicit deterministic mask across all nine languages.

[Unique Letters Count](benchmarks/u/unique_letters_count/README.md) ports the pinned R ASCII-letter frequency example to all nine languages, preserving first-appearance order. Every port passed 276 oracle inputs and 18 workload cases.

[Units Converter](benchmarks/u/units_converter/README.md) ports the pinned Java affine conversion closure across all nine languages, including inverse edges and composed conversions.

[Complex Arithmetic](benchmarks/c/complex_arithmetic/README.md) ports the shared exact-integer complex operations from Lua and C++ to all nine languages with portable scalar arithmetic. Every port passed 277 oracle inputs and 15 workload cases.

[Linear Regression Cost](benchmarks/l/linear_regression_cost/README.md) ports the pinned MATLAB/Octave multivariate half-mean-squared-error calculation to all nine languages. Every port passed 281 oracle inputs and 19 workload cases.

[Factorize](benchmarks/f/factorize/README.md) ports the Lua prime-to-exponent map, including its `{0: 1}` and `{1: 1}` edge results, to all nine languages with sorted little-endian factor pairs. All nine ports passed 9,230 oracle/capacity cases each and recorded 12 workload cases; see the [capacity-aware verifier](benchmarks/verify_factorize.py).

[Fuzzy Set Operations](benchmarks/f/fuzzy_set_operations/README.md) ports the pinned Python membership-vector formulas for triangular membership and eight fuzzy set operators to all nine languages using an explicit fixed-point input scale.

[Logistic Regression Cost and Gradient](benchmarks/l/logistic_regression_cost_gradient/README.md) follows the pinned MATLAB-Octave cost function and returns binary cross-entropy with the full parameter-gradient vector. All nine ports compile and pass 11 workload cases.

## CRC Polynomial Division

[CRC Polynomial Division](benchmarks/c/crc_polynomial_division/README.md) generates fixed-width CRC codewords and checks received codewords over GF(2). It corrects the pinned Java source’s unconditional XOR and variable-width remainder output. All nine ports passed 46,969 oracle cases each; see the [verifier](benchmarks/verify_crc_polynomial_division.py).

[Sentinel search](benchmarks/s/sentinel_search/README.md) reviews the pinned PHP and TypeScript sentinel scans and provides a shared mutable-array contract with nine portable implementations.

[Reverse letters](benchmarks/r/reverse_letters/README.md) reviews the pinned F-Sharp and Python word-reversal functions and provides a nine-language ASCII benchmark.

[Resistor Color Code](benchmarks/r/resistor_color_code/README.md) ports the pinned Python 3–6 band calculator across all nine languages, preserving its tolerance, temperature coefficient, and exact output-string behavior.

The F-Sharp [`has_prefix`](benchmarks/s/string_prefix_suffix/README.md) and [`has_suffix`](benchmarks/s/string_prefix_suffix/README.md) candidates share the UTF-16 prefix/suffix benchmark.

Several H candidates reuse existing contracts: F-Sharp prefix/suffix checks, Python linked-list cycle detection, Go hexadecimal conversion, and the Haskell bubble-sort re-export. Interactive and data-analysis sources are excluded; see [CATALOG.md](CATALOG.md).

[Median of medians](benchmarks/m/median_of_medians/README.md) adds bounded deterministic selection with corrected groups of at most five across all nine languages; its zero-based rank contract and pinned-source defects are documented.

[Maximal square](benchmarks/m/maximal_square/README.md) adds the bounded binary-matrix DP in all nine languages.
[Speed conversion](benchmarks/s/speed_conversion/README.md) ports the pinned PHP five-unit conversion and two-decimal rounding behavior to all nine target languages.

[Median of two sorted arrays](benchmarks/m/median_two_array/README.md) adds a bounded binary64 median benchmark across all nine languages.

[Magic diamond pattern](benchmarks/m/magicdiamondpattern/README.md) preserves the pinned formatted Floyd diamond output, including trailing spaces and the nonpositive sentinel, across all nine languages.
[Weddle's rule](benchmarks/w/weddles_rule/README.md) ports the pinned modulo-six composite quadrature weights to all nine languages using bounded fixed-point sample tables.
[Word patterns](benchmarks/w/word_patterns/README.md) maps ASCII characters to their first-seen indices, preserving the pinned Python implementation's uppercase normalization across nine languages.
[Welford's variance](benchmarks/w/welfords_variance/README.md) adds the one-pass online sample-variance recurrence across nine languages, distinct from the existing two-pass variance benchmark.

[Welsh–Powell greedy coloring](benchmarks/w/welsh_powell/README.md) preserves the pinned Java degree sort, stable index ties, and its rule for admitting uncolored vertices to each color class across all nine languages.
[XTEA](benchmarks/x/xtea/README.md) adds bounded 64-bit block encryption with the pinned Python source's big-endian encoding across nine languages.
[Z algorithm](benchmarks/z/z_algorithm/README.md) computes the Z-array used for overlapping substring search.
[Interleaving strings](benchmarks/i/interleavingstrings/README.md) adds the bounded two-source order-preserving dynamic program across nine languages.
[Half-wave rectifier](benchmarks/h/half_wave_rectifier/README.md) ports six selected current/voltage calculations and their resistance constraints across nine languages.
[IPv4-mapped IPv6 conversion](benchmarks/i/ipv6_converter/README.md) adds both raw-byte conversion directions across nine languages.
[Hamming code encoder](benchmarks/h/hamming_code/README.md) ports the pinned parity-bit placement and emission routine across nine languages.

[IMPLY Gate](benchmarks/h/imply_gate/README.md) ports the pinned Python two-input implication function to all nine languages, covering the complete Boolean truth table.



The pinned Java `iterative_flood_fill` source uses a FIFO queue with eight-neighbor connectivity, matching [`flood_fill_breadth_first`](benchmarks/f/flood_fill_breadth_first/README.md); the existing [`flood_fill`](benchmarks/f/flood_fill/README.md) profile uses a LIFO stack.

The pinned Go `isisogram` first-order predicate is represented by the shared [isogram benchmark](benchmarks/i/isogram/README.md).

[Inversion count](benchmarks/i/inversions/README.md) ports the pinned Python brute-force strict inversion counter to all nine languages.

The pinned Lua `weighted_choice` source uses an external global random generator and has no deterministic result for a fixed benchmark input, so it is excluded.

[X9.23 padding](benchmarks/x/x932_padding/README.md) ports the pinned C# fixed-zero padding path to all nine languages, with the final byte storing the padding length.

[Insert/delete array elements](benchmarks/i/insert_delete_in_array/README.md) ports the pinned Java array-copy helpers for insertion and deletion to all nine languages.

[Highest response ratio next](benchmarks/h/highest_response_ratio_next/README.md) ports the pinned Python and Java non-preemptive HRRN schedulers to all nine languages.

Stateful API candidates `divide_digit`, `dict`, `dynamic_stack`, and `double_ended_queue` were source-reviewed and excluded because their outputs depend on prior state or command sequences.

MATLAB assignment demonstrations (`equal`, `equal_add`) and Solidity's transaction event demonstration (`events`) were excluded as non-algorithm examples.

[Elementary Rule 30](benchmarks/e/elementary/README.md) ports the pinned JavaScript and Python one-generation cellular automata to all nine languages.

The pinned Go `eggdropping` candidate shares the canonical [`egg_dropping`](benchmarks/e/egg_dropping/README.md) benchmark recurrence.

The Python `double_hash` candidate is an inherited stateful hash-table collision strategy, not a standalone algorithm call, and is excluded.

[Euler degree parity](benchmarks/e/euler/README.md) ports the pinned C helper that checks proposed Euler-trail endpoint degrees across all nine languages.

[Modified Euler (Heun)](benchmarks/e/euler_modified/README.md) ports the pinned Python predictor-corrector method to all nine languages on its example ODE.

[IIR filter](benchmarks/i/iir_filter/README.md) ports the pinned Python zero-state N-order sample recurrence to all nine languages.

[Transposed Direct Form II digital filter](benchmarks/d/digital_filter_direct_form_ii_transposed/README.md) benchmarks the zero-state shared delay-chain recurrence in ten languages; it uses a different state representation from the existing history-based `iir_filter`.

[Hilbert curve](benchmarks/h/hilbert_curve/README.md) ports the pinned Python recursive point generator to all nine languages with exact dyadic coordinates.
[Hilbert coordinate-to-index mapping](benchmarks/h/hilbert_curve_index_encode/README.md) uses the iterative Butz quadrant transform to encode one bounded grid point as its Hilbert path index, with a recursive quadrant oracle and byte-output suite registration.
[Aho BUILD rooted-triplet tree](benchmarks/a/aho_build_rooted_triplet_tree/README.md) checks rooted-triplet compatibility and serializes the resulting tree with deterministic child ordering; its independent union-find oracle and byte-output suite registration are included.
[Reverse-DSU brick-fall replay](benchmarks/b/bricks_falling_when_hit_reverse_dsu/README.md) restores a bounded grid-hit trace in reverse and measures roof-component growth; a forward flood-fill reference independently checks the per-hit fall counts.

[Hill encoder](benchmarks/h/hill_encoder/README.md) ports the pinned C# 3×3 chunk encoder to all nine languages on a bounded ASCII and integral-key domain.

The Lua `interval_scheduling` candidate maps to [`activity_selection`](benchmarks/a/activity_selection/README.md); Java `iirfilter` maps to [`iir_filter`](benchmarks/i/iir_filter/README.md) on the source setter’s zero-final-coefficient domain.

[Integral approximation](benchmarks/i/integral_approximation/README.md) ports the pinned C++ delta-based trapezoidal Riemann sum to all nine languages.

[Integration by Simpson approximation](benchmarks/i/integration_by_simpson_approx/README.md) ports the pinned Python 1,000-panel x² Simpson sum to all nine languages.

[Jaro similarity](benchmarks/j/jaro_similarity/README.md) ports the pinned C# matching-window similarity calculation to all nine languages on bounded ASCII strings.

The pinned C++ `longest_common_string` candidate computes longest common subsequence length and maps to [`longest_common_subsequence`](benchmarks/l/longest_common_subsequence/README.md).

[Longest repeating subsequence](benchmarks/l/longest_repeating_subsequence/README.md) ports the pinned Python LCS-on-self dynamic program to all nine languages.

The pinned Go `linear` function scans from the first element and returns the first matching index, so it maps to [`linear_search`](benchmarks/l/linear_search/README.md).

The pinned C# interval scheduler maps to [activity selection](benchmarks/a/activity_selection/README.md); the C# jump searcher maps to [jump search](benchmarks/j/jump_search/README.md); and the Python elementwise Leaky ReLU maps to [leaky_relu](benchmarks/l/leaky_relu/README.md) under numeric float comparison.

[Longest repeated substring](benchmarks/l/longest_repeated_substring/README.md) ports the pinned Java suffix-array result length to all nine languages.

The Go binary-lifting LCA, C# interval scheduler and jump searcher, C++ jump game, and Python Leaky ReLU candidates map to their corresponding canonical benchmarks.

[Jaro–Winkler similarity](benchmarks/j/jaro_winkler/README.md) is implemented across all nine languages from the pinned Python semantics. Related jump-search and longest-unique-substring candidates are documented as aliases; `jump2` retains a source-defect note.
[Jenkins One-at-a-Time hash](benchmarks/j/jenkins_one_at_a_time/README.md) ports the pinned Python 32-bit UTF-8 byte-mixing hash across all nine languages on a bounded ASCII byte-array contract; its per-step add/shift/XOR recurrence is distinct from DJB2 and SDBM.
[Astable 555 timer](benchmarks/i/ic_555_timer/README.md) ports the pinned Python frequency and duty-cycle formulas across all nine languages with a selector-based bounded contract.
[Longest increasing subsequence, iterative](benchmarks/l/longest_increasing_subsequence_iterative/README.md) preserves the pinned Python `<=` recurrence (a longest non-decreasing subsequence) and compares its length across all nine language ports.
[Longest palindromic substring](benchmarks/l/longestpalindrome/README.md) ports the pinned Go Manacher recurrence across all nine languages, preserving space filtering and bounding inputs to printable ASCII that avoids the source marker.
The pinned Go `longestarithmeticsubsequence` implementation uses the same endpoint/difference dynamic program and aliases to [longest arithmetic subsequence](benchmarks/l/longest_arithmetic_subsequence/README.md).
[Job sequence with deadline](benchmarks/j/job_sequence_with_deadline/README.md) ports the pinned Python stable reward-rank filter across all nine languages; its bounded contract compares the count of retained jobs.
[Job sequencing with deadline](benchmarks/j/job_sequencing_with_deadline/README.md) ports the pinned Python latest-free-slot greedy scheduler; its scalar result losslessly encodes scheduled count and total profit, distinct from the rank-filter variant.
[Iterating through submasks](benchmarks/i/iterating_through_submasks/README.md) ports the pinned Python descending submask loop across all nine languages and compares the number of nonzero submasks for bounded positive masks.
[Kahn topological sorting](benchmarks/k/kahn/README.md) ports the pinned Go queue-based DAG algorithm across all nine languages, deduplicating edges and comparing processed vertex count because neighbor-map order is nondeterministic.
[Largest divisible subset](benchmarks/l/largest_divisible_subset/README.md) ports the pinned Python sorted dynamic program across all nine languages and compares the longest divisible-chain length on bounded positive inputs.
[K-th lexicographic permutation](benchmarks/k/kth_lexicographic_permutation/README.md) ports the pinned Python factoradic selection across all nine languages and encodes the full bounded permutation in the scalar result.
[K-th order statistic](benchmarks/k/kth_order_statistic/README.md) ports the pinned Python divide-and-conquer quickselect across all nine languages for bounded unique-value inputs.
[K-th smallest with a max heap](benchmarks/k/kth_smallest_heap/README.md) ports the pinned Rust top-k max-heap algorithm across all nine languages.
[Log two](benchmarks/l/log_two/README.md) ports the matching JavaScript and TypeScript signed-shift loops across all nine languages, bounded to nonnegative signed-32-bit values.
[K-fold labels](benchmarks/k/k_folds/README.md) ports the pinned R source deterministic non-list fold assignment across all nine languages.

[K-th element from the end](benchmarks/k/kth_element_from_end/README.md) ports the pinned Python linked-list two-pointer lookup across all nine languages for bounded values.
[Long division](benchmarks/l/long_division/README.md) ports the pinned Java decimal digit-by-digit repeated-subtraction division across all nine languages for bounded integers.
[Lee breadth-first search](benchmarks/l/lee_breadth_first_search/README.md) ports the pinned Rust four-neighbor grid BFS across all nine languages and compares shortest path distance.
[Last item in a list](benchmarks/l/last_item_in_a_list/README.md) ports the pinned Clojure tail-recursive last-element lookup across all nine languages.
[Length of a list](benchmarks/l/length_of_list/README.md) ports both pinned Clojure counting approaches across all nine languages for bounded integer sequences.
[Langton's ant](benchmarks/l/langtons_ant/README.md) ports the pinned Python turn-move-flip automaton across all nine languages and packs the bounded final board and ant state.
[Largest square in a binary matrix](benchmarks/l/largest_square_area_in_matrix/README.md) ports the pinned Python bottom-up DP across all nine languages and returns the maximum all-1 square side length.
[Linear Diophantine equation solvability](benchmarks/l/linear_diophantine_eqn/README.md) ports the matching Dart recursive-gcd and MATLAB/Octave gcd-divisibility checks across all nine languages.
[Local maximum point](benchmarks/l/local_maximum_point/README.md) ports the pinned JavaScript divide-and-conquer peak search across all nine languages, preserving its midpoint tie-branch behavior.
[Linear Diophantine equations solver](benchmarks/l/linear_diophantine_equations_solver/README.md) ports the pinned Java extended-Euclidean particular-solution solver across all nine languages and packs its bounded solution pair.
[Lua uint53 predicate](benchmarks/i/is/README.md) ports the pinned integral, nonnegative, below-2^53 check across all nine languages.
[Intensity based segmentation](benchmarks/i/intensity_based_segmentation/README.md) ports the pinned Python ordered-threshold overwrite behavior across all nine languages and packs bounded pixel labels.
[Kinematics](benchmarks/k/kinematics/README.md) ports the four pinned Java SUVAT formulas across all nine languages with a bounded, exactly scaled integer result.
[Lua uint53 bit iterator](benchmarks/i/ibits/README.md) ports the pinned least-significant-first iterator across all nine languages and reports its bounded yield count.
[Local binary pattern](benchmarks/l/local_binary_pattern/README.md) ports the pinned Python neighbor comparisons and weight order across all nine languages for a bounded interior 3x3 patch.
[K-th next greater element](benchmarks/k/kth_next_greater_element/README.md) ports the pinned Python strict-successor chain semantics across all nine languages and reports the bounded number of complete results.
[Linked deque](benchmarks/l/linked_deque/README.md) ports the pinned Lua doubly linked deque operations across all nine languages and packs bounded query results.

[ISO 7816-4 padding](benchmarks/i/iso7816_d4_padding/README.md) ports all three methods from the pinned C# class—padding addition, suffix removal, and padding count—to nine portable implementations.
[ISO 10126-2 padding](benchmarks/i/iso10126_d2_padding/README.md) ports the pinned C# add, remove, and padding-count methods across all nine languages with deterministic supplied fill bytes.

[Dynamic coin change solver](benchmarks/d/dynamic_coin_change_solver/README.md) preserves the pinned C# backward-induction selection order across all nine languages; its documented rule can return a longer sequence than the true minimum-count solution. [Pinned source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Problems/DynamicProgramming/CoinChange/DynamicCoinChangeSolver.cs).

[Word occurrence](benchmarks/w/word_occurrence/README.md) ports the pinned Python case-sensitive token counter across all nine languages. The same-stem F# variant prints repeated words instead of incrementing their counts, so it is documented separately. [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/word_occurrence.py); [F# source](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Strings/WordOccurrence.fs).

[Different views of a binary tree](benchmarks/d/diff_views_of_binary_tree/README.md) implements the pinned Python right, left, top, and bottom views across all nine languages. The bounded indexed-tree contract preserves level and horizontal-column tie order. See the [verifier](benchmarks/verify_diff_views_of_binary_tree.py).
[Decision convolutions](benchmarks/d/decisions_convolutions/README.md) ports the pinned C# weighted-sum and max-min decision selection across all nine languages, preserving first-row ties under exact bounded decimal inputs.

[Gaussian elimination with pivoting](benchmarks/g/gaussian_elimination_pivoting/README.md) ports the pinned Python pivot selection, elimination order, and back-substitution across all nine languages for bounded 2–4 variable systems.
[Generate Subsets](benchmarks/s/generate_sub_sets/README.md) preserves the pinned JavaScript ascending bitmask order and input-position order across all nine languages; duplicate values remain distinct positions.
[Recursive string subsets](benchmarks/g/generate_subsets_recursive/README.md) preserves the pinned Java include-first depth-first traversal and duplicate character positions across all nine languages.
[Wa-Tor](benchmarks/w/wa_tor/README.md) models bounded prey-predator chronons across all nine languages with explicit deterministic movement, targeting, and entity order.
[Top K frequent words](benchmarks/t/top_k_frequent_words/README.md) preserves the pinned Python frequency-only max-heap ordering, including heap-layout-dependent ties, across all nine languages.

[Two-dimensional elastic collision](benchmarks/e/elastic_collision2_d/README.md) ports the pinned Java circular-body impulse calculation to all nine languages and returns the first body's quantized post-collision velocity.
[Elliptic-curve key exchange](benchmarks/e/elliptic_curve_key_exchange/README.md) ports the pinned C++ affine ECDH flow across all nine languages under a bounded small-prime field contract.
[Exponential Linear Unit (ELU)](benchmarks/e/elu/README.md) isolates the pinned MATLAB-Octave activation formula and ports it to all nine languages with an explicit scalar input contract.
[Evaluate expression](benchmarks/e/evaluate_expression/README.md) ports the pinned JavaScript postfix stack evaluator across all nine languages with bounded binary64 arithmetic and explicit invalid-expression results.
[Find month calendar](benchmarks/f/find_month_calendar/README.md) ports the pinned JavaScript Monday-first calendar formatter to all nine languages with a bounded date range and exact padded output.
[Parameterized sigmoid](benchmarks/s/sigmoid_without_inbuilt/README.md) ports the pinned MATLAB-Octave logistic activation with an explicit slope parameter across all nine languages.

[Strip characters from a string](benchmarks/s/strip/README.md) ports the pinned Python two-ended character-set scan across all nine languages for bounded ASCII strings.

[Flatten a nested list](benchmarks/f/flatten_nested_list/README.md) ports both pinned Clojure flatteners across all nine languages and hashes the bounded left-to-right leaf sequence.

The pinned Java `FIFOCache` source uses its default zero TTL, so sequential puts and gets expose FIFO insertion-order eviction: overwrite removes and appends the key, while reads do not reorder entries. The bounded [`fifocache`](benchmarks/f/fifocache/README.md) contract records hit/miss counts, get results, and final FIFO contents across nine languages; TTL timing, concurrency, callbacks, and explicit removal are outside its scope. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/caches/FIFOCache.java).

Recent source-backed additions from Library Checker, Rosetta Code, CP-Algorithms, OI Wiki, and published algorithm papers include [binomial-divisibility primality](benchmarks/b/binomial_divisibility_primality_test/README.md), [D'Esopo–Pape shortest paths](benchmarks/d/d_esopo_pape/README.md), [Dominator tree](benchmarks/d/dominator_tree/README.md), [Deque operate all composite](benchmarks/d/deque_operate_all_composite/README.md), [Eertree](benchmarks/e/eertree/README.md), [Erdős–Gallai graphical-sequence test](benchmarks/e/erdos_gallai_graphical_sequence/README.md), [Gabow path-based SCC](benchmarks/g/gabow_scc/README.md), [Hunt–Szymanski sparse LCS](benchmarks/h/hunt_szymanski_lcs/README.md), [incremental strongly connected components](benchmarks/i/incremental_scc/README.md), [`k_shortest_walk`](benchmarks/k/k_shortest_walk/README.md), [Li Chao tree](benchmarks/l/li_chao_tree/README.md), [Link-Cut Tree](benchmarks/l/link_cut_tree/README.md), [Manhattan MST](benchmarks/m/manhattan_mst/README.md), [Minkowski sum of convex polygons](benchmarks/p/minkowski_sum_convex_polygons/README.md), [point in polygon by ray casting](benchmarks/p/point_in_polygon_ray_casting/README.md), [point set range composite](benchmarks/p/point_set_range_composite/README.md), [queue operate all composite](benchmarks/q/queue_operate_all_composite/README.md), [unordered rooted-tree enumeration](benchmarks/r/list_rooted_trees/README.md), [Rectangle add point get](benchmarks/r/rectangle_add_point_get/README.md), [range affine point get](benchmarks/r/range_affine_point_get/README.md), [range affine range sum](benchmarks/r/range_affine_range_sum/README.md), [range set range composite](benchmarks/r/range_set_range_composite/README.md), [run enumeration](benchmarks/r/runenumerate/README.md), [SA-IS suffix-array construction](benchmarks/s/suffix_array_sais/README.md), [st-numbering](benchmarks/s/st_numbering/README.md), [Static range inversions query](benchmarks/s/static_range_inversions_query/README.md), [Static range LIS query](benchmarks/s/static_range_lis_query/README.md), [Static rectangle add rectangle sum](benchmarks/s/static_rectangle_add_rectangle_sum/README.md), [counting directed spanning trees](benchmarks/c/counting_spanning_trees_directed/README.md), [counting undirected spanning trees](benchmarks/c/counting_spanning_trees_undirected/README.md), [Cuckoo Filter trace](benchmarks/c/cuckoo_filter_operation_trace/README.md), [Crochemore–Perrin Two-Way string matching](benchmarks/c/crochemore_perrin_two_way/README.md), [rooted tree isomorphism classification](benchmarks/r/rooted_tree_isomorphism_classification/README.md), [Irving rank-maximal matching](benchmarks/r/rank_maximal_matching_irving/README.md), [segment add get min](benchmarks/s/segment_add_get_min/README.md), [segment tree beats](benchmarks/s/segment_tree_beats/README.md), [static range mode query](benchmarks/s/static_range_mode_query/README.md), [three-edge-connected components](benchmarks/t/three_edge_connected_components/README.md), and [global vertex connectivity](benchmarks/v/vertex_connectivity/README.md). Their source comparisons, duplicate decisions, and suite-integration status are tracked in the [additional algorithm coverage ledger](benchmarks/ALGORITHM_EXPANSION_COVERAGE.md).

The [Stockham autosort radix-2 FFT](benchmarks/s/stockham_autosort_radix2_fft/README.md) adds a ping-pong-stage complex transform with natural-order output, alongside the existing in-place and six-step FFT profiles. Ten language ports, independent references, workload fixtures, and float64-slice suite registration are included.

The recent additions also include [Brown's calendar queue](benchmarks/c/calendar_queue/README.md), [interval heaps](benchmarks/i/interval_heap_double_ended/README.md), [offline dynamic bipartiteness](benchmarks/o/offline_dynamic_bipartiteness/README.md), [k-truss edge peeling](benchmarks/k/k_truss_edge_peeling_decomposition/README.md), [LCM prefix-preserving closed-itemset enumeration](benchmarks/l/lcm_ppc_closed_itemset_enumeration/README.md), and [Sugiyama longest-path layer assignment](benchmarks/s/sugiyama_longest_path_layer_assignment/README.md). Each has ten language ports, bounded workloads, independent references, and byte-output suite registration.

The [lower-bound circulation feasibility](benchmarks/l/lower_bound_circulation_feasibility/README.md) benchmark reduces edge lower bounds to a super-source/super-sink maximum-flow problem. It includes ten language ports, an exhaustive independent oracle, bounded fixtures, and scalar-suite registration.

The [lazy-heap Dijkstra](benchmarks/d/dijkstra_lazy_heap/README.md) profile keeps immutable heap entries and discards stale pops, making its sparse frontier distinct from the existing dense-scan Dijkstra benchmark. It has ten language ports, a Bellman–Ford reference, stale-entry fixtures, and shortest-path suite coverage.

The [Elkin–Peleg sparse graph spanner](benchmarks/e/elkin_peleg_sparse_spanner/README.md) package implements a bounded `Sp Cons` profile with exact integer cluster thresholds and canonical connector paths. It has ten language ports, a matrix/Floyd independent reference, and byte-output suite registration.

The [Fakcharoenphol–Rao planar SSSP](benchmarks/f/fakcharoenphol_rao_planar_sssp/README.md) profile builds exact piece dense-distance graphs and bounded Monge-block Dijkstra for planar graphs with negative arcs. It includes ten language drafts, independent Bellman–Ford references, an unreachable-distance fixture, and byte-output suite registration.

The [sparse-heap Prim](benchmarks/p/prim_sparse_heap/README.md) profile uses an indexed decrease-key heap over adjacency lists, distinct from the existing dense-scan Prim implementation. It includes ten language ports, an independent Kruskal reference, bounded graph fixtures, and scalar-suite registration.

The [Mestre strict weighted popular matching](benchmarks/m/mestre_strict_weighted_popular_matching/README.md) profile applies strict-list category labels and promotion-cost edge pruning to one-sided weighted preferences with private last resorts. It differs from complete-list weighted and ties-aware popular-matching profiles; ten language ports, an exhaustive weighted-vote oracle, workload fixtures, and scalar-suite registration are included.

[Zhang–Suen thinning](benchmarks/z/zhang_suen_thinning/README.md) iteratively applies two simultaneous directional deletion phases to a bounded binary image until it reaches a skeleton fixed point. Ten ports and byte-output suite registration are included; it is distinct from SUSAN's edge-response thinning.

[Fast prime sums](benchmarks/f/fast_prime_sums/README.md) uses a Meissel–Lehmer weighted partial-sieve recurrence to sum primes through `n`, distinct from prime counting, Min_25 multiplicative-function summation, and the small-range Problem 10 sieve. Its ten ports use the scalar suite.

The [Dulmage–Mendelsohn decomposition](benchmarks/d/dulmage_mendelsohn_decomposition/README.md) reports which vertices can be exposed across all maximum bipartite matchings, alongside matching size. It is distinct from returning one maximum matching.

[Bipartite minimum vertex cover](benchmarks/b/bipartite_minimum_vertex_cover/README.md) returns a canonical minimum-cover certificate from ordered augmenting-path matching and alternating reachability. Its packed mask uses a fixed 0-first lexicographic tie rule; ten language ports and scalar-suite registration are included.

The [Pocklington certificate verifier](benchmarks/p/pocklington_primality_certificate/README.md) checks a partial factorization of `n-1` and supplied witnesses to prove primality deterministically; it is separate from probable-prime tests.

The [Pohlig–Hellman discrete logarithm](benchmarks/p/pohlig_hellman_discrete_log/README.md) factors the base order, lifts prime-power logarithm digits with small BSGS subproblems, and combines them by CRT. It differs from one-shot BSGS and generalized gcd-stripping discrete logarithms.

[Optimal Mismatch string search](benchmarks/o/optimal_mismatch/README.md) combines a frequency-ordered pattern scan with Quick Search and an adapted good-suffix shift, distinct from the local fixed-order and end-aligned matchers.

[Berry–Ravindran string search](benchmarks/b/berry_ravindran_search/README.md) uses a two-symbol lookahead shift table after each candidate window, distinct from single-symbol Quick Search and Zhu–Takaoka's mismatch-pair shift.

[Zhu–Takaoka string search](benchmarks/z/zhu_takaoka_search/README.md) combines a two-symbol bad-character table for the current window's final pair with a strong good-suffix shift. Ten language ports, independent references, fixtures, and scalar-suite registration are included.

[Simon sparse-automaton string matching](benchmarks/s/simon_string_search/README.md) stores only significant backward transitions of the pattern DFA, with linear preprocessing and space independent of alphabet size. It differs from the dense finite-automaton table and KMP's prefix-failure traversal.

[Galil–Seiferas string matching](benchmarks/g/galil_seiferas_search/README.md) finds a perfect factorization with short prefix-period searches and scans using constant extra state. Its search differs from Two-Way's critical factorization and period-memory procedure.

[KmpSkip string matching](benchmarks/k/kmp_skip_search/README.md) uses character-position buckets to sample candidate windows, then reconciles Morris–Pratt and KMP shifts while retaining a matched wall.

[Skip Search](benchmarks/s/skip_search/README.md) buckets every pattern position by symbol and samples one text position per pattern-length interval, verifying the candidate starts generated by that bucket.

[String Matching on Ordered Alphabets](benchmarks/s/string_matching_ordered_alphabets/README.md) updates maximal-suffix and period state online from the matched text prefix, with no pattern preprocessing and constant extra space.

[Morris–Pratt Search](benchmarks/m/morris_pratt_search/README.md) follows ordinary longest-border links on mismatch and after full matches, retaining overlaps without KMP's tagged-border optimization.

[Galil–Giancarlo string matching](benchmarks/g/galil_giancarlo_search/README.md) refines Colussi's ordered scan with a remembered-prefix transition for heavy overlaps. A separate run-count path handles constant-symbol patterns.

[Forward DAWG Matching](benchmarks/f/forward_dawg_matching/README.md) builds the pattern's suffix automaton, scans text left-to-right, and follows suffix links to detect every occurrence, including overlaps.

[Reverse Colussi string search](benchmarks/r/reverse_colussi_search/README.md) compares pattern positions in its h-derived order and selects between separate good-suffix and bad-character shift tables.

[Reverse Factor string search](benchmarks/r/reverse_factor_search/README.md) scans each candidate window backward with a suffix automaton of the reversed pattern, using its terminal states to choose safe shifts.

[Turbo Reverse Factor search](benchmarks/t/turbo_reverse_factor_search/README.md) retains the preceding shift and the matched pattern prefix, limiting reinspection while preserving the reversed-pattern automaton's safe shifts.

[Turbo Boyer–Moore string matching](benchmarks/t/turbo_boyer_moore_search/README.md) combines bad-character and good-suffix shifts with remembered matched-suffix state, returning every overlapping occurrence.

[Raita string matching](benchmarks/r/raita_search/README.md) keeps Horspool's shift table but probes each candidate window's last, first, and middle bytes before the remaining interior.

[Tuned Boyer–Moore string matching](benchmarks/t/tuned_boyer_moore_search/README.md) uses a sentinel-backed skip loop that advances through three bad-character shifts before checking a candidate prefix.

[Smith string matching](benchmarks/s/smith_string_search/README.md) advances by the larger of Horspool's end-byte shift and Quick Search's lookahead shift, reporting all overlapping matches.

[Maximal Shift string matching](benchmarks/m/maximal_shift_search/README.md) compares pattern positions by decreasing leading shift, then combines adapted good-suffix and Quick Search shifts; its position order differs from Optimal Mismatch.

[Smallest number with exactly `d` divisors](benchmarks/s/smallest_number_with_n_divisors/README.md) searches nonincreasing prime-exponent profiles for the least value within a caller-supplied cap.

[Baum–Welch re-estimation](benchmarks/b/baum_welch_reestimation/README.md) performs one forward–backward expectation step and re-estimates a discrete HMM's initial, transition, and emission distributions; this is distinct from Viterbi path decoding.

[Sieve of Sundaram](benchmarks/s/sieve_of_sundaram/README.md) counts primes through an inclusive limit by marking odd-composite indices `i + j + 2ij`, a construction distinct from the local Eratosthenes, Atkin, linear, segmented, and stream sieves.

[Perfect totient number](benchmarks/p/perfect_totient_number/README.md) tests whether the sum of the successive Euler totients down to the terminal value 1 equals the starting integer, using a bounded input domain of 3 through 65,535.

[Thiele rational interpolation](benchmarks/t/thiele_rational_interpolation/README.md) evaluates an inverse-difference continued fraction for ordered sample pairs on a bounded dyadic binary64 grid, with explicit near-pole guards; it is distinct from the local polynomial interpolation profiles.

The [prime-modulus p-free factorial](benchmarks/p/prime_modulus_p_free_factorial/README.md) adds a standalone large-`n` factorial-unit profile; its overlap with the p-adic binomial-coefficient implementation is documented in the coverage ledger.

The [Lucas binomial coefficient](benchmarks/b/binomial_coefficient_lucas/README.md) profile applies base-prime digit decomposition for large `n`, distinct from p-adic factorial cancellation modulo prime powers.

The [fundamental Pell solution](benchmarks/p/pell_fundamental_solution/README.md) profile uses continued fractions to solve the Diophantine equation, distinct from the local Pell-number sequence and rational continued-fraction conversion profiles.

The [American flag string sorter](benchmarks/a/american_flag_string_sorter/README.md) applies in-place R-way MSD cycle permutation, while the local string radix profile uses buffered stable distribution.

The [Apostolico–Crochemore search](benchmarks/a/apostolico_crochemore_search/README.md) adds a linear-time all-occurrences matcher distinct from KMP and Crochemore–Perrin Two-Way.

[Alpha Skip Search](benchmarks/a/alpha_skip_search/README.md) indexes fixed-length pattern factors in base-4 buckets and checks sampled text windows, distinct from prefix-function and critical-factorization methods.

The [generalized suffix automaton union](benchmarks/g/generalized_suffix_automaton_union/README.md) builds from a shared trie and counts distinct substrings across a set of strings, distinct from one-text suffix automata and pairwise LCS.

[Schorr–Waite graph marking](benchmarks/s/schorr_waite_graph_marking/README.md) uses in-place pointer reversal to traverse cyclic binary graphs with constant traversal control state, rather than an explicit DFS stack or BFS queue.

The [Size Balanced Tree ordered set](benchmarks/s/size_balanced_ordered_set/README.md) uses grandchild subtree sizes to decide single and double rotations, distinct from AVL height balancing, treap priorities, and splaying.

[Mo's algorithm with modifications](benchmarks/m/mo_with_modifications/README.md) sorts range queries by left block, right block, and update time, distinct from the static-array [`mos_algorithm`](benchmarks/m/mos_algorithm/README.md).

[Lindström–Gessel–Viennot nonintersecting paths](benchmarks/l/lgv_nonintersecting_paths/README.md) computes a small DAG path matrix and determinant; direct path enumeration is kept as an independent reference.

[Weak-heapsort](benchmarks/w/weak_heapsort/README.md) uses a reverse-bit weak-heap invariant and a distinguished-ancestor restore pass, distinct from ordinary binary heapsort.

[Persistent leftist heap](benchmarks/p/persistent_leftist_heap/README.md) path-copies merge paths to preserve branches, distinct from the local destructive leftist-heap trace.

The [perfect-shuffle order](benchmarks/p/perfect_shuffle_order/README.md) profile adds the repeated out-shuffle restoration count, which is distinct from returning one half-interleave in `shuffle_array`.

The [three-prime Carmichael enumerator](benchmarks/t/three_prime_carmichael_enumerator/README.md) is a bounded generator, distinct from the local supplied-integer Carmichael and Miller–Rabin tests. It uses the Rosetta task's mathematical parameterization and an independent Korselt-criterion oracle.

The [Chernick Carmichael least multiplier](benchmarks/c/chernick_carmichael_least_multiplier/README.md) adds the restricted factor family for 3–9 prime factors; it returns the least multiplier and uses an independent sieve-based primality reference.

[Dynamic graph vertex-add component-sum](benchmarks/d/dynamic_graph_vertex_add_component_sum/README.md) covers edge insertion/removal, vertex-value updates, and component-sum queries with a time segment tree and rollback DSU; its ten ports are registered in the byte-output suite with direct-graph and independent rebuild-DSU oracles.

[Virtual tree](benchmarks/v/virtual_tree/README.md) builds the LCA-closed compressed tree for a marked vertex set; its ten ports use adjacent-mark LCAs and the byte-output suite includes generated tree, empty-mark, maximum-output, malformed-input, and capacity cases.

[Hirschberg LCS reconstruction](benchmarks/h/hirschberg_lcs/README.md) returns an actual longest common subsequence using shared forward and backward rows; its full-table verifier checks the result independently, and the byte-output suite covers maximum sequences and capacity boundaries.

[Games on arbitrary directed graphs](benchmarks/g/games_on_arbitrary_graphs/README.md) classifies every vertex as winning, losing, or drawing with reverse-edge retrograde propagation; its independent fixed-point oracle and generated cyclic-graph cases are registered in the byte-output suite.

[Disjoint sparse table affine composition](benchmarks/d/disjoint_sparse_table_affine_composition/README.md) answers static ordered range folds of affine maps in O(1) after preprocessing; ten ports and an independent direct-application oracle are registered in the byte-output suite.

[Deque operate all composite](benchmarks/d/deque_operate_all_composite/README.md) maintains affine-function composition across pushes and pops at both ends; its nine ports are registered in the scalar suite with a direct-list oracle. [Rectangle add point get](benchmarks/r/rectangle_add_point_get/README.md) supports dynamic half-open rectangle updates with point queries, while [static rectangle add rectangle sum](benchmarks/s/static_rectangle_add_rectangle_sum/README.md) handles a fixed update batch and rectangle-sum queries modulo 998244353. Both rectangle packages have ten ports and byte-output suite registration. [Static range LIS query](benchmarks/s/static_range_lis_query/README.md) provides strict LIS lengths over permutation subranges with a bounded per-query scan, while [static range inversions](benchmarks/s/static_range_inversions_query/README.md) answers strict inversion counts on arbitrary subranges using Mo ordering and a Fenwick tree. Both are registered in the byte-output suite.

[Range affine point get](benchmarks/r/range_affine_point_get/README.md) applies modular affine maps to ranges and reads individual positions through lazy propagation; it has ten language ports and byte-output suite registration. [Range affine range sum](benchmarks/r/range_affine_range_sum/README.md) combines affine range updates with range-sum queries in a lazy segment tree; its ten ports, direct-array oracle, and scalar-suite registration are in place.

[Range set range composite](benchmarks/r/range_set_range_composite/README.md) assigns one affine map across a range and composes the functions over queried ranges. Its ten language ports use lazy segment-tree tags for repeated affine composition, with byte-output suite registration.

[Point set range frequency](benchmarks/p/point_set_range_frequency/README.md) supports point assignments and exact-value frequency queries over half-open subranges. Its ten ports use coordinate-compressed, value-indexed Fenwick trees and are registered in the byte-output suite.

[Range reverse range sum](benchmarks/r/range_reverse_range_sum/README.md) applies implicit-sequence reversals and range-sum queries with a lazy implicit treap. Its ten language ports, bounded workload, and independent list-based oracles are registered in the byte-output suite.

[Range linear add range min](benchmarks/r/range_linear_add_range_min/README.md) applies index-linear additions and range-minimum queries using square-root blocks with lazy line tags and lower hulls. Its ten ports, direct-list oracle, and scalar-suite registration are in place.

[Persistent queue](benchmarks/p/persistent_queue/README.md) supports branching append/pop histories using a path-copied segment tree with version-specific head and tail offsets. Its ten ports, bounded workload, and copied-list oracle are registered in the byte-output suite.

[Dynamic sequence range affine range sum](benchmarks/d/dynamic_sequence_range_affine_range_sum/README.md) combines positional insertion/deletion, reversal, affine range updates, and range sums with a lazy implicit treap across ten languages; its byte-output suite registration and two list-based oracles are in place. [Dynamic point set rectangle affine rectangle sum](benchmarks/d/dynamic_point_set_rectangle_affine_rectangle_sum/README.md) combines online point activation, point assignment, rectangle sums, and rectangle affine maps in ten offline-coordinate k-d tree ports, with direct-list checking and byte-output registration.

[Persistent range affine range sum](benchmarks/p/persistent_range_affine_range_sum/README.md) adds branching historical affine updates, range copies, and range-sum queries with a path-copying lazy segment tree. It has ten ports, direct and independent snapshot oracles, and byte-output suite registration.

[Maximum independent set](benchmarks/m/maximum_independent_set/README.md) adds exact graph MIS using degree-based branching and a greedy clique-cover bound. It has ten ports, an independent subset-enumeration fixture oracle, and scalar-suite registration.

[Chromatic polynomial](benchmarks/c/chromatic_polynomial/README.md) returns all coefficients of a bounded graph's coloring polynomial using deletion–contraction. Ten language ports use an independent spanning-subgraph inclusion–exclusion oracle and are registered in the byte-output suite.

[Vertex add range contour sum on tree](benchmarks/v/vertex_add_range_contour_sum_on_tree/README.md) combines centroid decomposition with distance-indexed Fenwick buckets for point additions and contour-distance interval sums. It has ten ports, BFS-based independent oracles, and byte-output suite registration.

[Common interval decomposition tree](benchmarks/c/common_interval_decomposition_tree/README.md) constructs a bounded strong-interval decomposition of a permutation using exhaustive connected-interval and overlap checks. Ten ports, an independent certificate validator, and byte-output suite registration are present; the local profile is intentionally small and does not claim the official linear-time scale.

[Convex/convex min-plus convolution](benchmarks/m/min_plus_convolution_convex_convex/README.md) merges two nondecreasing discrete-slope sequences in linear time. Ten ports, a direct oracle, independent slope-merge checker, and byte-output suite registration are present.

[Convex/arbitrary min-plus convolution](benchmarks/m/min_plus_convolution_convex_arbitrary/README.md) uses Monge monotone divide-and-conquer minima for a discrete-convex input and an arbitrary sequence. Ten ports, direct and independent oracles, and byte-output suite registration are present.

[Concave/arbitrary min-plus convolution](benchmarks/m/min_plus_convolution_concave_arbitrary/README.md) handles the feasible-index staircase with rectangle partitioning and boundary scans, using monotone minima only on fully feasible blocks. Ten ports, an independent brute-force oracle, and byte-output suite registration are present.

[Multiplicative convolution modulo a prime](benchmarks/m/mul_modp_convolution/README.md) maps nonzero residues to cyclic exponents using a primitive root, then handles zero separately; the bounded profile uses `P <= 97` and a direct residue-pair oracle. [Multiplicative convolution modulo a power of two](benchmarks/m/mul_mod2n_convolution/README.md) enumerates products in `Z/2^N Z` for `N <= 5`, with an independent per-output scan. Both have ten ports and byte-output suite registration.

[General weighted matching](benchmarks/g/general_weighted_matching/README.md) computes a maximum-total-weight matching in a simple general graph with exact bitmask dynamic programming through `N <= 16`. Ten ports, a recursive independent checker, a certificate workload, and byte-output suite registration are present; this bounded profile does not claim weighted-blossom scale.

[General weighted matching by primal-dual blossom](benchmarks/g/general_weighted_matching_primal_dual_blossom/README.md) uses odd-blossom contraction and dual adjustment to maximize total matching weight through 64 vertices, complementing the smaller subset-DP profile.

[Multiplicative order](benchmarks/m/multiplicative_order/README.md) reduces φ(m) by its prime factors to find the least positive exponent for one supplied unit, with a direct repeated-power oracle and scalar-suite registration.

[Continued-fraction convergents](benchmarks/c/continued_fraction_convergents/README.md) emits each prefix numerator and denominator using recurrence updates, with nested-rational independent reference and bounded byte-output fixtures.
[Steed continued-fraction convergents](benchmarks/s/steed_continued_fraction_convergents/README.md) uses the DLMF forward D/deltaC recurrence over a finite field, with a homogeneous-pair reference and byte-output suite registration.

[Tree path composite sum](benchmarks/t/tree_path_composite_sum/README.md) reroots affine path-composition messages to report the sum from every possible tree root. Ten language ports, independent direct-path and composition-traversal oracles, bounded fixtures, and byte-output suite wiring are present; the dense-table implementation uses `O(N^2)` time for its local `N <= 32` profile.

[Tree decomposition width 2](benchmarks/t/tree_decomposition_width_2/README.md) recognizes bounded graphs by degree-two elimination and returns a checked tree-decomposition certificate. [Truncated multivariate convolution](benchmarks/m/multivariate_convolution/README.md) discards products outside the per-axis degree limits; [cyclic multivariate convolution](benchmarks/m/multivariate_convolution_cyclic/README.md) wraps coordinates modulo each axis. Both convolution profiles have ten ports and direct plus independent oracles. [Dynamic star-augmented global minimum cut](benchmarks/g/global_minimum_cut_of_dynamic_star_augmented_graph/README.md) recomputes cuts after spoke updates, with an exhaustive cut checker. [Rooted-tree topological order with minimum inversions](benchmarks/r/rooted_tree_topological_order_with_minimum_inversions/README.md) uses DSU ratio contractions and a subset-DP optimality checker. All five have byte-output suite registration and bounded local workloads.

[Linear-extension counting](benchmarks/l/linear_extension_count/README.md) counts all topological orders of a bounded poset by subset DP. A recursive minimal-element oracle with component interleaving independently checks exact counts; ten ports and scalar-suite registration are included.

[Bitwise XOR convolution](benchmarks/b/bitwise_xor_convolution/README.md) transforms both input arrays with the XOR Walsh–Hadamard transform, multiplies pointwise, then applies the inverse transform and normalization. Its ten ports are distinct from the standalone transform benchmark and have direct pair-enumeration and independent per-output oracles plus byte-output suite registration.

[Bitwise OR convolution](benchmarks/b/bitwise_or_convolution/README.md) computes the union-indexed modular convolution with subset zeta transforms, pointwise multiplication, and Möbius inversion. It is distinct from the AND and XOR products and from subset convolution; ten ports, direct and independent oracles, a bounded workload, provenance notes, and byte-output suite wiring are present.

[Knuth-optimized optimal binary search tree](benchmarks/k/knuth_optimized_optimal_binary_search_tree/README.md) applies monotone-root bounds to the same successful-search cost recurrence as the existing cubic profile, reducing root-search work from O(n^3) to O(n^2). Ten ports, a bounded workload, Knuth and cubic oracles, and scalar-suite registration are present.

[Broken-profile domino tilings](benchmarks/b/broken_profile_domino_tilings/README.md) counts open rectangular-board tilings with a frontier-mask DP, transposing to keep the profile width at most eight. Ten ports, small-board enumeration, an independent row-transition oracle, a bounded workload, and scalar-suite registration are present.

[Baum–Sweet sequence prefixes](benchmarks/b/baum_sweet_sequence/README.md) pack the first 0–63 terms of OEIS A086747 using a binary zero-run parity automaton. Ten ports, two independent references, workload fixtures, and `i64_array_scalar` runner/verifier dispatch are present in source; no executable checks were run.

[Coloured triangle reduction](benchmarks/c/coloured_triangle_reduction/README.md) uses a signed binomial transform modulo three with Lucas digit coefficients to return the final color in linearithmic time. Ten ports, a repeated-reduction reference, workload fixtures, and scalar-suite dispatch are integrated in source; no executable checks were run.

[Polydivisible prefix search](benchmarks/p/polydivisible_prefix_search/README.md) counts positive base-2-through-10 values by extending only prefixes that satisfy the current divisibility condition, bounded to six digits. Ten ports, an independent exhaustive reference, workload fixtures, and scalar-suite dispatch are integrated in source; no executable checks were run.

[Global balanced binary tree construction](benchmarks/g/global_balanced_binary_tree/README.md) builds the weighted-midpoint binary trees over each heavy path and joins their roots across light edges. Ten language ports, structurally independent construction references, bounded tree fixtures, and `i64_array_scalar` runner/verifier dispatch are included; no executable checks were run.

[Nonogram line-domain solver](benchmarks/n/nonogram_line_domain_solver/README.md) solves bounded monochrome puzzles by repeated line-domain support propagation and deterministic row branching. Ten ports, an independent row-tuple enumerator, and byte-output suite dispatch are integrated in source; no executable checks were run.

[Partially retroactive priority queue](benchmarks/p/partially_retroactive_priority_queue/README.md) replaces historical queue operations and reports the resulting count and sum after each update. Ten ports, a segment-tree primary reference, a heap-replay oracle, and byte-output suite dispatch are integrated in source. Its Library Checker task is still an open proposal, not a merged upstream problem.

[NegaFibonacci representation](benchmarks/n/negafibonacci_representation/README.md) encodes signed integers as canonical nonadjacent sums of negatively indexed Fibonacci weights. Ten ports, interval and exhaustive-mask references, workload fixtures, and byte-output suite dispatch are integrated in source; no executable checks were run.

[Monotone constant-interval partition](benchmarks/c/constant_intervals/README.md) emits maximal constant ranges of a monotone integer function using recursive endpoint pruning. Ten ports, threshold and direct-scan references, workload fixtures, and byte-output suite dispatch are integrated in source; no executable checks were run.

[Hanging-line largest rectangle](benchmarks/h/hanging_line_largest_rectangle/README.md) computes widest equal-or-higher histogram spans through prior-link jumps, distinct from the local monotone-stack method. Ten language ports, prior-link and quadratic references, workload fixtures, and scalar-suite dispatch are integrated in source; no programs or checks were run.

[Robinson–Schensted–Knuth row insertion](benchmarks/r/rsk_row_insertion/README.md) constructs and encodes the insertion and recording tableaux for bounded permutations. It is distinct from hook-length counting; ten language ports, forward and inverse references, fixtures, and `i64_array_scalar` suite dispatch are integrated in source. No executable checks were run.

[Small Multiple via shortest path modulo](benchmarks/s/shortest_path_modulo_small_multiple/README.md) finds the minimum digit sum of a positive 0/1-digit multiple using 0–1 BFS over residues. Ten language ports, an exhaustive bounded reference, workload fixtures, and scalar-suite dispatch are integrated in source; no executable checks were run.

[Dynamic centroid active-set diameter](benchmarks/d/dynamic_centroid_active_set_diameter/README.md) toggles vertices in a fixed tree and queries the diameter among active vertices using centroid ancestor and branch maxima. Ten language ports, a direct all-pairs reference, workload fixtures, and scalar-suite dispatch are integrated in source; no executable checks were run.

[Fenwick tree in block array](benchmarks/f/fenwick_tree_in_block_array_rectangle_count/README.md) handles online point-y updates and rectangle counts with blocked x-coordinates, per-block y-Fenwick trees, and an outer Fenwick tree. Ten language ports, a direct-scan reference, workload fixtures, and scalar-suite dispatch are integrated in source; no executable checks were run.

[Divide-and-combine tree construction](benchmarks/d/divide_combine_tree_incremental/README.md) builds the primitive common-interval tree incrementally with a range-minimum segment tree and monotone extrema stacks, a faster construction variant of the local exhaustive profile. Ten ports, incremental and exhaustive references, workload fixtures, and scalar-suite dispatch are integrated in source; no executable checks were run.

[Fenwick weighted segment trees for dynamic range k-th](benchmarks/f/fenwick_weighted_segment_tree_range_kth/README.md) supports point replacement and range-order-statistic queries by descending weighted value trees rooted at Fenwick positions. It is distinct from the local static persistent-segment-tree profile. Ten language ports, a direct update-and-sort reference, workload fixtures, and scalar-suite dispatch are integrated in source; no executable checks were run.

[Rabin content-defined chunking](benchmarks/r/rabin_content_defined_chunking/README.md) computes byte boundaries from a rolling four-byte GF(2) fingerprint. Ten language ports remove the outgoing contribution before each shift; rolling and per-window references, fixtures, a static inventory checker, and byte-output suite wiring are included. No programs or checks were run.

[Statistical region merging with supplied bounds](benchmarks/s/statistical_region_merging_table/README.md) merges grayscale grid regions in stable edge order using an exact squared-mean predicate and a caller-supplied size-bound table. Ten ports, DSU and exact-rational references, fixtures, a static package checker, and byte-output suite wiring are included. No executable checks were run.

[Fixed-cardinality combinations in Gray order](benchmarks/g/gray_code_k_combinations/README.md) emits every k-subset in a cyclic minimal-change sequence, distinct from lexicographic fixed-size combinations and all-subsets Gray code. Ten language ports, filtered and recursive references, bounded fixtures, a static package checker, and byte-output suite wiring are integrated in source; no executable checks were run.

[Fixed-size subset colex rank and unrank](benchmarks/k/k_subset_colex_rank_unrank/README.md) maps between a k-subset and its combinadic rank, distinguishing the colex bijection from lexicographic and Gray-order enumeration.

[Singly-even magic square by Strachey's construction](benchmarks/m/magic_square_singly_even_strachey/README.md) fills the order-6-mod-4 gap beside the existing odd-order Siamese `magic_square`. Ten ports, stepwise and modular-inverse references, boundary fixtures, a static inventory checker, and `scalar_call` suite wiring are integrated in source; no executable checks were run.

[Doubly-even magic square by diagonal complements](benchmarks/m/magic_square_doubly_even_complement/README.md) constructs orders divisible by four with row-major filling and the repeating 4×4 diagonal-complement mask. Ten language ports, cellwise and mask-table/invariant references, bounded workload, and `scalar_call` suite registration are included.

[Jacobson–Matthews Latin-square chain](benchmarks/j/jacobson_matthews_latin_square_chain/README.md) follows proper and improper one-hot 3D states with caller-supplied move ranks, exposing the transition kernel without claiming a random sampler.

[Hofstadter Figure–Figure sequences](benchmarks/h/hofstadter_figure_figure_sequences/README.md) return both complementary integer-sequence prefixes from the greedy additive recurrence, with ten language ports and a bounded byte-output profile.

[Maximum-sum contiguous submatrix](benchmarks/m/maximum_sum_contiguous_submatrix/README.md) compresses each row band and applies Kadane's algorithm across columns, covering nonempty rectangles in a bounded matrix.

[Glushkov bit-parallel regex search](benchmarks/g/glushkov_bit_parallel_regex_search/README.md) compiles a bounded regex to an epsilon-free position automaton and tracks its subsets with bit-parallel transitions. It is distinct from Thompson NFA simulation and the local source-compatible regex engines. Ten language ports, position-set and direct AST references, bounded fixtures, a static package checker, and byte-output suite wiring are integrated in source; no executable checks were run.

[Van der Corput sequence](benchmarks/v/van_der_corput_sequence/README.md) returns exact unreduced radical-inverse fractions for bounded base/index windows. Its digit reflection is distinct from the integer recurrence in `van_ecks_sequence`; ten ports, dual references, workload and static inventory are wired to the byte-output suite in source.

[Exact deterministic MDP policy iteration](benchmarks/m/mdp_policy_iteration/README.md) evaluates fixed policies as exact rational values, then improves actions until stable. It differs from fixed-sweep value iteration, model-free Q-learning, and minimum-cycle-mean policy iteration. Ten ports, an exhaustive-policy verifier, bounded workload and byte-output suite integration are present in source; no executable checks were run.

The [SPLASH-2-inspired water profiles](benchmarks/s/splash2_water_nsquared/README.md) share a bounded rational molecule-pair law and byte output. [`splash2_water_nsquared`](benchmarks/s/splash2_water_nsquared/README.md) scans all pairs; [`water_spatial`](benchmarks/w/water_spatial/README.md) builds uniform cells and searches clipped neighbor cells. Each has ten ports and independent oracle coverage; neither claims to reproduce the full molecular-dynamics application.

[Incremental XOR linear basis](benchmarks/x/xor_linear_basis/README.md) maintains a 63-pivot basis for insertions, maximum-subset-XOR queries, and representability checks. Ten ports, exhaustive-subset primary and independent checkers bounded to 16 insertions, and byte-output suite wiring are present.

[GraphAIBench gated graph-message update](benchmarks/g/graphai_ggnn_message_update/README.md) sums each vertex's outgoing neighbor states, applies reset/update gates and a recurrent candidate using six supplied matrices, and emits the next node states. Nine standard-language ports plus Mojo are wired into the float64 slice suite.

[Kahan compensated summation](benchmarks/k/kahan_summation/README.md) processes ordered binary64 values with a running correction term. Ten ports, an exact-step independent verifier, and float64 slice suite registration are present.

[Shewchuk expansion summation](benchmarks/s/shewchuk_expansion_sum/README.md) uses error-free Two-Sum transforms and Grow-Expansion to recover an exact bounded dyadic sum. Its offset encoding keeps every valid result distinct from malformed-input output; ten ports and scalar-suite registration are included.

[Lengauer–Tarjan immediate dominators](benchmarks/l/lengauer_tarjan_dominator_tree/README.md) uses DFS semidominators and path-compressed `LINK`/`EVAL`, alongside the existing bitset fixed-point dominator-tree benchmark. Ten ports, a vertex-removal oracle, bounded workload, and byte-output suite registration are present.

[Half-plane intersection](benchmarks/h/half_plane_intersection/README.md) constructs the exact rational convex region cut out by up to twelve primitive integer inequalities inside a fixed bounding square. Ten ports use angle sorting and deque pruning; an independent pair-intersection and convex-hull oracle and byte-output suite profile are included.

[Symbolic circle-line intersection](benchmarks/c/circle_line_intersection_symbolic/README.md) constructs exact intersection coordinates using an integer radicand, extending the existing count-only profile. Ten ports and suite wiring are drafted and unverified.

[Symbolic circle-circle intersection](benchmarks/c/circle_circle_intersection_symbolic/README.md) constructs exact common points of two circles and distinguishes coincident circles. Its ten ports and suite wiring are drafted and unverified.

[Incremental half-plane clipping](benchmarks/h/half_plane_intersection_incremental_clipping/README.md) constructs the same bounded region by clipping a polygon in input order, with ten draft ports and suite wiring. The profile remains unverified.

[Integer convex-region inradius](benchmarks/c/convex_polygon_integer_inradius/README.md) searches for the largest integer disk radius using offset half-planes, including point and segment optima. Its ten ports and scalar-suite wiring are drafted and unverified.

[SMAWK row minima](benchmarks/s/smawk_row_minima/README.md) finds the leftmost minimum of every row in a promised totally monotone matrix using column reduction, recursive odd-row minima, and interpolation. Ten ports, an independent row-scan oracle, bounded fixtures, and byte-output suite registration are present.

[Minimum-cost max-flow with tight-edge blocking flow](benchmarks/m/min_cost_max_flow_blocking_paths/README.md) recomputes shortest residual distances and sends blocking flow over tight arcs. Ten ports share the existing reduced-cost shortest-path contract; a Bellman–Ford successive-path oracle and byte-output suite registration are included.

[Convex polygon point-membership queries](benchmarks/p/point_in_convex_polygon_log_query/README.md) rotate a strictly convex polygon to a canonical pivot and binary-search its radial fan for each query. Ten ports, an independent linear edge scan, bounded workloads, and byte-output suite registration are included.

[Legendre prime counting](benchmarks/l/legendre_prime_count/README.md) evaluates the partial-sieve formula through `x = 10,000`. Ten ports, an independent direct-sieve oracle, bounded scalar fixtures, and scalar-suite registration are included.

[Finite discrete rejection sampling](benchmarks/d/discrete_rejection_sampling/README.md) replays a supplied proposal and acceptance-draw tape against integer target weights using an exact integer envelope. Ten ports, an independent oracle, an explicit exhaustion result, bounded byte-output cases, and suite registration are included.

[Brent–Kung formal power-series composition](benchmarks/b/brent_kung_fps_composition/README.md) computes `f(g) mod x^N` with baby-step/giant-step blocks over `F_998244353`, distinct from the existing descending-Horner composition. Ten ports, independent Horner verification, bounded workloads, and byte-output suite registration are included.

[Exact graph Steiner tree by terminal-subset DP](benchmarks/p/steiner_tree_subset_dp/README.md) finds the minimum weight connecting a bounded terminal set using subset merges and multi-source shortest-path relaxation. It differs from the finite-family gain-greedy approximation. Ten ports, an independent edge-subset oracle, bounded workload, and scalar-array suite registration are included.

[Mehlhorn Steiner tree by Voronoi and sparse terminal MST](benchmarks/s/steiner_tree_mehlhorn_voronoi_mst/README.md) adds a distinct approximation construction using nearest-terminal regions, minimum crossing-edge witnesses, a terminal MST, path expansion, and nonterminal-leaf pruning. Ten native ports, independent references, bounded workloads, and byte-output suite registration are integrated.

[Create Maximum Number](benchmarks/c/create_maximum_number/README.md) chooses the lexicographically greatest length-`k` digit sequence from two ordered sources using split enumeration, monotone subsequence selection, and suffix-aware merging. Ten ports, an independent skip/take oracle, bounded workload, and byte-output suite registration are included.

[Minimum-spanning-tree edge classification](benchmarks/m/mst_edge_classification/README.md) labels every edge as absent from all, present in some, or present in every minimum spanning tree. Ten ports use equal-weight Kruskal groups and edge-ID-aware quotient bridges; an independent force/forbid Kruskal oracle and byte-output suite profile are included.

[Two-dimensional trapped rainwater](benchmarks/t/trapping_rain_water_ii/README.md) computes retained volume using a min-heap flood from boundary cells. Ten ports, an independent per-cell threshold/BFS oracle, bounded grid workloads, and scalar-array suite registration are included.

[Planar face counting](benchmarks/p/planar_face_count/README.md) validates a bounded connected planar straight-line graph, orders each vertex's neighbors by polar angle, and traverses directed-edge face orbits. Ten language ports, an independent Euler-characteristic oracle, bounded fixtures, and scalar-array suite registration are included.

[Hash join](benchmarks/h/hash_join/README.md) joins two bounded integer-key relations by hashing the smaller side and retaining duplicate row IDs in input order. Ten language ports, an independent nested-loop oracle, bounded byte-output workloads, and suite registration are included.

[Dynamic MEX with point updates](benchmarks/d/dynamic_mex_updates/README.md) maintains candidate-value frequencies and a segment tree to report the minimum excluded value after each replacement. Ten ports, an independent direct-scan oracle, bounded workloads, and byte-output suite registration are included.

[Bishop placement count](benchmarks/b/bishop_placements_count/README.md) counts exact nonattacking bishop placements by splitting the board's diagonals by square color and combining the two counts. Ten language ports, an independent diagonal-mask oracle, bounded scalar workloads, and suite registration are included.

[Goldberg exact maximum-density subgraph](benchmarks/g/goldberg_maximum_density_subgraph/README.md) uses binary search and min cuts to return the exact reduced density of a densest induced vertex subset. It complements the existing approximation profiles; ten language ports, an exhaustive subset oracle, and scalar-suite registration are included.

[Karp minimum directed cycle mean](benchmarks/m/minimum_mean_cycle_karp/README.md) returns the exact reduced mean weight of a minimum-mean cycle using exact-length path dynamic programming. Ten ports, an independent simple-cycle enumeration oracle, and byte-output suite registration are included.

[Howard minimum mean cycle](benchmarks/m/minimum_mean_cycle_howard/README.md) uses exact-rational policy iteration over selected outgoing edges, giving a distinct method comparison with Karp's exact-length path dynamic program. Ten ports passed static review.

[Horton minimum cycle basis](benchmarks/m/minimum_cycle_basis_horton/README.md) builds shortest-path-tree candidates and greedily extracts a minimum-weight GF(2) cycle basis. A symbolic path perturbation handles ties while preserving original basis weights; ten ports and scalar-suite registration are included.

[Johnson's two-machine flow shop](benchmarks/j/johnson_two_machine_flow_shop/README.md) orders jobs on both machines to minimize makespan using Johnson's partition-and-sort rule. Ten ports, an independent exhaustive-permutation oracle, bounded workloads, and scalar-array suite registration are included.

[Undirected Chinese postman](benchmarks/u/undirected_chinese_postman/README.md) finds the shortest closed route covering every edge by pairing odd-degree vertices in the shortest-path metric. Ten ports, an independent edge-coverage-state oracle, bounded workloads, and scalar-array suite registration are included.

[All shortest paths in an unweighted graph](benchmarks/a/all_shortest_paths_unweighted/README.md) enumerates every lexicographically ordered shortest path through a BFS predecessor DAG. Ten ports, an independent Floyd-Warshall oracle, bounded output/workspace profiles, and byte-output suite registration are included.

[Maximum number of jobs before deadlines](benchmarks/d/max_jobs_before_deadlines/README.md) chooses the largest feasible subset of arbitrary-duration jobs using reverse deadline intervals and a min-heap of residual durations. Ten ports, an independent subset/EDF oracle, bounded workloads, and scalar-array suite registration are included.

[Connected labeled graph count](benchmarks/c/connected_labeled_graph_count/README.md) counts connected simple undirected graphs on a labeled vertex set modulo 998244353 using the rooted-component recurrence, with an independent EGF formal-series oracle. Ten ports and bounded scalar-suite registration are included.

[Bostan–Mori recurrence term](benchmarks/b/bostan_mori_recurrence_term/README.md) extracts a distant term by parity-selecting numerator and denominator coefficients while halving the index. Ten ports, an independent companion-matrix oracle, and scalar-suite registration cover orders through eight and indices through 10^18.

[Common tangents to two circles](benchmarks/c/common_tangents_two_circles/README.md) counts distinct shared tangent lines with exact signed-radius discriminants, including degenerate point circles and coincident tangency cases. Ten ports, an independent squared-distance oracle, and scalar-suite profiles are included.

[Circle-line intersection counts](benchmarks/c/circle_line_intersection_count/README.md) classify each bounded integer line as missing, tangent to, or crossing a circle using exact discriminants. Ten ports, an independent line-parameter oracle, and byte-output suite registration are included.

[Circle-circle intersection counts](benchmarks/c/circle_circle_intersection_count/README.md) use the radical axis and an exact discriminant to classify disjoint, tangent, two-point, and coincident circles. Ten ports, an independent squared-distance oracle, and scalar-suite registration are included.

[Circle–polygon intersection area](benchmarks/c/circle_polygon_intersection_area/README.md) sums oriented sector and triangle contributions along a strictly convex polygon's edges. Ten ports, an independent polar-integration reference, and `i64_array_float64` suite registration are included.

[Circular mean direction](benchmarks/c/circular_mean_direction/README.md) returns the conventional resultant direction of bounded radian samples, with compensated sums and an independent Decimal trigonometric reference. Ten ports and `float64_slice_io` runner/verifier wiring are included.

[Two-dimensional rolling-hash rectangle queries](benchmarks/r/rolling_hash_2d_rectangle_query/README.md) uses a polynomial prefix table and four-corner extraction for half-open subgrid queries. Ten ports, an independent direct weighted-cell reference, and byte-output suite registration are included.

[Three-dimensional Bird–Baker matching](benchmarks/t/three_dimensional_bird_baker_matching/README.md) reduces each distinct pattern slice to row-match labels, then runs KMP over those labels along depth. Ten language ports, independent 3D cell matching, bounded byte-output fixtures, and suite registration are included; the [2D Bird–Baker profile](benchmarks/t/two_dimensional_string_matching/README.md) is its lower-dimensional base.

[Two-dimensional optimal-expected exact matching](benchmarks/t/two_dimensional_optimal_expected_matching/README.md) uses a static grid of test points, overlapping linear templates, and exact verification of distinct candidates. Ten language ports, a direct independent reference, bounded byte-output fixtures, and byte-output suite registration are included. It is distinct from the 2D Bird–Baker row reduction.

[Cupif–Giannini perfect-tree traversal](benchmarks/c/cupif_giannini_tree_traversal/README.md) visits implicit perfect-binary-tree leaves in count-XOR-key order and emits their low-bit-first path codes. It is distinct from arbitrary-tree XOR leaf peeling; ten ports and byte-output suite registration are included.

[Position-only Störmer–Verlet integration](benchmarks/s/stormer_verlet_position/README.md) advances positions with the two-position recurrence and supplied acceleration terms. It differs from the existing velocity-Verlet state update; ten ports, a closed-form independent reference, and byte-output suite registration are included.

[Two-dimensional one-mismatch linear-template matching](benchmarks/t/two_dimensional_k_mismatch_linear_templates/README.md) reports square windows within Hamming distance one using two periodic test rows, a linear-template witness filter, and exact bounded verification. It complements the exact 2D matcher with a distinct approximate result; ten ports and byte-output suite registration are included.

[Tree center by leaf peeling](benchmarks/t/tree_center/README.md) returns the one or two vertices with minimum eccentricity. Ten ports, an independent all-sources BFS reference, and byte-output suite registration are included.

[Tree center by rerooting DP](benchmarks/t/tree_center_rerooting_dp/README.md) computes each vertex's eccentricity from its best downward branches and best outside-subtree distance. It is distinct from the leaf-peeling implementation; ten ports, an independent all-sources BFS reference, and byte-output suite registration are included.

[PMR edge quadtree construction](benchmarks/p/pmr_edge_quadtree/README.md) incrementally inserts line segments into every intersected cell, splitting overfull leaves and redistributing their segments. It indexes edges, unlike the local point-oriented quadtree.

[Seven-sided dice from five-sided dice](benchmarks/s/seven_sided_dice_from_five_sided_dice/README.md) recycles accepted quotient entropy and rejected tail states from a bounded base-5 draw tape to produce uniform faces 1–7. Ten ports, independent interval-bucket reference, finite-tape fixtures, and byte-output suite registration are included. It is distinct from `unbias_01`, which extracts one fair bit from biased binary pairs.

[Fixed-edge shortest path in a Monge DAG](benchmarks/m/monge_dag_fixed_edge_shortest_path/README.md) finds the minimum-cost path with exactly `D` edges by applying monotone divide-and-conquer row minima to each exact-edge DP layer. Its triangular Monge input and predecessor-scan reference distinguish it from explicit-graph min-plus powers and general SMAWK row minima. Ten ports, fixtures, and scalar-suite registration are included.

[Functional graph cycle parameters](benchmarks/f/functional_graph_cycle_parameters/README.md) finds the preperiod and eventual cycle length from one node in a bounded successor map using constant-space tortoise-and-hare traversal. Ten ports, an independent first-seen-table oracle, workload fixtures, and scalar-suite registration are included.

[Functional graph cycle parameters by Brent's method](benchmarks/f/functional_graph_cycle_brent/README.md) solves the same map contract with power-of-two checkpoint blocks, then measures the cycle entry from a period offset. Its traversal and successor-evaluation pattern is distinct from Floyd's two-speed method.

[Largest zero submatrix](benchmarks/l/largest_zero_submatrix/README.md) updates per-column blocker heights for each binary-matrix row and uses monotone stacks to find the largest all-zero rectangle. Ten ports, an independent exhaustive rectangle oracle, and scalar-suite registration are included.

[Maximum frequency stack](benchmarks/m/maximum_frequency_stack/README.md) removes an online value with highest current frequency, breaking ties by its latest active push. Ten ports, an independent active-list rescan oracle, bounded byte-output workloads, and suite registration are included.

[Balanced ternary conversion](benchmarks/b/balanced_ternary_conversion/README.md) converts any signed 64-bit integer to canonical radix-three digits `Z`, `0`, and `1`. Ten ports, independent signed-remainder and carry oracles, bounded byte-output workloads, and suite registration are included.

[Tree edge painting and path counts](benchmarks/t/tree_edge_paint_path_count/README.md) supports idempotent edge paints and arbitrary path queries on a bounded tree. Ten ports use directional Euler-tour segment trees with LCA path splitting; an independent BFS oracle reconstructs each path. Scalar-suite registration is included.

[Online temporary-task load balancing](benchmarks/o/online_temporary_task_load_balancing/README.md) assigns each arriving temporary task to a least-loaded machine after expiring completed tasks, then reports peak active load and assignments. Ten ports, independent expiration-heap and history-replay oracles, bounded byte-output workloads, and suite registration are included.

[Convolution over GF(2^64)](benchmarks/c/convolution_f2_64/README.md) computes carryless polynomial convolution modulo `x^64+x^4+x^3+x+1`, treating each i64 input bit pattern as a u64 field element. Ten ports, independent shift/reduce and polynomial-division oracles, bounded byte-output workloads, and suite registration are included.

[Convex-polygon minimax-length triangulation](benchmarks/c/convex_polygon_minimax_length_triangulation/README.md) minimizes the longest edge over triangulations of a strictly convex integer polygon. Ten ports use interval minimax dynamic programming; an independent exhaustive enumerator checks the small bounded profile, which is registered in the scalar suite.

[Convex-polygon max-min-length triangulation](benchmarks/c/convex_polygon_max_min_length_triangulation/README.md) uses Hu's exact 60-degree corner-cut rule to maximize the shortest triangulation edge. The packed scalar contains the squared optimum and the deterministic diagonal mask, so the greedy triangulation is observable; all ten ports are registered in the scalar suite.

[Convex-polygon min-max-angle edge insertion](benchmarks/c/convex_polygon_minimax_angle_edge_insertion/README.md) applies the worst-angle edge-insertion step to strict convex triangles and quadrilaterals with exact integer angle comparisons; its ten ports are registered in the scalar suite.

[Max-min triangle-height triangulation](benchmarks/m/max_min_triangle_height_triangulation/README.md) maximizes the least triangle altitude over strict convex polygons with at most five vertices using exact rational edge insertion; all ten ports are registered in the scalar suite.

[Convex-polygon minimax-slope edge insertion](benchmarks/c/convex_polygon_minimax_slope_edge_insertion/README.md) minimizes the largest squared slope of a lifted triangulation on bounded strict-convex inputs. Its ten ports use exact rational comparisons, with an independent exhaustive triangulation reference; the profile is registered in the scalar suite.

[Convex-polygon min-max eccentricity edge insertion](benchmarks/c/convex_polygon_minimax_eccentricity_edge_insertion/README.md) minimizes the largest triangle eccentricity using exact squared-rational scores and bounded edge insertion. Ten language ports, an exhaustive independent reference, and scalar-suite registration are included.

[Fractional cascading on a nested catalog chain](benchmarks/f/fractional_cascading_subset_chain/README.md) performs batched successor searches across nested sorted catalogs using parent-to-child bridge tables. Ten ports, independent bridge and per-catalog references, and scalar-suite registration are included; the contract is a bounded path specialization, not the full catalog-graph construction.

[Priority search tree three-sided reporting](benchmarks/p/priority_search_tree_three_sided_reporting/README.md) uses McCreight's radix x-splits and y-priority invariant to report points in a closed x-range below a y threshold. Ten ports, a direct-scan reference, and scalar-suite registration are present.

[DAG minimum path cover](benchmarks/d/dag_minimum_path_cover/README.md) reduces a simple directed acyclic graph to bipartite matching and reconstructs a canonical minimum vertex-disjoint path cover. Ten language ports, an independent subset-DP reference, and scalar-suite registration are present.

[Pfaffian of an alternating matrix](benchmarks/p/pfaffian_of_matrix/README.md) computes the Pfaffian modulo 998244353 for bounded alternating matrices. Ten ports use pivoted elimination; an independent pairing-mask recurrence verifies the scalar profile, which is registered in the scalar suite.

[Static x-fast trie predecessor](benchmarks/x/x_fast_trie_static_predecessor/README.md) answers bounded batches of integer predecessor queries using prefix-level catalogs and longest-existing-prefix search. Ten ports, an independent sorted-array oracle, and scalar-suite registration are included; the profile does not claim the classic expected `O(log log U)` bound.

[Static y-fast trie strict neighbors](benchmarks/y/y_fast_trie_static_predecessor/README.md) uses a binary trie over small sorted clusters to answer strict predecessor and successor queries. Ten language ports, independent trie-based and sorted-array oracles, workload checks, and scalar-suite registration are included. The deterministic 16-bit profile separates cluster selection from in-cluster search and does not claim the randomized classic expected bound.

[Fixed-point HITS hub-authority ranking](benchmarks/h/hits_fixed_point/README.md) alternates incoming-link authority and outgoing-link hub updates on a directed graph. Ten language ports use deterministic integer normalization, with an independent dense-matrix oracle and scalar-suite registration; this ranking recurrence differs from PageRank.

[Two-dimensional Mo rectangle frequency queries](benchmarks/m/mo_2d_rectangle_frequency_square/README.md) schedules static matrix rectangles by all four boundaries and maintains the sum of squared value frequencies as the active rectangle moves. Ten language ports, a direct-scan verifier, workload checks, and scalar-suite registration are included. It is distinct from the existing one-dimensional Mo range-query profile.

[Dinkelbach fixed-cardinality maximum ratio](benchmarks/d/dinkelbach_fixed_cardinality_ratio/README.md) uses exact residual sorting and rational updates to maximize a ratio over exactly `K` selected items. Ten ports, an exhaustive subset oracle, bounded fixtures, and scalar-suite registration are included; it is distinct from fractional knapsack and minimum-mean-cycle algorithms.

[Fractional programming by ratio bisection and denominator knapsack](benchmarks/f/fractional_programming_ratio_knapsack_binary_search/README.md) maximizes a sum ratio over subsets meeting a minimum denominator threshold. It uses a transformed-score 0/1 knapsack feasibility DP inside integer ratio bisection, distinct from the fixed-cardinality Dinkelbach method.

[D* Lite incremental replanning](benchmarks/d/d_star_lite_incremental_replanning/README.md) maintains `g`/`rhs` consistency while the start moves and directed edge costs change. Ten ports use a deterministic bounded open set; a fresh Floyd–Warshall oracle independently recomputes each snapshot. This is distinct from the static A* and Dijkstra profiles.

[Fourier–Motzkin feasibility](benchmarks/f/fourier_motzkin_feasibility/README.md) eliminates variables from small real linear-inequality systems using exact integer combinations. Ten language ports, an independent exact-vertex oracle, bounded fixtures, and scalar-suite registration are included.

[Fiduccia–Mattheyses hypergraph bipartitioning](benchmarks/f/fiduccia_mattheyses_hypergraph_bipartitioning/README.md) performs deterministic one-vertex gain-bucket passes with balance limits and strict best-prefix acceptance. Ten ports, direct-rescoring and cut-recount oracles, bounded fixtures, and scalar-suite registration are included; this differs from Kernighan–Lin's paired swaps.

[Hypergraph incidence-graph encoding](benchmarks/h/hypergraph_incidence_graph_encoding/README.md) converts an indexed hyperedge family into a two-colored bipartite graph, preserving empty and equal hyperedges as distinct nodes. Ten ports, independent list and matrix references, fixtures, and byte-output suite registration are included; this is a representation transform, not graph isomorphism or hypergraph partitioning.

[Louvain multilevel community detection](benchmarks/l/louvain_multilevel_community_detection/README.md) repeatedly moves vertices to neighboring communities for exact positive modularity gain, then aggregates communities into weighted supernodes. Ten ports, quotient-matrix and original-graph oracles, deterministic tie rules, bounded fixtures, and scalar-suite registration are included.

[Dirichlet convolution and prefix sums](benchmarks/d/dirichlet_convolution_and_prefix_sums/README.md) computes convolution-prefix values over the floor-quotient set `Q_N` from cumulative function values. Ten ports use two quotient-interval groupings with structurally independent oracles; the bounded byte-output profile is registered in the suite.

[Blocked right-looking LU factorization](benchmarks/b/blocked_lu_factorization/README.md) uses a serial block-width-two schedule and trailing Schur updates. Ten ports and float64-slice suite registration are included; its bounded internal workspace is 2560 bytes.

[15-puzzle solvability](benchmarks/f/fifteen_puzzle_solvability/README.md) classifies a 4×4 board by the inversion/blank-row parity invariant, without searching for a move sequence. Ten ports, independent permutation-cycle and checkerboard-color verification, and scalar-suite registration are included.

[Binomial coefficients modulo prime powers](benchmarks/b/binomial_coefficient_prime_power/README.md) use p-adic factorial cancellation and invert only p-free units. Ten ports, an independent Pascal-row oracle, bounded byte-output workloads, and suite registration are included.

[Minimum queue with two stacks](benchmarks/m/minimum_queue_two_stacks/README.md) maintains FIFO order and constant-time minimum queries with two prefix-minimum stacks. Ten ports, a direct FIFO oracle, bounded workloads, and scalar-suite registration are included.

[Adaptive Simpson quadrature](benchmarks/a/adaptive_simpson_quadrature/README.md) refines only intervals whose local Simpson error estimate exceeds tolerance, with a correction on accepted intervals. Ten ports, a closed-form oracle, bounded workloads, and float64-suite registration are included.

[Parallel binary search for range-threshold crossings](benchmarks/p/parallel_binary_search_range_threshold/README.md) batches monotone earliest-prefix queries by midpoint and replays range additions through Fenwick trees. Ten ports, independent replay-and-scan verification, bounded workloads, and scalar-suite registration are included.

[Mergeable and splittable segment tree](benchmarks/s/segment_tree_merge_split/README.md) maintains sparse value-domain multisets with destructive root merges and interval extraction. Ten language ports, an independent count-array oracle, bounded byte-output workloads, and suite registration are included.

[SMO dual pair update](benchmarks/s/smo_dual_pair_update/README.md) performs one analytic linear-kernel SVM dual update for a supplied coefficient pair and bias. Ten language ports, an independent restricted-objective oracle, bounded ABI fixtures, and float64-suite registration are included; this is a training primitive, not a full classifier.

[Deterministic bounded SMO training](benchmarks/s/smo_deterministic_training/README.md) implements the full linear-SVM training loop with deterministic working-pair selection and a finite pass cap. It is distinct from the single-pair update primitive and projected-gradient classifier.

[CDQ 3D dominance counts](benchmarks/c/cdq_three_dimensional_dominance/README.md) counts weakly dominated points with multiplicity-weighted Fenwick queries and y-ordered CDQ merges. Ten ports, a direct ordered-pair oracle, bounded fixtures, and scalar-suite registration are included.

[Distinct palindromic subsequences](benchmarks/c/count_different_palindromic_subsequences/README.md) counts distinct nonempty palindrome sequences over a bounded four-symbol alphabet. Ten ports, duplicate-aware interval DP, an independent mask enumerator, bounded workloads, and scalar-suite registration are included.

[Palindrome pairs](benchmarks/p/palindrome_pairs/README.md) enumerates ordered word-index pairs whose concatenation is palindromic, including empty and duplicate words. Ten ports, split-and-lookup and direct-concatenation oracles, bounded byte-output workloads, and byte-suite registration are included.

[Dormand–Prince adaptive ODE solver](benchmarks/d/dormand_prince_54_adaptive_ode/README.md) integrates four bounded scalar ODEs with the adaptive 5(4) Runge–Kutta pair, accept/reject control, and FSAL reuse. Ten ports, an independent closed-form verifier, bounded float64 workloads, and float64-suite registration are included.

[Dial bucket shortest paths](benchmarks/d/dial_bucket_shortest_paths/README.md) computes directed shortest-path distances with a nine-slot cyclic bucket queue for weights from zero to eight. Ten ports, an independent Floyd–Warshall oracle, bounded byte-output workloads, and byte-suite registration are included.

[Bareiss fraction-free determinant](benchmarks/b/bareiss_determinant/README.md) computes exact small integer determinants using pivoted fraction-free elimination. Ten ports, an independent signed-permutation expansion, bounded matrix workloads, and scalar-suite registration are included.

[Monotone convex hull trick](benchmarks/m/monotone_convex_hull_trick/README.md) answers sorted minimum-line queries with a decreasing-slope lower hull and front advancement. Ten ports, a direct all-lines oracle, bounded workloads, and scalar-suite registration are included.

[Bounded knapsack with a monotone queue](benchmarks/b/bounded_knapsack_monotone_queue/README.md) solves exact multiplicity-limited knapsack by residue-class sliding maxima. Ten ports, a direct-count independent oracle, bounded workloads, and scalar-suite registration are included.

[Aho–Corasick failure-tree counts](benchmarks/a/aho_corasick_failure_tree_counts/README.md) counts overlapping pattern occurrences by aggregating state visits from failure children to parents. Ten ports, a direct substring-scan oracle, bounded byte-output workloads, and byte-suite registration are included.

[Pollard p−1 factorization](benchmarks/p/pollard_p_minus_one_factorization/README.md) applies successive maximal prime-power exponents and gcd checks to find factors with smooth predecessors. Ten ports, an independent big-exponent oracle, bounded workloads, and scalar-suite registration are included.

[Fermat factorization](benchmarks/f/fermat_factorization/README.md) searches bounded difference-of-squares candidates for a proper factor of an odd integer. Ten ports, an independent divisor-pair oracle, bounded workloads, and scalar-suite registration are included; the profile differs from trial division, Pollard rho, and Pollard p−1.

[Generalized Chinese remainder theorem](benchmarks/g/generalized_chinese_remainder_theorem/README.md) solves bounded congruence systems with shared factors by consolidating prime powers before CRT combination. Ten ports, a separate extended-gcd merge oracle, conflict fixtures, and scalar-suite registration are included; it extends the pairwise-coprime [`chinese_remainder_theorem`](benchmarks/c/chinese_remainder_theorem/README.md) contract.

[Edge connectivity by all-pairs max flow](benchmarks/e/edge_connectivity_all_pairs_maxflow/README.md) returns the minimum unit-capacity s–t maximum-flow value over all unordered terminal pairs in a small undirected graph. Ten ports, an independent cut-enumeration oracle, bounded workloads, and scalar-suite registration are included.

[Edge-colored graph layer encoding](benchmarks/e/edge_colored_graph_layer_encoding/README.md) reduces a simple edge-colored graph to a vertex-colored graph by copying edges into color-bit layers and joining each vertex's copies as a path. Ten ports, independent references, bounded byte-output fixtures, and suite registration are included; it is distinct from hypergraph incidence encoding.

[Ratcliff/Obershelp Gestalt similarity](benchmarks/r/ratcliff_obershelp_similarity/README.md) recursively matches longest common substrings and scores the total matched length. Ten ports and independent dynamic-programming/direct-search references are registered in the scalar suite; the recursive decomposition differs from standalone longest-common-substring and edit-distance algorithms.

[Adaptive Gauss–Kronrod 15-point quadrature](benchmarks/a/adaptive_gauss_kronrod_15_quadrature/README.md) estimates integrals with an embedded Gauss-7/Kronrod-15 pair and repeatedly splits the interval with the largest estimated error. Ten ports, closed-form verification, bounded interval work, and float64-suite registration are included.

[Factoring-based exponentiation](benchmarks/f/factoring_exponentiation/README.md) computes `a*x^y mod 2^d` with a 2-adic logarithm and exponent reconstruction. Ten ports, an independent repeated-squaring oracle, bounded workloads, and scalar-suite registration are included.

[ISAP maximum flow](benchmarks/i/isap_maxflow/README.md) combines reverse-BFS distance labels, dynamic relabeling, current arcs, and the gap rule. Ten ports, an independent cut oracle, bounded workloads, and scalar-suite registration are included.

[ECM stage-one factor detection](benchmarks/e/elliptic_curve_method_stage1/README.md) uses Montgomery X:Z scalar multiplication on a supplied curve and point, with a gcd checkpoint after each prime-power factor. Ten ports, an independent affine-curve oracle, bounded workloads, and scalar-suite registration are included.

[Ridders root finding](benchmarks/r/ridders_root_finding/README.md) uses midpoint-based exponential interpolation to preserve a sign-changing root bracket. Ten ports, an independent high-precision bisection oracle, bounded float64 workloads, and float64-suite registration are included.

[Romberg integration](benchmarks/r/romberg_integration/README.md) refines nested trapezoid estimates and applies Richardson extrapolation in a bounded tableau. Ten ports, an independent closed-form antiderivative verifier, bounded float64 workloads, and float64-suite registration are included.

[Persistent segment-tree range kth](benchmarks/p/persistent_segment_tree_range_kth/README.md) answers static subarray order-statistic queries by descending differences between path-copied prefix histograms. Ten ports, an independent per-slice sort oracle, bounded scalar workloads, and scalar-suite registration are included.

[Dynamic ordered set with AVL order statistics](benchmarks/o/ordered_set_avl_order_statistics/README.md) combines idempotent updates with kth, rank, predecessor, and successor queries using subtree-size augmentation. Ten ports, an independent sorted-list oracle, bounded workloads, and scalar-suite registration are included.

[Indexed block list](benchmarks/i/indexed_block_list/README.md) benchmarks arbitrary-index insertion and access over linked fixed-size blocks, including interior splits. Ten ports, primary and independent oracles, bounded workloads, and byte-output suite registration are included.

[Walker–Vose alias sampling](benchmarks/w/walker_vose_alias_sampling/README.md) has ten unverified language drafts and byte-output suite wiring for exact integer alias-table construction and deterministic categorical draws.

[Space-Saving frequent-item summaries](benchmarks/s/space_saving_frequent_items/README.md) have ten unverified language drafts and byte-output suite wiring for deterministic bounded streaming summaries.

[Melkman simple-polyline hull](benchmarks/m/melkman_simple_polyline_hull/README.md) has ten unverified language drafts and byte-output suite wiring for a linear-time deque hull on a promised simple chain.

[HyperLogLog raw estimate](benchmarks/h/hyperloglog_raw_estimate/README.md) has ten unverified drafts for fixed-bucket sketch updates and an exact rational raw estimate; correction branches are covered separately by the draft below.

[Corrected HyperLogLog estimate](benchmarks/h/hyperloglog_corrected_estimate/README.md) has ten unverified drafts and byte-output suite wiring for the original small- and large-range corrections, including an explicit saturation result.

[Prime-modulus inverse table](benchmarks/p/prime_modulus_inverse_table/README.md) builds a recurrence table for a bounded batch of modular inverses. Ten ports and byte-output suite registration are included.

[Newton formal-series reversion](benchmarks/n/newton_compositional_inverse_fps/README.md) uses precision doubling to invert a series under composition. Its ten language drafts and suite wiring remain unexecuted.

[Newton formal-series reciprocal](benchmarks/n/newton_reciprocal_fps/README.md) uses precision doubling for multiplicative inversion. Its ten language drafts and suite wiring remain unexecuted.

[Newton formal-series reciprocal square root](benchmarks/n/newton_inverse_sqrt_fps/README.md) uses precision doubling for a unit-constant series. Its ten language drafts and suite wiring remain unexecuted.

[Seidel unweighted all-pairs distances](benchmarks/s/seidel_unweighted_apsp/README.md) uses adjacency squaring and distance recovery on bounded connected graphs. Its ten language drafts and suite wiring remain unexecuted.

[Sparse supernodal Cholesky](benchmarks/s/sparse_supernodal_cholesky/README.md) factors a supplied filled sparse pattern in bounded supernodes, with ten language ports and byte-output suite registration. The package remains unexecuted.

[Second-best MST with binary lifting](benchmarks/s/second_best_mst_binary_lifting/README.md) finds the least strictly heavier spanning-tree weight using lifted path summaries. Ten language drafts and scalar-suite registration are present; they remain unexecuted.

[Static range count and sum under a threshold](benchmarks/s/static_range_sum_with_upper_bound/README.md) augments a wavelet matrix with value sums. Ten language drafts, a direct reference, workload, and byte-output suite wiring are present; none has been executed.

[Dynamic range majority](benchmarks/m/dynamic_range_majority/README.md) combines point updates and subrange majority queries using cancellation summaries and position bitmaps. Its ten language drafts and byte-output suite wiring remain unexecuted.

[All farthest neighbors on a convex polygon](benchmarks/a/all_farthest_neighbors_convex/README.md) uses an implicit totally monotone distance matrix and SMAWK to select one farthest vertex for every vertex. Its ten language drafts and byte-output suite wiring remain unexecuted.

[Dirichlet inverse prefix sums](benchmarks/d/dirichlet_inverse_and_prefix_sums/README.md) reconstructs inverse-function prefix values on floor-quotient indices. Its ten language drafts and byte-output suite wiring remain unexecuted.

[Polynomial discrete antidifferentiation](benchmarks/p/polynomial_discrete_antiderivative/README.md) converts a polynomial to the coefficients of its prefix-sum polynomial. Its ten language drafts and byte-output suite wiring remain unexecuted.

[Bivariate formal-series reciprocal](benchmarks/i/inv_of_formal_power_series_2d/README.md) inverts a rectangularly truncated two-variable series. Its ten language drafts and byte-output suite wiring remain unexecuted.

[Set power-series logarithm](benchmarks/l/log_of_set_power_series/README.md) uses a pivot-subset recurrence in square-zero algebra. Its ten language drafts and byte-output suite wiring remain unexecuted.

[Range addition and minimum queries](benchmarks/r/range_add_range_min/README.md) uses a lazy segment tree. Its ten language drafts and byte-output suite wiring remain unexecuted.

[Fixed-modulus discrete logarithms](benchmarks/d/discrete_logarithm_fixed_mod/README.md) amortizes a power table across a batch of targets. Its ten language drafts and byte-output suite wiring remain unexecuted.

[Indexed deque](benchmarks/i/indexed_deque/README.md) combines both-ended mutations with indexed reads in a circular array. Its ten language drafts and byte-output suite wiring remain unexecuted.

[Undirected Eulerian trail](benchmarks/u/undirected_eulerian_trail_hierholzer/README.md) uses Hierholzer traversal with edge identities for multigraphs, including loops and parallel edges. Its ten language drafts, independent reference, workload, and byte-output suite wiring remain unexecuted.

[Undirected breadth-first cycle check](benchmarks/u/undirected_cycle_check_bfs/README.md) uses a FIFO queue with parent tracking and shares its graph contract with the existing stack-based profile. Its ten language drafts and scalar-suite registration remain unexecuted.

[Graph-guided approximate nearest-neighbor hill climbing](benchmarks/g/graphai_gnns_hill_climbing/README.md) profiles the GNNS query stage over a supplied precomputed k-NN graph, with one supplied start, `K=1`, deterministic ascending-ID expansion, strict-improvement moves, and a bounded `T`. Ten language ports, independent mask/list oracles, fixtures, and scalar-suite wiring are included. The pinned GraphAIBench implementation is an empty stub, so this profile follows the cited GNNS paper and is not a source port.

[Deque sliding-window aggregation](benchmarks/s/slide_window_aggregation_deque/README.md) keeps end-oriented monoid aggregates in two stacks and rebuilds a balanced split when a pop empties one side. The ten-language matrix-product profile and scalar-suite wiring are present; it is distinct from the local segment-tree deque and FIFO queue aggregate.

[Barrett modular reduction](benchmarks/b/barrett_reduction/README.md) applies a fixed-radix reciprocal estimate and one bounded correction to a batch of values. Its ten language ports, independent direct-modulo reference, fixtures, and scalar-suite registration are included; it complements the suite's odd-modulus Montgomery REDC profile.

[Sequitur grammar induction](benchmarks/s/sequitur_grammar_induction/README.md) builds a deterministic bounded grammar by enforcing digram uniqueness and rule utility. Ten language ports, independent references, fixtures, and scalar-suite registration are included; it is distinct from frequency-driven BPE tokenization.

[Sparse set with dense and sparse arrays](benchmarks/s/sparse_set_dense_array/README.md) uses an inverse-index invariant for constant-time insertion, deletion, membership, and clear operations. Its ten language ports, references, workload, and scalar-suite registration are included.

[Polynomial Hensel lifting](benchmarks/h/hensel_lifting_polynomial_root/README.md) extends a supplied simple root from a prime modulus to a bounded prime power one p-adic digit at a time. Ten language ports, two references, fixtures, and scalar-suite registration are included.

[Rotation-system planarity testing](benchmarks/r/rotation_system_planarity_test/README.md) checks bounded graphs by enumerating cyclic edge orders and testing the induced Euler characteristic. Its independent forbidden-minor reference, ten language ports, fixtures, and scalar-suite registration are included; this differs from counting faces in a supplied embedding.

[Cyclic symmetric-drawing wedge extraction](benchmarks/s/symmetric_drawing_cyclic_wedge/README.md) consumes a planar rotation system and a supplied rotational automorphism, then extracts one bounded sector and its induced subgraph. Ten language ports, independent references, byte-pinned fixtures, and byte-output suite registration are included; it does not search for an embedding or automorphism.

[LZ-End phrase parsing](benchmarks/l/lz_end_phrase_parsing/README.md) greedily copies the longest proper prefix whose source ends at a prior phrase boundary, then consumes one trailing symbol. Its ten language ports, independent references, fixtures, and scalar-suite registration distinguish it from arbitrary-source LZ77 and dictionary-based LZ78/LZW.

[K3 suffix-array LPF factorization](benchmarks/l/lz77_lpf_suffix_array/README.md) emits each longest previous factor as a `(source, length)` pair using suffix-array PSV/NSV candidates. Its ten ports, independent references, bounded fixtures, and byte-output suite registration distinguish it from the rightmost LZ77 parser that consumes a following character.

[LZ78RL binary run-length transform](benchmarks/l/lz78_run_length_transform/README.md) encodes each maximal run as the MSB-first binary digits of its length, then applies greedy LZ78 to the transformed stream. Ten ports, independent references, fixtures, and byte-output suite registration cover this composition separately from ordinary LZ78 and count-prefixed RLE.

[Khuller–Vishkin DFS 2-edge-connected spanning subgraph](benchmarks/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs/README.md) keeps the deterministic DFS tree and selected `low_H`/`savior` back edges from the paper's 3/2-approximation construction. Ten language ports, independent references, bounded fixtures, and byte-output suite registration are included; the critical-edge deletion heuristic remains a separate profile.

[Khuller–Vishkin DFS 2-vertex-connected spanning subgraph](benchmarks/t/two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs/README.md) implements the paper's sequential `low_H` finish checks and tree-edge discarding rule. Ten language ports, independent references, bounded fixtures, and byte-output suite registration distinguish it from vertex-connectivity decision and articulation-reporting algorithms.

[Nagamochi–Ibaraki sparse k-connectivity certificate](benchmarks/t/nagamochi_ibaraki_sparse_k_connectivity_certificate/README.md) partitions input edges into FOREST layers and keeps the first `k`, preserving each pair's edge connectivity up to `k`. Ten language ports, a cut-enumeration reference, bounded fixtures, and byte-output suite registration distinguish it from flow-value and spanning-subgraph profiles.

[Cheriyan–Thurimella matching-based 2-vertex-connected augmentation](benchmarks/t/cheriyan_thurimella_two_vertex_connected_augmentation/README.md) starts with a minimum edge cover derived from a maximum matching, then scans edges for connectivity-preserving deletions. Ten language ports, independent matching/connectivity references, bounded fixtures, and byte-output suite registration distinguish this heuristic from DFS constructions and connectivity decision algorithms.

[Khuller–Raghavachari phased 3-edge-connected spanning subgraph](benchmarks/t/khuller_raghavachari_three_edge_connected_spanning_subgraph/README.md) uses a DFS tree, postorder highest-going back-edge additions, then a maximal forest from the residual graph. Ten language ports, independent DFS/cut references, bounded fixtures, and byte-output suite registration distinguish it from the 2-edge profiles and the Nagamochi–Ibaraki certificate.

[Jacobi symbol by quadratic reciprocity](benchmarks/j/jacobi_symbol/README.md) computes symbols for positive odd denominators, including composites, without factoring. Its ten language ports, independent factorization reference, fixtures, and scalar-suite registration distinguish it from the prime-only Legendre-symbol profile.

[Minimum directed feedback arc set](benchmarks/m/minimum_directed_feedback_arc_set/README.md) finds the fewest arcs to delete to make a bounded digraph acyclic, using subset DP over vertex orderings. Its permutation oracle, ten language ports, fixtures, and scalar-suite registration distinguish it from vertex-deletion and cycle-enumeration algorithms.

[Tunstall codebook construction](benchmarks/t/tunstall_codebook_construction/README.md) builds a variable-to-fixed prefix code for a bounded memoryless source by repeatedly splitting the most probable phrase. Its exact-probability ties, independent heap reference, ten language ports, fixtures, and scalar-suite registration distinguish it from Huffman and text-dictionary profiles.

[DAG transitive reduction](benchmarks/d/dag_transitive_reduction/README.md) counts the unique cover arcs of a bounded directed acyclic graph. Its closure-based primary, independent edge-deletion searches, ten language ports, fixtures, and scalar-suite registration distinguish it from transitive closure and topological sorting.

[Cornacchia descent for (x^2+2y^2=p)](benchmarks/c/cornacchia_x2_plus_2y2/README.md) finds a prime's positive representation from a supplied square root of (-2) using Euclidean remainders. Its coordinate-scan oracle, ten language ports, fixtures, and scalar-suite registration distinguish it from direct sum-of-two-squares enumeration.

[Newton divided-difference interpolation](benchmarks/n/newton_divided_difference_interpolation/README.md) evaluates a finite-field interpolant in nested Newton form, separate from the local Lagrange-basis coefficient construction. Ten language ports, an independent Lagrange evaluator, fixtures, and scalar-suite registration are included.

[CYK context-free recognition](benchmarks/c/cyk_context_free_recognition/README.md) recognizes bounded Chomsky-normal-form grammars with a triangular chart; an independent reference generates each nonterminal's finite language by length. Its ten language ports and scalar-suite registration are included.

[Minimum dominating set by branch and bound](benchmarks/m/minimum_dominating_set_branch_bound/README.md) solves the unweighted general simple-graph problem exactly through 12 vertices, with a greedy incumbent, coverage lower bound, and subset-enumeration reference. Ten language ports and scalar-suite registration are included.

[Dedekind sums by Euclidean reciprocity](benchmarks/d/dedekind_sum_reciprocity/README.md) computes the scaled classical sum through the Euclidean recurrence, checked against a direct sawtooth finite sum. Ten language ports, fixtures, and scalar-suite registration are included; this is distinct from Jacobi-symbol reciprocity.

[DAG shortest path](benchmarks/d/dag_shortest_path/README.md) solves a weighted source-to-target query by Kahn topological ordering and one edge-relaxation pass, including negative edge weights. Ten language ports, a path-enumeration reference, fixtures, and scalar-suite registration are included.

[OI Wiki maximum clique branch and bound](benchmarks/o/oi_wiki_maximum_clique_branch_bound/README.md) uses ordered candidate-intersection DFS and a suffix-optimum bound to return clique cardinality on graphs through 24 vertices. Ten ports and scalar-suite registration are included; large fixtures have documented hand-derived values.

[Konc–Janežič MaxCliqueDyn](benchmarks/k/konc_maxclique_dyn/README.md) combines greedy coloring bounds, branch and bound, and thresholded degree reordering to return maximum clique cardinality on graphs through 24 vertices. It is a distinct candidate-order and bounding method from the OI Wiki profile; ten ports and scalar-suite registration are included.

[Laguerre complex polynomial root](benchmarks/l/laguerre_complex_polynomial_root/README.md) follows one supplied complex seed through Laguerre corrections for real-coefficient polynomials of degree 2 through 6. Ten language ports, a separate root-set reference, fixtures, and float64 slice-suite integration are included.

[Dietz–Sleator order maintenance](benchmarks/o/order_maintenance/README.md) maintains cyclic labels through insertion and relative-order queries, with a direct-list independent reference and a wraparound relabel fixture. Ten language ports and scalar-suite registration are included.

[Synchronous-round push–relabel](benchmarks/s/synchronous_round_push_relabel/README.md) simulates the paper's round barriers, deferred excess updates, and simultaneous relabels to compute a maximum flow. It is distinct from sequential discharge schedules; ten language ports and scalar-suite registration are included.

[EIBFS max-flow](benchmarks/e/eibfs_maxflow/README.md) maintains source and sink breadth-first forests with pseudoflow excesses, drains imbalances through the tree paths, and extracts the terminal blocking cut. Ten language ports, an exhaustive cut reference, null-input fixtures, and scalar-suite registration are included.

[Hochbaum pseudoflow max-flow](benchmarks/h/hochbaum_pseudoflow_maxflow/README.md) uses full-excess normalization over strong and weak branches, with highest-label branch selection and FIFO ties. It is distinct from preflow push–relabel and from Hochbaum’s §10 pseudoflow-simplex variant; ten language ports and scalar-suite registration are included.

[Adaptive bottom-up graph-cut merging](benchmarks/a/adaptive_bottom_up_graph_cut_merging/README.md) solves independent vertex blocks, orders their merges by a deterministic residual-boundary potential, restores internalized boundary arcs, and augments the retained residual graph. Its bounded profile uses Edmonds–Karp; ten language ports and scalar-suite registration are included.

[EIBFS bottom-up graph-cut merging](benchmarks/e/eibfs_bottom_up_graph_cut_merging/README.md) uses canonical minimum-cut tags to prioritize block merges and runs a fresh EIBFS solve over original capacities after each union. This bounded PEIBFS-inspired profile has ten language ports, an independent whole-graph cut reference, and scalar-suite registration; it does not reuse stale pseudoflow state or claim the upstream parallel schedule.

[Dual-decomposition graph-cut maxflow](benchmarks/d/dual_decomposition_graph_cut_maxflow/README.md) optimizes two overlapping cut subproblems with fixed-point Lagrange multipliers. Its bounded finite-round profile reports both the dual lower bound and whether overlap labels agree; ten language ports and scalar-suite registration are included.

[Region-discharge path-augmentation maxflow](benchmarks/r/region_discharge_path_push_relabel_maxflow/README.md) follows a bounded sequential S-ARD profile, preserving one global preflow and residual graph while augmenting paths to nested sink and boundary targets by region. It has ten language ports, an exhaustive min-cut reference, and scalar-suite registration.

[Caverphone 2.0 phonetic encoding](benchmarks/c/caverphone_2_encoder/README.md) applies the ordered updated Caverphone substitutions and emits a fixed ten-byte code. Ten language ports, primary and independent references, workload fixtures, and byte-output suite registration are present.

[Vogel approximation method](benchmarks/v/vogel_approximation_transportation/README.md) constructs a deterministic feasible transportation allocation by selecting the largest active row or column penalty and filling its least-cost cell. Ten language ports, independent references, fixtures, and scalar-suite registration are included; this is a heuristic initial solution, not an exact minimum-cost flow.

[Capacitated facility-location T-Hunt](benchmarks/c/capacitated_facility_location_t_hunt/README.md) selects the first improving count of target-facility copies and chooses dropped current copies with a profit-maximizing knapsack. Ten language ports, an independent subset-enumeration reference, fixtures, and byte-output suite registration are included; the profile is distinct from uncapacitated add/delete/swap search.

[Capacitated facility-location T-Hunt local search](benchmarks/c/capacitated_facility_location_t_hunt_local_search/README.md) runs the bounded outer strict-improvement scan, including single-copy additions and repeated T-Hunt drop/add moves, with minimum-cost assignment recomputed after each move. Ten language ports, independent references, fixtures, and byte-output suite registration are included; its terminal condition covers the declared scan profile.

[Randomized facility-location add-one/delete-many](benchmarks/f/facility_location_randomized_add_delete_many/README.md) replays the Charikar–Guha uncapacitated update from supplied facility draws, moving strictly closer clients and deleting any independently profitable old facilities. Ten language ports, an independent subset-enumeration reference, fixtures, and byte-output suite registration are included; the deterministic replay makes no probabilistic guarantee.

[Misra–Gries/Vizing edge coloring](benchmarks/m/misra_gries_edge_coloring/README.md) colors bounded general simple graphs with `Delta+1` colors using fan extension, alternating-path inversion, and fan rotation. Ten language ports, an independent coloring-certificate verifier, fixtures, and scalar-suite registration are included; it differs from minimum-`Delta` bipartite edge coloring.

[Additive 2-spanner completion](benchmarks/a/additive_two_spanner_completion/README.md) starts from an empty subgraph and repeatedly adds a shortest input-graph path for the first pair violating additive stretch two. Ten language ports, independent references, fixtures, and byte-output suite registration are included; this graph-distance profile is distinct from geometric multiplicative spanners.

[Euclidean TSP with few inner points: subset DP](benchmarks/t/tsp_few_inner_points_subset_dp/README.md) implements Chapter 426's second fixed-parameter algorithm using the `F2[i,S,r]` recurrence, including a documented initialization for interior points in the first hull gap. Ten language ports, independent references, a bounded fixed-point hull-order workload, and byte-output suite registration are included. Its objective does not claim the unrestricted exact-Euclidean optimum.

[Parallel Clarke–Wright savings for capacitated vehicle routing](benchmarks/c/clarke_wright_savings_cvrp/README.md) starts with one route per customer and applies deterministic positive-savings endpoint merges subject to vehicle capacity. Ten ports, route-chain and adjacency-forest references, bounded fixtures, and byte-output suite registration are included; the profile makes no optimality claim.

[Freivalds matrix-product verification](benchmarks/f/freivalds_matrix_product_verification/README.md) replays the `A(BX)=CX` test over supplied sign vectors, without generating randomness or claiming a probability bound for a fixed tape. Ten language ports, two references, bounded fixtures, and scalar-suite registration are included.

[Hough line transform](benchmarks/h/hough_line_transform/README.md) accumulates exact votes for four integer line normals over a bounded binary image. Ten language ports, pixel-vote and bin-scan references, sparse fixtures, and byte-output suite wiring are integrated in source; no executable checks were run.

[K-means++ D² seeding](benchmarks/k/kmeans_plus_plus_seeding/README.md) chooses centers using exact squared-distance weights and a deterministic draw tape. It isolates initialization from Lloyd iterations and preserves duplicate-row multiplicity; ten language ports, independent references, fixtures, and byte-output suite wiring are integrated in source. No executable checks were run.

[Palindromic partition series-link optimization](benchmarks/p/palindromic_partition_series_links/README.md) uses an eertree's suffix-link difference series to accelerate minimum palindrome partition DP, with deterministic reconstruction ties. It differs from the existing quadratic table partitioner and distinct-palindrome counter. Ten ports, independent references, fixtures, and byte-output suite registration are included.

[LZW-compressed Shift-And matching](benchmarks/l/lzw_compressed_shift_and_matching/README.md) searches compressed LZW phrases using Shift-And transition, boundary, and in-phrase match summaries. Ten ports, primary and independent references, workload fixtures, and byte-output suite registration are included.

[BKP online speed-scaling trace](benchmarks/b/bkp_speed_scaling_trace/README.md) evaluates the Bansal–Kimbrel–Pruhs speed rule at supplied bounded scheduler states, using exact arithmetic with a fixed rational approximation to `e`. Ten language ports, independent references, fixtures, and byte-output suite registration are included; the profile emits speeds only and does not simulate EDF scheduling or claim a competitive guarantee.

[Rational polygon lattice points](benchmarks/r/rational_polygon_lattice_points/README.md) counts strict interior integer points in bounded rational convex polygons using oriented edge floor sums, with a separate exact point-in-polygon enumeration reference. It is distinct from the Pick's theorem benchmark for polygons with lattice vertices. Ten language ports, fixtures, and scalar-suite registration are included.

[Left-truncatable prime search](benchmarks/l/left_truncatable_prime_search/README.md) finds the largest prime in a bounded base whose leading-digit deletions remain prime. It differs from the local decimal profile that requires both left and right truncations. Ten language ports, an independent sieve reference, fixtures, and scalar-suite registration are included.

[Exact effective resistance in a unit graph](benchmarks/e/effective_resistance_unit_graph/README.md) returns the reduced resistance between two terminals as a ratio of Laplacian minors. Ten language ports, an edge-subset reference, bounded fixtures, and scalar-suite registration are present; execution remains unverified.

[Strong, weak, and balanced prime distribution](benchmarks/s/strong_weak_balanced_prime_distribution/README.md) counts primes according to whether they lie above, below, or at the mean of their neighboring primes. It is distinct from cryptographic strong-prime and probable-prime tests; ten language ports, a sieve implementation, an independent trial-division reference, fixtures, and scalar-suite wiring are included.

[Clock Patience simulation](benchmarks/c/clock_patience_simulation/README.md) replays a supplied 52-card rank deal and reports whether every card is exposed. It uses Knuth’s bottom-card directed-tree characterization as an independent reference; ten language ports, fixtures, and scalar-suite registration are included.

[LOUDS ordered-tree navigation](benchmarks/l/louds_ordered_tree_navigation/README.md) encodes an ordered tree in breadth-first unary-degree form and answers degree, parent, and child-rank queries. Ten language ports, independent references, bounded fixtures, and byte-output suite registration are included.

[BP ordered-tree navigation](benchmarks/b/bp_ordered_tree_navigation/README.md) builds the depth-first balanced-parenthesis representation and answers excess searches, range-minimum excess, and matching/enclosing queries. Ten language ports, independent references, bounded fixtures, and byte-output suite registration are included.

[DFUDS ordered-tree navigation](benchmarks/d/dfuds_ordered_tree_navigation/README.md) encodes an ordered tree as depth-first unary degrees with the dummy opening bit and answers degree, child-rank, and parent queries. Ten language ports, an independent direct-tree reference, and byte-output suite registration are included; the maximum output is 288 bytes.

[Canonical ordering of a maximal plane triangulation](benchmarks/c/canonical_order_maximal_plane_triangulation/README.md) applies Chapter 650's reverse shelling to a supplied rotation system and returns a deterministic canonical vertex order. It profiles ordering only, not embedding construction or drawing; ten language ports and byte-output suite registration are included.

[Canonical-order Schnyder realizer](benchmarks/c/canonical_order_schnyder_realizer/README.md) turns a supplied canonical order into three colored parent trees rooted at the outer vertices. It outputs parent assignments rather than drawing coordinates; ten language ports and byte-output suite registration are included.

[Liu Hui inscribed-polygon area approximation](benchmarks/l/liu_hui_pi_approximation/README.md) doubles an inscribed regular hexagon and returns the unit-circle polygon area rounded to millionths. It is distinct from point-sampling π estimates, series summation, and digit generators; ten ports and scalar-suite registration are included.

[Polygon area centroid](benchmarks/p/polygon_area_centroid/README.md) computes a strictly convex polygon's uniform-area centroid from exact signed cross sums and returns both coordinates in millionths. It differs from particle center of mass and area-only calculation; ten ports and byte-output suite registration are included.

[Directed line and convex hull intersection](benchmarks/l/line_hull_intersection/README.md) returns the two boundary-edge indices where a directed infinite line meets a strictly convex polygon, with explicit corner-touch, side-overlap, and no-hit results. The primary uses circular edge-direction ordering and binary searches; the independent reference scans edges with exact rational parameters. Ten language ports and byte-output suite registration are included.

[Oriented polyhedron volume](benchmarks/p/polyhedron_volume/README.md) computes algebraic signed volume from an already supplied closed, edge-paired oriented triangle mesh, returning micro-volume with exact rounding. It accepts disconnected and self-intersecting components under winding-volume semantics; it differs from constructing a hull from a point cloud. Ten ports and byte-output suite registration are included.

[Pisinger bounded-weight subset sum](benchmarks/p/pisinger_bounded_weight_subset_sum/README.md) returns the greatest subset mass at most a target using the balanced `2W`-state recurrence. It differs from capacity-indexed subset-sum DP; ten language ports and scalar-suite registration are included.

[Ryser matrix permanent](benchmarks/r/ryser_permanent/README.md) computes the exact signed permanent of a bounded square matrix using Gray-code subset updates. It is a different matrix function from determinant; ten language ports and scalar-suite registration are included.

[Binary-search maximum-average segment](benchmarks/b/binary_search_maximum_average_segment/README.md) finds the greatest average among intervals at least a supplied length, returning the floor at thousandth precision. It uses transformed-prefix feasibility rather than an exact scan over a length interval; ten ports and scalar-suite registration are included.

[Bounded knapsack by binary grouping](benchmarks/b/bounded_knapsack_binary_grouping/README.md) expands each finite item count into binary bundles and applies each bundle with a descending 0/1 capacity update. It is distinct from the residue-class monotone-queue method; ten ports and scalar-suite registration are included.

[Mixed knapsack](benchmarks/m/mixed_knapsack/README.md) solves one heterogeneous instance with per-item 0/1, unbounded, or bounded modes, dispatching each type to its corresponding capacity-DP update. It composes existing transitions without claiming new subkernels; ten ports and scalar-suite registration are included.

[Orthogonal-drawing bend minimization](benchmarks/o/orthogonal_drawing_minimum_bends/README.md) builds the embedding-derived dual and corner network from Tamassia's flow reduction and returns the minimum bend count. It does not produce drawing coordinates; ten ports and byte-output suite registration are included.

[Hash-free Weisfeiler–Lehman color refinement](benchmarks/w/weisfeiler_lehman_color_refinement/README.md) computes canonical stable 1-WL colors for small unlabeled undirected graphs and packs them into a scalar. It returns colors rather than a graph-hash digest; ten ports and scalar-suite registration are included.

[Havel–Hakimi graph realization](benchmarks/h/havel_hakimi_graph_realization/README.md) constructs a deterministic simple graph from a graphical degree sequence, with explicit residual-degree and vertex-ID tie rules. It returns an edge list rather than a graphicality decision; ten ports and byte-output suite registration are included.

[Hickerson almost-integer expression](benchmarks/h/hickerson_almost_integer/README.md) evaluates `n!/(2·ln(2)^(n+1))` for `1<=n<=17`, returning the binary64 value itself. Its ten ports, high-precision independent reference, bounded workload, and float64 array-suite registration are included; it does not replace the result with a nearby integer.

[Constant-time Sqrt Tree range minimum](benchmarks/s/sqrt_tree_constant_time/README.md) uses padded power-of-two layers and selects a query layer from the highest differing endpoint bit. It is separate from the recursive O(log log n) profile and the O(n log n)-space sparse table; ten ports and byte-output suite registration are included.

[Thomassen convex-drawing extendibility](benchmarks/t/thomassen_convex_drawing_extendibility/README.md) decides whether a supplied convex outer polygon can extend to a convex drawing of a bounded embedded plane graph. It checks Thomassen's three conditions, returns a decision bit rather than coordinates, and includes ten ports, independent path/cycle references, and scalar-suite registration.

[K inverse pairs array](benchmarks/k/k_inverse_pairs_array/README.md) counts permutations with an exact inversion total using the Mahonian distribution. It differs from counting inversions in a given sequence; ten language ports, independent coefficient references, and scalar-suite registration are included.

[Maximum-sum rectangle no larger than K](benchmarks/m/max_sum_rectangle_no_larger_than_k/README.md) finds the largest nonempty rectangle sum at or below a ceiling using band compression and sorted-prefix successor queries. Ten language ports, an independent direct-rectangle reference, bounded fixtures, and scalar-suite registration are included.

[Read-only in-place integer suffix array](benchmarks/s/suffix_array_inplace_readonly_integer/README.md) builds a suffix array with LMS reduction and induced sorting while using caller-provided output storage as its sequence workspace. Ten language ports, independent references, and byte-output suite registration are included; the maximum call workspace is 264 bytes.

[Blind-trie suffix-array construction](benchmarks/s/suffix_array_blind_trie/README.md) inserts bounded byte-string suffixes into an ordered blind trie and traverses its leaves to produce their lexicographic order. Ten language ports, an independent direct-order reference, and byte-output suite registration are included; the maximum result is 256 bytes and the declared workspace is 2,304 bytes.

[Aliquot orbit decomposition](benchmarks/a/aliquot_orbit_decomposition/README.md) reports the transient and eventual cycle for one bounded aliquot-sequence seed, including termination at zero and explicit transition/value caps. It differs from one-step aliquot sums and range searches for long cycles; ten language ports and byte-output suite registration are included.

[Pisano period](benchmarks/p/pisano_period/README.md) finds the least positive index where a consecutive Fibonacci residue pair returns to its initial state. It is distinct from computing one Fibonacci value modulo a modulus; ten language ports, a fast-doubling independent reference, and scalar-suite registration are included.

[Longest common increasing subsequence](benchmarks/l/longest_common_increasing_subsequence/README.md) finds the longest strictly increasing sequence shared as a subsequence by two arrays. It combines the value-order constraint from LIS with the shared-position constraint from LCS; ten language ports, independent references, bounded fixtures, and scalar-suite registration are included.

[Randomized BST order statistics with split and join](benchmarks/r/randomized_binary_search_tree_order_statistics_split_join/README.md) profiles Martínez–Roura subtree-size randomized balancing with kth selection and structural split/join operations. It is distinct from the repository's priority treap and AVL order-statistics profiles; ten language ports, primary and sorted-list references, bounded fixtures, and scalar-suite registration are included.

[C-connected clustered embedding condition](benchmarks/c/c_connected_clustered_embedding_condition/README.md) checks whether one supplied planar rotation system satisfies the outer-face criterion for every c-connected cluster. It does not search alternate embeddings; ten language ports, a face-DSU reference, an independent dual-BFS reference, bounded fixtures, and scalar-suite registration are included.

[Cartesian-tree/FCB static RMQ](benchmarks/r/rmq_cartesian_tree_fcb/README.md) composes a min Cartesian tree with Euler-tour Farach–Colton–Bender LCA to return leftmost argmin indices in constant time per query. The package includes ten language ports, a direct-scan independent reference, explicit 194/195-word limits, a 65-byte maximum-output fixture, and byte-output suite registration.

[Linear hashing operation trace](benchmarks/l/linear_hashing_trace/README.md) profiles signed-key insert, delete, and membership operations with incremental one-bucket splits driven by a level and split pointer. It differs from the local open-addressing and cuckoo-hashing maps; ten language ports, a flat-list independent reference, bounded fixtures, and scalar-suite registration are included.

[Move-to-root BST access trace](benchmarks/m/move_to_root_bst_access_trace/README.md) builds a BST by insertion order and repeatedly rotates a successful search result upward one edge at a time. This differs from splaying's zig/zig-zig/zig-zag rules; ten language ports, array and object-tree references, bounded fixtures, and scalar-suite registration are included.

[Lovasz-toggle defective coloring](benchmarks/l/lovasz_toggle_defective_coloring_trace/README.md) deterministically flips the lowest-index vertex violating its red/blue same-color degree bound until a valid defective coloring is reached. Its weighted potential guarantees termination under the degree condition; ten language ports, independent references, bounded fixtures, and scalar-suite registration are included.

[Erasable priority queue trace](benchmarks/e/erasable_priority_queue_trace/README.md) benchmarks insert, erase-one-by-value, minimum peek, and minimum removal using two heaps with lazy cancellation. Duplicate values are distinct entries and missing erasures are invalid; ten language ports, independent references, bounded fixtures, and scalar-suite registration are included.

[Dynamic rolling-hash substring comparison](benchmarks/r/rolling_hash_on_segment_tree_trace/README.md) combines point assignments with segment-tree range fingerprints, so comparisons observe updates made earlier in the trace. Ten language ports, segment-tree and direct-polynomial references, bounded fixtures, and scalar-suite registration are included.

[Manhattan MST candidate-edge reduction](benchmarks/m/manhattan_mst_candidate_edge_reduction/README.md) generates an octant-based sparse candidate graph with four sweeps and runs Kruskal, complementing the existing complete-graph Prim implementation. Ten language ports, a complete-graph Prim reference, bounded fixtures, and scalar-suite registration are included.

[Minimum Window Subsequence](benchmarks/m/minimum_window_subsequence/README.md) finds the shortest window containing a pattern in order, with an earliest-start tie rule. Its latest-start DP is distinct from the multiplicity-based minimum-window substring; ten language ports, independent backward-greedy reference, and byte-output suite registration are included.

[Shortest subarray with sum at least K](benchmarks/s/shortest_subarray_with_sum_at_least_k/README.md) uses a monotone deque over prefix sums and supports negative values, unlike the positive-only minimum-size subarray profile. Ten language ports, a quadratic independent reference, bounded fixtures, and scalar-suite registration are included.

[Linear partition minimax](benchmarks/l/linear_partition_minimax/README.md) divides a nonnegative sequence into exactly `m` contiguous groups while minimizing the largest group sum. Ten language ports, an independent cut-point DP, bounded fixtures, and scalar-suite registration are included.

[Number of ways of cutting a pizza](benchmarks/n/number_of_ways_of_cutting_a_pizza/README.md) counts legal ordered guillotine cuts with a suffix-count DP, where every resulting piece must contain an apple. Ten language ports, an independent direct-region reference, bounded fixtures, and scalar-suite registration are included.

[HPL blocked partial-pivot LU](benchmarks/h/hpl_blocked_partial_pivot_lu/README.md) profiles small-matrix right-looking blocked LU with partial row pivoting and trailing updates. Ten language ports, independent references, bounded workloads, and float64 array-suite registration are included.

[Minimum-cost K-way merge](benchmarks/m/minimum_cost_to_merge_stones/README.md) computes the cheapest sequence of consecutive-pile merges. Its primary interval DP tracks remaining pile count; an independent residue-based recurrence provides a distinct reference. Ten language ports, bounded fixtures, and scalar-suite registration are included.

[Connectivity-aware plug DP for binary grid colorings](benchmarks/c/connectivity_aware_plug_dp_binary_grid_colorings/README.md) counts rectangular colorings whose two induced color classes are both connected while forbidding monochromatic 2×2 blocks. Ten language ports, an independent exhaustive connectivity reference, bounded fixtures, and scalar-suite registration are included.

[Paint House III](benchmarks/p/paint_house_iii/README.md) minimizes repainting cost while forming an exact number of contiguous color neighborhoods. Ten language ports, a rolling DP, an independent exhaustive reference, bounded fixtures, and scalar-suite registration are included.

[Efficient domination via graph-square MWIS](benchmarks/e/efficient_dominating_set_square_graph_mwis/README.md) decides whether closed neighborhoods partition the graph by checking a weighted independent-set optimum in `G²`. It differs from minimum domination, which allows overlap, and tree-only independent domination. Ten language ports, a direct exact-cover reference, bounded fixtures, and scalar-suite registration are included.

[Maximum employees to be invited](benchmarks/m/maximum_employees_to_be_invited/README.md) optimizes favorite-adjacent circular seating in a functional graph by peeling incoming trees and analyzing its cycles. Ten language ports, exhaustive circular-order references, bounded fixtures, and scalar-suite registration are included.

[Catmull–Clark subdivision](benchmarks/c/catmull_clark_subdivision/README.md) performs one refinement step on a bounded closed polygon mesh, updating old vertices and adding edge and face points. It includes ten language ports, a binary64 primary reference, an exact-rational independent reference, bounded topology and ABI fixtures, and `float64_slice_io` suite registration.

[Max points on a line](benchmarks/m/max_points_on_a_line/README.md) finds the largest collinear subset of distinct bounded planar points by counting normalized directions from each anchor. Its independent reference checks pair-defined lines with exact cross products; ten language ports and scalar-suite registration are included.

[Cherry Pickup II](benchmarks/c/cherry_pickup_ii/README.md) maximizes reward for two robots that move down a grid in lockstep, counting a shared cell once. A rolling paired-column dynamic program is checked by exhaustive paired-path enumeration; ten language ports and scalar-suite registration are included.

[Delaunay-rooted triangulation reverse search](benchmarks/d/delaunay_rooted_triangulation_reverse_search/README.md) enumerates all triangulations of a small strictly convex point set by the Lawson-edge parent rule. Exact integer geometric predicates and an independent diagonal-subset reference support ten language ports and scalar-suite registration.

[String Compression II](benchmarks/s/string_compression_ii/README.md) minimizes run-length encoded length after at most `k` deletions. A prefix dynamic program is checked against deletion-mask enumeration; ten language ports and scalar-suite registration are included.

[Hofstadter Q sequence](benchmarks/h/hofstadter_q_sequence/README.md) evaluates the nested recurrence through the published finite prefix ending at index 128. Bottom-up evaluation is checked against memoized recursion; ten ports and scalar-suite registration are included, with no claim about global definedness.

[Reservoir sampling: quantized Algorithm X](benchmarks/x/reservoir_sampling_algorithm_x/README.md) samples by drawing skip lengths from a bounded exact tail CDF, then selecting a reservoir slot. It is distinct from per-record Algorithm R and makes no continuous-uniform claim for its finite draw grid. Ten language ports, independent rational references, bounded fixtures, and byte-output suite registration are included.

[Simpath s–t path ZDD](benchmarks/s/simpath_st_paths_zdd/README.md) constructs a reduced zero-suppressed decision diagram for all simple paths between two vertices using frontier/mate states. A path-family enumeration and ZDD canonicalization reference is independent of the state-merging method. Ten language ports and scalar-suite registration are included.

[Domino and L-tromino tilings of a 2×n board](benchmarks/d/domino_l_tromino_tilings_2xn/README.md) counts exact tilings using a four-state column-frontier dynamic program. A scalar recurrence provides an independent reference. Ten language ports and scalar-suite registration are included.

[Double Metaphone](benchmarks/d/double_metaphone/README.md) encodes bounded names into Philips's primary and alternate phonetic keys using ordered context-sensitive spelling rules. The profile includes four-symbol keys and explicit Latin-1 Ç/Ñ handling, with two independently structured references and ten language ports.

[Zhouge summatory multiplicative function](benchmarks/z/zhouge_summatory_multiplicative_function/README.md) evaluates a prime-power-defined multiplicative family with quotient-compressed Zhouge sieve states. A segmented factorization oracle provides an independent reference; ten language ports and scalar-suite registration are included.

[Integer domain coloring](benchmarks/d/domain_coloring/README.md) samples `f(z)=z²` on a bounded complex grid and emits deterministic RGB24 pixels from integer phase and magnitude rules. An independently structured octant reference supports ten language ports and byte-output suite registration.

[Pearson byte-string hash](benchmarks/p/pearson_hash/README.md) applies `h = T[h XOR c]` with a caller-supplied byte permutation. A transition-map reference, compact materialized fixtures, ten language ports, and scalar-suite registration are included.

[Minimum unfairness by K-selection](benchmarks/m/minimum_unfairness_k_selection/README.md) chooses exactly `K` values with minimum maximum-minus-minimum range. Its sorted adjacent-window reference is checked against an independent endpoint/count method; ten language ports, bounded fixtures, and scalar-suite registration are included.

[Cosine fixed-point iteration](benchmarks/c/cosine_fixed_point_iteration/README.md) replays `x <- (cos(x)+2)/2` with an explicit initial value and source-style update count. It is distinct from the local root-finding and optimization procedures; ten language ports, binary64 and Decimal-Taylor references, bounded fixtures, and `float64_pair` runner/verifier integration are included.

[All-distances k-mins](benchmarks/a/all_distances_sketch_k_mins/README.md) emits each new distance-prefix minimum for multiple supplied rank assignments. Its MV/D lists differ from the existing shared bottom-k sketch and whole-set k-mins operation; ten language ports, incremental and query-prefix references, bounded fixtures, and byte-output runner/verifier integration are included.

[Arbitrary-arrival bottom-k ADS interval updates](benchmarks/a/all_distances_bottom_k_interval_updates/README.md) maintains item-membership intervals with successive maximum-rank truncations when arrivals are not distance-sorted. This differs from the distance-ordered shared ADS and prefix-minimum records; ten language ports and independent references are registered with the byte-output suite.

[Zobrist position-hash trace](benchmarks/z/zobrist_position_hash_trace/README.md) benchmarks incremental feature-key XOR updates on a bounded position. It is distinct from Pearson's byte recurrence and rolling hashes; ten language ports, incremental and full-position references, bounded fixtures, and byte-output runner/verifier integration are included.

[Schuler randomized general-CNF SAT](benchmarks/s/schuler_randomized_general_cnf_sat/README.md) replays PPZ attempts and recursive clause-prefix falsification from supplied permutation, bit, and branch-choice tapes. It differs from Procedure S and deterministic greedy DPLL; ten language ports, recursive and assignment-vector references, bounded fixtures, and byte-output runner/verifier integration are included.

[Left-right planar embedding](benchmarks/p/planar_embedding_lr/README.md) uses Brandes's DFS lowpoint and conflict-pair test to decide bounded simple-graph planarity and emits a cyclic-neighbor embedding certificate. It complements the six-vertex exhaustive rotation-system profile; ten language paths, independent decision/certificate references, bounded fixtures, and byte-output suite registration are included.

[Metropolis–Hastings with asymmetric proposals](benchmarks/m/metropolis_hastings_asymmetric_proposal/README.md) replays a bounded finite-state chain using exact integer cross-products for the reverse/forward proposal correction and supplied rational draws. Its independent reference constructs the exact transition kernel and verifies detailed balance; ten language ports and byte-output suite registration are included.

[Race-car minimum instruction count](benchmarks/r/race_car_minimum_instruction_count/README.md) minimizes accelerate/reverse commands over a bounded speed-changing integer state, using run-length dynamic programming and an independent exact-state BFS; ten language ports and scalar-suite registration are included.

[Miller backward recurrence normalization](benchmarks/m/miller_backward_recurrence_normalization/README.md) performs a bounded terminal-trial backward sweep and normalizes its finite-field trial vector; it has an independent boundary-system reference, ten ports, and byte-output suite registration.

[Barycentric Lagrange evaluation](benchmarks/b/barycentric_lagrange_evaluation/README.md) evaluates one finite-field interpolation query with reciprocal nodal-product weights, independently checked by Vandermonde solving; ten language ports and scalar-suite registration are included.

[CL complementary-pair bucket heuristic](benchmarks/r/random_3sat_cl_bucket_heuristic/README.md) deterministically replays a bounded random 3-SAT CL bucket-selection trace over a supplied formula. Independent mutable and immutable references, ten language ports, and byte-output suite registration are included.

[Bairstow quadratic-factor iteration](benchmarks/b/bairstow_quadratic_factor_iteration/README.md) records bounded DLMF `q`/`r` corrections over `F_998244353`, with a direct-convolution reference, ten language ports, and byte-output suite registration. The finite-field trace makes no claim of real-root convergence.

[Punycode code-point sequence encoding](benchmarks/p/punycode_codepoint_sequence_encode/README.md) encodes bounded Unicode scalar sequences using RFC 3492 generalized digits and bias adaptation. Ten language ports, a built-in-codec/decoder reference, and byte-output suite registration are included; IDNA processing is outside the profile.

[Lentz continued-fraction convergents](benchmarks/l/lentz_continued_fraction_convergents/README.md) uses multiplicative `C_n`/`D_n` convergent ratios over a finite field, with a direct-continuant reference and ten language ports. It is registered in the byte-output suite and rejects its explicitly pinned zero-divisor cases.

[Fornberg finite-difference weights](benchmarks/f/fornberg_finite_difference_weights/README.md) generates arbitrary-grid derivative weights with the triangular recurrence over a finite field; an independent moment-system solve checks the vector. Ten language ports and byte-output suite registration are included.

[Pratt expression evaluation](benchmarks/p/pratt_expression_evaluation/README.md) parses a bounded integer-token expression with recursive binding powers; shunting-yard parsing provides an independent reference. Ten language ports and scalar-suite registration are included.

[Clenshaw–Curtis quadrature](benchmarks/c/clenshaw_curtis_quadrature/README.md) integrates supplied values at Chebyshev–Lobatto nodes with the explicit even-order weights; an independent DCT-I Chebyshev-series reference checks the result. Ten language ports and `float64_slice_io` suite registration are included.

[Minimal dominating sets in permutation graphs](benchmarks/m/minimal_dominating_sets_permutation_graphs/README.md) counts minimal dominating sets through the permutation-model five-tuple DAG; exhaustive subset/private-neighbor checking provides an independent reference. Ten language ports and scalar-suite registration are included.

[Brownian-tree diffusion-limited aggregation](benchmarks/b/brownian_tree_diffusion_limited_aggregation/README.md) grows a bounded lattice cluster through seeded random walks and first-contact attachment. Two differently structured references, pinned workloads, ten language ports, and byte-output suite registration are included.

[Padé approximant coefficients from a formal series](benchmarks/p/pade_approximant_series_coefficients/README.md) solves the normalized finite-field coefficient-matching system for a bounded `[p/q]` approximant. A determinant/Cramer reference checks the Gauss–Jordan primary; ten language ports, bounded fixtures, and byte-output suite registration are included.

[K-quadtree edge distribution](benchmarks/k/k_quadtree_edge_distribution/README.md) assigns supplied straight-line edges to the leaves of a canonical partition using the paper's two opposite-Z frontier-stack sweeps. A direct rational clipping oracle checks the incidences; ten ports and byte-output suite registration are included.

[Olver backward recurrence boundary value](benchmarks/o/olver_backward_recurrence_boundary_value/README.md) advances the inhomogeneous `p_n`/`e_n` state to the first endpoint that meets DLMF's relative cutoff, then reconstructs the requested prefix. It is distinct from Miller's homogeneous terminal-trial normalization. A pivoted boundary-system oracle provides an independent reconstruction; ten language ports and `float64_slice_io` suite registration are included.

[Synchronous stochastic forest-fire automaton](benchmarks/f/forest_fire_synchronous_stochastic_ca/README.md) replays Moore-neighbor ignition, growth, and burnout from fixed draw tapes. The outermost row and column must be empty initially and remain empty. It includes ten language ports, direct and burning-neighbor-mask references, pinned workloads, and byte-output suite registration.

[Parameterized pattern matching with modified KMP](benchmarks/p/parameterized_pattern_matching_kmp/README.md) builds parameterized failure links and scans text using mapped-match predicates. It is distinct from the local per-window predecessor-string comparison profile; ten language ports, an independent bijection-window reference, bounded workloads, and byte-output suite registration are included.

[Farey sequence ordered enumeration](benchmarks/f/farey_sequence_ordered_enumeration/README.md) generates every reduced fraction through a fixed denominator order with the constant-space successor recurrence. It is distinct from single-target Farey approximation and Stern–Brocot navigation; ten language ports, a gcd-and-cross-product reference, bounded workloads, and byte-output suite registration are included.

[Lanczos symmetric tridiagonalization](benchmarks/l/lanczos_symmetric_tridiagonalization/README.md) returns the bounded three-term recurrence coefficient trace for a symmetric matrix and fixed start vector. It differs from local QR eigensolvers and power iteration; ten language ports, an independent Krylov-projection reference, bounded workloads, and `float64_slice_io` suite registration are included.

[Randomized Tutte-matrix perfect matching](benchmarks/t/tutte_matrix_randomized_perfect_matching/README.md) replays a supplied finite-field edge substitution, inverts the skew-symmetric Tutte matrix, and extracts a perfect matching. It differs from blossom contraction and weighted subset DP; ten language ports, a determinant/cofactor reference, bounded workloads, and byte-output suite registration are included.

[Grid shortest path with obstacle elimination](benchmarks/g/grid_shortest_path_obstacle_elimination/README.md) performs BFS on cell-and-budget product states, so entering an obstacle consumes one of a bounded number of eliminations. It differs from ordinary grid BFS and monotone path counting; ten language ports, an edge-relaxation reference, bounded workloads, and scalar suite registration are included.

[Chan output-sensitive planar convex hull](benchmarks/c/chan_output_sensitive_hull/README.md) groups points, wraps with subgroup tangent queries, and increases the group-size guess when a wrap does not close. This differs from Jarvis scan, monotone chain, Quickhull, and divide-and-conquer tangent merging; ten language ports, independent monotone-chain/grouped references, bounded workloads, and byte-output suite registration are included.

[Kirkpatrick–Seidel convex hull](benchmarks/k/kirkpatrick_seidel_convex_hull/README.md) uses marriage-before-conquest bridges with median-of-medians selection and point pruning. It differs from Chan wrapping and tangent merging; ten language ports, an independent support-edge oracle, bounded fixtures, and byte-output suite registration are included.

[Chess960 Scharnagl position unranking](benchmarks/c/chess960_scharnagl_position_unrank/README.md) decodes the constrained bishop, queen, and knight digits into one of 960 canonical first ranks, then places the king between the remaining rooks. It is distinct from arbitrary permutation unranking and random shuffle-and-reject generation; ten language ports, mixed-radix and reverse-ranking references, bounded workloads, and byte-output suite registration are included.

[Cohen–Sutherland line clipping](benchmarks/c/cohen_sutherland/README.md) repeatedly clips an outside segment endpoint according to its four-bit region code and a fixed boundary priority. It measures a distinct geometry kernel from the local Liang–Barsky interval clipper; ten language ports, an independent parametric reference, bounded workloads, and float64 suite registration are included.

[Divide-and-conquer tangent-merge convex hull](benchmarks/d/divide_conquer_tangent_hull/README.md) recursively builds two x-monotone chains and joins them with common tangents. It measures a different hull-construction path from monotone chain, Quickhull, and Chan's algorithm; ten language ports, an independent monotone-chain reference, bounded workloads, and byte-output suite registration are included.

[Signed-permutation overlap-forest components](benchmarks/s/signed_permutation_overlap_forest_components/README.md) constructs breakpoint cycles and assigns their overlap-forest components with Bader–Moret–Yan’s stack refinement. It complements the shortest-reversal sequence package without computing reversal distance; ten language ports, an explicit overlap-graph reference, bounded workloads, and byte-output suite registration are included.

[Recursive-backtracker maze generation](benchmarks/r/recursive_backtracker_maze_generation/README.md) builds a perfect maze through DFS and backtracking with a deterministic caller-supplied neighbor-choice tape. It differs from maze solvers and Wilson's loop-erased random walks; ten language ports, iterative and recursive references, bounded workloads, and byte-output suite registration are included.

[Zwick deterministic bridging set](benchmarks/z/zwick_deterministic_bridging_set/README.md) extracts witness-path prefixes and greedily hits the resulting set family for a bounded unweighted directed graph. It is a distinct Chapter 12 APSP component, not a full distance algorithm; ten language ports, independent witness-path references, bounded workloads, and scalar suite registration are included.

[Halley root finding](benchmarks/h/halley_root_finding/README.md) replays the second-derivative update for `x^3-2` with a fixed bounded iteration count. It differs from Newton and bracketed methods; ten language ports, a Decimal reference, bounded fixtures, and `float64_pair` registration are included.

[Asteroid collision](benchmarks/a/asteroid_collision_stack/README.md) resolves a signed one-dimensional arrival sequence with a survivor stack, preserving surviving order and applying pairwise annihilation rules. It is separate from physical 2D collision simulation; ten language ports, an independent rewrite reference, bounded fixtures, and byte-output suite registration are included.

[K-mismatch longest-extension table](benchmarks/k/k_mismatch_longest_extension_table/README.md) computes `LP_k(p)` for every suffix with suffix-array/LCP/RMQ exact-LCE jumps, and checks the results against direct mismatch scans. It is a reusable approximate-repeat kernel, distinct from the local repeat-enumeration packages; ten language ports, bounded fixtures, and byte-output suite registration are included.

[K-mismatch repetition binary-division kernel](benchmarks/k/k_repetition_binary_division_kernel/README.md) isolates the intra-block recursive midpoint stage for finding globally-defined approximate repetitions, using copy-overlap Lempel–Ziv factors and direct extension walks. It complements the `LP_k(p)` table and local definition enumerators; ten language ports, independent factor-block references, bounded fixtures, provenance, and byte-output suite registration are included.

[Markov normal string rewriting](benchmarks/m/markov_normal_string_rewriting/README.md) interprets prioritized ordinary/final rewrite rules, choosing the first rule and its leftmost match before restarting priority. It has ten language ports, independent match-selection references, bounded rewrite and growth limits, provenance, fixtures, and byte-output suite registration.

[K-mismatch repetition block-head pair pass](benchmarks/k/k_repetition_block_head_pair_pass/README.md) isolates the first paired-block head stage of globally-defined K-mismatch repetition search. It complements the intra-block binary-division kernel and `LP_k(p)` table without claiming the full maximality pipeline; ten language ports, independent references, bounded fixtures, provenance, and byte-output suite registration are included.

[K-mismatch within-factor copy propagation](benchmarks/k/k_repetition_within_factor_copy_propagation/README.md) isolates Chapter 24's final copy-propagation stage over supplied Lempel–Ziv factors and maximal seed records. It handles overlapping copies and deduplicates shifted records; ten language ports, independent ordered-bucket and full-set references, bounded fixtures, provenance, and byte-output suite registration are included.

[Modified Newton for a multiple root](benchmarks/m/modified_newton_multiple_root/README.md) uses the known-multiplicity correction on a polynomial with a double root, giving a distinct update from ordinary Newton and Halley. It has ten language ports, a high-precision Decimal reference, bounded fixtures, and `float64_pair` workload registration.

[Round-robin tournament schedule](benchmarks/r/round_robin_tournament_schedule/README.md) generates a deterministic opponent table by the circle method, with dummy-team byes for odd team counts. It differs from CPU-job `round_robin` and `tournament_sort`; ten language ports, two references, bounded fixtures, and byte-output suite registration are included.

[Sierpinski curve direction trace](benchmarks/s/sierpinski_curve_trace/README.md) emits Wirth's closed A/B/C/D recursive curve as direction/length bytes. It is distinct from the Sierpinski triangle-outline and carpet-raster benchmarks; ten language ports, independent recursion and grammar references, bounded fixtures, provenance, and byte-output suite registration are included.

[Arbitrary-axis finite vector rotation](benchmarks/r/rodrigues_arbitrary_axis_rotation/README.md) applies the Euler–Rodrigues vector identity to rotate one 3D vector about a caller-supplied nonzero axis. It differs from single-coordinate-axis rotation, planar rotation, and quaternion conversion/product kernels; ten language ports, independent vector and matrix references, bounded fixtures, provenance, and float64-slice suite registration are included.

[Cyclotomic polynomial coefficients](benchmarks/c/cyclotomic_polynomial_coefficients/README.md) constructs `Phi_n(x)` by exact proper-divisor polynomial quotients for `1 <= n <= 32`, returning ascending signed-integer coefficients. It is distinct from scalar Möbius and general polynomial evaluation/interpolation benchmarks; ten language ports, quotient and Newton-identity references, bounded byte-output fixtures, provenance, and suite registration are included.

[Fortunate numbers](benchmarks/f/fortunate_numbers/README.md) returns the least prime-producing offset above each of the first ten primorials. It is distinct from returning primorials, Euclid–Mullin factors, or Sylvester terms; ten language ports, trial-division and segmented-sieve references, bounded fixtures, provenance, and i64-array-scalar suite registration are included.

[MRG32k3a combined recursive generator](benchmarks/m/mrg32k3a_combined_recursive_generator/README.md) emits a bounded integer trace from two order-three modular recurrences. It is distinct from the local lagged subtractive generator and LCG; ten language ports, rolling-state and full-history references, bounded output fixtures, provenance, and byte-output suite registration are included.

[Tanh–sinh double-exponential quadrature](benchmarks/t/tanh_sinh_double_exponential_quadrature/README.md) uses the finite Takahasi–Mori transformed trapezoid on four fixed integrands, including endpoint-singular cases. Ten language ports use an independent closed-form integral reference, bounded fixtures, and `float64_slice_io` suite registration.

[Finite standard Sturmian word generation](benchmarks/s/sturmian_standard_word/README.md) constructs a standard word from a bounded directive prefix using the directive recurrence. It differs from numeric Fibonacci and fixed Fibonacci-word profiles; ten language ports use an independent morphism-composition reference and `i64_array_bytes_output` suite registration.

[Dividuus number predicate](benchmarks/r/dividuus_number_predicate/README.md) checks whether a number is divisible by its digit sum, digit product, digital root, and multiplicative digital root. It combines properties covered separately by existing number benchmarks; ten language ports, independent numeric and digit-vector references, bounded fixtures, and scalar-suite registration are included.

[Gaussian prime classifier](benchmarks/g/gaussian_prime_classifier/README.md) classifies bounded Gaussian integers by the axis-prime and norm-prime criteria. It is distinct from Gaussian-integer arithmetic benchmarks; ten language ports, trial-division and sieve references, bounded fixtures, and scalar-suite registration are included.

[Sieve of Pritchard](benchmarks/s/sieve_of_pritchard/README.md) counts primes with a dynamically extended wheel and reverse multiple deletion. It is distinct from the repository's Eratosthenes-family, Sundaram, Atkin, Euler/linear, and segmented sieves; ten language ports, an independent trial-division reference, bounded fixtures, and scalar-suite registration are included.

[SQUFOF semiprime factor search](benchmarks/s/squfof_semiprime_factor/README.md) tests even-index square remainders in a bounded continued-fraction walk and reverses each square form to seek a proper gcd split. It differs from Fermat, Pollard rho, Pollard p−1, and trial division; ten language ports and two references are registered in the scalar suite.

[Ring-Expander closed-mesh pass](benchmarks/r/ring_expander_closed_triangle_mesh/README.md) replays one seeded traversal over a validated closed triangle mesh and emits its corner trace and visit masks. It measures a mesh-connectivity algorithm distinct from triangulation construction and queries; ten language ports, two references, and byte-output suite registration are included.

[Stieltjes quotient-difference transform](benchmarks/s/stieltjes_quotient_difference_transform/README.md) derives S-fraction coefficients from a finite power-series prefix using the Q-D rhombus recurrence over a prime field. It differs from evaluating supplied continued-fraction coefficients; ten language ports, Q-D and Hankel-determinant references, bounded fixtures, and byte-output suite registration are included.

[Weiler–Atherton polygon intersection](benchmarks/w/weiler_atherton_polygon_intersection/README.md) alternates between interleaved polygon boundaries at entry and exit crossings to emit exact-rational intersection rings; an edge-fragment reference and ten native ports accompany the byte-output suite registration.

[Succinct BP pioneer-family matching](benchmarks/s/succinct_bp_pioneer_match_index/README.md) builds a bounded recursive parenthesis-matching index from far-parenthesis pioneers and their balanced family, with query-time recursion and ordered block/depth groups; ten native ports are registered in the byte-output suite.

[Standard quotient-filter operation trace](benchmarks/q/quotient_filter_operation_trace/README.md) replays duplicate-aware insert, lookup, and delete operations with local circular shifts and metadata updates; a physical-slot primary and abstract multiset reference accompany ten native ports in the byte-output suite.

[Counting Bloom filter operation trace](benchmarks/c/counting_bloom_filter_operation_trace/README.md) profiles four-counter insert, valid delete, and approximate membership operations over a 67-counter array. A history-based reference checks the incremental counter implementation; ten language ports and bounded byte-output fixtures are registered.

[Routh–Hurwitz stability predicate](benchmarks/r/routh_hurwitz_stability_predicate/README.md) checks strict left-half-plane stability with an exact Routh table and an independent Hurwitz-minor reference. Ten language ports, 18 bounded fixtures, and scalar-suite registration cover degree-1-to-4 polynomials with integer coefficients, including marginal and degenerate cases.

[Jury discrete-time stability predicate](benchmarks/j/jury_discrete_time_stability_predicate/README.md) checks strict open-unit-disk stability with the division-free Jury–Blanchard coefficient table and an independent Schur–Cohn determinant reference. Ten language ports and bounded polynomial fixtures are registered in the scalar suite.

[RNA pair-activity partition function](benchmarks/r/rna_pair_activity_partition_function/README.md) sums integer weights over all noncrossing partial pairings using an O(n³) interval dynamic program. It is distinct from maximum-pair-count folding and minimum-energy RNA folding; ten language ports and bounded fixtures are registered in the scalar suite.

[One-sided Jacobi singular values](benchmarks/o/one_sided_jacobi_svd/README.md) adds a bounded cyclic Jacobi SVD spectrum profile, with an independent symmetric-Jacobi reference over `AᵀA`, fixed-point scalar output, and ten language ports in the scalar suite.

[Minimum-area arbitrary-orientation rectangle](benchmarks/m/minimum_area_rectangle_arbitrary_orientation/README.md) finds a minimum-area rectangle from four selected input points using equal-midpoint, equal-length diagonal pairs. It differs from convex-polygon enclosing rectangles; ten language ports and an independent four-point reference are registered in the scalar suite.

[Time-batched secret sharing](benchmarks/s/secret_sharing_time_batched_dsu/README.md) propagates information through each timestamp's transitive meeting components and resets uninformed temporary links. Ten language ports use an independent per-time BFS reference and are registered in the scalar suite.

[Redundant directed connection repair](benchmarks/r/redundant_directed_connection_repair/README.md) removes the input edge that restores a rooted arborescence after one extra directed edge was added, using two-parent detection and DSU cycle resolution. It is distinct from undirected redundant-edge detection; ten language ports and an independent deletion-and-reachability reference are registered in the scalar suite.

[Undirected simple-cycle subset DP](benchmarks/u/undirected_simple_cycle_subset_dp_count/README.md) counts every simple cycle of length at least three once up to rotation and reversal by fixing each cycle's least vertex and counting subset paths. It differs from fixed-length cycle counting and cycle-basis problems; ten language ports and an independent canonical DFS reference are registered in the scalar suite.

[Batched bounded-range GCD](benchmarks/b/batch_gcd_small_range_precomputed/README.md) preprocesses values through a small bound with a linear sieve, three-factor representations, and a compact GCD table, then answers each pair query in constant time. It differs from per-pair Euclid, binary GCD, and list-fold GCD; ten language ports, a direct-Euclid reference, and byte-output suite registration are included.

[Android unlock pattern count](benchmarks/a/android_unlock_pattern_count/README.md) counts length-4-to-9 paths on the canonical 3×3 grid under the visited-midpoint rule. A visited-mask DFS is checked against an independent permutation scan; ten ports and scalar-suite registration are included.

[Random permutation count with a cycle cap](benchmarks/r/random_permutation_cycle_cap_count/README.md) counts permutations whose disjoint cycles all have length at most `k`, using a fixed-label recurrence and an independent cycle-type sum. Ten ports, bounded fixtures, and scalar-suite registration are included.

[Factorial last nonzero digit](benchmarks/f/factorial_last_nonzero_digit/README.md) computes the final nonzero decimal digit of `n!` with a logarithmic base-five recurrence and an independent digit-product reference. Ten language ports and scalar-suite registration are included.

[NMEA payload XOR checksum](benchmarks/n/nmea_xor_checksum/README.md) folds a bounded payload with bytewise XOR, excluding sentence framing and checksum text. It differs from additive and CRC checksum profiles; ten language ports and scalar-suite registration are included.

[Morris approximate counter with base-three transitions](benchmarks/m/morris_approximate_counter_base_three/README.md) records the ternary transition schedule and estimator as a distinct parameter profile, with an independent estimate-gap reference and byte-output suite registration.

[Dense bitset Kosaraju SCC](benchmarks/k/kosaraju_dense_bitset_scc/README.md) finds strongly connected components from packed adjacency rows using word-parallel neighbor discovery. A Tarjan reference and byte-output suite registration are included.

[Binary divisibility by three with a streaming DFA](benchmarks/b/binary_divisibility_by_three_dfa/README.md) scans an MSB-first bit stream with three remainder states and emits one divisibility byte. Its 4096-bit constant-state scan differs from materializing a signed-64-bit integer or testing a numeric operand; ten language ports and byte-output suite registration are included.

[Eulerian number by descent count](benchmarks/e/eulerian_number/README.md) computes one entry of the classical Eulerian triangle with a row recurrence and checks it against an independent inclusion–exclusion reference. It is distinct from Entringer numbers and graph Eulerian paths; ten language ports and scalar-suite registration are included.

[Hashiwokakero small solver](benchmarks/h/hashiwokakero_small_solver/README.md) searches bounded geometric bridge assignments with exact degrees, crossing checks, connectivity pruning, and a lexicographic tie rule. Its exhaustive complete-vector reference is independent of the pruned search; ten language ports and scalar-suite registration are included.

[Quantum spectral energy expectation](benchmarks/q/quantum_spectral_energy_expectation/README.md) applies the Fourier-domain kinetic operator and pointwise potential to a normalized complex state, then returns its Hamiltonian expectation. It is distinct from split-operator state evolution; ten language ports use a radix-2 primary and direct-DFT reference in the `i64_array_float64` suite.

[Extended Straddling Checkerboard transducer](benchmarks/s/straddling_checkerboard_transducer/README.md) maps a 30-cell checkerboard to a prefix-free decimal code and decodes variable-length digit streams. The bounded profile pins the two row-indicator holes, duplicate-symbol and NUL handling, output-capacity errors, and error precedence; ten language ports use independent direct-map and prefix-trie references in the byte-output suite.

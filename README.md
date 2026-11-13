# Encyclopedia of Benchmarks

A cross-platform collection for comparing algorithm implementations across programming languages. TheAlgorithms repositories are an initial discovery source; the supplied *Encyclopedia of Algorithms* is another. Its chapter-by-chapter coverage and the disposition of distinct candidates are tracked in the [Encyclopedia crosswalk](benchmarks/ENCYCLOPEDIA_COVERAGE.md). When an algorithm has no implementation in one of our target languages, we will write one and record it as a port.

## Goals

- Catalog algorithms and implementations across languages.
- Compare implementations only when they solve the same problem with the same input and output semantics.
- Keep a portable baseline for every benchmark. Default code must not depend on Intel-only instructions or x86-only compiler flags.
- Record enough source, build, machine, and workload details to reproduce a result.
- Preserve attribution and license information for any code taken from an upstream project.

## Layout

The current language folders are `c`, `c3`, `cpp`, `elisa`, `nim`, `odin`, `rust`, `v`, and `zig`. Algorithms are grouped by the first letter of the algorithm name, for example `rust/l/linear_search.rs`; names beginning with a digit go under `0-9/`. Numeric source filenames stay as catalog candidate IDs; a reviewed candidate can use an alphabetic `benchmark_name` for its algorithm folder. Workloads and result files use the same organization, such as `benchmarks/l/linear_search/` and `results/l/linear_search/`.

The latest static audit of the pinned TheAlgorithms inventory records 2,506 distinct mapped benchmark names, with 2,463 complete across all nine target languages and 43 still incomplete; see [CATALOG.md](CATALOG.md) for the full counts and audit limits. These are file-presence results, not evidence of runtime correctness. ANSIbench additions are tracked in the [ANSIbench coverage crosswalk](benchmarks/ANSIBENCH_COVERAGE.md), Embench-IoT kernels in the [Embench-IoT source crosswalk](benchmarks/EMBENCH_IOT_COVERAGE.md), Rodinia kernels in the [Rodinia source crosswalk](benchmarks/RODINIA_COVERAGE.md), the 17-kernel GitHub shortlist and its deduplication notes are in the [GitHub source crosswalk](benchmarks/GITHUB_BENCHMARKS_COVERAGE.md), Parboil kernels are tracked in the [Parboil source crosswalk](benchmarks/PARBOIL_COVERAGE.md), and the 273-launcher lac-dcc inventory is in the [lac-dcc coverage crosswalk](benchmarks/LAC_DCC_BENCHMARKS_COVERAGE.md). New source discovery and duplicate decisions are recorded in the [additional algorithm coverage ledger](benchmarks/ALGORITHM_EXPANSION_COVERAGE.md). Alias and benchmark-name mappings are documented in [CATALOG.md](CATALOG.md) and [`catalog/algorithm-candidates.json`](catalog/algorithm-candidates.json). See each algorithm guide under [`benchmarks/`](benchmarks/) and the [benchmarking instructions](BENCHMARKING.md).

[External merge sorter](benchmarks/e/external_merge_sorter/README.md) follows the pinned C# bottom-up merge passes over sequential stores, modeled with bounded buffers across all nine target languages.

[Sattolo cycle shuffle](benchmarks/s/sattolo_cycle/README.md) restricts each descending swap to an earlier position, generating a single-cycle permutation with a shared deterministic stream across the nine standard languages and the optional Mojo port.

[Dynamic predecessor problem](benchmarks/p/predecessor_problem/README.md) maintains a bounded set in packed 64-bit words and answers membership, successor, and predecessor queries alongside idempotent updates.

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

[Persistent union-find](benchmarks/p/persistent_unionfind/README.md) answers connectivity queries across branching graph versions with rollback DSU traversal.

[Strong orientation](benchmarks/s/strong_orientation/README.md) directs every edge to minimize the number of strongly connected components and emits the orientation certificate.

[Set XOR-min](benchmarks/s/set_xor_min/README.md) uses a counted binary trie to maintain a 30-bit integer set and answer minimum-XOR queries.

[Complement-graph components](benchmarks/c/connected_components_of_complement_graph/README.md) finds components in the implicit complement using neighbor marking and an unvisited-vertex traversal.

[Bipartite edge coloring](benchmarks/b/bipartite_edge_coloring/README.md) decomposes a multigraph into the minimum number of matchings by regularization and repeated perfect matchings.

[Minimum-cost b-flow](benchmarks/m/minimum_cost_b_flow/README.md) handles signed vertex balances, lower and upper bounds, negative costs, and a primal/dual optimality certificate.

[Weighted tree diameter](benchmarks/t/tree_diameter/README.md) returns a maximum-weight path from an arbitrary positively weighted tree with deterministic endpoint ties.

[Biconnected components](benchmarks/b/biconnected_components/README.md) uses DFS low links and an edge stack to return vertex blocks, including singleton blocks and multigraph support.

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

[Jump on tree](benchmarks/j/jump_on_tree/README.md) answers kth-vertex-on-path queries using shared binary-lifting preprocessing.

[Vertex-set path composite](benchmarks/v/vertex_set_path_composite/README.md) combines point-updated affine maps along a tree path while preserving traversal direction.

[Dynamic tree vertex add and subtree sum](benchmarks/d/dynamic_tree_vertex_add_subtree_sum/README.md) maintains a link-cut tree with virtual-subtree totals while replacing edges, adding vertex weights, and querying one side of an edge.

[Dynamic tree subtree add and subtree sum](benchmarks/d/dynamic_tree_subtree_add_subtree_sum/README.md) uses a lazy Euler-tour treap to add to one edge-oriented component and query its sum while replacing edges in a tree.

[Euler Tour Tree](benchmarks/e/euler_tour_tree/README.md) maintains a dynamic forest with implicit-treap Euler tours, supporting link, cut, vertex-weight assignment, and component size/weight queries.

[Dynamic top-tree component diameter](benchmarks/d/dynamic_top_tree_component_diameter/README.md) builds a balanced rake/compress hierarchy once for a fixed tree, then updates edge weights through cluster ancestors and answers diameter queries from the root summary.

[Dynamic tree vertex-set path composite](benchmarks/t/dynamic_tree_vertex_set_path_composite/README.md) maintains forward and reverse affine-composition summaries in a link-cut tree for edge replacement, vertex-map updates, and oriented path queries.

[Garsia–Wachs alphabetic tree](benchmarks/g/garsia_wachs_alphabetic_tree/README.md) computes minimum weighted external path length for ordered leaf weights and returns an ordered depth certificate.

[Schreier–Sims](benchmarks/s/schreier_sims/README.md) builds a fixed-base stabilizer chain for bounded permutation-group order and membership queries, checked against full group closure.

[Hafnian of a matrix](benchmarks/l/hafnian_of_matrix/README.md) computes the weighted sum over perfect pairings with bounded subset dynamic programming modulo 998244353.

[Binary matrix product over GF(2)](benchmarks/m/matrix_product_mod_2/README.md) packs rows of the right operand and XORs the selected rows to multiply over the two-element field.

[Binary matrix determinant over GF(2)](benchmarks/m/matrix_det_mod_2/README.md) uses packed Gaussian elimination with XOR row operations to test full rank over the two-element field.

[Determinant modulo an arbitrary integer](benchmarks/m/matrix_det_arbitrary_mod/README.md) uses Euclidean row transformations that work even when composite-modulus pivots are not invertible.

[Characteristic polynomial over a prime field](benchmarks/m/characteristic_polynomial/README.md) reduces matrices to upper Hessenberg form and applies a leading-principal-submatrix recurrence to return every coefficient.

[Modular adjugate matrix](benchmarks/a/adjugate_matrix/README.md) computes every signed minor directly, including for singular matrices.

[Marsaglia polar normal transform](benchmarks/m/marsaglia_polar_normal/README.md) produces a deterministic normal pair from a bounded integer tape using rejection inside the unit disk.

[Metropolis MCMC](benchmarks/m/metropolis_mcmc/README.md) replays a fixed-temperature accept/reject chain from symmetric proposals and supplied uniform values.

[Cartesian Box–Muller normal transform](benchmarks/b/box_muller_cartesian_normal/README.md) maps supplied radial and angular draws directly to standard-normal pairs without rejection.

[NAS Parallel Benchmarks EP kernel](benchmarks/n/npb_ep/README.md) combines the specified 46-bit LCG, polar rejection transform, square-annulus histogram, and coordinate-sum reductions.

[NAS Parallel Benchmarks sparse CG profile](benchmarks/n/npb_cg_sparse_inverse_power/README.md) runs CSR conjugate-gradient inner solves inside bounded inverse-power eigenvalue iterations.

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

[Point-set range sort and affine composition](benchmarks/p/point_set_range_sort_range_composite/README.md) combines point replacement, ascending or descending priority sorts over ranges, and ordered affine evaluation.

[Signed decimal big integer addition](benchmarks/a/addition_of_big_integers/README.md) compares magnitudes, then performs carry addition or borrow subtraction with canonical sign handling.

[Prefix sum of binomial coefficients](benchmarks/p/prefix_sum_of_binomial_coefficient/README.md) advances across a bounded modular binomial row and accumulates an arbitrary prefix.

[Formal power-series inverse](benchmarks/i/inv_of_formal_power_series/README.md) computes the reciprocal coefficients modulo x^N with a bounded quadratic recurrence and an independent Newton-iteration oracle.

[Polynomial inverse modulo a polynomial](benchmarks/i/inv_of_polynomials/README.md) uses extended Euclid over F_998244353 to find an inverse representative modulo an arbitrary polynomial, or reports when no inverse exists.

[Formal power-series exponential](benchmarks/e/exp_of_formal_power_series/README.md) computes exp(f) modulo x^N from the derivative recurrence g'=f'g, with an independent truncated-power oracle.

[Formal power-series square root](benchmarks/s/sqrt_of_formal_power_series/README.md) uses Tonelli–Shanks and a quadratic coefficient recurrence, with an independent Cipolla/binomial-series oracle and a deterministic root choice.

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

[Polynomial root finding over a finite field](benchmarks/p/polynomial_root_finding/README.md) isolates and splits every base-field linear factor using Cantor–Zassenhaus, with an independent direct-evaluation oracle.

[Multipoint evaluation on a geometric sequence](benchmarks/m/multipoint_evaluation_on_geometric_sequence/README.md) uses the Bluestein chirp-z identity and NTT convolution, with repeated Horner evaluation as an independent oracle.

[Polynomial interpolation on a geometric sequence](benchmarks/p/polynomial_interpolation_on_geometric_sequence/README.md) reconstructs coefficients from geometric sample points using q-Newton divided differences, with an independent Vandermonde-elimination oracle.

[Polynomial composition in a set power series](benchmarks/p/polynomial_composite_set_power_series/README.md) evaluates a univariate polynomial in the square-zero subset algebra using Horner composition and subset convolution, with an independent ordered-factor assignment oracle.

[Farach–Colton–Bender lowest common ancestor](benchmarks/l/lowest_common_ancestor_farach_colton_bender/README.md) answers batched tree queries with Euler-tour ±1 RMQ microblocks and a macroblock sparse table; parent climbing and BFS/ancestor-set oracles are kept independent.

[Fixed-root HLD path-composite sum](benchmarks/p/point_set_tree_path_composite_sum_fixed_root/README.md) maintains affine path aggregates after vertex-value and edge-map updates with heavy-light decomposition and a segment tree; a full postorder recomputation provides the independent oracle.

[Arbitrary-root point-set tree path-composite sum](benchmarks/p/point_set_tree_path_composite_sum/README.md) maintains affine maps and vertex values in a balanced rake/compress top tree, then propagates outside summaries to answer each chosen-root aggregate; direct path reconstruction is the independent oracle.

[De Bruijn sequence generation](benchmarks/d/de_bruijn_sequences/README.md) uses FKM necklace concatenation to emit a bounded k-ary cycle; cyclic-window validation is independent of the generator.

[Knuth's power tree](benchmarks/k/knuth_power_tree/README.md) finds first-discovery exponent paths in one shared addition-chain tree using breadth-first parent expansion; an explicit path-frontier oracle checks the result.

[Prefix-substring LCS](benchmarks/p/prefix_substring_lcs/README.md) batches prefix/substring longest-common-subsequence queries with semi-local boundary values and Fenwick sweeps; direct per-query LCS is the independent oracle.

[Main–Lorentz tandem repetitions](benchmarks/p/main_lorentz_tandem_repetitions/README.md) enumerates every tandem square using divide-and-conquer Z comparisons, with direct adjacent-block comparison as an independent oracle.

[Suffix balanced tree](benchmarks/s/suffix_balanced_tree/README.md) constructs a suffix array by reverse insertion into a scapegoat-style tree whose comparisons use successor suffix ranks, with direct suffix sorting as an independent oracle.

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

[Undirected cycle check](benchmarks/u/undirected_cycle_check/README.md) separates the undirected DFS/BFS methods in the pinned Rust `detect_cycle.rs` from its directed-cycle methods and ports the parent-tracking traversal to all nine languages.

[Directed Eulerian path](benchmarks/e/eulerian_path/README.md) ports the pinned Rust Hierholzer traversal to all nine languages, preserving its start-vertex and adjacency-consumption order while handling parallel edges and self-loops.

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
[Z-block substring search](benchmarks/z/zblock_substring_search/README.md) returns an exact, overlapping match count using Z blocks across nine languages.
[Interleaving strings](benchmarks/i/interleavingstrings/README.md) adds the bounded two-source order-preserving dynamic program across nine languages.
[Half-wave rectifier](benchmarks/h/half_wave_rectifier/README.md) ports six selected current/voltage calculations and their resistance constraints across nine languages.
[IPv4-mapped IPv6 conversion](benchmarks/i/ipv6_converter/README.md) adds both raw-byte conversion directions across nine languages.
[Hamming code encoder](benchmarks/h/hamming_code/README.md) ports the pinned parity-bit placement and emission routine across nine languages.

[IMPLY Gate](benchmarks/h/imply_gate/README.md) ports the pinned Python two-input implication function to all nine languages, covering the complete Boolean truth table.



The pinned Java `iterative_flood_fill` source shares the existing eight-connected [`flood_fill`](benchmarks/f/flood_fill/README.md) benchmark contract.

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

[Hilbert curve](benchmarks/h/hilbert_curve/README.md) ports the pinned Python recursive point generator to all nine languages with exact dyadic coordinates.

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

Recent source-backed additions from Library Checker, Rosetta Code, CP-Algorithms, OI Wiki, and published algorithm papers include [D'Esopo–Pape shortest paths](benchmarks/d/d_esopo_pape/README.md), [Dominator tree](benchmarks/d/dominator_tree/README.md), [Deque operate all composite](benchmarks/d/deque_operate_all_composite/README.md), [Eertree](benchmarks/e/eertree/README.md), [Gabow path-based SCC](benchmarks/g/gabow_scc/README.md), [Hunt–Szymanski sparse LCS](benchmarks/h/hunt_szymanski_lcs/README.md), [incremental strongly connected components](benchmarks/i/incremental_scc/README.md), [`k_shortest_walk`](benchmarks/k/k_shortest_walk/README.md), [Li Chao tree](benchmarks/l/li_chao_tree/README.md), [Link-Cut Tree](benchmarks/l/link_cut_tree/README.md), [Manhattan MST](benchmarks/m/manhattan_mst/README.md), [Minkowski sum of convex polygons](benchmarks/p/minkowski_sum_convex_polygons/README.md), [point in polygon by ray casting](benchmarks/p/point_in_polygon_ray_casting/README.md), [point set range composite](benchmarks/p/point_set_range_composite/README.md), [queue operate all composite](benchmarks/q/queue_operate_all_composite/README.md), [Rectangle add point get](benchmarks/r/rectangle_add_point_get/README.md), [range affine point get](benchmarks/r/range_affine_point_get/README.md), [range affine range sum](benchmarks/r/range_affine_range_sum/README.md), [range set range composite](benchmarks/r/range_set_range_composite/README.md), [run enumeration](benchmarks/r/runenumerate/README.md), [SA-IS suffix-array construction](benchmarks/s/suffix_array_sais/README.md), [st-numbering](benchmarks/s/st_numbering/README.md), [Static range inversions query](benchmarks/s/static_range_inversions_query/README.md), [Static range LIS query](benchmarks/s/static_range_lis_query/README.md), [Static rectangle add rectangle sum](benchmarks/s/static_rectangle_add_rectangle_sum/README.md), [counting directed spanning trees](benchmarks/c/counting_spanning_trees_directed/README.md), [counting undirected spanning trees](benchmarks/c/counting_spanning_trees_undirected/README.md), [Crochemore–Perrin Two-Way string matching](benchmarks/c/crochemore_perrin_two_way/README.md), [rooted tree isomorphism classification](benchmarks/r/rooted_tree_isomorphism_classification/README.md), [segment add get min](benchmarks/s/segment_add_get_min/README.md), [segment tree beats](benchmarks/s/segment_tree_beats/README.md), [static range mode query](benchmarks/s/static_range_mode_query/README.md), [three-edge-connected components](benchmarks/t/three_edge_connected_components/README.md), and [global vertex connectivity](benchmarks/v/vertex_connectivity/README.md). Their source comparisons, duplicate decisions, and suite-integration status are tracked in the [additional algorithm coverage ledger](benchmarks/ALGORITHM_EXPANSION_COVERAGE.md).

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

[Tree path composite sum](benchmarks/t/tree_path_composite_sum/README.md) reroots affine path-composition messages to report the sum from every possible tree root. Ten language ports, independent direct-path and composition-traversal oracles, bounded fixtures, and byte-output suite wiring are present; the dense-table implementation uses `O(N^2)` time for its local `N <= 32` profile.

[Tree decomposition width 2](benchmarks/t/tree_decomposition_width_2/README.md) recognizes bounded graphs by degree-two elimination and returns a checked tree-decomposition certificate. [Truncated multivariate convolution](benchmarks/m/multivariate_convolution/README.md) discards products outside the per-axis degree limits; [cyclic multivariate convolution](benchmarks/m/multivariate_convolution_cyclic/README.md) wraps coordinates modulo each axis. Both convolution profiles have ten ports and direct plus independent oracles. [Dynamic star-augmented global minimum cut](benchmarks/g/global_minimum_cut_of_dynamic_star_augmented_graph/README.md) recomputes cuts after spoke updates, with an exhaustive cut checker. [Rooted-tree topological order with minimum inversions](benchmarks/r/rooted_tree_topological_order_with_minimum_inversions/README.md) uses DSU ratio contractions and a subset-DP optimality checker. All five have byte-output suite registration and bounded local workloads.

[Bitwise XOR convolution](benchmarks/b/bitwise_xor_convolution/README.md) transforms both input arrays with the XOR Walsh–Hadamard transform, multiplies pointwise, then applies the inverse transform and normalization. Its ten ports are distinct from the standalone transform benchmark and have direct pair-enumeration and independent per-output oracles plus byte-output suite registration.

[Bitwise OR convolution](benchmarks/b/bitwise_or_convolution/README.md) computes the union-indexed modular convolution with subset zeta transforms, pointwise multiplication, and Möbius inversion. It is distinct from the AND and XOR products and from subset convolution; ten ports, direct and independent oracles, a bounded workload, provenance notes, and byte-output suite wiring are present.

[Knuth-optimized optimal binary search tree](benchmarks/k/knuth_optimized_optimal_binary_search_tree/README.md) applies monotone-root bounds to the same successful-search cost recurrence as the existing cubic profile, reducing root-search work from O(n^3) to O(n^2). Ten ports, a bounded workload, Knuth and cubic oracles, and scalar-suite registration are present.

[Broken-profile domino tilings](benchmarks/b/broken_profile_domino_tilings/README.md) counts open rectangular-board tilings with a frontier-mask DP, transposing to keep the profile width at most eight. Ten ports, small-board enumeration, an independent row-transition oracle, a bounded workload, and scalar-suite registration are present.

The [SPLASH-2-inspired water profiles](benchmarks/s/splash2_water_nsquared/README.md) share a bounded rational molecule-pair law and byte output. [`splash2_water_nsquared`](benchmarks/s/splash2_water_nsquared/README.md) scans all pairs; [`water_spatial`](benchmarks/w/water_spatial/README.md) builds uniform cells and searches clipped neighbor cells. Each has ten ports and independent oracle coverage; neither claims to reproduce the full molecular-dynamics application.

[Incremental XOR linear basis](benchmarks/x/xor_linear_basis/README.md) maintains a 63-pivot basis for insertions, maximum-subset-XOR queries, and representability checks. Ten ports, exhaustive-subset primary and independent checkers bounded to 16 insertions, and byte-output suite wiring are present.

[GraphAIBench gated graph-message update](benchmarks/g/graphai_ggnn_message_update/README.md) sums each vertex's outgoing neighbor states, applies reset/update gates and a recurrent candidate using six supplied matrices, and emits the next node states. Nine standard-language ports plus Mojo are wired into the float64 slice suite.

[Kahan compensated summation](benchmarks/k/kahan_summation/README.md) processes ordered binary64 values with a running correction term. Ten ports, an exact-step independent verifier, and float64 slice suite registration are present.

[Lengauer–Tarjan immediate dominators](benchmarks/l/lengauer_tarjan_dominator_tree/README.md) uses DFS semidominators and path-compressed `LINK`/`EVAL`, alongside the existing bitset fixed-point dominator-tree benchmark. Ten ports, a vertex-removal oracle, bounded workload, and byte-output suite registration are present.

[Half-plane intersection](benchmarks/h/half_plane_intersection/README.md) constructs the exact rational convex region cut out by up to twelve primitive integer inequalities inside a fixed bounding square. Ten ports use angle sorting and deque pruning; an independent pair-intersection and convex-hull oracle and byte-output suite profile are included.

[SMAWK row minima](benchmarks/s/smawk_row_minima/README.md) finds the leftmost minimum of every row in a promised totally monotone matrix using column reduction, recursive odd-row minima, and interpolation. Ten ports, an independent row-scan oracle, bounded fixtures, and byte-output suite registration are present.

[Minimum-cost max-flow with tight-edge blocking flow](benchmarks/m/min_cost_max_flow_blocking_paths/README.md) recomputes shortest residual distances and sends blocking flow over tight arcs. Ten ports share the existing reduced-cost shortest-path contract; a Bellman–Ford successive-path oracle and byte-output suite registration are included.

[Convex polygon point-membership queries](benchmarks/p/point_in_convex_polygon_log_query/README.md) rotate a strictly convex polygon to a canonical pivot and binary-search its radial fan for each query. Ten ports, an independent linear edge scan, bounded workloads, and byte-output suite registration are included.

[Legendre prime counting](benchmarks/l/legendre_prime_count/README.md) evaluates the partial-sieve formula through `x = 10,000`. Ten ports, an independent direct-sieve oracle, bounded scalar fixtures, and scalar-suite registration are included.

[Finite discrete rejection sampling](benchmarks/d/discrete_rejection_sampling/README.md) replays a supplied proposal and acceptance-draw tape against integer target weights using an exact integer envelope. Ten ports, an independent oracle, an explicit exhaustion result, bounded byte-output cases, and suite registration are included.

[Brent–Kung formal power-series composition](benchmarks/b/brent_kung_fps_composition/README.md) computes `f(g) mod x^N` with baby-step/giant-step blocks over `F_998244353`, distinct from the existing descending-Horner composition. Ten ports, independent Horner verification, bounded workloads, and byte-output suite registration are included.

[Exact graph Steiner tree by terminal-subset DP](benchmarks/p/steiner_tree_subset_dp/README.md) finds the minimum weight connecting a bounded terminal set using subset merges and multi-source shortest-path relaxation. It differs from the finite-family gain-greedy approximation. Ten ports, an independent edge-subset oracle, bounded workload, and scalar-array suite registration are included.

[Create Maximum Number](benchmarks/c/create_maximum_number/README.md) chooses the lexicographically greatest length-`k` digit sequence from two ordered sources using split enumeration, monotone subsequence selection, and suffix-aware merging. Ten ports, an independent skip/take oracle, bounded workload, and byte-output suite registration are included.

[Minimum-spanning-tree edge classification](benchmarks/m/mst_edge_classification/README.md) labels every edge as absent from all, present in some, or present in every minimum spanning tree. Ten ports use equal-weight Kruskal groups and edge-ID-aware quotient bridges; an independent force/forbid Kruskal oracle and byte-output suite profile are included.

[Two-dimensional trapped rainwater](benchmarks/t/trapping_rain_water_ii/README.md) computes retained volume using a min-heap flood from boundary cells. Ten ports, an independent per-cell threshold/BFS oracle, bounded grid workloads, and scalar-array suite registration are included.

[Planar face counting](benchmarks/p/planar_face_count/README.md) validates a bounded connected planar straight-line graph, orders each vertex's neighbors by polar angle, and traverses directed-edge face orbits. Ten language ports, an independent Euler-characteristic oracle, bounded fixtures, and scalar-array suite registration are included.

[Hash join](benchmarks/h/hash_join/README.md) joins two bounded integer-key relations by hashing the smaller side and retaining duplicate row IDs in input order. Ten language ports, an independent nested-loop oracle, bounded byte-output workloads, and suite registration are included.

[Dynamic MEX with point updates](benchmarks/d/dynamic_mex_updates/README.md) maintains candidate-value frequencies and a segment tree to report the minimum excluded value after each replacement. Ten ports, an independent direct-scan oracle, bounded workloads, and byte-output suite registration are included.

[Bishop placement count](benchmarks/b/bishop_placements_count/README.md) counts exact nonattacking bishop placements by splitting the board's diagonals by square color and combining the two counts. Ten language ports, an independent diagonal-mask oracle, bounded scalar workloads, and suite registration are included.

[Karp minimum directed cycle mean](benchmarks/m/minimum_mean_cycle_karp/README.md) returns the exact reduced mean weight of a minimum-mean cycle using exact-length path dynamic programming. Ten ports, an independent simple-cycle enumeration oracle, and byte-output suite registration are included.

[Johnson's two-machine flow shop](benchmarks/j/johnson_two_machine_flow_shop/README.md) orders jobs on both machines to minimize makespan using Johnson's partition-and-sort rule. Ten ports, an independent exhaustive-permutation oracle, bounded workloads, and scalar-array suite registration are included.

[Undirected Chinese postman](benchmarks/u/undirected_chinese_postman/README.md) finds the shortest closed route covering every edge by pairing odd-degree vertices in the shortest-path metric. Ten ports, an independent edge-coverage-state oracle, bounded workloads, and scalar-array suite registration are included.

[All shortest paths in an unweighted graph](benchmarks/a/all_shortest_paths_unweighted/README.md) enumerates every lexicographically ordered shortest path through a BFS predecessor DAG. Ten ports, an independent Floyd-Warshall oracle, bounded output/workspace profiles, and byte-output suite registration are included.

[Maximum number of jobs before deadlines](benchmarks/d/max_jobs_before_deadlines/README.md) chooses the largest feasible subset of arbitrary-duration jobs using reverse deadline intervals and a min-heap of residual durations. Ten ports, an independent subset/EDF oracle, bounded workloads, and scalar-array suite registration are included.

[Connected labeled graph count](benchmarks/c/connected_labeled_graph_count/README.md) counts connected simple undirected graphs on a labeled vertex set modulo 998244353 using the rooted-component recurrence, with an independent EGF formal-series oracle. Ten ports and bounded scalar-suite registration are included.

[Bostan–Mori recurrence term](benchmarks/b/bostan_mori_recurrence_term/README.md) extracts a distant term by parity-selecting numerator and denominator coefficients while halving the index. Ten ports, an independent companion-matrix oracle, and scalar-suite registration cover orders through eight and indices through 10^18.

[Common tangents to two circles](benchmarks/c/common_tangents_two_circles/README.md) counts distinct shared tangent lines with exact signed-radius discriminants, including degenerate point circles and coincident tangency cases. Ten ports, an independent squared-distance oracle, and scalar-suite profiles are included.

[Circle-line intersection counts](benchmarks/c/circle_line_intersection_count/README.md) classify each bounded integer line as missing, tangent to, or crossing a circle using exact discriminants. Ten ports, an independent line-parameter oracle, and byte-output suite registration are included.

[Circle-circle intersection counts](benchmarks/c/circle_circle_intersection_count/README.md) use the radical axis and an exact discriminant to classify disjoint, tangent, two-point, and coincident circles. Ten ports, an independent squared-distance oracle, and scalar-suite registration are included.

[Functional graph cycle parameters](benchmarks/f/functional_graph_cycle_parameters/README.md) finds the preperiod and eventual cycle length from one node in a bounded successor map using constant-space tortoise-and-hare traversal. Ten ports, an independent first-seen-table oracle, workload fixtures, and scalar-suite registration are included.

[Largest zero submatrix](benchmarks/l/largest_zero_submatrix/README.md) updates per-column blocker heights for each binary-matrix row and uses monotone stacks to find the largest all-zero rectangle. Ten ports, an independent exhaustive rectangle oracle, and scalar-suite registration are included.

[Maximum frequency stack](benchmarks/m/maximum_frequency_stack/README.md) removes an online value with highest current frequency, breaking ties by its latest active push. Ten ports, an independent active-list rescan oracle, bounded byte-output workloads, and suite registration are included.

[Balanced ternary conversion](benchmarks/b/balanced_ternary_conversion/README.md) converts any signed 64-bit integer to canonical radix-three digits `Z`, `0`, and `1`. Ten ports, independent signed-remainder and carry oracles, bounded byte-output workloads, and suite registration are included.

[Tree edge painting and path counts](benchmarks/t/tree_edge_paint_path_count/README.md) supports idempotent edge paints and arbitrary path queries on a bounded tree. Ten ports use directional Euler-tour segment trees with LCA path splitting; an independent BFS oracle reconstructs each path. Scalar-suite registration is included.

[Online temporary-task load balancing](benchmarks/o/online_temporary_task_load_balancing/README.md) assigns each arriving temporary task to a least-loaded machine after expiring completed tasks, then reports peak active load and assignments. Ten ports, independent expiration-heap and history-replay oracles, bounded byte-output workloads, and suite registration are included.

[Convolution over GF(2^64)](benchmarks/c/convolution_f2_64/README.md) computes carryless polynomial convolution modulo `x^64+x^4+x^3+x+1`, treating each i64 input bit pattern as a u64 field element. Ten ports, independent shift/reduce and polynomial-division oracles, bounded byte-output workloads, and suite registration are included.

[Convex-polygon minimax-length triangulation](benchmarks/c/convex_polygon_minimax_length_triangulation/README.md) minimizes the longest edge over triangulations of a strictly convex integer polygon. Ten ports use interval minimax dynamic programming; an independent exhaustive enumerator checks the small bounded profile, which is registered in the scalar suite.

[Pfaffian of an alternating matrix](benchmarks/p/pfaffian_of_matrix/README.md) computes the Pfaffian modulo 998244353 for bounded alternating matrices. Ten ports use pivoted elimination; an independent pairing-mask recurrence verifies the scalar profile, which is registered in the scalar suite.

[Static x-fast trie predecessor](benchmarks/x/x_fast_trie_static_predecessor/README.md) answers bounded batches of integer predecessor queries using prefix-level catalogs and longest-existing-prefix search. Ten ports, an independent sorted-array oracle, and scalar-suite registration are included; the profile does not claim the classic expected `O(log log U)` bound.

[Dirichlet convolution and prefix sums](benchmarks/d/dirichlet_convolution_and_prefix_sums/README.md) computes convolution-prefix values over the floor-quotient set `Q_N` from cumulative function values. Ten ports use two quotient-interval groupings with structurally independent oracles; the bounded byte-output profile is registered in the suite.

[Blocked right-looking LU factorization](benchmarks/b/blocked_lu_factorization/README.md) uses a serial block-width-two schedule and trailing Schur updates. Ten ports and float64-slice suite registration are included; its bounded internal workspace is 2560 bytes.

[15-puzzle solvability](benchmarks/f/fifteen_puzzle_solvability/README.md) classifies a 4×4 board by the inversion/blank-row parity invariant, without searching for a move sequence. Ten ports, independent permutation-cycle and checkerboard-color verification, and scalar-suite registration are included.

[Binomial coefficients modulo prime powers](benchmarks/b/binomial_coefficient_prime_power/README.md) use p-adic factorial cancellation and invert only p-free units. Ten ports, an independent Pascal-row oracle, bounded byte-output workloads, and suite registration are included.

[Minimum queue with two stacks](benchmarks/m/minimum_queue_two_stacks/README.md) maintains FIFO order and constant-time minimum queries with two prefix-minimum stacks. Ten ports, a direct FIFO oracle, bounded workloads, and scalar-suite registration are included.

[Adaptive Simpson quadrature](benchmarks/a/adaptive_simpson_quadrature/README.md) refines only intervals whose local Simpson error estimate exceeds tolerance, with a correction on accepted intervals. Ten ports, a closed-form oracle, bounded workloads, and float64-suite registration are included.

[Parallel binary search for range-threshold crossings](benchmarks/p/parallel_binary_search_range_threshold/README.md) batches monotone earliest-prefix queries by midpoint and replays range additions through Fenwick trees. Ten ports, independent replay-and-scan verification, bounded workloads, and scalar-suite registration are included.

[Mergeable and splittable segment tree](benchmarks/s/segment_tree_merge_split/README.md) maintains sparse value-domain multisets with destructive root merges and interval extraction. Ten language ports, an independent count-array oracle, bounded byte-output workloads, and suite registration are included.

[SMO dual pair update](benchmarks/s/smo_dual_pair_update/README.md) performs one analytic linear-kernel SVM dual update for a supplied coefficient pair and bias. Ten language ports, an independent restricted-objective oracle, bounded ABI fixtures, and float64-suite registration are included; this is a training primitive, not a full classifier.

[CDQ 3D dominance counts](benchmarks/c/cdq_three_dimensional_dominance/README.md) counts weakly dominated points with multiplicity-weighted Fenwick queries and y-ordered CDQ merges. Ten ports, a direct ordered-pair oracle, bounded fixtures, and scalar-suite registration are included.

[Distinct palindromic subsequences](benchmarks/c/count_different_palindromic_subsequences/README.md) counts distinct nonempty palindrome sequences over a bounded four-symbol alphabet. Ten ports, duplicate-aware interval DP, an independent mask enumerator, bounded workloads, and scalar-suite registration are included.

[Palindrome pairs](benchmarks/p/palindrome_pairs/README.md) enumerates ordered word-index pairs whose concatenation is palindromic, including empty and duplicate words. Ten ports, split-and-lookup and direct-concatenation oracles, bounded byte-output workloads, and byte-suite registration are included.

[Dormand–Prince adaptive ODE solver](benchmarks/d/dormand_prince_54_adaptive_ode/README.md) integrates four bounded scalar ODEs with the adaptive 5(4) Runge–Kutta pair, accept/reject control, and FSAL reuse. Ten ports, an independent closed-form verifier, bounded float64 workloads, and float64-suite registration are included.

[Dial bucket shortest paths](benchmarks/d/dial_bucket_shortest_paths/README.md) computes directed shortest-path distances with a nine-slot cyclic bucket queue for weights from zero to eight. Ten ports, an independent Floyd–Warshall oracle, bounded byte-output workloads, and byte-suite registration are included.

[Bareiss fraction-free determinant](benchmarks/b/bareiss_determinant/README.md) computes exact small integer determinants using pivoted fraction-free elimination. Ten ports, an independent signed-permutation expansion, bounded matrix workloads, and scalar-suite registration are included.

[Ridders root finding](benchmarks/r/ridders_root_finding/README.md) uses midpoint-based exponential interpolation to preserve a sign-changing root bracket. Ten ports, an independent high-precision bisection oracle, bounded float64 workloads, and float64-suite registration are included.

[Romberg integration](benchmarks/r/romberg_integration/README.md) refines nested trapezoid estimates and applies Richardson extrapolation in a bounded tableau. Ten ports, an independent closed-form antiderivative verifier, bounded float64 workloads, and float64-suite registration are included.

[Persistent segment-tree range kth](benchmarks/p/persistent_segment_tree_range_kth/README.md) answers static subarray order-statistic queries by descending differences between path-copied prefix histograms. Ten ports, an independent per-slice sort oracle, bounded scalar workloads, and scalar-suite registration are included.

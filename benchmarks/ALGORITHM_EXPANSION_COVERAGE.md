# Additional Algorithm Source Coverage

This is the shared, incremental ledger for algorithms discovered outside the pinned TheAlgorithms catalog and the supplied *Encyclopedia of Algorithms*. It records equivalence decisions and in-flight ownership so independent ports do not collide. A source appearing below does not mean its entire catalog has been reviewed.

## Source review status

| Source | Current evidence / coverage record | Review status |
| --- | --- | --- |
| TheAlgorithms repositories | [`CATALOG.md`](../CATALOG.md), pinned in [`catalog/algorithm-candidates.json`](../catalog/algorithm-candidates.json) | Existing inventory; continue resolving the remaining candidate records there. |
| *Encyclopedia of Algorithms* | [Chapter crosswalk](ENCYCLOPEDIA_COVERAGE.md) and its A–F, G–M, N–S, T–Z sections | Existing chapter-by-chapter review; preserve its explicit partial and excluded decisions. |
| ANSIbench, Embench-IoT, Rodinia, Parboil, GAPBS, GARDENIA, GBBS, GraphAI, Pannotia, SAGA-Bench, lac-dcc, and selected GitHub suites | Existing source-specific crosswalks, including [`ANSIBENCH_COVERAGE.md`](ANSIBENCH_COVERAGE.md), [`RODINIA_COVERAGE.md`](RODINIA_COVERAGE.md), and [`GITHUB_BENCHMARKS_COVERAGE.md`](GITHUB_BENCHMARKS_COVERAGE.md) | Existing partial suite inventories; continue from each crosswalk rather than duplicating its candidates. |
| Library Checker / Yosupo Judge | Candidate decisions below; official problem pages linked per item | Initial targeted audit; full category review remains open. |
| NAS Parallel Benchmarks | [NASA suite definition](https://www.nas.nasa.gov/software/npb.html); existing [`lac-dcc` NPB-serial crosswalk](LAC_DCC_BENCHMARKS_COVERAGE.md#npb-serial) | Partial: `npb_is` and `npb_serial_dc` cover two NPB-serial profiles. The official NPB kernels and pseudo-applications have not been reconciled as a complete suite. |
| HPC Challenge | [Official suite description](https://www.hpcchallenge.org/hpcc/) | No suite crosswalk found. Existing `stream_vector_kernels`, `matrix_transpose`, FFT, and linear-algebra packages are possible operation-level overlaps, but HPCC's precise workload semantics have not been checked; no duplicates are confirmed. |
| HPCG | [Official operation and solver description](https://www.hpcg-benchmark.org/) | No suite crosswalk found. `conjugate_gradient`, `gauss_seidel_method`, and sparse-matrix packages are possible kernel overlaps; the HPCG multigrid-preconditioned solver and its sparse triangular solve remain unreviewed as complete behavior. |
| PARSEC | [Princeton technical report](https://www.cs.princeton.edu/techreports/2010/890.pdf) | No suite crosswalk found. Static search found a Black–Scholes option-price package and a Rodinia streamcluster gain-step package; their relationship to PARSEC's complete applications has not been established. |
| SPLASH-2 | [Available suite source mirror](https://github.com/staceyson/splash2) | No suite crosswalk found. Existing Barnes–Hut, radix-sort, FFT, and Cholesky packages are possible algorithm overlaps; source-level behavior and suite coverage remain unaudited. |
| CP-Algorithms, OI Wiki, Algorithm Archive, and Rosetta Code | Use as algorithm indexes and descriptions; compare behavior before recording candidates | Not yet reviewed systematically. |
| Codewars and LeetCode | Discovery only; respect their current terms and do not scrape or reuse problem text or submissions | Not yet reviewed systematically. |

## Library Checker candidate ledger

| Candidate | Decision | Repository comparison / owner |
| --- | --- | --- |
| Li Chao tree (dynamic line insertion and minimum query) | Confirmed distinct; implementation in progress | No Li Chao tree or equivalent line-container package found in a static filename/content search. Dynamic line queries are not the same algorithm as the existing [smallest enclosing circle](s/smallest_circle/README.md). Owned by `/root/li_chao_tree`; scope is its package and nine language ports only. [Yosupo line-add/get-min problem](https://judge.yosupo.jp/problem/line_add_get_min). |
| Dominator tree | Confirmed distinct; implementation in progress | No dominator, immediate-dominator, or Lengauer–Tarjan dominator implementation found. Existing connected dominating-set benchmarks and Tarjan offline LCA/SCC are different algorithms. Owned by `/root/dominator_tree`; scope is its package and nine language ports only. [Yosupo dominator-tree problem](https://judge.yosupo.jp/problem/dominatortree). |
| Segment tree beats (range chmin, chmax, add, and sum) | Confirmed distinct; implementation in progress | No segment tree beats or range-chmin/chmax package found. Existing point-update segment trees, lazy range structures, and wavelet trees do not implement this same operation set. Owned by `/root/segment_tree_beats`; scope is its package and nine language ports only. [Yosupo range chmin/chmax/add/sum problem](https://judge.yosupo.jp/problem/range_chmin_chmax_add_range_sum). |
| Directed minimum spanning arborescence (Chu–Liu/Edmonds) | Already present; no new package | Covered by [`edmonds`](e/edmonds/README.md), with a rooted directed graph contract. |
| Minimum enclosing circle | Already present; no new package | Covered by [`smallest_circle`](s/smallest_circle/README.md). |
| Global minimum cut (Stoer–Wagner) | Already present; no new package | Covered by [`stoer_wagner`](s/stoer_wagner/README.md). |

## Library Checker candidates awaiting review

These names appear in the [official Library Checker problem index](https://judge.yosupo.jp/) and have no same-name package in a static filename search. They remain unassigned until their contracts and algorithm identity are compared against all related local packages.

| Candidate | Initial local comparison | Status |
| --- | --- | --- |
| Three-edge-connected components | Existing bridges and two-edge-connected-subgraph packages do not compute 3-edge-connected components. | Pending contract review; no owner. [Problem](https://judge.yosupo.jp/problem/three_edge_connected_components). |
| Incremental strongly connected components | Static SCC packages compute a decomposition of a fixed graph; no insertion-only SCC package was found. | Pending contract review; no owner. |
| st-numbering | No package matching an st-numbering of a biconnected graph was found. | Pending contract review; no owner. |
| Counting Eulerian circuits | Eulerian path/trail packages construct a traversal; no circuit-counting package was found. | Pending contract review; no owner. |
| Counting spanning trees (undirected) | Existing minimum spanning tree algorithms optimize a tree's weight; no spanning-tree counting package was found. | Pending contract review; no owner. |
| Counting spanning trees (directed) | Existing directed arborescence optimization does not count rooted directed spanning trees; no counting package was found. | Pending contract review; no owner. |
| Minimum-cost b-flow | A min-cost max-flow package exists, but the general vertex-balance and circulation contract has not been compared. | Pending equivalence review; no owner. |
| Rooted tree isomorphism classification | Tree traversal, LCA, and centroid packages do not classify rooted trees up to isomorphism. | Pending contract review; no owner. |
| Euclidean / Manhattan MST | Generic graph MST packages accept explicit edge lists; no geometric candidate-generation package was found in the static name search. | Pending equivalence review; no owner. |
| Eertree / palindromic tree | Existing palindrome and Manacher packages do not expose the online palindromic-tree data structure. | Pending contract review; no owner. |

## Implementation and attribution rules

- Compare the mathematical operation, input/output contract, and relevant behavior before calling two names duplicates. Keep different algorithms or materially different computational tasks separate.
- Write clean-room implementations from algorithm descriptions. Do not copy submissions, tests, problem statements, or other source text. Link the discovery source and record applicable license or terms before reusing any material.
- Record each new candidate here before assigning it. Mark a candidate implemented only after all nine current language ports and suite registration are present; static presence is not runtime validation.
- While compiler profiling is underway, all work remains static. Do not run programs, tests, builds, compilers, benchmarks, or repository scripts.

# Algorithm source inventory

Checked 2026-10-16 against pinned default-branch commits from 34 non-archived TheAlgorithms algorithm repositories. The inventory contains 6,158 source files and 3,871 catalog records after splitting same-name files whose implementations expose different operations or semantics. Each source commit and file path is linked in [`catalog/algorithm-candidates.json`](catalog/algorithm-candidates.json).

## How to read this inventory

The pinned Java, Python, and Rust `graham_scan` sources map to the shared [`convex_hull_graham_scan`](benchmarks/c/convex_hull_graham_scan/README.md) contract for inputs with at least four distinct points, no three collinear points, and coordinates in `[-15,000, 15,000]`. This common domain avoids source-specific handling of three-point inputs, duplicate and collinear points, and Java's 32-bit orientation overflow. The benchmark's broader boundary and duplicate behavior is not attributed to these sources.

The pinned C `lexicographic_permutations` source sorts a string and repeatedly advances to its next lexicographic arrangement. Its distinct output rows match the `unique_permutation` benchmark on nonempty ASCII tokens excluding NUL and whitespace; the candidate is recorded as an alias. [C source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/misc/lexicographic_permutations.c) · [benchmark guide](benchmarks/u/unique_permutation/README.md).

The pinned C++ `inorder_successor_of_bst` copies agree on insertion and successor lookup; its contract uses distinct positive int32 keys and reserves 0 for an absent target or a target without a successor. See the [BST successor guide](benchmarks/i/inorder_successor_of_bst/README.md).


The pinned Go `constraints` source contains only compile-time generic type sets for signed, unsigned, integer, floating-point, numeric, and ordered types; it defines no standalone runtime algorithm, so it is recorded as non-benchmarkable. [Source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/constraints/constraints.go).

The pinned Swift `Minimax.playground/Contents.swift` file only creates the UIKit live view; the minimax game-search algorithm is recorded separately. [Playground source](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/algorithms/AI/minimax/Sources/Minimax.playground/Contents.swift).

The pinned MATLAB-Octave `UniformCrossover.m` selects each gene from one of two parents using an independent random binary mask. The [`uniform_crossover`](benchmarks/u/uniform_crossover/README.md) benchmark supplies that mask explicitly for deterministic cross-language calls.

The MATLAB-Octave `ELU.m` plotting demo contains the conventional scalar activation expression, now isolated in [`elu`](benchmarks/e/elu/README.md) with alpha supplied as an input. It remains distinct from the Rust `exponential_linear_unit` source, whose negative branch computes a different expression. The Java `ECC.java` candidate is excluded as invalid: its message encoder can create off-curve points, and its random curve setup does not validate the fixed base point. The Rust `elliptic_curve` group operations are already covered by the affine addition and scalar multiplication in [`elliptic_curve_key_exchange`](benchmarks/e/elliptic_curve_key_exchange/README.md).
The JavaScript `EvaluateExpression.js` source is a reverse Polish notation stack evaluator, not an infix parser. It maps to [`evaluate_expression`](benchmarks/e/evaluate_expression/README.md), which uses bounded milli-unit operands and binary64 results; integer postfix variants remain separately cataloged.
The C# ScapegoatTree `Extensions.cs` file only provides inorder flattening and midpoint rebuild helpers invoked by the parent scapegoat-tree rebalancing implementation; it is excluded as a standalone algorithm candidate.
The pinned Python `external_sort.py` candidate is excluded as invalid: its N-way merge selector never updates the current minimum and therefore returns the last run head instead of the smallest. [Source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/external_sort.py).
The pinned C# `ExternalMergeSorter<T>` uses width-doubling merge passes over sequential storage; [`external_merge_sorter`](benchmarks/e/external_merge_sorter/README.md) models those passes with two bounded buffers and excludes disk I/O.
The pinned Rust `finance_ratios.rs` exposes four formulas, now mapped separately to [`return_on_investment`](benchmarks/r/return_on_investment/README.md), [`debt_to_equity`](benchmarks/d/debt_to_equity/README.md), [`gross_profit_margin`](benchmarks/g/gross_profit_margin/README.md), and [`earnings_per_sale`](benchmarks/e/earnings_per_sale/README.md).
The pinned Java `FlattenMultilevelLinkedList.java` merges sorted child-linked columns by recursively flattening the right-hand suffix and merging each current column. The nine-language [`flatten_multilevel_linked_list`](benchmarks/f/flatten_multilevel_linked_list/README.md) package preserves that merge behavior over up to eight sorted chains of eight signed-i64 values, emits the merged sequence as little-endian i64 bytes, and returns the element count.
The pinned Python `update_image_and_anno` helper flips images horizontally or vertically and reflects the corresponding normalized bounding-box center. The nine-language [`flip_augmentation`](benchmarks/f/flip_augmentation/README.md) package models grayscale pixels and millionth-scaled boxes without the source's filesystem and image-codec wrapper.
The pinned Python `make_linked_list` rejects empty input, appends nodes in sequence order, and exposes that order through `Node.__repr__`. [`from_sequence`](benchmarks/f/from_sequence/README.md) preserves the representation for bounded signed-i64 sequences across all nine languages.
The Fortran `gaussian_legendre` candidate provides quadrature tables for orders 1–5. [`gaussian_legendre`](benchmarks/g/gaussian_legendre/README.md) specializes its callback to a bounded cubic polynomial and remains distinct from Java's [`gauss_legendre`](benchmarks/g/gauss_legendre/README.md) π iteration.
The Java, Python, and Rust `ford_fulkerson` implementations use BFS augmenting paths, matching the existing [`edmonds_karp`](benchmarks/e/edmonds_karp/README.md) contract.
The C `geometry_datatypes.h` candidate only declares vector, matrix, quaternion, and angle types; it contains no standalone algorithm.
The JavaScript `FindMonthCalendar.js` candidate maps to [`find_month_calendar`](benchmarks/f/find_month_calendar/README.md), preserving its Monday-first Gregorian output and 1900 epoch over a bounded range; each call uses fresh epoch state to isolate the source method mutation. [Source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/FindMonthCalendar.js).
The MATLAB-Octave `Sigmoid(without inbuilt).m` candidate maps to [`sigmoid_without_inbuilt`](benchmarks/s/sigmoid_without_inbuilt/README.md), preserving the source-provided slope in the scalar logistic formula; the existing unit-slope sigmoid remains distinct.
The Java `RowColumnWiseSorted2dArrayBinarySearch` candidate aliases [`saddleback_search`](benchmarks/s/saddleback_search/README.md) on the shared strictly increasing, unique matrix domain; its zero-based coordinate result is normalized to the benchmark's one-based flattened index, with zero for absence. The Python and Rust `modular_exponential` candidates alias [`modular_exponentiation`](benchmarks/m/modular_exponentiation/README.md) on the restricted signed-i32 domain base >= 0, power >= 1, modulus >= 2; negative powers and modulus-one behavior remain outside this alias contract.
The pinned Python grayscale threshold function maps to [`mean_threshold`](benchmarks/m/mean_threshold/README.md) on bounded nonempty rectangular images, and its four independent word/document frequency, IDF, and TF-IDF routines map to the grouped [`word_frequency_functions`](benchmarks/w/word_frequency_functions/README.md) package with separate operation tags.
The pinned Dart `symmetric_derivative` uses the centered finite-difference quotient with its default step; the bounded [`symmetric_derivative`](benchmarks/s/symmetric_derivative/README.md) contract keeps sin/exp differentiation distinct from root finding and dual-number automatic differentiation.
The Rust `field` candidate is excluded because its recorded source path is absent at the pinned commit, so the newer upstream Field module cannot be attributed to this snapshot.

The pinned Java `UnitsConverter` computes affine conversion inverses and compositions until its directed conversion map reaches closure. `UnitConversions.TEMPERATURE` supplies a fixed configuration of that same process and aliases the [`units_converter`](benchmarks/u/units_converter/README.md) benchmark's temperature profile.

The Julia `data_structure` module is only an export/include barrel, and the C# `fheap_node` plus Go `edge` and `root` candidates are supporting components of their parent data structures rather than independent algorithms. The Julia `dynamic_programming` file is likewise only a module barrel; C# `dictionary_extensions` forwards to the built-in dictionary, and PHP `execution_time` is a timing helper. The PHP `graph_edge` candidate is only a record declaration with no algorithmic behavior. The C# `euclidean` method matches the n-dimensional [`euclidean_distance`](benchmarks/e/euclidean_distance/README.md) contract. Haskell `graph_dist` is its three-dimensional origin and point-to-point special case. MATLAB `decrypt` is an interactive, hard-coded image-file demo, and MATLAB `crossover` randomly dispatches to three other routines, so those sources are recorded as non-benchmarkable.

The pinned Julia `Conversions.jl` file only exports and includes temperature, weight, and length conversion routines; the conversions themselves are inventoried as separate source candidates. [Module source](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/conversions/Conversions.jl).

The pinned Java `EmptyHeapException`, PHP `DuplicateKeyException`, C# hash-table `Entry`, and Swift Minimax `DifficultLevel` sources are support declarations or configuration values only; they contain no standalone benchmark algorithm and are recorded as non-benchmarkable. [Java exception](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/heaps/EmptyHeapException.java), [PHP exception](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/BinarySearchTree/DuplicateKeyException.php), [C# entry](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Hashing/Entry.cs), [Swift enum](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/algorithms/AI/minimax/Sources/Minimax.playground/Sources/Model/GameModel/DifficultLevel.swift).

Each candidate is based on a normalized source filename, with camelCase converted to snake_case. The list is a discovery aid: matching filenames do not prove that implementations use the same algorithm, input contract, edge cases, or output. Unreviewed filename candidates remain marked `unreviewed_filename_match` in the JSON until their implementations are inspected. The latest static coverage audit finds 2,506 distinct mapped benchmark names: 2,463 have complete files for all nine target languages, and 43 remain incomplete. Those 43 names are represented by 38 incomplete source-candidate rows. The audit covers 3,871 reviewed source candidates; 3,348 rows are complete, 485 sources are excluded (60 invalid and 425 non-benchmarkable), and 387 language implementation files are missing. These sources normalize to 2,944 canonical candidates and 927 aliases. This is a static presence audit and does not establish runtime correctness; see [`catalog/coverage.py`](catalog/coverage.py). The pinned Rust `negative_log_likelihood` source maps to [`negative_log_likelihood`](benchmarks/n/negative_log_likelihood/README.md), a source-ordered binary negative log-likelihood benchmark with a finite probability domain. The pinned Java `Cycles.java` source maps to [`directed_simple_cycles`](benchmarks/d/directed_simple_cycles/README.md), which preserves its directed DFS enumeration order, self-loops, and per-start edge clearing. The A5/1 cipher and key-stream-generator entries follow the pinned Java register-clock and frame-counter behavior, with separate plaintext-XOR and raw-stream contracts. See the [cipher guide](benchmarks/a/a5_cipher/README.md) and [key-stream guide](benchmarks/a/a5_key_stream_generator/README.md). The pinned C# AA tree is ported with its Skew/Split insertion and level-decreasing deletion operations; the portable contract uses signed 32-bit keys and natural ordering. See the [AA tree guide](benchmarks/a/aatree/README.md). The pinned C and C++ ADALINE learner sources share a sequential sign-prediction update; the benchmark uses a deterministic fixed-point projection for exact cross-platform updates. See the [ADALINE guide](benchmarks/a/adaline_learning/README.md). The pinned Rust Adam implementation carries first and second moments with bias correction and decoupled weight decay; nine portable ports share a bounded multi-parameter trace contract. See the [Adam guide](benchmarks/a/adam/README.md) and [source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/machine_learning/optimization/adam.rs). The Python `adam_optimizer` candidate uses the same update with state keyed by parameter-group ID and aliases this benchmark. The C LeetCode filename `231` aliases `power_of_two`; `atbash` aliases `atbash_cipher`; `xorcipher` aliases `xor_cipher`; `a1z26` aliases `a1z26_cipher`; `caesar` aliases `caesar_cipher`; `vigenere` and `vignere_cipher` alias `vigenere_cipher`; C filename `9` aliases `palindrome_number`; C LeetCode filename `190` aliases `reverse_bits`; C LeetCode candidate `119` uses benchmark name `pascal_triangle_row`; C candidate `215` uses benchmark name `kth_largest_by_sort`; Python `kth_largest_element` uses the quickselect benchmark. C LeetCode candidate `4` uses benchmark name `median_of_two_sorted_arrays`; candidate `2125` uses benchmark name `number_of_laser_beams`; candidates `2482` and `2501` use benchmark names `ones_minus_zeros` and `longest_square_streak`, respectively. C LeetCode candidate `274` uses benchmark name `h_index`. Candidate `278` uses benchmark name `first_bad_version`. Candidate `287` uses benchmark name `find_duplicate_number`. Candidate `234` uses benchmark name `palindrome_linked_list`. C LeetCode candidate `2130` uses benchmark name `maximum_twin_sum_of_linked_list`. The C LeetCode filename `121` and Java `stock_profit_calculator` alias `best_time_to_buy_and_sell_stock`. The C LeetCode filename `136` is reviewed as an alias of `single_number`. The C LeetCode filename `10` is reviewed as an alias of `regex_match`; candidate `11` uses benchmark name `container_with_most_water`; candidate `125` uses benchmark name `valid_palindrome`; C LeetCode candidate `101`, Java `check_tree_is_symmetric`, and Python `symmetric_tree` share the recursive mirror-check contract; C LeetCode candidate `1019` uses benchmark name `next_greater_nodes`; C LeetCode candidate `1026` uses benchmark name `max_ancestor_diff`; C LeetCode candidate `104` uses benchmark name `max_depth`; C LeetCode candidate `110` uses benchmark name `balanced_binary_tree`; C LeetCode candidate `404` uses benchmark name `sum_of_left_leaves`; C LeetCode candidate `965` uses benchmark name `univalued_binary_tree`; C LeetCode candidate `124` aliases `binary_tree_maximum_path_sum`; C LeetCode `12`, `decimal_to_roman`, `decimal_to_roman_numeral`, and `inttoroman` alias `integer_to_roman`; `roman_numeral_util` aliases `integer_to_roman`; `roman_numerals` aliases `roman_to_integer`; `roman_numerals_to_decimal`, `roman_to_decimal`, and `romantoint` alias `roman_to_integer`; C LeetCode candidate `13` aliases `roman_to_integer`; C LeetCode candidate `14` aliases `max_consecutive_ones`; `regex_matching` in Java implements wildcard matching and is tracked separately. The C LeetCode filename `1` is reviewed as an alias of `two_sum`; the `letter_combination` filename is recorded as an alias of `letter_combinations_of_phone_number`; `edit_distance`, `levenshtein`, and `levenshteindistance` alias `levenshtein_distance`; `coin_change_topdown` aliases `coin_change`; `lcs` aliases `longest_common_subsequence`; `decimal_to_any` aliases `decimal_to_any_base`; `int_to_base` and `base_x` alias `decimal_to_any_base`; `arbitrary_base` aliases `any_base_to_any_base`; `int_to_negative_binary_base` aliases `base_neg2_conversion`; and `prime_sieve`, `prime_sieve_eratosthenes`, `eratosthenes_sieve`, `sieve_er`, `sieve2`, and `odd_sieve` alias `sieve_of_eratosthenes`; `bogo_sorter` and `bogosort` alias `bogo_sort`; `greatest_common_divisor` aliases `gcd`; and `least_common_multiple` aliases `lcm`; `circular_queue` aliases `queue`; `singly_linked_list` aliases `linked_list`; `knapsack` and R candidate `1_knapsack_problem` alias `knapsack_zero_one_tabulation` for their 0/1 dynamic-programming variants; `fractional_knapsack_2` aliases `fractional_knapsack`; `abundant_numbers` aliases `abundant_number`; `add_digits` aliases `digital_root`; `iterative_merge_sort` and `non_recursive_merge_sort` alias `merge_sort_nr`; `merge_sort_recursive` and `recursive_mergesort_array` alias `merge_sorter`; `quick_sort_3_ways` aliases `quick_sort_3`; `circlesort` aliases `circle_sort`; `brick_sort`, `oddevensort`, and `odd_even_transposition_single_threaded` alias `odd_even_sort`; `shaker_sort` and `cocktail_shaker_sort` alias `cocktail_sort`; `shellsort` and `shell_sorter` alias `shell_sort`; `select_sort` and `selectionsort` alias `selection_sort`; `recursive_insertion_sort` aliases `insertion_sort_recursive`; `recursive_quick_sort` and `quick_sort_recursive` alias `quick_sort`; `mergesort` aliases `merge_sorter`; `slowsort` aliases `slow_sort`; `timsort` aliases `tim_sort`; `random_quick_sort`, `randomized_quick_sort`, and `random_pivot_quick_sorter` alias `random_pivot_quick_sort`; `radixsort`, `radix_sort2`, and `radix_sort_2` alias `radix_sort`; `pigeonhole_sort`, `pigeon_sort`, `pigeonholesort`, and `pigeon_hole_sort` alias `counting_sort`; The Go/Lua `bubblesort` filename aliases `bubble_sort`; Go `cocktailsort`, `cyclesort`, `heapsort`, `insertionsort`, `pancakesort`, `patiencesort`, and `exchangesort` alias their matching benchmark names; Go/Lua `countingsort` and Dart/PHP `count_sort` alias `counting_sort`; C `bubble_sort_2` and PHP `bubble_sort2` alias `bubble_sort`; C `bubble_sort_recursion` aliases `bubble_sort_recursive`; Go `bucketsort` aliases `bucket_sort`; C-Sharp `BucketSorter` aliases `radix_sort` because it sorts by repeated decimal-digit bucket passes; `binary_insertion_sorter` and `binaryinsertionsort` alias `binary_insertion_sort`; C-Sharp `counting_sorter` aliases `counting_sort`; C-Sharp `exchange_sorter` aliases `exchange_sort`; JavaScript `heap_sort_v2` aliases `heap_sort`; Dart `insert_sort` aliases `insertion_sort`; `subset_sum` maps signed existence; `subset_sum_count`, `subset_sum_dynamic`, and `subset_sum_values_enumeration` are separate count, signed memoized, and positive-only value-list contracts; `subset_sum_space_optimized` and `subsetsum` alias the positive-only decision package. C-Sharp `aliquot_sum_calculator` and Go `aliquotsum` are reviewed aliases of `aliquot_sum`. Java `AmicableNumber`, C# `AmicableNumbersChecker`, and the Dart/R predicates in `amicable_numbers` map to `amicable_number`; the Java range enumerator and Julia/Rust range algorithms in `amicable_numbers` map to `amicable_pairs_below`. C++ `count_of_trailing_ciphers_in_factorial_n` aliases `factorial_trailing_zeroes`; Ruby `binary_count_trailing_zeroes` aliases `binary_count_trailing_zeros`. The pinned PHP `ArrayKeysSort` candidate is mapped to a numeric multi-key row sort with explicit key priority and direction; tied selected-key tuples are excluded from its portable contract. The Go `avl` and C, Python, and Rust `avl_tree` sources share the existing unique-key AVL operations contract; Ruby is tracked separately for unique-key insert/search/traversal because its deletion path is unsafe for general deletes. The MD5 candidate maps C++, Go, JavaScript, Python, and Rust to a byte-oriented digest contract; Python hex output is normalized to raw digest bytes, and the C++ source endian helper is limited to little-endian hosts. The Python `validate_sudoku_board` candidate checks duplicate filled digits in rows, columns, and 3×3 boxes; it validates a supplied board and does not test solvability. The SHA-1 candidate maps the C++, Go, JavaScript, Python, and Rust byte-oriented implementations to a raw digest contract; its AArch64 entry is a fixed-input demo and is outside that shared interface. The SHA-256 candidate maps the C++, Go, JavaScript, and Python byte-oriented implementations to a raw digest contract; its AArch64 entry is a fixed-input demo outside the shared interface. The `heap` candidate maps the data-structure implementations to max-heap operations; its Rust Heap permutation generator is tracked separately because its output order differs from `all_permutations`. The LRU cache sources map to a positive-capacity page-reference trace with hit, eviction, and MRU-to-LRU outputs; Zig recency is refreshed explicitly on hits. The treap sources map to a unique-key set trace with known-present deletes and sorted final contents; randomized priorities and internal tree shape are ignored. The Hopcroft–Karp candidate compares maximum matching cardinality across C++, Java, and Python, not matching-pair choices. The Huffman candidate compares weighted encoded bit cost to avoid tie-dependent code maps. The binary k-nearest-neighbors contract excludes distance and vote ties. The linked-queue trace avoids empty dequeues and reuse after emptying, which the TypeScript source cannot handle. The BFS filename covers three source contracts: connected traversal order, Ruby parent/distance result trees, and Go greedy coloring. The binary-heap candidate uses incremental min-heap insertion and extraction across C#, JavaScript, Julia, and R; comparisons cover output order rather than internal heap layout. The separate `min_heap` candidate bulk-builds then extracts all values in ascending order; Dart exposes only `buildHead`, so its package documents an extraction adapter, and Dart `min_heap_two` aliases the same output contract. The Dijkstra candidate uses a bounded connected graph domain with source 0 and positive weights to preserve the C#, Java, and Python source behavior. The skip-list candidate uses a unique-key set trace with membership queries and known-present deletes; randomized tower heights are not compared. The graph candidate is split into C adjacency-matrix, Go coloring, JavaScript traversal, Lua directed weighted, Rust weighted, and Swift directed-path contracts; its Julia entry is an aggregator. The heavy-light-decomposition filename is split into path-sum, path-maximum, and decomposition-metadata contracts because the pinned C++, Java, and Rust sources expose different operations. The `knight_tour` contract fixes an 8×8 DFS move order from (0,0); Python order differences are normalized and the broken JavaScript source is documented. The Java `knights_tour` candidate remains a separate Warnsdorff-order open-tour contract. The Python transitive-closure source uses reflexive reachability (diagonal initialized true); the C source is a fixed non-reflexive graph demo and is documented as a source-specific mismatch. `autocomplete_using_trie` returns sorted unique lowercase-ASCII prefix matches to normalize Rust hash iteration and Python terminal markers. Repeated inserted words are accepted and deduplicated; all nine ports passed 404 oracle cases each and recorded nine workload cases. See the [guide](benchmarks/a/autocomplete_using_trie/README.md), [verifier](benchmarks/verify_autocomplete_using_trie.py), and the pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/autocomplete_using_trie.py) and [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/autocomplete_using_trie.rs). The B-tree candidate shares unique-key inserts, membership queries, known-present deletes, and sorted final keys; workloads exceed Lua’s 509-key root capacity. The `crc32` contract accepts explicit bytes; Java’s platform-default-charset String overload is excluded. C `hash_crc32` aliases it only for empty or NUL-free ASCII input because its NUL-terminated API cannot represent embedded NUL bytes or the broader byte-array contract. See the [CRC32 guide](benchmarks/c/crc32/README.md). The Count-Min Sketch contract uses width 1 and depth 3 so all bounded keys deterministically collide. The CRC-8 model contract makes polynomial and reflection parameters explicit. The `node` and `avltree_node` helper candidates, the `client`/`server` I/O demos, and `logistic_regression_2` are excluded as helper-name collisions or incomplete I/O/library-demo snippets without portable algorithm contracts. The main logistic-regression candidate is split into Python, C#, and Rust training contracts because intercept and gradient-normalization behavior differs across the handwritten sources. The C# `backtracking_nqueens_solver` returns all solutions in DFS row order for n≤8; the matching C++ N-Queens sources alias it for n=1..8. The Dart, Python math, Rust, Haskell, Java, and JavaScript count APIs map to a separate scalar solution-count package, while the broken Python mutable-result implementation and optimized C++ duplicate-producing variant are excluded. `tournament_sort` sorts signed i32 arrays through a winner tree. The min-max heap contract covers both extrema and bulk/trace operations; Zig `red_black_trees` has a separate insert/search-only contract because it has no deletion. The Go `set` source is mapped to full set algebra with sorted outputs, while its TypeScript companion is interface-only. The misspelled Dart `knuth_morris_prat` candidate has a Boolean KMP contract, including its false result for an empty pattern. The Python undirected Eulerian-trail source is constrained to simple connected nonzero-degree graphs because it does not handle parallel edges or connectivity checks. `flash_sort` maps the pinned Java, JavaScript, and Python distribution-and-permutation implementations to one bounded signed-integer contract with their final insertion pass; the Java classifier defect and Java/JavaScript two-element failure are documented. `coordinate_compression` maps Python values to zero-based ranks of sorted distinct values and emits ranks in original order; its portable contract narrows the comparable source types to signed int32. `gamma` benchmarks the pinned recursive recurrence; the separate `gamma_iterative` wrapper delegates to SciPy quadrature and is excluded as an external library call. `parse_integer` preserves Java int32 wraparound while restricting input to ASCII bytes and normalizing malformed-input errors. The `good_pairs` source row maps its nested scan and frequency-map files to separate benchmarks. The Java heap-based `find_kth_number` package preserves sequential max-heap insertion and repeated removal, separately from the quickselect candidates. Tests, examples, benchmarks, documentation, scripts, build output, and vendor directories are omitted. Project Euler `solN` files include their problem number in the candidate name. The Python `basic_graphs.py` candidate maps BFS, DFS, Dijkstra, topological sort, Floyd–Warshall, Prim, and Kruskal to shared contracts; `find_isolated_nodes` is ported as a separate benchmark, while graph input helpers are excluded. The Java and R `prim_mst` sources alias the existing Prim contract on their five-vertex connected positive-weight common domain; the misnamed JavaScript source aliases Dijkstra through a parent-tree distance adapter. The Python `basic_maths.py` candidate maps prime factors, positive-divisor counting, and Euler totient to shared contracts. Its divisor-sum implementation misses a residual prime factor, so the new `sum_of_divisors` benchmark records the defect and ports the conventional sigma function. See the [isolated-node guide](benchmarks/f/find_isolated_nodes/README.md).
## Recently reviewed source mappings

The pinned Python `priority_queue_using_list.py` contains two independent queue classes. [`fixed_priority_queue_using_list`](benchmarks/f/fixed_priority_queue_using_list/README.md) uses three FIFO buckets, preserving the source's priority scan order and Python's negative-index mapping for priorities -3 through -1; [`element_priority_queue_using_list`](benchmarks/e/element_priority_queue_using_list/README.md) stores values in one unsorted list and removes the first minimum. The bucket queues hold at most 100 values per bucket, while the element queue holds at most 100 values total. Both emit dequeued signed-i32 values as little-endian i64 words.

The pinned Python `primelib.py` bundle maps its even/odd checks, prime testing and listing, factorization, divisors, perfect-number check, LCM, nth-prime lookup, Goldbach pairs, factorial, and shifted Fibonacci routine to existing contracts on their source-compatible domains. Greatest and smallest prime factors, prime intervals, and signed-fraction simplification remain separate open gaps; 97b has statically cleared the source-to-contract mapping.

The separate [`greatest_prime_factor`](benchmarks/g/greatest_prime_factor/README.md) contract preserves the pinned source's 0 and 1 sentinels, rejects negative inputs, and uses repeated prime-factor division for positive values; its docs, oracle, and nine ports are statically cleared, with scalar runner/verifier integration statically cleared. The [`smallest_prime_factor`](benchmarks/s/smallest_prime_factor/README.md) contract is bounded to 2..1,000,005 to preserve the source's factor-list semantics; its docs, workload, oracle, and all nine ports are statically cleared; scalar runner/verifier integration is statically cleared.

The separate [`simplify_fraction`](benchmarks/s/simplify_fraction/README.md) contract uses bounded signed numerator/denominator pairs and preserves the source's denominator sign. Its README, workload, oracle, and nine suite-language ports are statically cleared, and the byte-output runner/verifier cover the valid and ABI boundary cases.

The separate [`get_primes_between`](benchmarks/g/get_primes_between/README.md) contract uses prime endpoints in 2..997 and returns the strict interior primes as comma-separated ASCII; empty interiors map to the source's index error. Its README, workload, oracle, all nine ports, and byte-output runner/verifier integration are statically cleared.

The Java [`rrcache`](benchmarks/r/rrcache/README.md) package fixes a single-threaded cache trace, Java's seeded `Random` sequence, insertion-only replacement draws, and TTL safely beyond the trace; the README, workload, oracle, all nine ports, and i64 byte-output runner/verifier integration are statically cleared. See the pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/caches/RRCache.java).

The C# and Dart [`priority_queue`](benchmarks/p/priority_queue/README.md) contract uses their common min-priority behavior for unique signed-i32 priorities and valid nonempty enqueue/peek/dequeue traces; ties, empty operations, and backing-layout details are excluded. Its README, workload, oracle, and all nine ports are statically cleared; shared runner/verifier integration is statically cleared. See the pinned [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Search/AStar/PriorityQueue.cs) and [Dart source](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/data_structures/Queue/Priority_Queue.dart).

The [`robin_hood_hash`](benchmarks/r/robin_hood_hash/README.md) contract is a fixed-capacity Zig Robin Hood map trace bounded to capacity 16 and at most 14 live entries, staying below the source's load and probe guards. Its README, workload, oracle, and all nine ports are statically cleared; byte-output runner/verifier integration is statically cleared. See the pinned [Zig source](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/tiger_style/robin_hood_hash.zig).

The [`hash_table`](benchmarks/h/hash_table/README.md) contract proposal narrows the C#, Python, and Rust candidates to unique positive key=value inserts with collision-free source-specific capacities, followed by membership queries; updates, duplicates, removals, collisions, and resizing are excluded. The README, workload, oracle, and all nine ports are statically cleared; runner/verifier registration is statically cleared.

The scalar [`kalman_filter`](benchmarks/k/kalman_filter/README.md) contract follows Java `filter(double)` with fixed-point inputs and emits estimate, covariance, and gain after each measurement. Its contract artifacts, all nine ports, and float64 runner/verifier integration are statically cleared. The R two-state simulation remains a separate candidate.

The Python [`mini_batch_gradient_descent`](benchmarks/m/mini_batch_gradient_descent/README.md) contract supplies per-epoch permutations to preserve deterministic sequential mini-batch updates without reproducing NumPy RNG state. README, workload, and oracle are with the reviewer; ports have not started.

The Java antithetic [`monte_carlo_integration`](benchmarks/m/monte_carlo_integration/README.md) variant has nine port files, but static review found a missing null-input probe and inconsistent pointer-language null handling; the author is correcting these. The Julia independent-draw variant has a separate contract and its nine ports are in progress. Float64 runner/verifier dispatch for both variants is registered and submitted for static review.

The R [`monte_carlo_simulation`](benchmarks/m/monte_carlo_simulation/README.md) candidate uses one end-to-end discounted option-price contract with explicit normal variates in simulation-major/step-major order. Its README, workload, and oracle are with 97b for static review; nine ports remain.

The Rust [`principal_component_analysis`](benchmarks/p/principal_component_analysis/README.md) candidate is tracked separately from the R PCA package because it centers unscaled inputs, uses population covariance and power iteration, and returns projected scores only. Its contract covers one to four components with rank-one deflation and a deterministic simulator stability guard; README, workload, oracle, and all nine ports are statically cleared.

The R [`pca`](benchmarks/p/pca/README.md) contract standardizes each column, forms the sample covariance, and projects onto the top principal components with a canonical eigenvector sign rule. Its README, workload, oracle, all nine ports, and float64 runner/verifier integration are statically cleared. Keep it separate from the Python PCA and Rust `principal_component_analysis` candidates; the Rust source centers unscaled inputs and returns projected scores only, so it needs its own contract. See the pinned [R source](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/data_preprocessing/pca.r).

The Julia [`permutation_count`](benchmarks/p/permutation_count/README.md) variant is separately tracked as an nPr count and has all nine ports and scalar runner/verifier registration statically cleared. The Java [`permutation_array`](benchmarks/p/permutation_array/README.md) variant preserves duplicate arrays and recursive order; its contract, all nine ports, and byte-output runner/verifier integration are statically cleared. The C# [`permutation_unique_string`](benchmarks/p/permutation_unique_string/README.md) variant preserves unique strings and uses canonical lexicographic output for the source's unordered HashSet result; its contract, all nine ports, and byte-output runner/verifier integration are statically cleared.

The [`ramer_douglas_peucker`](benchmarks/r/ramer_douglas_peucker/README.md) contract, oracle, and workload are statically cleared. Its all-chord compatibility preflight requires Python and Rust distance formulas to choose the same split and epsilon decision. All nine ports are statically cleared; Odin, V, and Zig recursion use Python’s `hypot` expression, and preflight checks Rust/Python split and epsilon-decision agreement on every original chord.

The [`scapegoat_tree`](benchmarks/s/scapegoat_tree/README.md) contract, all nine language ports, and byte-output runner/verifier registration are submitted for static review.

The [`splay_tree`](benchmarks/s/splay_tree/README.md) contract covers the common Java/Python unique-key insert, search, and known-present delete trace; PHP stays excluded. Adapter-level invalid fixtures reject duplicate inserts and empty-tree deletes before source calls. Contract files, all nine ports, and runner/verifier registration are statically cleared.

The pinned JavaScript `Shuf.js` source maps to [`shuf`](benchmarks/s/shuf/README.md), which preserves its initial cyclic slot placement and later reservoir-replacement pass while supplying each random draw as bounded input. Results retain occupied-slot order and are emitted as little-endian signed-i32 values.

The pinned Lua `table_list.lua` source maps to [`table_list`](benchmarks/t/table_list/README.md), which exercises the list-backed structure's 1-based indexing, head/tail operations, bounds checks, and forward/reverse iterators. Each operation records its return values, followed by a final list snapshot.

The pinned Lua `shuffle.lua` source maps to [`shuffle`](benchmarks/s/shuffle/README.md), which preserves the forward Fisher–Yates swap order with explicit bounded offsets, one per iteration, instead of depending on Lua's process-global random sequence. [Lua source](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/random/shuffle.lua).

The pinned Python `random_graph_generator.py` source maps to [`random_graph_generator`](benchmarks/r/random_graph_generator/README.md). For 0<p<1 it draws once per unordered pair in nested i<j order; p<=0 returns no edges, and p>=1 returns an undirected complete graph even in directed mode. The benchmark supplies 53-bit draws explicitly to keep those source decisions deterministic. [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/random_graph_generator.py).

The pinned Python `single_indeterminate_operations.py` source maps to [`single_indeterminate_operations`](benchmarks/s/single_indeterminate_operations/README.md). It preserves low-degree-first coefficients and the source's six numeric operations, including an empty coefficient vector for the derivative of a constant; formatting and equality are excluded. [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/polynomials/single_indeterminate_operations.py).

The pinned Go serial `MonteCarloPi` source maps to [`montecarlopi`](benchmarks/m/montecarlopi/README.md), with explicit sample points replacing the source time-seeded draws. It preserves the point-boundary comparison and division-then-multiplication order; the concurrent variant is excluded. [Go source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/pi/montecarlopi.go).

The pinned Java `SelfAdjustingScheduling.scheduleNext` source maps to [`self_adjusting_scheduling`](benchmarks/s/self_adjusting_scheduling/README.md). The bounded trace updates each selected task's priority by its cumulative wait time and rejects tied priorities before a poll so the source's priority-only comparison remains deterministic.

The pinned JavaScript `ReverseSinglyLinkedList.solution` source maps to [`reverse_singly_linked_list`](benchmarks/r/reverse_singly_linked_list/README.md), which reverses up to 256 signed-i32 payloads and emits them as little-endian bytes. Null input remains invalid at length zero, and output-pointer and capacity errors follow input validation.

The pinned Go `cache.LRU` source maps to [`lru`](benchmarks/l/lru/README.md), which records put/get results and the final cache from least-recently-used to most-recently-used. Its bounded traces preserve recency refresh and eviction behavior on capacity 2..16.

The pinned C++ `linkedlist_implentation_usingarray` source maps to [`linkedlist_implentation_usingarray`](benchmarks/l/linkedlist_implentation_usingarray/README.md), preserving its fixed 100-node array pool and head/tail insertion trace while emitting the final list in head-to-tail order.

The pinned Rust `snail` source maps to [`snail`](benchmarks/s/snail/README.md), which traverses bounded rectangular signed-i32 matrices clockwise inward and excludes the source's panic-prone multi-row, one-column shape.

The pinned Rust `PCG32` source maps to [`random`](benchmarks/r/random/README.md), which preserves the custom 64-bit state initialization and XSH-RR output sequence while supplying seed, multiplier, stream, and count explicitly.

The pinned Java `ReverseKGroup.reverseKGroup` source maps to [`reverse_kgroup`](benchmarks/r/reverse_kgroup/README.md), which reverses complete groups of up to 256 signed-i32 payloads and leaves the final short group unchanged.

The pinned Java `SelfOrganizingLinkedList` source maps to [`self_organizing_linked_list`](benchmarks/s/self_organizing_linked_list/README.md), preserving tail insertion, first-match lookup, and move-to-front behavior while recording each operation and the final list snapshot.

The pinned Python `rmsprop.py` source performs one ordered update of each parameter and its running square-gradient state. [`rmsprop`](benchmarks/r/rmsprop/README.md) makes the updated parameters and state visible through a bounded `float64_slice_io` contract with either zero-initialized or explicitly supplied state. All nine language ports and the 17 semantic plus 9 ABI workload cases are present.

The pinned Python `proof_of_work` source maps to [`simple_proof_of_work`](benchmarks/s/simple_proof_of_work/README.md), which hashes the delimiter-free UTF-8 preimage with SHA-256, searches nonce values inclusively from zero through the bounded cap, and returns the first matching nonce with its lowercase digest.

The pinned Python `sharpe_ratio` source maps to [`sharpe_ratio`](benchmarks/s/sharpe_ratio/README.md), which computes a non-annualized ratio from micro-unit periodic returns, sample standard deviation, and a per-period risk-free rate.

The pinned Java `SJFScheduling` source maps to [`sjfscheduling`](benchmarks/s/sjfscheduling/README.md), which schedules arrived processes nonpreemptively by shortest burst, preserves arrival and input order on ties, and emits completion-order input indices.

The pinned Java `RottingOranges.run` source maps to [`rotting_oranges`](benchmarks/r/rotting_oranges/README.md), which preserves copied rectangular 0/1/2 grids, four-neighbor multi-source BFS, zero for null/empty/zero-width inputs, and `-1` for unreachable fresh oranges. The packed contract uses `INT64_MIN` for malformed inputs; its 255-minute finite-result bound is conservative for a 16×16 grid. See the pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/graphs/RottingOranges.java).

The pinned C++ and C++-1 `queue_using_array.cpp` copies implement the same capacity-10 linear FIFO. The benchmark restricts values to signed 8-bit to preserve the source dequeue narrowing, and keeps no-prefix-reuse, empty-dequeue-zero, and reset-after-drain behavior. See the [guide](benchmarks/q/queue_using_array/README.md), [C++ source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/queue_using_array.cpp), and [C++-1 source](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/queue_using_array.cpp).

The pinned C++ and C++-1 `queue_using_array2.cpp` copies implement the same capacity-10 shifting FIFO. Its benchmark records every post-operation queue state, including compaction and capacity reuse, while excluding display text; it remains distinct from the linear no-prefix-reuse queue. See the [guide](benchmarks/q/queue_using_array2/README.md), [C++ source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/queue_using_array2.cpp), and [C++-1 source](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/queue_using_array2.cpp).

The pinned C `quat_from_euler`, `euler_from_quat`, and `quaternion_multiply` routines map to [`quaternions`](benchmarks/q/quaternions/README.md), preserving their binary32 formulas, the executable source's plus-sign pitch expression, and scalar-first Hamilton products while widening results to binary64.

The pinned Python `heap_generic.py` maps to [`heap_generic`](benchmarks/h/heap_generic/README.md), preserving the bounded max-heap insert, peek, extract, priority-update, and delete operations with unique IDs and distinct live priorities.

The pinned Zig `ring_buffer.zig` maps to [`ring_buffer`](benchmarks/r/ring_buffer/README.md), which covers the full capacity-8 API including wraparound, indexed access, front/back peeks, clear, and explicit full/empty results beyond FIFO queue behavior.

The pinned JavaScript, C#, Python, and Rust softmax functions map to [`softmax`](benchmarks/s/softmax/README.md) over finite one-dimensional logits in [-20,20]. C# `SoftMax.Compute` directly exponentiates each logit, sums in input order, and normalizes in a second pass. The MATLAB-Octave file is a fixed-grid plotting script and is excluded as non-benchmarkable.

The pinned Lua `median_heap` keeps a max-heap for the lower half and a min-heap for the upper half; `top` returns the lower median for even-sized traces, and `pop` rebalances after removal. [`median_heap`](benchmarks/m/median_heap/README.md) emits one signed-i64 result per operation, using `INT64_MIN` to encode Lua `nil` without colliding with signed-i32 values.

The pinned Lua `table_heap.lua` maps to [`table_heap`](benchmarks/t/table_heap/README.md), a mutable-priority min-heap keyed by unique signed-i32 IDs. Its bounded trace covers push, top, pop, priority changes, replacement, removal, lookup, and size queries while preserving the source's strict-comparison tie order. Ports maintain an ID-to-current-index map for direct lookup and use `INT64_MIN` for nil results.

The pinned C# `PollardsRhoFactorizing.Calculate` source maps to [`pollards_rho_factorizing`](benchmarks/p/pollards_rho_factorizing/README.md). Its deterministic `x=y=2` recurrence returns the first gcd other than 1, which can equal the input; the contract restricts inputs to 2..46340 to avoid the source's signed 32-bit square overflow.

The pinned C `ssort2main` multikey string quicksort maps to [`multikey_quick_sort`](benchmarks/m/multikey_quick_sort/README.md). It preserves the deterministic insertion-sort and median-of-three/pseudomedian-of-nine paths and sorts length-prefixed ASCII byte strings lexicographically.

The pinned Python `maxpooling` function maps to [`max_pooling`](benchmarks/m/max_pooling/README.md). It computes row-major maxima over full square windows and emits raw little-endian f64 values; the adjacent `avgpooling` function is outside this contract.

The pinned Python `gradient_descent` function maps to [`linear_regression_vectorized`](benchmarks/l/linear_regression_vectorized/README.md). The benchmark preserves the source's vectorized coefficient update order over a bounded finite dataset with an explicit intercept column.

The MATLAB-Octave `Predict.m` helper maps to [`logistic_regression_predict`](benchmarks/l/logistic_regression_predict/README.md), which computes row-feature dot products using supplied parameters and packs a bit when the corresponding sigmoid score is at least 0.5. This covers prediction with supplied parameters, separate from the catalog's training contracts.

The pinned Zig `time_simulation` source maps to [`time_simulation`](benchmarks/t/time_simulation/README.md), which hashes each virtual-clock action result and fired event in source order. The contract preserves the 1024-event active queue, inclusive ticks, first-slot tie order, and the maximum 4092 callbacks across a 4096-action trace.

The pinned C++ `ans`, `multiply`, and `power` functions map to [`matrix_exponentiation`](benchmarks/m/matrix_exponentiation/README.md), which preserves the order-k recurrence, modulo reductions, and recursive companion-matrix power. The C++-1 source is a duplicate repository entry; Python's similarly named implementation has different semantics and is excluded.

The pinned C# `MillerRabinPrimalityChecker` maps to [`miller_rabin_primality_checker`](benchmarks/m/miller_rabin_primality_checker/README.md), with odd signed-32-bit `n`, bounded rounds, and an explicit seed normalized through SplitMix64. It selects one witness per call and reuses it for every round, preserving the source's observable control flow. This is separate from the fixed-base [`miller_rabin`](benchmarks/m/miller_rabin/README.md) contract.

The pinned Java `HungarianAlgorithm.solve` maps to [`hungarian_algorithm`](benchmarks/h/hungarian_algorithm/README.md), which zero-pads rectangular cost matrices and preserves the source's ascending scan and strict-comparison tie behavior. It emits one assignment per row followed by the total cost as little-endian signed-i32 values.

The pinned C++ `backtracking::rat_maze::solveMaze` maps to [`rat_maze`](benchmarks/m/rat_maze/README.md), which encodes the first right-before-down path as a row-major solution matrix and preserves the source's malformed-input and output-capacity behavior.

The two pinned C++ `mo.cpp` programs answer distinct-value range queries with offline Mo ordering, using `ceil(sqrt(n))` blocks and restoring answers to input order. The benchmark bounds the array to 64 values in `[0,255]` and supports zero queries; zero-byte success requires a non-null output pointer, while null output returns `-2`. See the [Mo guide](benchmarks/m/mo/README.md).

The pinned Python `prisms_algorithm` maps to [`minimum_spanning_tree_prims`](benchmarks/m/minimum_spanning_tree_prims/README.md), preserving vertex-zero rooting, the indexed-heap tie rules, and parent-to-child edge extraction order.

The pinned Java `generatePerlinNoise` method maps to [`perlin_noise`](benchmarks/p/perlin_noise/README.md), preserving Java `Random` initialization, x-major output ordering, and binary32 rounding at each source float operation.

The pinned lac-dcc `Misc/perlin` kernel maps to [`improved_perlin_noise_3d`](benchmarks/i/improved_perlin_noise_3d/README.md), which uses a fixed permutation and hashed 3D gradient interpolation. It is distinct from the seeded 2D value-noise method above.

The pinned lac-dcc `Misc/dt` kernel maps to [`misc_dt`](benchmarks/m/misc_dt/README.md), a repeated elementwise double-precision vector division loop initialized with float32 trigonometric values. It has a different operation from the existing array-multiply and STREAM kernels.

The pinned lac-dcc [`Misc/himenobmtxpa`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/himenobmtxpa/himenobmtxpa.c) kernel maps to [`himenobmtxpa`](benchmarks/h/himenobmtxpa/README.md), a bounded binary32 weighted point-Jacobi solver for a 3D Poisson pressure equation. It reports the final residual sum and is distinct from the existing 2D Jacobi stencil and 3D heat-diffusion kernel. The pinned source has no explicit license grant; the ports were written independently.

The pinned lac-dcc [`CoyoteBench/lpbench`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/CoyoteBench/lpbench/lpbench.c) and [`Linpack`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Linpack/linpack-pc.c) launchers use the same pivoted LINPACK `dgefa` factorization and `dgesl` solve covered by [`linpack_lu_solve`](benchmarks/l/linpack_lu_solve/README.md). Their matrix generation, larger problem sizes, timing, and report formats are workload profiles rather than separate algorithms.

The pinned cBench [`automotive_bitcount`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/automotive_bitcount/src) copy uses the same seven bit-count algorithms already covered by [`automotive_bitcount`](benchmarks/a/automotive_bitcount/README.md). Its deterministic seed, input progression, and outer repetition differ, but they define workload rather than algorithm changes.

The pinned cBench [`telecom_CRC32`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/telecom_CRC32/src/crc_32.c) copy uses the same reflected IEEE CRC-32 table recurrence as [`crc32`](benchmarks/c/crc32/README.md) and MiBench `telecomm-CRC32`; its launcher profile does not add an algorithm.

The pinned lac-dcc McGill `chomp` launcher maps to [`mcgill_chomp`](benchmarks/c/mcgill_chomp/README.md), which solves the fixed 7-column game tree selected by its noninteractive launcher mode.

The pinned MiBench `network-dijkstra` source uses FIFO queue-based label-correcting shortest-path relaxation, not the globally-minimum label selection in [`dijkstra`](benchmarks/d/dijkstra/README.md) or the full edge passes in [`bellman_ford`](benchmarks/b/bellman_ford/README.md). It maps to [`mibench_network_dijkstra`](benchmarks/m/mibench_network_dijkstra/README.md) with bounded row-major graphs and a reachable-distance checksum.

The MiBench `network-patricia` and cBench `network_patricia` sources use the same path-compressed Patricia/radix-trie insertion and exact-search algorithm covered by [`radix_tree`](benchmarks/r/radix_tree/README.md). Their fixed-width IPv4 key encoding and launcher traces do not define separate algorithms or packages.

The MiBench `security-blowfish` package maps to [`mibench_security_blowfish`](benchmarks/m/mibench_security_blowfish/README.md), a bounded one-block ECB core port that preserves Eric Young's terms. Its file-processing launcher and CBC/CFB/OFB modes are not included there; the distinct CBC chaining mode is covered by [`cbench_blowfish_cbc`](benchmarks/c/cbench_blowfish_cbc/README.md), while CFB/OFB and launcher file handling remain outside the local packages.

The pinned Olden `power` launcher maps to [`olden_power`](benchmarks/o/olden_power/README.md), preserving the feeder-tree voltage and demand recurrence with a bounded optimizer update and fixed-point projection of the final state.

The pinned Olden `tsp` launcher maps to [`olden_tsp`](benchmarks/o/olden_tsp/README.md), with closest-point insertion at small leaves and the source's four-choice Karp cycle merge at internal nodes.

The pinned Olden `voronoi` launcher maps to [`olden_voronoi`](benchmarks/o/olden_voronoi/README.md), retaining the quad-edge divide-and-conquer Delaunay triangulation and its Voronoi dual checksum; it is distinct from the local Fortune sweep implementation.

The Olden `treeadd` launcher uses the same node-plus-left-and-right-subtree recursive sum as [`binary_tree_node_sum`](benchmarks/b/binary_tree_node_sum/README.md); its value-one full-tree input and repeated traversal are workload details, so it is cross-referenced there rather than retained as a duplicate package.

The pinned Olden `bh` kernel maps to [`olden_bh`](benchmarks/o/olden_bh/README.md), a bounded 3D Barnes–Hut octree with the source's monopole cell approximation and traversal order. The Olden `em3d` and `health` launchers map to [`olden_em3d`](benchmarks/o/olden_em3d/README.md), which updates a bipartite electric/magnetic graph in source order, and [`olden_health`](benchmarks/o/olden_health/README.md), which simulates patients across a four-way village tree and FIFO hospital queues.

The pinned lac-dcc `Misc/salsa20` launcher aliases [`salsa`](benchmarks/s/salsa/README.md): it uses the same 16-word Salsa core and ten double rounds; the counter-based PRNG wrapper does not define a new core algorithm.

The pinned `Prolangs-C/allroots` launcher maps to [`prolangs_c_allroots`](benchmarks/a/prolangs_c_allroots/README.md), which preserves the cubic real-root path using simultaneous Horner/Newton evaluation, synthetic deflation, the quadratic formula, and source-order refinements.

The MATLAB-Octave repository has two `multiple.m` files: `algorithms/Divisibility_of_integers/multiple.m` maps to [`is_divisible`](benchmarks/i/is_divisible/README.md) on its nonnegative-dividend, positive-divisor domain, while `project-euler/Problem1/multiple.m` is a one-term filter mapped to [`multiple_of_3_or_5_term`](benchmarks/m/multiple_of_3_or_5_term/README.md). The latter returns the input term when divisible by 3 or 5 and zero otherwise; it is not the Problem 1 sum.

The Python `minimum_spanning_tree_prims2.py` candidate is a Dijkstra implementation despite its filename. It aliases [`dijkstra`](benchmarks/d/dijkstra/README.md) on connected simple undirected graphs encoded as reciprocal directed edges, with insertion order fixing the source; the shared contract records distances and omits the source parent map.

The pinned Rust `minimum_spanning_tree.rs` candidate implements Kruskal and aliases [`kruskal`](benchmarks/k/kruskal/README.md) on graphs with 1–64 vertices, zero-based in-range endpoints, and nonnegative weights up to 1,000,000. Disconnected graphs return `None`; the shared scalar output compares total cost, so the source's unstable equal-weight edge order is outside the contract.

The pinned Zig coordinator maps to [`two_phase_commit`](benchmarks/t/two_phase_commit/README.md), preserving unrecorded no-response votes, decision only after all commit/abort votes, and strict timeout observation without automatic abort.

The pinned Python `GraphAdjacencyList` source maps to [`graph_adjacency_list`](benchmarks/g/graph_adjacency_list/README.md), a bounded operation trace that preserves insertion order, directed and undirected edge behavior, and the source’s doubled undirected self-loops across all nine target languages. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/graph_adjacency_list.py).
The pinned Python `GraphAdjacencyMatrix` maps to [`graph_adjacency_matrix`](benchmarks/g/graph_adjacency_matrix/README.md), a nine-language trace for at most 8 active vertices, 64 initial edges, and 24 operations. It preserves labels 0–31, directedness, vertex and matrix order, matrix symmetry, and row/column compaction when a vertex is removed. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/graph_adjacency_matrix.py).
The pinned Python `graph_peripherality.py` maps to [`graph_peripherality`](benchmarks/g/graph_peripherality/README.md), which ports Floyd–Warshall and preserves maximum eccentricity, maximum farness, lowest-index ties, and the source's infinity handling for nodes without outgoing reachability. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/graph_peripherality.py).
The pinned Python `greedy_min_vertex_cover.py` maps to [`greedy_min_vertex_cover`](benchmarks/g/greedy_min_vertex_cover/README.md), preserving maximum-current-degree choices and smallest-integer-ID heap ties for simple undirected graphs across all nine ports. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/greedy_min_vertex_cover.py).
The shared `greedy` filename is split by source semantics: Go `greedy.go` maps to [`greedy_graph_coloring`](benchmarks/g/greedy_graph_coloring/README.md), with deterministic smallest-ID ties for its descending-degree first-fit coloring; Python `greedy.py` maps to [`greedy_item_selection_by_value`](benchmarks/g/greedy_item_selection_by_value/README.md), preserving stable descending-value whole-item selection. [Go source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/coloring/greedy.go); [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/greedy.py).
The pinned Java `Gravitation.java` exposes two separate calculations: [`gravitational_force`](benchmarks/g/gravitational_force/README.md) preserves its two-dimensional force-vector formula and coincident-position zero case, while [`circular_orbit_velocity`](benchmarks/c/circular_orbit_velocity/README.md) preserves its positive-mass/radius square-root formula. Both are ported across all nine target languages. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/physics/Gravitation.java).
The pinned Python `graph_centrality.py` maps to [`graph_centrality`](benchmarks/g/graph_centrality/README.md), which ports Floyd–Warshall and its minimum-eccentricity and harmonic-closeness selections to all nine languages under a bounded integer-weight contract. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/graph_centrality.py).
The JavaScript `Graph2.js` candidate aliases [`graph_adjacency_list`](benchmarks/g/graph_adjacency_list/README.md) on its valid undirected graph-construction subset; `printGraph` formatting is normalized to the shared ordered adjacency rows. [Pinned source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Graph/Graph2.js).
The JavaScript `Graph3.js` candidate maps `DFSIterative` to [`depth_first_search_iterative_order`](benchmarks/d/depth_first_search_iterative_order/README.md). Its bounded undirected graph contract preserves adjacency insertion order, marks on push, and emits LIFO pop order; the same file’s recursive DFS and BFS map to the existing [`graph_js_undirected_unweighted`](benchmarks/g/graph_js_undirected_unweighted/README.md) traversal contract on its valid subset. [Pinned source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Graph/Graph3.js).
The pinned Java `Graphs.java` demo's `AdjacencyListGraph` class aliases [`graph_adjacency_list`](benchmarks/g/graph_adjacency_list/README.md) for directed graphs with predeclared distinct vertices, unique non-self-loop edges, and removals of existing edges; its demo entry point and string formatting are outside the shared trace. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/graphs/Graphs.java).

The pinned C#, Go, and Java `deque` implementations and Python `deque_doubly` expose the same core insertion, removal, end-observation, and empty-check behavior as the existing [`linked_deque`](benchmarks/l/linked_deque/README.md) trace. Their storage layouts differ, while extra size, clear, and membership methods are outside the shared operation subset, so those filename candidates are recorded as aliases. The pinned Go `Doubly` structure also maps its push/pop/front/back behavior to this trace; its count, positional delete, reversal, and move-to-back operations remain outside the deque contract.


The pinned Python `detecting_english_programmatically` source filters message characters, checks whitespace-delimited tokens against its uppercase dictionary, and applies both word-match and retained-letter thresholds. The bounded contract supplies the dictionary explicitly and treats empty and all-filtered messages as invalid because the source divides by zero when no tokens remain. See the [benchmark guide](benchmarks/d/detecting_english_programmatically/README.md).

The pinned Python `vector3_for_2d_rendering.py` contains two operations tracked separately: perspective projection rejects the singular `z == -distance` case, while axis rotation preserves the source's doctested angle conversion `(angle % 360) / 450 * 180 / pi`. See the [projection guide](benchmarks/v/vector3_perspective_projection/README.md) and [axis-rotation guide](benchmarks/v/vector3_axis_rotation/README.md).

The pinned Python Weddle's rule source uses `6 * acc + 1` samples and modulo-six interior weights before scaling the ordered sum by `0.3 * h`. The portable contract supplies fixed-point samples directly, avoiding its NumPy and SymPy input path while retaining the quadrature kernel; see the [benchmark guide](benchmarks/w/weddles_rule/README.md).

The pinned Python PSNR path computes on OpenCV `uint8` image arrays, while Rust squares f64 differences. The shared contract limits each pixel-pair difference to 15 so squared errors cannot overflow in the Python path; identical images are excluded because the sources return different special values. See the [PSNR guide](benchmarks/p/peak_signal_to_noise_ratio/README.md).

The pinned Java `WineProblem` source provides uncached recursive, memoized, and bottom-up tabulated solutions for maximizing revenue while selling one endpoint wine each year. The three strategies have separate contracts: [recursive](benchmarks/w/wine_problem_recursive/README.md), [memoized](benchmarks/w/wine_problem_memoized/README.md), and [tabulated](benchmarks/w/wine_problem_tabulated/README.md).

The pinned Python `rotate_matrix.py` provides 90-degree counterclockwise, 180-degree, 270-degree counterclockwise, and in-place transpose operations; each is tracked separately ([90](benchmarks/r/rotate_matrix_90/README.md), [180](benchmarks/r/rotate_matrix_180/README.md), [270](benchmarks/r/rotate_matrix_270/README.md), [transpose](benchmarks/r/rotate_matrix_transpose/README.md)). Java `MatrixTranspose` allocates and returns a transpose in its own [contract](benchmarks/m/matrix_transpose/README.md). Java `RotateMatrixBy90Degrees` matches the 90-degree counterclockwise contract for square signed-i32 matrices.

The pinned Python `join(separator, separated)` concatenates strings in order and places the separator only between items. Its bounded ASCII-byte contract is documented in the [join guide](benchmarks/j/join/README.md).

The pinned Java `word_ladder` uses breadth-first search for a shortest transformation length, while Python’s `word_ladder.py` performs depth-first backtracking and is cataloged separately as [`word_ladder_dfs`](benchmarks/w/word_ladder_dfs/README.md). Java and Python inclusive range-sum queries alias selector 1 of the existing [prefix_sum](benchmarks/p/prefix_sum/README.md) benchmark.

The pinned Python `simple_keyword_cypher.py` exposes separate encipher and decipher operations over a keyword-derived substitution alphabet; each has its own bounded contract. See the [encipher guide](benchmarks/s/simple_keyword_cypher_encipher/README.md) and [decipher guide](benchmarks/s/simple_keyword_cypher_decipher/README.md).

The Go `heaps` source uses generated digit labels and its own Heap order; the Dart/Python `heaps_algorithm` sources share a positional-value order, with the iterative Python candidate as an alias. Both packages remain separate from Rust `heap_permutation`, which preserves another swap order. See the [Go Heap guide](benchmarks/h/heaps/README.md), [positional Heap guide](benchmarks/h/heaps_algorithm/README.md), and [Rust Heap guide](benchmarks/h/heap_permutation/README.md).

The Rust `heap_permute` function is cataloged separately from the heap data structure as [`heap_permutation`](benchmarks/h/heap_permutation/README.md), preserving its swap-before-recursion output order and repeated rows for equal-valued positions.

The two pinned C++ `poisson_dist` copies are identical; a fixed-milli operation selector benchmarks their deterministic rate, expectation, point-probability, and inclusive-range helpers under a zero-absolute-tolerance contract. See the [Poisson guide](benchmarks/p/poisson_dist/README.md).

The pinned C++ `modular_inverse_fermat_little_theorem` and `modular_inverse_simple` sources use separate primality/exponentiation and brute-force search strategies, so each has its own binary-scalar contract. Their bounded domains exclude source inputs that would return a non-inverse or fail to terminate. See the [Fermat guide](benchmarks/m/modular_inverse_fermat_little_theorem/README.md) and [simple inverse guide](benchmarks/m/modular_inverse_simple/README.md). The C# `fermat_prime_checker` source uses a fixed-seed Fermat probable-prime test; its benchmark preserves the seeded `Random(0)` bases and the source loop’s `timesToCheck - 1` iterations. See the [Fermat prime checker guide](benchmarks/f/fermat_prime_checker/README.md).
The pinned C++ matrix-power implementation for `linear_recurrence_matrix` is benchmarked with bounded recurrence dimensions, residues, and index values. See the [guide](benchmarks/l/linear_recurrence_matrix/README.md). The Python `double_sort` candidate performs forward and backward adjacent-swap passes and maps to the existing [cocktail sort contract](benchmarks/c/cocktail_sort/README.md), although its pass bound differs from the C implementation. The same-named Go and Solidity `exponentiation` files implement different operations, so the catalog splits Go modular exponentiation (mapped to the existing [modular exponentiation guide](benchmarks/m/modular_exponentiation/README.md)) from Solidity unmodded integer power (covered by the [exponentiation guide](benchmarks/e/exponentiation/README.md)). Likewise, the Rust `reverse` string routine maps to the [`reverse_string`](benchmarks/r/reverse_string/README.md) contract, while JavaScript `Reverse`, Python `reverse_array`, and Solidity `ReverseArray` share the bounded [`reverse_array`](benchmarks/r/reverse_array/README.md) operation.

The pinned C# and Java `fibonacci_heap` sources share the bounded insert/extract-min contract, while Dart, JavaScript, and Rust `fisher_yates_shuffle` use a common seeded shuffle stream; the contract corrects Dart/Rust off-by-one defects and Ruby’s final `rand(0)` call rather than preserving those source failures. See the [heap guide](benchmarks/f/fibonacci_heap/README.md) and [shuffle guide](benchmarks/f/fisher_yates_shuffle/README.md). The Rust `gradient_descent` candidate is represented by its included square-function test in the [gradient descent guide](benchmarks/g/gradient_descent/README.md); C++ and Rust `graph_coloring` candidates share the recursive coloring count in the [graph coloring guide](benchmarks/g/graph_coloring/README.md).
The pinned C and C++ ODE demos use the harmonic oscillator with forward Euler, explicit midpoint Euler, or semi-implicit Euler updates. Each benchmark fixes a bounded step count and dyadic step size while omitting CSV and timing drivers; see the [forward Euler](benchmarks/o/ode_forward_euler/README.md), [midpoint Euler](benchmarks/o/ode_midpoint_euler/README.md), and [semi-implicit Euler](benchmarks/o/ode_semi_implicit_euler/README.md) guides.
The pinned C++ `newton_raphson_method` sources define a fixed cubic and use a saved-residual stopping rule; the generic R routine with the same normalized filename is tracked separately under `newton_raphson`. See the [fixed-cubic guide](benchmarks/n/newton_raphson_method/README.md).
The pinned C++ `power_for_huge_numbers` implementation multiplies a decimal digit array repeatedly; its bounded base and exponent keep the result within the fixed output workspace. See the [guide](benchmarks/p/power_for_huge_numbers/README.md).

The pinned Python `power_factor_correction.py` provides shunt-capacitor and shunt-inductor correction formulas. The contract preserves the source reactive-power calculation order and excludes zero power factors and source error cases. See the [power-factor-correction guide](benchmarks/p/power_factor_correction/README.md).
The pinned JavaScript MeterToFeetConversion module exports both feet-to-meter and meter-to-feet calculations. The benchmark preserves both expressions under an operation selector. See the [meter-to-feet guide](benchmarks/m/meter_to_feet_conversion/README.md).
The pinned Java and Rust `twos_complement` sources alias [`binary_twos_complement`](benchmarks/b/binary_twos_complement/README.md) for negative i32 values excluding `i32::MIN`; Java receives the corresponding padded binary string, while Rust accepts the signed integer directly. Zero and positive values are excluded.
The Fortran and Ruby `recursive_linear_search` sources use different search directions and return one-based versus zero-based indices. Distinct array values make their matching position unambiguous; see the [recursive search guide](benchmarks/r/recursive_linear_search/README.md).

The C and Python `matrix_chain_order` sources use the same recurrence as [`matrix_chain_multiplication`](benchmarks/m/matrix_chain_multiplication/README.md); the C int32 source maps only on its safe overlap of at most 64 matrices with dimensions 1..300.

The C `modified_binary_search` helper uses the same middle-column row narrowing as [`binary_search2d_array`](benchmarks/b/binary_search2d_array/README.md). Its source driver is safe on square matrices with side at least 3, and the printed coordinate maps to the shared row-major result.

The pinned C++ `hash_search` examples build a fixed five-bucket separate-chaining table and perform one membership query. Because head-versus-tail insertion does not change membership, this source aliases the general [`chaining`](benchmarks/c/chaining/README.md) contract.

The C++ `subarray_sum` candidates use prefix-sum frequencies with a direct prefix-equals-target check instead of seeding zero; that behavior is equivalent to [`subarray_sum_equals_k`](benchmarks/s/subarray_sum_equals_k/README.md) and aliases the existing contract.

The pinned Java `MatrixChainRecursiveTopDownMemoisation` source uses the same minimum scalar-multiplication recurrence as [`matrix_chain_multiplication`](benchmarks/m/matrix_chain_multiplication/README.md), with memoized recursion rather than tabulation. Its `int` arithmetic overflows for some large dimensions, so the alias applies on the shared bounded domain where costs fit signed 32-bit. [Pinned Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/MatrixChainRecursiveTopDownMemoisation.java).
The pinned Rust `matrix_chain_multiply` uses the same bottom-up minimum-cost recurrence as [`matrix_chain_multiplication`](benchmarks/m/matrix_chain_multiplication/README.md). Equivalence covers chains with at least two dimensions; Rust reports errors for shorter inputs while the benchmark returns zero. [Pinned Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/matrix_chain_multiply.rs).

The pinned Python `median_two_array` function sorts two input arrays together and returns their median. The bounded [median-two-array benchmark](benchmarks/m/median_two_array/README.md) uses sorted integer inputs and a binary64 result. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/median_two_array.py).

The two pinned C++ `median_search` files map to the bounded deterministic-selection package. Distinct values and a 25-element cap preserve the source’s correct pivot branch; see the [median search guide](benchmarks/m/median_search/README.md).
The pinned Python `median_of_medians` selection source is ported with corrected groups of at most five and an explicit zero-based rank contract. Its upstream group slicing and one-based rank behavior are documented in the [benchmark guide](benchmarks/m/median_of_medians/README.md). [Pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/searches/median_of_medians.py).
The pinned Rust `maximal_square` DP updates each cell with the largest all-one square side ending there and returns its area. The benchmark covers bounded row-major binary matrices across all nine languages; see the [guide](benchmarks/m/maximal_square/README.md) and [pinned source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/maximal_square.rs).

The pinned C# `LinearSearcher<T>.FindIndex` scans from the first element, returning the first index accepted by its predicate or `-1`. Under the benchmark equality predicate, it aliases the existing [`linear_search`](benchmarks/l/linear_search/README.md) contract. [Pinned C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Search/LinearSearcher.cs).

The pinned Ruby `get_products_of_all_other_elements.rb` defines three methods named `products`; the final method is the active prefix/suffix product routine, returning an empty vector for inputs shorter than two. The bounded nine-language contract preserves its traversal and update order. See the [products guide](benchmarks/g/get_products_of_all_other_elements/README.md) and [pinned Ruby source](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/get_products_of_all_other_elements.rb).

The corrected C++ and Rust Kadane candidates map to the bounded, nonempty [`maximum_subarray_int32`](benchmarks/m/maximum_subarray_int32/README.md) contract; the broken C++ variant is excluded. Haskell’s empty-allowed result maps separately to [`maximum_subarray_allow_empty`](benchmarks/m/maximum_subarray_allow_empty/README.md), distinct from the existing full-range nonempty `maximum_subarray`.

The Python and C# present-value sources round exact half-cent values to even, while the Rust source rounds them away from zero. They therefore use separate [`present_value`](benchmarks/p/present_value/README.md) and [`present_value_rust`](benchmarks/p/present_value_rust/README.md) contracts on a shared bounded domain.

The pinned MATLAB `code.m` particle-swarm example maps to [`particle_swarm_optimization`](benchmarks/p/particle_swarm_optimization/README.md), which preserves its five-dimensional sphere recurrence with a shared deterministic random stream.

The pinned C# `CollaborativeFiltering.cs` maps prediction with injected similarities to [`collaborative_filtering`](benchmarks/c/collaborative_filtering/README.md), and its separate Pearson method to [`collaborative_filtering_pearson_similarity`](benchmarks/c/collaborative_filtering_pearson_similarity/README.md).

The pinned Python `convolve_1d.py` maps to [`convolve_1d`](benchmarks/c/convolve_1d/README.md), preserving one output per signal sample, the source kernel order, and centered zero padding.

The pinned Go `depthfirstsearch.go` maps to [`depth_first_search_target_route`](benchmarks/d/depth_first_search_target_route/README.md). Its contract preserves undirected adjacency-matrix construction and returns stack-pop visitation order through the target, with an empty route when unreachable; it remains separate from full-traversal DFS contracts.

The pinned Java `ConnectedComponent.java` maps to [`directed_dfs_forest_count`](benchmarks/d/directed_dfs_forest_count/README.md). Its count follows outgoing edges in first-seen node order, with the source’s self-loop node-identity behavior preserved; it is distinct from undirected connected-components and SCC algorithms.

The pinned Java `ConvolutionFFT.java` and `FFT.java` helper map to [`convolution_fft`](benchmarks/c/convolution_fft/README.md), which preserves full linear complex output and the source radix-2 FFT pipeline. The pinned Python `radix2_fft.py` is a restricted alias on nonempty, nonzero real q/16 coefficient vectors of length 1–64 whose final coefficients are nonzero; that subset avoids its trailing-zero trimming and all-zero input failure while preserving the same full n+m−1 coefficient product after its eight-decimal rounding.

The pinned Java `SecondMinMax.java` maps its second-smallest and second-largest operations to [`second_min_max`](benchmarks/s/second_min_max/README.md), preserving distinct-value comparisons and sentinel collision behavior.

The pinned Python `cramers_rule_2x2.py` maps to [`cramers_rule_2x2`](benchmarks/c/cramers_rule_2x2/README.md), which preserves determinant-based solving on the bounded two-equation domain.

The pinned Go `hammingdistance.go` maps to [`hamming_distance_strings`](benchmarks/h/hamming_distance_strings/README.md), preserving byte-wise Hamming distance and the source error behavior for unequal byte lengths.

The pinned Java `LengthOfLastWord.java` maps to [`length_of_last_word`](benchmarks/l/length_of_last_word/README.md), preserving literal-space separators on the bounded byte domain.

The MATLAB `comment.m` and `continuation.m` files are reviewed and excluded: they demonstrate commenting and line-continuation syntax with fixed arithmetic examples, not reusable algorithms ([comment](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/matlab_for_beginners/part_1%28learn_basic_programing%29/comment.m), [continuation](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/matlab_for_beginners/part_1%28learn_basic_programing%29/continuation.m)).
The pinned PHP `CompareBinaryTree` implementation is an alias of [`same_trees_check`](benchmarks/s/same_trees_check/README.md). It uses recursive left/right comparisons and strict value inequality; the benchmark value domain is signed integers.

The pinned Lua `factorize.lua` returns a prime-to-exponent map, including singleton maps `{[0] = 1}` and `{[1] = 1}` for the tested edge inputs. It maps to [`factorize`](benchmarks/f/factorize/README.md), whose portable contract serializes sorted factor/exponent pairs; all nine ports passed 9,230 oracle/capacity cases and 12 workload cases.

The pinned Java `CreateAndDetectLoop` utility uses Floyd pointers in `detectLoop`; its `createLoop` method only constructs test input. The detection operation aliases [`linked_list_has_cycle`](benchmarks/l/linked_list_has_cycle/README.md).

The pinned JavaScript `CreatePermutations.js` recursively selects each character position and retains repeated rows. On ASCII strings, its order and multiplicity match [`all_permutations`](benchmarks/a/all_permutations/README.md) when characters are represented by their integer codes.

The pinned Dart `findCyclicNode` returns the first node in a linked-list cycle using Floyd’s algorithm; its randomized cycle creation is test setup. It aliases [`linked_list_cycle_entry`](benchmarks/l/linked_list_cycle_entry/README.md).

The pinned Python `cryptomath_module.py` exposes modular inverse via iterative GCD validation and extended Euclid; it aliases [`modular_inverse`](benchmarks/m/modular_inverse/README.md) over that contract’s shared domain. The C# `CryptoException` and `DataLengthException` files only declare exception types. The R `data_processing.r` file is an external-workbook tutorial script with a hard-coded working directory; those three are excluded from algorithm benchmarks.


The pinned Dart `car_pool.dart` source maps to the `car_pool` difference-timeline benchmark. Its loop misses occupancy from stop zero to one; the nine-port contract keeps the array method and checks that segment. See the [guide](benchmarks/c/car_pool/README.md) and [pinned Dart source](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/array/car_pool.dart).

The pinned Java `CeilInBinarySearchTree.java` maps to `ceil_in_binary_search_tree`. The benchmark follows executable behavior where the source prose and example conflict with the branches. All nine ports passed 2,673 oracle arrays and 14 workload records. See the [guide](benchmarks/c/ceil_in_binary_search_tree/README.md) and [pinned Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/CeilInBinarySearchTree.java).

The pinned Rust `chacha.rs` source implements the ChaCha20 16-word block function. The benchmark takes sixteen numeric u32 state words and returns one little-endian 64-byte block; key setup and stream handling are outside the source function. All nine ports passed 269 oracle inputs and recorded 10 workload cases. See the [guide](benchmarks/c/chacha/README.md) and [pinned Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/chacha.rs).

The Haskell `Statistics.Center` module groups arithmetic mean, geometric mean, harmonic mean, and median routines. They map to the existing `arithmetic_mean`, `geometric_mean`, `harmonic_mean`, and `median` contracts; those benchmark guides now cite the pinned Haskell source. The mean contracts use bounded domains, with positive values for the geometric and harmonic means.

The two pinned C++ `chaining.cpp` files define the same modulus-based linked-bucket table. The nine-port `chaining` contract preserves append-at-tail insertion and chain lookup, returning lookup results in a bit mask. All ports passed 4,631 oracle arrays and 15 workload cases. See the [guide](benchmarks/c/chaining/README.md), [C-Plus-Plus source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/hashing/chaining.cpp), and [C-Plus-Plus-1 source](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/hashing/chaining.cpp).

The pinned Python `butterfly_pattern.py` source maps to a bounded ASCII output contract that preserves its top, middle, and mirrored bottom rows. See the [guide](benchmarks/b/butterfly_pattern/README.md), [scalar byte-output verifier](benchmarks/verify_i64_scalar_bytes_output.py), and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphics/butterfly_pattern.py).

The pinned Python `burkes.py` source maps to the nine-language `burkes_dithering` benchmark. Its shared contract uses exact rational grayscale weights and truncation toward zero for error diffusion, avoiding floating-point boundary differences between compilers. The Java `BufferedReader` candidate is reviewed as a byte-stream I/O utility rather than a standalone benchmark algorithm. See the [Burkes guide](benchmarks/b/burkes_dithering/README.md), [verifier](benchmarks/verify_i64_array_scalar.py), and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/dithering/burkes.py).

The pinned C# `JaccardDistance` source maps to the `jaccard_distance` benchmark, which preserves character-set deduplication and both-empty distance semantics on its portable ASCII contract. The pinned Solidity `AddArray` source maps candidate `add_array` to the `array_sum` benchmark, whose bounded signed-64-bit contract preserves its cumulative-sum loop. See the [Jaccard-distance guide](benchmarks/j/jaccard_distance/README.md) and [array-sum guide](benchmarks/a/array_sum/README.md). The pinned Java, JavaScript, and Python `AlternativeStringArrange` sources map to the `alternative_string_arrange` benchmark, and the AArch64 Assembly `append` and `concatenation` routines perform the same string-copy operation and map to portable `string_append` implementations; `concatenation` uses two copy loops and its fixed newline example is outside the shared printable-ASCII contract. Their contracts are linked in the benchmark guides. The JavaScript `alphaNumericalSort` comparator maps to `alpha_numerical_sort` on lowercase ASCII with canonical decimal runs, avoiding locale-dependent cases.

The pinned Lua `logical_right_shift` candidate maps to the 53-bit logical shift benchmark. C++, JavaScript, and MATLAB numeric-palindrome candidates map to `palindrome_number` on its bounded nonnegative integer domain. The mixed `is_palindrome` filename candidate maps its F# filtered string, JavaScript and MATLAB exact strings, Julia case-insensitive string, Python linked list, and R/TypeScript numeric sources to their matching palindrome benchmarks. Fortran `euclid_gcd`, Ruby `euclidean_gcd`, C++ `gcd_iterative_euclidean`, Java `gcdrecursion`, JavaScript `get_euclid_gcd`, Zig `euclidian_greatest_common_divisor`, and C# `euclidean_greatest_common_divisor_finder` map to the shared `gcd` benchmark with source-domain differences recorded in the JSON catalog and benchmark guide. Dart `binary_search_recursion` and C# `RecursiveBinarySearcher` alias `recursive_binary_search`; C `other_binary_search` and C# `BinarySearcher` alias `binary_search`. Python `simple_binary_search` now has a separate boolean-returning benchmark. JavaScript, Julia, Python, and Ruby `average_median` sources alias the exact scaled-median benchmark; the Ruby source defects are documented in its guide.

The pinned Go `NextPermutation` source maps to `next_permutation`; its benchmark returns the immediate lexicographic successor, wrapping the descending final ordering back to the minimum. The shared contract bounds elements to signed 32-bit values and serializes them as little-endian bytes. See the [next-permutation guide](benchmarks/n/next_permutation/README.md).

The pinned Java `RotatedBinarySearch` source maps to `rotated_binary_search`, with duplicate-aware midpoint search over validated rotated-sorted signed 32-bit arrays. See the [rotated-binary-search guide](benchmarks/r/rotated_binary_search/README.md).

The Nim `bresenhams_line` source and the Python `bresenham_line_basic` source use inclusive error comparisons, while Java `bresenham_line` and Python `bresenham_line_generalized` use strict comparisons; their tie pixels can differ, so they map to separate portable contracts. The basic Python function is matched on its documented shallow, rising-line domain, and the shared inclusive contract supports all octants. See the [inclusive tie-rule guide](benchmarks/b/bresenhams_line/README.md) and [strict tie-rule guide](benchmarks/b/bresenham_line/README.md). The pinned C# `BranchAndBoundKnapsackSolver` explores a FIFO include/exclude tree with a fractional bound. Its ascending value-density sort can prune the optimum, so the portable benchmark corrects the ordering to stable descending density; `BranchAndBoundNode` is cataloged as a helper record. See the [branch-and-bound knapsack guide](benchmarks/b/branch_and_bound_knapsack_solver/README.md) and [pinned C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Knapsack/BranchAndBoundKnapsackSolver.cs). The pinned MATLAB-Octave `brightness.m` classifies RGB inputs with a fixed 11-row nearest-neighbor model; the nine-port benchmark uses squared integer distances and retains the source’s first-row tie behavior. All ports passed 3,150 oracle cases each and recorded 35 workloads. See the [brightness guide](benchmarks/b/brightness/README.md), [array-scalar verifier](benchmarks/verify_i64_array_scalar.py), and [pinned MATLAB source](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/machine_learning/Nearest-Neighbor/brightness.m). The pinned Java `BronKerbosch.java` uses pivoted recursion to enumerate maximal cliques in an undirected graph. The nine-port benchmark preserves the complete clique set in an order-independent bitset for graphs through five vertices. All ports passed 1,117 oracle cases each and recorded 19 workloads. See the [Bron–Kerbosch guide](benchmarks/b/bron_kerbosch/README.md), [array-scalar verifier](benchmarks/verify_i64_array_scalar.py), and [pinned Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/BronKerbosch.java).

The pinned C `ascending_priority_queue` source appends to a linked list and scans it to remove the minimum; the shared bounded trace preserves that behavior across all nine local languages. See the [ascending priority queue guide](benchmarks/a/ascending_priority_queue/README.md).

The two pinned C++ `counting_sort_string` candidates implement byte-frequency sorting. The shared contract bounds tokens to printable non-space ASCII and supplies the output storage missing from the source demo. See the [counting-sort-string guide](benchmarks/c/counting_sort_string/README.md).

The Go and C++ directed-cycle candidates are mapped to separate three-color DFS and Kahn zero-indegree benchmarks, each with the same graph workload and nine portable ports. The Go `HasCycle` method is used only with directed input because the source graph defaults to undirected edges; its separate `FindAllCycles` helper is not mapped because it does not enumerate every distinct cycle. See the [DFS guide](benchmarks/c/cycle_check_directed_graph/README.md) and [Kahn guide](benchmarks/c/cycle_check_directed_graph_kahn/README.md).

The pinned Python `triplet_sum` source contains a factorial permutation search and a separate sort-and-two-pointers implementation; they can select different valid results and are tracked as `triplet_sum` and `triplet_sum_two_pointer`. Both have nine portable language ports and passed more than 43,000 oracle inputs per implementation. See the [permutation-search guide](benchmarks/t/triplet_sum/README.md), [two-pointer guide](benchmarks/t/triplet_sum_two_pointer/README.md), and [verifier](benchmarks/verify_triplet_sum.py).

The pinned Java `TurkishToLatinConversion` source replaces twelve Turkish BMP letters with their basic Latin counterparts. Nine portable ports apply the exact case-sensitive map over validated UTF-8 and preserve all other Unicode scalars. See the [guide](benchmarks/t/turkish_to_latin_conversion/README.md) and [verifier](benchmarks/verify_turkish_to_latin_conversion.py).

AArch64 Assembly paths are included only as discovery references. They are architecture-specific and are not portable benchmark implementations. Any benchmark derived from those algorithms still needs a portable implementation for each target.

The pinned Java `DarkSort.java` counts nonnegative keys in a max+1 histogram and reconstructs them in ascending order. Over the shared key domain `0..128`, it aliases the existing [counting_sort](benchmarks/c/counting_sort/README.md) contract.

The pinned Julia `DifferenceArray` module builds adjacent differences, reconstructs by prefix summation, and applies inclusive range additions at the two boundary positions. After translating its one-based indices, it aliases the existing [difference_array](benchmarks/d/difference_array/README.md) contract.

The pinned [Python CPU scheduler](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/scheduling/cpuschedulingalgorithms.py) contains FCFS, non-preemptive and preemptive SJF, non-preemptive and preemptive priority, and round robin modes. The portable [CPU scheduling algorithms suite](benchmarks/c/cpu_scheduling_algorithms/README.md) keeps all six modes under one workload and nine language ports while omitting the GUI and animation.

The pinned Python `one_dimensional.py` source runs a fixed 31-cell elementary cellular automaton for 16 generations from a live center seed. Its source-specific decimal encoding of the eight-bit rule and black/white RGB output are preserved in the [one-dimensional automaton guide](benchmarks/o/one_dimensional/README.md). [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/cellular_automata/one_dimensional.py).

The pinned Python `number_container_system.py` keeps sorted index lists by number; changes replace an index value and find returns the smallest matching index or `-1`. The shared benchmark bounds change/find traces to 32 triplets, indices 0–63 and values -100–100, and writes comma-separated ASCII results in at most 95 bytes. See the [number-container guide](benchmarks/o/number_container_system/README.md). [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/number_container_system.py).

The pinned Java and JavaScript `MinPriorityQueue` sources implement fixed-capacity binary min-heaps with insert, peek, delete, empty, and full operations. The shared trace bounds capacity and operation count to 64 and emits query records as little-endian signed-i32 words. Java `heapSort` compares its increasing loop index against a queue size that shrinks during deletion, so it may leave initial items behind; JavaScript `heapReverse` drains the heap and stores keys in descending order. Both helpers are outside the shared contract. See the [min-priority-queue guide](benchmarks/m/min_priority_queue/README.md).

The pinned Python `RandomizedHeap` randomly swaps child links while merging, but its observable minimum order is deterministic. The shared contract bounds `insert`, `top`, `pop`, and `isEmpty` traces to 64 operations with signed-i32 keys, rejects top/pop on empty, and excludes the source's `clear` and `to_sorted_list` helpers. See the [randomized-heap guide](benchmarks/r/randomized_heap/README.md). [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/heap/randomized_heap.py).

The pinned Ruby `ones_and_zeros.rb` uses descending two-budget updates for its binary-string 0/1 knapsack. The benchmark bounds item counts and budgets and passes each string’s zero/one counts directly; see the [ones-and-zeros guide](benchmarks/o/ones_and_zeros/README.md). [Pinned source](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/dynamic_programming/ones_and_zeros.rb).

The pinned Java and Python optimal-BST sources minimize weighted search cost over ordered key frequencies; the Java version applies Knuth root bounds. Rust `optimal_bst` and Go `optimalbst` use the same recurrence on frequencies already in key order and alias the shared [optimal-BST guide](benchmarks/o/optimal_binary_search_tree/README.md). [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/OptimalBinarySearchTree.java), [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/optimal_binary_search_tree.py), [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/optimal_bst.rs), [Go source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/dynamic/optimalbst.go).

The pinned Python `nagel_schrekenberg.py` evolves car speeds on a circular road, applying acceleration, a wrapped gap limit, and simultaneous movement; random slowdowns are fixed off in the bounded contract. See the [Nagel–Schreckenberg guide](benchmarks/n/nagel_schrekenberg/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/cellular_automata/nagel_schrekenberg.py).

The pinned JavaScript `NodeNeighbors.js` scans undirected edges in insertion order and returns unique adjacent nodes in first-encounter order, including a queried-node self-loop once. See the [node-neighbors guide](benchmarks/n/node_neighbors/README.md) and [pinned source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Graphs/NodeNeighbors.js).

The pinned Rust `rhumb_dist` method computes great-circle-style distance along a rhumb line with one strict longitude wrap and a Mercator-latitude threshold branch. [`rhumb_distance`](benchmarks/r/rhumb_distance/README.md) preserves the source formula and returns meters. [Pinned source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a939ec5163648458a8c2b46fd4c/src/navigation/rhumbline.rs).

The same Rust navigation module exposes [`rhumb_bearing`](benchmarks/r/rhumb_bearing/README.md), which applies the strict one-wrap longitude delta and normalizes `atan2` output to `[0,360)`, and [`rhumb_destination`](benchmarks/r/rhumb_destination/README.md), which preserves source operation order and returns longitude without normalization. Both methods use separate workloads and source symbols. [Pinned source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/navigation/rhumbline.rs).

## Candidates already present in at least three local source languages

These normalized names have files in at least three of the existing source repositories for `c/`, `cpp/`, `nim/`, `rust/`, and `zig/`. The repository count includes matching files found in any scanned TheAlgorithms language repository. Review semantics before turning a candidate into a benchmark.

| Candidate name | Local source folders | Upstream repositories |
| --- | --- | ---: |
| `aliquot_sum` | `cpp/`, `nim/`, `rust/` | 12 |
| `armstrong_number` | `c/`, `cpp/`, `rust/` | 12 |
| `bead_sort` | `c/`, `cpp/`, `rust/` | 9 |
| `bellman_ford` | `c/`, `cpp/`, `rust/` | 11 |
| `binary_insertion_sort` | `c/`, `cpp/`, `rust/` | 9 |
| `binary_search` | `c/`, `cpp/`, `nim/`, `rust/` | 22 |
| `binary_search_tree` | `c/`, `cpp/`, `rust/`, `zig/` | 12 |
| `bogo_sort` | `c/`, `cpp/`, `nim/`, `rust/` | 12 |
| `bubble_sort` | `c/`, `cpp/`, `rust/`, `zig/` | 25 |
| `bucket_sort` | `c/`, `cpp/`, `rust/` | 10 |
| `catalan_numbers` | `cpp/`, `nim/`, `rust/` | 8 |
| `coin_change` | `cpp/`, `rust/`, `zig/` | 13 |
| `comb_sort` | `c/`, `cpp/`, `rust/` | 14 |
| `counting_sort` | `c/`, `cpp/`, `rust/` | 13 |
| `cycle_sort` | `c/`, `cpp/`, `rust/` | 10 |
| `decimal_to_binary` | `c/`, `cpp/`, `rust/` | 11 |
| `dijkstra` | `c/`, `cpp/`, `rust/` | 10 |
| `doubly_linked_list` | `c/`, `cpp/`, `zig/` | 14 |
| `exponential_search` | `c/`, `cpp/`, `rust/` | 11 |
| `factorial` | `c/`, `cpp/`, `rust/`, `zig/` | 22 |
| `fibonacci` | `c/`, `cpp/`, `rust/` | 20 |
| `fibonacci_search` | `c/`, `cpp/`, `rust/` | 11 |
| `floyd_warshall` | `c/`, `cpp/`, `rust/` | 10 |
| `gnome_sort` | `c/`, `cpp/`, `rust/` | 16 |
| `hamming_distance` | `c/`, `cpp/`, `rust/` | 13 |
| `heap_sort` | `c/`, `cpp/`, `rust/`, `zig/` | 22 |
| `insertion_sort` | `c/`, `cpp/`, `rust/`, `zig/` | 24 |
| `interpolation_search` | `c/`, `cpp/`, `rust/` | 15 |
| `jump_search` | `c/`, `cpp/`, `rust/` | 15 |
| `knapsack` | `cpp/`, `rust/`, `zig/` | 10 |
| `linear_search` | `c/`, `cpp/`, `nim/`, `rust/`, `zig/` | 23 |
| `linked_list` | `cpp/`, `rust/`, `zig/` | 9 |
| `longest_increasing_subsequence` | `cpp/`, `rust/`, `zig/` | 8 |
| `merge_sort` | `c/`, `cpp/`, `rust/`, `zig/` | 26 |
| `odd_even_sort` | `c/`, `cpp/`, `rust/` | 8 |
| `pancake_sort` | `c/`, `cpp/`, `rust/` | 12 |
| `postfix_evaluation` | `c/`, `cpp/`, `rust/` | 5 |
| `prim` | `c/`, `cpp/`, `rust/` | 7 |
| `queue` | `c/`, `cpp/`, `rust/`, `zig/` | 11 |
| `quick_sort` | `c/`, `cpp/`, `rust/`, `zig/` | 24 |
| `radix_sort` | `c/`, `cpp/`, `rust/`, `zig/` | 14 |
| `segment_tree` | `c/`, `cpp/`, `rust/` | 9 |
| `selection_sort` | `c/`, `rust/`, `zig/` | 19 |
| `shell_sort` | `c/`, `cpp/`, `rust/` | 15 |
| `skip_list` | `cpp/`, `rust/`, `zig/` | 7 |
| `stack` | `c/`, `cpp/`, `zig/` | 12 |
| `stooge_sort` | `c/`, `cpp/`, `rust/` | 8 |
| `ternary_search` | `c/`, `cpp/`, `rust/` | 13 |
| `topological_sort` | `c/`, `cpp/`, `rust/` | 10 |
| `trie` | `c/`, `rust/`, `zig/` | 11 |

## First all-folder candidate: linear search

`linear_search` is the only normalized filename candidate present in all five folders that have a direct TheAlgorithms source repository. The checked sources scan in order and stop at the first equal value; their return conventions differ. The local benchmark contract standardizes the result as a first-match index or `-1`. See [`benchmarks/l/linear_search/README.md`](benchmarks/l/linear_search/README.md) for the workload and ports. Upstream references are [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/searching/linear_search.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/search/linear_search.cpp), [Nim](https://github.com/TheAlgorithms/Nim/blob/63eec16614b46c91078653e8d3c049fe99ad36b3/searches/linear_search.nim), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/searching/linear_search.rs), and [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/search/linearSearch.zig).

The search pass itself is a clear match, but the APIs differ: C returns a found/not-found flag, C++ returns an index or `-1`, Nim and Rust return an optional index, and Zig returns an index or an error. The local contract normalizes these result conventions and uses the same element type, first-match duplicate behavior, and hit/miss workloads before comparing timings.

## Second reviewed candidate: binary search

`binary_search` appears in 22 source repositories and in four of the local direct-source folders (`c/`, `cpp/`, `nim/`, and `rust/`). The checked implementations share binary search on sorted input, but their APIs and scope differ: the C source has recursive and iterative versions, Nim returns an optional position, Rust handles ascending and descending arrays, and C++ takes its vector by value. The local benchmark narrows this to ascending signed 64-bit values and returns any matching index or `-1`; its workload has unique values. Portable implementations are also provided for C3, Elisa, Odin, V, and Zig. See [`benchmarks/b/binary_search/README.md`](benchmarks/b/binary_search/README.md).

## Third reviewed candidate: exponential search

`exponential_search` is present in 11 source repositories and in the direct C, C++, and Rust folders. The inspected upstream versions differ in their bounded-range logic and return types; the C version uses a 16-bit length and checks a bound that may be one past the sequence, while C++ implements a Struzik variant and returns a pointer. The local benchmark uses a portable ascending `i64` contract with exponential range growth and a bounded binary search, returning any matching index or `-1`. Ports cover the other six target languages. See [`benchmarks/e/exponential_search/README.md`](benchmarks/e/exponential_search/README.md).

## Fourth reviewed candidate: jump search

`jump_search` appears in 15 source repositories and in the direct C, C++, and Rust folders. The C and C++ examples assume nonempty arrays and use floating-point square root, while Rust returns an optional index. The local ports use an integer square-root calculation, explicitly handle empty input, and expose the shared ascending signed 64-bit search contract. See [`benchmarks/j/jump_search/README.md`](benchmarks/j/jump_search/README.md).

## Fifth reviewed candidate: Fibonacci search

`fibonacci_search` appears in 11 source repositories and in the direct C, C++, and Rust folders. Their APIs and index widths differ; local ports standardize the result and empty-input behavior while keeping the Fibonacci probe sequence. See [`benchmarks/f/fibonacci_search/README.md`](benchmarks/f/fibonacci_search/README.md).

## Sixth reviewed candidate: interpolation search

`interpolation_search` appears in 15 source repositories and the direct C, C++, and Rust folders. Their arithmetic widths and result APIs differ; the local contract states the range needed to keep the interpolation numerator in bounds, and the workload stays within it. Nine-language ports and a workload are in [`benchmarks/i/interpolation_search/README.md`](benchmarks/i/interpolation_search/README.md).

## Seventh reviewed candidate: ternary search

`ternary_search` appears in 13 source repositories and the direct C, C++, and Rust folders. Upstream variants differ in recursion, precision handling, and result conventions. The local ports use exact search on ascending signed 64-bit values and return any matching index or `-1`; implementations and workload are in [`benchmarks/t/ternary_search/README.md`](benchmarks/t/ternary_search/README.md).

## Eighth reviewed candidate: sentinel linear search

`sentinel_linear_search` appears in three source repositories, including C, Java, and Python. Each uses the target as an end sentinel to avoid a range check on each scan step, though the implementations differ on mutation and result conventions. The local nine-language contract uses a mutable input buffer and restores the final value before returning; see [`benchmarks/s/sentinel_linear_search/README.md`](benchmarks/s/sentinel_linear_search/README.md).

## Ninth reviewed candidate: recursive binary search

`recursive_binary_search` appears in the Java source inventory. The Java implementation recursively narrows a sorted array and returns an index or `-1`; the local contract uses ascending signed 64-bit values, a half-open range, and explicit empty-input handling. Nine-language ports and a workload are in [`benchmarks/r/recursive_binary_search/README.md`](benchmarks/r/recursive_binary_search/README.md).

## Reviewed candidate: sentinel search

`sentinel_search` appears in pinned PHP and TypeScript repositories. Both save the final element, install the target as a sentinel, scan until a match, restore the original value, and normalize a miss to the shared `-1` result. The local contract defines empty input and uses integer-only inputs so PHP loose equality and TypeScript strict equality agree. See [`benchmarks/s/sentinel_search/README.md`](benchmarks/s/sentinel_search/README.md).

## Tenth reviewed candidate: bubble sort

`bubble_sort` appears in 25 source repositories and in the direct C, C++, Rust, and Zig folders. The checked C and C++ versions compare adjacent elements, swap out-of-order pairs, and stop when a pass makes no swaps. The local ports preserve that stable ascending behavior over signed 64-bit values; see [`benchmarks/b/bubble_sort/README.md`](benchmarks/b/bubble_sort/README.md).

## Eleventh reviewed candidate: insertion sort

`insertion_sort` appears in 24 source repositories and in the direct C, C++, Rust, and Zig folders. The checked C and C++ versions maintain a sorted prefix by shifting larger values and inserting each key. Nine-language ports and the workload are in [`benchmarks/i/insertion_sort/README.md`](benchmarks/i/insertion_sort/README.md).

## Twelfth reviewed candidate: selection sort

`selection_sort` appears in 19 source repositories and in the direct C, Rust, and Zig folders. The checked C version selects the minimum value from each remaining suffix and swaps it into place. Its shared workload and nine-language ports are in [`benchmarks/s/selection_sort/README.md`](benchmarks/s/selection_sort/README.md). The two pinned C++ `selection_sort_iterative` files use the same minimum-selection and swap procedure and are cataloged as aliases of this benchmark.

## Thirteenth reviewed candidate: Shell sort

`shell_sort` appears in 15 source repositories and in the direct C, C++, and Rust folders. The checked C version uses a halving gap sequence; the local contract standardizes that sequence and in-place ascending sorting. See [`benchmarks/s/shell_sort/README.md`](benchmarks/s/shell_sort/README.md).

## Fourteenth reviewed candidate: Comb sort

`comb_sort` appears in 14 source repositories and in the direct C, C++, and Rust folders. The inspected C and C++ versions shrink the comparison gap by a factor near 1.3, with differing termination details. The local ports use an integer 10/13 shrink and finish after a gap-one pass makes no swaps. See [`benchmarks/c/comb_sort/README.md`](benchmarks/c/comb_sort/README.md). The C-Sharp `comb_sorter` uses the same default 1.3 shrink factor and is recorded as an alias.

## Fifteenth reviewed candidate: Gnome sort

`gnome_sort` appears in 16 source repositories and in the direct C, C++, and Rust folders. The C implementation can access before the first element; the C++ implementation guards that boundary. The local ports start at the first valid adjacent pair and preserve equal-value order. See [`benchmarks/g/gnome_sort/README.md`](benchmarks/g/gnome_sort/README.md). The C-Sharp `gnome_sorter` follows the same adjacent-swap and backstep procedure and is recorded as an alias.

## Sixteenth reviewed candidate: Odd-even sort

`odd_even_sort` appears in 8 source repositories and in the direct C, C++, and Rust folders. The checked versions repeatedly compare alternating adjacent pairs until a full round makes no swaps. The local contract fixes the even-then-odd phase order and preserves stability. See [`benchmarks/o/odd_even_sort/README.md`](benchmarks/o/odd_even_sort/README.md).

## Seventeenth reviewed candidate: Pancake sort

`pancake_sort` appears in 12 source repositories and in the direct C, C++, and Rust folders. The inspected versions place each active prefix maximum with prefix flips. See [`benchmarks/p/pancake_sort/README.md`](benchmarks/p/pancake_sort/README.md).

## Eighteenth reviewed candidate: Heap sort

`heap_sort` appears in 22 source repositories and in the direct C, C++, Rust, and Zig folders. The checked C example uses a one-based heap; C++ uses a zero-based max heap. The local contract fixes zero-based in-place sorting of signed 64-bit values. See [`benchmarks/h/heap_sort/README.md`](benchmarks/h/heap_sort/README.md).

## Nineteenth reviewed candidate: Quick sort

`quick_sort` appears in 24 source repositories and in the direct C, C++, Rust, and Zig folders. The checked C and C++ versions use a last-element Lomuto pivot, with different range and container APIs. The local ports use half-open ranges and bound recursion by processing the smaller partition recursively. See [`benchmarks/q/quick_sort/README.md`](benchmarks/q/quick_sort/README.md).

## Twentieth reviewed candidate: Binary insertion sort

`binary_insertion_sort` appears in 9 source repositories and in the direct C, C++, and Rust folders. Each version finds an insertion position in the sorted prefix before shifting the suffix; their helper boundaries and APIs differ. The local contract uses a stable upper-bound search over signed 64-bit values. See [`benchmarks/b/binary_insertion_sort/README.md`](benchmarks/b/binary_insertion_sort/README.md).

## Twenty-first reviewed candidate: Cycle sort

`cycle_sort` appears in 10 source repositories and in the direct C, C++, and Rust folders. The inspected versions count smaller values to locate each item and rotate values through their destinations, while their APIs differ. The local ports use the same in-place signed 64-bit contract and guard duplicate skips. See [`benchmarks/c/cycle_sort/README.md`](benchmarks/c/cycle_sort/README.md). The C-Sharp `cycle_sorter` uses the same rank-and-rotate method, but its duplicate skip has no bounds check; the alias note records this source defect.

## Twenty-second reviewed candidate: Stooge sort

`stooge_sort` appears in 8 source repositories and in the direct C, C++, and Rust folders. The inspected implementations compare range endpoints and recursively sort overlapping two-thirds ranges three times. The local workload uses small lengths because the algorithm grows at roughly `O(n^2.71)`. See [`benchmarks/s/stooge_sort/README.md`](benchmarks/s/stooge_sort/README.md).

## Twenty-third reviewed candidate: Merge sort

`merge_sort` appears in 26 source repositories and in the direct C, C++, Rust, and Zig folders. The inspected implementations use stable divide-and-conquer merging but allocate temporary storage differently. The local contract uses stable bottom-up passes and a reusable scratch buffer allocated outside timing. See [`benchmarks/m/merge_sort/README.md`](benchmarks/m/merge_sort/README.md).

## Twenty-fourth reviewed candidate: Counting sort

`counting_sort` appears in 13 source repositories and in the direct C, C++, and Rust folders. The inspected implementations differ in key domain and whether they mutate or return a new array. The local contract sorts signed 64-bit keys in `[-128, 128]` with a shared 257-counter histogram. The `pigeonhole_sort` sources use the same frequency-array reconstruction on this integer-only contract and are cataloged as aliases. See [`benchmarks/c/counting_sort/README.md`](benchmarks/c/counting_sort/README.md).

## Twenty-fifth reviewed candidate: Radix sort

`radix_sort` appears in 14 source repositories and in the direct C, C++, Rust, and Zig folders. The checked C and C++ examples use decimal passes on nonnegative integers, while Rust sorts unsigned values. The local ports use stable byte-wise passes with a sign-order transform for signed 64-bit keys. See [`benchmarks/r/radix_sort/README.md`](benchmarks/r/radix_sort/README.md).

## Twenty-sixth reviewed candidate: Bucket sort

`bucket_sort` appears in 10 source repositories and in the direct C, C++, and Rust folders. The inspected implementations use fixed integer buckets, normalized floating-point buckets, and input-sized buckets for nonnegative integers, respectively. The local ports use 256 stable buckets keyed by the high byte of an order-preserving signed 64-bit representation, then insertion-sort each bucket. See [`benchmarks/b/bucket_sort/README.md`](benchmarks/b/bucket_sort/README.md).

## Target folders without a source repository

The current source snapshot has no matching TheAlgorithms repository for `c3/`, `odin/`, or `v/`. Elisa is a custom language whose compiler lives in the neighboring `Elisa-compiler` project, and it also has no upstream collection. These folders need ports for whichever candidates we select. The direct source matches are limited to C, C++, Nim, Rust, and Zig.

## Next inventory pass

Continue promoting filename candidates to confirmed algorithms by checking source behavior and contracts. Then define shared workloads, record source and license details, and add ports where the selected target language has no suitable implementation.

[`catalog/coverage.py`](catalog/coverage.py) audits every candidate against all nine implementation paths and its guide/workload, resolving documented aliases to their canonical benchmark. Run `python3 catalog/coverage.py --output build/catalog-coverage.json` for the complete backlog. `--require-complete` fails while any candidate still needs review, a benchmark mapping, or files. Invalid sources and programs outside the portable benchmark scope are reported separately and do not count as completed implementations. This is a file and review audit; runtime correctness and discovery of multiple algorithms within an upstream file still need their own evidence.

## Twenty-seventh reviewed candidate: Bead sort

`bead_sort` appears in nine source repositories, including an AArch64 assembly example, and in the direct C, C++, and Rust folders. The inspected C and C++ implementations allocate a bead matrix, while Rust uses nested vectors; all require nonnegative values. The local ports keep the bead-height and gravity model for values in `[0, 63]`, using 64 reusable counters across all nine languages. See [`benchmarks/b/bead_sort/README.md`](benchmarks/b/bead_sort/README.md).

## Twenty-eighth reviewed candidate: Pigeonhole sort

`pigeonhole_sort` appears in eight source repositories. Its frequency-array reconstruction is the same integer sorting operation as `counting_sort` on the shared bounded domain, so the source candidate and its spelling variants alias [the counting-sort contract](benchmarks/c/counting_sort/README.md).

## Twenty-ninth reviewed candidate: Strand sort

`strand_sort` appears in six source repositories and in the direct C++ and Rust folders. The checked implementations extract nondecreasing subsequences and merge each into an accumulated sorted result. The local ports use flat arrays and a caller-provided strand buffer, allocated outside timing. See [`benchmarks/s/strand_sort/README.md`](benchmarks/s/strand_sort/README.md).

## Thirtieth reviewed candidate: Cocktail sort

`cocktail_sort` appears in seven source repositories, including an AArch64 assembly example, and directly in the C folder. The C implementation makes forward and backward adjacent-swap passes, shrinks the active bounds, and stops when a pass makes no swaps. The local ports use the same stable bidirectional strategy across all nine target languages. See [`benchmarks/c/cocktail_sort/README.md`](benchmarks/c/cocktail_sort/README.md). The C-Sharp `cocktail_sorter` and the `cocktail_shaker_sort` candidate use the same bidirectional adjacent-swap algorithm and are recorded as aliases.

## Thirty-first reviewed candidate: Cocktail shaker sort

`cocktail_shaker_sort` appears in four source repositories and directly in Rust. It is the same bidirectional adjacent-swap algorithm as `cocktail_sort`; the pinned Rust version scans the full range while other ports shrink the bounds. It aliases [the cocktail-sort contract](benchmarks/c/cocktail_sort/README.md).

## Thirty-second reviewed candidate: Bitonic sort

`bitonic_sort` appears in six source repositories and directly in the C++ and Rust folders. The inspected implementations use recursive compare-and-swap merges and require power-of-two input lengths. The local ports preserve that constraint and expose one ascending in-place contract across all nine target languages. See [`benchmarks/b/bitonic_sort/README.md`](benchmarks/b/bitonic_sort/README.md).


## Thirty-third reviewed candidate: Exchange sort

`exchange_sort` appears in four source repositories and directly in Rust. The inspected Rust implementation compares each element with every later element and immediately swaps when that later value is smaller. Nine-language ports preserve this exchange pattern under the shared signed 64-bit in-place contract. See [exchange_sort guide](benchmarks/e/exchange_sort/README.md).

## Thirty-fourth reviewed candidate: Recursive selection sort

`selection_sort_recursive` appears in four source repositories and directly in C and C++. The inspected implementations recursively find the minimum in the active suffix, place it at the front, and recurse on the remaining suffix. The benchmark keeps both recursive steps and caps workload length at 256 to bound stack depth. See [recursive selection sort guide](benchmarks/s/selection_sort_recursive/README.md).


## Thirty-fifth reviewed candidate: Introsort

`intro_sort` appears in four source repositories and directly in Rust. The inspected implementation combines quicksort partitioning, insertion sort for short ranges, and heapsort when the recursion budget expires. The local ports calculate the shared 2 floor(log2(n)) depth budget using integer operations so every language uses the same portable rule. See [the introsort guide](benchmarks/i/intro_sort/README.md).

## Thirty-sixth reviewed candidate: Dutch national flag sort

`dutch_national_flag_sort` appears in four source repositories and directly in Rust. The inspected Rust and Python versions use a three-way partition for the values 0, 1, and 2. C LeetCode candidate `75` and both C++ `dnf_sort` candidates use the same Dutch national flag partition for the same three-value domain, so they alias this benchmark. The local contract preserves that domain restriction, defines empty input as unchanged, and provides nine in-place ports. See [the Dutch national flag sort guide](benchmarks/d/dutch_national_flag_sort/README.md).

## Stack-based depth-first search variant

`depth_first_search_with_stack` appears in two mirrored C++ repositories. Its stack traversal marks vertices when they are pushed and emits them when popped, giving a distinct order from recursive-preorder DFS. The shared directed-graph contract preserves edge insertion order and duplicate edges, and nine portable ports implement the bounded traversal. See [the stack-based DFS guide](benchmarks/d/depth_first_search_with_stack/README.md).

## Iterative depth-first reachability

The pinned JavaScript `DepthFirstSearchIterative` searches an unweighted undirected graph with an explicit stack and returns whether the target is reachable. The benchmark uses node IDs 0 through 63, accepts any signed-i64 target (an ID outside the graph is unreachable), and includes an independent breadth-first oracle. See [the iterative DFS guide](benchmarks/d/depth_first_search_iterative/README.md) and [source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Graphs/DepthFirstSearchIterative.js).

## False position

`false_position` appears in two C++ repositories and MATLAB-Octave. The MATLAB implementation maintains a sign-changing bracket, while the C++ helper's recursive endpoint update does not; its default scan also lands exactly on both roots of `x² - x` without exercising the helper. The nine ports use the intended bracket-preserving update on that pinned quadratic with bounded endpoints and residual tolerance. See [the false-position guide](benchmarks/f/false_position/README.md).

## Jump Game II

C LeetCode candidate 45 explores reachable indices in breadth-first order and returns the first jump count that reaches the final index. The nine portable ports preserve the BFS with a FIFO queue, visited positions, and per-index distances. All nine passed 9,253 oracle arrays each and recorded eight workload cases, including shortest paths, unreachable arrays, maximum-length validation, and a 1,024-element one-step path. See the [benchmark guide](benchmarks/j/jump_game_ii/README.md) and [verifier](benchmarks/verify_jump_game_ii.py). Upstream reference: [C LeetCode 45](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/45.c).


## Thirty-seventh reviewed candidate: Tim sort

`tim_sort` appears in eight source repositories and directly in C++ and Rust. The inspected C++ source insertion-sorts runs of 32 before merging them bottom-up; the Rust implementation also uses insertion runs and merges, with a different run-size calculation. The shared nine-language contract follows the explicit 32-item C++ structure and allocates one reusable scratch buffer before timing. See [the Tim sort guide](benchmarks/t/tim_sort/README.md).


## Thirty-eighth reviewed candidate: Recursive bubble sort

`recursive_bubble_sort` appears in three source repositories and directly in C++. The inspected implementation performs an adjacent-swap pass, then recurses on the shorter prefix without an early-exit check. The shared workload caps the recursive length at 256. See [the recursive bubble sort guide](benchmarks/r/recursive_bubble_sort/README.md).

## Thirty-ninth reviewed candidate: Circle sort

`circle_sort` appears in three source repositories, including Java and Python. The inspected versions compare mirrored elements in recursive halves and repeat full passes until no swaps occur. Nine-language ports use the same ascending signed 64-bit contract. See [the circle sort guide](benchmarks/c/circle_sort/README.md).

## Fortieth reviewed candidate: Factorial

`factorial` appears in 22 source repositories, including C, C++, Rust, and Zig. The inspected C example prints arbitrary-precision digits, while C++ uses recursion and limits its input to 20. The shared scalar contract returns exact signed 64-bit results for `0..20` and `-1` outside that range. Nine-language iterative ports and an explicit workload are in [the factorial guide](benchmarks/f/factorial/README.md).

## Forty-first reviewed candidate: Fibonacci

`fibonacci` appears in 20 source repositories, including C, C++, and Rust. Their indexing conventions and variants differ: the C example uses a one-based argument and naive recursion, C++ uses zero-based naive recursion, and Rust contains several variants. The shared scalar contract defines `F(0) = 0`, `F(1) = 1`, computes through `F(92)` in signed 64-bit arithmetic, and returns `-1` outside that input range. See [the Fibonacci guide](benchmarks/f/fibonacci/README.md). The pinned C++ `fibonacci_large` sources use the same iterative recurrence with a custom arbitrary-precision integer; inputs 3..92 alias this bounded benchmark (the source returns 2 for inputs 1 and 2, and input 0 underflows its unsigned counter), while larger outputs fall outside its signed 64-bit ABI.

## Forty-second reviewed candidate: Aliquot sum

`aliquot_sum` appears in 12 source repositories, including C++, Nim, and Rust. The reviewed implementations scan all candidate proper divisors, with different input types and zero behavior. Nine-language ports preserve that scan and define signed 64-bit results, zero and one, negative input, and accumulator overflow. See [the aliquot sum guide](benchmarks/a/aliquot_sum/README.md).

## Forty-third reviewed candidate: Armstrong number

`armstrong_number` appears in 12 source repositories, including C, C++, and Rust. The reviewed implementations use different integer widths and integer or floating-point exponentiation. The nine local ports use exact decimal digit powers across the signed 64-bit input range and prevent sum overflow. See [the Armstrong number guide](benchmarks/a/armstrong_number/README.md).

The separate C++ `armstrong_number_templated` filename implements the same digit-power predicate and is cataloged as an alias of `armstrong_number`; its template wrapper and narrower `int` intermediates do not define a distinct algorithm.

## Forty-fourth reviewed candidate: Bellman–Ford

`bellman_ford` appears in 11 source repositories, including C, C++, and Rust. The inspected implementations use different graph representations and integer/result conventions. The shared directed edge-list contract reports source-reachable negative cycles and signed 64-bit addition overflow explicitly, and keeps reachability separate from distance storage. All nine target-language ports pass the same graph corpus. See [the Bellman–Ford guide](benchmarks/b/bellman_ford/README.md).

## Forty-fifth reviewed candidate: Dijkstra

The `dijkstra` filename candidate appears in 10 source repositories and directly in C, C++, and Rust. The inspected sources use adjacency-matrix selection, a priority queue, and an ordered set, respectively. The local flat-edge-list contract uses nonnegative signed 64-bit weights, separate reachability flags, and checked distance addition; it rejects negative weights and gives all nine ports the same no-allocation selection variant. Python `dijkstra_2` and `dijkstra_alternate`, the binary-grid specialization, Java Dial's bucket variant, R `dijkstra_shortest_path`, JavaScript `DijkstraSmallestPath`, and PHP `Dijkstras` are reviewed aliases on documented input subsets. The C++ `dijkstra_greedy` candidate is excluded because its empty vectors are indexed out of bounds. See [the Dijkstra guide](benchmarks/d/dijkstra/README.md).

## Forty-sixth reviewed candidate: Hamming distance

`hamming_distance` appears in 13 source repositories, including direct C, C++, and Rust files. The C source implements the string form, while C++ and Rust also provide an unsigned 64-bit integer form. The shared contract selects the bitwise integer variant, counts all 64 positions, and records two unsigned inputs. The C++ `count_bits_flip` and Java `CountBitsFlip` sources also XOR the pair and count set bits, so their candidate is an alias over the shared nonnegative signed 64-bit domain. Nine portable implementations and a binary-scalar verifier are in [the Hamming distance guide](benchmarks/h/hamming_distance/README.md).

## Forty-seventh reviewed candidate: GCD

`gcd` appears in five source repositories, including direct C and Zig files. The C source uses recursive Euclid with signed integers; Zig uses an iterative unsigned form and rejects the `(0, 0)` input. The Rust `greatest_common_divisor` source provides recursive and iterative signed Euclid plus an unsigned Stein variant; its name is recorded as an alias under the local nonnegative contract. The local contract uses iterative Euclid over values through `INT64_MAX` and defines `gcd(0, 0) = 0`. All nine implementations share the binary-scalar ABI. See [the GCD guide](benchmarks/g/gcd/README.md). Upstream alias reference: [Rust `greatest_common_divisor.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/greatest_common_divisor.rs).

## Forty-eighth reviewed candidate: LCM

`lcm` appears in five source repositories and directly in C. The reviewed implementations multiply before dividing by the GCD, and the Go version then converts the product to floating point. The `least_common_multiple` sources use the same mathematical definition, including the C++ GCD formula and Java repeated-multiple search; that filename is recorded as an alias. The local contract divides by the GCD first, defines a zero operand result as zero, checks the signed 64-bit limit before multiplication, and returns `-1` when the mathematical result does not fit. Nine portable implementations are in [the LCM guide](benchmarks/l/lcm/README.md). Upstream alias references: [C++ `least_common_multiple.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/least_common_multiple.cpp) and [Java `LeastCommonMultiple.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/LeastCommonMultiple.java).

## Forty-ninth reviewed candidate: LCM of N numbers

`lcm_of_n_numbers` appears in the Rust source inventory. The inspected Rust implementation recursively folds the sequence and multiplies before dividing by the GCD; it assumes at least one value and uses machine-sized unsigned integers. The shared contract defines the empty result as `1`, makes any zero input produce `0`, and returns `-1` if the exact result exceeds `INT64_MAX`. Nine portable implementations use a read-only array ABI and are checked against Python's arbitrary-precision `math.lcm`. See [the LCM of N numbers guide](benchmarks/l/lcm_of_n_numbers/README.md).

## Fiftieth reviewed candidate: LCM sum

`lcm_sum` appears in two C++ source repositories. The implementations use the identity involving weighted Euler totients to compute `sum(LCM(i, n))` for `1 <= i <= n`, with `n` stored as an unsigned 16-bit value. The shared contract accepts `1..=65535` and returns `-1` outside that range; nine portable ports are checked against a direct GCD-based sum. See [the LCM sum guide](benchmarks/l/lcm_sum/README.md).

## Fifty-first reviewed candidate: Leonardo number

`leonardo_number` appears in Java. The source defines `L(0) = L(1) = 1` and `L(n) = L(n-1) + L(n-2) + 1`, with both recursive and iterative variants returning `int`. The shared contract uses the iterative recurrence, extends exact results through index `89` with signed 64-bit storage, and returns `-1` for other indices. Nine portable ports are checked against a fast-doubling Fibonacci identity. See [the Leonardo number guide](benchmarks/l/leonardo_number/README.md).

## Fifty-second reviewed candidate: LERP

`lerp` appears in C and Go. The C source includes `start + t * (end - start)` and an alternate expression, while Go uses `(1 - t) * start + t * end`; the shared benchmark selects the classic form over finite binary64 inputs with `t` in `[0, 1]`. A high-precision oracle checks the nine ports using an input-scaled rounding tolerance. See [the LERP guide](benchmarks/l/lerp/README.md).

## Fifty-third reviewed benchmark algorithm: Phone letter combinations

The JavaScript `LetterCombination.js` and Java `LetterCombinationsOfPhoneNumber.java` sources both recursively enumerate the Cartesian product of keypad letters. They are recorded as two reviewed filename candidates but one benchmark algorithm, with the JavaScript candidate marked as an alias. The shared contract accepts digit sequences from 2 through 9 and writes ordered combinations to a fixed-width caller-provided byte buffer. Nine language ports are checked against exhaustive short inputs and deterministic longer cases. See [the phone letter-combinations guide](benchmarks/l/letter_combinations_of_phone_number/README.md).

## Fifty-fourth reviewed benchmark algorithm: Level-order traversal

The Java source traverses a binary tree with a FIFO queue, processing one level at a time and visiting each node's left child before its right child. The local ABI represents the tree with indexed `[value, left, right]` records and preserves level grouping with cumulative output offsets. Nine language ports were checked on all ordered binary-tree shapes through seven nodes, deterministic generated trees up to 256 nodes, and larger cases with up to 2,047 nodes. See [the level-order traversal guide](benchmarks/l/level_order_traversal/README.md).

## Fifty-fifth reviewed benchmark algorithm: Levenshtein distance

The inspected TheAlgorithms sources under `edit_distance`, `levenshtein_distance`, `levenshtein`, `levenshteindistance`, and `editdistance` names all compute unit-cost insertion, deletion, and substitution distance. The Go source exposes weights, which are fixed to one for this benchmark. Its ASCII-byte contract makes the source languages' byte and character indexing agree; adjacent transpositions remain a separate Damerau–Levenshtein algorithm. The nine ports passed 4,531 oracle inputs, including every pair of binary strings through length five, random pairs, malformed encodings, and maximum-length inputs. The `levenshtein`, `levenshteindistance`, and `editdistance` candidate filenames share this one contract. See [the Levenshtein distance guide](benchmarks/l/levenshtein_distance/README.md).

## Fifty-sixth reviewed benchmark algorithm: 0/1 knapsack tabulation

The C++ `0_1_knapsack.cpp`, Java `KnapsackZeroOneTabulation.java`, and Kotlin `ZeroOneKnapsackProblem.kt` sources use the bottom-up 0/1 knapsack recurrence. The shared contract packs capacity and weight/value pairs into the array scalar ABI, limits capacity to 512 and item count to 128, and uses descending capacities to preserve the one-use-per-item rule with a single DP row. The C++ and Kotlin candidate filenames are aliases of the reviewed Java tabulation candidate. The generic `knapsack` filename group is mixed: its Go, Java, Python, Ruby, Rust, Solidity, TypeScript, and Zig implementations are 0/1 variants and alias this benchmark; its two C++ sources implement fractional knapsack and are cross-listed in that benchmark. Python also exposes an optional unbounded mode. Recursive and memoized knapsack algorithms remain distinct. See [the 0/1 knapsack tabulation guide](benchmarks/k/knapsack_zero_one_tabulation/README.md).

## Fifty-seventh reviewed benchmark algorithm: Sum of digits

Nine TheAlgorithms repositories contain a `sum_of_digits` filename, including direct C++ and Rust sources. The reviewed implementations use decimal division and remainder to accumulate the digit sum; C++ and Rust ignore a negative sign, while the C-Sharp source rejects negative input. The shared contract selects the signed-integer iterative variant, defines the input range as signed 32-bit, and handles the minimum value without signed overflow. Nine portable ports pass a decimal-string oracle over 20,555 inputs. See [the sum-of-digits guide](benchmarks/s/sum_of_digits/README.md).

## Fifty-eighth reviewed benchmark algorithm: Perfect square

Nine TheAlgorithms repositories contain a `perfect_square` implementation. Their sources include floating-point square-root checks and integer-square-root methods; Rust also includes an exact integer binary-search variant. The shared contract extends the predicate to the full signed 64-bit range and uses integer division and remainder to avoid floating-point rounding and square overflow. All nine ports are checked against Python `math.isqrt` on 23,126 inputs. See [the perfect-square guide](benchmarks/p/perfect_square/README.md).

## Fifty-ninth reviewed benchmark algorithm: Absolute value

Fourteen TheAlgorithms repositories contain an `abs` source, including direct Nim and Rust files. The reviewed implementations include ordinary sign checks and a Go bitwise variant; the related Java and TypeScript `absolute_value` sources use the same mapping and are cataloged as aliases. The shared contract covers signed 64-bit integers and returns `-1` for `INT64_MIN`, whose positive magnitude overflows the result type. All nine ports use the non-conflicting C-ABI symbol `abs_i64`. See [the absolute-value guide](benchmarks/a/abs/README.md).

## Sixtieth reviewed benchmark algorithm: Binary to decimal

Nine TheAlgorithms repositories contain a `binary_to_decimal` implementation. The sources accept binary text or a numeric representation made of binary digits; the shared contract packs those bits into a most-significant-first array, allows leading zeroes, and limits inputs to 63 bits so the decimal result fits signed 64-bit. Negative-string support in the Dart and Python variants is outside this unsigned benchmark contract. All nine ports pass exhaustive bit sequences through length 12, deterministic random cases, and invalid-input checks. See [the binary-to-decimal guide](benchmarks/b/binary_to_decimal/README.md).

## Sixty-first reviewed benchmark algorithm: Signum

Four TheAlgorithms repositories contain a `signum` implementation. JavaScript, Python, and Rust sources accept real values and return the sign; the shared scalar contract covers the full signed 64-bit integer domain. Comparison-based ports handle `INT64_MIN` without negation. The nine implementations are checked across dense small inputs and deterministic full-width values. See [the signum guide](benchmarks/s/signum/README.md).

## Sixty-second reviewed benchmark algorithm: Is even

Four TheAlgorithms repositories contain an `is_even` implementation. The inspected Java source uses a bit test, while JavaScript, Python, and TypeScript use parity or validate integer inputs. The shared contract returns `1` for even and `0` for odd signed 64-bit integers, including `INT64_MIN`. C++ `check_even_odd.cpp` uses the same least-significant-bit test, and PHP `check_even` uses the remainder predicate; both are cataloged as aliases. All nine ports are checked against dense and deterministic full-width inputs. See [the is-even guide](benchmarks/i/is_even/README.md).

## Sixty-third reviewed benchmark algorithm: Decimal to binary

Twelve TheAlgorithms repositories contain a `decimal_to_binary` implementation, including two C++ repositories and Go's `decimaltobinary` name. They convert by division/remainder, bit operations, or recursive decomposition; zero and negative-input behavior varies. The shared contract writes binary digits for nonnegative signed 64-bit inputs into a caller-provided byte buffer. All nine ports include `INT64_MAX` and reject negatives. The Go alias accumulates low bits, shifts, then reverses, and its ambiguous source comment is not used to claim a wider numeric bound. See [the decimal-to-binary guide](benchmarks/d/decimal_to_binary/README.md).

## Sixty-fourth reviewed benchmark algorithm: Double factorial

Four TheAlgorithms repositories contain a `double_factorial` implementation. C++ and Python include iterative and recursive forms, while C-Sharp uses arbitrary-precision multiplication. The shared contract defines `0!! = 1`, returns exact signed 64-bit results through `33!!`, and reports `-1` for negative or overflowing inputs. See [the double-factorial guide](benchmarks/d/double_factorial/README.md).

## Sixty-fifth reviewed benchmark algorithm: Power of two

The `power_of_two` and `is_power_of_two` filename candidates name the same predicate and are cataloged as a canonical benchmark and alias. Inspected C++, Dart, Ruby, JavaScript, Python, and Rust sources use variants of the bit-clearing test, though several return true for zero. The local contract follows the positive-power definition, returns `1` only for positive powers of two, and covers the signed 64-bit domain. See [the power-of-two guide](benchmarks/p/power_of_two/README.md).

## Sixty-sixth reviewed benchmark algorithm: Prime check

The `prime_check`, `prime`, `check_prime`, and `is_prime` filename candidates implement the same scalar primality predicate and are grouped under `prime_check`. Across their pinned C, C++, C-Sharp, Dart, F-Sharp, Java, JavaScript, Julia, Kotlin, Lua, MATLAB-Octave, PHP, Python, R, and Rust sources, trial division is the common exact approach; Java also includes a randomized Fermat variant. The shared contract uses deterministic trial division for inputs through `2,147,483,647`, returning `-1` above that bound. See [the prime-check guide](benchmarks/p/prime_check/README.md).

## Sixty-seventh reviewed benchmark algorithm: Perfect number

Ten TheAlgorithms repositories contain this predicate under the `perfect_number`, `perfect_number_checker`, or `perfectnumber` filenames. The pinned sources agree that a perfect number equals the sum of its positive proper divisors; their implementations range from direct scans to paired-divisor scans through the square root. `perfect_number_checker` and `perfectnumber` are cataloged as aliases of `perfect_number`. The benchmark uses the paired-divisor method for signed inputs through `1,000,000,000,000`, with an explicit result for larger values. See [the perfect-number guide](benchmarks/p/perfect_number/README.md).

## Sixty-eighth reviewed benchmark algorithm: Catalan number

Pinned C, C++, C-Sharp, Go, Java, JavaScript, Julia, Nim, Python, R, and Rust sources compute or generate the standard Catalan sequence. The `catalan`, `catalan_numbers`, `catalan_sequence`, and `catalannumber` filename candidates alias the exact indexed `catalan_number` benchmark. One Rust source applies a modulus and is documented as a separate output variant. The shared signed 64-bit contract accepts indices 0 through 35; the ports cancel numerator and denominator factors before multiplying to keep every intermediate exact. See [the Catalan-number guide](benchmarks/c/catalan_number/README.md).

## Sixty-ninth reviewed benchmark algorithm: Longest increasing subsequence

`longest_increasing_subsequence` appears in eight source repositories, including the direct C++, Rust, and Zig folders. The checked C++, Java, Rust, and Zig implementations use strict comparison; Rust returns an actual subsequence while the local benchmark measures its length. The canonical Python file permits equality, and separately named Python and C variants also compute non-decreasing subsequences, so those are excluded from this strict contract. Strict lower-bound O(n log n) variants in Java, C++, Python, and Go are cataloged as aliases. The local nine-language contract accepts signed 64-bit arrays up to 512 values and verifies the quadratic DP ports against a separate binary-search tails oracle. See [`benchmarks/l/longest_increasing_subsequence/README.md`](benchmarks/l/longest_increasing_subsequence/README.md).

## Seventieth reviewed benchmark algorithm: Coin change

`coin_change` appears in 13 source repositories, with both minimum-coin and combination-counting variants under the same normalized name. The local contract selects minimum count with unlimited positive denominations. The Java and JavaScript files expose both minimum-count and combination-counting functions; Scala counts combinations, while the Lua and Java greedy variants return currency-specific coin lists. The two `coin_change_topdown` C++ sources solve the same minimum-count problem and are cataloged as an alias. All nine portable ports passed 4,836 BFS-oracle inputs. See [the coin-change guide](benchmarks/c/coin_change/README.md).

The separate `dynamic_coin_change_solver` candidate implements its own backward-induction choice sequence: it chooses the next coin by selecting the remainder whose precomputed minimum coin count is smallest, with descending-denomination tie order. It can return a non-optimal sequence; amount 12 with coins `[1, 4, 5]` produces `[5, 5, 1, 1]`. It is mapped to a distinct benchmark rather than the minimum-count contract above. See [the dynamic coin-change solver guide](benchmarks/d/dynamic_coin_change_solver/README.md).

## Seventy-first reviewed benchmark algorithm: Longest common subsequence

The `longest_common_subsequence` filename appears in eight source repositories; the shorter `lcs` name appears in C, Julia, Kotlin, and TypeScript. The inspected variants use the LCS dynamic-programming recurrence, but their APIs return either the sequence or its length. This benchmark standardizes on the length of the longest common subsequence of two ASCII sequences; `lcs` is cataloged as an alias. All nine portable ports passed 4,249 full-table-oracle inputs, including every binary-alphabet sequence pair through length five, deterministic random pairs, 255-byte boundaries, and malformed packed inputs. See [the LCS guide](benchmarks/l/longest_common_subsequence/README.md).

## Seventy-second reviewed benchmark algorithm: Rabin–Karp search

`rabin_karp` appears in nine pinned repositories, including the direct C++ and Rust folders. The sources use different rolling-hash constants and return a first index, all indices, or a boolean; some also differ on empty patterns. The local contract normalizes this to ASCII-pattern presence (`1` or `0`), defines an empty pattern as present, validates the packed input, and checks bytes after hash matches to handle collisions. All nine portable ports passed 4,247 naive-oracle inputs, including exhaustive short binary sequences, deterministic random pairs, a crafted hash collision, maximum lengths, and invalid encodings. See [the Rabin–Karp guide](benchmarks/r/rabin_karp/README.md).

## Seventy-third reviewed benchmark algorithm: Sieve of Eratosthenes

`sieve_of_eratosthenes` appears in 12 pinned repositories, including the direct C++ and Rust folders. The sources return prime lists or boolean sieve arrays, and Java and R also provide count helpers. They mostly use the inclusive bound and begin marking at each prime squared; one JavaScript source begins at twice the prime. The local contract counts primes through an inclusive limit from 0 to 4096, so every port uses the same scalar result and fixed-buffer bound. All nine ports passed 4,104 trial-division-oracle inputs. See [the sieve guide](benchmarks/s/sieve_of_eratosthenes/README.md).

## Seventy-fourth reviewed benchmark algorithm: Linear sieve

`linear_sieve` appears in JavaScript, Rust, and Scala, including the direct Rust folder. The sources return prime lists, and Rust also retains a minimum-prime-factor table for factorization. The local benchmark uses the standard linear-sieve inner bound and returns the prime count through an inclusive limit from 0 to 4096. All nine ports passed 4,104 trial-division-oracle inputs. See [the linear-sieve guide](benchmarks/l/linear_sieve/README.md).

## Seventy-fifth reviewed benchmark algorithm: Sieve of Atkin

The Sieve of Atkin appears in pinned Java and Python sources. Both toggle candidates from quadratic forms modulo 12, remove multiples of prime squares, and include 2 and 3 separately. Their APIs return prime lists; the local scalar contract returns the prime count through an inclusive limit from 0 to 4096. All nine ports passed 4,104 trial-division-oracle inputs. See [the Atkin-sieve guide](benchmarks/s/sieve_of_atkin/README.md).

## Seventy-sixth reviewed benchmark algorithm: Next prime number

The pinned Python source searches for the smallest prime strictly greater than its input, returning 2 for negative values and zero. The local scalar contract bounds input to -4096..4096 and returns -1 outside that range. All nine ports passed 8,199 oracle inputs, covering every supported input and signed 64-bit boundaries. See [the next-prime guide](benchmarks/n/next_prime_number/README.md).

## Seventy-seventh reviewed benchmark algorithm: Perfect cube

Perfect-cube predicates appear in Java, JavaScript, Julia, Python, Rust, and TypeScript. The sources include floating-point and binary-search variants; Rust's search can overflow when negating or cubing signed values. The local contract accepts signed values through magnitude `10^12` and uses exact integer binary search over cube-root magnitudes, including negative cubes. All nine ports passed 64,541 oracle inputs. See [the perfect-cube guide](benchmarks/p/perfect_cube/README.md).

## Seventy-eighth reviewed benchmark algorithm: Binomial coefficient

The binomial coefficient appears in six pinned source repositories. Their implementations include Pascal-triangle, recursive, and multiplicative formulations. The Go `dynamic/Bin2` source maps to the Pascal-triangle package; Go `math/Combinations` and Java/Python/Rust `combinations` map to the separate multiplicative package. The binomial-coefficient contract uses the standard `C(n,k)` definition, returns 0 when `k > n`, and bounds `n` at 66 so every exact result fits signed 64-bit output. All nine ports previously passed 5,057 pairs against Python's arbitrary-precision `math.comb`. See the [binomial-coefficient guide](benchmarks/b/binomial_coefficient/README.md) and [multiplicative guide](benchmarks/b/binomial_calculate/README.md).

## Seventy-ninth reviewed benchmark algorithm: Find minimum

The `find_min` candidate appears in seven source repositories. The inspected Python source provides iterative and recursive scans, while the Dart example prints the result and assumes a nonempty list. The local contract scans signed 64-bit arrays of up to 512 values and returns the minimum. All nine ports passed 4,432 oracle arrays, including signed boundaries and invalid lengths. See [the find-minimum guide](benchmarks/f/find_min/README.md).

## Eightieth reviewed benchmark algorithm: Find maximum

The `find_max` candidate appears in five source repositories. The inspected Python source provides iterative and divide-and-conquer scans and rejects empty lists. The local contract scans signed 64-bit arrays of up to 512 values and returns the maximum. All nine ports passed 4,432 oracle arrays, including signed boundaries and invalid lengths. See [the find-maximum guide](benchmarks/f/find_max/README.md).

## Eighty-first reviewed benchmark algorithm: Decimal to octal

Six pinned repositories contain decimal-to-octal conversion sources. They vary in prefix and negative-input behavior; the C console implementation also does not print zero. The local byte-output contract emits prefix-free octal digits for nonnegative signed 64-bit inputs, with explicit negative and buffer-capacity results. All nine ports passed 4,620 oracle inputs. See [the decimal-to-octal guide](benchmarks/d/decimal_to_octal/README.md).

## Eighty-second reviewed benchmark algorithm: Decimal to hexadecimal

Six pinned repositories contain decimal-to-hexadecimal conversion sources. The local contract normalizes case and prefix differences to lowercase, prefix-free digits for nonnegative signed 64-bit inputs and uses the shared byte-output ABI. All nine ports passed 4,621 oracle inputs. See [the decimal-to-hexadecimal guide](benchmarks/d/decimal_to_hexadecimal/README.md).

## Eighty-third reviewed benchmark algorithm: Octal to decimal

Six pinned repositories contain octal-to-decimal conversion sources. Their interfaces range from strings to numeric digit encodings; the shared contract uses a most-significant-first array of octal digits, validates each digit, and caps the length at 21 so the result fits signed 64-bit. All nine ports passed 5,117 oracle arrays, including exhaustive short inputs, deterministic random values, malformed digits, and the maximum result. See [the octal-to-decimal guide](benchmarks/o/octal_to_decimal/README.md). The pinned JavaScript `OctToDecimal.js` uses the same positional base-8 evaluation on decimal-encoded octal digits; it maps to this contract for valid digits and numeric encodings through 999,999,999,999,999. See the [pinned source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/OctToDecimal.js).

## Eighty-fourth reviewed benchmark algorithm: Hexadecimal to decimal

Four filename candidates were found for hexadecimal-to-decimal conversion. The pinned Dart, PHP, and Python sources validate hexadecimal representations; their whitespace and signed-input behavior differs, so the shared contract uses an unsigned most-significant-first array of numeric hexadecimal digits with signed 64-bit overflow rejection. The cataloged Rust path does not resolve at its pinned revision. All nine ports passed 4,804 oracle arrays. See [the hexadecimal-to-decimal guide](benchmarks/h/hexadecimal_to_decimal/README.md).

## Eighty-fifth reviewed benchmark algorithm: Binary to octal

Five filename candidates cover binary-to-octal conversion. The inspected C, Dart, Java, and Python sources convert bit strings or decimal-encoded bit digits; input validation and signed-input behavior vary. The shared contract accepts a most-significant-first bit array, writes prefix-free octal digits, and checks insufficient buffer capacity. The cataloged Rust path does not resolve at its pinned revision. All nine ports passed 8,606 oracle arrays. See [the binary-to-octal guide](benchmarks/b/binary_to_octal/README.md).

## Eighty-sixth reviewed benchmark algorithm: Binary to hexadecimal

Five filename candidates cover binary-to-hexadecimal conversion. The inspected C, Dart, Java, and Python sources vary in validation, sign handling, case, and prefixes. The shared contract accepts a most-significant-first bit array and emits prefix-free lowercase hexadecimal digits. The cataloged Rust path does not resolve at its pinned revision. All nine ports passed 8,606 oracle arrays. See [the binary-to-hexadecimal guide](benchmarks/b/binary_to_hexadecimal/README.md).

## Eighty-seventh reviewed benchmark algorithm: Octal to binary

Five filename candidates cover octal-to-binary conversion. The inspected C, Dart, Java, and Python sources convert octal strings or decimal-encoded digits; they differ on signed values and leading-zero output. The shared contract accepts a most-significant-first octal digit array and writes canonical prefix-free binary text. The cataloged Rust path does not resolve at its pinned revision. All nine ports passed 5,118 oracle arrays. See [the octal-to-binary guide](benchmarks/o/octal_to_binary/README.md).

## Eighty-eighth reviewed benchmark algorithm: Octal to hexadecimal

Five filename candidates cover octal-to-hexadecimal conversion. The inspected C, Dart, Java, and Python sources differ in signed-input support, prefixes, and letter case. The shared contract accepts a most-significant-first octal digit array and writes lowercase prefix-free hexadecimal. The cataloged Rust path does not resolve at its pinned revision. All nine ports passed 5,118 oracle arrays. See [the octal-to-hexadecimal guide](benchmarks/o/octal_to_hexadecimal/README.md).

## Eighty-ninth reviewed benchmark algorithm: Hexadecimal to binary

Two filename candidates cover hexadecimal-to-binary conversion. The inspected Dart source maps hexadecimal characters to binary groups and accepts signed input. The shared contract uses a most-significant-first numeric digit array, rejects values beyond signed 64-bit range, and emits canonical prefix-free binary. The cataloged Rust path does not resolve at its pinned revision. All nine ports passed 4,803 oracle arrays. See [the hexadecimal-to-binary guide](benchmarks/h/hexadecimal_to_binary/README.md).

## Ninetieth reviewed benchmark algorithm: Hexadecimal to octal

Three filename candidates cover hexadecimal-to-octal conversion. The inspected C console program and Dart source convert through numeric intermediates; Dart accepts signed input and uses floating-point powers. The shared contract bounds inputs to nonnegative signed 64-bit values and emits prefix-free octal. The cataloged Rust path does not resolve at its pinned revision. All nine ports passed 4,804 oracle arrays. See [the hexadecimal-to-octal guide](benchmarks/h/hexadecimal_to_octal/README.md).


## Ninety-first reviewed benchmark algorithm: Decimal to any base

The C and Java repositories contain `decimal_to_any_base`; Dart and Python contain the related `decimal_to_any` filename, and JavaScript and PHP contain similar routines named `int_to_base` and `base_x`. Their source APIs vary in alphabet, validation, and sign behavior. The shared contract converts a nonnegative signed 64-bit value to radix 2 through 36 using uppercase prefix-free digits; `decimal_to_any`, `int_to_base`, and `base_x` are cataloged as aliases over their shared normalized domains. All nine portable implementations passed 5,689 oracle arrays, including every value 0 through 128 in each radix, signed 64-bit boundaries, invalid inputs, and insufficient output capacity. See [the decimal-to-any-base guide](benchmarks/d/decimal_to_any_base/README.md).

## Ninety-second reviewed benchmark algorithm: Any base to decimal

The pinned Java source parses digits `0`-`9` and `A`-`Z` using a caller-supplied radix. The local contract accepts most-significant-first digit arrays in bases 2 through 36 and checks every multiply-and-add against the signed 64-bit maximum; this also avoids the narrower accumulator in the upstream Java source. All nine portable implementations passed 21,370 oracle arrays, including exhaustive one- and two-digit sequences across every radix, short three-digit sequences, signed 64-bit boundaries, invalid digits, and overflow. See [the any-base-to-decimal guide](benchmarks/a/any_base_to_decimal/README.md).


## Ninety-third reviewed benchmark algorithm: Decimal to any base using a stack

The pinned Java `DecimalToAnyUsingStack` source pushes successive remainder digits into a character stack and supports bases 2 through 16. The nine portable ports share its uppercase output and radix range, widen the input to nonnegative signed 64-bit, and use the supplied output buffer as the temporary stack. All nine ports passed 3,030 oracle arrays, including zero, signed 64-bit limits, invalid arguments, and insufficient capacity. See [the stack-based decimal conversion guide](benchmarks/d/decimal_to_any_using_stack/README.md).


## Ninety-fourth reviewed benchmark algorithm: Any base to any base

The pinned Java `AnyBaseToAnyBase` utility accepts radix-2-through-36 digits and converts through a decimal intermediate. JavaScript's `ArbitraryBase` source supports custom alphabets and has an exact `BigInt` variant; it aliases this benchmark after normalizing to the shared digit alphabet. The contract uses numeric digit arrays, uppercase output, and overflow-checked signed 64-bit accumulation because the Java source's accumulator is narrower. All nine portable ports passed 8,263 oracle arrays across radix pairs, short digit sequences, boundaries, invalid inputs, and overflow. See [the any-base-to-any-base guide](benchmarks/a/any_base_to_any_base/README.md).


## Ninety-fifth reviewed benchmark algorithm: Base -2 conversion

The pinned Python source converts signed decimal integers to negabinary by dividing by -2 and correcting negative remainders. The benchmark emits the canonical binary digit string, allowing the entire signed 64-bit domain to share one output contract across languages. All nine ports are checked against a Euclidean-remainder oracle, including both 64-bit boundaries. See [the base -2 conversion guide](benchmarks/b/base_neg2_conversion/README.md).


## Ninety-sixth reviewed benchmark algorithm: Negative binary base to integer

The pinned Python source evaluates digits by their alternating signed powers of two. The shared contract folds a most-significant-first bit array of up to 63 digits, ensuring all possible inputs and intermediate values fit signed 64-bit. All nine portable ports are checked against Python's arbitrary-precision oracle across exhaustive short arrays and maximum-length patterns. See [the negative-binary decoder guide](benchmarks/n/negative_binary_base_to_int/README.md).


## Ninety-seventh reviewed benchmark algorithm: Base16 codec

The pinned Python and Rust sources each provide uppercase Base16 encoding and strict decoding. The benchmark exposes both directions through a mode and byte-array contract, requiring uppercase input and an even digit count on decode. All nine portable ports are checked against exhaustive one- and two-byte inputs, deterministic longer payloads, malformed input, and capacity cases. See [the Base16 guide](benchmarks/b/base16/README.md).

## Ninety-eighth reviewed benchmark algorithm: Base32 codec

The pinned Python and Rust sources provide Base32 encoding and decoding with the uppercase RFC 4648 alphabet. The byte-array benchmark normalizes the APIs across all nine languages, checks padded and valid unpadded forms, and rejects malformed padding and nonzero trailing bits. The oracle covers every one-byte and two-byte payload in both directions. See [the Base32 guide](benchmarks/b/base32/README.md).

## Ninety-ninth reviewed benchmark algorithm: Base64 codec

The pinned Go, Java, and Rust sources provide Base64 encoding and decoding. The byte-array contract uses the RFC 4648 alphabet, supports canonical padded and valid unpadded input, and rejects malformed padding and nonzero trailing bits in all nine portable ports. The oracle covers every one-byte and two-byte payload in both directions. See [the Base64 guide](benchmarks/b/base64/README.md).

## One hundredth reviewed benchmark algorithm: Floyd–Warshall shortest paths

The pinned C and C++ sources initialize an adjacency matrix and apply the triple-loop recurrence; Rust returns a map of all-pairs distances. The Go `floydwarshall` and Python `graphs_floyd_warshall` candidates use the same recurrence and are cataloged as aliases; Go's float64 implementation is equivalent for nonempty graphs with exactly representable integer weights, while Python's console output and return wrapper are outside the benchmarked operation. The benchmark normalizes these graph APIs to a bounded edge-list input and a requested source row, with checked signed 64-bit arithmetic and reachable negative-cycle errors. All nine portable ports pass exhaustive small-graph and deterministic larger-graph checks. See [the Floyd–Warshall guide](benchmarks/f/floyd_warshall/README.md). Upstream aliases: [Go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/floydwarshall.go) and [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/graphs_floyd_warshall.py).

## Floyd's Triangle

The pinned Java source builds successive rows by appending increasing integers. The shared contract flattens the row-major triangle into unsigned 16-bit little-endian output for the nine portable implementations. See [the Floyd's Triangle guide](benchmarks/f/floyd_triangle/README.md) and [source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/FloydTriangle.java).

## Conway's Game of Life

The pinned Python source documents Conway's B3/S23 rules for one generation. Its top and left NumPy slices can be empty at the boundary, so the shared contract uses the documented finite-board behavior with dead cells outside the edge and no wraparound. All nine portable ports accept a flattened square board and emit the next generation as row-major bytes. See [the Game of Life guide](benchmarks/g/game_of_life/README.md) and [source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/cellular_automata/game_of_life.py).


## One hundred first reviewed benchmark algorithm: Topological sort

The pinned C and C++ sources use visited-only depth-first postorder and do not reliably reject cycles; the C implementation also uses a fixed 40-node stack. The pinned Rust source and the separate `topological_sort_by_kahns_algo` C++ candidate use Kahn's algorithm and map to this FIFO benchmark. The Python `g_topological_sort` candidate maps to the separate `topological_sort_dfs` benchmark. This benchmark fixes a portable graph-order contract with deterministic FIFO Kahn ordering, coalesced duplicate edges, and explicit cycle handling. All nine language ports passed exhaustive graphs through three vertices, randomized graph cases, malformed inputs, and maximum-size workloads. See [the topological-sort guide](benchmarks/t/topological_sort/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/graphs/topological_sort.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/topological_sort.cpp), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a4c939ec5163648458a8c2b46fd4c/src/graph/topological_sort.rs).


## One hundred second reviewed benchmark algorithm: Breadth-first search

The pinned C++ source supports directed or bidirectional edges and returns the visited set; the Rust source returns traversal history only through a requested target. The local contract standardizes a full directed traversal from a selected start, with ascending-neighbor order and byte-encoded output. The verifier exhausts all directed graphs through three vertices for every start and checks random, malformed, and boundary cases across nine languages. See [the breadth-first-search guide](benchmarks/b/breadth_first_search/README.md). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/breadth_first_search.cpp) and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/breadth_first_search.rs).

## One hundred third reviewed benchmark algorithm: Depth-first search

The pinned C++ source recursively traverses an undirected graph; the Rust implementation named DFS uses a deque as a stack and stops at a requested target. The local contract provides a full directed traversal in recursive preorder, encoded as vertex bytes. The Python `depth_first_search_2` candidate is excluded because its recursive helper loops over every graph key rather than the current vertex's neighbors, so the named DFS ignores edges and can index outside its visited array for noncontiguous keys. All nine ports are checked against exhaustive small graphs and deterministic larger inputs. See [the depth-first-search guide](benchmarks/d/depth_first_search/README.md). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/depth_first_search.cpp), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/depth_first_search_2.py), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/depth_first_search.rs).

The C `dfs_recursive` candidate searches an undirected graph recursively for a target and aliases [recursive depth-first reachability](benchmarks/d/depth_first_search_recursive/README.md) on valid graphs with distinct source and target vertices. Its helper does not return true when source and target are equal, so that case is outside the alias subset.


## One hundred fourth reviewed benchmark algorithm: Tower of Hanoi

The pinned C and Python sources recursively emit the standard three-peg move sequence. The C++ source simulates the same recurrence by moving disks between tower states. The benchmark writes each move as a pair of peg-ID bytes, verifies the legal disk state after every move, and covers all six peg assignments through twelve disks. The Haskell filename towers_of_hanoi uses the same recursive recurrence and aliases this canonical contract. See [the Tower of Hanoi guide](benchmarks/t/tower_of_hanoi/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/misc/tower_of_hanoi.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/tower_of_hanoi.cpp), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/tower_of_hanoi.py), and [Haskell](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/Misc/TowersOfHanoi.hs).


## One hundred fifth reviewed benchmark algorithm: Bogo sort

The pinned C, C++, Nim, and Rust sources repeatedly shuffle until the input is sorted; their shuffle APIs and random seeds differ. The C# `bogo_sorter` and Go and Lua `bogosort` filenames implement the same algorithm and are recorded as aliases. The shared contract uses Fisher–Yates with a fixed unsigned LCG stream so all nine ports produce reproducible behavior. Since expected work grows factorially, the workload is capped at six values. The verifier checks every relative-order and duplicate pattern through length six, along with signed boundaries and the published workload. See [the bogo-sort guide](benchmarks/b/bogo_sort/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/bogo_sort.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/bogo_sort.cpp), [Nim](https://github.com/TheAlgorithms/Nim/blob/63eec16614b46c91078653e8d3c049fe99ad36b3/sorts/bogo_sort.nim), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/bogo_sort.rs), [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sorters/Comparison/BogoSorter.cs), [Go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/sort/bogosort.go), and [Lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/sorting/bogosort.lua).


## One hundred sixth reviewed benchmark algorithm: Two sum

The pinned Rust source uses a one-pass complement map, while Python and JavaScript provide independent implementations of the same pair-sum task. The shared contract accepts a target and up to 256 signed 32-bit values, returning the earliest matching pair by increasing right index and then earliest left index; missing and invalid inputs have explicit sentinel results. The fixed open-addressing table gives each language a portable implementation without platform-specific instructions. All nine ports passed 35,683 oracle cases and the 12 published workload records. See [the Two Sum guide](benchmarks/t/two_sum/README.md). Upstream references: [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/general/two_sum.rs), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/two_sum.py), and [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/TwoSum.js).


## One hundred seventh reviewed benchmark algorithm: Prim minimum spanning tree

The pinned C implementation expects a connected graph and limits its matrix to 20 vertices. C++ and Rust use priority queues and return the spanning tree grown from a selected start vertex; Rust returns the tree of the reachable component for disconnected inputs. The shared contract accepts an undirected packed edge list with up to 64 vertices, ignores self-loops, coalesces parallel edges by minimum weight, and reports total minimum-spanning-tree weight for connected graphs. All nine portable ports passed an independent Kruskal oracle over 1,505 small exhaustive, random, malformed, and boundary graph inputs, plus 12 workload records. See [the Prim guide](benchmarks/p/prim/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/greedy_approach/prim.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/prim.cpp), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/prim.py), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/prim.rs).


## One hundred eighth reviewed benchmark algorithm: Kruskal minimum spanning tree

The pinned C and C++ implementations sort weighted edges and use disjoint sets; the C source’s qsort comparator returns a boolean, which does not provide a valid three-way ordering. The shared contract uses a deterministic portable heapsort over packed edge keys followed by union by rank and path compression. It accepts the same bounded undirected edge-list domain as Prim and returns the tree’s total weight, with explicit empty, disconnected, self-loop, and parallel-edge behavior. All nine ports passed an independent dense Prim oracle over 1,505 exhaustive small, random, malformed, and boundary inputs, plus 12 workload records. See [the Kruskal guide](benchmarks/k/kruskal/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/graphs/kruskal.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/kruskal.cpp), [Go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/kruskal.go), and [Swift](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/graph/spanning_tree/kruskal.swift).


## One hundred ninth reviewed benchmark algorithm: Modular exponentiation

The pinned C++ implementation uses binary exponentiation with modular reduction, while C# multiplies once per exponent and R supports modular and unmodded modes. The shared contract accepts a signed 32-bit base, nonnegative signed 32-bit exponent, and positive signed 32-bit modulus; negative bases are normalized to the mathematical residue in `[0, modulus)`. The nine portable ports use repeated squaring with products bounded to signed 64-bit. All passed 3,661 oracle inputs, including exhaustive small combinations, random values, boundaries, and malformed arrays, plus 12 workload records. See [the modular-exponentiation guide](benchmarks/m/modular_exponentiation/README.md). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/modular_exponentiation.cpp), [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/ModularExponentiation.cs), and [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/mathematics/modular_exponentiation.r).


## One hundred tenth reviewed benchmark algorithm: Number of digits

The pinned Java, Python, and JavaScript sources include arithmetic, logarithmic, and string-based implementations. The TypeScript source accepts only positive integers, while the Ruby loop does not terminate for negative values. The shared contract counts decimal digits in the magnitude of any signed 64-bit input, with zero returning one; all nine ports handle `i64` minimum without overflowing when computing its magnitude. The scalar verifier passed 2,656 oracle inputs per language, including dense small values, random signed 64-bit values, decimal powers and neighbors, and boundaries, plus 22 workload records. See [the number-of-digits guide](benchmarks/n/number_of_digits/README.md). Upstream references: [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/NumberOfDigits.java), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/number_of_digits.py), [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/number_of_digits.rb), and [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/number_of_digits.ts).


## One hundred eleventh reviewed benchmark algorithm: Binary exponentiation

The pinned Rust and Java sources implement integer powers, while Python provides recursive and iterative power variants; the nearby C++ `fast_power` API uses real-number inputs. The shared contract standardizes exact nonnegative signed-32-bit base and exponent inputs, returns the result only when it fits in signed 64-bit, and reports invalid input or overflow as `-1` (`0^0` is 1). All nine portable ports passed 2,041 oracle inputs per language, including exhaustive small pairs, randomized inputs, overflow boundaries, and malformed arrays, plus 14 workload records. The Elisa loop expression returns the accumulated value after its final local assignment. See [the binary-exponentiation guide](benchmarks/b/binary_exponentiation/README.md). Upstream references: [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/binary_exponentiation.rs), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/divideandconquer/BinaryExponentiation.java), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/binary_exponentiation.py), and [C++ fast power](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/fast_power.cpp).


## One hundred twelfth reviewed benchmark algorithm: Palindrome

The pinned filename is not one uniform implementation: C checks numeric palindromes, Java and Python include exact string checks, and Rust's string implementation ignores non-alphanumeric characters and ASCII case. The shared contract selects exact ASCII sequence comparison, with case, punctuation, spaces, and control characters preserved. It accepts up to 4,096 code points in `[0, 127]`; empty input is a palindrome, invalid values or lengths return `-1`, and valid results are `0` or `1`. All nine ports passed 20,320 oracle inputs per language, including all sequences through length six over a small alphabet, random inputs, malformed values, size boundaries, and 18 workload records. See [the palindrome guide](benchmarks/p/palindrome/README.md). Upstream references: [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/Palindrome.java), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/palindrome.py), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/palindrome.rs), and [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/palindrome.c).


## One hundred thirteenth reviewed benchmark algorithm: Happy number

The pinned Java and Python implementations use the standard sum-of-squared-decimal-digits definition. Both pinned C++ copies instead sum digits to a digital root, which misclassifies values such as 7. The shared contract accepts positive signed 64-bit integers, returns `1` for happy and `0` for unhappy values, and uses `-1` for nonpositive inputs. All nine portable ports use Floyd cycle detection and passed 10,550 set-oracle inputs per language, including the small integer range, deterministic random inputs, known values, and signed boundaries, plus 18 workload records. See [the happy-number guide](benchmarks/h/happy_number/README.md). Upstream references: [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/HappyNumber.java), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/happy_number.py), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/happy_number.cpp), and [additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/others/happy_number.cpp).


## One hundred fourteenth reviewed benchmark algorithm: Automorphic number

The pinned C#, Java, JavaScript, and Python sources check whether a number's square ends in the number's decimal digits. Their domains differ, and the Java `long` variant can overflow while squaring larger inputs. The shared contract accepts all signed 64-bit inputs, returns `0` for negatives, and checks the full nonnegative range including zero. The nine portable ports use repeated-doubling modular multiplication with modulus `10^digits`, avoiding dependence on 128-bit arithmetic or architecture-specific instructions. All passed 100,556 arbitrary-precision oracle inputs per language, including every value from -32 through 100,000, deterministic random values, large known examples and neighbors, and signed boundaries, plus 18 workload records. See [the automorphic-number guide](benchmarks/a/automorphic_number/README.md). Upstream references: [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/AutomorphicNumber.cs), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/AutomorphicNumber.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/AutomorphicNumber.js), and [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/automorphic_number.py).


## One hundred fifteenth reviewed benchmark algorithm: Postfix evaluation

The pinned C source accepts decimal token strings and supports an additional remainder operator with narrow integer storage; C++ uses floating-point values; Python also supports exponentiation, unary operators, and empty-input behavior; Rust uses integer values and four binary operators. The shared contract standardizes an integer token-pair encoding and the common addition, subtraction, multiplication, and division operations, with truncation toward zero. It bounds operand and result ranges, defines stack underflow, leftover operands, division by zero, and malformed tokens as an explicit invalid sentinel. All nine portable ports passed 20,627 oracle inputs per language, including exhaustive short token streams, random valid expressions, malformed cases, arithmetic bounds, and the maximum stack workload, plus 20 workload records. See [the postfix-evaluation guide](benchmarks/p/postfix_evaluation/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/misc/postfix_evaluation.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/postfix_evaluation.cpp), [additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/others/postfix_evaluation.cpp), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/postfix_evaluation.py), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/postfix_evaluation.rs).


## One hundred sixteenth reviewed benchmark algorithm: Stack

The pinned inventory finds stack implementations in 12 repositories. The APIs share push, pop, peek/top, and empty checks, but the storage differs: TheAlgorithms' C sources include dynamic-array and linked-list stacks, C++ uses a linked representation, Elixir uses a list, and Zig uses a linked stack. The benchmark defines a bounded, array-backed operation-trace contract with explicit handling for invalid operations, underflow, overflow, and a checksum that preserves the order of observed results and remaining contents. All nine portable implementations passed 10,608 oracle traces per language and recorded all 20 workload cases. See [the stack guide](benchmarks/s/stack/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/stack.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/stack.hpp), [Elixir](https://github.com/TheAlgorithms/Elixir/blob/6212e7e905ec2d2687e7f6e9e4b07b7fabb40f19/lib/data_structures/stack.ex), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/stacks/Stack.java), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/stack.py), and [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/dataStructures/stack.zig).


## One hundred seventeenth reviewed benchmark algorithm: Queue

The pinned queue candidates use linked lists, circular arrays, and dynamic arrays; the Ruby file demonstrates standard-library queues, and TypeScript provides an interface. The six `circular_queue` sources all implement bounded FIFO rings and alias this contract, which already exercises a full-buffer wraparound trace. The shared contract standardizes FIFO enqueue/dequeue plus front and rear peeks, emptiness, and size over a bounded ring buffer. It defines explicit underflow, overflow, and malformed-input behavior. All nine portable implementations passed 38,730 oracle traces per language and recorded all 20 workload cases, including a full-capacity wraparound trace. See [the queue guide](benchmarks/q/queue/README.md). Upstream references: [C graph queue](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/graphs/queue.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/queue.hpp), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/queues/Queue.java), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/queue.rs), and [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/dataStructures/queue.zig).


## One hundred eighteenth reviewed benchmark algorithm: Queue using two stacks

The pinned Java implementation transfers from an input stack to an output stack only when the front is needed; the two pinned C++ copies eagerly reverse elements on each enqueue. The benchmark explicitly selects the amortized lazy-transfer strategy and defines the same bounded FIFO operations and results across all nine target languages. All nine implementations passed 20,508 oracle traces and recorded 20 workload cases each. See [the queue-using-two-stacks guide](benchmarks/q/queue_using_two_stacks/README.md). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/queue_using_two_stacks.cpp), [additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/queue_using_two_stacks.cpp), and [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/QueueUsingTwoStacks.java).

## One hundred nineteenth reviewed benchmark algorithm: Doubly linked list

The pinned inventory finds doubly linked list implementations in 14 repositories. They share a bidirectional linked structure, but expose different combinations of positional insertion/deletion, operations at either end, removal by value, search, reversal, and size. The benchmark normalizes common list operations to append, prepend, pop from either end, remove the first matching value, contains, and length. It uses a bounded index-based node pool with a free list to keep the representation portable across all nine target languages. All nine implementations passed 4,902 oracle traces and recorded 21 workload cases each. See [the doubly linked list guide](benchmarks/d/doubly_linked_list/README.md). The pinned Python `doubly_linked_list_two` source maps to this shared contract for append, first-match removal, membership, and traversal; its one-based positional insertion and missing-value exception are outside the normalized operation trace. Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/linked_list/doubly_linked_list.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/doubly_linked_list.cpp), [C++ additional repository](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/doubly_linked_list.cpp), [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/LinkedList/DoublyLinkedList/DoublyLinkedList.cs), [Elixir](https://github.com/TheAlgorithms/Elixir/blob/6212e7e905ec2d2687e7f6e9e4b07b7fabb40f19/lib/data_structures/doubly_linked_list.ex), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/DoublyLinkedList.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Linked-List/DoublyLinkedList.js), [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/DoublyLinkedList.php), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/doubly_linked_list.py), [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/linked_list_algorithms/doubly_linked_list.r), [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/linked_lists/doubly_linked_list.rb), [Swift](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/data_structures/doubly_linked_list/DoublyLinkedList.swift), [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/list/doubly_linked_list.ts), [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/dataStructures/doublyLinkedList.zig).

## One hundred twentieth reviewed benchmark algorithm: Linked list

The pinned `linked_list` sources include singly linked lists, doubly linked lists, and an interface; the `singly_linked_list` candidate includes nine additional repositories. Their APIs range from head and tail insertion and deletion to indexed access, search, and reversal. The canonical benchmark standardizes a shared operation trace over a bounded singly linked node pool; removing the tail walks the forward links to find its predecessor. `singly_linked_list` aliases this contract to share one workload. C LeetCode candidate 206 adds opcode 7 for in-place pointer reversal. All nine portable implementations passed 5,659 oracle traces each and recorded 27 workload cases. See [the linked list guide](benchmarks/l/linked_list/README.md). Upstream references cover each of the 19 pinned source files: [C-Plus-Plus](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/linked_list.cpp), [C++ additional repository](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/linked_list.cpp), [Clojure](https://github.com/TheAlgorithms/Clojure/blob/a9c5bec14928cb22fd4d69e951edf5bd15e16a18/src/data_structures/lists/linked_list.clj), [Dart](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/data_structures/linked_list/linked_list.dart), [Julia](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/data_structures/linked_list.jl), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/linked_list.rs), [Swift](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/data_structures/Linked%20List/LinkedList.swift), [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/list/linked_list.ts), [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/dataStructures/linkedList.zig), [C LeetCode 206](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/206.c), [C-Sharp](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/LinkedList/SinglyLinkedList/SinglyLinkedList.cs), [Elixir](https://github.com/TheAlgorithms/Elixir/blob/6212e7e905ec2d2687e7f6e9e4b07b7fabb40f19/lib/data_structures/singly_linked_list.ex), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/SinglyLinkedList.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Linked-List/SinglyLinkedList.js), [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/SinglyLinkedList.php), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/singly_linked_list.py), [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/linked_list_algorithms/singly_linked_list.r), [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/linked_lists/singly_linked_list.rb), [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/list/singly_linked_list.ts).

## One hundred twenty-first reviewed benchmark algorithm: Binary search tree

The pinned sources implement ordered insertion, search, deletion, extrema, and traversal, but duplicate handling and deletion details vary. The benchmark chooses unique-key set semantics, where duplicate insertion returns zero without changing the tree, and uses an in-order predecessor when deleting a key with two children. All nine portable implementations passed 3,173 oracle traces and recorded 21 workload cases each. See [the binary search tree guide](benchmarks/b/binary_search_tree/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/binary_trees/binary_search_tree.c), [C-Plus-Plus](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/binary_search_tree.cpp), [C++ additional repository](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/binary_search_tree.cpp), [C-Sharp](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/BinarySearchTree/BinarySearchTree.cs), [Haskell](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/BinaryTree/BinarySearchTree.hs), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Tree/BinarySearchTree.js), [Lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/sorted_set/binary_search_tree.lua), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/binary_search_tree.py), [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/data_structures/binary_search_tree.r), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/binary_search_tree.rs), [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/tree/binary_search_tree.ts), [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/search/binarySearchTree.zig).


## One hundred twenty-second reviewed benchmark algorithm: Trie

The 11 pinned sources share prefix-tree storage and exact-word lookup, but vary in alphabet handling, duplicate insertion, deletion, prefix operations, and multiplicity. The benchmark standardizes lowercase ASCII words and unique-word set semantics, with insert, delete, exact search, prefix presence, prefix count, and total size operations. It supports empty words and prefix queries, and bounds inputs to 1,024 values and words to 128 characters. All nine portable implementations passed 3,435 oracle traces per language and recorded all 23 workload cases. See [the trie guide](benchmarks/t/trie/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/trie/trie.c), [C-Sharp](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Tries/Trie.cs), [F-Sharp](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/DataStructures/Trie.fs), [Go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/structure/trie/trie.go), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/Trie.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Tree/Trie.js), [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/Trie/Trie.php), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/trie/trie.py), [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/tries/trie.rb), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/trie.rs), and [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/dataStructures/trie.zig).


## One hundred twenty-third reviewed benchmark algorithm: Fractional knapsack

The pinned C++ copies, Java, Lua, two Python files, and Rust sources rank items by value-to-weight ratio and allow taking a fraction of an item. The generic knapsack filename group is mixed: its Go, Java, Python, Ruby, Rust, Solidity, TypeScript, and Zig sources cover 0/1 knapsack, the two C++ files implement fractional knapsack, and Python also offers an optional unbounded mode. The catalog aliases the generic filename to the existing 0/1 benchmark and cross-lists the C++ files here. This benchmark compares exact integer ratios and returns the optimum scaled by one million, truncated to six decimal places. All nine portable implementations passed 6,793 exact-rational oracle traces per language and recorded all 25 workload cases. The Python `fractional_knapsack_2` filename aliases this benchmark. See [the fractional-knapsack guide](benchmarks/f/fractional_knapsack/README.md). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/greedy_algorithms/knapsack.cpp), [additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/greedy_algorithms/knapsack.cpp), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/greedyalgorithms/FractionalKnapsack.java), [Lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/knapsack/fractional_knapsack.lua), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/greedy_methods/fractional_knapsack.py), [additional Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/greedy_methods/fractional_knapsack_2.py), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/fractional_knapsack.rs).
## One hundred twenty-fourth reviewed benchmark algorithm: Segment tree range queries

The pinned Java `SegmentTree2D.java` candidate maps to [`segment_tree2_d`](benchmarks/s/segment_tree2_d/README.md), a nine-language point-assignment and half-open submatrix-sum trace with the source's power-of-two padding; see the [workload](benchmarks/s/segment_tree2_d/workload.json) and [source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/SegmentTree2D.java). The pinned C# `SegmentTreeApply` candidate maps to [`segment_tree_apply`](benchmarks/s/segment_tree_apply/README.md), a bounded inclusive range-multiply and range-sum trace that preserves the source's lazy multiplier propagation; see the [workload](benchmarks/s/segment_tree_apply/workload.json) and [source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/SegmentTrees/SegmentTreeApply.cs).
The nine pinned sources implement segment trees for associative range aggregation, with different examples using sums, minima, maxima, or caller-selected operations. C++ and JavaScript use sums; C and Rust demonstrate min or generic operations; Lua and PHP accept a selected combine operation; Python demonstrates range assignment and maximum queries. C# provides the sum query structure, and Java supports point assignments and sum queries. The shared benchmark standardizes point assignment and inclusive range queries for sum, minimum, or maximum, with one aggregate mode per trace. Nine portable implementations passed 23,474 direct-array oracle traces per language and recorded all 28 workload cases. See [the segment-tree guide](benchmarks/s/segment_tree/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/binary_trees/segment_tree.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/segment_tree.cpp), [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/SegmentTrees/SegmentTree.cs), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/SegmentTree.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Tree/SegmentTree.js), [Lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/segment_tree.lua), [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/SegmentTree/SegmentTree.php), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/segment_tree.py), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/segment_tree.rs).

## One hundred twenty-fifth reviewed benchmark algorithm: Pascal triangle

The seven pinned sources generate the first N rows of Pascal’s triangle. The C++ copies print a centered layout; Java, JavaScript, Python, R, and Rust construct row values, with Rust using 32-bit integers. The shared benchmark hashes every coefficient in row-major order and limits the triangle to 30 rows, which keeps all coefficients and the Rust recurrence’s intermediate products within signed 32-bit range. Nine portable implementations passed 322 exact-binomial oracle traces per language and recorded all 14 workload cases. See [the Pascal-triangle guide](benchmarks/p/pascal_triangle/README.md). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/pascal_triangle.cpp), [additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/others/pascal_triangle.cpp), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PascalTriangle.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/PascalTriangle.js), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/pascal_triangle.py), [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/mathematics/pascal_triangle.r), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/pascal_triangle.rs).

## One hundred twenty-sixth reviewed benchmark algorithm: Union-find

The pinned `union_find`, `disjoint_set`, `disjoint_set_union`, and Python `alternate_disjoint_set` sources track the same partitioning algorithm. Their APIs use zero-based or one-based indices, arbitrary payloads, or explicit nodes; their merge heuristics use path compression, path halving, union by rank, union by size, or member-list merging. The benchmark standardizes a bounded zero-based integer universe with union, connectivity, and component-count operations, then checks the final partition without relying on representative IDs. All nine portable implementations passed 9,381 exhaustive, randomized, malformed, and boundary traces per language and recorded all 10 workload cases. `disjoint_set` and `disjoint_set_union` alias this shared benchmark contract. See [the union-find guide](benchmarks/u/union_find/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/misc/union_find.c), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/UnionFind.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Search/UnionFind.js), [Lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/union_find.lua), [Rust union-find](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/union_find.rs), [Swift](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/data_structures/union_find/union_find.swift), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/disjoint_set.cpp), [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/DisjointSet/DisjointSet.cs), [Julia](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/data_structures/disjoint_set/disjoint_set.jl), [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/DisjointSets/DisjointSet.php), [Python alternate](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/disjoint_set/alternate_disjoint_set.py), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/disjoint_set/disjoint_set.py), [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/disjoint_set/disjoint_set.ts), [Java disjoint-set union](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/disjointsetunion/DisjointSetUnion.java), and [Rust disjoint-set union](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/disjoint_set_union.rs).

## One hundred twenty-seventh reviewed benchmark algorithm: Fenwick tree

The seven pinned sources in C++ (two repositories), Java, JavaScript, Julia, Python, and Rust share point additions and prefix or range sums. Public indexing and range boundaries differ, and Python also supports point assignment. The benchmark standardizes zero-based point additions and inclusive range queries. All nine portable implementations passed 5,818 exhaustive, randomized, malformed, and boundary traces per language and recorded all 10 workload cases. See [the Fenwick-tree guide](benchmarks/f/fenwick_tree/README.md). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/range_queries/fenwick_tree.cpp), [additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/range_queries/fenwick_tree.cpp), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/FenwickTree.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Trees/FenwickTree.js), [Julia](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/data_structures/fenwick_tree.jl), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/fenwick_tree.py), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/fenwick_tree.rs).

## One hundred twenty-eighth reviewed benchmark algorithm: Ceiling

The eight pinned sources in C-Sharp, Java, Julia, Mojo, Python, Ruby, Rust, and Zig aim to compute the mathematical ceiling function, but their numeric domains and conversion behavior differ. The benchmark standardizes batches of exact rational values with bounded signed numerators and positive denominators, avoiding floating-point rounding and narrow integer conversions. All nine portable implementations passed 1,928 exhaustive, randomized, malformed, and boundary inputs per language and recorded all 11 workload cases. See [the ceiling guide](benchmarks/c/ceil/README.md). Upstream references: [C-Sharp](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/Ceil.cs), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Ceil.java), [Julia](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/ceil.jl), [Mojo](https://github.com/TheAlgorithms/Mojo/blob/de31759cab02892cb7ccc7767d97fc000b10fcae/maths/ceil.mojo), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/ceil.py), [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/ceil.rb), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/ceil.rs), and [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/math/ceil.zig).


## One hundred twenty-ninth reviewed benchmark algorithm: Area of a polygon

The pinned Rust source uses the shoelace formula over ordered vertices and wraps the last vertex to the first. The shared benchmark keeps the computation exact for bounded integer coordinates and reports twice the area, including the source algorithm’s absolute algebraic result for self-intersecting boundaries. All nine portable implementations passed 16,885 oracle cases per language and recorded 11 workload cases. See [the area-of-a-polygon guide](benchmarks/a/area_of_polygon/README.md). Upstream reference: [Rust `area_of_polygon.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/area_of_polygon.rs).


## One hundred thirtieth reviewed benchmark algorithm: Minimum absolute magnitude

Dart, F-Sharp, and Scala select the first sequence value with the least absolute magnitude. Python defines the same `abs_min` operation inside `maths/abs.py`, discovered while reviewing the filename candidates. The Ruby file named `abs_min.rb` computes the ordinary numeric minimum and does not match this magnitude-based contract. All nine portable implementations passed 4,124 oracle arrays per language and recorded eight workload cases. See [the minimum-magnitude guide](benchmarks/a/abs_min/README.md). Upstream references: [Dart](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/abs_min.dart), [F-Sharp](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Math/AbsMin.fs), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/abs.py), [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/abs_min.rb), and [Scala](https://github.com/TheAlgorithms/Scala/blob/de555349d5effb87962d3116eb08c9f374065112/src/main/scala/Mathematics/AbsMin.scala).

## One hundred thirty-first reviewed benchmark algorithm: Maximum absolute magnitude

Dart, F-Sharp, and Scala select the first sequence value with the greatest absolute magnitude. Python defines the same `abs_max` operation inside `maths/abs.py`. The Ruby file named `abs_max.rb` computes the ordinary numeric maximum and does not match this magnitude-based contract. All nine portable implementations passed 4,123 oracle arrays per language and recorded eight workload cases. See [the maximum-magnitude guide](benchmarks/a/abs_max/README.md). Upstream references: [Dart](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/abs_max.dart), [F-Sharp](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Math/AbsMax.fs), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/abs.py), [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/abs_max.rb), and [Scala](https://github.com/TheAlgorithms/Scala/blob/de555349d5effb87962d3116eb08c9f374065112/src/main/scala/Mathematics/AbsMax.scala).

## One hundred thirty-second reviewed benchmark algorithm: Shape area and surface area

The eight pinned source files collect overlapping plane-area and solid-surface-area formulas. This shared contract covers 22 shape formulas and reports fixed-point milli-square-units using bounded integer dimensions, integer square roots, and fixed π constants. Polygon shoelace area remains a separate algorithm. All nine portable implementations passed 9,082 oracle arrays per language and recorded 13 workload cases each. See [the shape-area guide](benchmarks/a/area/README.md). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/area.cpp), [additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/area.cpp), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Area.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/Area.js), [Julia](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/area.jl), [Kotlin](https://github.com/TheAlgorithms/Kotlin/blob/b913c1d85c972fd1e679c5d832d6458b21be8fb0/src/main/kotlin/math/Area.kt), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/area.py), and [Solidity](https://github.com/TheAlgorithms/Solidity/blob/08cba51fb38e276062b0c9791d7e0ee494ffa903/src/Maths/Area.sol).

## One hundred thirty-third reviewed benchmark algorithm: Abundant number

The pinned Java and Python sources determine whether the sum of positive proper divisors exceeds the input. The shared contract covers positive values through 1,000,000,000 and returns a portable sentinel outside that range. All nine implementations passed 10,148 oracle cases per language and recorded 13 workload cases each. See [the abundant-number guide](benchmarks/a/abundant_number/README.md). Upstream references: [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/AbundantNumber.java) and [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/abundant_numbers.py).

## One hundred thirty-fourth reviewed benchmark algorithm: Absolute maximum with signed tie-break

The pinned Java source selects the value with greatest magnitude and chooses the greater signed value when magnitudes tie. The PHP file with the same name returns the ordinary numeric maximum, so it is documented as a semantic mismatch. All nine portable implementations passed 4,120 oracle arrays per language and recorded nine workload cases each. See [the signed-tie absolute-maximum guide](benchmarks/a/absolute_max/README.md). Upstream references: [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/AbsoluteMax.java) and [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/AbsoluteMax.php).

## One hundred thirty-fifth reviewed benchmark algorithm: Absolute minimum with signed tie-break

The pinned Java source selects the value with least magnitude and chooses the smaller signed value when magnitudes tie. The PHP file with the same name returns the ordinary numeric minimum, so it is documented as a semantic mismatch. All nine portable implementations passed 4,120 oracle arrays per language and recorded nine workload cases each. See [the signed-tie absolute-minimum guide](benchmarks/a/absolute_min/README.md). Upstream references: [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/AbsoluteMin.java) and [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/AbsoluteMin.php).

## One hundred thirty-sixth reviewed benchmark algorithm: Recursive 0/1 knapsack

The pinned Dart source uses direct recursion to include or exclude each item, without memoization. The benchmark stays separate from the bottom-up tabulation variant so their runtime and call-stack behavior can be compared. Its item limit bounds recursion to at most 2^16 leaves. All nine portable implementations passed 5,874 oracle cases per language and recorded 16 workload cases each. See [the recursive 0/1 knapsack guide](benchmarks/0-9/01knapsack_recursive/README.md). Upstream reference: [Dart `01knapsack_recursive.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/dynamic_programming/01knapsack_recursive.dart).

## One hundred thirty-seventh reviewed benchmark algorithm: Regular expression matching

The pinned C LeetCode source, Python recursive matcher, and C# WildCardMatcher implement full-string matching for lowercase text with `.` and `*` applied to the preceding atom. The Python file also contains a dynamic-programming version, while this benchmark measures direct recursion. The Java file named `RegexMatching` uses `?` and `*` wildcard semantics and maps to the separate `wildcard_matching` contract. Python `wildcard_pattern_matching` uses the `.` and preceding-atom `*` grammar and aliases this regular-expression contract. All nine portable implementations passed 48,463 oracle inputs per language and recorded 24 workload cases each. See [the regular-expression matching guide](benchmarks/r/regex_match/README.md). Upstream references: [C LeetCode `10.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/10.c) and [Python `regex_match.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/regex_match.py).

## One hundred thirty-eighth reviewed benchmark algorithm: Single number by XOR

The pinned C LeetCode source reduces signed 32-bit values with XOR. The Ruby source implements the same single-value problem with a frequency map and an O(n²) counting alternative; this benchmark selects the XOR method. All nine portable implementations passed 20,060 bit-vector oracle inputs per language and recorded 16 workload cases each. See [the single-number guide](benchmarks/s/single_number/README.md). Upstream references: [C LeetCode `136.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/136.c) and [Ruby `single_number.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/single_number.rb).

## One hundred thirty-ninth reviewed benchmark algorithm: Best time to buy and sell stock

The pinned C, Python, and Java sources compute the maximum profit from one buy followed by one later sale. C applies Kadane's recurrence to adjacent price differences, while Python and Java track the minimum price. The benchmark sets shared price and array bounds and defines empty input as zero. All nine portable implementations passed 3,810 oracle inputs per language and recorded 16 workload cases each. See [the stock-profit guide](benchmarks/b/best_time_to_buy_and_sell_stock/README.md). Upstream references: [C LeetCode `121.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/121.c), [Python `best_time_to_buy_and_sell_stock.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/greedy_methods/best_time_to_buy_and_sell_stock.py), and [Java `StockProfitCalculator.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/greedyalgorithms/StockProfitCalculator.java).
## One hundred fortieth reviewed benchmark algorithm: Palindrome number

The pinned C source reverses half the digits, while Dart and Java reverse the full number for nonnegative inputs. The shared contract is bounded to nonnegative signed 32-bit values, and all nine portable implementations use half reversal to avoid intermediate overflow. All nine passed 100,538 oracle inputs per language and recorded 18 workload cases each. See [the palindrome-number guide](benchmarks/p/palindrome_number/README.md). Upstream references: [C LeetCode `9.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/9.c), [Dart `palindrome_number.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/palindrome_number.dart), and [Java `PalindromeNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PalindromeNumber.java).

## One hundred forty-first reviewed benchmark algorithm: Power of four

The pinned Java source checks that a signed 32-bit integer is positive, has one set bit, and places that bit at an even position. All nine portable implementations passed 11,571 scalar oracle inputs per language and recorded 19 workload cases each. See [the power-of-four guide](benchmarks/p/power_of_four/README.md). Upstream reference: [Java `PowerOfFour.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PowerOfFour.java).

## One hundred forty-second reviewed benchmark algorithm: ROT13

The benchmark applies the standard case-preserving ROT13 mapping to non-NUL 7-bit ASCII, leaving punctuation, digits, and other ASCII values unchanged. The pinned Rust `rot13` implementation uppercases input; the Rust `another_rot13` implementation preserves case and is recorded as an alias. The lowercase-only `theoretical_rot13` variant has [its own benchmark](benchmarks/t/theoretical_rot13/README.md). All nine ports of both ROT13 variants passed 16,758 oracle inputs per language and recorded 10 workload cases each. See [the ROT13 guide](benchmarks/r/rot13/README.md) and [workload](benchmarks/r/rot13/workload.json). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/cipher/rot13.c), [Go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/cipher/rot13/rot13.go), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Ciphers/ROT13.js), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/rot13.py), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/rot13.rs), and Rust's [case-preserving alternative](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/another_rot13.rs).

## One hundred forty-third reviewed benchmark algorithm: Lowercase-only ROT13

The pinned Rust `theoretical_rot13` source rotates `a` through `z` by thirteen positions while leaving uppercase ASCII letters and all other characters unchanged. The shared workload uses non-NUL 7-bit ASCII and checks both alphabets, wraparound, punctuation, and invalid values. All nine ports passed 16,758 oracle inputs per language and recorded 10 workload cases each. See [the theoretical ROT13 guide](benchmarks/t/theoretical_rot13/README.md) and [workload](benchmarks/t/theoretical_rot13/workload.json). Upstream reference: [Rust `theoretical_rot13.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/theoretical_rot13.rs).

## One hundred eighty-third reviewed benchmark algorithm: Caesar cipher

The source filename candidates `caesar` and `caesar_cipher` point to variants of the same letter-substitution algorithm. Their upstream implementations disagree on shifts, case handling, and nonletters, so the shared contract accepts any signed 64-bit shift, normalizes it modulo 26, preserves case, and leaves other 7-bit ASCII bytes unchanged. The pinned C# `CaesarEncoder` also maps to this contract for keys in ±1,000,000, within its source integer range. All nine ports passed 2,637 oracle inputs per language and recorded 12 workload cases each. See the [Caesar cipher guide](benchmarks/c/caesar_cipher/README.md) and [workload](benchmarks/c/caesar_cipher/workload.json). Upstream implementations are cataloged for [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/ciphers/caesar_cipher.cpp), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Ciphers/CaesarCipher.js), [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Ciphers/CaesarCipher.php), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/caesar_cipher.py), [Go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/cipher/caesar/caesar.go), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/Caesar.java), [Julia](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/cipher/caesar.jl), [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/ciphers/caesar.rb), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/caesar.rs), and [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Encoders/CaesarEncoder.cs).

## One hundred forty-fourth reviewed benchmark algorithm: GCD of N numbers

The pinned C++ and Rust implementations combine pairwise Euclidean GCD, using an iterative fold in C++ and recursive slice reduction in Rust. The Python implementation instead intersects prime-factor counts. The shared contract accepts 1 to 64 positive signed 32-bit values and uses the pairwise Euclidean fold; this keeps zero, negative, and empty-input convention differences outside the comparison. All nine ports passed 2,076 oracle arrays per language and recorded 12 workload cases each. See [the GCD-of-N guide](benchmarks/g/gcd_of_n_numbers/README.md). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/gcd_of_n_numbers.cpp), [additional C++ source](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/gcd_of_n_numbers.cpp), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/gcd_of_n_numbers.py), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/gcd_of_n_numbers.rs).

## One hundred forty-fifth reviewed benchmark algorithm: Fast Fibonacci

The pinned C source uses recursive fast doubling for the zero-based Fibonacci sequence. The similarly named C++ files use a stateful linear recurrence instead, so the benchmark selects the C algorithm and specifies indices `0..=92` to keep every result within signed 64-bit range. All nine portable ports passed 106 oracle inputs per language and recorded 10 workload cases each. See [the fast-Fibonacci guide](benchmarks/f/fibonacci_fast/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/fibonacci_fast.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/fibonacci_fast.cpp), and [additional C++ source](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/fibonacci_fast.cpp).


## One hundred forty-sixth reviewed benchmark algorithm: Recursive insertion sort

The pinned C source recursively sorts each prefix and inserts its last value. The C++ source with the same filename uses iterative insertion sort, so the shared contract follows the recursive C algorithm. The nine portable implementations sort signed 64-bit values in ascending order and cap workload length at 256 to bound recursion depth. All nine passed 5,529 short-array order-pattern, boundary, and deterministic random cases, plus all six workload lengths. See [the recursive-insertion-sort guide](benchmarks/i/insertion_sort_recursive/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/insertion_sort_recursive.c) and [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/insertion_sort_recursive.cpp).


## One hundred forty-seventh reviewed benchmark algorithm: Patience sort

The pinned C, Rust, Java, and Python sources build patience piles and merge their exposed values. The C and Rust implementations scan exposed pile tops during merging, while Java and Python use a heap; their rules for placing equal values also vary. The shared contract uses lower-bound pile placement and a binary min-heap merge, sorts signed 64-bit values in place, and supports empty arrays up to length 1024. All nine portable ports passed 5,529 short-array order-pattern, boundary, and deterministic random cases, plus all six workload lengths. See [the patience-sort guide](benchmarks/p/patience_sort/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/patience_sort.c), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/PatienceSort.java), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/patience_sort.py), [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/sorting_algorithms/patience_sort.r), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/patience_sort.rs).


## One hundred forty-eighth reviewed benchmark algorithm: Swap sort

The pinned C++ source counts permutation cycles to return the minimum number of swaps. The JavaScript and TypeScript sources also aim to count swaps but use default sorting and value maps, while the Java `SwapSort` class sorts the array in place and returns it. The shared contract follows minimum-swap cycle decomposition for distinct signed 64-bit values, returns zero for empty arrays, and rejects duplicates or inputs over 256 values with `-1`. All nine portable implementations passed 1,399 exhaustive, randomized, boundary, and invalid-input arrays per language and recorded all eight workload cases. See [the swap-sort guide](benchmarks/s/swap_sort/README.md). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/swap_sort.cpp), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/SwapSort.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Sorts/SwapSort.js), and [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/sorts/swap_sort.ts).


## One hundred forty-ninth reviewed benchmark algorithm: Slow sort

The pinned C++ and Java sources use the recursive divide, compare, and prefix-sort procedure. The C++ sample passes the array length as an inclusive last index, so the benchmark follows Java's `length - 1` boundary. Inputs are capped at 16 because recursive work grows very quickly. All nine portable implementations passed 5,529 short-array order-pattern, boundary, and deterministic random cases, plus all seven workload lengths. See [the SlowSort guide](benchmarks/s/slow_sort/README.md). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/slow_sort.cpp), [additional C++ source](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/sorting/slow_sort.cpp), and [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/SlowSort.java).

## One hundred fiftieth reviewed benchmark algorithm: Shell sort with the Ciura gap sequence

The pinned C and C++ sources use the fixed gaps `701, 301, 132, 57, 23, 10, 4, 1`, while the existing Shell sort benchmark uses a halving sequence. The shared contract retains the Ciura gaps and compares signed 64-bit values directly, avoiding overflow in the upstream subtraction expression. All nine portable implementations passed 5,529 short-array order-pattern, boundary, and deterministic random cases, plus all six workload lengths. See [the fixed-gap Shell sort guide](benchmarks/s/shell_sort2/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/shell_sort2.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/shell_sort2.cpp), and [additional C++ source](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/sorting/shell_sort2.cpp).


## One hundred fifty-first reviewed benchmark algorithm: Tree sort

The pinned Java, Python, Rust, and TypeScript sources insert values into a binary search tree and traverse it in order. Their duplicate handling differs: Java drops equal keys, while the other implementations retain them with different insertion directions. The shared contract sorts signed 64-bit values in place, retains duplicates by inserting equals into the right subtree, and accepts up to 1024 values. All nine iterative ports passed 5,529 short-array order-pattern, boundary, and deterministic random cases, plus all seven workload lengths. See [the tree-sort guide](benchmarks/t/tree_sort/README.md). Upstream references: [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/TreeSort.java), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/tree_sort.py), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/tree_sort.rs), and [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/sorts/tree_sort.ts).


## One hundred fifty-second reviewed benchmark algorithm: Non-recursive merge sort

The pinned C source uses bottom-up merging but limits its temporary array to 50 integers and mixes interactive I/O into the demo. The shared contract sorts signed 64-bit values in place up to length 1024, with a fixed scratch buffer and no I/O in the timed call. The ports merge equal values from the left; the upstream example selects the right value on ties, which is unobservable for this scalar integer contract. All nine implementations passed 5,529 short-array order-pattern, boundary, and deterministic random cases, plus all six workload lengths. See [the non-recursive merge-sort guide](benchmarks/m/merge_sort_nr/README.md). Upstream reference: [C `merge_sort_nr.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/merge_sort_nr.c).


## One hundred fifty-third reviewed benchmark algorithm: Recursive bubble sort with early exit

The pinned Java and Python sources make one adjacent-swap pass, then recursively process the shorter prefix only when the pass changed the array. Java sorts in place; Python builds the recursive result from a slice. The shared contract sorts signed 64-bit values in place up to length 256. Its early exit makes it distinct from `recursive_bubble_sort`, which recurses after every pass. All nine implementations passed 5,529 short-array order-pattern, boundary, and deterministic random cases, plus all six workload lengths. See [the recursive bubble-sort guide](benchmarks/b/bubble_sort_recursive/README.md). Upstream references: [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/BubbleSortRecursive.java) and [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/bubble_sort_recursive.py).


## One hundred fifty-fourth reviewed benchmark algorithm: Cocktail selection sort

The two pinned C++ copies scan the active range for a minimum and maximum, place them at opposite ends, and repeat on the smaller range. Their endpoint-swap logic can misplace values when the maximum starts at the low endpoint because it reuses the maximum's old index after moving the minimum. The shared contract corrects that index update and sorts signed 64-bit values in place up to length 1024. All nine ports passed 5,529 short-array order-pattern, duplicate, boundary, and deterministic random cases, plus all seven workload lengths. See [the cocktail-selection-sort guide](benchmarks/c/cocktail_selection_sort/README.md). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/cocktail_selection_sort.cpp) and [additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/sorting/cocktail_selection_sort.cpp).


## One hundred fifty-fifth reviewed benchmark algorithm: Heap sort with top-down heap construction

The pinned C source builds a max heap by inserting values one at a time with sift-up, then extracts each maximum with sift-down. This construction strategy is distinct from the existing bottom-up `heap_sort` benchmark. The source limits values to `int8_t` and uses an 8-bit length in its random demo; the shared contract sorts signed 64-bit values in place up to length 1024. All nine ports passed 5,529 short-array order-pattern, duplicate, boundary, and deterministic random cases, plus all seven workload lengths. See [the heap-sort-2 guide](benchmarks/h/heap_sort_2/README.md). Upstream reference: [C `heap_sort_2.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/heap_sort_2.c).


## One hundred fifty-sixth reviewed benchmark algorithm: Recursive top-down merge sort

The pinned C-Sharp `MergeSorter` recursively splits the input, sorts both halves, and merges them while taking equal values from the left half first. It allocates split arrays at each recursive call; the shared contract keeps the top-down recursion and stable ordering while using one fixed scratch array per sort call. Inputs are signed 64-bit values capped at length 1024. All nine ports passed 5,529 short-array order-pattern, duplicate, boundary, and deterministic random cases, plus all seven workload lengths. See [the recursive merge-sort guide](benchmarks/m/merge_sorter/README.md). Upstream reference: [C-Sharp `MergeSorter.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sorters/Comparison/MergeSorter.cs). The pinned Java `ConcurrentMergeSort` candidate shares its stable output contract and is mapped to this benchmark; its Java-specific task scheduling is outside the cross-language workload.


## One hundred fifty-seventh reviewed benchmark algorithm: Merge-insertion sort

The pinned Python source orders adjacent pairs, merge-sorts the pairs by their lower values, then builds the sorted result by binary-inserting the upper values and any odd leftover. The two C++ copies describe a merge/insertion hybrid, but their demo runs only insertion sort and leaves the hybrid call commented out. The shared contract follows the Python pair-and-insert method and uses full-chain lower-bound insertion for duplicates. It sorts signed 64-bit values in place up to length 256. All nine implementations passed 5,529 short-array order-pattern, duplicate, boundary, and deterministic random cases, plus all eight workload lengths. See [the merge-insertion-sort guide](benchmarks/m/merge_insertion_sort/README.md). Upstream references: [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/merge_insertion_sort.py), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/merge_insertion_sort.cpp), and [additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/sorting/merge_insertion_sort.cpp).


## One hundred fifty-eighth reviewed benchmark algorithm: Bingo sort

The pinned Rust source groups each occurrence of the current minimum value at the front and advances through the numeric range. The shared contract preserves that grouping strategy while scanning for the next value present, so work does not grow with empty gaps and signed 64-bit boundaries are supported. Inputs are capped at 1024 values. All nine ports passed 5,529 short-array order-pattern, duplicate, boundary, and deterministic random cases, plus all seven workload lengths. See [the Bingo-sort guide](benchmarks/b/bingo_sort/README.md). Upstream reference: [Rust `bingo_sort.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/bingo_sort.rs).


## One hundred fifty-ninth reviewed benchmark algorithm: Most-significant-bit radix sort

The pinned Python source includes an in-place binary radix sort that partitions from the most-significant bit downward; this differs from the least-significant-digit passes in `radix_sort`. The shared contract extends its nonnegative input domain to signed 64-bit integers by mapping signed order to unsigned bit order. All nine portable ports passed 5,529 short-array order and duplicate patterns, signed boundaries, deterministic random cases, and all four workload lengths. See [the MSD-radix-sort guide](benchmarks/m/msd_radix_sort/README.md). Upstream reference: [Python `msd_radix_sort.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/msd_radix_sort.py).


## One hundred sixtieth reviewed benchmark algorithm: Three-way quicksort

The two pinned C++ files are identical and use Dutch-national-flag partitioning around the final value in each range. The shared implementations retain that three-way partition while recursing into the smaller outer partition to bound stack depth. The Rust `quick_sort_3_ways` filename uses the same partition family with a randomized pivot and is recorded as an alias. All nine ports passed 5,529 short-array order and duplicate patterns, signed boundaries, deterministic random cases, and all four workload lengths. See [the three-way-quicksort guide](benchmarks/q/quick_sort_3/README.md). Upstream references: [C++ `quick_sort_3.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/quick_sort_3.cpp), [additional identical C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/sorting/quick_sort_3.cpp), and [Rust `quick_sort_3_ways.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/quick_sort_3_ways.rs).


## One hundred sixty-first reviewed benchmark algorithm: Dual-pivot quicksort

The pinned Java source uses the first and final range values as ordered pivots, partitions values into lower, middle, and upper regions, and recurses on all three. The shared contract preserves that two-pivot partition while tracking the final pivot positions explicitly and recursing into the smaller regions to bound stack depth. All nine ports passed 5,529 short-array order and duplicate patterns, signed boundaries, deterministic random cases, and all four workload lengths. See [the dual-pivot-quicksort guide](benchmarks/d/dual_pivot_quick_sort/README.md). Upstream reference: [Java `DualPivotQuickSort.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/DualPivotQuickSort.java).

## One hundred sixty-second reviewed benchmark algorithm: Iterative quicksort

The pinned C++ source uses Lomuto partitioning around the final value and stores pending index ranges on an explicit stack. The nine portable ports retain iterative traversal and final-value pivots; they process the smaller side immediately and push the larger side to bound stack space. All nine passed 5,529 short-array order and duplicate patterns, signed boundaries, deterministic random cases, and all four workload lengths. See [the iterative-quicksort guide](benchmarks/q/quick_sort_iterative/README.md). Upstream reference: [C++ `quick_sort_iterative.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/quick_sort_iterative.cpp).

## One hundred sixty-third reviewed benchmark algorithm: Reverse selection sort

The pinned Python source finds the minimum in each remaining suffix and reverses the prefix through that value to place it. This differs from standard selection sort, which swaps the selected value directly into place. All nine ports use the in-place signed 64-bit contract and passed 5,529 short-array order and duplicate patterns, signed boundaries, deterministic random cases, and all four workload lengths. See [the reverse-selection guide](benchmarks/r/reverse_selection/README.md). Upstream reference: [Python `reverse_selection.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/reverse_selection.py).

## One hundred sixty-fourth reviewed benchmark algorithm: Random-pivot quicksort

The pinned C++ sources select a random pivot from each range, move it to the end, and apply strict-less Lomuto partitioning. The nine ports use the same partition policy with a fixed-seed portable pseudorandom stream and an explicit stack that processes smaller partitions first. All nine passed 5,529 short-array order and duplicate patterns, signed boundaries, deterministic random cases, and all four workload lengths. See [the random-pivot-quicksort guide](benchmarks/r/random_pivot_quick_sort/README.md). Upstream references: [C++ `random_pivot_quick_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/random_pivot_quick_sort.cpp), [C `random_quick_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/random_quick_sort.c), and [Java `RandomizedQuickSort.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/randomized/RandomizedQuickSort.java).

## One hundred sixty-fifth reviewed benchmark algorithm: Quickselect

The pinned Python implementation selects a random pivot and recursively partitions values into less, equal, and greater lists; JavaScript and TypeScript partition the input array in place, while Java uses a median-of-medians pivot. The shared contract selects the upper median at zero-based rank `floor(length / 2)`. The nine portable implementations use a deterministic median-of-three pivot and three-way partition on a bounded local copy to match the read-only array-scalar ABI. See [the quickselect guide](benchmarks/q/quick_select/README.md). Upstream references: [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/searches/quick_select.py), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Array/QuickSelect.js), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/QuickSelect.java), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a4c939ec5163648458a8c2b46fd4c/src/searching/quick_select.rs), and [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/sorts/quick_select.ts).

## One hundred sixty-sixth reviewed benchmark algorithm: Matrix-chain multiplication

The pinned C++ sources use a memoized top-down recurrence with a small fixed dimension table. Python provides a bottom-up table and a cached recursive variant. The shared contract uses bottom-up dynamic programming over at most 64 matrices and dimensions from 1 through 1,000, keeping costs within signed 64-bit range. See [the matrix-chain-multiplication guide](benchmarks/m/matrix_chain_multiplication/README.md). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/matrix_chain_multiplication.cpp), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/MatrixChainMultiplication.java), [Kotlin](https://github.com/TheAlgorithms/Kotlin/blob/b913c1d85c972fd1e679c5d832d6458b21be8fb0/src/main/kotlin/dynamicProgramming/MatrixChainMultiplication.kt), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/matrix_chain_multiplication.py), and [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/dynamic_programming/matrix_chain_multiplication.r).

## One hundred sixty-seventh reviewed benchmark algorithm: Chinese remainder theorem

The inspected C#, Java, Rust, and Zig implementations solve systems with pairwise-coprime moduli; the Python source lacks a coprimality check and includes a non-coprime example whose returned value does not satisfy the input congruences. The shared contract accepts one to four valid pairwise-coprime congruences and uses incremental extended-Euclid modular inverses to return the least nonnegative solution. See [the Chinese-remainder-theorem guide](benchmarks/c/chinese_remainder_theorem/README.md). Upstream references: [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/ModularArithmetic/ChineseRemainderTheorem.cs), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/ChineseRemainderTheorem.java), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/chinese_remainder_theorem.py), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a4c939ec5163648458a8c2b46fd4c/src/math/chinese_remainder_theorem.rs), and [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/math/chineseRemainderTheorem.zig).

## One hundred sixty-eighth reviewed benchmark algorithm: Longest palindromic subsequence

The pinned Python and JavaScript implementations compute the LPS length with dynamic programming. C++ computes an LCS with the reversed input and reconstructs a subsequence; R also reconstructs one result, while Java recursively constructs strings. The shared contract returns the length and uses bottom-up interval DP over signed 64-bit symbols. See [the LPS guide](benchmarks/l/longest_palindromic_subsequence/README.md). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/longest_palindromic_subsequence.cpp), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/LongestPalindromicSubsequence.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/LongestPalindromicSubsequence.js), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/longest_palindromic_subsequence.py), and [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/string_manipulation/longest.palindromic.subsequence.r).

## One hundred sixty-ninth reviewed benchmark algorithm: Square root by Newton's method

The pinned JavaScript source uses four fixed Newton iterations; Python, Ruby, and TypeScript iterate to a tolerance. The shared contract uses finite nonnegative binary64 inputs through `1e300`, a portable initial estimate, and a fixed Newton recurrence with relative output tolerance. Four pinned source files were inspected; the cataloged Rust path does not resolve at its pinned revision. See [the square-root guide](benchmarks/s/square_root/README.md). Upstream references: [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/SquareRoot.js), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/numerical_analysis/square_root.py), [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/square_root.rb), and [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/square_root.ts).

## One hundred seventieth reviewed benchmark algorithm: Square root by binary search

The pinned Java implementation searches for the integer floor using division rather than squaring the midpoint, avoiding overflow at signed 64-bit boundaries. The JavaScript `SquareRootLogarithmic` candidate uses the same binary-search floor-root method and is recorded as a filename alias. The shared contract returns `-1` for negative input and supports every nonnegative signed 64-bit integer. See [the square-root binary-search guide](benchmarks/s/square_root_binary_search/README.md). Upstream references: [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/SquareRootBinarySearch.java) and [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/SquareRootLogarithmic.js).

## One hundred seventy-first reviewed benchmark algorithm: Minimum number of perfect squares

The pinned Java `SumOfSquares` source implements the minimum number of perfect-square summands: it checks one-square and two-square decompositions, then applies Legendre's three-square theorem. Its zero case returns one; the shared contract corrects that to zero. The nine ports use exact integer arithmetic through the source's nonnegative signed 32-bit domain. See [the minimum-square-summands guide](benchmarks/s/sum_of_squares/README.md). Upstream reference: [Java `SumOfSquares.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/SumOfSquares.java).


## One hundred seventy-second reviewed benchmark algorithm: Abbreviation

The pinned C++, Go, Java, JavaScript, and Python implementations solve the HackerRank abbreviation problem: lowercase source letters can be capitalized or deleted, while uppercase source letters must be retained. The shared contract packs two ASCII letter strings, bounds each at 128 characters, and uses two fixed dynamic-programming rows. All nine portable implementations are represented in the workload guide at [benchmarks/a/abbreviation/README.md](benchmarks/a/abbreviation/README.md). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/abbreviation.cpp), [additional C++ repository](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/dynamic_programming/abbreviation.cpp), [Go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/dynamic/abbreviation.go), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/Abbreviation.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/Abbreviation.js), and [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/abbreviation.py).


## One hundred seventy-third reviewed benchmark algorithm: Gale–Shapley stable matching

The pinned C++, C#, Java, Lua, and Nim sources implement proposer-proposing Gale–Shapley matching. The C# `Accepter` and `Proposer` files are participant state types used by that algorithm, and Python’s `gale_shapley_bigraph` source uses the same strict complete-preference matching semantics; all three filename candidates are recorded as aliases. The shared contract packs two preference matrices for up to five participants per side and returns one accepter ID byte per proposer. All nine implementations passed the 12 published cases, 170 workload and generated oracle inputs, and five output-capacity checks per language. See the [Gale–Shapley guide](benchmarks/g/gale_shapley/README.md) and [repeatable verifier](benchmarks/verify_gale_shapley.py). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/greedy_algorithms/gale_shapley.cpp), [C# GaleShapley](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Problems/StableMarriage/GaleShapley.cs), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/greedyalgorithms/GaleShapley.java), [Lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/misc/stable_marriage/gale_shapley.lua), [Nim](https://github.com/TheAlgorithms/Nim/blob/63eec16614b46c91078653e8d3c049fe99ad36b3/stable_marriage/gale_shapley.nim), and [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/gale_shapley_bigraph.py).


## One hundred seventy-fourth reviewed benchmark algorithm: Tribonacci number

The pinned C LeetCode 1137, Java, and JavaScript sources agree on the zero-based nth Tribonacci recurrence with initial values 0, 1, 1. The C LeetCode filename and JavaScript `tribonacci_number` are aliases of the Java `tribonacci` candidate. The Python file with the same stem produces the first n terms beginning 0, 0, 1, while the C# `TribonacciNumbersSequence` starts 1, 1, 1; these are documented as distinct semantics. The shared contract supports exact signed 64-bit terms through n = 73. See the [Tribonacci guide](benchmarks/t/tribonacci/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1137.c), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/Tribonacci.java), and [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/TribonacciNumber.js).


## One hundred seventy-fifth reviewed benchmark algorithm: Bitwise complement

The pinned C LeetCode 1009 source uses `ceil(log2(n))` to determine a complement mask, and C LeetCode 476 grows the mask through the most significant bit. They implement the same operation for nonnegative signed 32-bit inputs; candidate 476 aliases candidate 1009. The catalog assigns candidate 1009 the alphabetic benchmark name `bitwise_complement`, so the nine portable integer-shift implementations are stored under `b/`. All nine passed 4,627 oracle inputs and 15 workload records through the scalar verifier. See the [bitwise-complement guide](benchmarks/b/bitwise_complement/README.md). Upstream references: [C LeetCode 1009](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1009.c) and [C LeetCode 476](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/476.c).


Additional numeric C candidates were reviewed as filename aliases: `17` maps to [phone letter combinations](benchmarks/l/letter_combinations_of_phone_number/README.md), `69` to [square root by binary search](benchmarks/s/square_root_binary_search/README.md), `118` to [Pascal triangle](benchmarks/p/pascal_triangle/README.md), `367` to [perfect square](benchmarks/p/perfect_square/README.md), `509` to [Fibonacci](benchmarks/f/fibonacci/README.md), and `704` to [binary search](benchmarks/b/binary_search/README.md).


## One hundred seventy-sixth reviewed benchmark algorithm: Maximum subarray with Kadane’s algorithm

The pinned C LeetCode 53, Ruby, Rust, and Python `max_subarray_sum` sources implement the maximum nonempty contiguous-subarray sum with Kadane’s scan. Python `maximum_subsequence` uses the same Kadane recurrence and is also an alias of `maximum_subarray`. The C 53, Python `max_subarray_sum`, and both Go `maxsubarraysum` candidates alias the Rust/Ruby `maximum_subarray` candidate for the shared nonempty input domain; the Go dynamic source panics on empty input while its companion returns zero. The shared contract accepts up to 1,024 signed 32-bit elements and returns the maximum nonempty sum. See the [maximum-subarray guide](benchmarks/m/maximum_subarray/README.md). Upstream references: [C LeetCode 53](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/53.c), [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/maximum_subarray.rb), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/maximum_subarray.rs), and [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/max_subarray_sum.py).

## One hundred seventy-seventh reviewed benchmark algorithm: Maximum subarray by divide and conquer

The pinned Python `max_subarray` source divides the input, recursively solves both halves, and evaluates the best interval crossing the midpoint. Its sum objective matches the nonempty maximum-subarray contract; it remains a separate benchmark because it uses a distinct strategy. See the [divide-and-conquer guide](benchmarks/m/max_subarray/README.md) and [maximum-subarray verifier](benchmarks/verify_maximum_subarray.py). Upstream reference: [Python max_subarray](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/divide_and_conquer/max_subarray.py).


## One hundred seventy-eighth reviewed benchmark algorithm: Lucas number by iteration

The pinned Java, JavaScript, Python, Ruby, Rust, and Solidity source group computes Lucas numbers with index conventions that differ between files. The shared contract uses zero-based indices and exact integer recurrence; Java’s one-based method is normalized, and the Ruby approximation is noted as incorrect for the first two terms. See the [iterative Lucas guide](benchmarks/l/lucas_series/README.md). Upstream references: [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/LucasSeries.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/LucasSeries.js), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/lucas_series.py), [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/lucas_series.rb), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/lucas_series.rs), and [Solidity](https://github.com/TheAlgorithms/Solidity/blob/08cba51fb38e276062b0c9791d7e0ee494ffa903/src/Maths/lucasSeries.sol).

## One hundred seventy-ninth reviewed benchmark algorithm: Lucas number by direct recursion

The same source group includes un-memoized recursive methods in Java, Python, Rust, and Solidity. Those recursive implementations are tracked separately from the linear iterative recurrence and use a bounded index to keep the exponential workload practical. See the [recursive Lucas guide](benchmarks/l/lucas_series_recursive/README.md). Upstream references: [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/LucasSeries.java), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/lucas_series.py), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/lucas_series.rs), and [Solidity](https://github.com/TheAlgorithms/Solidity/blob/08cba51fb38e276062b0c9791d7e0ee494ffa903/src/Maths/lucasSeries.sol).


## One hundred eightieth reviewed benchmark algorithm: Josephus problem by iterative recurrence

The pinned R source iterates the zero-based survivor recurrence, and the Java and Python sources state the same recurrence recursively. The shared contract accepts up to 100,000 participants and a positive signed 64-bit step, returning the one-based survivor. The step is reduced modulo each circle size before addition to avoid overflow. See the [iterative Josephus guide](benchmarks/j/josephus_problem/README.md) and [three-strategy verifier](benchmarks/verify_josephus_problem.py). Upstream references: [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/JosephusProblem.java), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/josephus_problem.py), and [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/mathematics/josephus_problem.r).

## One hundred eighty-first reviewed benchmark algorithm: Josephus problem by direct recursion

Java and Python provide direct recursive implementations of the zero-based survivor recurrence. The shared one-based output is used with a participant bound of 256 to constrain recursion depth. See the [recursive Josephus guide](benchmarks/j/josephus_problem_recursive/README.md). Upstream references: [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/JosephusProblem.java) and [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/josephus_problem.py).

## One hundred eighty-second reviewed benchmark algorithm: Josephus problem by list simulation

Python also simulates removals with a list, an O(n^2) strategy distinct from the survivor recurrence. The ports preserve that shifting-list behavior with a bounded participant array. The C-Sharp source path recorded in the inventory does not resolve at its pinned revision; AArch64 Assembly is retained as a nonportable discovery reference. See the [simulation guide](benchmarks/j/josephus_problem_simulation/README.md). Upstream reference: [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/josephus_problem.py).

## One hundred eighty-fourth reviewed benchmark algorithm: Run-length encoding

The pinned C, Java, and Rust string implementations emit textual counts before each symbol, while Clojure, Python, and another Rust implementation return count/symbol pairs. The shared contract emits decimal count bytes followed by each ASCII symbol, excluding decimal digit symbols to keep the representation unambiguous. All nine ports passed 1,013 oracle inputs per language and recorded 12 workload cases each. See the [run-length encoding guide](benchmarks/r/run_length_encoding/README.md) and [workload](benchmarks/r/run_length_encoding/workload.json).

## One hundred eighty-fifth reviewed benchmark algorithm: Vigenère cipher

The Java, Julia, Rust, C++, JavaScript, and Python sources share repeating-key Vigenère encryption but differ on case preservation, invalid or empty keys, and whether punctuation advances the key. A PHP source uses the misspelled filename `vignere_cipher`. The shared contract uses a nonempty ASCII-letter key, preserves message case, and advances the key only for letters. All nine ports passed 3,575 oracle inputs per language and recorded 12 workload cases each. See the [Vigenère guide](benchmarks/v/vigenere_cipher/README.md) and [workload](benchmarks/v/vigenere_cipher/workload.json).

## One hundred eighty-sixth reviewed benchmark algorithm: Atbash cipher

The C++, Java, and PHP sources use the filename `atbash_cipher`; JavaScript, Julia, and Python use `atbash`. The benchmark standardizes to case-preserving reversal of ASCII letters and leaves all other 7-bit ASCII bytes unchanged. All nine ports passed 17,006 oracle inputs per language and recorded 8 workload cases each. See the [Atbash guide](benchmarks/a/atbash_cipher/README.md) and [workload](benchmarks/a/atbash_cipher/workload.json).

## One hundred eighty-seventh reviewed benchmark algorithm: XOR cipher

The C++, Python, and TypeScript `xor_cipher` sources use an integer key; Java, JavaScript, and PHP use the joined filename `xorcipher`, with some versions repeating a byte-string key and Java returning hexadecimal text. The shared contract uses a repeating byte key and returns raw output bytes, covering the single-byte integer-key form as well. All nine ports passed 2,577 oracle inputs per language and recorded 12 workload cases each. See the [XOR cipher guide](benchmarks/x/xor_cipher/README.md) and [workload](benchmarks/x/xor_cipher/workload.json).

## One hundred eighty-eighth reviewed benchmark algorithm: A1Z26 encoding

The pinned C++ `a1z26_cipher` and Python `a1z26` sources encode letters as one-based alphabet positions, using text or list results. The shared contract uses numeric bytes and accepts either ASCII letter case. All nine ports passed 684 oracle inputs per language and recorded 9 workload cases each. See the [A1Z26 encoding guide](benchmarks/a/a1z26_cipher/README.md) and [workload](benchmarks/a/a1z26_cipher/workload.json).

## One hundred eighty-ninth reviewed benchmark algorithm: A1Z26 decoding

The C++ `a1z26_cipher` source also decodes alphabet positions. This inverse operation has its own contract, accepting values from 1 through 26 and returning lowercase ASCII bytes. All nine ports passed 568 oracle inputs per language and recorded 8 workload cases each. See the [A1Z26 decoding guide](benchmarks/a/a1z26_decipher/README.md) and [workload](benchmarks/a/a1z26_decipher/workload.json).

## One hundred ninetieth reviewed benchmark algorithm: Container With Most Water

The pinned C LeetCode 11 implementation uses two pointers to find the maximum area between vertical lines. The shared contract accepts nonnegative signed 32-bit heights and returns signed 64-bit areas. All nine ports passed 22,412 oracle inputs per language and recorded 11 workload cases each. See the [Container With Most Water guide](benchmarks/c/container_with_most_water/README.md) and [workload](benchmarks/c/container_with_most_water/workload.json).

## One hundred ninety-first reviewed benchmark algorithm: Valid Palindrome

The pinned C LeetCode 125 implementation skips non-alphanumeric characters and compares ASCII letters without case sensitivity. The shared contract uses an explicit-length ASCII sequence and returns 1 for a palindrome, 0 otherwise, and -1 for invalid values or lengths. All nine ports passed 20,247 oracle inputs per language and recorded 11 workload cases each. See the [Valid Palindrome guide](benchmarks/v/valid_palindrome/README.md) and [workload](benchmarks/v/valid_palindrome/workload.json).

## One hundred ninety-second reviewed benchmark algorithm: Integer to Roman Numeral

The pinned C LeetCode 12, Java, Go, JavaScript, C++, and Python sources implement integer-to-Roman conversion. The shared contract emits canonical uppercase notation for values 1 through 3,999 and returns length-prefixed ASCII bytes. The pinned Dart source prints symbols but returns an empty list. All nine ports passed 4,620 oracle values per language, including every value from 0 through 4,096, capacity boundaries, and 11 workload cases. See the [Integer to Roman guide](benchmarks/i/integer_to_roman/README.md) and [workload](benchmarks/i/integer_to_roman/workload.json).

## One hundred ninety-third reviewed benchmark algorithm: Roman Numeral to Integer

The pinned C, JavaScript, Dart, Java, Ruby, Go, Python, and Rust sources decode Roman numerals with additive and subtractive notation. The shared contract accepts canonical uppercase numerals from 1 through 3,999 and rejects malformed forms. All nine ports passed 8,927 oracle arrays per language, including every valid numeral in range, exhaustive short symbol sequences, and 13 workload cases. See the [Roman Numeral to Integer guide](benchmarks/r/roman_to_integer/README.md) and [workload](benchmarks/r/roman_to_integer/workload.json).

## One hundred ninety-fourth reviewed benchmark algorithm: Maximum Consecutive Ones

The pinned C LeetCode filename 14 and JavaScript `MaxConsecutiveOnes` sources both count contiguous ones on binary arrays. All nine ports passed 8,734 oracle inputs per language and recorded 11 workload cases each. See the [Maximum Consecutive Ones guide](benchmarks/m/max_consecutive_ones/README.md) and [workload](benchmarks/m/max_consecutive_ones/workload.json).

## One hundred ninety-fifth reviewed benchmark algorithm: Subset Sum Existence

The signed existence workload maps directly to the pinned Rust backtracking source, which supports signed items and targets. The Java, Go, R, and Rust dynamic-programming decision variants require nonnegative values and map to the separate [Subset Sum Nonnegative Existence](benchmarks/s/subset_sum_nonnegative_exists/README.md) workload. The Go `subsetsum` and Java `subset_sum_space_optimized` records alias that positive-only contract. The signed C++ top-down variants map to the distinct `subset_sum_dynamic` package. All nine ports passed 56,773 exhaustive and deterministic oracle inputs per language. See the [Subset Sum Existence guide](benchmarks/s/subset_sum_exists/README.md) and [workload](benchmarks/s/subset_sum_exists/workload.json).

## One hundred ninety-sixth reviewed benchmark algorithm: Subset Sum Count

The pinned C++ backtracking implementation counts indexed subsets that reach a target, including the empty subset for target zero. The shared contract preserves index identity for duplicate values and uses signed inputs. All nine ports passed 56,771 exhaustive and deterministic count-oracle inputs per language. See the [Subset Sum Count guide](benchmarks/s/subset_sum_count/README.md) and [workload](benchmarks/s/subset_sum_count/workload.json).

## One hundred ninety-seventh reviewed benchmark algorithm: Subset Sum Enumeration

The portable workload uses signed inputs and emits each matching input-index mask once in ascending order, so duplicate values remain distinct. The R `find_all_subsets` routine is a related but separate candidate: it uses positive-value pruning and returns value vectors in include-first order, so it maps to the separate [Positive Subset Sum Value Enumeration](benchmarks/s/subset_sum_values_enumeration/README.md) contract, which requires strictly positive items. All nine ports passed 48,959 exhaustive and deterministic mask-oracle inputs per language, including output-capacity failures. See the [Subset Sum Enumeration guide](benchmarks/s/subset_sum_enumerate/README.md) and [workload](benchmarks/s/subset_sum_enumerate/workload.json).

## One hundred ninety-eighth reviewed benchmark algorithm: Subset Combinations

The pinned Python source builds fixed-size combinations with a dynamic-programming table, while Rust recursively emits index selections. The Rust `all_combination_of_size_k`, JavaScript and TypeScript `all_combinations_of_size_k`, and Python `all_combinations` candidates are reviewed aliases of this same fixed-size combination algorithm. The shared contract emits two-byte masks in lexicographic index order and preserves duplicate positions. All nine ports passed 8,692 exhaustive and deterministic oracle inputs per language, including output-capacity failures. See the [Subset Combinations guide](benchmarks/s/subset_combinations/README.md) and [workload](benchmarks/s/subset_combinations/workload.json).

## One hundred ninety-ninth reviewed benchmark algorithm: BST From Preorder

The pinned C LeetCode 1008 source recursively partitions a valid BST preorder at each root and constructs its subtrees. The shared contract validates unique signed 32-bit keys and emits a preorder serialization with null-child markers so the resulting shape is explicit. All nine ports passed 6,892 exhaustive and deterministic oracle inputs per language, including invalid traversals and insufficient output capacity. See the [BST From Preorder guide](benchmarks/b/bst_from_preorder/README.md) and [workload](benchmarks/b/bst_from_preorder/workload.json).

## Kth Largest Element by Quickselect

The pinned TheAlgorithms/Python source uses a descending final-element-pivot Lomuto partition and iterative quickselect. The shared contract accepts a rank and a bounded signed-32-bit array; all nine ports operate on a local copy. They passed 29,398 oracle cases per language and recorded 11 workload cases. See the [guide](benchmarks/k/kth_largest_element/README.md), [workload](benchmarks/k/kth_largest_element/workload.json), and [verifier](benchmarks/verify_kth_largest.py).

## Kth Largest Element by Full Sort

The pinned C LeetCode 215 source sorts the full array descending before selecting rank k. This is cataloged separately from quickselect; the nine portable ports use heapsort on a local copy before selecting the requested rank. They passed 29,398 oracle cases per language and recorded 11 workload cases. See the [guide](benchmarks/k/kth_largest_by_sort/README.md), [workload](benchmarks/k/kth_largest_by_sort/workload.json), and [verifier](benchmarks/verify_kth_largest.py).

## Median benchmark

The pinned C median source is an interactive random-data demonstration and truncates the middle-pair division; Go truncates integer division before converting to `float64`; Java and Kotlin can overflow while adding the middle `int` values; Lua uses quickselect; and PHP sorts variadic numeric inputs. The shared contract accepts 1–1,024 signed 32-bit values and reports twice the exact statistical median, preserving half-integer results in the integer-array scalar ABI. Nine portable ports insertion-sort a bounded local copy. The verifier checks 4,475 oracle arrays per language, including the maximum-length input, and checks the published workload. See [the median guide](benchmarks/m/median/README.md).

## Median of two sorted arrays

The pinned C LeetCode 4 source merges two already sorted arrays, then selects the middle value or pair. The contract packs both arrays as lengths followed by signed 32-bit values and returns twice the exact median. This merge algorithm remains separate from the one-array median benchmark. All nine ports passed 30,408 oracle cases per language and recorded 11 workload cases. See the [guide](benchmarks/m/median_of_two_sorted_arrays/README.md), [workload](benchmarks/m/median_of_two_sorted_arrays/workload.json), and [verifier](benchmarks/verify_median_of_two_sorted_arrays.py).

## Number of Laser Beams

The pinned C LeetCode 2125 source counts devices per row and multiplies the counts for adjacent nonempty rows. All nine ports use a bounded row-major ASCII grid and track only the preceding nonempty row; they passed 5,569 oracle cases per language and recorded 8 workload cases. See the [guide](benchmarks/n/number_of_laser_beams/README.md), [workload](benchmarks/n/number_of_laser_beams/workload.json), and [verifier](benchmarks/verify_number_of_laser_beams.py).

## Maximum Twin Sum of a Linked List

The pinned C LeetCode 2130 source copies list values to an array and scans mirrored pairs for the maximum sum. The shared contract keeps the source constraints of an even list length and positive values. All nine ports use a bounded local copy; they passed 5,145 oracle cases per language and recorded 7 workload cases. See the [guide](benchmarks/m/maximum_twin_sum_of_linked_list/README.md), [workload](benchmarks/m/maximum_twin_sum_of_linked_list/workload.json), and [verifier](benchmarks/verify_maximum_twin_sum_of_linked_list.py).

## Morse code encoder

The pinned C++ snapshots accept lowercase ASCII letters and digits; JavaScript supports a wider set with a configurable dot symbol; PHP, Python, and Rust encode letters, digits, spaces, and punctuation with differing invalid-input behavior. The shared contract keeps the common alphanumeric encoder, normalizes ASCII case, and emits canonical Morse tokens separated by single spaces. All nine ports passed 4,490 oracle inputs each, including invalid bytes and zero output capacity. See [the Morse code guide](benchmarks/m/morse_code/README.md).

## Extended Euclidean algorithm

The pinned C-Sharp, Java, Python, R, and Rust implementations differ in tuple order, whether the GCD is returned, and behavior for zero or negative inputs. The shared contract accepts two positive signed-32-bit values and emits `(gcd,x,y)` as three signed little-endian 32-bit integers. All nine ports passed 2,126 recursive-oracle inputs and the 17 published workload cases. See [the extended Euclidean guide](benchmarks/e/extended_euclidean_algorithm/README.md).


## Climbing stairs

The pinned Java, JavaScript, Python, and Ruby sources count ordered ways to climb using one-step and two-step moves. Their zero-step behavior differs, so the shared contract uses positive inputs from 1 through 45 and returns the corresponding Fibonacci value F(n+1); out-of-range inputs return -1. Nine portable ports use an iterative recurrence. The verifier checked all 45 valid inputs plus nine signed-64-bit boundary cases per language, and checked all 20 published workload cases. See the [climbing stairs guide](benchmarks/c/climbing_stairs/README.md). Upstream references: [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/ClimbingStairs.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/ClimbingStairs.js), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/climbing_stairs.py), and [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/dynamic_programming/climbing_stairs.rb).


## Factors

The pinned Dart and JavaScript implementations scan upward, Python and Rust scan divisor pairs through the square root and sort them, and TypeScript returns divisor pairs in a Set. The shared contract accepts positive values from 1 through 256 and emits every positive divisor once in ascending order as comma-separated bytes. All nine ports passed 520 exhaustive validity, output-capacity, and signed-boundary cases per language, plus the 14 workload cases. See the [factors guide](benchmarks/f/factors/README.md) and [workload](benchmarks/f/factors/workload.json). Upstream references: [Dart](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/factors.dart), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/Factors.js), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/factors.py), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/factors.rs), and [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/factors.ts).


## Prime factors

The pinned JavaScript, Python, Rust, and intended Julia implementations emit prime factors with multiplicity; Python also has a distinct-factor helper. The Julia source can divide by a nonfactor because it compares the remainder to 1, and Scala returns `[1]` for input 1. The shared contract accepts positive signed-32-bit inputs, returns factors in ascending order, and encodes them as comma-separated ASCII bytes. All nine languages passed 5,143 oracle cases per language, including insufficient output capacity, plus the 17 published workload cases. See the [prime-factors guide](benchmarks/p/prime_factors/README.md) and [workload](benchmarks/p/prime_factors/workload.json). Upstream references: [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/PrimeFactors.js), [Julia](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/prime_factors.jl), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/prime_factors.py), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/prime_factors.rs), and [Scala](https://github.com/TheAlgorithms/Scala/blob/de555349d5effb87962d3116eb08c9f374065112/src/main/scala/Mathematics/PrimeFactors.scala).


## Knuth–Morris–Pratt

The pinned C++, F#, Python, and Rust versions expose different result types; Rust also uses Unicode character positions and returns every match. The shared contract standardizes first-match byte indices over ASCII inputs. All nine ports passed 4,504 oracle cases each, including exhaustive short binary strings, malformed packed inputs, deterministic random sequences, and long near-matches. See the [Knuth–Morris–Pratt guide](benchmarks/k/knuth_morris_pratt/README.md) and [workload](benchmarks/k/knuth_morris_pratt/workload.json). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/strings/knuth_morris_pratt.cpp), [C++1](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/strings/knuth_morris_pratt.cpp), [F#](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Strings/KnuthMorrisPratt.fs), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/knuth_morris_pratt.py), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/knuth_morris_pratt.rs).


## Isogram

The pinned TypeScript `calculate_median` source directly indexes the middle of an already sorted array. Its nine portable ports keep the measured operation O(1) by treating sortedness and signed-i32 range as input preconditions; even-length results are encoded as the sum of the two central values, exactly twice the statistical median. See the [calculate-median guide](benchmarks/c/calculate_median/README.md) and [verifier](benchmarks/verify_calculate_median.py).

The pinned C implementation checks exact byte duplicates; Java contains alphabetic-only and full-string variants; Rust folds ASCII case, ignores whitespace, and rejects other nonletters. The benchmark standardizes case-insensitive ASCII letters with ASCII spaces ignored. All nine ports passed 4,440 oracle cases each, including exhaustive case-and-space sequences, invalid bytes, random inputs, and maximum lengths. See the [Isogram guide](benchmarks/i/isogram/README.md) and [workload](benchmarks/i/isogram/workload.json). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/exercism/isogram/isogram.c), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/Isogram.java), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/isogram.rs).


## Boyer–Moore Search

The pinned C, Python, and Rust versions implement the bad-character rule but expose different APIs; Rust returns Unicode character positions. The shared contract returns the first matching ASCII byte index. All nine ports passed 4,505 oracle inputs each, including exhaustive short binary strings, malformed packed inputs, random sequences, and long near-matches. See the [Boyer–Moore Search guide](benchmarks/b/boyer_moore_search/README.md) and [workload](benchmarks/b/boyer_moore_search/workload.json). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/searching/pattern_search/boyer_moore_search.c), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/boyer_moore_search.py), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/boyer_moore_search.rs).
The pinned Julia naive_pattern_search performs a direct left-to-right window scan and reports the first zero-based match. Its benchmark bounds the domain to ASCII bytes and projects the source string result to the matching offset. See the [naive-pattern-search guide](benchmarks/n/naive_pattern_search/README.md).


## Trapped Rainwater

The pinned C++ and Rust versions compute left and right maximum heights and sum the enclosed water. The pinned Python [`trapped_water.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/trapped_water.py) uses the same prefix/suffix-maxima algorithm and is cataloged as an alias of this benchmark. The contract bounds 4,096 heights to 0 through 1,000,000; the maximum total remains within their unsigned 32-bit result range. All nine ports passed 22,401 oracle arrays each, including exhaustive short profiles, random profiles, invalid values, and a maximum-length basin. See the [Trapped Rainwater guide](benchmarks/t/trapped_rainwater/README.md) and [workload](benchmarks/t/trapped_rainwater/workload.json). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/trapped_rainwater.cpp) and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/trapped_rainwater.rs).


## Miller–Rabin

The pinned C++ and Python `rabin_miller.py` sources choose random witnesses, while the Rust source accepts a fixed list and returns a witness for composites. Python `rabin_miller.py` also screens with small primes through 997. The deterministic Python source selects a threshold-dependent prefix of prime bases, which gives the same classification as fixed bases `[2, 3, 5, 7]` on the signed 32-bit domain. The shared contract normalizes these witness strategies to those bases, returns `1` for prime and `0` for composite, and returns `-1` above the benchmark domain; the Rust source states that these bases are deterministic below 3,215,031,751, covering the full signed 32-bit input range. The raw randomized Python primitive is undefined below 3, so the benchmark guards small inputs before invoking it. All nine implementations passed 100,271 trial-division oracle inputs each, including published pseudoprime cases and signed boundaries. See the [Miller–Rabin guide](benchmarks/m/miller_rabin/README.md) and [workload](benchmarks/m/miller_rabin/workload.json). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/miller_rabin.cpp), [C++1](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/miller_rabin.cpp), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/miller_rabin.rs), randomized [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/rabin_miller.py), and deterministic [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/deterministic_miller_rabin.py).


## Word Break

The pinned C++ and Python sources all allow reuse of dictionary words, using memoized prefix or suffix checks, trie traversal, or backtracking. The shared contract uses lowercase ASCII and fixed-width dictionary slots, and treats empty text as segmentable. All nine ports passed 8,668 oracle inputs per language plus 27 workload records. See the [Word Break guide](benchmarks/w/word_break/README.md) and [workload](benchmarks/w/word_break/workload.json).

## Unique Paths

The pinned Java implementation offers one- and two-dimensional dynamic programming; JavaScript uses a one-dimensional row. The shared contract accepts dimensions from 1 through 34 and returns exact signed-64-bit counts, rejecting out-of-range dimensions. All nine ports passed 1,913 oracle pairs each and recorded 17 workload cases. See the [Unique Paths guide](benchmarks/u/unique_paths/README.md) and [workload](benchmarks/u/unique_paths/workload.json).


## Activity Selection

The pinned Java and Python greedy implementations sort activities by finish time and select the next activity when its start is at least the last finish; a second Python source assumes sorted inputs and prints selected indices. The shared contract returns the maximum selection count and validates a packed list of up to 64 signed-time intervals. All nine ports passed 11,615 oracle arrays each, including exhaustive small schedules and malformed inputs, and recorded 17 workload cases. See the [Activity Selection guide](benchmarks/a/activity_selection/README.md) and [workload](benchmarks/a/activity_selection/workload.json).


## Sorted Array to BST

The pinned C LeetCode 108 source recursively chooses the midpoint of a sorted array and constructs the left and right subtrees; empty input returns a null tree. The shared contract uses the lower median for even ranges and serializes the balanced result in preorder. All nine ports passed 1,032 serialized-tree cases each, including invalid arrays and insufficient output capacity, and recorded 12 workload cases. See the [Sorted Array to BST guide](benchmarks/s/sorted_array_to_bst/README.md) and [workload](benchmarks/s/sorted_array_to_bst/workload.json).


## Duplicate Zeros

The pinned C LeetCode 1089 source copies the input and duplicates zero values while preserving the array length. The shared contract emits the resulting values in signed 32-bit little-endian form. All nine ports passed 1,597 output-array cases each, including exhaustive short arrays and insufficient capacity, and recorded 11 workload cases. See the [Duplicate Zeros guide](benchmarks/d/duplicate_zeros/README.md) and [workload](benchmarks/d/duplicate_zeros/workload.json).

## Sorted List to BST

The pinned C LeetCode 109 source recursively finds each subtree root with slow and fast linked-list pointers; its walk selects the upper middle node for even lengths. The shared contract represents the list as a sorted array and serializes the resulting balanced tree. All nine ports passed 3,945 serialized-tree cases each, including duplicate keys, malformed sequences, and insufficient capacity, and recorded 12 workload cases. See the [Sorted List to BST guide](benchmarks/s/sorted_list_to_bst/README.md) and [workload](benchmarks/s/sorted_list_to_bst/workload.json).


## Path Sum

The pinned C LeetCode 112 source subtracts each node value from the requested target and accepts a match only at a leaf. The Dart `path_sum.dart` candidate accumulates path values and checks the sum only at leaves; it has the same root-to-leaf semantics. The shared contract uses a validated indexed-tree input with signed 32-bit node values and a signed 64-bit target. All nine ports passed 14,729 oracle trees each, including every small tree shape and malformed structures, and recorded 22 workload cases. See the [Path Sum guide](benchmarks/p/path_sum/README.md) and [workload](benchmarks/p/path_sum/workload.json).

## Longest Chunked Palindrome Decomposition

The pinned C LeetCode 1147 candidate is reviewed and mapped to longest_chunked_palindrome_decomposition. Its contract returns the maximum number of mirrored chunks for a bounded ASCII input. Nine portable ports, the workload, and an exhaustive-cut oracle verifier are recorded under benchmarks/l/longest_chunked_palindrome_decomposition/.

## Distance Between Bus Stops

The pinned C LeetCode 1184 candidate is reviewed and mapped to distance_between_bus_stops. Its bounded contract returns the shorter of the two circular routes between a pair of stops. Nine portable ports, the workload, and an exact summation verifier are recorded under benchmarks/d/distance_between_bus_stops/.

## Maximum Number of Balloons

The pinned C LeetCode 1189 candidate is reviewed and mapped to max_number_of_balloons. Its contract accepts up to 256 lowercase ASCII letters and returns the number of copies of balloon that can be formed. All nine language ports passed 20,054 oracle cases each and recorded 14 workload cases. See the [benchmark guide](benchmarks/m/max_number_of_balloons/README.md) and [verifier](benchmarks/verify_max_number_of_balloons.py).

## Unique Occurrences

The pinned C LeetCode 1207 candidate is reviewed and mapped to unique_occurrences. Its contract accepts up to 1,000 values in -1,000..1,000 and checks whether every value has a distinct positive frequency. All nine language ports passed 10,365 oracle cases each and recorded 13 workload cases. See the [benchmark guide](benchmarks/u/unique_occurrences/README.md) and [verifier](benchmarks/verify_unique_occurrences.py).

## Smallest Divisor

The pinned C LeetCode 1283 candidate is reviewed and mapped to smallest_divisor. Its packed input contains a threshold followed by 1 to 256 positive values. All nine language ports passed 5,797 cases each against a direct divisor scan and recorded 14 workload cases. See the [benchmark guide](benchmarks/s/smallest_divisor/README.md) and [verifier](benchmarks/verify_smallest_divisor.py).

## Number of Subarrays With Odd Sum

The pinned C LeetCode 1524 candidate is reviewed and mapped to number_of_subarrays_with_odd_sum. It returns the odd-sum contiguous subarray count modulo 1,000,000,007. All nine language ports passed 10,358 oracle cases each and recorded 11 workload cases. See the [benchmark guide](benchmarks/n/number_of_subarrays_with_odd_sum/README.md) and [verifier](benchmarks/verify_number_of_subarrays_with_odd_sum.py).



## Minimum Deletions to Make String Balanced

The pinned C LeetCode 1653 candidate is reviewed and mapped to minimum_deletions_to_make_string_balanced. Its packed input maps a to 0 and b to 1; it returns the fewest deletions needed to leave all a values before all b values. All nine language ports passed 8,690 oracle cases each and recorded 15 workload cases. See the [benchmark guide](benchmarks/m/minimum_deletions_to_make_string_balanced/README.md) and [verifier](benchmarks/verify_minimum_deletions_to_make_string_balanced.py).

## Close Strings

The pinned C LeetCode 1657 candidate is reviewed and mapped to close_strings. Its packed input contains two lowercase ASCII strings and checks their character sets and frequency multisets. All nine language ports passed 15,168 oracle cases each and recorded 14 workload cases. See the [benchmark guide](benchmarks/c/close_strings/README.md) and [verifier](benchmarks/verify_close_strings.py).

## Maximum Unique Subarray

The pinned C LeetCode 1695 candidate is reviewed and mapped to maximum_unique_subarray. It maximizes the sum of a contiguous subarray whose values are distinct. The shared contract accepts 0 to 256 positive values in 1..10,000. All nine language ports passed 22,371 oracle cases each and recorded 14 workload cases. See the [benchmark guide](benchmarks/m/maximum_unique_subarray/README.md) and [verifier](benchmarks/verify_maximum_unique_subarray.py).

## Halves Are Alike

The pinned C LeetCode 1704 candidate is reviewed and mapped to halves_are_alike. Its contract accepts even-length ASCII letter sequences and compares vowel counts in their equal halves. All nine language ports passed 16,797 oracle cases each and recorded 13 workload cases. See the [benchmark guide](benchmarks/h/halves_are_alike/README.md) and [verifier](benchmarks/verify_halves_are_alike.py).



## Minimum Operations to Move All Balls

The pinned C LeetCode 1769 candidate is reviewed and mapped to minimum_operations_to_move_all_balls. Its binary input represents occupied boxes, and it returns each box’s total movement count using two linear passes. All nine language ports passed 1,017 oracle cases each and recorded 15 workload cases. See the [benchmark guide](benchmarks/m/minimum_operations_to_move_all_balls/README.md) and [verifier](benchmarks/verify_minimum_operations_to_move_all_balls.py).

## Check If Array Is Sorted and Rotated

The pinned C LeetCode 1752 candidate is reviewed and mapped to check_if_array_is_sorted_and_rotated. Its contract accepts bounded signed 32-bit arrays and checks whether any rotation is nondecreasing. All nine language ports passed 3,805 oracle cases each and recorded 14 workload cases. See the [benchmark guide](benchmarks/c/check_if_array_is_sorted_and_rotated/README.md) and [verifier](benchmarks/verify_check_if_array_is_sorted_and_rotated.py).


## Maximum Ice Cream Bars

The pinned C LeetCode 1833 candidate is reviewed and mapped to maximum_ice_cream_bars. Its greedy implementation sorts costs and buys the cheapest bars while the budget permits. All nine language ports passed 10,649 oracle cases each and recorded 15 workload cases. See the [benchmark guide](benchmarks/m/maximum_ice_cream_bars/README.md) and [verifier](benchmarks/verify_maximum_ice_cream_bars.py).


## Maximum Frequency After Increments

The pinned C LeetCode 1838 candidate is reviewed and mapped to maximum_frequency_after_increments. It sorts values and finds the largest targetable window within the increment budget. All nine language ports passed 7,335 oracle cases each and recorded 16 workload cases. See the [benchmark guide](benchmarks/m/maximum_frequency_after_increments/README.md) and [verifier](benchmarks/verify_maximum_frequency_after_increments.py).


## Search Insert Position

The pinned C LeetCode 35 candidate is reviewed and mapped to search_insert_position. The benchmark uses the first, iterative binary-search definition in the upstream file and returns the lower-bound index for strictly increasing input. All nine language ports passed 6,582 oracle cases each and recorded 15 workload cases. See the [benchmark guide](benchmarks/s/search_insert_position/README.md) and [verifier](benchmarks/verify_search_insert_position.py).


## Plus One

The pinned C LeetCode 66 candidate is reviewed and mapped to plus_one. It increments canonical decimal digit arrays and returns ASCII decimal bytes. All nine language ports passed 10,519 oracle cases each and recorded 12 workload cases. See the [benchmark guide](benchmarks/p/plus_one/README.md) and [verifier](benchmarks/verify_plus_one.py).


## Valid Parentheses

The pinned C LeetCode 20 and Java `ValidParentheses` candidates share stack-based bracket matching; candidate `20` is recorded as an alias of the canonical Java filename candidate. The common contract returns 1 for correctly nested `()[]{}`, 0 for malformed nesting, and -1 for unsupported byte values or inputs longer than 256. All nine language ports passed 56,506 oracle arrays and recorded 14 workload cases. See the [benchmark guide](benchmarks/v/valid_parentheses/README.md) and [verifier](benchmarks/verify_valid_parentheses.py).


## Find Minimum in Rotated Sorted Array

The pinned C LeetCode 153 candidate assumes a nonempty rotation of a strictly increasing array and uses binary search to return its minimum. The shared contract supports up to 256 signed 64-bit values. All nine ports passed 981 oracle arrays each and recorded 13 workload cases. See the [benchmark guide](benchmarks/f/find_min_rotated_sorted_array/README.md) and [verifier](benchmarks/verify_find_min_rotated_sorted_array.py).


## Boyer–Moore Majority Vote

The C LeetCode 169, C-Sharp, and Rust Moore voting sources implement strict majority cancellation and verification; the Python generalized vote routine matches when its threshold is fixed at 2. The Rust `moore_voting` source is an alias of this contract. The Java `MajorityElement` candidate uses a different threshold and can return multiple values, so it remains separate. All nine ports passed 20,574 oracle arrays each and recorded 14 workload cases. See the [benchmark guide](benchmarks/b/boyer_moore_majority_vote/README.md) and [verifier](benchmarks/verify_boyer_moore_majority_vote.py).


## Hamming Weight

The pinned C LeetCode 191 candidate counts set bits across an unsigned 32-bit value. The C++ `count_of_set_bits` and JavaScript `binary_count_set_bits` candidates match it on this shared input domain and are recorded as aliases. All nine language ports passed 66,104 oracle cases each and recorded 10 workload cases. See the [benchmark guide](benchmarks/h/hamming_weight/README.md) and [verifier](benchmarks/verify_scalar.py). Upstream references: [C LeetCode 191](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/191.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2849e8d1a8d926e171cc5b39f97759/bit_manipulation/count_of_set_bits.cpp), and [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Bit-Manipulation/BinaryCountSetBits.js).


## Bit-array operations

The pinned C# `BitArray` supplies bit counts, parity, conversion, Boolean operations, and logical shifts. Its shared operations map to existing portable contracts, with a dedicated nine-language zero-bit counter. The source also has array comparison, iteration, cloning, reset, and fill helpers; these remain data-structure support operations. Its AND adapter is limited to equal-width operands to honor the implementation's stated precondition. See the [zero-bit guide](benchmarks/b/bit_array_count_zero_bits/README.md) and the pinned [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/BitArray.cs).

## BLAKE2b-512

The pinned Rust source implements keyed BLAKE2b with configurable digest length. The shared benchmark uses its unkeyed 64-byte configuration and bounds messages to 4,096 bytes. The C `hash_blake2b` candidate exposes the same compression with the same unkeyed 64-byte parameters and aliases this contract. See the [BLAKE2b-512 guide](benchmarks/b/blake2b/README.md), [byte-output verifier](benchmarks/verify_i64_array_bytes_output.py), and pinned [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/hashing/blake2b.rs) and [C source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/hash/hash_blake2b.c).

## Prime Numbers

The pinned C++1, Python, and Rust sources generate primes through an inclusive limit; the C++1 version uses a linear sieve, while Python and Rust include trial-division generators. One Python file with the same filename contains next-prime helper functions rather than the prime-list operation and is documented separately. The shared benchmark returns comma-separated primes for limits 0 through 80. All nine ports passed 175 oracle cases each, including insufficient output capacity and signed boundaries, and recorded 11 workload cases. See the [benchmark guide](benchmarks/p/prime_numbers/README.md) and [verifier](benchmarks/verify_prime_numbers.py). Upstream references: [C++1](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/prime_numbers.cpp), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/prime_numbers.py), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/prime_numbers.rs).


## First N Primes

The pinned TypeScript source provides an infinite prime generator, and Zig computes the first 25 primes for its test. The benchmark returns the first `n` primes for counts from 0 through 20. All nine ports passed 54 oracle cases each, including output-capacity failures and signed boundaries, and recorded 9 workload cases. See the [benchmark guide](benchmarks/f/first_n_primes/README.md) and [verifier](benchmarks/verify_first_n_primes.py). Upstream references: [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/primes.ts) and [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/math/primes.zig).


## Digital Root

The pinned Java and Python sources compute the decimal digital root by repeatedly summing digits. The Ruby `add_digits` files implement the same operation with recursive summation and the modulo-nine identity, and are recorded as aliases. The shared contract accepts nonnegative signed-64-bit inputs; all nine ports passed 10,538 oracle cases each and recorded 12 workload cases. See the [benchmark guide](benchmarks/d/digital_root/README.md) and [verifier](benchmarks/verify_scalar.py). Upstream references: [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/DigitalRoot.java), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/digital_root.py), [Ruby repeated sum](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/add_digits.rb), and [Ruby modulo nine](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/add_digits.rb).


## Addition Without Arithmetic

The pinned C-Sharp and Python implementations use the XOR/AND/shift carry recurrence; the C-Sharp source uses 32-bit integers while Python integers are unbounded. The shared contract accepts signed-32-bit operands, returns an exact sum only when the result also fits signed 32-bit range, and returns -1 for input-range failures or overflow. All nine ports passed 66,129 oracle pairs each and recorded 13 workload cases. See the [benchmark guide](benchmarks/a/addition_without_arithmetic/README.md) and [verifier](benchmarks/verify_binary_scalar.py). Upstream references: [C-Sharp](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/AdditionWithoutArithmetic.cs) and [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/addition_without_arithmetic.py).


## Amicable Number

The pinned Java source defines a pair of distinct positive integers as amicable when each number equals the other number’s proper-divisor sum. Its recursive predicate omits an equal-number check, so equal perfect numbers would otherwise pass despite the documented definition. The shared contract bounds both values to 1 through 1,000,000,000 and rejects equal pairs. All nine ports passed 66,058 oracle pairs each and recorded 15 workload cases. See the [benchmark guide](benchmarks/a/amicable_number/README.md) and [verifier](benchmarks/verify_binary_scalar.py). Upstream reference: [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/AmicableNumber.java).

## Linked List Cycle Detection

The pinned C LeetCode 141 source uses Floyd’s tortoise and hare pointers to detect a cycle reachable from the head. The JavaScript `cycle_detection`, Python `floyds_cycle_detection`, and Rust `floyds_algorithm` candidates implement that same intended boolean operation and alias this benchmark. The Python node dataclass compares structurally rather than by identity, so the alias follows the standard pointer-identity semantics represented by the portable contract. The Rust file also contains a separate `detect_cycle` helper whose reported cycle index is incorrect; it is not mapped to the cycle-entry benchmark. The portable contract represents links as successor indices, with `-1` for null and node `0` as the head, so the implementations do not depend on pointer layout or allocator behavior. All nine language ports passed 8,967 oracle arrays each, including every successor graph through five nodes, deterministic random arrays, malformed references, and 100,000-node stress cases. See the [benchmark guide](benchmarks/l/linked_list_has_cycle/README.md) and [verifier](benchmarks/verify_linked_list_cycles.py). Upstream references: [C LeetCode 141](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/141.c), [JavaScript `CycleDetection.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Linked-List/CycleDetection.js), [Python `floyds_cycle_detection.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/floyds_cycle_detection.py), and [Rust `floyds_algorithm.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/floyds_algorithm.rs).

## Linked List Cycle Entry

The pinned C LeetCode 142 source uses Floyd’s two-pass method to return the node where a reachable cycle begins. The portable contract uses successor indices with `-1` for null and node `0` as the head, returning the zero-based entry index, `-1` for an acyclic path, and `-2` for malformed input. All nine language ports passed 8,967 oracle arrays each and recorded 13 workload cases. See the [benchmark guide](benchmarks/l/linked_list_cycle_entry/README.md) and [verifier](benchmarks/verify_linked_list_cycles.py). Upstream reference: [C LeetCode 142](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/142.c). The pinned JavaScript `CycleDetectionII.js` source is an alias of the same `linked_list_cycle_entry` contract; it measures the cycle length and offsets one pointer before converging on the entry ([source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Linked-List/CycleDetectionII.js)).


## Contains Duplicate

The pinned C LeetCode 217 source sorts the integer array and scans neighboring values. The shared contract accepts up to 1,024 signed 32-bit integers, returning 1 when a value repeats, 0 otherwise, and -1 for invalid values or lengths. All nine language ports sort a private copy with portable heapsort; they passed 20,168 oracle arrays each and recorded 11 workload cases. See the [benchmark guide](benchmarks/c/contains_duplicate/README.md) and [verifier](benchmarks/verify_contains_duplicate.py). Upstream reference: [C LeetCode 217](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/217.c).


## Max Consecutive Answers

The pinned C LeetCode 2024 source uses a sliding window for both T and F targets, allowing at most k changes. The portable contract encodes answers as 0/1 values after k and returns the longest run for either target. All nine ports passed 9,740 oracle arrays each and recorded 12 workload cases. See the [benchmark guide](benchmarks/m/max_consecutive_answers/README.md) and [verifier](benchmarks/verify_max_consecutive_answers.py). Upstream reference: [C LeetCode 2024](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2024.c).


## Additional C LeetCode aliases

C LeetCode 461 counts differing bits for nonnegative 32-bit inputs and aliases the fixed-width [hamming_distance benchmark](benchmarks/h/hamming_distance/README.md). C LeetCode 485 counts runs of ones in a binary array and aliases [max_consecutive_ones](benchmarks/m/max_consecutive_ones/README.md). Both candidates use the existing nine-language implementations and workload contracts.


## Missing Number

The pinned C LeetCode 268 source subtracts the observed sum from the sum of 0 through n. The shared contract validates distinct values in [0,n], including the empty-array case. All nine ports passed 8,990 oracle arrays each and recorded 13 workload cases. See the [benchmark guide](benchmarks/m/missing_number/README.md) and [verifier](benchmarks/verify_missing_number.py). Upstream reference: [C LeetCode 268](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/268.c).


## Missing Number in Consecutive Range

The pinned Python and Rust sources use XOR cancellation over a consecutive signed range inferred from observed endpoints. This is separate from LeetCode 268, whose domain permits a missing endpoint. The shared contract requires both endpoints to occur and a single missing interior value. All nine ports passed 39,619 oracle arrays each and recorded 13 workload cases. See the [benchmark guide](benchmarks/m/missing_number_in_range/README.md) and [verifier](benchmarks/verify_missing_number_in_range.py). Upstream references: [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/missing_number.py) and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/bit_manipulation/find_missing_number.rs).


## Single Non-Duplicate

The pinned C LeetCode 540 source uses pair-index parity to binary-search a sorted array containing one single value and otherwise duplicated pairs. The benchmark keeps sortedness and pair multiplicities as input preconditions, preserving O(log n) search cost. All nine ports passed 972 oracle arrays each and recorded 13 workload cases. See the [benchmark guide](benchmarks/s/single_non_duplicate/README.md) and [verifier](benchmarks/verify_single_non_duplicate.py). Upstream reference: [C LeetCode 540](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/540.c).


## First Unique Character

The pinned C LeetCode 387 and JavaScript FirstUniqueCharacter sources both count character frequencies and return the first unique index; the JavaScript candidate is an alias under the lowercase ASCII contract. All nine ports passed 10,356 oracle arrays each and recorded 12 workload cases. See the [benchmark guide](benchmarks/f/first_unique_character/README.md) and [verifier](benchmarks/verify_first_unique_character.py). Upstream references: [C LeetCode 387](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/387.c) and [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/FirstUniqueCharacter.js).


## Longest Substring Without Repeating Characters

The C LeetCode 3 implementation tracks last-seen byte positions in an O(n) sliding window; its source file also contains a separate brute-force duplicate definition. The Java and JavaScript candidates use a shrinking unique-character window. The portable contract represents printable ASCII as values 32 through 126 and bounds the input to 1,024 values. All nine language ports are checked against an independent sliding-window oracle. The numeric LeetCode source stem `3` is an alias of this alphabetic benchmark name. The pinned C++ source candidate returned 404 during review and is excluded from the evidence. See the [benchmark guide](benchmarks/l/longest_substring_without_repeating_characters/README.md) and [verifier](benchmarks/verify_longest_substring_without_repeating_characters.py). Upstream references: [C LeetCode 3](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/3.c), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/slidingwindow/LongestSubstringWithoutRepeatingCharacters.java), and [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/Sliding-Window/LongestSubstringWithoutRepeatingCharacters.js).


## Three Sum Closest

The pinned C LeetCode 16 source sorts the values and uses a two-pointer search for the closest three-value sum. Its qsort mutates the input and its `int` distance expression can overflow outside the problem’s original narrow bounds. The shared contract copies and heapsorts signed 32-bit values, widens arithmetic to signed 64-bit, and resolves equal-distance results to the lower sum. All nine ports passed 16,740 independent pair-plus-binary-search oracle inputs each and recorded 13 workload cases. See the [benchmark guide](benchmarks/t/three_sum_closest/README.md) and [verifier](benchmarks/verify_three_sum_closest.py). Upstream reference: [C LeetCode 16](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/16.c).


## Valid Anagram

The pinned C LeetCode 242 source counts lowercase ASCII letters separately in each input string and compares the resulting 26-entry frequency tables. The shared packed-array contract validates both string lengths and the lowercase ASCII domain. All nine ports passed 15,170 independent frequency-oracle inputs each and recorded 14 workload cases. See the [benchmark guide](benchmarks/v/valid_anagram/README.md) and [verifier](benchmarks/verify_valid_anagram.py). Upstream reference: [C LeetCode 242](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/242.c).


## To Lower Case

The pinned C LeetCode 709 source calls locale-sensitive `tolower` and mutates its NUL-terminated input. The shared benchmark uses explicit ASCII values, maps `A` through `Z`, preserves other non-NUL 7-bit bytes, and writes to a separate output buffer. All nine ports passed 16,780 oracle inputs each and recorded 12 workload cases, including insufficient capacity. See the [benchmark guide](benchmarks/t/to_lower_case/README.md) and [verifier](benchmarks/verify_to_lower_case.py). Upstream reference: [C LeetCode 709](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/709.c).

## Remove Nth Node From End of List

The pinned C LeetCode 19 source counts nodes and unlinks the node at a one-based position from the tail. The pinned Python source validates the position and uses two pointers to remove the same node. The shared contract bounds inputs to 1,024 signed 32-bit values and returns the remaining list as little-endian bytes. All nine ports passed 6,800 oracle cases each and recorded 13 workload cases. C candidate `19` is cataloged as an alias under the alphabetic algorithm name. See the [benchmark guide](benchmarks/r/remove_nth_node_from_end_of_list/README.md) and [verifier](benchmarks/verify_remove_nth_node_from_end_of_list.py). Upstream references: [C LeetCode 19](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/19.c) and [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/remove_nth_node_from_end_of_list.py).

## Merge Two Sorted Lists

The pinned C LeetCode 21, Dart, and JavaScript sources merge ascending lists with a linear two-cursor pass. The Python source rebuilds the sorted result using a different method, with the same output semantics for sorted inputs. The shared contract validates two ascending signed 32-bit sequences and emits their merged values as little-endian bytes. All nine ports passed 5,690 oracle inputs each and recorded 14 workload cases. The C LeetCode candidate uses the alphabetic benchmark name; Dart `merge_sorted_list`, Python `merge_two_lists`, and JavaScript `merge_two_sorted_linked_lists` are cataloged as aliases. See the [benchmark guide](benchmarks/m/merge_two_sorted_lists/README.md) and [verifier](benchmarks/verify_merge_two_sorted_lists.py). Upstream references: [C LeetCode 21](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/21.c), [Dart](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/data_structures/linked_list/merge_sorted_list.dart), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/merge_two_lists.py), and [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Linked-List/MergeTwoSortedLinkedLists.js).

## Remove Duplicates From Sorted Array

The pinned C LeetCode 26 source uses a write index to compact an ascending array in place and returns the number of unique values. The shared contract validates signed 32-bit inputs and emits the unique prefix in a separate output buffer. All nine ports passed 1,570 oracle cases each and recorded 10 workload cases, including 4,096-element arrays. The numeric C filename `26` is cataloged under the alphabetic algorithm name. See the [benchmark guide](benchmarks/r/remove_duplicates_from_sorted_array/README.md) and [verifier](benchmarks/verify_remove_duplicates_from_sorted_array.py). Upstream reference: [C LeetCode 26](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/26.c).


## Remove Element

The pinned C LeetCode 27 implementation compacts values with a write index, removing every occurrence of the target. The Ruby `remove_elements` candidate implements the same removal goal and permits survivor reordering; the shared contract emits survivors in their original order. All nine portable ports passed 20,315 oracle inputs each and recorded 10 workload cases, including maximum-length arrays and an output-capacity failure. See the [benchmark guide](benchmarks/r/remove_element/README.md) and [verifier](benchmarks/verify_remove_element.py). C candidate `27` uses the alphabetic benchmark name, and Ruby candidate `remove_elements` aliases it. Upstream references: [C LeetCode 27](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/27.c) and [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/remove_elements.rb).


## Divide Two Integers

The pinned C LeetCode 29 source doubles the divisor to subtract power-of-two multiples and truncates the quotient toward zero. The portable ports widen signed 32-bit values, avoid signed overflow at the minimum integer, and saturate the result at the signed 32-bit maximum. All nine ports passed 42,512 oracle inputs each and recorded 12 workload cases. See the [benchmark guide](benchmarks/d/divide_two_integers/README.md) and [verifier](benchmarks/verify_divide_two_integers.py). The numeric source stem `29` is cataloged as `divide_two_integers`. Upstream reference: [C LeetCode 29](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/29.c).

## String Search by Brute Force

C LeetCode 28 defines `strStr` twice: an initial brute-force scan and a second KMP implementation. The second maps to the existing KMP benchmark; the first now has its own portable benchmark. The C++ candidates `brute_force_string_searching.cpp` implement the same first-match direct scan and map to this benchmark. All nine ports passed 4,504 oracle inputs each and recorded 10 workload cases, including a maximum-length near-match. See the [benchmark guide](benchmarks/s/str_str_brute_force/README.md) and [verifier](benchmarks/verify_str_str_brute_force.py). Upstream reference: [C LeetCode 28](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/28.c).


## Swap Nodes in Pairs

The pinned C LeetCode 24 source recursively swaps adjacent linked-list nodes and leaves an odd final node in place. The shared array ABI preserves list order as input and emits pair-swapped values as little-endian signed 32-bit integers. All nine ports passed 20,309 oracle inputs each and recorded 10 workload cases, including maximum-length lists and insufficient output capacity. See the [benchmark guide](benchmarks/s/swap_pairs/README.md) and [verifier](benchmarks/verify_swap_pairs.py). The numeric source stem `24` is cataloged under the alphabetic benchmark name `swap_pairs`. Upstream reference: [C LeetCode 24](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/24.c).


## Longest Valid Parentheses

The pinned C LeetCode 32 source uses a memoized endpoint recurrence for the longest well-formed contiguous parenthesis substring. The nine portable ports evaluate that recurrence bottom-up on ASCII parenthesis values. The C LeetCode 42 source uses prefix and suffix maximum heights and is reviewed as an alias of `trapped_rainwater`; the shared contract defines empty input safely. See [`benchmarks/l/longest_valid_parentheses/README.md`](benchmarks/l/longest_valid_parentheses/README.md).


## Reverse Integer

C LeetCode candidate 7 reverses decimal digits by repeatedly popping the final digit and checking signed 32-bit bounds before each multiply-and-add. The nine portable ports preserve that procedure; overflow returns zero. The shared contract defines a distinct error sentinel for values outside the source domain. See [`benchmarks/r/reverse_integer/README.md`](benchmarks/r/reverse_integer/README.md).


## Count Segments in a String

C LeetCode candidate 434 scans a string and counts each transition from ASCII space to a non-space character; tabs and other bytes do not delimit segments. Nine portable ports use the same one-pass rule with explicit lengths. See [`benchmarks/c/count_segments/README.md`](benchmarks/c/count_segments/README.md).


## Detect Capital Usage

C LeetCode candidate 520 contains two `detectCapitalUse` definitions: an O(n) uppercase-count method and an alternative that rechecks the whole word for every uppercase character after the first. Both algorithms now have separate contracts and nine-language ports, since their work differs substantially despite returning the same classification. The original file's repeated definition is not compiled directly. See [`detect_capital_usage`](benchmarks/d/detect_capital_usage/README.md) and [`detect_capital_usage_scan`](benchmarks/d/detect_capital_usage_scan/README.md).


## Find the Difference

C LeetCode candidate 389 sums character codes for two lowercase strings and subtracts the source sum from the target sum. The target contract requires a permutation with one additional character. Nine portable ports use a packed, length-prefixed array and the same linear-time sum method. See [`benchmarks/f/find_the_difference/README.md`](benchmarks/f/find_the_difference/README.md).

## Jewels and Stones

C LeetCode candidate 771 builds a frequency lookup from the jewel string, then totals lookup values for the stone string. The shared contract makes the source constraints explicit: jewels are unique, all bytes are nonzero ASCII, and lengths are bounded. Nine portable ports use the lookup-table method. See [`benchmarks/j/jewels_and_stones/README.md`](benchmarks/j/jewels_and_stones/README.md).

## Array Pair Sum

C LeetCode candidate 561 sorts the input and sums the smaller value from each adjacent pair. The shared contract accepts even-length arrays of signed 32-bit values, keeps the input read-only, and uses a local copy with portable heapsort in each language. All nine ports passed 16,832 sorting-oracle inputs each and recorded 13 workload cases. See the [benchmark guide](benchmarks/a/array_pair_sum/README.md) and [verifier](benchmarks/verify_array_pair_sum.py). Upstream reference: [C LeetCode 561](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/561.c).

## Permutation in String

C LeetCode candidate 567 maintains letter-count differences between the pattern and the current text window, then updates only the outgoing and incoming letters as the window slides. The JavaScript `PermutationinString` candidate compares the same 26-letter windows and is recorded as an alias. The shared contract accepts packed lowercase ASCII strings up to 1,024 characters and returns whether a pattern permutation occurs contiguously in the text. All nine ports passed 15,175 independent window-oracle inputs each and recorded 20 workload cases. See the [benchmark guide](benchmarks/p/permutation_in_string/README.md) and [verifier](benchmarks/verify_permutation_in_string.py). Upstream references: [C LeetCode 567](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/567.c) and [JavaScript PermutationinString](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/Sliding-Window/PermutationinString.js).

## Rotate Array

C LeetCode candidate 189 rotates right by repeatedly moving the last value to the front and shifting the rest one place. The nine ports keep the input unchanged and return the result as little-endian signed 32-bit values. All nine ports passed 9,697 independent rotation-oracle inputs each and recorded 17 workload cases, including empty and maximum-length arrays, repeated rotations, signed boundaries, invalid inputs, and insufficient output capacity. See the [benchmark guide](benchmarks/r/rotate_array/README.md) and [verifier](benchmarks/verify_rotate_array.py). Upstream reference: [C LeetCode 189](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/189.c).

## Rotate Array by Reversal

The pinned Python `rotate_array` source normalizes positive and negative steps, then reverses the entire array, the rotated prefix, and the remaining suffix. This linear-time strategy is distinct from C LeetCode 189’s repeated one-place shifts, so it has a separate benchmark. All nine ports passed 17,771 independent rotation-oracle inputs each and recorded 19 workload cases, including negative steps and signed boundaries. See the [benchmark guide](benchmarks/r/rotate_array_reversal/README.md) and [verifier](benchmarks/verify_rotate_array_reversal.py). Upstream reference: [Python rotate_array.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/rotate_array.py).

## Intersection of Two Linked Lists

C LeetCode candidate 160 advances two list pointers and switches each pointer to the other head after reaching the end. The packed benchmark represents node identity with nonnegative IDs and requires intersecting lists to have the same shared suffix. All nine ports passed 2,561 independent identity-oracle inputs each and recorded 20 workload cases, including empty lists, shared tails, no intersection, maximum list lengths, and malformed packed inputs. See the [benchmark guide](benchmarks/i/intersection_of_two_linked_lists/README.md) and [verifier](benchmarks/verify_intersection_of_two_linked_lists.py). Upstream reference: [C LeetCode 160](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/160.c).

## BST Iterator

C LeetCode candidate 173 eagerly materializes a BST in ascending in-order order, then serves values through `hasNext` and `next`. The shared indexed-tree contract records the iterator's full value sequence as an order-sensitive checksum. All nine portable ports passed 2,585 independent tree-oracle inputs each and recorded 11 workload cases, including empty and singleton trees, shuffled node IDs, signed boundaries, malformed tables, and a 1,023-node chain. See the [BST Iterator guide](benchmarks/b/bst_iterator/README.md) and [verifier](benchmarks/verify_bst_iterator.py). Upstream reference: [C LeetCode 173](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/173.c).

## Range Bitwise AND

C LeetCode candidate 201 repeatedly clears the lowest set bit of the upper range endpoint until it reaches the lower endpoint. The benchmark accepts inclusive ranges from 0 through 2,147,483,647 and returns -1 for invalid bounds. All nine portable ports passed 75,437 independent common-prefix oracle pairs each and recorded 15 workload cases. See the [Range Bitwise AND guide](benchmarks/r/range_bitwise_and/README.md) and [binary scalar verifier](benchmarks/verify_binary_scalar.py). Upstream reference: [C LeetCode 201](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/201.c).

## Remove Linked List Elements

C LeetCode candidate 203 recursively removes every node whose value matches the target and returns the updated list head. The nine portable ports preserve that recursive link-rewrite behavior with an index-based node pool and serialize surviving signed 32-bit values in list order. All nine ports passed 20,318 oracle inputs each and recorded nine workload cases, including a 1,024-node recursion case, signed boundaries, invalid values, and insufficient output capacity. See the [benchmark guide](benchmarks/r/remove_linked_list_elements/README.md) and [verifier](benchmarks/verify_remove_linked_list_elements.py). Upstream reference: [C LeetCode 203](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/203.c).

## Delete Middle Node

C LeetCode candidate 2095 counts nodes, advances fast and slow pointers, then uses the length parity to unlink node `floor(n / 2)`; an empty or singleton list yields an empty list. The nine portable ports preserve the count pass, two-pointer traversal, unlink, and ordered signed 32-bit serialization using an index-based link pool. All nine passed 20,312 oracle inputs each and recorded nine workload cases, including empty and singleton inputs, odd and even lengths, signed boundaries, invalid values, and insufficient output capacity. See the [benchmark guide](benchmarks/d/delete_middle_node/README.md) and [verifier](benchmarks/verify_delete_middle_node.py). Upstream reference: [C LeetCode 2095](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2095.c).

## Remove All Duplicates from Sorted List

C LeetCode candidate 82 recursively skips every run of repeated values and relinks singleton nodes to the recursively processed suffix. The nine portable ports preserve that recursive behavior with an index-based node chain. All nine passed 1,246 oracle inputs each and recorded nine workload cases, including empty and singleton lists, duplicate runs, sortedness errors, signed boundaries, maximum length, and insufficient output capacity. See the [benchmark guide](benchmarks/r/remove_all_duplicates_from_sorted_list/README.md) and [verifier](benchmarks/verify_remove_all_duplicates_from_sorted_list.py). Upstream reference: [C LeetCode 82](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/82.c).

## Remove Duplicates from Sorted List

C LeetCode candidate 83 assumes ascending input and walks current/next nodes, unlinking each later node when its value matches the current node. The nine portable ports preserve this in-place link update using an index-based node chain. All nine passed 1,244 oracle inputs each and recorded nine workload cases, including empty and singleton lists, duplicate runs, sortedness errors, signed boundaries, maximum length, and insufficient output capacity. See the [benchmark guide](benchmarks/r/remove_duplicates_from_sorted_list/README.md) and [verifier](benchmarks/verify_remove_duplicates_from_sorted_list.py). Upstream reference: [C LeetCode 83](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/83.c).

## Move Zeroes

C LeetCode candidate 283 and Dart `move_zeroes` both stably compact nonzero values, then fill the remaining array positions with zero. The C candidate supplies the canonical numeric-source mapping; Dart is cataloged as a semantic alias. All nine portable ports passed 10,622 oracle inputs each and recorded nine workload cases, including signed 32-bit boundaries, invalid values, maximum-length arrays, and insufficient output capacity. See the [benchmark guide](benchmarks/m/move_zeroes/README.md) and [verifier](benchmarks/verify_move_zeroes.py). Upstream references: [C LeetCode 283](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/283.c) and [Dart `move_zeroes`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/array/move_zeroes.dart).

## Add Two Numbers

C LeetCode candidate 2 and JavaScript `AddTwoNumbers` both add digit lists stored least-significant first, propagating carries as they traverse. The benchmark keeps each list's supplied digit count, returns an empty list for two empty operands, and serializes each result digit as one byte. All nine portable ports passed 8,009 oracle inputs each and recorded nine workload cases, including empty operands, unequal list lengths, long carry chains, invalid values, and insufficient output capacity. See the [benchmark guide](benchmarks/a/add_two_numbers/README.md) and [verifier](benchmarks/verify_add_two_numbers.py). Upstream references: [C LeetCode 2](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2.c) and [JavaScript `AddTwoNumbers`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Linked-List/AddTwoNumbers.js).

## Reverse String In Place

C LeetCode candidate 344 swaps bytes from the ends toward the middle. The shared benchmark preserves that two-pointer mutation algorithm with a byte-array input and separate output buffer, covering all byte values including embedded zeroes. All nine ports passed 6,243 oracle inputs each and recorded nine workload cases. See the [benchmark guide](benchmarks/r/reverse_string_in_place/README.md) and [verifier](benchmarks/verify_reverse_string_in_place.py). Upstream reference: [C LeetCode 344](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/344.c).


## Number of Ways to Select Buildings

C LeetCode candidate 2222 counts length-three `010` and `101` subsequences with two linear scans. The shared contract uses binary ASCII values and allows strings up to 4,096 characters. All nine portable ports passed 8,705 independent subsequence-oracle inputs each and recorded eight workload cases. See the [benchmark guide](benchmarks/n/number_of_ways_to_select_buildings/README.md) and [verifier](benchmarks/verify_number_of_ways_to_select_buildings.py). Upstream reference: [C LeetCode 2222](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2222.c).


## Rectangle Union Area

C LeetCode candidate 223 computes the area of both rectangles and subtracts the area of their intersection. The shared contract accepts two valid axis-aligned rectangles with coordinates bounded to ±1,000,000,000. All nine portable ports passed 10,526 independent clipping-oracle inputs each and recorded eight workload cases. See the [benchmark guide](benchmarks/r/rectangle_union_area/README.md) and [verifier](benchmarks/verify_rectangle_union_area.py). Upstream reference: [C LeetCode 223](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/223.c).


## Minimum Average Difference

C LeetCode candidate 2256 sums the values, then scans prefix splits and compares truncated integer averages. The shared contract accepts 1 through 100,000 values in the range 0 through 100,000 and preserves first-index ties. All nine portable ports passed 22,367 independent prefix/suffix-oracle inputs each and recorded seven workload cases. See the [benchmark guide](benchmarks/m/minimum_average_difference/README.md) and [verifier](benchmarks/verify_minimum_average_difference.py). Upstream reference: [C LeetCode 2256](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2256.c).


## Invert Binary Tree

C LeetCode candidate 226 recursively exchanges each node’s left and right child links. PHP `invert_binary_tree` and Python `mirror_binary_tree` use the same operation and are cataloged as aliases. The shared indexed-tree ABI emits every mirrored node triplet in a portable little-endian format. All nine language ports passed 716 independent tree-oracle inputs each and recorded nine workload cases. See the [benchmark guide](benchmarks/i/invert_binary_tree/README.md) and [verifier](benchmarks/verify_invert_binary_tree.py). Upstream references: [C LeetCode 226](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/226.c), [PHP `InvertBinaryTree`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/InvertBinaryTree/InvertBinaryTree.php), and [Python `mirror_binary_tree`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/mirror_binary_tree.py).

## Ways to Split Array

C LeetCode candidate 2270 sums the values, then scans each valid split and counts positions where the left sum is at least the right sum. The shared contract accepts 2 through 100,000 signed values in -100,000..100,000. All nine portable ports use 64-bit sums and two linear scans with constant auxiliary space. They passed 20,046 independent oracle inputs each and recorded seven workload cases. See the [benchmark guide](benchmarks/w/ways_to_split_array/README.md) and [verifier](benchmarks/verify_ways_to_split_array.py). Upstream reference: [C LeetCode 2270](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2270.c).

## Maximum Bags With Full Capacity

C LeetCode candidate 2279 computes each bag’s remaining capacity, sorts those deficits, and fills the smallest gaps first. The shared ABI packs the budget, bag count, capacities, and rocks, with up to 8,191 bags so the fixed work array stays below C3’s 64 KiB stack-object limit. All nine portable ports passed 10,373 independent oracle inputs each and recorded thirteen workload cases. See the [benchmark guide](benchmarks/m/maximum_bags_with_full_capacity/README.md) and [verifier](benchmarks/verify_maximum_bags_with_full_capacity.py). Upstream reference: [C LeetCode 2279](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2279.c).

## Minimum Path Cost in a Grid

C LeetCode candidate 2304 uses row-by-row dynamic programming to minimize each next-column path cost, then adds the final cell value. The shared contract packs a rectangular grid and its complete move-cost table, with dimensions up to 32 by 32. All nine portable ports passed 959 independent oracle inputs each and recorded thirteen workload cases. See the [benchmark guide](benchmarks/m/minimum_path_cost_in_grid/README.md) and [verifier](benchmarks/verify_minimum_path_cost_in_grid.py). Upstream reference: [C LeetCode 2304](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2304.c).

## Ones Minus Zeros

C LeetCode candidate 2482 counts ones by row and column, then computes each output cell from those counts. The pinned source uses the wrong opposite dimension for zero counts on rectangular matrices, so the shared contract follows the stated row/column formula and checks nonsquare cases. The contract supports up to 100,000 cells and writes signed 32-bit little-endian outputs. All nine portable ports reuse the output buffer for counts, run in linear time, and avoid processor-specific optimizations. They passed 917 independent oracle matrices each and recorded 13 workload cases, including a full 100,000-cell matrix. See the [benchmark guide](benchmarks/o/ones_minus_zeros/README.md) and [verifier](benchmarks/verify_ones_minus_zeros.py). Upstream reference: [C LeetCode 2482](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2482.c).

## Longest Square Streak

C LeetCode candidate 2501 finds the longest chain in which each next value is the square of its predecessor. The shared contract supports 2 to 100,000 values in 2..100,000 and supplies a 400,004-byte workspace for membership and memoized chain lengths. The nine portable implementations passed 1,306 independent oracle arrays each and recorded 11 workload cases, including the full input bound and maximum value. See the [benchmark guide](benchmarks/l/longest_square_streak/README.md) and [verifier](benchmarks/verify_longest_square_streak.py). Upstream reference: [C LeetCode 2501](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2501.c).

## H-Index

C LeetCode candidate 274 sorts citations and scans from largest to smallest. Since the shared array-scalar ABI is read-only, all nine ports instead binary-search the possible H-index and count citations meeting each midpoint. They accept 0 to 5,000 citation counts in 0..1,000, return 0 for empty input, reject invalid input with -1, and leave the array unchanged. The nine implementations passed 2,039 independent oracle arrays each and recorded 14 workload cases. See the [benchmark guide](benchmarks/h/h_index/README.md) and [verifier](benchmarks/verify_h_index.py). Upstream reference: [C LeetCode 274](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/274.c).

## First Bad Version

C LeetCode candidate 278 uses binary search over a monotone `isBadVersion` predicate. The benchmark takes the first bad version as input so the predicate can be evaluated portably without an external API. Its nine implementations passed 9,105 boundary and oracle pairs each and recorded 15 workload cases, including the maximum 32-bit version count. See the [benchmark guide](benchmarks/f/first_bad_version/README.md) and [shared verifier](benchmarks/verify_binary_scalar.py). Upstream reference: [C LeetCode 278](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/278.c).

## Find the Duplicate Number

C LeetCode candidate 287 sorts the array, while the benchmark follows the problem's required linear-time, constant-space, read-only contract with Floyd's cycle-entry algorithm. The pinned C and C++ `floyd_cycle_detection` implementations use that same cycle-entry method on the valid duplicate-number domain and are cataloged as aliases. The nine ports passed 17,733 independent frequency-oracle arrays each and recorded 12 workload cases, including the maximum 100,001-value input. See the [benchmark guide](benchmarks/f/find_duplicate_number/README.md) and [verifier](benchmarks/verify_find_duplicate_number.py). Upstream references: [C LeetCode 287](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/287.c), [C `floyd_cycle_detection_algorithm.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/searching/floyd_cycle_detection_algorithm.c), and [C++ `floyd_cycle_detection_algo.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/search/floyd_cycle_detection_algo.cpp); [problem statement](https://leetcode.com/problems/find-the-duplicate-number/).

## Palindrome Linked List

C LeetCode candidate 234 uses slow/fast pointers, reverses the second half of the list, then compares values. The shared value-array ABI allows the nine ports to compare symmetric entries directly with constant extra space and no mutation. They passed 10,656 exhaustive/randomized oracle arrays each and recorded 11 workload cases, including a 100,000-value palindrome. See the [benchmark guide](benchmarks/p/palindrome_linked_list/README.md) and [verifier](benchmarks/verify_palindrome_linked_list.py). Upstream reference: [C LeetCode 234](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/234.c); [problem statement](https://leetcode.com/problems/palindrome-linked-list/).


## Longest Palindromic Substring

C LeetCode candidate 5 uses center expansion for odd and even palindromes. The nine portable ports preserve leftmost tie behavior and use caller-provided output storage. They passed 1,038 independent oracle inputs and recorded 15 workload cases each. See the [benchmark guide](benchmarks/l/longest_palindromic_substring/README.md) and [verifier](benchmarks/verify_longest_palindromic_substring.py). Upstream reference: [C LeetCode 5](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/5.c).

## Longest Word in a Sentence

The pinned Python source splits on whitespace and selects the first word with maximum length. The shared portable contract covers printable ASCII words and ASCII whitespace; all nine ports passed 9,866 independent inputs and recorded 10 workload cases. See the [benchmark guide](benchmarks/l/longest_word_in_sentence/README.md), [verifier](benchmarks/verify_longest_word_in_sentence.py), and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/longest_word_in_sentence.py).

## Wave String

The pinned Python routine emits one full-string variant for each alphabetic character, uppercasing only the selected position. The portable contract uses printable ASCII and length-prefixed byte strings. All nine ports passed 9,861 oracle inputs each and recorded 11 workload cases, including maximum output size. See the [guide](benchmarks/w/wave_string/README.md), [verifier](benchmarks/verify_wave_string.py), and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/wave_string.py).

## Collatz Sequence Length

The pinned C and Dart candidates generate the sequence by halving even values and applying 3n+1 to odd values. The benchmark returns the transition count to 1 for inputs from 1 through 1,000,000. All nine ports passed 66,022 oracle inputs per language and recorded 14 workload cases. An exhaustive trace of the supported range found a maximum stopping time of 524 and maximum intermediate value of 56,991,483,520. See the [benchmark guide](benchmarks/c/collatz/README.md) and shared [scalar verifier](benchmarks/verify_scalar.py). Upstream references: [C candidate](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/collatz.c), [Dart candidate](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/other/collatz.dart).

## Factorial Trailing Zeroes

The C and C++ candidates both count factors of five in n! to determine its decimal trailing-zero count. The nine ports passed 10,545 oracle inputs per language and recorded 16 workload cases. C++ `count_of_trailing_ciphers_in_factorial_n` aliases the C candidate's shared contract. See the [benchmark guide](benchmarks/f/factorial_trailing_zeroes/README.md) and shared [scalar verifier](benchmarks/verify_scalar.py). Upstream references: [C candidate](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/factorial_trailing_zeroes.c), [C++ candidate](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/bit_manipulation/count_of_trailing_ciphers_in_factorial_n.cpp).

## Binary Count Trailing Zeros

The Python, Rust, and Ruby candidates count the low-order zero bits in an integer. The shared contract maps zero to 0 and negative inputs to -1, standardizing differences in the source edge cases. All nine ports passed 66,197 oracle inputs per language and recorded 13 workload cases. See the [benchmark guide](benchmarks/b/binary_count_trailing_zeros/README.md) and shared [scalar verifier](benchmarks/verify_scalar.py). Upstream references: [Python candidate](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/binary_count_trailing_zeros.py), [Rust candidate](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/bit_manipulation/binary_count_trailing_zeros.rs), [Ruby spelling variant](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/bit_manipulation/binary_count_trailing_zeroes.rb).

## Trailing Zeroes in an Integer

The pinned Python source repeatedly divides the input by ten while its final decimal digit is zero. This differs from counting zeroes in a factorial: zero returns 1, positive inputs return the count of final zero digits, and negative inputs return -1. All nine ports passed 11,585 oracle inputs each and recorded 11 workload cases. See the [benchmark guide](benchmarks/t/trailing_zeroes/README.md) and shared [scalar verifier](benchmarks/verify_scalar.py). Upstream reference: [Python `trailing_zeroes.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/trailing_zeroes.py).

## 3Sum

The pinned Ruby source sorts a copy, skips repeated first values, then scans with two pointers to emit unique zero-sum triplets. All nine target-language ports passed 4,175 oracle inputs each and recorded 12 workload cases. See the [benchmark guide](benchmarks/0-9/3sum/README.md).

## Count and Say

C LeetCode candidate 38 generates each term by describing maximal equal-digit runs in the preceding term. The shared contract supports indices 1 through 19 and bounded ASCII byte output. See the [benchmark guide](benchmarks/c/count_and_say/README.md).

## Zigzag Conversion

C LeetCode candidate 6 emits text row by row, alternating vertical and diagonal gaps for interior rows. The benchmark bounds its row count and ASCII-letter input and provides all nine portable ports. See the [benchmark guide](benchmarks/z/zigzag_conversion/README.md).

## Longest Continuous Increasing Subsequence

C LeetCode candidate 674 scans adjacent values to find the longest strictly increasing contiguous run. The Rust filename candidate has matching semantics and is recorded as an alias. All nine ports passed 10,114 oracle inputs and recorded 15 workload cases. See the [benchmark guide](benchmarks/l/longest_continuous_increasing_subsequence/README.md).

## Peak Index in a Mountain Array

C LeetCode candidate 852 intends a binary search on adjacent mountain values but can read beyond the final element. The ports use a safe binary search on the slope and accept strict mountain arrays. All nine passed 1,373 oracle inputs and recorded 13 workload cases. See the [benchmark guide](benchmarks/p/peak_index_in_mountain_array/README.md).

## Sort Array by Parity

C LeetCode candidate 905 writes even values forward and odd values backward from the output end. The shared contract preserves even order and reverses odd order, producing repeatable output in all nine languages. The ports passed 5,985 oracle inputs and recorded 12 workload cases. See the [benchmark guide](benchmarks/s/sort_array_by_parity/README.md).

## Squares of a Sorted Array

C LeetCode candidate 977 uses a two-pointer scan to place squared endpoints from right to left. The benchmark follows its nondecreasing-input contract and emits signed 64-bit results. All nine ports passed 3,949 oracle inputs and recorded 13 workload cases. See the [benchmark guide](benchmarks/s/squares_of_a_sorted_array/README.md).

## Middle of Linked List

The C middle_element_in_list demo also uses fast and slow pointers and selects the second middle for even-length lists; it aliases this contract, which returns the selected node index rather than its payload. C LeetCode candidate 876 uses fast and slow pointers and returns the second middle for even-length lists. The portable successor-index representation lets the nine language ports share explicit bounds, cycle, and malformed-edge behavior. See the [benchmark guide](benchmarks/m/middle_of_linked_list/README.md).

## Reverse Only Letters

C LeetCode candidate 917 skips nonletters at both ends and swaps ASCII letters inward. The shared contract fixes letter classification to ASCII and preserves other printable bytes at their original positions. See the [benchmark guide](benchmarks/r/reverse_only_letters/README.md) and [verifier](benchmarks/verify_reverse_only_letters.py).

## Find All Duplicates in an Array

C LeetCode candidate 442 sorts the array, then collects each repeated adjacent value once. The contract follows the source problem's at-most-twice value bound and returns duplicates in ascending order. All nine ports passed 32,482 oracle inputs and recorded 12 workload cases. See the [benchmark guide](benchmarks/f/find_all_duplicates_in_array/README.md).

## Unique Paths II

C LeetCode candidate 63 counts paths through a grid with blocked cells. The nine ports compress the source's top/left recurrence to one row; the packed grid contract is bounded to 20 rows and columns so results fit signed 64-bit. All nine passed 1,196 oracle inputs and recorded 20 workload cases. See the [benchmark guide](benchmarks/u/unique_paths_with_obstacles/README.md).

## String to Integer

C LeetCode candidate 8 parses leading ASCII spaces, an optional sign, and the initial decimal digit run, then clamps to signed 32-bit bounds. The nine ports use a bounded byte-array contract with explicit empty and invalid-byte behavior. See the [benchmark guide](benchmarks/s/string_to_integer/README.md).

## Split

The pinned Python and F# split scans agree on empty input or nonempty ASCII text containing one separator and not ending with it; leading and adjacent separators preserve empty fields. The bounded package encodes the resulting fields as length-prefixed bytes. See the [benchmark guide](benchmarks/s/split/README.md).

## Shortest Word Distance

The pinned Ruby routine returns the minimum absolute distance between occurrences of two distinct words. The benchmark requires both lowercase ASCII targets to appear in the bounded word list; same-word and missing-word inputs return 0 in Ruby and are excluded. See the [benchmark guide](benchmarks/s/shortest_word_distance/README.md).

## Character-Array Left Rotation

The pinned Java overload mutates its character array using three reversals; its bounded benchmark returns the rotated ASCII bytes. It is separate from Java's allocating string overload and Python's affine image rotation. See the [benchmark guide](benchmarks/c/char_array_left_rotation/README.md).

The pinned Java `Rotation.rotation(String, int)` returns `s.substring(n) + s.substring(0, n)`. The [`string_left_rotation` guide](benchmarks/s/string_left_rotation/README.md) measures UTF-16 code-unit rotation and serializes the result as little-endian 16-bit units, including lone surrogates and rotations that split surrogate pairs. Its ABI probes cover null and short output buffers, with empty output succeeding for a null pointer. See the [workload](benchmarks/s/string_left_rotation/workload.json) and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/Rotation.java).

The pinned Python `get_rotation` estimates a three-point affine map and calls `cv2.warpAffine` with destination size `(rows, cols)`, which OpenCV interprets as `(width, height)`. The [`affine_image_rotation` guide](benchmarks/a/affine_image_rotation/README.md) preserves the resulting `(cols, rows)` output shape and bounds the map to exact integer unimodular transforms so interpolation samples the integer pixel lattice; output is raw grayscale bytes with zero border fill. See the [workload](benchmarks/a/affine_image_rotation/workload.json) and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/rotation/rotation.py).

The pinned recursive C++ list reversal descends to the tail and rewires each predecessor link while the calls unwind. [`reverse_a_linked_list_using_recusion`](benchmarks/r/reverse_a_linked_list_using_recusion/README.md) bounds the source's two-node minimum to 64 nodes and returns the reversed signed-i32 values as little-endian bytes. [C++ source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/operations_on_datastructures/reverse_a_linked_list_using_recusion.cpp).

The pinned Java `rotateRight` method forms a temporary circular list, advances to the new tail, and cuts the circle. [`rotate_singly_linked_lists`](benchmarks/r/rotate_singly_linked_lists/README.md) covers nonnegative Java-int rotation counts and encodes the rotated values with a count prefix. [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/RotateSinglyLinkedLists.java).

The pinned C `deletion(pos)` operation unlinks the head or the selected node after its predecessor. [`singly_link_list_deletion`](benchmarks/s/singly_link_list_deletion/README.md) bounds the list to 64 nodes and returns surviving signed-i32 values as little-endian bytes. [C source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/linked_list/singly_link_list_deletion.c).

The pinned C `merge()` operation alternately splices nodes from a second list between nodes of the first; it does not sort values. [`merge_linked_lists`](benchmarks/m/merge_linked_lists/README.md) encodes traversal from the possibly-spliced first head as signed-i64 bytes. An empty first list produces an empty traversal. [C source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/linked_list/merge_linked_lists.c).

The pinned R `iddfs()` normalizes named adjacency to vertices `1..max`, preserves neighbor order, and repeats depth-limited DFS while avoiding cycles on the current path. [`iddfs`](benchmarks/i/iddfs/README.md) returns the first shallowest path or a not-found record as little-endian signed-i64 fields. [R source](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/graph_algorithms/iddfs.r).

The pinned Java and Python power functions both use linear recursion, multiplying by the base until the exponent reaches zero. [`power_using_recursion`](benchmarks/p/power_using_recursion/README.md) bounds inputs to small integers so both source return types produce the same exact integral result. [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PowerUsingRecursion.java), [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/power_using_recursion.py).

The pinned Java slack scheduler stably sorts tasks by deadline minus execution time and returns task names in that order. [`slack_time_scheduling`](benchmarks/s/slack_time_scheduling/README.md) uses stable input indices to represent task identities and does not simulate execution. [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/SlackTimeScheduling.java).

The pinned Fortran and Ruby routines recursively search an integer array. [`recursive_linear_search`](benchmarks/r/recursive_linear_search/README.md) restricts values to distinct signed-i32 integers and reports a zero-based index, normalizing the Fortran source's one-based result. [Fortran source](https://github.com/TheAlgorithms/Fortran/blob/c91199703b78bd2181051b01bd5269740e41e121/modules/searches/recursive_linear_search.f90), [Ruby source](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/searches/recursive_linear_search.rb).

## Find the Town Judge

C LeetCode candidate 997 counts incoming and outgoing trust edges and selects the unique person trusted by all others who trusts nobody. The portable flattened edge-list contract validates bounds, self-trust, and duplicate pairs. See the [benchmark guide](benchmarks/f/find_the_town_judge/README.md).

## Redundant Connection

C LeetCode candidate 684 uses disjoint sets to find the unique edge that closes the cycle in a tree plus one edge. The contract preserves endpoint order and encodes the pair as little-endian signed 32-bit values. All nine ports passed 632 prefix-BFS oracle inputs and recorded 11 workload cases. See the [benchmark guide](benchmarks/r/redundant_connection/README.md).

## Minimum Falling Path Sum

C LeetCode candidate 931 uses row dynamic programming, taking the minimum of the same or adjacent columns from the preceding row before adding the current cell. The shared packed contract supports square matrices of size 1 through 100 with values from -100 through 100. The nine ports, workload, and guide are present; All nine ports passed 19,973 oracle cases each and recorded six workload cases. See the [benchmark guide](benchmarks/m/minimum_falling_path_sum/README.md) and [verifier](benchmarks/verify_minimum_falling_path_sum.py).

## Palindromic Substrings

C LeetCode candidate 647 expands around odd and even centers and counts each palindromic occurrence separately. All nine ports passed 3,542 interval-oracle inputs and recorded 13 workload cases. See the [benchmark guide](benchmarks/p/palindromic_substrings/README.md).

## Range Sum of BST

C LeetCode candidate 938 adds each node value in the inclusive query interval and visits both children at every node, even though the tree is ordered. The indexed-tree contract supports up to 1,023 nodes. All nine ports passed 801 tree/range oracle inputs and recorded 19 workload cases. See the [benchmark guide](benchmarks/r/range_sum_bst/README.md).

## Max Increase to Keep City Skyline

C LeetCode candidate 807 computes row and column maxima, then adds the smaller allowable increase for each cell. The square-grid contract supports dimensions 2 through 50 and heights from 0 through 100. All nine ports passed 20,302 oracle grids and recorded 14 workload cases. See the [benchmark guide](benchmarks/m/max_increase_keeping_skyline/README.md).

## Kth Smallest in BST

C LeetCode candidate 230 performs in-order traversal, decrementing the requested rank and stopping when it reaches zero. The nine ports passed 4,295 inorder-oracle inputs and recorded 15 workload cases. See the [benchmark guide](benchmarks/k/kth_smallest_bst/README.md).

## Keys and Rooms

C LeetCode candidate 841 runs depth-first search from room zero and checks whether all rooms were visited. The shared flattened adjacency-list contract allows duplicate keys; the nine ports passed 1,028 oracle graphs and recorded 15 workload cases. See the [benchmark guide](benchmarks/k/keys_and_rooms/README.md).

## Lowest Common Ancestor of a Binary Tree

C LeetCode candidate 236 builds root-to-target paths for p and q and returns their longest common prefix. The indexed-tree contract returns an ancestor node index and requires distinct, uniquely valued targets. The nine source ports, guide, and workload are present; runtime compilation and verifier execution remain pending. See the [benchmark guide](benchmarks/l/lowest_common_ancestor/README.md).

## Validate Binary Search Tree

C LeetCode candidate 98 checks each node against strict lower and upper bounds inherited from its ancestors. The nine ports passed 2,820 independent in-order-oracle inputs and recorded 14 workload cases. See the [benchmark guide](benchmarks/v/validate_bst/README.md).

## Binary Tree Inorder Traversal

C LeetCode candidate 94 recursively visits the left subtree, current node, then right subtree and writes the values to caller-owned storage. All nine ports passed 690 traversal-oracle inputs and recorded 13 workload cases. See the [benchmark guide](benchmarks/b/binary_tree_inorder_traversal/README.md).

## Verifying an Alien Dictionary

C LeetCode candidate 953 assigns each lowercase letter its rank in the supplied alphabet, then compares adjacent words at their first difference. The source accepts equal words and uses the shorter-prefix rule. Nine source ports, a guide, and a workload are present; runtime compilation and independent verification remain pending. See the [benchmark guide](benchmarks/v/verifying_an_alien_dictionary/README.md).

## Sum of Even Numbers After Queries

C LeetCode candidate 985 maintains the even-value sum while applying each delta/index update and emits the sum after every query. The ports preserve source mutation semantics using private working storage under the shared read-only input ABI. All nine passed 7,967 recomputing-oracle inputs and recorded 16 workload cases. See the [benchmark guide](benchmarks/s/sum_even_after_queries/README.md).

## Online Stock Span

C LeetCode candidate 901 pops prior prices less than or equal to the current price from a monotone stack, then uses the nearest greater price to calculate the span. All nine ports passed 5,733 oracle cases each and recorded 11 workload cases. See the [benchmark guide](benchmarks/o/online_stock_span/README.md) and [verifier](benchmarks/verify_online_stock_span.py).

## Merge Two Binary Trees

C LeetCode candidate 617 recursively creates a new tree, summing overlapping nodes and copying values where only one input has a node. The benchmark preserves heap positions through a bounded slot-array representation. Nine ports, a guide, a workload, and an independent oracle verifier are present; runtime compilation and verifier execution remain pending. See the [benchmark guide](benchmarks/m/merge_two_binary_trees/README.md).

## Search in a BST

C LeetCode candidate 700 follows the unique BST branch for the target and returns the matching node index, or `-1` when it is absent. All nine ports passed 1,559 oracle inputs and recorded 17 workload cases. See the [benchmark guide](benchmarks/s/search_in_bst/README.md) and [verifier](benchmarks/verify_search_in_bst.py).

## Sudoku Solver

C LeetCode candidate 37 uses row-major recursive backtracking with row, column, and 3×3-box occupancy masks. The ports place each trial digit before recursion and restore it after a failed branch, correcting the pinned source’s call-order bug. All nine passed 106 independent oracle inputs and recorded nine workload cases. See the [benchmark guide](benchmarks/s/sudoku_solver/README.md).

## Adaptive Merge Sort

The pinned Python source recursively sorts each half and skips the merge when the largest left value is already no greater than the smallest right value. Nine portable ports, a shared contract, and workload are present. See the [benchmark guide](benchmarks/a/adaptive_merge_sort/README.md).

## Adler-32

The pinned Python `adler32.py` source maintains two sums modulo 65,521 and packs them into one checksum. Nine portable byte-array ports, a workload, and an independent oracle verifier are present. See the [benchmark guide](benchmarks/a/adler32/README.md).

## Distribute Coins in Binary Tree

C LeetCode candidate 979 computes subtree excess in postorder and adds each child edge’s absolute coin flow. Python `distribute_coins` is reviewed as a semantic alias. All nine ports passed 5,221 independent oracle inputs and recorded 18 workload cases. See the [benchmark guide](benchmarks/d/distribute_coins/README.md).

## Pow(x, n)

C LeetCode candidate 50 uses repeated squaring for a binary64 base and signed 32-bit exponent, including the `INT32_MIN` reciprocal case. Nine portable ports, a shared workload, and a contract are present. See the [benchmark guide](benchmarks/p/powx_n/README.md).

## Triangular Number

The pinned Python `triangular_numbers.py` source exposes `triangular_number(position)` and computes `T(n) = n(n + 1) / 2`. The shared contract bounds positions so the result fits signed 64-bit output. Nine portable scalar ports and a workload are present. See the [benchmark guide](benchmarks/t/triangular_number/README.md).

## Trim a Binary Search Tree

C LeetCode candidate 669 recursively removes nodes outside an inclusive range, replacing an out-of-range node with the child subtree that may still contain valid values. The indexed-tree contract serializes retained nodes with compact preorder indexes. All nine ports passed 2,677 oracle cases and recorded 17 workload cases. See the [benchmark guide](benchmarks/t/trim_bst/README.md) and [verifier](benchmarks/verify_trim_bst.py).

## Word Search

C LeetCode candidate 79 searches orthogonal neighbors with depth-first backtracking and prevents a cell from appearing twice in one path. The packed rectangular-board contract preserves case-sensitive ASCII letters. All nine ports passed 5,127 oracle inputs and recorded 21 workload cases. See the [benchmark guide](benchmarks/w/word_search/README.md) and [verifier](benchmarks/verify_word_search.py).


## Buzz Number

The two pinned C++ candidates return true for values divisible by 7 or with a final decimal digit of 7. The signed 64-bit benchmark preserves their negative-remainder behavior across all nine ports. See the [benchmark guide](benchmarks/b/buzz_number/README.md).

## Almost Palindrome Checker

The Python source accepts a lowercase ASCII sequence if it is a palindrome or can become one after deleting one character. This remains distinct from punctuation-insensitive valid-palindrome checks. Nine portable ports and a workload are present. See the [benchmark guide](benchmarks/a/almost_palindrome_checker/README.md).

## Binary Addition

The benchmark performs right-to-left carry addition on two binary strings and preserves leading zeroes from the longer operand. C++ `binary_addition` is the canonical candidate and C++, Java, and TypeScript `add_binary` sources share its contract. Nine ports and a workload are present. See the [benchmark guide](benchmarks/b/binary_addition/README.md).


## Compute Totient

The pinned Rust source initializes a totient table, identifies primes, and updates their multiples from 2p. The shared benchmark emits phi(1) through phi(n) in ascending order as comma-separated ASCII. Nine portable ports and a workload are present. See the [benchmark guide](benchmarks/c/compute_totient/README.md).

## Euler Totient

The scalar benchmark computes phi(n) by prime factorization for `1 <= n <= 1,000,000`. Rust, TypeScript, Dart, JavaScript, Julia, C++, and Lua sources share this contract; the Lua implementation counts coprime values directly. Nine portable ports and a workload are present. See the [benchmark guide](benchmarks/e/euler_totient/README.md).

## Euler Totient Sequence

The C-Sharp sequence factors each integer independently and emits phi(1) through phi(n). The benchmark bounds prefixes at 80 and preserves that repeated-factorization method in all nine ports. See the [benchmark guide](benchmarks/e/euler_totient_sequence/README.md).

## Totients Linear Sieve

The Python `eulers_totient` source returns a sequence using the linear sieve. Nine ports use the conventional recurrence and the shared bounded sequence output. See the [benchmark guide](benchmarks/t/totients_linear_sieve/README.md).

## Count Inversions

The pinned C++ sources count strict inversions during bottom-up merge sort. The shared signed 64-bit array contract returns the count for lengths through 4,096 and `-1` for longer inputs; all nine ports use private merge buffers to match the read-only ABI. See the [benchmark guide](benchmarks/c/count_inversions/README.md).

## A* Search

The Python grid, C++ state-space, and R weighted-graph filename matches all implement A* search. The shared contract normalizes them to directed unit-cost graphs with consistent nonnegative heuristics and deterministic shortest-path selection; the Python `a_star` candidate aliases this path benchmark and its action-map output is outside the shared result. Nine language ports are present. See the [benchmark guide](benchmarks/a/a_star_search/README.md).

## Arithmetic Coding

The pinned Java compressor builds a byte-frequency model, sorts symbols, and narrows an arithmetic interval for every input symbol. The nine portable ports use exact rational interval updates and return a bounded integer representation of the final lower bound. See the [benchmark guide](benchmarks/a/arithmetic_coding/README.md).

## Arithmetic Decoding

The inverse benchmark takes the symbol-frequency model and exact encoded lower-bound numerator, then recovers the byte sequence by finding the matching half-open subinterval at each step. It ports the source's decompressor using integer comparisons. See the [benchmark guide](benchmarks/a/arithmetic_decoding/README.md).

## Acronym

The pinned C source builds an acronym from the first character of each space-delimited word. The explicit-length ASCII contract keeps the behavior safe and consistent across all nine language ports. See the [benchmark guide](benchmarks/a/acronym/README.md).

## Account Merge

The pinned Java implementation groups accounts through shared email addresses with union-find, then emits sorted unique emails. The benchmark defines deterministic grouping and rejects conflicting owner names in merged components. Nine language ports and a shared workload are present. See the [benchmark guide](benchmarks/a/account_merge/README.md).

## Affine Cipher

The pinned C, Julia, Java, JavaScript, Python, and Rust sources implement affine encryption and decryption with modular inversion. The shared contract supplies a unique printable-ASCII alphabet to reconcile their source alphabets and key representations. All nine ports passed 1,772 oracle inputs and recorded 19 workload cases. C candidate `affine` is a reviewed alias. See the [benchmark guide](benchmarks/a/affine_cipher/README.md) and [verifier](benchmarks/verify_affine_cipher.py).

## Alternate Harmonic Series

The finite sequence must alternate in sign and have reciprocal magnitudes in arithmetic progression; a singleton is true. The exact-rational contract supports up to 1,000 terms. Nine ports, a workload, and a Fraction-based verifier are present; runtime verification is pending. See the [benchmark guide](benchmarks/a/alternate_harmonic_series/README.md).

## Alternating Harmonic Series

The finite sequence is compared with the canonical prefix `1, -1/2, 1/3, ...` using an inclusive absolute tolerance of 1e-9; the empty sequence is false. Nine ports, a workload, and a Fraction-based verifier are present; runtime verification is pending. See the [benchmark guide](benchmarks/a/alternating_harmonic_series/README.md).

## Spy Number

The pinned Python source returns false for nonpositive integers and checks whether a positive integer's decimal digit sum equals its digit product. Nine scalar ports and a workload are present; runtime verification remains pending. See the [benchmark guide](benchmarks/s/spy_number/README.md).

## Leap Year

The JavaScript and TypeScript source candidates share the Gregorian divisibility rule. The benchmark accepts positive years and returns `-1` for nonpositive input. TypeScript candidate `is_leap_year` is a reviewed alias of `leap_year`. Nine scalar ports and a workload are present; runtime verification remains pending. See the [benchmark guide](benchmarks/l/leap_year/README.md).


## Smith Number

The pinned Java implementation rejects primes and compares a value's base-10 digit sum with the digit sums of its prime factors, counting repeated factors. The shared positive signed-int contract excludes the source helper's zero false positive. Nine portable implementations and a workload are present; see the [benchmark guide](benchmarks/s/smith_number/README.md).


## Sum of Geometric Progression

The pinned Rust, Julia, and Python sources use the same finite geometric-series formula, while JavaScript reverses the formula's subtraction order and also handles infinite term counts. The benchmark uses bounded finite inputs, a ratio-one special case, and a scaled float64 tolerance. Nine portable implementations and a workload are present; see the [benchmark guide](benchmarks/s/sum_of_geometric_progression/README.md).


## Conditional Probability

The pinned C++ implementation returns the joint probability divided by the conditioning probability when both inputs are in their valid probability ranges. The benchmark maps the source exceptions for invalid values to `-1.0` and rejects non-finite inputs. Nine portable implementations and a workload are present; see the [benchmark guide](benchmarks/c/conditional_probability/README.md).


## Boyer–Moore–Horspool Search

The pinned Python source provides first-match and all-match Horspool search. The shared benchmark uses the all-match variant, preserves overlapping occurrences, and treats an empty pattern as a match at every text boundary. The Ruby `boyer_moore_horspool_search` filename is recorded as an alias; its source has a zero-shift defect that the guide documents. Nine portable implementations and a workload are present; see the [benchmark guide](benchmarks/b/boyer_moore_horspool/README.md).


## Beaufort Cipher

The pinned Python source encrypts with `(plaintext - key) mod 26` and decrypts by adding the key; literal spaces do not advance the repeated-key cursor. The benchmark records the source's uppercase-only behavior and excludes keys longer than the message, which make the source key expansion loop indefinitely. Nine portable ports and a workload are present; see the [benchmark guide](benchmarks/b/beaufort_cipher/README.md).


## Count Leading Zeros

The pinned Java implementation scans a 32-bit mask from the most-significant bit: zero returns 32, positive values count leading zero bits, and negative values return 0. The benchmark preserves the Java int domain inside the shared signed-i64 ABI, returning `-1` for values outside int32. Nine portable implementations and a workload are present; see the [benchmark guide](benchmarks/c/count_leading_zeros/README.md).


## Pell Number

The pinned Python iterative implementation uses `P(0)=0`, `P(1)=1`, and `P(n)=2P(n-1)+P(n-2)`. The benchmark caps the index at 50 so results fit signed 64-bit. Nine portable scalar implementations and a workload are present; see the [benchmark guide](benchmarks/p/pell_number/README.md).


## Perrin Number

The pinned Java implementation uses initial terms `3, 0, 2` and the recurrence `P(n)=P(n-2)+P(n-3)`. The benchmark caps the index at 155 so results fit signed 64-bit and keeps the distinct Padovan initial values out of this contract. Nine portable scalar implementations and a workload are present; see the [benchmark guide](benchmarks/p/perrin_number/README.md).


## Nth Ugly Number

The pinned Java source generates sorted values from a configured base set; this benchmark fixes the bases to `[2, 3, 5]` and uses zero-based indexing. The maximum index is 12,690, whose value fits signed 64-bit. Nine portable scalar implementations and a workload are present; see the [benchmark guide](benchmarks/n/nth_ugly_number/README.md).


## Naive shuffler

The pinned C# `NaiveShuffler<T>` chooses a random index from the full array for every position and swaps the pair, distinguishing it from Fisher–Yates. Nine portable ports preserve that loop and use a shared seeded Park–Miller stream so each language receives the same choices on every platform. See the [benchmark guide](benchmarks/n/naive_shuffler/README.md).


## Reviewed invalid source: Go `topological`

The pinned Go function calls a general DFS helper that treats edges as undirected, records pre-order traversal, and lacks a global finished set. It can return an invalid ordering for a directed acyclic graph, so the candidate is marked `reviewed_excluded_invalid_source` and is not counted as a completed benchmark. See the [topological-sort guide](benchmarks/t/topological_sort/README.md).

The Euler totient candidates are separated by contract and method: scalar factorization maps to `euler_totient`; C-Sharp repeated factorization maps to `euler_totient_sequence`; Python linear sieve maps to `totients_linear_sieve`; and the Rust table sieve remains `compute_totient`. `eulers_totient` contains both scalar sources and the Python sequence source, so its catalog entry maps to the scalar benchmark and records the additional linear-sieve benchmark.

The `fast_power` filename groups two semantics: Rust modular exponentiation aliases `modular_exponentiation`, while the C++ nonmodular signed-exponent routines map to `powx_n`.


## Wave sort variants

The pinned C++ sources from both repositories and Rust sort the full array, then swap adjacent pairs from index zero; these map to `wave_sort`. The Java source instead makes even-indexed elements peaks using local swaps, which can return a different permutation and maps to `wave_sort_greedy`. Both contracts are implemented in all nine target languages over bounded signed-i32 arrays. See the [sort-then-swap guide](benchmarks/w/wave_sort/README.md) and [greedy-peak guide](benchmarks/w/wave_sort_greedy/README.md).


## Reviewed physics and sequence candidates

The pinned Python buoyancy and kinetic-energy sources are represented with bounded integral inputs and preserve their formula ordering. The C# Kummer and tetranacci generators retain their source initial values and recurrences. The Java `new_man_shanks_prime` method compares a recurrence value; it is not a primality test. Each has a nine-language contract and workload in its benchmark guide.


## Fast inverse square root and potential energy

The PHP fast-inverse-square-root source uses the IEEE-754 binary32 magic-constant seed and one Newton correction; the nine ports use portable language operations without x86-specific instructions. The Python potential-energy source uses `mass * g * height` with `g=9.80665`. Both contracts and bounded workloads are documented in their benchmark guides.


## Longest alternating subsequence

The pinned Java dynamic program alternates strict rising and falling transitions. Its result starts at 1, including for an empty input; the nine portable ports preserve that behavior and bound values to signed int32. See the [benchmark guide](benchmarks/l/longest_alternating_subsequence/README.md).


## Newton force and sign-bit comparison

The pinned Python Newton-law source multiplies signed mass and acceleration; the benchmark keeps bounded signed inputs. Java and Python `numbers_different_signs` both test whether the signed XOR is negative, and the shared contract limits Python values to Java int32. See the guides for [Newton force](benchmarks/n/newtons_second_law_of_motion/README.md) and [different signs](benchmarks/n/numbers_different_signs/README.md).

## Geometric distribution

Both pinned C++ snapshots expose the same geometric distribution calculations. The benchmark covers deterministic expectation, variance, standard deviation, PDF, CDF, inverse CDF, and inclusive range probability with binary32 source rounding; it excludes random sampling. See the [benchmark guide](benchmarks/g/geometric_dist/README.md).


## Geometric sequence and mean

The pinned Python `geometric.py` contains two operations: checking whether adjacent terms have a common ratio and calculating the geometric mean. They have a selector-based bounded contract and are distinct from the finite term generator in `geometric_series` and the probability calculations in `geometric_dist`. See the [benchmark guide](benchmarks/g/geometric/README.md).


## Double linear search

The pinned Python and Ruby sources probe the left endpoint before the right endpoint, then move inward. The benchmark preserves that order for duplicate matches and limits values to the exact-integer range shared with JavaScript. See the [benchmark guide](benchmarks/d/double_linear_search/README.md).


## ASCI Purple anisotropic 7-point residual (`asci_purple_smg2000_residual`)

This package computes the structured 3D residual `r = b - A*x` with the pinned `smg2000` anisotropic 7-point coefficients (`cx=0.1`, `cy=1`, `cz=10`). It is a bounded kernel from the ASCI Purple multigrid benchmark, not the complete HYPRE solver. Nine clean-room ports and float64 slice suite integration are present; the pinned source refers to missing copyright/disclaimer text and grants no explicit redistribution permission. See the [guide](benchmarks/a/asci_purple_smg2000_residual/README.md), [workload](benchmarks/a/asci_purple_smg2000_residual/workload.json), and [oracle](benchmarks/asci_purple_smg2000_residual_oracle.py).

## ASCII uppercase

The pinned F#, Java, JavaScript, and Python implementations uppercase ASCII letters. The contract excludes ASCII whitespace so F# split-and-join follows the same separator behavior as the other sources. See the [benchmark guide](benchmarks/u/upper/README.md).


## Maximum sum of distinct fixed-size windows

The pinned Java source updates its maximum only for length-`k` windows containing distinct values, with an initial maximum of zero. That preserves zero when no qualifying window exists or all valid sums are negative. See the [benchmark guide](benchmarks/m/maximum_sum_of_distinct_subarrays_with_length_k/README.md).


## Infix to postfix conversion

The pinned Python stack conversion emits space-separated postfix tokens. Exponentiation is right-associative, while the supported arithmetic operators are left-associative. See the [benchmark guide](benchmarks/i/infix_to_postfix_conversion/README.md).


## Kaprekar constant routine

The pinned Python source pads each value to four digits, subtracts the ascending digit arrangement from the descending arrangement, and stops at 6174, zero, or the iteration limit. The benchmark reports the iteration count. See the [benchmark guide](benchmarks/k/kaprekar_constant/README.md).


## Z-function

The pinned C++ and Python implementations return the Z-array, with `z[0]=0`; this is distinct from pattern search in `z_algorithm`. See the [benchmark guide](benchmarks/z/z_function/README.md).


## Recursive find minimum

The pinned Dart and Java sources split an inclusive index range recursively, then combine the minimum from each half. The benchmark applies that recurrence to a bounded nonempty input. See the [benchmark guide](benchmarks/f/find_min_recursion/README.md).


## Weekday formulas: Doomsday and month offsets

The pinned Python `doomsday.py` uses Conway's Doomsday rule. The Rust source with the same filename uses a separate fixed month-offset formula, so the catalog maps it to the additional `weekday_by_month_offsets` benchmark. See the [Doomsday guide](benchmarks/d/doomsday/README.md) and the [month-offset guide](benchmarks/w/weekday_by_month_offsets/README.md).


## Binary morphology: dilation

The pinned Python `dilation_operation.py` benchmark applies a fixed 3×3 binary structuring element to a zero-padded image and emits 1 wherever the source-ordered neighborhood sum is positive. See the [benchmark guide](benchmarks/d/dilation_operation/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/morphological_operations/dilation_operation.py).


## Treynor ratio

The pinned Rust implementation computes excess portfolio return divided by beta. The finite benchmark contract bounds its inputs and excludes zero beta, which produces NaN in the source. See the [benchmark guide](benchmarks/t/treynor_ratio/README.md).


## Cross-entropy loss

The pinned Rust source forms negative actual-times-log-predicted terms in order and then sums the terms in order. The bounded contract keeps results finite and excludes unequal vectors and invalid logarithm inputs. See the [benchmark guide](benchmarks/c/cross_entropy_loss/README.md).

## Order-agnostic binary search

The pinned Java source derives ascending or descending comparison order from the endpoints, then performs midpoint binary search. The benchmark preserves the source's returned midpoint for duplicate keys and requires monotone input. See the [benchmark guide](benchmarks/o/order_agnostic_binary_search/README.md).


## Distance filename variants

The Go `distance` source computes Euclidean distance and aliases `euclidean_distance`; the PHP source computes byte-string Levenshtein distance and maps to the additional `levenshtein_distance` benchmark. See the [Euclidean-distance guide](benchmarks/e/euclidean_distance/README.md) and the [Levenshtein guide](benchmarks/l/levenshtein_distance/README.md).

## Multiplicative binomial coefficient

The pinned C++ `binomial_calculate` and `n_choose_r` sources evaluate `n choose k` with the same iterative multiplicative recurrence; `n_choose_r` aliases this benchmark on its bounded common domain. This is distinct from the Pascal-triangle strategy in `binomial_coefficient`. See the [benchmark guide](benchmarks/b/binomial_calculate/README.md).


## Set the kth bit

The pinned C++ sources return `N | (1 << k)` for zero-based bit position `k`. The benchmark stays inside the source's defined signed-shift domain. See the [benchmark guide](benchmarks/s/set_kth_bit/README.md).
The Elixir `set_bit` and JavaScript `SetBit` candidates use the same operation and alias this benchmark on its bounded domain.

## Reviewed non-benchmarkable source: Java SearchAlgorithm

The pinned Java `SearchAlgorithm` file declares a generic interface only; it has no search implementation to benchmark.


## Duval least cyclic shift

The pinned C++ `duval.cpp` scan returns the source-selected start of a lexicographically least cyclic rotation. It is separate from Rust `duval_algorithm`, which performs Lyndon factorization. See the [benchmark guide](benchmarks/d/duval/README.md).


## Minimum size subarray sum

The pinned Python source grows a right edge, records qualifying lengths, and shrinks the left edge while the sum stays at least the target. Positive inputs preserve this sliding-window invariant. See the [benchmark guide](benchmarks/m/minimum_size_subarray_sum/README.md).


## Duplicate brackets

The pinned Java stack scan reports whether a closing parenthesis encloses no expression characters. It detects redundant grouping and is distinct from balanced-parenthesis checks. See the [benchmark guide](benchmarks/d/duplicate_brackets/README.md).

## Binary OR and XOR formatting

The pinned Python and Ruby sources calculate a binary OR or XOR result and emit it with a `0b` prefix and width derived from the operands. These byte-output packages preserve the source formatting contract for bounded nonnegative values. See the guides for [binary OR](benchmarks/b/binary_or_operator/README.md) and [binary XOR](benchmarks/b/binary_xor_operator/README.md).

## Ordinary annuity future value

The pinned Python formula is payment times `(((1+rate)^periods)-1)/rate`, without the final rate factor used for an annuity due. See the [benchmark guide](benchmarks/o/ordinary_annuity_future_value/README.md).


## Even tree cuts

The pinned Python source roots the tree at node 1, computes subtree sizes, and counts edges whose child subtree is even. The benchmark limits the domain to valid trees with an even node count. See the [benchmark guide](benchmarks/e/even_tree/README.md).

## Simple moving average

The pinned Python source emits unavailable values until a complete trailing window exists, then sums each window independently and divides by its length. The portable output uses canonical quiet-NaN bits for the unavailable prefix. See the [benchmark guide](benchmarks/s/simple_moving_average/README.md).

## Generate parentheses

The pinned C++, JavaScript, and Python sources generate the same well-formed parenthesis strings with different traversal orders. The benchmark sorts them lexicographically and concatenates the fixed-length results. See the [benchmark guide](benchmarks/g/generate_parentheses/README.md).

## Streaming moving average

The pinned Python class reports the average of its current trailing values after each update, including partial windows. This is distinct from the batch simple moving average, which marks the incomplete prefix unavailable. See the [benchmark guide](benchmarks/s/streaming_moving_average/README.md).

## Time and a half pay

The pinned Python source computes regular pay, then adds a half-rate premium for hours above the threshold. It preserves the source's operation order and explicit threshold parameter. See the [benchmark guide](benchmarks/t/time_and_half_pay/README.md).

## Camel case to snake case

The pinned Python source inserts underscores before uppercase ASCII letters and lowercases them. The letter-only contract keeps the transformation shared across the nine ports and distinguishes it from the inverse snake-to-camel conversion. See the [benchmark guide](benchmarks/c/camel_case_to_snake_case/README.md).


## Integer partition count

The pinned Python and Rust implementations use the same two-dimensional recurrence to count partitions of a positive integer. The benchmark bounds n so the exact result fits signed 64-bit. See the [benchmark guide](benchmarks/i/integer_partition/README.md).

## Binary numeral to Base64 text

The pinned Python source maps six-bit groups from a textual binary numeral through the Base64 alphabet. The contract preserves left-padding, the mandatory group at exact six-bit multiples, an optional leading sign, and edge-whitespace trimming; this is distinct from byte-to-Base64 encoding. See the [benchmark guide](benchmarks/b/binary_to_base64/README.md).


## Squareplus activation

The pinned Python function applies `(x + sqrt(x^2 + beta))/2` elementwise. The benchmark scalarizes one vector element while retaining configurable positive beta and the source expression order. See the [benchmark guide](benchmarks/s/squareplus/README.md).


## Trapping rain water alias

The pinned JavaScript source uses prefix and suffix maximum heights and sums trapped water per position, matching the C++ and Rust `trapped_rainwater` benchmark. The JavaScript filename is cataloged as an alias. See the [benchmark guide](benchmarks/t/trapped_rainwater/README.md).

## Softplus activation

The pinned Python source evaluates `log(1 + exp(x))` directly. The bounded unary contract preserves that operation order and its rounding at the lower endpoint, instead of substituting a stabilized identity. See the [benchmark guide](benchmarks/s/softplus/README.md).

## First-match Horspool search

The pinned Java `findFirst` routine searches right-to-left and shifts from the text byte aligned with the pattern's final position. It returns only the first match, unlike the all-match `boyer_moore_horspool` benchmark. See the [benchmark guide](benchmarks/h/horspool_search/README.md).

## Temperature conversion

The pinned JavaScript source defines 16 directed conversions among Celsius, Fahrenheit, Kelvin, Rankine, and Réaumur, rounding each result with `Math.round`. The package preserves its formula order and whole-degree rounding. See the [benchmark guide](benchmarks/t/temperature_conversion/README.md).


## Softsign activation

The pinned Python source evaluates `x/(1+abs(x))` directly for each value. The bounded unary contract preserves the expression and source operation order. See the [benchmark guide](benchmarks/s/softsign/README.md).

## Segmented sieve

The pinned Python source builds base primes through the square root, then marks each consecutive segment and emits primes in ascending order. This differs from sieving the entire range in `sieve_of_eratosthenes`. See the [benchmark guide](benchmarks/s/segmented_sieve/README.md).

## Banker's algorithm source variants

The pinned Java `checkSafeSystem` source returns whether an allocation state is safe. The Python demonstration prints a sequence and uses a different index map for duplicate need rows, which can release the first matching process allocation more than once; that behavior is preserved in a separate benchmark. See the [Java guide](benchmarks/b/bankers_algorithm/README.md) and the [Python-demo guide](benchmarks/b/bankers_algorithm_python_demo/README.md).

## Mish activation

The pinned Python source evaluates `x * tanh(log(1 + exp(x)))` in that order. The bounded unary package preserves the source's direct formula. See the [benchmark guide](benchmarks/m/mish/README.md).

## Circular convolution

The pinned Python source pads both inputs to the longer length, wraps products modulo that length, and rounds outputs to two decimals. On the bounded integer domain the result stays exact; this is distinct from linear convolution. See the [benchmark guide](benchmarks/c/circular_convolution/README.md).

## Möbius function

The pinned Java, JavaScript, and Python sources return zero when a prime square divides n; otherwise they return the parity of distinct prime factors, with μ(1)=1. Go `mobius` matches on the positive domain and is an alias. See the [benchmark guide](benchmarks/m/mobius_function/README.md).

## Unique subsequences count

The pinned Java source counts nonempty subsequence strings while deduplicating equal character sequences at each suffix. The ASCII contract bounds the count to the source's signed-int range. See the [benchmark guide](benchmarks/u/unique_subsequences_count/README.md).


## Decimal expansion

The pinned JavaScript source emits a fraction's radix digits by long division and detects repeating cycles by remainder. This is distinct from integer base conversion. See the [benchmark guide](benchmarks/d/decimal_expansion/README.md).

## Misnamed Base58 source

The pinned Python file named `base58.py` actually provides RFC 4648 Base64 byte encoding and decoding, so it aliases the `base64` benchmark. See the [Base64 guide](benchmarks/b/base64/README.md).


## Hexadecimal text to decimal

The pinned JavaScript source folds uppercase hexadecimal digits into a nonnegative integer. Its bounded values match the existing `hexadecimal_to_decimal` contract after input normalization, so the candidate is cataloged as an alias. See the [benchmark guide](benchmarks/h/hexadecimal_to_decimal/README.md).

## Unbounded knapsack

The pinned C++ file named `unbounded_0_1_knapsack.cpp` and Kotlin `UnboundedKnapsack.kt` use capacity-ascending recurrences that allow unlimited reuse. They map to the `unbounded_knapsack` benchmark; the Kotlin driver’s printed DP row is outside the normalized scalar result. See the [benchmark guide](benchmarks/u/unbounded_knapsack/README.md).

## Base64 source aliases

The Python `base58.py` filename actually implements Base64, and the C++ `base64_encoding.cpp` sources implement RFC 4648 encoding and decoding; both are cataloged as aliases of `base64`. The C++ signed-`char` limitation is documented in the alias review notes. See the [benchmark guide](benchmarks/b/base64/README.md).


## Additional source mappings

The Kotlin `UnboundedKnapsack.kt` source uses capacity-ascending dynamic programming and maps to `unbounded_knapsack`; its printed DP row is outside the scalar result. The JavaScript `DegreeToRadian.js` source aliases `radians` within the shared binary64 tolerance. The Java `SnellLaw.java` source is a radian-valued Snell refraction benchmark; the Python degree-valued, rounded sibling remains a separate source variant. See the [unbounded-knapsack guide](benchmarks/u/unbounded_knapsack/README.md), [radians guide](benchmarks/r/radians/README.md), and [Snell's-law guide](benchmarks/s/snell_law/README.md).

The unrestricted Java Damerau–Levenshtein source and restricted Python/C# optimal-string-alignment sources are separate benchmarks. The JavaScript `hex_to_binary` preserves leading zeroes, while the Python `convert_number_to_words` package supports short, long, and Indian numbering systems. The Java `longest_common_prefix` package sorts internally without modifying input. See the [Damerau–Levenshtein guide](benchmarks/d/damerau_levenshtein_distance/README.md), [OSA guide](benchmarks/o/optimal_string_alignment_distance/README.md), [hex-to-binary guide](benchmarks/h/hex_to_binary/README.md), [number-to-words guide](benchmarks/c/convert_number_to_words/README.md), and [longest-common-prefix guide](benchmarks/l/longest_common_prefix/README.md).

The standard Haversine sources return kilometers using the central-angle formula. The pinned Rust expression is materially different and returns meters, so it has its own benchmark; `haversine_formula` aliases the standard formula. See the [standard Haversine guide](benchmarks/h/haversine_distance/README.md) and [Rust-variant guide](benchmarks/h/haversine_rust_variant/README.md).

The C# `GeoLocation.CalculateDistanceFromLatLng` source uses the Haversine central angle with a 6371.01 km radius and returns meters. It is a distinct all-language benchmark because the standard `haversine_distance` contract uses a 6371 km radius and returns kilometers. See the [geo-location guide](benchmarks/g/geo_location/README.md).

The Python `gabor_filter_kernel` candidate is benchmarked as a kernel generator, excluding image loading, OpenCV filtering, and the demo's orientation accumulation. Its nine ports promote even kernel sizes to odd and return row-major binary32 coefficients; see the [Gabor kernel guide](benchmarks/g/gabor_filter/README.md).

The Java `GomoryHuTree.buildTree` candidate uses n−1 Edmonds–Karp flows and parent updates to build the cut-equivalent tree. The all-pairs path-minimum signature is independent of tree representation, and the oracle enumerates cuts directly; see the [Gomory–Hu guide](benchmarks/g/gomory_hu_tree/README.md).

The R `gradient_boosting.r` source contains its own squared-error regression trees and residual boosting loop. The bounded one-feature stump contract preserves mean initialization, midpoint split selection, residual means, and learning-rate updates. The Python file with the same regressor name delegates to scikit-learn and remains a separate excluded demo; see the [gradient-boosting guide](benchmarks/g/gradient_boosting_regressor/README.md).


The JavaScript `RadianToDegree.js` source uses the inverse unit conversion from `radians` and is benchmarked separately. The C++ `connected_components.cpp` source counts undirected-graph components with recursive DFS, distinct from the DSU benchmark. See the [radian-to-degree guide](benchmarks/r/radian_to_degree/README.md) and [DFS connected-components guide](benchmarks/c/connected_components/README.md).


The Python `snake_case_to_camel_pascal_case` helper supports camelCase and PascalCase output modes. The bounded ASCII contract preserves its word-boundary and capitalization behavior across the ports. See the [snake-case conversion guide](benchmarks/s/snake_case_to_camel_pascal_case/README.md).


The Python `base64_to_binary` source maps each Base64 alphabet symbol independently to six bits, trims edge ASCII whitespace, and preserves one leading minus sign. It is distinct from byte-oriented Base64 decoding and from `binary_to_base64`. See the [Base64-alphabet-to-binary guide](benchmarks/b/base64_to_binary/README.md).


The Java, Python, R, and Rust `dinic` sources implement the same bounded maximum-flow scalar using Dinic's level graph and blocking-flow method; their residual representations and vertex indexing are adapted to one packed contract. The Rust `dinic_maxflow` name is canonical, while Java/Python `dinic` and R `dinic_max_flow` are aliases. See the [Dinic guide](benchmarks/d/dinic_maxflow/README.md).


The pinned primary C++ digit-count file contains two methods: the repeated-division integer routine and a separate `floor(log10(abs(x)) + 1)` binary64 routine. Both have independent benchmark contracts, including the logarithmic method’s fractional-input behavior. See the [integer digit-count guide](benchmarks/f/finding_number_of_digits_in_a_number/README.md) and [logarithmic digit-count guide](benchmarks/f/finding_number_of_digits_in_a_number_using_log/README.md).


The JavaScript `MaxProductOfThree.js` source compares the product of the three largest values with the product of the largest value and two smallest values. It chooses exactly three positions and is distinct from contiguous maximum-product-subarray algorithms. See the [maximum-product-of-three guide](benchmarks/m/max_product_of_three/README.md).


The Java `AutoCorrelation` source returns the complete unnormalized linear signal through `CrossCorrelation`, distinct from a normalized coefficient at one lag. The mixed `linear_regression` candidate includes OLS in C#/Rust/R, batch gradient descent in Java/Python, sequential one-feature gradient descent in Julia, and stochastic gradient descent in the Jupyter notebook. OLS, batch, Julia sequential gradient descent, and notebook stochastic gradient descent each have separate benchmark packages. See the [auto-correlation guide](benchmarks/a/auto_correlation/README.md), [OLS guide](benchmarks/l/linear_regression_ols/README.md), [batch-gradient-descent guide](benchmarks/l/linear_regression_gradient_descent/README.md), and [Julia sequential-gradient-descent guide](benchmarks/l/linear_regression_sequential_gradient_descent/README.md), and [notebook stochastic-gradient-descent guide](benchmarks/l/linear_regression_stochastic_gradient_descent/README.md).


The Ruby `find_the_highest_altitude` source returns the greatest prefix sum including the initial altitude of zero; its second method definition is the effective implementation. JavaScript `array_buffer_to_base64` encodes ArrayBuffer bytes with the standard Base64 alphabet and aliases the existing Base64 byte-encoder package. See the [highest-altitude guide](benchmarks/f/find_the_highest_altitude/README.md) and [Base64 guide](benchmarks/b/base64/README.md).


The Python `snells_law` source uses degree-valued angles, near-critical `math.isclose` checks, and two-decimal ties-to-even rounding. It is a separate benchmark from Java's unrounded radian-valued `snell_law`. See the [Python Snell's-law guide](benchmarks/s/snells_law/README.md).


The pinned C++ sources repeatedly select each component's cheapest outgoing edge and merge components, preserving Borůvka's phases. Python `boruvka` and Java `boruvkaMST` map to the same connected-graph total-weight contract; disconnected inputs are excluded because the Python and Java loops do not make progress there. This is distinct from Prim's and Kruskal's MST algorithms. See the [Borůvka MST guide](benchmarks/b/boruvkas_minimum_spanning_tree/README.md).


The JavaScript `ExponentialFunction.js` source sums a finite Taylor expansion with source loop order and special-cases zero terms; it is not the exact `exp` operation. The Java `assignment_using_bitmask` source counts assignments with a bitmask DP while allowing tasks to remain unused. See the [Taylor exponential guide](benchmarks/e/exponential_function/README.md) and [bitmask assignment guide](benchmarks/a/assignment_using_bitmask/README.md).


The pinned Python `nth_root` source uses Newton iteration with its exact initialization, update order, and stopping rule. The Go `binarytodecimal` string parser aliases the unsigned `binary_to_decimal` benchmark on strings of at most 32 bits. Python and MATLAB `bisection` candidates use interval bisection and map to the normalized `bisection_method` contract, while preserving their stopping-condition differences in review notes. The JavaScript `circular_arc` package preserves its arc-length and sector-area functions as separate modes; the arc-length mode also overlaps the degree mode of `arc_length`. See the [nth-root guide](benchmarks/n/nth_root/README.md), [binary-to-decimal guide](benchmarks/b/binary_to_decimal/README.md), [bisection guide](benchmarks/b/bisection_method/README.md), and [arc-length guide](benchmarks/a/arc_length/README.md).


The pinned Java and Python `linear_congruential_generator` sources apply the same explicit seeded recurrence. Time-based default seeding is excluded; generated states are serialized as little-endian unsigned 64-bit values. See the [linear-congruential-generator guide](benchmarks/l/linear_congruential_generator/README.md).

The pinned Rust `gradient_descent` optimizer accepts a derivative callback; its included test uses the square-function gradient `2*x`. Its nine-language benchmark preserves that callback and update order over a bounded vector, while the Jupyter and Python filename matches are distinct fixed-data linear-regression trainers. See the [gradient-descent guide](benchmarks/g/gradient_descent/README.md).


The JavaScript `circular_arc` source exposes both arc length and sector area; a mode-driven package preserves each formula and its degree conversion order. The mixed `linear_regression` candidate maps OLS, batch gradient descent, Julia's sequential one-feature gradient descent, and notebook stochastic gradient descent to separate benchmarks; the notebook stochastic package is now complete. See the [circular-arc guide](benchmarks/c/circular_arc/README.md) and [Julia sequential-gradient-descent guide](benchmarks/l/linear_regression_sequential_gradient_descent/README.md), and [notebook stochastic-gradient-descent guide](benchmarks/l/linear_regression_stochastic_gradient_descent/README.md).


The Python `brent_method` source combines inverse-quadratic interpolation, secant steps, and safeguarded bisection for bracketed roots. The Python `relativistic_kinetic_energy` source applies the Lorentz factor and is distinct from classical kinetic energy. JavaScript `base64_to_array_buffer` aliases the Base64 decoder on canonical RFC 4648 encodings. See the [Brent-method guide](benchmarks/b/brent_method/README.md), [relativistic kinetic-energy guide](benchmarks/r/relativistic_kinetic_energy/README.md), and [Base64 guide](benchmarks/b/base64/README.md).


The JavaScript `farey_approximation` source repeatedly updates rational bounds with mediants and returns the final mediant after a fixed number of steps. The benchmark preserves its tie direction and encodes the target as integer millionths. See the [Farey-approximation guide](benchmarks/f/farey_approximation/README.md).


The JavaScript `decimal_to_hex` source emits uppercase hexadecimal digits and is distinct in case from `decimal_to_hexadecimal`; its safe-integer domain normalizes JavaScript's numeric return for single digits to text. JavaScript `base64_to_array_buffer` aliases the strict Base64 decoder for canonical RFC 4648 inputs. See the [decimal-to-hex guide](benchmarks/d/decimal_to_hex/README.md) and [Base64 guide](benchmarks/b/base64/README.md).


The Python `relativistic_velocity_summation` source applies the relativistic velocity-addition formula, with an object-speed boundary that permits ±c and a strictly subluminal frame-speed bound. It is distinct from classical velocity addition. See the [relativistic-velocity-summation guide](benchmarks/r/relativistic_velocity_summation/README.md).


The Python `booths_algorithm` source finds a string's lexicographically smallest rotation with Booth's linear-time failure-table method. It is distinct from Booth multiplication. See the [minimal-rotation guide](benchmarks/b/booths_algorithm/README.md).


The Python `max_difference_pair` source recursively selects an ordered `(small,big)` value pair and preserves its split/tie comparison order. Equal indices are allowed, so decreasing arrays return a zero-difference pair; the contract differs from stock-profit benchmarks. See the [maximum-difference-pair guide](benchmarks/m/max_difference_pair/README.md).


The Java `Correlation.java` source retains a nonstandard normalization that can return values above one; the benchmark preserves its accumulation and expression order instead of substituting standard Pearson correlation. It is distinct from OLS slope. See the [discrete-correlation guide](benchmarks/c/correlation/README.md).


The Java `BruteForceKnapsack.java` source uses a direct include/exclude recursion without memoization, distinct from the tabulation benchmark. Its item-count bound preserves the recursive workload while keeping values within the source integer range. See the [brute-force knapsack guide](benchmarks/b/brute_force_knapsack/README.md).


The JavaScript `quadratic_roots` source preserves the direct discriminant formula and plus-before-minus root order; its variable-length binary64 vector uses tolerant comparison. Java `ddaline` includes both endpoints, follows Java rounding at half values, and emits the supplied start point for a zero-length segment, distinct from the Python DDA variant. Java `next_smaller_element` actually returns the previous strictly smaller element for each input. See the [quadratic-roots guide](benchmarks/q/quadratic_roots/README.md), [Java DDA guide](benchmarks/d/ddaline/README.md), and [next-smaller-element guide](benchmarks/n/next_smaller_element/README.md).

The pinned MATLAB `shreeDharacharyaFormula` returns both real roots in plus-root then minus-root order, including the repeated root twice. Its bounded [`shree_dharacharya_formula`](benchmarks/s/shree_dharacharya_formula/README.md) contract returns two little-endian binary64 values for exact `[a,b,c]` inputs and rejects negative discriminants, distinct from the Dart `shreedharacharya` contract. See the [workload](benchmarks/s/shree_dharacharya_formula/workload.json), [byte-output verifier](benchmarks/verify_i64_array_bytes_output.py), and pinned [MATLAB source](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/maths/shreeDharacharyaFormula.m).


The pinned C#, Go, Java, and Python Luhn validators agree on even-length decimal digit sequences; the package preserves leading zeroes and excludes odd lengths where source parity rules differ. See the [Luhn guide](benchmarks/l/luhn/README.md).


The pinned JavaScript `Sphere` class computes volume and surface area using two distinct formulas; the package exposes both with bounded integer radii. The pinned Java shortest-common-supersequence-length method uses a bottom-up LCS table and returns a length, distinct from the sequence-producing variant. The C++ and R sequence-producing sources map to [`shortest_common_supersequence`](benchmarks/s/shortest_common_supersequence/README.md), with printable ASCII inputs and Y chosen on LCS ties. See the [sphere guide](benchmarks/s/sphere/README.md) and [length guide](benchmarks/s/shortest_common_supersequence_length/README.md).


The pinned Python Fizz Buzz function returns the inclusive 1..n token sequence with a trailing space; the Ruby and Dart variants share the token rules. The package uses the fixed start value one and preserves the common output format. See the [Fizz Buzz guide](benchmarks/f/fizz_buzz/README.md).


The two pinned C++ golden-section search sources are algorithmic duplicates. Their float literal widens to `1.61803400516510009765625`; both stop at interval width `1e-7`, update the mean after shrinking the bracket, and return the prior midpoint. The package keeps test-harness printing outside the measured function. See the [golden-search guide](benchmarks/g/golden_search_extrema/README.md).


Dart `binpow` is a modular binary-exponentiation alias of `modular_exponentiation` on the package domain of positive modulus and exponent at least one. The source’s nonpositive-exponent behavior is outside that contract. See the [modular-exponentiation guide](benchmarks/m/modular_exponentiation/README.md).


The pinned Rust `npv` function discounts one bounded cash-flow sequence and sums terms in period order; `npv_sensitivity` applies the same source-ordered calculation to each supplied rate and returns a vector. Python `polygonal_numbers` uses its direct integer formula, and Java `xs3_conversion` handles both decimal/XS-3 conversion directions. Python Spearman correlation preserves average ranks for ties and one-decimal ties-to-even rounding. Ruby `number_of_days` aliases `date_day_difference` on valid ISO dates. See the [NPV guide](benchmarks/n/npv/README.md) and [NPV sensitivity guide](benchmarks/n/npv_sensitivity/README.md), [polygonal-number guide](benchmarks/p/polygonal_numbers/README.md), [XS-3 guide](benchmarks/x/xs3_conversion/README.md), [Spearman guide](benchmarks/s/spearman_rank_correlation_coefficient/README.md), and [date-difference guide](benchmarks/d/date_day_difference/README.md).


The Dart `min_number_of_jumps` candidate uses its quadratic DP recurrence and preserves the `1_000_000_000_000` unreachable sentinel; empty input is excluded because the source initializes index zero. Python `real_and_reactive_power` contains separate real- and reactive-power formulas, with source validation of the power-factor range. See the [minimum-jumps guide](benchmarks/m/min_number_of_jumps/README.md) and [real/reactive power guide](benchmarks/r/real_and_reactive_power/README.md).


The pinned Python `tonelli_shanks` source reduces the residue, handles zero first, uses the `p ≡ 3 (mod 4)` shortcut, and otherwise performs Tonelli–Shanks before returning the smaller root. Primality remains a contract precondition; nonresidues map the source exception to the invalid sentinel. See the [Tonelli–Shanks guide](benchmarks/t/tonelli_shanks/README.md).


The pinned Python `excel_title_to_column` converts case-insensitive alphabetic titles with a right-to-left base-26 sum, where A maps to 1. The package bounds the shared input to ASCII letters. See the [Excel-column guide](benchmarks/e/excel_title_to_column/README.md).


The pinned Java `herons_formula` checks for positive sides and strict triangle inequalities, then applies the source-ordered semi-perimeter product and square root. Its binary64 output and rejection of degenerate triangles distinguish it from the integer-scaled `area` benchmark. See the [Heron formula guide](benchmarks/h/herons_formula/README.md).


The Python `find_triplets_with_0_sum` primary function sorts, enumerates all 3-position combinations, deduplicates matching tuples, and returns them lexicographically; it is distinct from the O(n²) two-pointer `three_sum_problem`. Its separately named hashing helper is tracked for a separate contract. Python `carrier_concentration` selects the missing concentration from exactly one zero input and applies the source formula for that branch; the package encodes the returned field label through the zero position. See the [zero-sum triplets guide](benchmarks/f/find_triplets_with_0_sum/README.md) and [carrier-concentration guide](benchmarks/c/carrier_concentration/README.md).


The pinned Java `CountDistinctElementsInWindow` maintains a frequency map and emits the number of distinct values in each complete fixed-width window. It is distinct from sliding-window maximum-sum and median benchmarks. See the [window-count guide](benchmarks/c/count_distinct_elements_in_window/README.md).


The Jupyter `association` notebook calls `mlxtend.frequent_patterns.apriori` on grocery transactions; its bounded package emits itemset masks and support counts in cardinality-then-mask order, separate from Java bitmask assignment. The Casimir-effect package covers the pinned SI force, energy, and pressure equations; `ncr_combinations` preserves the Python falling-product order for finite fractional totals; and Go `powvialogarithm` preserves its log/exp and rounding sequence. The zero-sum triplets source also has a separate hashing benchmark that preserves first-discovery order.


Reviewed aliases now include JavaScript `find_hcf` and Scala `greater_common_divisor` for `gcd`, Java `eulers_function` for `euler_totient`, Go `fastexponent` for `binary_exponentiation`, Python `fermat_little_theorem` for `modular_exponentiation`, and degree/radian conversion filename variants for their corresponding conversion packages. The skipped Dart Fermat file is excluded as invalid source; the MATLAB `array` lesson and TypeScript Babel configuration are excluded as non-benchmarkable sources. Java `fast_exponentiation` maps to modular exponentiation, while the PHP source maps separately to unmodded binary exponentiation; Go `twin` aliases `twin_prime`.


The `hardy_ramanujanalgo` filename maps to the exact number of distinct prime divisors, not the Hardy–Ramanujan average. JavaScript `upper_case_conversion` aliases the byte-preserving ASCII `upper` benchmark on their shared input domain.
 The Python `triangle` source is represented by one package that returns its circumcenter, incenter, and orthocenter together.


The Java `cross_correlation` package preserves the source reversed-y overlap order on arbitrary finite signals. `brute_force_caesar_cipher` records all 26 uppercase-letter decryption candidates in key order.
 The Python `base64_cipher` candidate aliases the Base64 codec on canonical padded inputs; the package’s broader input normalization is documented in the review note.
 The Python `lens_formulae` package covers three reciprocal thin-lens solves and remains distinct from magnification/classification in `thin_lens`. PHP `array_helpers` aliases the nondecreasing `is_sorted` predicate after normalizing its exception behavior.
 The Python `fast_inverse_sqrt` source aliases the numeric `fast_inverse_square_root` package, while Go’s two-step binary32 approximation is a separate package; Java’s exact-equality overload checks are mapped to a separate package.
 The C# `bag_node` entry is excluded because it only defines a generic linked-node representation without an independent algorithm.
 Go `binary` aliases the ordinary ascending `binary_search` contract; its lower-bound and upper-bound helpers remain separate candidates.
 The four `astar` implementations use distinct grid, weighted-graph, directed-graph, and spatial-node contracts. Python preserves the squared-distance 8-neighbor grid; Java preserves simple-path weighted search; Rust preserves directed edge relaxation and returns cost plus path; the C# spatial package is complete. The JavaScript `vitest_config` entry is excluded as runner configuration without an algorithm.
 Java, JavaScript, TypeScript, and Go matrix-product sources share the exact square-domain `matrix_multiplication` contract; the package uses n≥2 to avoid the JavaScript one-row failure. Go's `Matrix.Multiply` candidate aliases this package; the Rust `multiply.rs` candidate is the separate decimal-string algorithm.
 The Python/Rust `exponential_moving_average` batch recurrence uses a shared window-size-at-least-two warm-up; Java streaming EMA is tracked separately. `bisection_2` preserves its fixed `10-x²` equation and 0.01 interval threshold. JavaScript `check_word_occurrence` preserves the source flag inversion and whitespace tokenization behavior.
 The C++ `ncr_modulo_p` package preserves modular-inverse failure for composite moduli. Python `magnetic_flux` preserves the field-area-cosine formula and one-decimal rounding.
 Forward radix-2 FFT is mapped across the pinned C++ and Rust implementations. The inverse benchmark uses the valid Rust implementation embedded in its FFT module; the two pinned C++ inverse files are excluded as mathematically incorrect. LAC-DCC's [`oourafft`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/oourafft/oourafft.c) repeatedly uses Ooura's forward and inverse complex DFT for correlation, and [`ffbench`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/ffbench/ffbench.c) applies the same FFT core in separable 2D passes; these benchmark profiles map to existing FFT packages instead of duplicating the transform algorithm.
 FreeBench `pifft` uses an FFT-convolution multiplier inside a modified AGM π calculation. [`freebench_pifft`](benchmarks/f/freebench_pifft/README.md) preserves that operation mix with a bounded eight-point, six-decimal fixed-point profile; it is related to [`gauss_legendre`](benchmarks/g/gauss_legendre/README.md) but has a distinct multiplication kernel. The pinned source has no explicit license grant.
 The MiBench SUSAN package implements bounded smoothing, and cBench `automotive_susan_s` selects the same operation despite its separate launcher. The cBench `automotive_susan_c` and `_e` profiles invoke distinct corner-detection and edge-detection/thinning operations, now covered by [`cbench_automotive_susan_c`](benchmarks/c/cbench_automotive_susan_c/README.md) and [`cbench_automotive_susan_e`](benchmarks/c/cbench_automotive_susan_e/README.md); all three cBench variants share byte-identical `susan.c` source content.
 cBench [`network_dijkstra`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/network_dijkstra/src/dijkstra_large.c) uses the same FIFO label-correcting queue, queued distance snapshots, and adjacency relaxation as MiBench [`network-dijkstra`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/network-dijkstra/dijkstra.c). Its dynamic matrix and repeated source/destination driver do not add a new shortest-path algorithm; both map to [`mibench_network_dijkstra`](benchmarks/m/mibench_network_dijkstra/README.md).
 FreeBench `analyzer` is a distinct memory-trace algorithm: it counts loads whose latest earlier writer belongs to a prior epoch. The bounded implementation is in [`analyzer`](benchmarks/a/analyzer/README.md), with file parsing and speculative timing excluded from the measured core.
 FreeBench `fourinarow` is bounded depth-limited heuristic minimax/alpha-beta on Connect Four, captured by [`fourinarow_minimax`](benchmarks/f/fourinarow_minimax/README.md) and distinct from the exact endgame result in [`fhourstones_exact`](benchmarks/f/fhourstones_exact/README.md). That package covers both [Fhourstones 2.0](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones) and [Fhourstones 3.1](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones_31), which are versions of the same exact solver family.
 FreeBench `neural` is a bounded continuous Hopfield network with Hebbian weights and delta recall, implemented in [`freebench_neural_hopfield`](benchmarks/f/freebench_neural_hopfield/README.md). It is distinct from feed-forward backpropagation and perceptron inference; the accepted repeated-pattern domain proves the source's delta loop converges after one pass.
 FreeBench `mason` is a distinct alternating-permutation puzzle search with a source-ordered move tree and per-piece reachability pruning, represented by [`freebench_mason`](benchmarks/f/freebench_mason/README.md) with an explicit depth cap of 8.
 FreeBench `distray` renders a deterministic selected pixel through distribution sampling and recursive scene shading. [`freebench_distray`](benchmarks/f/freebench_distray/README.md) captures that ray-tracing core without the full-image and timing wrappers; the pinned source has no explicit license grant.
 FreeBench `pcompress2` applies a Burrows-Wheeler transform over cyclic byte rotations, the source run-length packetizer, and adaptive arithmetic coding. [`pcompress2`](benchmarks/p/pcompress2/README.md) returns the bounded compressed record, with file I/O and repetition omitted. Existing standalone BWT and arithmetic-coding contracts cover component operations rather than this complete compression pipeline; the pinned sources have no explicit license grant.
 MiBench `security-sha` and cBench `security_sha` both leave `USE_MODIFIED_SHA` undefined and therefore select the original SHA-0 schedule without the SHA-1 one-bit rotation. [`mibench_security_sha0`](benchmarks/s/mibench_security_sha0/README.md) covers both launchers with a bounded single-block raw digest; the pinned MiBench files contain attribution but no explicit redistribution grant.
 LAC-DCC's telecom ADPCM encoder and decoder plus Mediabench `rawcaudio`/`rawdaudio` use the same IMA/DVI adaptive differential PCM recurrences and tables. [`lac_adpcm`](benchmarks/i/lac_adpcm/README.md) uses a mode field to expose both bounded operations; the original source permission notice is retained in every port.
 McCat `05-eks` performs a band-to-tridiagonal Givens reduction followed by shifted symmetric QR iteration. [`mccat_05_eks`](benchmarks/m/mccat_05_eks/README.md) keeps that general eigensolver distinct from the existing two-by-two shifted QR kernel; the independent oracle diagonalizes the bounded symmetric inputs with cyclic Jacobi rotations.

 McCat `08-main` updates child points through source-ordered scale, Euler rotation, and translation operations, then applies a parent transform across a rotation sweep. [`mccat_08_main`](benchmarks/m/mccat_08_main/README.md) preserves the `Rx * Ry * Rz` order, first-seen point deduplication, and frame-indexed parent rotation; this is distinct from the local single-axis vector rotation operation.

 McCat `09-vor` constructs a convex hull, greedily contracts hull vertices by local circumradius priority, and reports the final three-site circle. [`mccat_09_vor`](benchmarks/m/mccat_09_vor/README.md) is distinct from the local Fortune sweep, Olden quad-edge, and Bowyer-Watson triangulation packages, which construct different geometric structures.

 McCat `12-IOtest` scans generated byte arrays at different strides and reports simple aggregates. It measures memory-access patterns rather than a distinct algorithm, so the crosswalk records it without adding another package.

 MallocBench's Espresso launcher runs a full multi-output PLA minimizer, but [`mallocbench_espresso`](benchmarks/m/mallocbench_espresso/README.md) isolates bounded single-output EXPAND and IRREDUNDANT phases over binary minterm masks. Its deterministic cover cost is not a claim of global minimization; the later Espresso phases and large PLA input are outside the profile.

 Stanford `Puzzle` is a fixed 5×5×5 polycube packing search. [`stanford_puzzle`](benchmarks/p/stanford_puzzle/README.md) keeps the first-empty-cell DFS, 13 source orientations, shared piece-class counts, and source's 2,005-call observation. The source attributes the benchmark to Forest Baskett and has no explicit redistribution grant; the package records that status and uses independent ports.

 McCat `17-bintr` inserts values into a sorted binary tree, reports size, sum, and mean, then runs 100 recursive left-first depth-first membership scans. [`mccat_bintr`](benchmarks/m/mccat_bintr/README.md) keeps this launcher behavior distinct from [`binary_search_tree`](benchmarks/b/binary_search_tree/README.md), whose lookups follow ordered key comparisons; the source's key-directed search call is commented out. All nine ports and the byte-output runner/verifier integration preserve the source notice.
 LAC-DCC's FLoPS.c v2.0 family contains eight different numerical kernels. [`misc_flops`](benchmarks/m/misc_flops/README.md) selects each through a bounded module input and keeps them distinct from Whetstone and the existing generic integration algorithms. Its upstream files provide attribution but no explicit redistribution grant.
 LAC-DCC `Misc/fbench` traces rays through a four-surface achromatic telescope and computes spherical, sine-condition, and chromatic aberrations. [`freebench_fbench`](benchmarks/f/freebench_fbench/README.md) keeps the source ray trace in a bounded pass profile, distinct from the numerical kernels in FLoPS and the operation mix in Whetstone.
 MiBench `automotive-basicmath` integer square root is covered by [`mibench_automotive_basicmath_isqrt`](benchmarks/m/mibench_automotive_basicmath_isqrt/README.md): nine ports implement the 32-step digit recurrence, and the `i64_array_scalar` runner/verifier validate its pinned workload and generated square-boundary probes. The source and launcher state no redistribution license; the package records no inferred license. Its angle-conversion kernels map to existing [`radians`](benchmarks/r/radians/README.md) and [`radian_to_degree`](benchmarks/r/radian_to_degree/README.md) packages, so they are not repeated under a new name.
 LAC-DCC's [`Dhrystone/dry/dry.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Dhrystone/dry/dry.c) is the C/1.1 integer Dhrystone procedure workload; [`Dhrystone/fldry/fldry.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Dhrystone/fldry/fldry.c) uses the same sequence with numeric fields promoted to floating point. Both are version/type variants of the same Dhrystone benchmark family represented by ANSIbench's bounded Dhrystone 2.1 core, rather than separate algorithm packages.
 LAC-DCC's [`richards_benchmark.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/richards_benchmark/richards_benchmark.c) and the existing [`richards_benchmark`](benchmarks/r/richards_benchmark/README.md) package implement the same six-task packet scheduler and callback transitions. The local package exposes the source's optional 1,000,000-iteration profile; the pinned launcher leaves `SMALL_PROBLEM_SIZE` undefined and runs the default 10,000,000-iteration profile.
 cBench [`security_sha`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/security_sha/src/sha.c) and MiBench `security-sha` both compile without `USE_MODIFIED_SHA`, selecting the unrotated SHA-0 schedule; both are covered by [`mibench_security_sha0`](benchmarks/s/mibench_security_sha0/README.md), while [`sha1`](benchmarks/s/sha1/README.md) retains the standard rotated schedule.
 Weighted interval scheduling preserves the Python predecessor search, DP recurrence, and selected-index reconstruction. `palindrome_partitioning` is split between minimum-cut DP (C++, Python, Rust, Kotlin) and JavaScript all-partitions backtracking.
 Gaussian elimination is mapped on symmetric tridiagonal systems that prevent row-pivot swaps; the pinned C `gauss_elimination` source has a separate dense partial-pivoting contract. Euler-method variants share a dyadic-grid trajectory for C#/Java/JavaScript/Python, while Julia keeps its distinct span-based contract. Hill-cipher sources are split by modulus 36, 26, and 97 rather than merged by filename.
 AVL-tree sources are split into unique-key mutable operations, C++ insert-only behavior, and F# persistent insert/delete behavior; the C++ demo deletion path does not rebalance.

## FCFS Scheduling

The two pinned C++ `fcfs_scheduling` sources use non-preemptive first-come-first-served scheduling, order equal-arrival processes by ID, and idle until a process arrives. The Julia `fcfs`, Java `FCFSScheduling`, and Python `first_come_first_served` sources alias this benchmark for already ordered processes that are all available before execution. The benchmark excludes demo output and returns each scheduled process's completion, turnaround, and waiting times. All nine ports and a checker-only oracle verifier are in [the FCFS scheduling guide](benchmarks/f/fcfs_scheduling/README.md).

## Fair-Share Scheduling

The pinned Java `FairShareScheduling` implementation sums each user's task weights and assigns a proportional share using integer truncation; it leaves fractional leftovers unallocated and ignores tasks for unknown users. The shared bounded contract expresses the proportional result with exact integer arithmetic. All nine ports and the checker-only verifier are documented in [the fair-share scheduling guide](benchmarks/f/fair_share_scheduling/README.md). Upstream: [Java `FairShareScheduling.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/FairShareScheduling.java).

## Faraday–Lenz Law

The pinned Python source returns the negative magnetic-flux change divided by the time interval, rounded to one decimal place. The nine-language benchmark uses fixed-point milli-units and returns decivolts with exact ties-to-even rounding for cross-platform consistency. See [the Faraday–Lenz guide](benchmarks/f/faraday_lenz_law/README.md) and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/faraday_lenz_law.py).

## Maxwell Scalar Methods

The pinned Python module contributes seven separately selected scalar methods in [`maxwells_equations`](benchmarks/maxwells_equations/README.md): electric Gauss law, Faraday law, Ampere–Maxwell law, electromagnetic wave speed and impedance, the signed Poynting expression, and electromagnetic energy density. The contract uses fixed-point signed-i64 inputs and binary64 outputs; it excludes `gauss_law_magnetic`, which is a constant-true placeholder with no flux input. See the [workload](benchmarks/maxwells_equations/workload.json) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/maxwells_equations.py).

## Fletcher-16

The pinned Python implementation converts ASCII text to bytes, updates the two modulo-255 sums for each byte, then combines them into a 16-bit checksum. The shared contract bounds inputs at 4,096 bytes, accepts NUL bytes, and returns a sentinel for invalid byte values. The Rust `fletcher` source has the same recurrence on this ASCII domain and is cataloged as an alias. All nine ports and a weighted-sum oracle verifier are documented in [the Fletcher-16 guide](benchmarks/f/fletcher16/README.md). Upstream: [Python `fletcher16.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/hashes/fletcher16.py), [Rust `fletcher.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/hashing/fletcher.rs).

## Binary Tree Boundary Traversal

The pinned Java `BoundaryTraversal.boundaryTraversal` method emits the nonleaf root, the left boundary, all leaves from left to right, then the right boundary in reverse. The left path falls back to right children; when the root has no left child, the same path is not emitted a second time as the right boundary. The nine portable implementations use an indexed tree table and caller-owned result buffer. A checker-only verifier passed 688 oracle trees per language, including exhaustive ordered shapes through seven nodes and deterministic trees up to 100 nodes. See the [benchmark guide](benchmarks/b/boundary_traversal/README.md), [verifier](benchmarks/verify_boundary_traversal.py), and [pinned Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/BoundaryTraversal.java).


## Autocomplete Using Trie

The Python and Rust sources build a trie and return prefix matches. The shared contract accepts repeated inserts, deduplicates words, permits empty query prefixes, and sorts the unique results to make output stable across hash iteration orders. All nine ports passed 404 oracle cases per language and recorded the nine published workload cases. See the [guide](benchmarks/a/autocomplete_using_trie/README.md), [verifier](benchmarks/verify_autocomplete_using_trie.py), and the pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/autocomplete_using_trie.py) and [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/autocomplete_using_trie.rs).

## AVLTreeNode helper files

The pinned C# and PHP `AVLTreeNode` files define storage fields and local height/balance-factor updates, not tree-level search, insertion, deletion, or traversal. They are excluded as non-benchmarkable helper components; complete AVL-tree implementations are cataloged separately. Sources: [C# node](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/AVLTree/AVLTreeNode.cs), [PHP node](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/AVLTree/AVLTreeNode.php).


## AVL simple insertion alias

The pinned Java `AVLSimple` source implements unique-key AVL insertion with height updates and the four insertion rotation cases. It aliases the [`avltree_unique_key_ops` benchmark](benchmarks/a/avltree_unique_key_ops/README.md) on unique-key insertion traces; display formatting and root-height printing are outside the shared comparison. Upstream: [Java `AVLSimple.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/AVLSimple.java).

## Bitap String Match

The pinned Python source uses exact Bitap shift-OR matching and returns the first zero-based occurrence. The portable contract bounds text to 4,096 lowercase ASCII bytes and pattern length to 63 so the mask fits a standard 64-bit integer; an empty pattern returns 0, absence returns -1, and malformed inputs return -2. The separate C# `bitap` candidate supports only 31-character patterns and remains unmapped to this wider workload. All nine ports passed 8,541 independent naive-search inputs and recorded 17 workload cases. See the [guide](benchmarks/b/bitap_string_match/README.md), [verifier](benchmarks/verify_bitap_string_match.py), and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/bitap_string_match.py).


## Bipartite Graph by DFS

The pinned Java and Go sources color components with DFS, while C# provides BFS and DFS predicates and TypeScript provides DFS. Their Boolean decisions map to the same bounded undirected graph contract; the Go wrapper auto-adds out-of-range vertices, which the benchmark excludes. All repeated-edge and self-loop cases follow the shared contract. See the [guide](benchmarks/b/bipartite_graph_dfs/README.md) and pinned [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/graphs/BipartiteGraphDFS.java), [Go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/coloring/bipartite.go), [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Graph/BipartiteGraph.cs), and [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/graph/bipartite_graph.ts) sources.

## Reversort

The pinned Python `reversort` routine finds the minimum of each remaining suffix and reverses through it. Its companion `reversort_cost` applies the same pass and sums segment lengths, counting length-one reversals. Both contracts are implemented in all nine target languages. The sort ports passed 5,681 arrays and four workload lengths each; the cost ports passed 1,620 oracle arrays and 12 workload records each. See the [Reversort guide](benchmarks/r/reversort/README.md), [cost guide](benchmarks/r/reversort_cost/README.md), and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/reversort.py).


## Boundary Fill

The pinned Java routine performs an 8-connected fill from a seed until it reaches the boundary color. Its array access checks lower bounds but can index past the matrix at the right and bottom edges; the portable contract adds upper-bound checks and uses x-major pixel storage. All nine ports pass ten workload cases. See the [guide](benchmarks/b/boundary_fill/README.md) and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/BoundaryFill.java).


## Binary Tree Traversal

The pinned C, C++, Dart, PHP, Java, Ruby, and Python sources provide preorder, inorder, and postorder traversals over a rooted binary tree. The PHP AVL `TreeTraversal` candidate also exposes those orders plus breadth-first traversal and maps here; its key/value outputs are projected to node values. Standalone Ruby and Java sources map to their matching order codes, Java's zigzag levels flatten to the shared zigzag sequence, and Python `inorder_tree_traversal_2022` maps to inorder. The C and C++ recursive traversal candidates expose all three depth-first orders, with C restricted to signed 32-bit values and C++ to nonnegative signed-64-bit values. Haskell and Java add opposite breadth-first directions; the additional Python traversal module adds reverse-inorder and zigzag order, while its height function maps to `max_depth`. The nine portable ports use an explicit bounded tree table, retain duplicate values, and reject malformed shapes. See the [guide](benchmarks/b/binary_tree_traversal/README.md).

## Excess-3 Code

The pinned Python function clamps negative inputs to zero, adds three to each decimal digit, and appends each four-bit nibble after the `0b` prefix. All signed 64-bit inputs are supported, and output is written as ASCII bytes. All nine ports passed 7,183 oracle and capacity cases each and recorded ten workload inputs. See the [guide](benchmarks/e/excess_3_code/README.md), [verifier](benchmarks/verify_excess_3_code.py), and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/excess_3_code.py).


## Bidirectional Dijkstra

Both pinned C++ sources use directed graphs with nonnegative edge weights; they differ only by one explicit integer header include. The portable contract accepts bounded graphs with parallel edges and self-loops and returns the shortest distance, or -1 for an unreachable target. See the [guide](benchmarks/b/bidirectional_dijkstra/README.md).


## Bidirectional A*

The pinned Python routine mutates its search targets and uses identity-based node membership, which can change route selection and may fail to terminate on some unreachable cyclic grids. The nine-port contract keeps goals fixed, tracks coordinates, and guarantees a shortest path; its no-route `[start]` result is benchmark-defined. See the [guide](benchmarks/b/bidirectional_a_star/README.md).


## Binary indexed tree

The pinned C# implementation supports point additions and prefix sums, but its update bound can overrun the backing array on arbitrary lengths. The shared contract restricts array sizes to powers of two from 2 through 256 and preserves point updates and inclusive range-sum queries. See the [guide](benchmarks/b/binary_indexed_tree/README.md).

## Binary lifting kth ancestor

The pinned JavaScript `BinaryLifting` class implements kth-ancestor queries on a connected rooted tree; it does not expose LCA despite a comment describing that possible use. LCA remains in the separate [`lowest_common_ancestor_binary_lifting`](benchmarks/l/lowest_common_ancestor_binary_lifting/README.md) package. See the [kth-ancestor guide](benchmarks/b/binary_lifting_kth_ancestor/README.md).

## Remove Duplicate Words

The pinned Python routine splits the sentence, removes duplicate tokens, sorts the unique words lexicographically, and joins them with single spaces. The portable contract covers lowercase ASCII words with ASCII-space separators, including repeated, leading, and trailing spaces. All nine ports passed 3,816 independent inputs and recorded 12 workload cases. See the [guide](benchmarks/r/remove_duplicate/README.md), [verifier](benchmarks/verify_remove_duplicate.py), and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/remove_duplicate.py).


## R Bellman–Ford alias

The R `bellman_ford_shortest_path` source shares the directed signed-weight, source-reachable negative-cycle behavior of the all-destination package. Its one-based labels and `Inf` reachability need adapter normalization, and the alias is exact only when intermediate distances stay within the exact-integer range of binary64 (`|d| <= 2^53`). See the [benchmark guide](benchmarks/b/bellman_ford/README.md).


## AND gate

The pinned Python gate and nine portable ports share the binary 0/1 truth table. Python-specific type and value exceptions outside that domain are not part of the benchmark contract. See the [guide](benchmarks/a/and_gate/README.md).


## BFPRT selection

The pinned Java scalar helper returns the one-based kth-smallest value using median-of-medians and a copied array. Its separate vector-returning helper is outside this contract. See the [guide](benchmarks/b/bfprt/README.md).


## Bidirectional breadth-first search

The pinned Python grid demo omits discovered-state tracking and checks meetings only when both popped nodes agree, so some small cyclic grids can loop. The nine-port package follows the intended shortest-path operation with visited-on-enqueue, alternating complete layers, and deterministic first cross-frontier discovery. See the [guide](benchmarks/b/bidirectional_breadth_first_search/README.md).


## Base LFSR interface

The pinned Java `BaseLFSR` file declares initialization, clocking, and key/frame widths but no concrete register transition, so it is excluded as a standalone benchmark. A5/1 state progression is covered by the key-stream package.


## Bitap Exact Match (31-bit)

The pinned C# exact matcher returns the first lowercase-ASCII match and supports patterns up to 31 characters. It has a separate package from the Python Bitap contract, which permits 63-character patterns. See the [guide](benchmarks/b/bitap_exact_match_31/README.md).


## Positive Subset Sum Value Enumeration

The pinned R `find_all_subsets` routine returns value lists in include-first order and stops once a partial sum equals the target. The nine-port contract restricts items to strictly positive values so that early return is complete, and it preserves duplicate value lists from distinct positions. See the [guide](benchmarks/s/subset_sum_values_enumeration/README.md).


## Bellman–Ford Pair Query

The pinned Go method returns one target's reachability and distance and stores one weight per ordered edge pair. Its separate package preserves last-write parallel-edge semantics, bounds weights so all in-place float64 candidates remain exact, and reports source-reachable negative cycles. See the [pair-query guide](benchmarks/b/bellman_ford_pair/README.md) and the distinct [all-destinations guide](benchmarks/b/bellman_ford/README.md).


## N-Queens solution count

The scalar package counts the empty placement for n=0 and all solutions through n=8, normalizing orientation and DFS order across the pinned Dart, Python, Rust, Haskell, Java, and JavaScript count implementations. See the [guide](benchmarks/n/n_queens_solution_count/README.md).


## Linear feedback shift register

The pinned Java class exposes a concrete configurable register transition with 64-bit session-key and 22-bit frame initialization, tap-XOR feedback, right-shifted state, and discarded top-bit output. It is separate from the three-register A5/1 stream package. See the [guide](benchmarks/l/lfsr/README.md).

## Composite LFSR majority clock

The pinned Java `CompositeLFSR.clock` returns the XOR of the old top bits and advances only registers whose clock bit matches the majority. The package benchmarks one step from explicit A5 register states, not key initialization or full stream generation. All nine ports passed 275 independent register-bit oracle inputs each and recorded 14 workload cases. See the [guide](benchmarks/c/composite_lfsr_majority_clock/README.md), [byte-output verifier](benchmarks/verify_i64_array_bytes_output.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/a5/CompositeLFSR.java) under [MIT](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/LICENSE).
## Cyclic Sort

The pinned Python implementation validates a permutation of 1..n, then swaps each value into index value-1. The nine portable implementations copy the read-only ABI input, run cyclic sort, and return the sorted i64 values. They passed 6,425 independent oracle inputs each and recorded 10 workload cases. See the [benchmark guide](benchmarks/c/cyclic_sort/README.md), [verifier](benchmarks/verify_cyclic_sort.py), and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/cyclic_sort.py).


## BFS shortest path

The two pinned Python path functions normalize arrow-delimited and list outputs to a vertex path while preserving directed adjacency order. Unreachable behavior is normalized to `[0]`; the separate `_2` hop-distance helper is tracked independently because it returns edge count and assumes single-character labels. See the [path guide](benchmarks/b/breadth_first_search_shortest_path/README.md) and [distance guide](benchmarks/b/breadth_first_search_shortest_path_distance/README.md).


## Binary search tree source aliases

The Python recursive BST and both C++ `binary_search_tree2` copies map to the existing unique-key operation trace. The Python successor-based two-child deletion and package predecessor-based deletion produce the same observable key set and sorted checksum. Julia `basic_binary_search_tree` is excluded because it supplies only index lookup over an array tree whose insertion does not preserve key ordering.

## ARIMA with Pyramid notebook

The pinned Jupyter notebook fits a seasonal ARIMA model only through the external `pmdarima.auto_arima` call, then forecasts and plots a climate-data example; it does not include the fitting algorithm implementation to port. Its hidden `.ipynb_checkpoints` copy is byte-for-byte identical, so both filename candidates are recorded as reviewed non-benchmarkable notebook sources. See the [main notebook](https://github.com/TheAlgorithms/Jupyter/blob/ebf48b9d0373ae4caccd1d2fad54ad173dbac9e9/machine_learning/ARIMA/ARIMA%20with%20pyramid.ipynb) and [identical checkpoint](https://github.com/TheAlgorithms/Jupyter/blob/ebf48b9d0373ae4caccd1d2fad54ad173dbac9e9/machine_learning/ARIMA/.ipynb_checkpoints/ARIMA%20with%20pyramid-checkpoint.ipynb).

## Autoencoder notebook

The pinned Jupyter example loads MNIST, builds and trains a convolutional autoencoder through TensorFlow/Keras, then visualizes reconstructions. Dataset splitting and model initialization are random, and the notebook delegates the tensor operations and optimizer to TensorFlow; it does not provide a fixed-weight deterministic routine to port as a comparable cross-language benchmark. See the [notebook](https://github.com/TheAlgorithms/Jupyter/blob/ebf48b9d0373ae4caccd1d2fad54ad173dbac9e9/neural_network/autoencoder.ipynb).

## Graph Coloring by Backtracking

The pinned Go `Graph.ColorUsingBacktracking` tries colors from 1 through the vertex count in ascending vertex order. Under the simple loopless graph contract, each vertex can always use a color not assigned to an earlier neighbor, so the recursive routine reduces to first-fit coloring and does not find a minimum-color solution. The map output is normalized to dense vertex order. All nine ports passed 1,355 graph and ABI cases each; see the [benchmark guide](benchmarks/g/graph_coloring_backtracking/README.md), [verifier](benchmarks/verify_graph_coloring_backtracking.py), and pinned [Go implementation](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/coloring/backtracking.go).

## Graph m-Coloring by Backtracking

The pinned Python `color()` routine tries a caller-supplied number of colors in ascending order and returns its first complete assignment, or an empty list if none exists. This is distinct from Go's unrestricted first-fit routine above. The portable contract uses symmetric loopless adjacency matrices and preserves Python's zero-based color ordering. All nine ports passed 7,903 oracle and ABI cases each and recorded 11 workload cases; see the [benchmark guide](benchmarks/g/graph_m_coloring_backtracking/README.md), [verifier](benchmarks/verify_graph_m_coloring_backtracking.py), and pinned [Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/coloring.py).

## Columnar Transposition

The pinned Python implementation writes plaintext into unpadded ragged rows and reads columns in stable key order; decryption reconstructs each ragged column, preserving whitespace and punctuation. The contract keeps ASCII text and normalizes ASCII key letters while retaining duplicate-letter order. The Java implementation aliases this package only for ASCII text whose length is divisible by the key length and unique uppercase ASCII keys, where its padding is unused and column ordering agrees; its stateful `decrypt()` returns the prior table's plaintext. All nine ports passed 18,534 oracle and ABI cases each and recorded nine workload cases. See the [guide](benchmarks/c/columnar_transposition/README.md), [verifier](benchmarks/verify_columnar_transposition.py), pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/columnar_transposition.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/ColumnarTranspositionCipher.java).


## Ascon Digest

The pinned C# digest class exposes Ascon-Hash and Ascon-HashA, absorbs big-endian 8-byte blocks, and emits a 32-byte digest. The benchmark follows the source class’s fixed 12-round finalization for both variants and uses portable scalar 64-bit operations in all nine ports. They passed 433 source-vector, boundary, randomized, malformed-input, and output-capacity cases per language. See the [contract](benchmarks/a/ascon_digest/README.md), [verifier](benchmarks/verify_ascon_digest.py), and pinned [C# implementation](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Crypto/Digests/AsconDigest.cs).


## Automatic Differentiation (Reverse Mode)

The pinned Python module records NumPy variable operations and reverse-accumulates local derivatives. The portable contract covers scalar add, subtract, multiply, divide, and integer-power tapes, leaving array broadcasting and matrix multiplication outside this benchmark. All nine ports passed 281 cases against an independent forward-mode dual-number oracle. See the [contract](benchmarks/a/automatic_differentiation/README.md), [verifier](benchmarks/verify_automatic_differentiation.py), and pinned [source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/automatic_differentiation.py).


## Back Propagation Neural Network

The pinned Python file is a stochastic, plotting-oriented demo. The benchmark extracts one deterministic sample update for a supplied scalar 1→1→1 network, preserving the source's `weight * input - bias` net input, sigmoid activations, squared-error derivative, and reverse-layer updates. It excludes random initialization, dataset generation, and plotting. All nine portable ports passed 535 oracle/ABI cases each and recorded 16 workload cases. See the [contract](benchmarks/b/back_propagation_neural_network/README.md), [verifier](benchmarks/verify_back_propagation_neural_network.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/back_propagation_neural_network.py).


## Bag

The pinned C# and Java classes both provide a multiset with duplicates, size, emptiness, and traversal, but C# aggregates distinct values while Java prepends one node per insertion. The shared benchmark compares size, emptiness, and membership; Java uses `contains`, and C# membership is checked by iteration. All nine ports passed 546 oracle/ABI cases each and recorded 16 workload cases. See the [contract](benchmarks/b/bag/README.md), [verifier](benchmarks/verify_bag.py), and the pinned [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Bag/Bag.cs) and [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/bags/Bag.java) sources.


## Bandwidth Allocation

The pinned Java routine sorts by descending value/demand ratio, allocates full demands greedily, then truncates the final partial value to an integer. Its comment's example claims 40, while the method computes 42; the benchmark follows the executable code. All nine ports passed 33,084 oracle/ABI cases each and recorded 16 workload cases. See the [contract](benchmarks/b/bandwidth_allocation/README.md), [verifier](benchmarks/verify_bandwidth_allocation.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/greedyalgorithms/BandwidthAllocation.java).


## Barnsley Fern

The pinned Python source selects among four affine maps from a supplied sample stream, rounds each transformed coordinate to 12 decimal places, and emits the initial origin followed by each transformed point. The shared trace contract applies the source probability thresholds with Q12 integer state and nearest-even division, and returns Q6 point coordinates for deterministic portable comparison. All nine implementations passed 22,306 oracle/ABI cases each and recorded 16 workload cases. See the [benchmark guide](benchmarks/b/barnsley_fern/README.md), [verifier](benchmarks/verify_barnsley_fern.py), and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/fractals/barnsley_fern.py).


## Julia Basic module

The pinned Julia `Basic.jl` file only exports and includes `prefix_sum`, `DifferenceArray`, and `Hanoi`; it contains no algorithm implementation of its own. The included algorithms are tracked separately. See the [module source](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/basic/Basic.jl).


## Orbital capture radius and area

The pinned Python `basic_orbital_capture.py` supplies two separately benchmarked routines. `capture_radii` computes gravitational focusing from target radius, mass, and projectile speed; `capture_area` returns the circular cross-section. The bounded portable contracts preserve the source formulas and whole-unit nearest-even rounding. All nine language implementations passed the 19 radius and 10 area workload cases. See the [radius guide](benchmarks/o/orbital_capture_radii/README.md), [area guide](benchmarks/o/orbital_capture_area/README.md), [verifier](benchmarks/verify_orbital_capture.py), and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/basic_orbital_capture.py).


## Basic binary tree

The pinned Python and Dart basic-tree classes share a recursive fullness predicate and inorder traversal, mapped to [Binary Tree Is Full](benchmarks/b/binary_tree_is_full/README.md) and [Binary Tree Inorder Traversal](benchmarks/b/binary_tree_inorder_traversal/README.md). The Julia file uses an array-backed tree and exposes separate insertion, height/depth, leaf, and extreme-node helpers; those APIs are not treated as equivalent to the Python/Dart operations. The full-tree ports passed 728 generated oracle inputs per language, and the inorder ports passed 690. See the [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/basic_binary_tree.py), [Dart source](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/data_structures/binary_tree/basic_binary_tree.dart), and [Julia source](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/data_structures/binary_tree/basic_binary_tree.jl).

The pinned C# and JavaScript `BreadthFirstTreeTraversal` sources enqueue each node's left child before its right child and return values in level order. They alias mode 3 of the shared [`binary_tree_traversal`](benchmarks/b/binary_tree_traversal/README.md) contract.

The pinned Lua Brainfuck interpreter pairs brackets before running the eight commands, uses unsigned byte cells, treats exhausted input as zero, and ignores other program characters. The nine-port [`brainfuck`](benchmarks/b/brainfuck/README.md) contract adds finite instruction, tape, output, and capacity bounds for portable execution. See the [workload](benchmarks/b/brainfuck/workload.json) and pinned [Lua source](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/esolang/brainfuck.lua).

The Jupyter `basic_of_tensor_flow` notebook is a Colab/TensorFlow setup and operation demo with no standalone algorithm, so it is excluded.

The pinned Python `basic_string.py` implements stochastic genetic string search. The shared `string_genetic_algorithm` contract makes its random state and generation bound explicit, and retains the top 66 candidates by fitness to avoid the source’s first-66 selection defect. All nine ports passed 280 oracle cases and 17 workload records. See the [guide](benchmarks/s/string_genetic_algorithm/README.md), [verifier](benchmarks/verify_string_genetic_algorithm.py), and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/genetic_algorithm/basic_string.py).

The pinned C# `BasicTimSorter` uses insertion-sorted runs of 32 elements followed by stable bottom-up merges, matching the existing `tim_sort` contract; it is cataloged as an alias. See the [Tim sort guide](benchmarks/t/tim_sort/README.md) and [source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sorters/Comparison/BasicTimSorter.cs).

The pinned C# `TimSorter<T>` candidate maps to a distinct nine-language [`tim_sorter`](benchmarks/t/tim_sorter/README.md) contract. It sorts `(key,item_id)` records stably by key and checksums their full order, with fixed `minMerge=32` and `minGallop=7` settings. The contract records that `Sort` ignores its comparer argument and that the constructor snapshots `initMinGallop=0`; portable ports may omit galloping as a performance optimization. See the [workload](benchmarks/t/tim_sorter/workload.json), [verifier](benchmarks/verify_i64_array_scalar.py), and [pinned C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sorters/Comparison/TimSorter.cs).

The Jupyter `bayesian_belief_networks` notebook configures a fixed pgmpy model and delegates inference to `VariableElimination.query`; it contains no reusable inference implementation, so it is excluded as a library demo. See the [pinned notebook](https://github.com/TheAlgorithms/Jupyter/blob/ebf48b9d0373ae4caccd1d2fad54ad173dbac9e9/machine_learning/bayesian_belief_networks.ipynb).

The Python `benchmark_sorts.py` file is a timing and correctness driver around separately imported sort implementations; it does not define a sorting algorithm and is excluded. See the [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/benchmark_sorts.py).

The Python `BezierCurve` source evaluates a point from Bernstein weights and computes its tangent from adjacent control-point differences. The portable `bezier_curve` benchmark combines those numerical outputs, uses an integer binomial recurrence instead of SciPy, and excludes plotting. All nine ports passed 410 oracle cases and 16 workload records. See the [guide](benchmarks/b/bezier_curve/README.md), [verifier](benchmarks/verify_bezier_curve.py), and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphics/bezier_curve.py).

The Python `bi_directional_dijkstra.py` candidate maps to the existing directed nonnegative-weight [`bidirectional_dijkstra`](benchmarks/b/bidirectional_dijkstra/README.md) contract; its separate reverse graph is constructed from the shared edge list. See the [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/bi_directional_dijkstra.py).

The Python `bilateral_filter.py` source applies spatial and intensity Gaussian weights to a grayscale image and leaves the output border zero-filled. The nine-language [`bilateral_filter`](benchmarks/b/bilateral_filter/README.md) port uses a bounded row-major image contract and passed 187 oracle cases plus 16 workload records in every language. See the [verifier](benchmarks/verify_bilateral_filter.py) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/filters/bilateral_filter.py).

## Project Euler Problem 1

The pinned C and Dart `sol1` implementations use arithmetic-series inclusion-exclusion: sum the progressions for 3 and 5, then subtract the shared multiples of 15. Their formula is benchmarked separately as [`sum_multiples_inclusion_exclusion`](benchmarks/s/sum_multiples_inclusion_exclusion/README.md); Python `sol1` and Ruby `sol1` map to the existing direct-scan [`problem1`](benchmarks/p/problem1/README.md) contract. The new formula ports pass 2,557 direct-scan oracle inputs and 15 workload cases in each of the nine target languages.

## Project Euler Problem 15

The pinned Python `sol2.py` fills a two-dimensional grid table from its upper and left neighbors, giving an O(n²)-time and O(n²)-space path count. It is tracked separately from the central-binomial recurrence in `problem15`; both contracts bound square-grid side lengths to 0 through 20 and return -1 outside that domain. See the [dynamic-programming contract](benchmarks/p/problem15_dp/README.md), [workload](benchmarks/p/problem15_dp/workload.json), and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_015/sol2.py).

## Project Euler Problem 16

The pinned C and Python `sol1` sources sum the decimal digits of `2^exponent`; Python `sol2` uses repeated remainder/division instead of converting the power to text. They map to the bounded `problem16` contract for exponents 0 through 1,000, which normalizes their output to the scalar digit sum. See the [contract](benchmarks/p/problem16/README.md), [C source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/project_euler/problem_16/sol1.c), and [Python sources](https://github.com/TheAlgorithms/Python/tree/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_016).

## Project Euler Problem 203

The pinned Python source builds Pascal rows through the requested depth, deduplicates the coefficients, and sums those with no repeated prime factor. The benchmark preserves the source behavior that depths below 2 return 1, and bounds supported inputs at 51 for signed 64-bit arithmetic. The canonical result is 34029210557338. See the [contract](benchmarks/p/problem203/README.md) and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_203/sol1.py).

## Project Euler Problem 234

The pinned Python source sieves adjacent prime bounds and uses interval-based inclusion-exclusion to sum semidivisible integers. The nine ports preserve its traversal for inclusive limits from 0 through 999966663333; invalid limits return -1. The canonical result is 1259187438574927161. See the [contract](benchmarks/p/problem234/README.md) and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_234/sol1.py).

## Project Euler Problem 493

The pinned Python source computes the expected number of distinct colours and formats nine decimal places. The portable scalar benchmark represents that output as an integer scaled by 1,000,000,000 and preserves the combinatorial expectation for 0..70 picks. The canonical result is 6.818741802. See the [contract](benchmarks/p/problem493/README.md) and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_493/sol1.py).

## Project Euler Problem 551

The pinned Python source generates the digit-sum sequence with cached decimal-prefix jumps. The nine-language scalar benchmark returns a(n) for indices 1 through 10^15 and -1 outside that range. Its canonical result is 73597483551591773. See the [contract](benchmarks/p/problem551/README.md) and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_551/sol1.py).

## Project Euler Problem 111

The pinned Python source selects candidate digit width from the input text length, sieves primes, and searches repeated-digit patterns in zero-, one-, and conditionally two-replacement passes. The benchmark preserves that source traversal for width selectors from 1,000 through 10,000,000,000. The canonical result is 612407567715. See the [contract](benchmarks/p/problem111/README.md) and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_111/sol1.py).


The pinned MATLAB-Octave `blobDetection.m` and `BlobUsingVideo.m` demos use the same RGB-to-HSV segmentation, disk opening, and area-filtered 8-connected blob count, with two distinct threshold profiles. The demos depend on unavailable frame/video inputs and MATLAB toolboxes. The portable `blob_detection` contract exposes a profile selector, exact rational threshold comparisons, explicit radius-3 disk offsets, MATLAB-compatible morphology borders, and the default 50-object cap. All nine language ports passed 164 oracle arrays and 29 workload records. See the [guide](benchmarks/b/blob_detection/README.md), [verifier](benchmarks/verify_blob_detection.py), [pinned frame source](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/image-processing/Blob-detection-using-Matlab/blobDetection.m), and [pinned video source](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/image-processing/Blob-detection-using-Matlab/BlobUsingVideo.m).


The pinned Java `Blowfish.java` candidate is excluded because its key setup only mixes the 18 P-array entries and leaves the four S-boxes at their fixed initialization. Standard Blowfish key expansion repeatedly encrypts and replaces all P-array and S-box entries, so the source is not a correct Blowfish implementation. See the [catalog review](catalog/algorithm-candidates.json) and the pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/Blowfish.java). The pinned C# `BlowfishEncoder` candidate is also excluded: it only XORs values into the P-array, omits the standard P-array/S-box expansion, and slices key material in fixed eight-character chunks that fail for many valid key lengths. See its [catalog review](catalog/algorithm-candidates.json) and the pinned [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Encoders/BlowfishEncoder.cs).

The pinned Java `BM25InvertedIndex` search is ported in all nine languages over pre-tokenized term IDs. Its one-query IDF is a common positive factor, so the benchmark compares the exact rational frequency/length factor and uses ascending document IDs for score ties. All nine ports passed 7,779 oracle cases and 16 workload records. See the [guide](benchmarks/b/bm25_inverted_index/README.md), [verifier](benchmarks/verify_bm25_inverted_index.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/BM25InvertedIndex.java).

The pinned Python `Tokenizer` performs byte-level BPE by repeatedly selecting the most frequent adjacent token pair, preserving first-encounter order for ties, and merging non-overlapping occurrences. All nine ports passed 7,020 oracle cases and recorded 19 workload cases using pre-encoded bytes and little-endian u16 token IDs. See the [guide](benchmarks/b/bpe_tokenizer/README.md), [verifier](benchmarks/verify_bpe_tokenizer.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/bpe_tokenizer.py).

The pinned Python `BraikMac` constructs the six signed 5×5 determinant coefficients for a conic through five points. The portable benchmark uses integer coordinates from -10 through 10 and serializes exact coefficients before the source's display formatting. All nine ports passed 1,300 oracle cases and recorded 13 workload cases. See the [guide](benchmarks/b/braikenridge_maclaurin_construction/README.md), [verifier](benchmarks/verify_braikenridge_maclaurin_construction.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/geometry/braik_mac_construction.py).

The pinned Swift Minimax `Board` candidate maps to `n_in_a_row_board_status`: all nine ports check the selected player’s full rows, columns, and diagonals, then distinguish continuing boards from draws. Sizes start at two to avoid the source’s size-one false-win behavior. The ports passed 40,053 oracle cases each and 16 workload records. The pinned Rust `depth_first_search_tic_tac_toe` source is a separate deterministic minimax search: it evaluates alternating 3×3 board states and returns all tied best moves, while this benchmark only checks board status. See [the minimax search guide](benchmarks/d/depth_first_search_tic_tac_toe/README.md) and pinned [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/depth_first_search_tic_tac_toe.rs). See the [status guide](benchmarks/n/n_in_a_row_board_status/README.md), [verifier](benchmarks/verify_n_in_a_row_board_status.py), and pinned [Swift source](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/algorithms/AI/minimax/Sources/Minimax.playground/Sources/Model/Board/Board.swift).

The pinned JavaScript `ValidateCreditCard.js` candidate is tracked separately from the Python `credit_card_validator`: it doubles digits at even zero-based positions from the left, which differs from conventional length-aware Luhn parity on odd-length strings. The nine-port [`validate_credit_card`](benchmarks/v/validate_credit_card/README.md) contract preserves that source behavior and projects successful validation to 1. See the [workload](benchmarks/v/validate_credit_card/workload.json) and pinned [JavaScript source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/ValidateCreditCard.js).

The pinned JavaScript `BreadthFirstShortestPath.js` candidate maps to the existing ordered-neighbor [`breadth_first_search_shortest_path`](benchmarks/b/breadth_first_search_shortest_path/README.md) benchmark. Both use FIFO breadth-first expansion, preserve outgoing-neighbor order for equal-length paths, return a one-vertex path when start equals target, and report unreachable targets with an empty path (normalized to `[0]` in the portable ABI). See the pinned [JavaScript source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Graphs/BreadthFirstShortestPath.js).

The pinned Python `breadth_first_search_2.py` contains queue-based and deque-based full BFS traversals. Both append each vertex on first discovery; the shared [`breadth_first_search`](benchmarks/b/breadth_first_search/README.md) package normalizes neighbor order to ascending vertex IDs. See the pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/breadth_first_search_2.py).

The pinned Java `MaximumSlidingWindow.java` is another implementation of the existing [`sliding_window_maximum`](benchmarks/s/sliding_window_maximum/README.md) contract. It uses an index deque to emit the maximum from each positive-width window in left-to-right order, returning an empty array when the input is shorter than the window.

The pinned Python `proper_fractions` source emits reduced `n/d` strings in ascending numerator order for a supplied denominator. The nine-port [`proper_fractions`](benchmarks/p/proper_fractions/README.md) package preserves that sequence as newline-delimited ASCII for denominators 0 through 256, with an empty result for zero and one and -1 for malformed inputs. See the [workload](benchmarks/p/proper_fractions/workload.json), [verifier](benchmarks/verify_i64_array_bytes_output.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/numerical_analysis/proper_fractions.py).

The pinned Rust `temperature` source maps the selected scale to Kelvin before converting to the destination scale. The nine-port [`temperature`](benchmarks/t/temperature/README.md) package preserves that operation order across eight scales and bounds finite inputs to ±1,000,000. See the [workload](benchmarks/t/temperature/workload.json), [verifier](benchmarks/verify_temperature.py), and pinned [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/conversions/temperature.rs).

The pinned Python `p_series` source returns `1` followed by `1 / k^power` terms, and the nine-port contract records the source's spacing in newline-delimited ASCII. See the [guide](benchmarks/p/p_series/README.md), [workload](benchmarks/p/p_series/workload.json), and pinned [source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/series/p_series.py).

The pinned Python `logarithmic_series` source returns unevaluated symbolic terms with alternating signs and a base of `x_value-1`; the nine-port package fixes symbolic expansion off and preserves the source's negative-base string cleanup. See the [guide](benchmarks/l/logarithmic_series/README.md), [workload](benchmarks/l/logarithmic_series/workload.json), and pinned [source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/series/logarithmic_series.py).

The pinned Rust `weight` source converts among 23 units using a shared kilogram-factor table and the operation order `(value * from_factor) / to_factor`. The nine-port [`weight`](benchmarks/w/weight/README.md) package preserves its factor values and enum order, distinct from the separate 11-unit `weight_conversion` contract. See the [workload](benchmarks/w/weight/workload.json), [verifier](benchmarks/verify_weight.py), and pinned [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/conversions/weight.rs).

The pinned Ruby `weight_conversions` source exposes six formatted one-way conversions among kilograms, grams, pounds, and ounces. The nine-port [`weight_conversions`](benchmarks/w/weight_conversions/README.md) benchmark preserves negative integer floor division, two-decimal kilogram/pound rounding, and the method-specific strings; it is distinct from the 11-unit numeric [`weight_conversion`](benchmarks/w/weight_conversion/README.md) and the 23-unit Rust [`weight`](benchmarks/w/weight/README.md) contracts. See the [workload](benchmarks/w/weight_conversions/workload.json), [byte-output verifier](benchmarks/verify_i64_array_bytes_output.py), and pinned [Ruby source](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/conversions/weight_conversions.rb).

The pinned Python `sumset` source returns the set of every pairwise sum of values from its two input sets. The nine-port [`sumset`](benchmarks/s/sumset/README.md) package preserves set semantics and writes the distinct sums in ascending order as newline-delimited ASCII, with bounded integer inputs. See the [workload](benchmarks/s/sumset/workload.json), [byte-output verifier](benchmarks/verify_i64_array_bytes_output.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/sumset.py).

The pinned Python `middle_element_of_linked_list.py` uses fast/slow pointers, returns the second middle node for even-length lists, and returns no value for an empty list. It maps to the existing [`middle_of_linked_list`](benchmarks/m/middle_of_linked_list/README.md) benchmark, which represents the selected node by index instead of payload. See the pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/middle_element_of_linked_list.py).


The pinned Python `endianness` module provides three fixed-width byte swaps and little- and big-endian byte/integer conversions. The nine-port [`endianness`](benchmarks/e/endianness/README.md) package covers all seven helpers with byte lengths from one to eight and UInt64 bit-pattern transport; it is distinct from the signed 32-bit [`endian_converter`](benchmarks/e/endian_converter/README.md) and narrower [`byte_encoding_utils`](benchmarks/b/byte_encoding_utils/README.md) contracts. See the [workload](benchmarks/e/endianness/workload.json), [i64-array scalar verifier](benchmarks/verify_i64_array_scalar.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/endianness.py).

The pinned Python [`grahams_law.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/grahams_law.py) provides five positive-input solvers for effusion ratios, rates, and molar masses, rounding each result to six decimals. The nine-port [`grahams_law`](benchmarks/g/grahams_law/README.md) package preserves those formulas and rounding behavior across a bounded binary64 input contract. See the [workload](benchmarks/g/grahams_law/workload.json) and [verifier](benchmarks/verify_grahams_law.py).

The pinned Ruby `postorder_traversal` recursively emits each binary-tree node after its left and right subtrees. It maps to the indexed-tree [`binary_tree_postorder_traversal`](benchmarks/b/binary_tree_postorder_traversal/README.md) contract on nonempty trees.

The pinned Ruby `bst.rb` candidate maps to [`binary_search_tree`](benchmarks/b/binary_search_tree/README.md) on traces with distinct insertions and known-present deletes. Its duplicate insertion raises, so that behavior is outside the Ruby source mapping.

The pinned Java `BSTIterative`, `BSTRecursive`, and `BSTRecursiveGeneric` candidates also map to [`binary_search_tree`](benchmarks/b/binary_search_tree/README.md). Their ordered-set semantics match for insert, delete, and search traces; minimum, maximum, and size operations are outside those source APIs. The generic class is mapped over integer keys.

The Go `bstree` and PHP `BSTree` candidates also map to [`binary_search_tree`](benchmarks/b/binary_search_tree/README.md) on unique-insert traces with known-present deletes. Go ignores duplicate inserts, while PHP throws on them; PHP's stored values are outside the key-only contract.

The pinned Java `BSTFromSortedArray` candidate maps to [`bst_from_sorted_array`](benchmarks/b/bst_from_sorted_array/README.md). It recursively selects the lower midpoint of each sorted slice; all nine portable ports passed 317 oracle arrays and 13 workload cases using an implicit heap-index shape result.


The pinned Python brightness and contrast transforms map to separate flat-byte-channel contracts. Brightness uses bounded integer levels with saturating addition; contrast preserves the source rational factor and truncates toward zero before clipping. Both have nine-language ports and exhaustive byte-domain oracle coverage. See the [brightness guide](benchmarks/c/change_brightness/README.md) and [contrast guide](benchmarks/c/change_contrast/README.md). The pinned Python chaos machine combines sequential logistic-map state updates and xorshift output. Its nine-port contract resets per call and preserves ten-place ties-to-even rounding for deterministic seeded output; all ports passed 329 oracle inputs and 14 workload cases. See the [chaos-machine guide](benchmarks/c/chaos_machine/README.md) and [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/hashes/chaos_machine.py). The Python `convert_to_negative` function complements each OpenCV byte channel with `255 - channel`; nine ports preserve this transform over flattened image channels. See the [guide](benchmarks/c/convert_to_negative/README.md) and [source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/convert_to_negative.py).

The pinned Java `ChebyshevIteration.solve` routine starts from `x0`, computes `r = b - A*x`, applies its alpha/beta recurrence using the supplied spectral bounds, recomputes the residual after each update, stops only when its Euclidean norm is strictly below tolerance, and returns the last iterate at the iteration limit. The nine-language `chebyshev_iteration` benchmark uses dense matrices through dimension 8 with fixed-point integer inputs scaled to binary64; it assumes an SPD matrix and valid spectral bounds, which the source does not check. All nine portable ports passed 113 oracle inputs and 16 workload records each. See the [benchmark guide](benchmarks/c/chebyshev_iteration/README.md), [workload](benchmarks/c/chebyshev_iteration/workload.json), [verifier](benchmarks/verify_i64_array_bytes_output.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/ChebyshevIteration.java).

The pinned Lua `choiceset` module stores unique elements in a dense array and tracks their positions in a hash table. Its remove operation swaps in the last element; choose calls the injected random function with the current set size. The benchmark supplies that one-based random rank in each trace operation for deterministic results, and excludes the unordered iterator. All nine portable ports passed 150 oracle/ABI inputs and recorded 16 workload cases. See the [guide](benchmarks/c/choiceset/README.md), [workload](benchmarks/c/choiceset/workload.json), [verifier](benchmarks/verify_i64_array_bytes_output.py), and pinned [Lua source](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/random/choiceset.lua).

The pinned Python `chudnovsky_algorithm.pi` uses Decimal precision and removes the final character from its result string. This bounded contract preserves the source's initial Chudnovsky term for precision 1 through 12, including its empty precision-1 output and `3.` precision-2 output. All nine portable ports passed 32 oracle/ABI inputs and recorded 17 workload cases. See the [guide](benchmarks/c/chudnovsky_algorithm/README.md), [workload](benchmarks/c/chudnovsky_algorithm/workload.json), [verifier](benchmarks/verify_i64_array_bytes_output.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/chudnovsky_algorithm.py).


The pinned Julia `Cipher.jl` source only exports and includes the separately cataloged affine, Caesar, Atbash, and Vigenere ciphers; it defines no standalone operation and is excluded as an aggregator.


The pinned Java `CircularConvolutionFFT` source maps to the existing `circular_convolution` contract: it pads unequal signals to a common length, transforms them with Bluestein FFT, multiplies frequency bins, and applies the inverse transform. Its real-valued integer subset shares the existing exact circular-convolution workload.


The pinned Java `CircularLookScheduling.java` source maps to the nine-language `circular_look_scheduling` contract. It preserves the source’s request filtering, duplicate visits, and descending order in the downward branch’s wrap segment. All nine ports passed 1,512 oracle inputs and 17 workload records each. See the [guide](benchmarks/c/circular_look_scheduling/README.md), [workload](benchmarks/c/circular_look_scheduling/workload.json), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/diskscheduling/CircularLookScheduling.java).

The pinned Java `CircularScanScheduling.java` source maps to a separate nine-language `circular_scan_scheduling` contract. It preserves endpoint inclusion, the ascending upward wrap, the descending downward wrap, and the source's asymmetric filtering of requests beyond the disk bound. All nine ports passed 1,511 oracle inputs and 17 workload records each. See the [guide](benchmarks/c/circular_scan_scheduling/README.md), [workload](benchmarks/c/circular_scan_scheduling/workload.json), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/diskscheduling/CircularScanScheduling.java).

The pinned Java `ScanScheduling.execute` visits requests below the head and requests at or above it in separate sorted partitions. [`scan_scheduling`](benchmarks/s/scan_scheduling/README.md) preserves the up/down order, duplicate requests, and endpoint marker for nonempty schedules over bounded disk positions.


The pinned Python `CircularQueueLinkedList` uses a sentinel-based circular doubly linked ring. Configured at capacity 256, its enqueue, dequeue, front, and empty transitions map to the existing [`queue`](benchmarks/q/queue/README.md) benchmark. The Go `CircularQueue` array implementation maps its FIFO operations at the same capacity; its `Size()` returns capacity, so that method is excluded from the dynamic size query. Both are source aliases, not separate workloads. See the pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/queues/circular_queue_linked_list.py) and [Go source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/structure/circularqueue/circularqueuearray.go).

The Lua `class` filename is a metatable-based class-construction and inheritance helper, not a standalone algorithm, so it is excluded from benchmark coverage. See the pinned [Lua source](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/class.lua).

The Jupyter `clothing_detection` notebook downloads Fashion-MNIST, trains a fixed TensorFlow/Keras dense classifier, then reports accuracy and plots predictions. It is an application demo that depends on an external dataset and framework, not a standalone algorithm routine, so it is excluded. See the pinned [notebook](https://github.com/TheAlgorithms/Jupyter/blob/ebf48b9d0373ae4caccd1d2fad54ad173dbac9e9/other/clothing_detection.ipynb).

The Jupyter `cnn_pytorch` and `cnn_using_keras` notebooks assemble CNNs with framework layers, then download MNIST and train with PyTorch or Keras. They delegate convolution, autodifferentiation, and optimizer kernels to those frameworks and are dataset-backed tutorials rather than standalone portable algorithm implementations, so they are excluded. See the pinned [PyTorch notebook](https://github.com/TheAlgorithms/Jupyter/blob/ebf48b9d0373ae4caccd1d2fad54ad173dbac9e9/neural_network/CNN_Pytorch.ipynb) and [Keras notebook](https://github.com/TheAlgorithms/Jupyter/blob/ebf48b9d0373ae4caccd1d2fad54ad173dbac9e9/neural_network/CNN-using%20keras.ipynb).

The two pinned C++ `cll` class sources alias the existing [`circular_linked_list`](benchmarks/c/circular_linked_list/README.md) benchmark. They implement a singly circular list, but the `find_item` loop skips the tail and `operator++` leaks the removed head; those source defects are documented in the guide.


The pinned Java and Python `combination_sum` implementations use depth-first backtracking and permit reusing the current candidate. The shared contract requires ascending distinct positive candidates so their traversal order matches, and serializes every combination with its length. All nine portable ports passed 5,621 oracle/ABI inputs each and recorded 13 workload cases. See the [guide](benchmarks/c/combination_sum/README.md), [workload](benchmarks/c/combination_sum/workload.json), [verifier](benchmarks/verify_combination_sum.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/backtracking/CombinationSum.java) and [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/combination_sum.py).


The pinned Clojure `compress.clj` exposes three ways to retain the first element of each adjacent-equal run. The shared signed-i32 contract excludes `nil`, which two variants use as their previous-value sentinel, and requires worst-case output capacity. All nine ports passed 277 oracle/ABI inputs each and recorded 18 workload cases. See the [guide](benchmarks/c/compress/README.md), [workload](benchmarks/c/compress/workload.json), [verifier](benchmarks/verify_i64_array_bytes_output.py), and pinned [Clojure source](https://github.com/TheAlgorithms/Clojure/blob/a9c5bec14928cb22fd4d69e951edf5bd15e16a18/src/data_structures/lists/compress.clj).


## Jump Game

The pinned JavaScript Max Consecutive Ones III source uses a sliding window for the longest contiguous window with at most `k` zeroes. Its shrink check contains a pointer/value bug; the nine ports implement the intended bounded window contract. See the [benchmark guide](benchmarks/m/max_consecutive_ones_iii/README.md) and [pinned source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/Sliding-Window/MaxConsecutiveOnesIII.js).

The pinned C++ `can_jump` method scans backward, updating the earliest position known to reach the end. Its nonempty, bounded-jump contract is implemented in all nine languages; each passed 284 oracle arrays and 10 workload cases. See the [guide](benchmarks/j/jump_game/README.md) and pinned [C++ source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/greedy_algorithms/jump_game.cpp).


## Pairs with a Given Sum

The pinned Python `pairs_with_sum` enumerates all two-position combinations. The contract counts duplicate values at distinct indices and bounds its i32 inputs. All nine ports passed 280 oracle arrays and 16 workload cases. See the [guide](benchmarks/p/pairs_with_given_sum/README.md) and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/pairs_with_given_sum.py).


## Range in Sorted Array

The pinned Java `sortedRange` performs two iterative binary searches to find the first and last matching positions. Its `getCountLessThan` method is benchmarked separately as `count_less_equal_in_sorted_array`; despite its Javadoc, the helper counts values less than or equal to the key and can return the full array length. See the [range guide](benchmarks/r/range_in_sorted_array/README.md), [count guide](benchmarks/c/count_less_equal_in_sorted_array/README.md), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/RangeInSortedArray.java).

## Two hundredth reviewed benchmark algorithm: Constrained shortest path

The pinned Java solver uses dynamic programming over resource totals and nodes, then returns the minimum feasible target cost. The shared contract bounds graph size, edge costs, and resource use; requiring strictly positive resource per edge avoids the source's order-dependent updates from zero-resource edges. All nine language ports passed 270 oracle cases each and recorded 9 workload cases. See the [guide](benchmarks/c/constrained_shortest_path/README.md), [scalar verifier](benchmarks/verify_i64_array_scalar.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/ConstrainedShortestPath.java).

## Two hundred first reviewed benchmark algorithm: String comparison

The pinned AArch64 Assembly source provides a bytewise case-sensitive comparison and a variant that folds only ASCII uppercase letters. The portable contract uses explicit lengths for nonzero ASCII byte strings, defines both modes, and excludes the original console wrapper. All nine ports passed 285 oracle cases each and recorded 27 workload cases. The guide preserves the Rosetta Code attribution and CC BY-SA 4.0 license. See the [guide](benchmarks/c/comparison/README.md), [scalar verifier](benchmarks/verify_i64_array_scalar.py), and pinned [assembly source](https://github.com/TheAlgorithms/AArch64_Assembly/blob/cb138a856a3af14d3d3dfcd2743d43841eec566f/string/comparison.s).

## Two hundred second reviewed benchmark algorithm: Lipogram

The pinned Rust source computes the missing ASCII letters `a` through `z` and compares them with the caller's expected set. The portable benchmark packs the expected set into a 26-bit mask and restricts text to ASCII letters and whitespace so lowercasing and whitespace handling are consistent across languages. All nine ports passed 26 oracle cases each and recorded 10 workload cases. See the [guide](benchmarks/l/lipogram/README.md), [scalar verifier](benchmarks/verify_i64_array_scalar.py), and pinned [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a939ec5163648458a8c2b46fd4c/src/string/lipogram.rs) under the repository's [MIT license](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a939ec5163648458a8c2b46fd4c/LICENSE).

## Two hundred third reviewed benchmark algorithm: Hampel filter

The pinned Java streaming filter uses a three-sample causal window, computes its median and median absolute deviation, and replaces a sample only when its deviation is strictly above three scaled MADs. Raw outliers remain in the window. All nine ports passed 266 oracle cases each and recorded 8 workload cases. See the [guide](benchmarks/h/hampel_filter/README.md), [byte-output verifier](benchmarks/verify_i64_array_bytes_output.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/streaming/HampelFilter.java) under its [MIT license](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/LICENSE).

## Two hundred fourth reviewed benchmark algorithm: Nearest-neighbor interpolation

The pinned MATLAB `zoomimg.m` demo rounds each output coordinate divided by its fixed 1.5 scale to choose a source pixel. The benchmark exposes that loop over bounded grayscale matrices and excludes the demo's fixed image-file loading and plotting. All nine ports passed 273 oracle cases each and recorded 9 workload cases. See the [guide](benchmarks/n/nearest_neighbor_interpolation/README.md), [byte-output verifier](benchmarks/verify_i64_array_bytes_output.py), and pinned [MATLAB source](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/ImageProcessing/Nearest%20Neighbhor%20Interpolation/zoomimg.m) under its [MIT license](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/LICENSE).


## Two hundred fifth reviewed benchmark algorithm: Partition problem

The pinned C++ sources use bottom-up subset-sum reachability and the Java source delegates to its subset-sum helper to decide whether a nonempty multiset can be split into equal sums. The shared contract bounds the inputs to 1–16 nonnegative values, each at most 256 and total at most 1,024. All nine ports passed 1,727 subset-mask oracle cases each and recorded 13 workload cases. See the [guide](benchmarks/p/partition_problem/README.md), [verifier](benchmarks/verify_partition_problem.py), and pinned [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/partition_problem.cpp), [C++-1](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/dynamic_programming/partition_problem.cpp), and [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/PartitionProblem.java) sources under MIT.

## Two hundred sixth reviewed benchmark algorithm: Composite LFSR majority clock

The pinned Java `CompositeLFSR.clock` XORs the registers' old highest bits and shifts only those registers whose clock bits match the current majority. The package uses the A5 subclass's 19/22/23-bit register and tap configuration, with input states supplied directly. All nine ports passed 275 independent register-bit oracle cases each and recorded 14 workload cases. See the [guide](benchmarks/c/composite_lfsr_majority_clock/README.md), [byte-output verifier](benchmarks/verify_i64_array_bytes_output.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/a5/CompositeLFSR.java) under [MIT](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/LICENSE).


## Two hundred seventh reviewed benchmark algorithm: Union of Two Arrays

The two pinned C++ sources merge sorted arrays with two cursors, advance both on equality, and emit each value once. The shared contract accepts non-decreasing signed 32-bit inputs up to 64 values per array and returns the sorted unique union. All nine ports passed 280 independent oracle inputs each and recorded 21 workload cases. See the [guide](benchmarks/u/union_of_two_arrays/README.md), [byte-output verifier](benchmarks/verify_i64_array_bytes_output.py), and pinned [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/operations_on_datastructures/union_of_two_arrays.cpp) and [C++-1](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/operations_on_datastructures/union_of_two_arrays.cpp) sources under MIT.

The pinned Go unionfind.go initializes a parent per element, compresses paths in Find, and merges roots by rank in Union. Its operations map to the existing [union_find](benchmarks/u/union_find/README.md) contract, so this reviewed candidate is an alias rather than a separate benchmark.

## Two hundred eighth reviewed benchmark algorithm: Unique Letters Count

The pinned R example filters to ASCII letters, lowercases them, and prints frequency counts in first-appearance order. The shared contract makes its character domain explicit and encodes each lowercase letter/count pair as little-endian signed 32-bit values. All nine ports passed 276 independent oracle inputs each and recorded 18 workload cases. See the [guide](benchmarks/u/unique_letters_count/README.md), [byte-output verifier](benchmarks/verify_i64_array_bytes_output.py), and pinned [R source](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/string_manipulation/unique.letters.count.r) under its [MIT license](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/LICENSE).

## Two hundred ninth reviewed benchmark algorithm: Complex Arithmetic

The pinned Lua complex-number module and the two identical C++ classes share addition, subtraction, multiplication, division, conjugation, and equality. The contract uses bounded integer components and accepts division only when both quotient components are exact integers; floating-only helpers and string formatting remain outside this package. All nine ports passed 277 oracle cases each and recorded 15 workload cases. See the [guide](benchmarks/c/complex_arithmetic/README.md), [byte-output verifier](benchmarks/verify_i64_array_bytes_output.py), pinned [Lua source](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/math/complex.lua), and identical [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/complex_numbers.cpp) and [C++-1](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/complex_numbers.cpp) sources.

## Two hundred tenth reviewed benchmark algorithm: Linear Regression Cost

The pinned MATLAB/Octave `computecost` function multiplies a feature matrix by its parameter vector, then returns the half-mean-squared residual. The bounded contract includes up to 64 observations and 16 features. All nine ports passed 281 oracle inputs each and recorded 19 workload cases. The separate `gradientdescent` files map to the existing batch-gradient benchmark on its one-feature, zero-initialization domain; the benchmark records the final slope, while the MATLAB API also returns the intercept. The pinned `plotdata` and `runLinearRegression` files are visualization and interactive-demo helpers. See the [cost guide](benchmarks/l/linear_regression_cost/README.md), [float64 verifier](benchmarks/verify_i64_array_float64.py), and pinned [computecost source](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/machine_learning/Linear-Regression/computecost.m).


## Two hundred eleventh reviewed benchmark algorithm: Conjugate Gradient

The pinned Python solver starts from a zero vector and follows the standard conjugate-gradient recurrence for symmetric positive-definite systems. The shared contract uses bounded exactly symmetric, strictly diagonally dominant matrices and an exact-rational oracle; the ports stop on residual norm to avoid the source's zero-denominator edge case after exact convergence. See the [guide](benchmarks/c/conjugate_gradient/README.md), [oracle](benchmarks/conjugate_gradient_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/linear_algebra/src/conjugate_gradient.py).

## Two hundred twelfth reviewed benchmark algorithm: Convolutional Neural Network Inference

The pinned Python CNN inference path performs valid convolution, sigmoid activation, average pooling, flattening, and two dense sigmoid layers. The benchmark passes fixed model parameters as input, returns probabilities rounded to three decimals, and excludes training and model persistence. All nine ports build and pass 12 workload cases; see the [guide](benchmarks/c/convolution_neural_network/README.md), [oracle](benchmarks/convolution_neural_network_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/convolution_neural_network.py).

## Two hundred thirteenth reviewed benchmark algorithm: Image Convolution

The pinned Python `img_convolve` function edge-pads a square grayscale image and takes row-major dot products with the kernel, without reversing its orientation. The benchmark restricts inputs to square images and odd kernels to preserve the source's valid same-size reshape. All nine ports build and pass 13 workload cases; see the [guide](benchmarks/i/image_convolution/README.md), [oracle](benchmarks/image_convolution_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/filters/convolve.py).

The JavaScript `ConwaysGameOfLife.js` and Python `conways_game_of_life.py` sources both implement one finite-board B3/S23 transition. They map to the existing [game_of_life](benchmarks/g/game_of_life/README.md) benchmark; the image-animation wrapper is excluded.

The JavaScript `Coordinate.js` source defines two scalar formulas: Euclidean distance in 2D and Manhattan distance in 2D. These are covered as dimensional subsets of the existing [euclidean_distance](benchmarks/e/euclidean_distance/README.md) and [manhattan_distance](benchmarks/m/manhattan_distance/README.md) contracts.
The pinned Python `m_coloring_problem` backtracking routine returns whether an undirected graph can be colored with at most `m` colors. This aliases [`graph_m_coloring_backtracking`](benchmarks/g/graph_m_coloring_backtracking/README.md) by projecting a nonempty first-coloring result to true; the empty-graph input is outside that projection. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/m_coloring_problem.py).
The pinned C# `Manhattan.Distance` sums absolute coordinate differences for equal-length points, matching the bounded [`manhattan_distance`](benchmarks/m/manhattan_distance/README.md) contract. [Pinned C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/LinearAlgebra/Distances/Manhattan.cs).

The Clojure dynamic-array and stack `core.clj` files map to the existing [dynamic_array](benchmarks/d/dynamic_array/README.md) and [stack](benchmarks/s/stack/README.md) operation traces. Their formatting and additional capacity/removal helpers remain outside those shared contracts.

## Two hundred fourteenth reviewed benchmark algorithm: Matrix Copy

The pinned Go `Matrix.Copy` allocates a new matrix and copies each element; a zero dimension returns the zero Matrix. The portable benchmark preserves values, dimensions, and empty-matrix behavior while excluding goroutine scheduling. All nine ports build and pass 13 workload cases; see the [guide](benchmarks/m/matrix_copy/README.md), [oracle](benchmarks/matrix_copy_oracle.py), and pinned [Go source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/matrix/copy.go).


## Two hundred fifteenth reviewed benchmark algorithm: Logistic Regression Cost and Gradient

The pinned MATLAB-Octave `costfunction.m` returns mean binary cross-entropy and the mean gradient with respect to each supplied parameter. Nine portable implementations use a bounded rectangular design matrix and produce the complete loss-plus-gradient vector. All nine compile and pass the 11 workload cases; see the [guide](benchmarks/l/logistic_regression_cost_gradient/README.md) and pinned [MATLAB source](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/machine_learning/Logistic-Regression/costfunction.m).

## Two hundred sixteenth reviewed benchmark algorithm: CRC Polynomial Division

The pinned Java `CRCAlgorithm` attempts CRC encoding and syndrome checking, but XORs polynomial windows even when their leading bit is zero and removes leading remainder bits without restoring the generator’s fixed degree. The portable contract applies standard GF(2) division and emits the full-width remainder, making encoded codewords pass the same check operation. Random transmission simulation is excluded. All nine ports passed 46,969 oracle cases each; see the [benchmark guide](benchmarks/c/crc_polynomial_division/README.md), [verifier](benchmarks/verify_crc_polynomial_division.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/CRCAlgorithm.java).

## Two hundred seventeenth reviewed benchmark algorithm: Modular Inverse with Fermat's Little Theorem

The two pinned C++ candidates use trial primality testing and binary exponentiation, but their wrappers differ on negative bases and multiples of the modulus. The shared positive-base contract rejects non-coprime inputs and bounds the modulus so modular products fit signed 64-bit arithmetic. All nine ports passed 408 oracle pairs each and recorded 15 workload cases; see the [guide](benchmarks/m/modular_inverse_fermat_little_theorem/README.md), [binary-scalar verifier](benchmarks/verify_binary_scalar.py), and pinned [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/modular_inverse_fermat_little_theorem.cpp) and [C++-1](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/modular_inverse_fermat_little_theorem.cpp) sources.

## Two hundred eighteenth reviewed benchmark algorithm: Linear Recurrence Matrix

Both pinned C++ sources implement matrix exponentiation for general linear recurrences and agree on the examples; the C-Plus-Plus-1 copy omits an explicit `<cstdint>` include. The shared contract fixes the modulus at 1,000,000,007, supports dimensions 1–4, and preserves the optional constant/sum offset behavior. All nine ports passed 588 oracle arrays each and recorded 36 workload cases; see the [guide](benchmarks/l/linear_recurrence_matrix/README.md), [array-scalar verifier](benchmarks/verify_i64_array_scalar.py), and pinned [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/linear_recurrence_matrix.cpp) and [C++-1](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/linear_recurrence_matrix.cpp) sources.

## Two hundred nineteenth reviewed benchmark algorithm: Recursive Linear Search

The pinned Fortran and Ruby implementations recursively search a linear array in different directions, and Fortran returns a one-based index while Ruby returns zero-based. The shared distinct-value contract gives each match one position and normalizes the result to a zero-based index. The scalar verifier covers bounded oracle arrays and the workload records 22 cases; see the [guide](benchmarks/r/recursive_linear_search/README.md), [array-scalar verifier](benchmarks/verify_i64_array_scalar.py), and pinned [Fortran](https://github.com/TheAlgorithms/Fortran/blob/c91199703b78bd2181051b01bd5269740e41e121/modules/searches/recursive_linear_search.f90) and [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/searches/recursive_linear_search.rb) sources.

## Two hundred twentieth reviewed benchmark algorithm: Recursive Shuffler

The pinned C# source cancels each recursive Fisher–Yates swap with a second identical swap and reinitializes its seeded random generator at every recursion level. The portable benchmark follows the documented recursive shuffle intent, fixes the stream with Park–Miller, and bounds recursion to 64 values. All nine ports passed 336 oracle inputs each and recorded 13 workload cases; see the [guide](benchmarks/r/recursive_shuffler/README.md), [byte-output verifier](benchmarks/verify_i64_array_bytes_output.py), and pinned [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbb6c/Algorithms/Shufflers/RecursiveShuffler.cs).

## Two hundred twenty-first reviewed benchmark algorithm: Wildcard Matching

The pinned C++, Java, Python, and Go sources match full strings using `?` for one character and `*` for any sequence. The two C++ sources keep memoized answers in a process-global table; the portable benchmark uses an isolated bounded dynamic-programming table per call. All nine ports passed 1,557 oracle arrays each and recorded 20 workload cases; see the [guide](benchmarks/w/wildcard_matching/README.md), [array-scalar verifier](benchmarks/verify_i64_array_scalar.py), and pinned sources linked there.

## Two hundred twenty-second reviewed benchmark algorithm: Primitive Root Search

The pinned Python `find_primitive` routine returns the first candidate whose first `modulus - 1` modular powers are distinct. The benchmark preserves this exact search behavior, including returning no candidate for composite modulus 4 despite the conventional primitive root 3. All nine ports passed 137 oracle arrays each and recorded 15 workload cases; see the [guide](benchmarks/p/primitive_root/README.md) and [array-scalar verifier](benchmarks/verify_i64_array_scalar.py).

The pinned Java `RedBlackBST` candidate aliases the existing [red-black insert/search](benchmarks/r/red_black_tree_insert_search/README.md) contract for its unique-key insertion and lookup routines. Its delete method operates on the fresh query node instead of the located tree node, so the broken deletion and interactive demo I/O are excluded.

## Two hundred twenty-third reviewed benchmark algorithm: Dijkstra's two-stack expression evaluation

The Python `dijkstras_two_stack_algorithm` source is Dijkstra's fully parenthesized infix expression evaluator, not graph shortest paths. The new nine-language benchmark uses separate operand and operator stacks over single-digit ASCII expressions, with exact integer division and bounded intermediates. See the [guide](benchmarks/d/dijkstras_two_stack_algorithm/README.md) and [source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/dijkstras_two_stack_algorithm.py).

## Two hundred twenty-fourth reviewed benchmark algorithm: Undirected cycle check

The pinned Rust `detect_cycle.rs` contains both directed and undirected graph routines. Its directed DFS and Kahn routines alias [`check_cycle`](benchmarks/c/check_cycle/README.md); its undirected DFS and BFS routines map to this separate benchmark, which tracks parent vertices while traversing a bounded simple undirected graph. Self-loops count as cycles, duplicate undirected edges are rejected as malformed input, and the nine implementations use portable iterative DFS. See the [guide](benchmarks/u/undirected_cycle_check/README.md) and [pinned Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/detect_cycle.rs).

## Directed Eulerian path

The pinned Rust `eulerian_path.rs` uses degree balance to select a start vertex and Hierholzer traversal to consume every directed edge exactly once. The new nine-language benchmark retains its adjacency-list order, accepts parallel edges and self-loops, and returns the vertex sequence or an empty result when no Eulerian path exists. See the [benchmark guide](benchmarks/e/eulerian_path/README.md) and [pinned Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/eulerian_path.rs).

## Horizontal projectile motion

The pinned Python source computes horizontal range, maximum height, and flight time with `g = 9.80665`, rounding each result to two decimals using Python's ties-to-even rule. The nine-language contract uses scaled integer inputs and emits the three results as little-endian float64 values. This remains separate from `ground_to_ground_projectile_motion`, which exposes a different input surface and unrounded results. See the [benchmark guide](benchmarks/h/horizontal_projectile_motion/README.md) and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/horizontal_projectile_motion.py).

## Dark sort

The pinned Java `DarkSort` counts nonnegative keys with a `max + 1` histogram. Its source domain does not match the signed range of the existing counting-sort benchmark, so it has a separate bounded `[0,128]` contract and nine-language package; see [the guide](benchmarks/d/dark_sort/README.md) and [pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/DarkSort.java).

## Frequency Finder

The pinned Python `english_freq_match_score` counts ASCII letters, sorts counts descending, and sorts equal-count groups by reverse ETAOIN order. The benchmark returns the source's score rather than the helper frequency-order string; see [the guide](benchmarks/f/frequency_finder/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/frequency_finder.py).

## Floor and ceiling in a binary search tree

The pinned Python `floor_ceiling` follows one BST path and returns both the greatest value at most the key and the least value at least the key. Missing sides are encoded with `INT64_MIN` in the bounded pair-output contract; see [the guide](benchmarks/f/floor_and_ceiling/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/floor_and_ceiling.py).

## Solve a quadratic equation

The pinned Lua p-q solver returns the minus-square-root result first, collapses a repeated root to one return value, and returns no values for a negative radicand. The separate bounded package preserves this variable-length vector behavior; see [the guide](benchmarks/s/solve_quadratic_equation/README.md) and [pinned source](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/math/solve_quadratic_equation.lua).

## Jarvis scan

The pinned Rust `jarvis_march` starts at the leftmost, then bottommost point and wraps counter-clockwise around the hull. The pinned Python `jarvis_march` and both C++ `jarvis_algorithm` copies implement the same gift-wrapping scan and are reviewed aliases. The C++ source is equivalent on inputs with at least three valid points and a unique minimum x; equal-leftmost-x ties are outside that alias because C++ keeps the first input point while the canonical contract breaks ties by lowest y. The benchmark uses bounded integer coordinates with distinct points and no collinear triples so all nine implementations share exact cross-product decisions. See the [benchmark guide](benchmarks/j/jarvis_scan/README.md) and its pinned Rust, [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/geometry/jarvis_march.py), and [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/geometry/jarvis_algorithm.cpp) sources.

## Reviewed candidate: reverse letters

`reverse_letters` appears in pinned F-Sharp and Python sources. Under the Python default threshold, both reverse each word while preserving word order. The benchmark limits inputs to printable ASCII words separated by single spaces to normalize source whitespace and Unicode differences. See [`benchmarks/r/reverse_letters/README.md`](benchmarks/r/reverse_letters/README.md).

The pinned JavaScript `fisher_yates_shuffle` candidate uses the descending Fisher–Yates swap loop. The Dart source calls `nextInt(i - 1)`, excluding legal swap choices, and the Rust source iterates `0..(len - 2)`, omitting the last forward swap and underflowing for slices shorter than two elements. The benchmark normalizes these sources to the canonical descending loop with a seeded Park–Miller stream and checks the resulting permutation bytes across all nine benchmark languages; see the [Fisher–Yates guide](benchmarks/f/fisher_yates_shuffle/README.md).

## F-Sharp prefix and suffix aliases

The pinned F-Sharp `has_prefix` and `has_suffix` helpers use ordinal substring comparisons. They map to the prefix and suffix modes of the existing [`string_prefix_suffix`](benchmarks/s/string_prefix_suffix/README.md) benchmark, which has nine-language ports and covers empty patterns and longer-than-text patterns.

## H-candidate review notes

The F-Sharp prefix/suffix helpers and Python `has_loop` map to the existing [`string_prefix_suffix`](benchmarks/s/string_prefix_suffix/README.md) and [`linked_list_has_cycle`](benchmarks/l/linked_list_has_cycle/README.md) contracts. Go `hexadecimaltodecimal` maps to [`hexadecimal_to_decimal`](benchmarks/h/hexadecimal_to_decimal/README.md), and the Haskell umbrella module maps to [`bubble_sort`](benchmarks/b/bubble_sort/README.md). The C Hangman program, Java `HeapElement` support type, and Jupyter house-price workflow are excluded as non-benchmarkable. `hamiltonian` groups unrelated graph-path and physics calculations; `hashing_traits` references a missing pinned file.

## Gauss-Seidel method

The pinned Python source supplies the generic sequential Gauss-Seidel contract in [`gauss_seidel_method`](benchmarks/g/gauss_seidel_method/README.md). The same-name pinned C file is a fixed three-variable example with a different and less strict stopping condition; the benchmark documents that divergence and follows Python's all-coordinate tolerance check and iteration limit.

## Gauss optimization

The pinned C# `GaussOptimization.Optimize` method searches four coordinate neighbors, keeps the first maximum in bottom/top/left/right order, updates one coordinate, and divides the step by its reduction factor. The [`gauss_optimization`](benchmarks/g/gauss_optimization/README.md) benchmark fixes the callback to a negative squared-distance surface around a supplied target and bounds the iterations for portable calls across all nine languages.

## Trapping rainwater source aliases

The pinned Java `TrappingRainwater.trap` implementation uses the two-pointer, constant-space algorithm and is cataloged as an alias of [`trapped_rainwater2`](benchmarks/t/trapped_rainwater_two_pointer/README.md) on its Java-safe subdomain of at most 2,048 heights in [0, 1,000,000]; the maximum trapped volume there is 2,046,000,000, within signed int range. Its right-on-tie loop is distinct from the prefix/suffix-maxima `trapped_rainwater` algorithm. The pinned Go `traprainwater` implementation uses prefix and suffix maxima and aliases [`trapped_rainwater`](benchmarks/t/trapped_rainwater/README.md). Their algorithm and space profiles remain separate.

## Diffie–Hellman shared secret

The pinned Java, Python, Rust, and Go implementations support a two-party modular-exponentiation exchange. The Go source fixes generator 3 and prime 6,700,417; the shared contract includes that group and computes the shared integer from a generator, two private exponents, and a prime modulus with primality and range validation. It excludes random secret generation, other predefined large groups, key encodings, public-key subgroup validation, and the Python SHA-256 wrapper. All nine ports passed 13 oracle inputs each, including the Go fixed group; see the [guide](benchmarks/d/diffie_hellman/README.md).
## Speed conversion

The pinned PHP `SpeedConversion.php` converts speeds among mph, km/h, m/s, ft/s, and knots using the source and destination factors in source order, then applies PHP rounding to two decimal places. This distinct algorithm is ported to all nine target languages under a bounded route contract; see the [guide](benchmarks/s/speed_conversion/README.md) and [workload](benchmarks/s/speed_conversion/workload.json).

## Magic diamond pattern

The pinned Python `pretty_print` combines Floyd's left-padded upper triangle with a reverse lower triangle, preserving trailing spaces; nonpositive sizes return a fixed message. The bounded bytes benchmark follows that output for sizes through 45. See the [guide](benchmarks/m/magicdiamondpattern/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/magicdiamondpattern.py).

The pinned Go `sieve.Generate(limit)` channel pipeline produces the first `limit` primes and aliases the bounded [`first_n_primes`](benchmarks/f/first_n_primes/README.md) contract; negative and over-limit counts are outside that contract.

The Go `shared` filename groups Aho–Corasick trie helpers and separate linked-list utilities; it is excluded as a filename collision rather than treated as one benchmark algorithm.

The pinned Python `three_sum` implementation aliases [`3sum`](benchmarks/0-9/3sum/README.md): both use duplicate-skipping two-pointer search for unique zero-sum triplets. The Python source sorts its list in place, which is not observable through the packed benchmark ABI.

## Word patterns

The pinned Python `get_word_pattern` uppercases the input, assigns each distinct character its first-seen index, and joins those indices with periods. The nine-language benchmark keeps this behavior for bounded ASCII input; see [`benchmarks/w/word_patterns/README.md`](benchmarks/w/word_patterns/README.md).

The Haskell `Setup.hs` delegates package setup to `Distribution.Simple`, and Java `TreeNode` is a mutable node DTO; both are excluded as build/support files rather than standalone benchmark algorithms.

The pinned Python `sentence_to_title_case` matches the [`title_case_conversion`](benchmarks/t/title_case_conversion/README.md) contract on ASCII-letter words separated by single spaces; whitespace normalization outside that domain is excluded.

The pinned Java `ZigZagPattern.encode` follows the same row-cycle and interior-diagonal indexing as [`zigzag_conversion`](benchmarks/z/zigzag_conversion/README.md); `zig_zag_pattern` is cataloged as an alias under the bounded ASCII contract.

The pinned JavaScript `mColoring` routine aliases [`graph_m_coloring_backtracking`](benchmarks/g/graph_m_coloring_backtracking/README.md): both choose the first DFS coloring in vertex and color order. The alias normalizes JS color labels from 1-based to 0-based and represents an impossible graph as an empty byte result.

## Shrink Shell sort

The pinned Python [`shrink_shell_sort.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/shrink_shell_sort.py) uses `int(gap / 1.3)` before each gapped insertion pass. It has a distinct gap sequence from the halving-gap and Ciura-gap Shell sort benchmarks; see [`benchmarks/s/shrink_shell_sort/README.md`](benchmarks/s/shrink_shell_sort/README.md).

The C `malloc_dbg` files wrap the system allocator, track process-global allocations, and print leak reports at exit; they are developer instrumentation rather than a standalone algorithm benchmark and are excluded.

## Welford's variance

The pinned C# `WelfordsVariance` maintains a running mean and squared-deviation total, returning sample variance as `M2 / (count - 1)`. This one-pass recurrence is distinct from the existing two-pass [`variance`](benchmarks/v/variance/README.md) benchmark; see [`benchmarks/w/welfords_variance/README.md`](benchmarks/w/welfords_variance/README.md).

The pinned Fortran `trapezoid`, Julia `trapezoid_integration`, and Python `trapezoidal_rule` sources alias [`trapezoidal_integration`](benchmarks/t/trapezoidal_integration/README.md) on the documented bounded function and endpoint domains. Each computes the composite trapezoidal sum; Python's alias is limited to its x² callback. Floating summation order can differ.

## XTEA

The pinned Python implementation encrypts one 64-bit block with the XTEA 32-bit update and 128-bit key. The benchmark preserves big-endian block encoding and bounds the rounds to 1–64; see [`benchmarks/x/xtea/README.md`](benchmarks/x/xtea/README.md).

The array-search routines in the pinned Fortran `ternary_search_module` and Rust `ternary_search_recursive` sources alias [`ternary_search`](benchmarks/t/ternary_search/README.md). Fortran indices are normalized to zero-based; the Rust source's inclusive-end and underflow hazards are avoided by the bounded ABI adapter. The Fortran module's separate function-min/max helpers are not part of this alias.

The Go `testcases` source contains search test fixtures, Haskell `TestData` is an empty test-data module, Julia `TheAlgorithms.jl` is a package entrypoint, and C# `TimSorterSettings` is a settings record; these are excluded as support/configuration rather than algorithms.

The four pinned C TCP client/server programs are interactive network demonstrations using sockets, process forks, blocking I/O, and infinite communication loops; they are excluded from deterministic algorithm benchmarks.

## Z-block substring search

The pinned C# implementation uses Z blocks and returns the count of exact pattern matches. The benchmark keeps overlapping matches, excludes `$` to avoid separator collisions, and remains distinct from the position-list Z search contract; see [`benchmarks/z/zblock_substring_search/README.md`](benchmarks/z/zblock_substring_search/README.md).

The pinned Java `WelfordAlgorithm` shares the online add recurrence and sample-variance definition with [`welfords_variance`](benchmarks/w/welfords_variance/README.md); its extra remove/merge operations are outside that contract.

## Interleaving strings

The pinned Go dynamic program checks whether a target can interleave the two source strings while preserving each source order. The bounded ASCII version is ported to all nine languages; see [`benchmarks/i/interleavingstrings/README.md`](benchmarks/i/interleavingstrings/README.md).

The pinned Lua `three_way_partition.lua` implements Dutch national flag partitioning across an inclusive range. The `three_way_partition` contract applies it to a bounded full array and reports zero-based half-open less-than and greater-than boundaries alongside the permuted values. See the [guide](benchmarks/t/three_way_partition/README.md) and [pinned Lua source](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/sorting/three_way_partition.lua).

## Half-wave rectifier calculations

The pinned Python module defines six deterministic electrical calculations. A selector-based bounded benchmark ports their formulas and resistance constraints to nine languages; see [`benchmarks/h/half_wave_rectifier/README.md`](benchmarks/h/half_wave_rectifier/README.md).

## IPv4-mapped IPv6 conversion

The pinned Java converter maps IPv4 addresses to and from the `::ffff:` IPv4-mapped form. A raw-byte contract removes host-resolver/text-format variability while preserving both directions; see [`benchmarks/i/ipv6_converter/README.md`](benchmarks/i/ipv6_converter/README.md).

The pinned C `udp_client.c` and `udp_server.c` are live network demonstrations with hard-coded endpoints, socket setup, blocking datagram I/O, and console output. They are excluded as environment-dependent applications rather than deterministic standalone algorithms. See the [client source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/client_server/udp_client.c) and [server source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/client_server/udp_server.c).

The pinned Lua `table_stack.lua` wraps Lua table insertion/removal with top and empty operations, matching the bounded LIFO trace contract. Candidate `table_stack` aliases [`stack`](benchmarks/s/stack/README.md); the source's unbounded capacity is restricted to the shared trace limit.

The pinned iterative Rust `ternary_search_min_max.rs` evaluates the same maximum and minimum quadratics and uses the same trisection update rules and final `f(start)` result as the recursive source. Candidate `ternary_search_min_max` aliases the bounded [recursive ternary min/max contract](benchmarks/t/ternary_search_min_max_recursive/README.md).

## Hamming code encoder

The pinned Python module contains a deterministic Hamming emitter alongside decoding and an interactive error demonstration. The benchmark isolates encoding and preserves the source parity-count condition; see [`benchmarks/h/hamming_code/README.md`](benchmarks/h/hamming_code/README.md).

The pinned Jupyter `text_classification_using_BERT.ipynb` installs Transformers, downloads the `bert-base-uncased` model/tokenizer, and trains on an external custom CSV dataset using a GPU runtime. Its model/data/runtime dependencies prevent a deterministic portable benchmark contract, so it is excluded.

## KMP source aliases

The pinned Go, Java, JavaScript, R, Julia, and C# KMP candidates expose all-match lists, first-match positions, or differing index bases. Their first exact match maps to the shared bounded ASCII [`knuth_morris_pratt`](benchmarks/k/knuth_morris_pratt/README.md) contract; case folding is disabled for the Julia source and indices are normalized where needed.

Both pinned C++ `text_search.cpp` candidates are the same interactive CLI that prompts for a paragraph, query, and case-sensitivity setting, calls `std::string::find`, and prints results in an endless loop. The lowercase helper is incidental; the source is excluded as an interactive program without a reusable search API.

The pinned Java `TreeRandomNode` accumulates an inorder traversal in a static list, samples it with `Math.random()`, and prints the chosen value. Its nondeterministic output and retained global state do not provide a stable standalone result contract, so `tree_random_node` is excluded.

## IMPLY gate

The pinned Python module defines a two-input truth-table function and a separate recursive list helper. The benchmark ports the named function over Boolean integer inputs in all nine target languages; see [`benchmarks/h/imply_gate/README.md`](benchmarks/h/imply_gate/README.md).

The pinned Lua `unbias_01.lua` implements the Von Neumann extractor: draw two biased bits until they differ, then return the first. The bounded contract supplies a deterministic bit stream for the callback and returns `-1` on exhaustion; see the [guide](benchmarks/u/unbias_01/README.md) and [pinned Lua source](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/random/unbias_01.lua).

The pinned Python `TwoHiddenLayerNeuralNetwork` initializes weights from an unseeded NumPy generator and performs stateful training on a supplied dataset. Its results depend on random initialization and accumulated floating-point training state, so it is excluded from deterministic portable coverage.


The pinned Java and Python `token_bucket` implementations refill against `System.nanoTime`/`time.time` and guard request state with synchronization. Their allow/deny trace depends on wall-clock scheduling and concurrency, with no injected clock seam, so this candidate is excluded from deterministic benchmarking.

The pinned Zig `ThreadPool.zig` is a thread runtime with atomic work scheduling, worker lifecycle management, CPU affinity, and I/O polling. Its execution depends on OS threads and scheduler timing, so it is excluded from deterministic standalone algorithm coverage.

The pinned Java `ThreadSafeQueue` blocks producers and consumers on ReentrantLock condition variables when the bounded circular buffer is full or empty. Its intended behavior is concurrent producer-consumer synchronization and wakeup, so it is excluded from deterministic single-call ABI coverage.


The pinned C# and PHP `TrieNode` candidates expose node fields and child accessors but no complete trie insertion/search algorithm; the standalone node types are excluded. The pinned C# `UnrolledLinkedListNode` contains only a fixed-size array and linkage/count fields, so it is excluded as a data carrier.

The pinned Java `TrieAutocomplete` has a null-path dereference in `search` and its recursive suggestion traversal fails to restore the prefix between sibling branches, producing malformed later completions; the entrypoint also prints suggestions. It is excluded as an invalid source rather than mapped to the working trie autocomplete benchmark.

## Iterative flood fill alias

The pinned Java implementation uses a queue and eight-neighbor connectivity, matching the existing bounded [`flood_fill`](benchmarks/f/flood_fill/README.md) contract; this candidate shares that workload.

The pinned Go `tilingproblem.go` counts 2-by-n domino coverings with the Fibonacci recurrence; its benchmark bounds n to 91 for signed-64-bit results. The similarly named Java candidate is a distinct recursive L-tromino board tiler. See the [Go guide](benchmarks/t/tilingproblem/README.md) and [pinned Go source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/dynamic/tilingproblem.go).

The pinned Go `isisogram` candidate's first-order predicate is covered by the same [`isogram`](benchmarks/i/isogram/README.md) benchmark; its case folding and whitespace handling fit the ASCII contract.

The pinned Python `two_pointer.py` scans a sorted integer list from both ends and returns the first pair whose sum matches the target. The new bounded contract keeps its sorted-input assumption and inward scan, encoding the two zero-based indices as a scalar; see the [guide](benchmarks/t/two_pointer/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/two_pointer.py).

## Inversion count

The pinned Python module contains brute-force and divide-and-conquer methods. The bounded benchmark ports its brute-force pair counter to all nine languages; see [`benchmarks/i/inversions/README.md`](benchmarks/i/inversions/README.md).

The pinned R `TimeSeriesAnalyzer` class combines stationarity tests, ACF/PACF, ARIMA fitting and model selection, forecasting, and diagnostics, while depending on R6. It is excluded as a broad analysis toolkit without one standalone operation for this candidate filename.

The pinned Lua `weighted_choice` closure draws from global `math.random()` state, so its output cannot be repeated from the benchmark input alone; it is excluded as nondeterministic.

The pinned MATLAB/Octave `to_polar.m` returns `sqrt(x^2+y^2)` and a degree angle from `atan(y/x)` with pi added only when x<0; its radius maps to component 0 of [`cartesian_to_polar`](benchmarks/c/cartesian_to_polar/README.md), and its source-formula angle maps to [`to_polar_angle_degrees`](benchmarks/t/to_polar_angle_degrees/README.md). The source also prints labels and values, which are outside these numeric contracts.

The pinned Python `t_stochastic_neighbour_embedding.py` loads the Iris dataset through scikit-learn and initializes its embedding optimization from an unseeded NumPy generator. The end-to-end embedding output is stochastic and depends on external dataset-library behavior, so the candidate is excluded from deterministic portable benchmarking.

The pinned Java `TortoiseHareAlgo.getMiddle()` advances slow by one node and fast by two, returning the second middle for even-length lists and null for empty input. It aliases the existing [`middle_of_linked_list`](benchmarks/m/middle_of_linked_list/README.md) traversal; the successor-index ABI identifies the selected node by index.

## X9.23 padding

The pinned C# class supports zero or random filler. The benchmark fixes zero filler, ports the byte-appending `AddPadding` operation, and records pad length in the final byte across all nine languages; see [`benchmarks/x/x932_padding/README.md`](benchmarks/x/x932_padding/README.md).

The pinned Java `TopKFrequentWords` counts words and sorts by descending frequency, then lexicographically ascending for ties. It has a distinct contract from the Python frequency-only heap benchmark: see [`top_kfrequent_words`](benchmarks/t/top_kfrequent_words/README.md).

## Insert and delete array elements

The pinned Java helpers allocate a new array for insertion or deletion at a zero-based position; the interactive input/output wrapper is omitted. The benchmark ports both operations to nine languages; see [`benchmarks/i/insert_delete_in_array/README.md`](benchmarks/i/insert_delete_in_array/README.md).

The pinned Java `TilingProblem` recursively fills a power-of-two board with L-shaped trominoes around one missing cell. It is distinct from Go's 2-by-n domino `tilingproblem`; see the [L-tromino benchmark](benchmarks/t/tiling_problem/README.md).

The pinned C tic-tac-toe program is an interactive menu game seeded from wall-clock time, while the MATLAB/Octave version prompts for moves and redraws the board. These complete interactive applications do not expose a deterministic single-call algorithm and are excluded from portable coverage.

The pinned Python and Java HRRN schedulers select the ready process with the highest response ratio and return turnaround times ordered by arrival. The benchmark bounds process count and times, and requires distinct arrivals to keep source ordering deterministic; see [`benchmarks/h/highest_response_ratio_next/README.md`](benchmarks/h/highest_response_ratio_next/README.md).

The pinned Ruby `find_uncommon_words` combines the two sentences, counts all tokens, and returns words occurring once, in first-seen Hash order. See the bounded [`uncommon_words`](benchmarks/u/uncommon_words/README.md) contract.

The pinned Solidity `divide_digit` contract stores operands through separate state-changing calls before a division getter; the C `dict` and `dynamic_stack` sources expose mutable pointer-backed APIs (the stack also prints console output), and Python `double_ended_queue` is a mutable linked deque class. These stateful interfaces do not define a single-call benchmark contract and are excluded.

The MATLAB `equal` and `equal_add` candidates are introductory assignment demonstrations, and Solidity `events` demonstrates transaction event emission; none defines a reusable deterministic algorithm entrypoint, so they are excluded.

The JavaScript elementary automaton supports configurable rules; this benchmark fixes Rule 30 and constrains the first cell to zero to align its edge behavior with the pinned Python Rule 30 source. Both candidate records share the [Rule 30 benchmark](benchmarks/e/elementary/README.md).

The pinned Go `eggdropping` implementation uses the same first-drop dynamic-programming recurrence as the canonical [egg dropping benchmark](benchmarks/e/egg_dropping/README.md) on its positive-egg, positive-floor domain.

The Python `double_hash` source is a collision-resolution hook on a mutable `HashTable` subclass and depends on inherited insertion state and probe sequence, so it is excluded as a standalone algorithm entrypoint.

The pinned Python `scaled_exponential_linear_unit.py` applies the SELU piecewise expression with defaults `alpha=1.6732` and `lambda_=1.0507`; the benchmark preserves those defaults and uses scaled integer output. See the [SELU guide](benchmarks/s/scaled_exponential_linear_unit/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/activation_functions/scaled_exponential_linear_unit.py).

The pinned C `euler.c` contains an interactive graph prompt around a `hasEulerPath` degree-parity helper. The benchmark isolates that helper and preserves its parity-only behavior, including the fact that it does not test graph connectivity; see [`benchmarks/e/euler/README.md`](benchmarks/e/euler/README.md).

The pinned JavaScript `MatrixExponentiationRecursive.js` uses recursive exponentiation by squaring: exponent zero returns identity, odd powers multiply `A^(m-1)` by `A`, and even powers square `A^(m/2)`. The bounded 2×2 benchmark preserves that recursion and right-multiplication order. See the [guide](benchmarks/m/matrix_exponentiation_recursive/README.md) and [pinned source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/MatrixExponentiationRecursive.js).

The pinned Python `euler_modified` source implements Heun's explicit trapezoid method, a predictor-corrector distinct from midpoint Euler; see [`benchmarks/e/euler_modified/README.md`](benchmarks/e/euler_modified/README.md). The notebook `euler_method_for_the_cauchy_problem` is an interactive global-state demonstration, while `index_calculation` dispatches among dozens of vegetation-index formulas; both are excluded as lacking one bounded algorithm contract.

The pinned Java `MaximumMinimumWindow.java` uses monotone stacks to find each value’s maximal window span, then propagates the maximum minimum for each width. Its answer array starts at zero, so the benchmark uses nonnegative inputs. See the [guide](benchmarks/m/maximum_minimum_window/README.md) and [pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/MaximumMinimumWindow.java).

The pinned JavaScript `ModularArithmetic.js` provides modular addition, subtraction, and multiplication. Its `divide` method returns an extended-Euclidean coefficient without forming a modular quotient, so the benchmark covers the three validated operations. See the [guide](benchmarks/m/modular_arithmetic/README.md) and [pinned source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/ModularArithmetic.js).

The pinned Python `IIRFilter` processes samples with zero-initialized input and output histories, accumulating numerator feedback and denominator feedback in source order before dividing by `a0`. The bounded nine-language contract supports orders 1–3 and emits the filtered float64 stream; see the [IIR filter guide](benchmarks/i/iir_filter/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/audio_filters/iir_filter.py).

The pinned Python `minimum_element_of_array.py` is randomized quickselect: it partitions around a random pivot and recurses into only the side containing the requested one-based rank. The benchmark supplies a fixed xorshift32 seed to make pivots repeatable. See the [guide](benchmarks/m/minimum_element_of_array/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/divide_and_conquer/minimum_element_of_array.py).

The pinned Java `MedianOfRunningArrayByte` inherits the two-heap running median and emits one byte for each inserted prefix. The benchmark preserves strict insertion into the lower heap, selection from the larger heap for odd prefixes, and Java truncation toward zero before signed-byte conversion for even prefixes. See the [byte median guide](benchmarks/m/median_of_running_array_byte/README.md), [byte specialization](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MedianOfRunningArrayByte.java), and [generic heap source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MedianOfRunningArray.java).

The pinned Java `MedianOfRunningArrayDouble` shares the two-heap insertion and rebalancing logic, then emits one binary64 median per prefix. The contract preserves Java `Double.compare` ordering for `-0.0` and `+0.0`, and the even-prefix average uses the source's `(lowerRoot + upperRoot) / 2.0d` operation order. See the [double median guide](benchmarks/m/median_of_running_array_double/README.md), [double specialization](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MedianOfRunningArrayDouble.java), and [generic heap source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MedianOfRunningArray.java).

The Java `MedianOfRunningArrayLong` specialization emits each prefix median as a little-endian signed-i64 value. Its bounded samples keep the even-root sum within signed-i64 range, and negative averages use Java division truncating toward zero. See the [long median guide](benchmarks/m/median_of_running_array_long/README.md), [long specialization](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MedianOfRunningArrayLong.java), and [generic heap source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MedianOfRunningArray.java).

The Java `MedianOfRunningArrayFloat` specialization rounds its even-prefix addition and division to binary32, then widens the result for the float64 slice ABI. Inputs must be exactly representable as binary32; Java `Float.compare` signed-zero order is preserved in the prefix medians. See the [float median guide](benchmarks/m/median_of_running_array_float/README.md), [float specialization](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MedianOfRunningArrayFloat.java), and [generic heap source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MedianOfRunningArray.java).

The pinned Java `MedianOfRunningArray` uses a lower max-heap and upper min-heap, rebalancing before reading the median. Its integer specialization averages equal-size heap roots with Java integer division. See the [benchmark guide](benchmarks/m/median_of_running_array_integer/README.md), [generic source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MedianOfRunningArray.java), and [integer specialization](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MedianOfRunningArrayInteger.java).

The pinned Python Hilbert curve routine recursively emits four oriented subcurves, reversing the first and fourth child point sequences. The benchmark fixes the center and unit side, bounds depth to six, and returns the ordered points as exact scaled integer coordinates; see the [Hilbert curve guide](benchmarks/h/hilbert_curve/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/fractals/hilbert_curve.py).

The pinned JavaScript `MidpointIntegration.js` evaluates a callback at each panel midpoint and multiplies the sample sum by the panel width. The benchmark specializes the callback to `1`, `x`, or `x²` and quantizes output at 1e-9. See the [guide](benchmarks/m/midpoint_integration/README.md) and [pinned source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/MidpointIntegration.js).

The pinned C# Hill encoder pads text to a three-character boundary, multiplies each chunk by a 3×3 key, and emits the resulting UTF-16 code units. The bounded contract uses uppercase ASCII and small integral keys across all nine languages; decode and Gaussian elimination are outside this encode-only operation. See the [Hill encoder guide](benchmarks/h/hill_encoder/README.md) and [pinned C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Encoders/HillEncoder.cs).


The pinned JavaScript `OuncesToKilograms.js` uses `(oz * 28.3498) / 1000`. Because its coefficient differs from the existing weight conversion chart, it has a separate benchmark with the source operation order and a bounded signed binary64 input. See the [guide](benchmarks/o/ounces_to_kilograms/README.md) and [pinned source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/OuncesToKilograms.js).

The pinned Java and Python minimum-window substring routines use multiplicity-aware sliding windows and retain the earliest shortest match. The Python filename candidate aliases the Java benchmark on the bounded ASCII contract; empty targets are excluded because the Java source does not handle them safely. See the [minimum-window guide](benchmarks/m/minimum_window_substring/README.md), [pinned Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/slidingwindow/MinimumWindowSubstring.java), and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/min_window_substring.py).

The Lua `interval_scheduling` source and C# `IntervalSchedulingSolver` both sort intervals by finish time and greedily choose non-overlapping jobs; they map to the existing [activity selection benchmark](benchmarks/a/activity_selection/README.md). Java `iirfilter` uses the same sample recurrence as the Python [IIR filter benchmark](benchmarks/i/iir_filter/README.md), with its final coefficient slots left at zero by the source setter.

The pinned C# modular multiplicative inverse uses extended Euclid, throws when the operands are not coprime, and normalizes the Bézout coefficient into the modulus range. The benchmark maps invalid and non-invertible inputs to -1. See the [guide](benchmarks/m/modular_multiplicative_inverse/README.md) and [pinned source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/ModularArithmetic/ModularMultiplicativeInverse.cs).

The two pinned C++ `integral_approximation` copies are identical delta-based trapezoidal Riemann sums. The nine-language benchmark preserves the source’s truncated step count and left-to-right endpoint construction for two bounded example callbacks; see the [integral approximation guide](benchmarks/i/integral_approximation/README.md) and [primary pinned source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/integral_approximation.cpp).

The pinned Dart file named `Moore_voting_algorithm.dart` actually sorts the input and counts equal runs, returning a value only for a strict majority. Its distinct sort-and-count behavior has a bounded scalar benchmark; see the [guide](benchmarks/m/majority_element_sort/README.md) and [pinned source](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/other/Moore_voting_algorithm.dart).

The pinned Python `integration_by_simpson_approx` fixes `f(x)=x²` and 1,000 Simpson panels, then rounds to the requested decimal precision. The bounded nine-language contract retains the weighted sample order and Python ties-to-even rounding; see the [Simpson approximation guide](benchmarks/i/integration_by_simpson_approx/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/numerical_analysis/integration_by_simpson_approx.py).

The pinned JavaScript modular binary exponentiation uses recursive squaring, with a base case that returns 1 directly when the exponent is zero. Its bounded benchmark preserves that behavior and keeps Number multiplications exact. See the [guide](benchmarks/m/modular_binary_exponentiation_recursive/README.md) and [pinned source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/ModularBinaryExponentiationRecursive.js).

The pinned Python minimum-ticket-cost routine memoizes a calendar-day recurrence and chooses among one-, seven-, and thirty-day passes on each travel day. The bounded benchmark preserves its empty-schedule result and pass-choice behavior; see the [guide](benchmarks/m/minimum_tickets_cost/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/minimum_tickets_cost.py).

The pinned C# Jaro similarity routine searches within a half-length matching window, counts transpositions among matches, and averages the three similarity terms. Its bounded contract preserves the source’s longer-first indexing assumption; see the [guide](benchmarks/j/jaro_similarity/README.md) and [pinned source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Strings/Similarity/JaroSimilarity.cs).

The pinned F# and Python prefix-function routines return the longest proper prefix/suffix length at each position using the linear KMP fallback recurrence. This computes the prefix table, not pattern search; see the [guide](benchmarks/p/prefix_function/README.md), [F# source](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Strings/PrefixFunction.fs), and [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/prefix_function.py).

The pinned C++ `longest_common_string` source uses the standard longest-common-subsequence dynamic program (the name’s “string” does not mean contiguous substring); its result is the LCS length, so it maps to the [canonical benchmark](benchmarks/l/longest_common_subsequence/README.md).
The pinned C# `nysiis_encoder` source applies the NYSIIS prefix/suffix and sequential character substitutions, then collapses duplicates and removes its terminal suffix. The shared contract limits names to ASCII letters and provides nine language ports. See the [NYSIIS encoder guide](benchmarks/n/nysiis_encoder/README.md).
The Python `newton_forward_interpolation` source builds forward differences and evaluates the polynomial for equally spaced nodes, so it aliases `neville` on that node domain. The similarly named Jupyter notebook uses shifted difference coefficients and is excluded as an invalid implementation. See the [Neville guide](benchmarks/n/neville/README.md).

The pinned Python minimum-deviation routine doubles odd values, then repeatedly halves the current maximum from a max heap while it remains even, minimizing the range along the way. See the [guide](benchmarks/m/minimize_deviation_in_array/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/greedy_methods/minimize_deviation_in_array.py).

The pinned Python longest-repeating-subsequence routine computes LCS of the input with itself while disallowing matches at the same position. The bounded ASCII benchmark preserves that recurrence with a fixed one-row DP buffer; see the [guide](benchmarks/l/longest_repeating_subsequence/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/longest_repeating_subsequence.py).

The pinned Go `Linear` routine performs a left-to-right scan and returns the first matching index (or -1); it maps to the [canonical linear search benchmark](benchmarks/l/linear_search/README.md).

The pinned Dart peak finder recursively bisects and returns a midpoint whose neighbors are no larger, using `<=` so a plateau can satisfy the peak condition. Its bounded contract preserves midpoint and branch behavior; see the [guide](benchmarks/p/peak_element/README.md) and [pinned source](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/search/peak_element.dart).
The pinned Java `number_to_words` converter spells whole-number groups through Trillion and renders nonzero fractional digits individually after “Point.” The bounded contract preserves title case and fractional scale. See the [number-to-words guide](benchmarks/n/number_to_words/README.md).

The pinned Java postfix evaluator consumes whitespace-delimited integer and binary-operator tokens from a stack, with Java `int` wraparound and truncating division. The bounded ABI uses distinct sentinels for operators and rejects malformed expressions; see the [postfix evaluator guide](benchmarks/p/postfix_evaluator/README.md) and [pinned Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/PostfixEvaluator.java).

The pinned C# interval scheduler is finish-time greedy and maps to the [activity selection benchmark](benchmarks/a/activity_selection/README.md). The C# `JumpSearcher` uses square-root blocks and a linear scan, mapping to [jump search](benchmarks/j/jump_search/README.md). Python `leaky_rectified_linear_unit` uses the same real-valued elementwise Leaky ReLU map as the canonical [`leaky_relu`](benchmarks/l/leaky_relu/README.md); signed-zero sign is not distinguished by the numeric contract.
The pinned Python `odd_even_transposition_parallel` uses one process per value and odd-even compare/swap phases. Because its worker performs exactly ten phases and the top-level setup assumes a nonempty input, it aliases `odd_even_sort` only for nonempty arrays of length at most ten. See the [odd-even sort guide](benchmarks/o/odd_even_sort/README.md).
The pinned Dart `nearest_neighbour_algorithm` performs a greedy nearest-unvisited walk over a weighted adjacency matrix, starting at node zero and preserving input order for ties. Its benchmark uses bounded integer weights and emits the zero-based visitation order. See the [nearest-neighbour algorithm guide](benchmarks/n/nearest_neighbour_algorithm/README.md).

The pinned Go and Python Pythagoras routines compute Euclidean distance between two 3D points from the squared coordinate differences. The bounded integer-coordinate contract preserves this distance; see the [guide](benchmarks/p/pythagoras/README.md), [Go source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/pythagoras/pythagoras.go), and [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/pythagoras.py).

The pinned Java `LongestRepeatedSubstring` uses a suffix array and Kasai LCP construction; its benchmark compares the returned substring length, omitting tie-sensitive contents. See the [guide](benchmarks/l/longest_repeated_substring/README.md) and [pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/LongestRepeatedSubstring.java).

The Go LCA candidate uses binary lifting and maps to [lowest common ancestor by binary lifting](benchmarks/l/lowest_common_ancestor_binary_lifting/README.md). The C# interval scheduler, C# jump searcher, C++ jump game, and Python Leaky ReLU map to [activity selection](benchmarks/a/activity_selection/README.md), [jump search](benchmarks/j/jump_search/README.md), [jump game](benchmarks/j/jump_game/README.md), and [leaky_relu](benchmarks/l/leaky_relu/README.md), respectively. The pinned JavaScript `LCABinaryLifting` module and its `BinaryLifting` helper are tracked as a separate [`lcabinary_lifting`](benchmarks/l/lcabinary_lifting/README.md) benchmark with a bounded rooted-tree query trace and weighted checksum; see the [workload](benchmarks/l/lcabinary_lifting/workload.json) and pinned [algorithm source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Graphs/LCABinaryLifting.js).
The pinned Dart `newton_method` and MATLAB `newton` implementations both map to the bounded `newton_raphson` contract when configured for `f(x)=x²-radicand` on its positive-start domain. The aliases preserve each source's derivative and stopping controls while remaining within the contract tolerance. See the [Newton–Raphson guide](benchmarks/n/newton_raphson/README.md).

The pinned Java prefix evaluator scans expression tokens right-to-left and applies binary operators to the next two stack values in prefix order. The bounded contract preserves Java `int` arithmetic and rejects malformed input; see the [prefix evaluator guide](benchmarks/p/prefix_evaluator/README.md) and [pinned Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/PrefixEvaluator.java).
The pinned R `one_hot_encode` default uses `model.matrix(~0 + ., data=x)` to create indicator columns for observed character/factor levels. Its bounded one-column contract maps A–Z categories to a row-major binary matrix. See the [one-hot encoding guide](benchmarks/o/one_hot_encode/README.md).

The benchmark pins Dart `pow`, whose repeated multiplication loop returns 1 for zero or negative exponents. The Java source throws on negative exponents, while the JavaScript file contains separate linear and logarithmic variants with their own negative-exponent handling. See the [Dart pow guide](benchmarks/p/pow/README.md), [Dart source](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/pow.dart), [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Pow.java), and [JavaScript source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/Pow.js).

The pinned C++ parenthesis matcher reads a whitespace-delimited token and validates properly nested `()`, `{}`, `[]`, and `<>` pairs with a stack; other characters fail. Both cataloged C++ repositories contain the same program. The bounded benchmark limits tokens to 99 characters; see the [guide](benchmarks/p/paranthesis_matching/README.md), [C-Plus-Plus source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/paranthesis_matching.cpp), and [C-Plus-Plus-1 source](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/others/paranthesis_matching.cpp).

[Jaro–Winkler similarity](benchmarks/j/jaro_winkler/README.md) follows the pinned Python matching-window implementation with its four-character prefix boost; the F# filename match is documented as divergent. The Go `jump2` candidate has a final-block skip defect; related Go `jump`, Java and JavaScript longest-unique-substring, and lowercase-ASCII R candidates map to their canonical contracts.
The pinned Java `optimal_job_scheduling` source uses dynamic programming for a precedence chain with machine-specific run costs and pair-dependent transfer delays. The benchmark returns the full cumulative process-by-machine cost matrix; this is distinct from weighted interval scheduling. See the [optimal job scheduling guide](benchmarks/o/optimal_job_scheduling/README.md).

The pinned Rust payback routine returns the zero-based index where cumulative cash flow first reaches or exceeds zero, or no result if it never recovers. Its bounded benchmark uses whole-unit integer flows; see the [payback guide](benchmarks/p/payback/README.md) and [pinned Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/financial/payback.rs).

The pinned Solidity `uint256Percentage` computes `(a*b*10^dp)/100` as an integer scaled result, rejecting zero inputs and products below 100; the separate signed variant remains distinct. See the [percentage guide](benchmarks/p/percentage/README.md) and [source](https://github.com/TheAlgorithms/Solidity/blob/08cba51fb38e276062b0c9791d7e0ee494ffa903/src/Maths/Percentage.sol).

The pinned Go `PartitionProblem` is an alias of the existing [partition problem benchmark](benchmarks/p/partition_problem/README.md): both use subset-sum reachability for an equal split on the shared nonempty nonnegative input domain. The Go source's empty-input result lies outside that contract; see its [pinned source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/dynamic/partitionproblem.go).

The pinned R permutation calculator returns `n!/(n-r)!`, with `0! = 1` and an error for `r > n`. Its bounded contract keeps the factorial ratio exact; see the [guide](benchmarks/p/permutation_calculation/README.md) and [R source](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/mathematics/permutation_calculation.r).
[Jenkins One-at-a-Time hash](benchmarks/j/jenkins_one_at_a_time/README.md) ports the pinned Python 32-bit UTF-8 byte-mixing hash across all nine languages on a bounded ASCII byte-array contract; its per-step add/shift/XOR recurrence is distinct from DJB2 and SDBM.
[Astable 555 timer](benchmarks/i/ic_555_timer/README.md) ports the pinned Python frequency and duty-cycle formulas across all nine languages with a selector-based bounded contract.
The pinned Python `product_sum_array` recursively weights each integer leaf by its containing list depth, starting with root depth 1; the same file also supplies an iterative variant. Its bounded benchmark uses explicit nested-list markers, with at most 128 tokens, depth 16, and leaves in ±1000. The published example evaluates to -12 under the recurrence; see the [product sum guide](benchmarks/p/product_sum/README.md) and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/product_sum.py).
[Longest increasing subsequence, iterative](benchmarks/l/longest_increasing_subsequence_iterative/README.md) preserves the pinned Python `<=` recurrence (a longest non-decreasing subsequence) and compares its length across all nine language ports.
[Longest palindromic substring](benchmarks/l/longestpalindrome/README.md) ports the pinned Go Manacher recurrence across all nine languages, preserving space filtering and bounding inputs to printable ASCII that avoids the source marker.
The pinned Python `pairwise_iteration_tee` advances a duplicate iterator and zips it with the original to yield adjacent pairs; its comprehension variant with default step 1 yields the same sequence. The bounded benchmark emits each pair as two little-endian i64 values; see the [pairwise iteration guide](benchmarks/p/pairwise_iteration/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/pairwise_iteration.py).
The pinned Go `longestarithmeticsubsequence` implementation uses the same endpoint/difference dynamic program and aliases to [longest arithmetic subsequence](benchmarks/l/longest_arithmetic_subsequence/README.md).
[Job sequence with deadline](benchmarks/j/job_sequence_with_deadline/README.md) ports the pinned Python stable reward-rank filter across all nine languages; its bounded contract compares the count of retained jobs.
[Job sequencing with deadline](benchmarks/j/job_sequencing_with_deadline/README.md) ports the pinned Python latest-free-slot greedy scheduler; its scalar result losslessly encodes scheduled count and total profit, distinct from the rank-filter variant.
[Job sequencing](benchmarks/j/job_sequencing/README.md) follows the pinned Java and Rust latest-free-slot scheduler; its bounded contract restricts jobs to strictly descending profits and reports scheduled IDs in slot order plus total profit.
The pinned Java postfix-to-infix converter handles empty input, accepts a single alphabetic character, and uses a stack to parenthesize each binary operation. The benchmark bounds input to 64 ASCII letter/operator tokens and maps malformed expressions to -1; see the [postfix-to-infix guide](benchmarks/p/postfix_to_infix/README.md) and [pinned Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/PostfixToInfix.java).
The pinned Python `otsu_threshold` source computes a 256-bin grayscale histogram, selects the earliest threshold attaining the maximum between-class variance (strict-greater update), then maps pixels strictly above the threshold to 255. Its bounded flattened-pixel benchmark is available in the [Otsu threshold guide](benchmarks/o/otsu_threshold/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/computer_vision/otsu_threshold.py).
[Iterating through submasks](benchmarks/i/iterating_through_submasks/README.md) ports the pinned Python descending submask loop across all nine languages and compares the number of nonzero submasks for bounded positive masks.

The pinned Go Polybius constructor builds a keyed square and encrypts letters as row/column coordinate pairs. The benchmark fixes a 5×5 square with J omitted and accepts bounded ASCII letters excluding J; see the [Polybius guide](benchmarks/p/polybius/README.md) and [pinned source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/cipher/polybius/polybius.go).
The pinned Python `postfix_to_infix_conversion` stack routine aliases to [postfix to infix](benchmarks/p/postfix_to_infix/README.md) on nonempty valid ASCII expressions; empty input is excluded because the source reads the top of an empty stack.
[Kahn topological sorting](benchmarks/k/kahn/README.md) ports the pinned Go queue-based DAG algorithm across all nine languages, deduplicating edges and comparing processed vertex count because neighbor-map order is nondeterministic.
The pinned Python `ordinary_least_squares_regression` source returns both intercept and slope from centered univariate ordinary least squares. Its bounded benchmark preserves that vector result in [little-endian binary64 form](benchmarks/o/ordinary_least_squares_regression/README.md) and links the [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/ordinary_least_squares_regression.py).

The pinned Python Pig Latin function lowercases a word, appends `way` for initial vowels, and rotates the leading consonant cluster before appending `ay`; consonant-only inputs fail in the source and are mapped to invalid by the bounded ASCII contract. See the [Pig Latin guide](benchmarks/p/pig_latin/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/pig_latin.py).
The pinned Python KD-tree `nearest_neighbour_search` visits the near branch first, updates only for strictly smaller squared distance, and prunes the far branch unless the split distance is strictly smaller than the current best. The benchmark preserves visit counts and traversal-order tie behavior in a [bounded serialized-tree contract](benchmarks/n/nearest_neighbour_search/README.md); see the [pinned search source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/kd_tree/nearest_neighbour_search.py).
The pinned Java `KDTree.java` candidate maps to [`kdtree`](benchmarks/k/kdtree/README.md), a bounded two-dimensional insert/search/extrema/nearest-query trace. It preserves the source median build and its nearest-search pruning quirk, covered by two regression fixtures; see the [workload](benchmarks/k/kdtree/workload.json) and [pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/KDTree.java).

The pinned Java `minimalPartitions` uses a palindrome table followed by prefix dynamic programming to compute the minimum cut count. The bounded contract accepts nonempty ASCII strings; see the [palindromic partitioning guide](benchmarks/p/palindromic_partitioning/README.md) and [pinned Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/PalindromicPartitioning.java).
[Largest divisible subset](benchmarks/l/largest_divisible_subset/README.md) ports the pinned Python sorted dynamic program across all nine languages and compares the longest divisible-chain length on bounded positive inputs.

The pinned JavaScript permutation-and-combination module exports recursive factorial, n-permute-r, and n-choose-r formulas. Its bounded three-operation benchmark restricts n to 18 for exact Number integers; see the [guide](benchmarks/p/permutation_and_combination/README.md) and [source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/PermutationAndCombination.js).
The pinned Go `GenerateTriangle` builds the first n Pascal rows and aliases to [Pascal triangle](benchmarks/p/pascal_triangle/README.md) for n >= 0 in its bounded domain; negative row counts panic in the source.
[K-th lexicographic permutation](benchmarks/k/kth_lexicographic_permutation/README.md) ports the pinned Python factoradic selection across all nine languages and encodes the full bounded permutation in the scalar result.
The pinned Python `n_body_simulation` updates velocities from softened gravitational forces, then updates positions only after all bodies have received their velocity updates. The bounded deterministic Euler benchmark retains that order and returns each body's final state; see the [N-body guide](benchmarks/n/n_body_simulation/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/n_body_simulation.py).

The pinned Java `generateParentheses` uses backtracking, explores `(` before `)`, and emits every balanced string. Its bounded benchmark preserves that order for zero through six pairs; see the [parentheses generator guide](benchmarks/p/parentheses_generator/README.md) and [pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/backtracking/ParenthesesGenerator.java).
[K-th order statistic](benchmarks/k/kth_order_statistic/README.md) ports the pinned Python divide-and-conquer quickselect across all nine languages for bounded unique-value inputs.

The pinned TypeScript `pascalsTriangle(n)` builds n rows and returns only the final row, so it remains distinct from the first-n-rows [Pascal triangle benchmark](benchmarks/p/pascal_triangle/README.md). Its bounded contract hashes the returned row for n=1..31; see the [guide](benchmarks/p/pascals_triangle/README.md) and [source](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/pascals_triangle.ts).
[K-th smallest with a max heap](benchmarks/k/kth_smallest_heap/README.md) ports the pinned Rust top-k max-heap algorithm across all nine languages.

The pinned Go `Parenthesis` checks only round parentheses with an early-negative counter and ignores other runes; the C filename match instead stack-validates `()`, `[]`, and `{}`. The benchmark follows Go on bounded ASCII inputs and records the C divergence in the [guide](benchmarks/p/parenthesis/README.md), with [Go source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/strings/parenthesis/parenthesis.go) and [C source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/stack/parenthesis.c).
The pinned Clojure matrix operators add or subtract equal-dimension matrices elementwise and return nil when dimensions differ. The bounded [operators benchmark](benchmarks/o/operators/README.md) covers row-major integer matrices and both operations.
[Log two](benchmarks/l/log_two/README.md) ports the matching JavaScript and TypeScript signed-shift loops across all nine languages, bounded to nonnegative signed-32-bit values.

The pinned Java FIFO and Python highest-label implementations use Push–Relabel preflow updates. The Python `edmonds_karp_multiple_source_and_sink` filename also contains a `PushRelabelExecutor` with super-terminals, despite its name, and aliases to the [multi-terminal Push–Relabel benchmark](benchmarks/p/push_relabel/README.md); its source constructor and executor disagree on field spelling.

The pinned Python dual-number class repeatedly multiplies `x + ε` and extracts the coefficient for the requested derivative order. The [dual-number automatic differentiation benchmark](benchmarks/d/dual_number_automatic_differentiation/README.md) fixes the callable to `x^p` and preserves the coefficient-times-factorial recurrence across nine languages.

The pinned Haskell `powerset` recursively emits the tail's subsets before the same subsets with the head prepended. The bounded contract preserves this ordering and supports repeated values; see the [Powerset guide](benchmarks/p/powerset/README.md) and [pinned source](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/Misc/Powerset.hs).
The pinned Python Nesterov optimizer starts velocity at zero per call, carries it across steps, and applies the momentum lookahead parameter update. The bounded [Nesterov accelerated SGD benchmark](benchmarks/n/nesterov_accelerated_sgd/README.md) compares final parameters as little-endian binary64 vectors.
[K-th element from the end](benchmarks/k/kth_element_from_end/README.md) ports the pinned Python linked-list two-pointer lookup across all nine languages for bounded values.

The pinned Java permutation cipher validates a one-based key, strips ASCII whitespace, uppercases ASCII text, pads blocks with `X`, and permutes each block; Python's source instead randomizes its default key and uses zero-based unpadded blocks. See the [permutation cipher guide](benchmarks/p/permutation_cipher/README.md), [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/PermutationCipher.java), and [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/permutation_cipher.py).
[Long division](benchmarks/l/long_division/README.md) ports the pinned Java decimal digit-by-digit repeated-subtraction division across all nine languages for bounded integers.

The pinned Python crossword puzzle backtracker stably tries longest words first, scans cells row-major, and allows matching letters at intersections; duplicate words remain valid inputs. Its behavior is cataloged separately from the Java blank-cell crossword routine in the [crossword puzzle solver guide](benchmarks/c/crossword_puzzle_solver/README.md) and [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/crossword_puzzle_solver.py).
The pinned [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Problems/KnightTour/OpenKnightTour.cs) and [Dart](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/backtracking/open_knight_tour.dart) open-tour solvers share a row-major start scan and deterministic DFS move order. The [open knight tour benchmark](benchmarks/n/open_knight_tour/README.md) accepts dimensions 1×1 and 5×5. Dimensions 2–4 have no tour; Dart returns an all-zero board there, while C# throws, so the workload rejects those inputs.
[Lee breadth-first search](benchmarks/l/lee_breadth_first_search/README.md) ports the pinned Rust four-neighbor grid BFS across all nine languages and compares shortest path distance.

The pinned Rust perfect-number enumerator uses a divisor scan, while F# checks divisor pairs and AArch64 generates even perfect numbers from Mersenne primes via the Euclid–Euler formula. The F# pair calculation double-counts the square-root divisor for square inputs; the benchmark uses the standard bounded proper-divisor predicate. See the [perfect numbers guide](benchmarks/p/perfect_numbers/README.md), [F# source](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Math/Perfect_Numbers.fs), [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/perfect_numbers.rs), and [AArch64 source](https://github.com/TheAlgorithms/AArch64_Assembly/blob/cb138a856a3af14d3d3dfcd2743d43841eec566f/misc/perfect_numbers.s).
The pinned Python orbital-transfer routine computes gravitational work with `G = 6.67430e-11` and presents the result in three-decimal scientific notation. The bounded [orbital transfer work benchmark](benchmarks/o/orbital_transfer_work/README.md) preserves the numeric formula and compares the work as a binary64 value.

The pinned Java `PalindromeWithStack` lowercases its input, pushes each character onto a stack, and compares the popped reverse with the lowered string. The bounded benchmark fixes the input to ASCII bytes; spaces and punctuation remain significant. See the [palindrome with stack guide](benchmarks/p/palindrome_with_stack/README.md) and [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/PalindromeWithStack.java).
[Last item in a list](benchmarks/l/last_item_in_a_list/README.md) ports the pinned Clojure tail-recursive last-element lookup across all nine languages.
[Length of a list](benchmarks/l/length_of_list/README.md) ports both pinned Clojure counting approaches across all nine languages for bounded integer sequences.
The pinned [Java priority scheduler](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/NonPreemptivePriorityScheduling.java) runs ready processes by ascending priority, while the similarly named [C source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/process_scheduling_algorithms/non_preemptive_priority_scheduling.c) calculates FIFO completion times and ignores priority. The benchmark follows the Java scheduler in the [guide](benchmarks/n/non_preemptive_priority_scheduling/README.md).

The pinned Java `PreemptivePriorityScheduling` selects one process per tick, preferring higher priority and then earlier arrival. [`preemptive_priority_scheduling`](benchmarks/p/preemptive_priority_scheduling/README.md) preserves idle ticks and preemption with unique priority/arrival pairs and bounded process records.

The pinned TypeScript `parseNestedBrackets` emits each matched outer tag before recursively appending tags from its interior, using `<` and `>` by default. See the [parse nested brackets guide](benchmarks/p/parse_nested_brackets/README.md) and [TypeScript source](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/other/parse_nested_brackets.ts).
[Langton's ant](benchmarks/l/langtons_ant/README.md) ports the pinned Python turn-move-flip automaton across all nine languages and packs the bounded final board and ant state.

The pinned Java `CursorLinkedList` stores singly linked nodes in a fixed 100-slot cursor array, using slot 0 as its free-list sentinel. The [cursor linked list guide](benchmarks/c/cursor_linked_list/README.md) models append, lookup, removal, and free-slot reuse in a bounded operation trace and preserves the source's duplicate-value `removeByIndex` behavior.

The pinned JavaScript `canPartition` explores equal-sum subsets recursively, trying inclusion before exclusion and pruning when the partial sum exceeds half. Its benchmark contract restricts values to nonnegative integers so that pruning is valid. See the [partition guide](benchmarks/p/partition/README.md) and [JavaScript source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Recursive/Partition.js).
[Largest square in a binary matrix](benchmarks/l/largest_square_area_in_matrix/README.md) ports the pinned Python bottom-up DP across all nine languages and returns the maximum all-1 square side length.

The pinned Python `peak` uses middle-three comparisons and recursive slicing, including a boundary adjustment when the left prefix contains two items. The benchmark restricts inputs to strict unimodal arrays with an interior peak. See the [peak guide](benchmarks/p/peak/README.md) and [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/divide_and_conquer/peak.py).
[Linear Diophantine equation solvability](benchmarks/l/linear_diophantine_eqn/README.md) ports the matching Dart recursive-gcd and MATLAB/Octave gcd-divisibility checks across all nine languages.
[Local maximum point](benchmarks/l/local_maximum_point/README.md) ports the pinned JavaScript divide-and-conquer peak search across all nine languages, preserving its midpoint tie-branch behavior.

The pinned JavaScript `parseDate` accepts `d/m/yyyy`, then validates the day using Gregorian month lengths; its helper treats year zero as leap. The benchmark keeps the exact ASCII format and encodes the parsed date as YYYYMMDD. See the [parse date guide](benchmarks/p/parse_date/README.md), [parser source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Timing-Functions/ParseDate.js), and [month-length helper](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Timing-Functions/GetMonthDays.js).

The pinned Java singly linked-list source includes a generic stack variant using object identity and an optimized integer-node variant that reverses the suffix from the midpoint before comparing values. The benchmark models the optimized signed-int path. See the [singly linked-list palindrome guide](benchmarks/p/palindrome_singly_linked_list/README.md) and [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/PalindromeSinglyLinkedList.java).

The pinned Go `Cyclic` type is a circular doubly linked list with head rotation, deletion, traversal, and destruction. Its file's Josephus routine performs `Rotate(k)`, `Delete()`, and `Rotate(-1)` per round, then destroys the list; this source-specific behavior is included in the [cyclic benchmark guide](benchmarks/c/cyclic/README.md).

The pinned JavaScript `checkIfPatternExists` performs a naive first-match scan. Its comment claims case normalization, but the code is case-sensitive; the benchmark follows the executable behavior and returns the first zero-based index. See the [pattern matching guide](benchmarks/p/pattern_matching/README.md) and [JavaScript source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/PatternMatching.js).
[Linear Diophantine equations solver](benchmarks/l/linear_diophantine_equations_solver/README.md) ports the pinned Java extended-Euclidean particular-solution solver across all nine languages and packs its bounded solution pair.
The pinned Julia `partitions_recursive` returns 1 for zero and otherwise sums the number of partitions with each possible part count using a recursive two-term recurrence. The benchmark memoizes the same recurrence for n in 0..=100, where results fit signed 64-bit. See the [partitions guide](benchmarks/p/partitions/README.md) and [pinned Julia source](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/partitions.jl).
[Lua uint53 predicate](benchmarks/i/is/README.md) ports the pinned integral, nonnegative, below-2^53 check across all nine languages.

The pinned R `data_normalization_standardization.r` defines min-max normalization and z-score standardization using R sample `sd`; the benchmark selects either operation and documents the bounded finite-output domain. See the [guide](benchmarks/d/data_normalization_standardization/README.md) and [pinned source](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/data_preprocessing/data_normalization_standardization.r).
The pinned Python `data_transformations.py` maps normalization and z-score standardization to a separate contract that preserves three-decimal rounding. See the [guide](benchmarks/d/data_transformations/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/data_transformations.py).
The pinned MATLAB-Octave `DoublePointCrossover.m` chooses two distinct random cuts, keeps each parent's prefix and suffix, and exchanges the inclusive middle segment. The [`double_point_crossover`](benchmarks/d/double_point_crossover/README.md) contract makes the cuts explicit for deterministic calls across all nine languages.
The pinned Python DPLL source has a recursive branch bug: nonempty result tuples are truthy under `or`, and both branches share one model. Its [benchmark](benchmarks/d/davis_putnam_logemann_loveland/README.md) implements the intended satisfiability algorithm with unit and pure-literal propagation.
The pinned Python source candidate `unknown_sort.py` names its function `merge_sort`, but the code repeatedly extracts the minimum and maximum into endpoint buffers. The catalog maps it to the semantically named [`double_ended_selection_sort`](benchmarks/d/double_ended_selection_sort/README.md) package.
The pinned Python `deep_clone_graph.py` uses an explicit stack and an identity-to-clone map. The bounded graph contract represents adjacency as symmetric row masks, retaining reachable clone topology, cycles, self-loops, and duplicate node values. See the [guide](benchmarks/d/deep_clone_graph/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/deep_clone_graph.py).
The pinned Python `fuzzy_set_operations.py` applies triangular membership and eight elementwise fuzzy-set formulas to NumPy vectors. The benchmark defines those operations over bounded membership values and excludes the plotting demo; see the [guide](benchmarks/f/fuzzy_set_operations/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/fuzzy_logic/fuzzy_set_operations.py).
The pinned Python `resistor_color_code.py` maps three through six color bands to significant digits, multiplier, optional tolerance, and optional temperature coefficient. Its [nine-language benchmark](benchmarks/r/resistor_color_code/README.md) preserves the returned resistance text, including source float formatting.
The pinned Java `WelshPowell.findColoring` sorts vertices by descending degree with stable index ties. Its color-class scan admits an uncolored vertex only when it has no already-colored neighbor of any color; the nine-port [`welsh_powell`](benchmarks/w/welsh_powell/README.md) package preserves that source rule.
The pinned Python and Java DES sources share a standard 16-round ECB block transform. The nine-language [`des_ecb`](benchmarks/d/des_ecb/README.md) contract normalizes their key and ciphertext encodings, restricts plaintext to ASCII bytes, and pads a partial final block with zero bytes. LAC-DCC's [VersaBench `ecbdes`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/ecbdes) uses the same DES ECB core with a fixed block-count driver, so it maps to this package rather than adding another DES algorithm benchmark.
[Intensity based segmentation](benchmarks/i/intensity_based_segmentation/README.md) ports the pinned Python ordered-threshold overwrite behavior across all nine languages and packs bounded pixel labels.
The pinned MATLAB-Octave `Parametric_ReLU.m` plots the same caller-supplied-slope piecewise function as `leaky_relu` on finite binary64 inputs; its prompt and plotting are presentation context. Candidate `parametric_re_lu` aliases the [leaky ReLU guide](benchmarks/l/leaky_relu/README.md).
The pinned JavaScript `permutate` incrementally inserts each character, deduplicates the resulting strings, and sorts them lexicographically. The benchmark restricts inputs to distinct printable ASCII and hashes the sorted permutation list for the scalar-array ABI. See the [permutate string guide](benchmarks/p/permutate_string/README.md) and [pinned JavaScript source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/PermutateString.js).
[Kinematics](benchmarks/k/kinematics/README.md) ports the four pinned Java SUVAT formulas across all nine languages with a bounded, exactly scaled integer result.
The pinned Ruby `pascal_triangle_ii` sources return a zero-based Pascal row; the dynamic-programming file's final active method builds the full triangle, while the maths file uses binomial coefficients. The benchmark preserves the row-index contract and hashes the returned row. See the [guide](benchmarks/p/pascal_triangle_ii/README.md) and [pinned Ruby sources](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/dynamic_programming/pascal_triangle_ii.rb) and [maths source](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/pascal_triangle_ii.rb).
[Lua uint53 bit iterator](benchmarks/i/ibits/README.md) ports the pinned least-significant-first iterator across all nine languages and reports its bounded yield count.
The pinned Python `partition_linked_list` performs a stable linked-list split, placing values below the pivot before values at or above it while preserving order within each group. The bounded array contract hashes that reordered sequence. See the [guide](benchmarks/p/partition_linked_list/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/partition_linked_list.py).
[Local binary pattern](benchmarks/l/local_binary_pattern/README.md) ports the pinned Python neighbor comparisons and weight order across all nine languages for a bounded interior 3x3 patch.
The pinned Python `calculate_pi` uses the Rabinowitz–Wagon spigot state to emit a decimal prefix of π. The portable benchmark preserves its updates through eight fractional digits and hashes the resulting ASCII string. See the [guide](benchmarks/p/pi_generator/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/pi_generator.py).
The pinned Python `naive_bayes_text_classification.py` tokenizes lowercase text, scores class priors and Laplace-smoothed token likelihoods in log space, then returns normalized posteriors. Its bounded contract uses two classes and at most one short ASCII token per document/query. See the [benchmark guide](benchmarks/n/naive_bayes_text_classification/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/naive_bayes_text_classification.py).
The pinned Python and Rust permutation sources differ in traversal order and duplicate handling. On strictly increasing distinct signed-i32 input they produce the same lexicographic permutation list; the benchmark hashes its bounded serialization. See the [guide](benchmarks/p/permutations/README.md), [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/permutations.py), and [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/backtracking/permutations.rs).
[K-th next greater element](benchmarks/k/kth_next_greater_element/README.md) ports the pinned Python strict-successor chain semantics across all nine languages and reports the bounded number of complete results.
The pinned C++ and C++-Plus-Plus-1 `ordinary_least_squares_regressor` sources append an intercept term, solve the multivariate normal equations, and predict rows in input order. The shared contract fixes two features, bounds training and query sizes, and requires full rank. This remains distinct from the univariate `ordinary_least_squares_regression` candidate. See the [guide](benchmarks/o/ordinary_least_squares_regressor/README.md), [C++ source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/machine_learning/ordinary_least_squares_regressor.cpp), and [second C++ source](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/machine_learning/ordinary_least_squares_regressor.cpp).
[Linked deque](benchmarks/l/linked_deque/README.md) ports the pinned Lua doubly linked deque operations across all nine languages and packs bounded query results.
The pinned Python `prefix_evaluation` driver uses the iterative reverse-token stack evaluator; the benchmark preserves its operand pop order for bounded single-digit prefix expressions and maps malformed expressions and division by zero to a sentinel. See the [guide](benchmarks/p/prefix_evaluation/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/prefix_evaluation.py).
The pinned PHP `NeuralNetworkPerceptronClassifier` separates randomized `mt_rand` training from a deterministic prediction method that accepts supplied weights and bias. The nine-language benchmark covers inference; sigmoid output `> 0.5` is exactly the positive weighted-sum decision. See the [guide](benchmarks/n/neural_network_perceptron_classifier/README.md) and [pinned source](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/NeuralNetworks/PerceptronClassifier/NeuralNetworkPerceptronClassifier.php).
The pinned C++ MLP sources expose deterministic `single_predict` for explicitly loaded weights; their normal constructors initialize weights randomly and the example reads CSV files. The benchmark covers one hidden layer with sigmoid activations, supplied bounded weights, and no bias terms. See the [guide](benchmarks/n/neural_network/README.md), [C++ source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/machine_learning/neural_network.cpp), and [second C++ source](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/machine_learning/neural_network.cpp).
[Least square approximation](benchmarks/l/least_square_approx/README.md) ports the pinned Rust degree-one least-squares fit across all nine languages, rounding slope and intercept to five decimals and packing the bounded coefficients.
The pinned Java `PrefixToInfix.getPrefixToInfix` scans prefix characters from right to left and combines the first popped operand before the second inside parentheses. The bounded benchmark accepts ASCII letters and the five source operators, returning the converted bytes or an invalid-expression sentinel. See the [guide](benchmarks/p/prefix_to_infix/README.md) and [pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/PrefixToInfix.java).
The Rust `naive_bayes` source implements Gaussian classification with population variance and a `1e-9` floor; its benchmark preserves first-seen tie order. The R files bundle three different Naive Bayes variants, and the Jupyter filename is a feature-binning notebook rather than a Naive Bayes implementation, so neither is mapped as an alias. See the [Gaussian guide](benchmarks/n/naive_bayes/README.md) and [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/machine_learning/naive_bayes.rs).
The Java `ORSet` candidate is excluded: its `Pair` objects use identity equality in `HashSet`, preventing tombstones from matching equivalent entries copied between replicas and breaking observed-remove merge behavior. [Source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/crdt/ORSet.java).
[K-th element in a list](benchmarks/k/kth_element_in_a_list/README.md) ports both equivalent pinned Clojure 1-based list selectors across all nine languages under a bounded integer-list contract.
The pinned Python `fuzzy_set_operations` module samples triangular membership and supplies eight vector operators: union, intersection, complement, difference, algebraic sum/product, and bounded sum/difference. The benchmark selects one operation per bounded fixed-point vector input; plotting is outside the contract. See the [guide](benchmarks/f/fuzzy_set_operations/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/fuzzy_logic/fuzzy_set_operations.py).
The pinned Python `fuzzy_operations.py` exposes triangular-set complement, intersection, union, and membership methods. The [`fuzzy_operations`](benchmarks/f/fuzzy_operations/README.md) contract preserves the methods’ source argument order (including intersection’s `[max(lefts), min(rights), average(peaks)]` result) on bounded fixed-point inputs; plotting is excluded. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/fuzzy_logic/fuzzy_operations.py).
The pinned Clojure `pack_consecutive_repetitions_in_sublist` provides three equivalent run packers: reduce-and-reverse, `partition-by`, and lazy `take-while`. The bounded benchmark hashes each maximal adjacent-equal run in encounter order. See the [guide](benchmarks/p/pack_consecutive_repetitions_in_sublist/README.md) and [pinned source](https://github.com/TheAlgorithms/Clojure/blob/a9c5bec14928cb22fd4d69e951edf5bd15e16a18/src/data_structures/lists/pack_consecutive_repetitions_in_sublist.clj).
[Kronecker product](benchmarks/k/kronecker_product/README.md) ports the pinned Python block-placement order across all nine languages for bounded 2×2 ⊗ 1×2 inputs and packs the row-major result.
The pinned Python `prefix_conversions_string.py` selects automatic SI or binary prefixes in descending scale order. Its SI function falls back to the original string for nonpositive values because the negative-prefix quotient never passes the source's strict `> 1` test; the bounded benchmark preserves that quirk and requires exact positive scaled quotients. See the [guide](benchmarks/p/prefix_conversions_string/README.md) and [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/prefix_conversions_string.py).
[K-th number](benchmarks/k/kthnumber/README.md) ports the pinned Go in-place partition quickselect with separate one-based minimum and maximum modes and duplicate-aware order statistics.

The pinned Lua `fraction.lua` library reduces rational values by gcd, normalizes denominators to positive values, and adds fractions using a gcd-derived common denominator. The bounded [`fraction`](benchmarks/f/fraction/README.md) benchmark preserves that addition and reduction path for signed numerators and nonzero signed denominators. [Pinned source](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/math/fraction.lua).
The pinned Python and Rust PSNR implementations agree on nonzero mean-squared error; the benchmark bounds paired 8-bit pixels and excludes identical images because Python returns 100 while Rust returns positive infinity. See the [guide](benchmarks/p/peak_signal_to_noise_ratio/README.md), [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_compression/peak_signal_to_noise_ratio.py), and [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/compression/peak_signal_to_noise_ratio.rs).
[Longest subsequence](benchmarks/l/longest_subsequence/README.md) ports the pinned C recursive nondecreasing search, including its strict tie rule and outer-index reuse quirk, with the chosen sequence packed in a bounded scalar.
The pinned Java `PrintAMatrixInSpiralOrder.print` walks the current top row, right column, bottom row backward, and left column backward while shrinking the bounds. The bounded [`print_amatrix_in_spiral_order`](benchmarks/p/print_amatrix_in_spiral_order/README.md) benchmark hashes the clockwise spiral values from rectangular matrices. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/matrix/PrintAMatrixInSpiralOrder.java).

The pinned C# `GallopingStrategy<T>` supplies left and right gallop-bound searches over sorted runs. The nine-port [`galloping_strategy`](benchmarks/g/galloping_strategy/README.md) contract preserves its bounded `BoundLeftShift` saturation and the `GallopRight` equal-key behavior at a run’s start. [Pinned source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sorters/Utils/GallopingStrategy.cs).
[ISO 7816-4 padding](benchmarks/i/iso7816_d4_padding/README.md) ports the pinned C# add, remove, and full-buffer padding-count methods across all nine languages with a bounded byte-array contract.
The pinned Java P² estimator returns exact interpolated quantiles before five samples, then adjusts five marker heights using desired positions and a parabolic prediction with linear fallback. The bounded [`p2_quantile_estimator`](benchmarks/p/p2_quantile_estimator/README.md) package fixes p=0.5 and follows the median marker. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/streaming/P2QuantileEstimator.java).
[Liang–Barsky line clipping](benchmarks/l/liang_barsky/README.md) ports the pinned Java boundary order and t0/t1 updates across all nine languages, packing clipped endpoints quantized to thousandths.

[Dynamic coin change solver](benchmarks/d/dynamic_coin_change_solver/README.md) preserves the pinned C# backward-induction selection order across all nine languages; its documented rule can return a longer sequence than the true minimum-count solution. [Pinned source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Problems/DynamicProgramming/CoinChange/DynamicCoinChangeSolver.cs).
The pinned C++ Gram-Schmidt routine builds each unnormalized orthogonal row by summing projections onto prior rows in source order, then subtracting that sum. The bounded [`gram_schmidt`](benchmarks/g/gram_schmidt/README.md) benchmark accepts at most four independent triangular rows and emits row-major binary64 values. [C++ source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/gram_schmidt.cpp) and [second C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/numerical_methods/gram_schmidt.cpp).

The official PolyBench/C 4.2.1-beta inventory has 30 kernels. The bounded [`polybench_gramschmidt`](benchmarks/p/polybench_gramschmidt/README.md) package preserves its modified Gram–Schmidt QR operation, including normalized Q and the R matrix; it is distinct from the unnormalized `gram_schmidt` profile above. The other kernels map to existing source-specific packages; Floyd–Warshall shares the local all-pairs recurrence but its package exposes a selected source row. See the [PolyBench crosswalk](benchmarks/LAC_DCC_BENCHMARKS_COVERAGE.md#polybench) for all 30 source paths, package mappings, suite status, and license provenance. The full Ohio State Software Distribution License is retained in the PolyBench-derived package directories.

[Word occurrence](benchmarks/w/word_occurrence/README.md) ports the pinned Python case-sensitive token counter across all nine languages. The same-stem F# variant prints repeated words instead of incrementing their counts, so it is documented separately. [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/word_occurrence.py); [F# source](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Strings/WordOccurrence.fs).
The pinned Java `textToPhonetic` uppercases input, skips whitespace, maps ASCII letters and digits to phonetic names, and passes other characters through before joining tokens with spaces. The bounded [`phonetic_alphabet_converter`](benchmarks/p/phonetic_alphabet_converter/README.md) contract covers ASCII input and returns the exact output bytes. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/PhoneticAlphabetConverter.java).
[Lambert ellipsoidal distance](benchmarks/l/lamberts_ellipsoidal_distance/README.md) ports the pinned Python reduced-latitude and Haversine-based Lambert correction across all nine languages for bounded WGS-84 coordinates, returning meters.
The pinned Python `gramian.py` computes the normalized channel Gram matrix of feature maps and the squared Frobenius loss between two such matrices. The bounded [`gramian`](benchmarks/g/gramian/README.md) benchmark exposes both operations on small fixed-point maps across all nine languages. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/computer_vision/gramian.py).

The pinned Python `diff_views_of_binary_tree.py` exposes left and right side views by depth-first preorder and top and bottom views by breadth-first horizontal distance. The nine-language benchmark captures these four outputs in one indexed-tree contract with deterministic level and column tie order. [Guide](benchmarks/d/diff_views_of_binary_tree/README.md) · [source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/diff_views_of_binary_tree.py).
The pinned JavaScript `Pyramid` class computes volume as `(baseArea * height) / 3` and total surface area as `baseArea + ((baseSide * 4) / 2) * sqrt((baseSide / 2)² + height²)`. The bounded [`pyramid`](benchmarks/p/pyramid/README.md) package exposes both formulas using positive fixed-thousandth dimensions. [Pinned source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Geometry/Pyramid.js).

The pinned Java `ElasticCollision2D.resolveCollision` leaves overlapping or separating bodies unchanged and otherwise applies a restitution-1 impulse along the center normal. The bounded [`elastic_collision2_d`](benchmarks/e/elastic_collision2_d/README.md) contract packs the first body's rounded thousandth-unit velocity components into signed 16-bit x/y words; it preserves the source's impulse at exact tangency and for separated approaching bodies. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/physics/ElasticCollision2D.java).
[Laplacian filter](benchmarks/l/laplacian_filter/README.md) ports the pinned Python ksize=1 kernel and top-left filter2D response across all nine languages for 3×3 grayscale patches.
The pinned Python Jacobi solver validates a square system and performs simultaneous updates from the previous iterate. Its helper compares each diagonal coefficient with the signed sum of off-diagonal entries; the bounded [`jacobi_iteration_method`](benchmarks/j/jacobi_iteration_method/README.md) contract uses nonnegative fixed-point coefficients and packs the final vector as binary64. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/linear_algebra/jacobi_iteration_method.py).
The pinned Python power iteration normalizes each matrix-vector product, stops on relative Rayleigh-quotient change, and returns the dominant eigenvalue with its vector. The bounded [`power_iteration`](benchmarks/p/power_iteration/README.md) benchmark selects the eigenvalue for positive-definite symmetric 2×2 matrices and positive starts; the pinned C# dot-product stopping rule and norm return are documented as a distinct variant. [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/linear_algebra/src/power_iteration.py) · [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/LinearAlgebra/Eigenvalue/PowerIteration.cs).
[Lorentz transformation of a four-vector](benchmarks/l/lorentz_transformation_four_vector/README.md) ports the pinned Python x-direction boost across all nine languages with a bounded scaled event and selected output component.
The pinned Python `gaussian_elimination_pivoting` solver chooses the largest absolute pivot with first-row tie behavior, performs elimination using the prior pivot row in its source loop order, and back-substitutes by updating the right-hand side. The bounded [`gaussian_elimination_pivoting`](benchmarks/g/gaussian_elimination_pivoting/README.md) benchmark supports 2–4 variable systems and emits the solution vector as binary64. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/linear_algebra/src/gaussian_elimination_pivoting.py).
The pinned Python `gauss_jordan` reduces a coefficient matrix and RHS together, choosing the first nonzero pivot in each column, normalizing it, and eliminating that column from all other rows. The bounded [`gauss_jordan`](benchmarks/g/gauss_jordan/README.md) benchmark preserves rectangular and rank-deficient cases and emits the reduced matrix followed by transformed RHS as binary64. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/linear_algebra/gauss_jordan.py).
[Gaussian filter](benchmarks/g/gaussian_filter/README.md) preserves the pinned Python valid-window Gaussian convolution for 3×3 and 5×5 kernels, using fixed-point kernel coefficients for cross-language byte consistency.
[Gaussian Mixture Model](benchmarks/g/gaussian_mixture_model/README.md) carries the pinned Python EM updates, covariance regularization, likelihood stopping rule, and component prediction into a bounded one-dimensional model with deterministic initialization.
[Frequent pattern growth](benchmarks/f/frequent_pattern_growth/README.md) counts nonempty frequent itemsets using weighted conditional paths across all nine languages.
[Fresnel diffraction](benchmarks/f/fresnel_diffract/README.md) specializes the pinned transfer-function method to a four-sample complex field with exact factors and a direct DFT.
[Longest Consecutive Characters](benchmarks/l/longest_consecutive_characters/README.md) ports the pinned C# one-pass longest equal-character run algorithm and preserves first-run ties.
[Line sweep overlap check](benchmarks/l/line_sweep/README.md) ports the pinned Java inclusive integer range difference-array scan across all nine languages for bounded endpoints.

The pinned Python `strip` function scans inward from both ends while characters belong to its supplied set, defaulting to space, tab, line feed, and carriage return. The bounded [`strip`](benchmarks/s/strip/README.md) contract preserves that boundary behavior across nine languages on ASCII input. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/strip.py).

The pinned Clojure `flatten_nested_list.clj` provides recursive and tail-recursive flatteners that splice nested collections in left-to-right leaf order. The bounded [`flatten_nested_list`](benchmarks/f/flatten_nested_list/README.md) contract encodes one nested integer-list root as a preorder open/close marker stream and hashes the flattened signed leaves as little-endian bytes with FNV-1a across nine languages. [Pinned source](https://github.com/TheAlgorithms/Clojure/blob/a9c5bec14928cb22fd4d69e951edf5bd15e16a18/src/data_structures/lists/flatten_nested_list.clj).
The pinned C++ elliptic-curve key-exchange sources use affine point addition and binary double-and-add to compute ECDH public points and a shared point; the duplicate repository copy agrees on those operations. The bounded [`elliptic_curve_key_exchange`](benchmarks/e/elliptic_curve_key_exchange/README.md) contract uses validated small prime fields and little-endian point-pair output, excluding the source demo’s large fixed parameters, custom integer tests, and console output. [C++ source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/ciphers/elliptic_curve_key_exchange.cpp) · [additional copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/ciphers/elliptic_curve_key_exchange.cpp).
The pinned C# `DecisionsConvolutions` class chooses a decision by either maximum weighted sum or maximum minimum weighted criterion, returning the first row with the highest score. The bounded [`decisions_convolutions`](benchmarks/d/decisions_convolutions/README.md) contract encodes decimal thousandths exactly and returns the selected zero-based row index across nine languages. [Pinned source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/DecisionsConvolutions.cs).
The pinned C# `Iso10126D2Padding` class adds random fill plus a final count byte, removes bytes based on that count, and reports valid padding lengths without checking the fill bytes. The bounded [`iso10126_d2_padding`](benchmarks/i/iso10126_d2_padding/README.md) contract supplies fill bytes explicitly and covers all three methods across nine languages. [Pinned source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6/Algorithms/Crypto/Paddings/Iso10126D2Padding.cs).

The pinned JavaScript `GenerateSubSets.js` enumerates integer masks in ascending order and scans positions from lowest to highest, preserving duplicate positions. The bounded [`generate_sub_sets`](benchmarks/s/generate_sub_sets/README.md) contract uses n<=12 to avoid the source's signed 32-bit shift edge cases at its nominal length limit and ports the output order to all nine languages. [Pinned source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Bit-Manipulation/GenerateSubSets.js).

The pinned Python Wa-Tor source chooses random entity, movement, and prey-target order. The bounded [`wa_tor`](benchmarks/w/wa_tor/README.md) contract supplies the initial board and fixes those choices to the source's row-major snapshot and pre-shuffle direction priorities, preserving its movement, reproduction, feeding, starvation, and timer rules across nine languages. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/cellular_automata/wa_tor.py).

The pinned Python `top_k_frequent_words` builds its max heap from first-seen words and compares frequency only with strict greater-than checks. The [`top_k_frequent_words`](benchmarks/t/top_k_frequent_words/README.md) benchmark keeps its resulting heap-order-dependent ties and packs bounded lowercase ASCII words for all nine languages. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/top_k_frequent_words.py).
The pinned Python `is_monotonic` accepts arrays whose adjacent pairs are all nondecreasing or all nonincreasing, with equality allowed; empty and singleton arrays return true. The bounded [`monotonic_array`](benchmarks/m/monotonic_array/README.md) benchmark preserves that predicate across nine languages. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/monotonic_array.py).

The pinned Java `LeftistHeap` recursively merges min-heap roots, swaps roots only on strict greater-than, restores the leftist property from null-path lengths, and empties the donor heap after merge. The bounded [`leftist_heap`](benchmarks/l/leftist_heap/README.md) contract uses two heaps, up to 14 operations and keys 0..9, and base-13 encodes up to ten extraction results, including the source's −1 empty result. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/heaps/LeftistHeap.java).
The pinned Python `star_to_delta` and `delta_to_star` routines apply the three-impedance pair-product formulas and return their outputs in a fixed order. The bounded [`star_delta_conversions`](benchmarks/s/star_delta_conversions/README.md) contract selects either direction for positive real fixed-thousandths impedances and hashes the rounded outputs across nine languages. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/star_delta_conversions.py).


The Python `dimensionality_reduction.py` source’s bounded one-component PCA path is tracked separately as [`dimensionality_reduction_pca`](benchmarks/d/dimensionality_reduction_pca/README.md); its LDA and t-SNE methods remain uncovered.


The pinned Python `erosion` function multiplies each image window by its kernel and marks a pixel when the sum equals five. The bounded [`erosion_operation`](benchmarks/e/erosion_operation/README.md) contract preserves the demo’s 3×3 cross kernel and zero padding on binary grids; grayscale conversion and file I/O are outside the operation. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/morphological_operations/erosion_operation.py).

The pinned Java `LyndonFactorization.factorize` uses Duval's linear-time algorithm, compares UTF-16 code units, and returns factors in non-increasing lexicographic order, repeating a factor when the matched period is shorter. The bounded [`lyndon_factorization`](benchmarks/l/lyndon_factorization/README.md) contract uses lowercase ASCII through length 256 and emits each factor followed by NUL; its maximum output buffer is `2*n` bytes across all nine ports. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/LyndonFactorization.java).
The pinned C# `RgbHsvConversion` exposes HSV-to-RGB conversion by six hue sections with nearest-even byte rounding and RGB-to-HSV conversion by max/min/chroma branches with red-first tie handling. The bounded [`rgbhsvconversion`](benchmarks/r/rgbhsvconversion/README.md) package covers both directions and packs their quantized results across nine languages. [Pinned source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/RGBHSVConversion.cs).


The Java bit-manipulation `GenerateSubsets` candidate shares the ascending-mask contract with [`generate_sub_sets`](benchmarks/s/generate_sub_sets/README.md). Its recursive `GenerateSubsets` sibling emits subsets in include-first depth-first order and is tracked separately as [`generate_subsets_recursive`](benchmarks/g/generate_subsets_recursive/README.md). [Bit-manipulation source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/GenerateSubsets.java), [recursive source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/recursion/GenerateSubsets.java).


The pinned Python `federated_average` normalizes nonnegative client weights by their positive sum, then aggregates matching tensor coordinates. The bounded [`federated_averaging`](benchmarks/f/federated_averaging/README.md) package preserves that weighted update for one scalar tensor per client across nine languages. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/federated_averaging.py).

The pinned Go `Matrix.SubMatrix` validates bounds, allocates the requested shape, and copies the selected rectangle; zero output dimensions preserve the corresponding empty shape. The bounded [`submatrix`](benchmarks/s/submatrix/README.md) contract hashes dimensions and row-major selected values for signed-i32 matrices up to 8×8 across all nine language ports. [Pinned source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/matrix/submatrix.go).

The pinned C# `Maclaurin` class also has error-threshold overloads for Exp, Sin, and Cos. The bounded [`maclaurin`](benchmarks/m/maclaurin/README.md) contract preserves `ErrorTermWrapper`'s add-prior-term, compute-next-term, stop-on-threshold order, including omission of the final below-threshold term; fixed-term series are covered by separate benchmarks. [Pinned source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6/Algorithms/Numeric/Series/Maclaurin.cs).

The pinned Python function differentiates symbolic coordinates `r(u,v)` and simplifies the dot products `E = r_u · r_u`, `F = r_u · r_v`, and `G = r_v · r_v`. The bounded [`first_fundamental_form`](benchmarks/f/first_fundamental_form/README.md) contract covers exact quadratic polynomial coordinates and returns the 18 E/F/G coefficients through a scalar hash across nine languages. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/first_fundamental_form.py).

The pinned Java `FIFOCache` source uses its default zero TTL, so sequential puts and gets expose FIFO insertion-order eviction: overwrite removes and appends the key, while reads do not reorder entries. The bounded [`fifocache`](benchmarks/f/fifocache/README.md) contract records hit/miss counts, get results, and final FIFO contents across nine languages; TTL timing, concurrency, callbacks, and explicit removal are outside its scope. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/caches/FIFOCache.java).

The pinned Julia `greedy_algorithm.jl` defines both 0/1 and complete-pack value-first selection. Its `zero_one_pack!` maps to [`greedy_item_selection_by_value`](benchmarks/g/greedy_item_selection_by_value/README.md), and `complete_pack!` maps to [`greedy_unbounded_knapsack_by_value`](benchmarks/g/greedy_unbounded_knapsack_by_value/README.md), which reuses each selected item before scanning the next. [Julia source](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/knapsack/greedy_algorithm.jl).

The pinned Python `greedy_best_first.py` uses a stable open-list sort by Manhattan distance, expands up/left/down/right, keeps the first parent for duplicate open nodes, and returns the start-only path when unreachable. [`greedy_best_first`](benchmarks/g/greedy_best_first/README.md) preserves that ordered result on a bounded grid. [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/greedy_best_first.py).
The pinned C# `JaroWinklerDistance.Calculate` and `JaroSimilarity.Calculate` sources map to [`jaro_winkler_distance`](benchmarks/j/jaro_winkler_distance/README.md), a bounded ASCII contract that returns the C# distance as a fixed-point value. It preserves greedy window matching, integer-divided transpositions, and the four-code-unit prefix boost; the input requires the first string to be at least as long as the second because the helper indexes that way. The same-named Rust candidate returns similarity and uses different matching logic, so it is recorded as divergent. [C# wrapper](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Strings/Similarity/JaroWinklerDistance.cs), [C# helper](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Strings/Similarity/JaroSimilarity.cs), [Rust candidate](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/jaro_winkler_distance.rs).

The pinned Java `GSet` implements a grow-only set CRDT: additions are idempotent, `compare` checks whether the receiver is a subset of the argument, and `merge` unions the argument into the receiver. [`grow_only_set`](benchmarks/g/grow_only_set/README.md) preserves those two-replica operations with deterministic membership masks. [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/crdt/GSet.java).

The pinned Java `PNCounter` keeps positive and negative component maps for each replica, merges them componentwise, and compares replicas with the source's nodewise predicate. [`pncounter`](benchmarks/p/pncounter/README.md) traces three independent counters, preserving its comparison behavior when both components are greater at one node and when P/N gains occur at different nodes. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/crdt/PNCounter.java).
The same-named lazy segment tree sources map to separate contracts: pinned Python range assignment and maximum become [`lazy_segment_tree_range_set_max`](benchmarks/l/lazy_segment_tree_range_set_max/README.md), while pinned Rust range addition and sum become [`lazy_segment_tree_range_add_sum`](benchmarks/l/lazy_segment_tree_range_add_sum/README.md). The Python wrapper normalizes 1-based inclusive source ranges to zero-based half-open operations; the Rust wrapper uses fixed-width records for opcode 0 add and opcode 1 sum query. The pinned Java source double-applies lazy updates and is excluded as invalid. [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/lazy_segment_tree.py), [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/lazy_segment_tree.rs), [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/LazySegmentTree.java).

The pinned R `get_k_folds` function creates contiguous labels in its `isList=FALSE` mode using ceiling blocks. [`k_folds`](benchmarks/k/k_folds/README.md) benchmarks that deterministic branch; the list mode's shuffled sample output is separately excluded. [R source](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/data_preprocessing/k_folds.r).

The pinned C# `Job.cs` file only declares a record with start and end times; it contains no scheduling procedure and is excluded as a non-benchmarkable support type. [Source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Problems/JobScheduling/Job.cs).
The pinned Java `LibrarySort` source maps to [`library_sort`](benchmarks/l/library_sort/README.md), a bounded gapped insertion sort that inserts doubling batches into a sparse array and evenly rebalances occupied slots. Both pinned C++ files are excluded because of uninitialized occupancy/library slots and their empty-input dereference. [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/LibrarySort.java).
The pinned Python and Rust `smallest_range` sources map to [`smallest_range`](benchmarks/s/smallest_range/README.md), which advances the minimum head from a min-heap while tracking the largest head. It returns the narrowest interval covering each nonempty sorted list and keeps the first interval found on equal widths. [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/greedy_methods/smallest_range.py), [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/greedy/smallest_range.rs).

The pinned C# `KochSnowflake.Iterate` repeatedly replaces each segment with its first third, the +60-degree middle-third point, and the second trisection point, preserving the endpoint order. [`koch_snowflake`](benchmarks/k/koch_snowflake/README.md) bounds the point-array ABI to eight points and one iteration, mirrors `Vector2` binary32 rounding, and widens coordinates for tolerance-based output comparison. [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/KochSnowflake.cs).

The pinned C# `LongUtils` exposes signed and unsigned 64-bit left and right rotations. [`long_utils`](benchmarks/l/long_utils/README.md) selects each overload with an operation code, bounds distances to 0..63, and returns the exact rotated bit pattern as little-endian bytes. [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Crypto/Utils/LongUtils.cs).

The pinned Java Hierholzer implementation builds undirected adjacency deques in ascending vertex order, consumes the first available edge, and prepends vertices while unwinding. [`hierholzer_algorithm`](benchmarks/h/hierholzer_algorithm/README.md) preserves the empty, edgeless, disconnected, and input-order results in a bounded undirected multigraph. [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/HierholzerAlgorithm.java).

The pinned C# HyperLogLog updates registers only for observed positive integers and estimates cardinality from their lowest-set-bit ranks with the source's 0.673 constant and ceiling rule. [`hyper_log_log`](benchmarks/h/hyper_log_log/README.md) preserves the binary-prefix register indexing and touched-register calculation for values 1 through 65,535. [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6/Algorithms/DataStructures/Probabilistic/HyperLogLog.cs).

The pinned C# `InvertedIndex` maps exact case-sensitive words to document IDs, removes duplicate words per document, and evaluates AND/OR queries. [`inverted_index`](benchmarks/i/inverted_index/README.md) sorts matching IDs and hashes the framed result list for its scalar ABI. [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6/Algorithms/DataStructures/InvertedIndex.cs).

The pinned Go hashmap stringifies integer keys, folds FNV-1a hashes into power-of-two buckets, appends new keys to separate chains, and doubles capacity when load exceeds 0.75. [`hashmap`](benchmarks/h/hashmap/README.md) records query results plus final size and capacity as little-endian signed-i64 bytes. [Go source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/structure/hashmap/hashmap.go).

The pinned MATLAB `secant` routine applies the two-point recurrence to f(x)=x²−3, checking the current second point's residual before each update. [`secant`](benchmarks/s/secant/README.md) bounds the initial values, residual tolerance, and update count in integer-scaled inputs; it returns the second point when the residual passes and a finite sentinel for invalid inputs or exhaustion. [MATLAB source](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/arithmetic_analysis/secant.m).

The pinned C++ sparse-matrix examples classify a matrix as sparse only when strictly more than half of its entries are zero. [`sparse_matrix`](benchmarks/s/sparse_matrix/README.md) uses bounded row-major signed 32-bit entries, includes maximum-dimension threshold cases, and returns `-1` for malformed or null input. [C++ source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/sparse_matrix.cpp).

The pinned Java `HashMapCuckooHashing` uses two hash locations, relocation on collisions, and nested table growth. [`hash_map_cuckoo_hashing`](benchmarks/h/hash_map_cuckoo_hashing/README.md) bounds the input to safe capacity/key classes and hashes the final size and lookup indices in insertion order. [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/hashmap/hashing/HashMapCuckooHashing.java).

The pinned Java and Python stock-span sources pop earlier prices less than or equal to the current price, so equal prices extend the span. [`stock_span_problem`](benchmarks/s/stock_span_problem/README.md) returns one little-endian signed-i64 span per price for a bounded stream of up to 64 signed-i32 prices. [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/StockSpanProblem.java), [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/stock_span_problem.py).

The pinned Python `points_to_polynomial` routine interpolates a polynomial with a descending-power Vandermonde matrix and Gauss–Jordan elimination. [`polynom_for_points`](benchmarks/p/polynom_for_points/README.md) preserves source operation order and exact formatting for a bounded integral-coefficient domain, including signed zero, with a maximum 124-byte output. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/linear_algebra/src/polynom_for_points.py).

The pinned Lua constructor uses median-of-medians quickselect to build a median-split k-d tree, and nearest-neighbor search visits the near branch before considering the far branch. [`k_d_tree`](benchmarks/k/k_d_tree/README.md) preserves that build and search behavior for bounded 2D and 3D point sets with distinct coordinates on each axis and a unique nearest point. [Pinned source](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/k_d_tree.lua).

The pinned Java `LZW` initializes compression and decompression dictionaries with byte codes 0 through 255, adds phrases in encounter order, and handles the decoder next-code special case. [`lzw`](benchmarks/l/lzw/README.md) covers bounded ASCII compression and decompression, rejecting invalid code streams and decoded output beyond its limit. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/compression/LZW.java).

The pinned C# `Pkcs7Padding` exposes add, remove, and padding-count operations. [`pkcs7_padding`](benchmarks/p/pkcs7_padding/README.md) preserves its full-buffer padding-count calculation, offset write behavior, and suffix validation quirks for bounded byte arrays. [Pinned source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6/Algorithms/Crypto/Paddings/Pkcs7Padding.cs).

The pinned Java `ProductCipher` demo shifts each accepted UTF-16 code unit by +5, pads with `/` to a multiple of n, and emits the padded text column by column. [`product_cipher`](benchmarks/p/product_cipher/README.md) benchmarks that ciphertext transform over bounded ASCII input. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/ProductCipher.java).

The pinned Rust `enumerate_graph` sorts vertices by `Ord`, maps labels to 1-based ranks, preserves adjacency-list order, and returns a leading empty row. [`graph_enumeration`](benchmarks/g/graph_enumeration/README.md) benchmarks that conversion for bounded signed labels, preserving duplicate neighbors while rejecting unknown labels. [Pinned source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/graph_enumeration.rs).

The pinned Java `LIFOCache` keeps insertion order from oldest to youngest: a full-cache insertion evicts the youngest entry, updates move an existing key to the youngest position, and reads do not reorder entries. [`lifocache`](benchmarks/l/lifocache/README.md) preserves that default-TTL operation trace, including hit/miss counters and removal behavior. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/caches/LIFOCache.java).

The pinned Python `LRUCache` keeps keys MRU-first in a deque; each reference moves its key to the front, and insertion into a full cache drops the LRU key at the back. [`least_recently_used`](benchmarks/l/least_recently_used/README.md) maps bounded reference traces to the final cache order for signed-i32 keys. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/least_recently_used.py).

The pinned Go `LFU` implementation never increments item frequencies, so successful reads and duplicate puts move entries within the frequency-one list as LRU touches; duplicate puts also lose the attempted value update. [`lfu`](benchmarks/l/lfu/README.md) preserves those source quirks in bounded signed-i32 cache traces with explicit null and output-capacity behavior. [LFU source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/cache/lfu.go) · [supporting item source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/cache/lru.go).

The pinned Java `LinkListSort.isSorted` supports linked-list merge sort, insertion sort, and heap sort selectors, each copying the ascending result into the input array; its boolean result is always true because both compared arrays alias that input. [`link_list_sort`](benchmarks/l/link_list_sort/README.md) records the sorted signed-i32 array as little-endian bytes for all three selectors. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/LinkListSort.java).

The pinned Python `merge_sort_linked_list` splits a singly linked list with slow and fast pointers, then recursively merges the sorted halves. [`merge_sort_linked_list`](benchmarks/merge_sort_linked_list/README.md) records ascending signed-i32 values as little-endian bytes for lists of up to 128 distinct values; duplicate values are rejected because equal dataclass keys can trigger comparisons between node links. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/merge_sort_linked_list.py).

The pinned Java `SortStack.sortStack` recursively orders stack entries in ascending bottom-to-top order while retaining duplicates. [`sort_stack`](benchmarks/s/sort_stack/README.md) uses a bounded signed-i32 stack and records the sorted values as little-endian bytes, including empty, maximum-size, and output-buffer boundary cases. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/SortStack.java).

The pinned Java `MergeKSortedLinkedList.mergeKList` merges bounded nondecreasing signed-i32 chains with a priority queue and keeps duplicates. [`merge_ksorted_linked_list`](benchmarks/merge_ksorted_linked_list/README.md) records the merged values as little-endian bytes for up to 16 lists and 128 total nodes. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/MergeKSortedLinkedList.java).

The pinned Python `MaxFenwickTree` supports point assignment and half-open range maximum queries over its zero-initialized tree. [`maximum_fenwick_tree`](benchmarks/maximum_fenwick_tree/README.md) records each query result as a little-endian signed-i64 word, including decreases that require recomputing a Fenwick bucket. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/maximum_fenwick_tree.py).

The pinned Java `MergeSortedSinglyLinkedList.merge` stably merges two sorted chains by relinking the original nodes, despite its Javadoc claim that it leaves inputs unchanged. [`merge_sorted_singly_linked_list`](benchmarks/merge_sorted_singly_linked_list/README.md) records each result node's value, source list, and original position as little-endian signed-i32 triples, preserving A-first tie order.

The pinned C++ `median_search2::middleNode` advances slow and fast links through a singly linked list, selecting the second middle node when the length is even. [`median_search2`](benchmarks/median_search2/README.md) records the selected node's zero-based position, so repeated values preserve node identity in the result.

The pinned Java `MazeRecursion` provides two recursive search orders over an 8-by-7 grid, marking path cells and explored dead ends in place. [`maze_recursion`](benchmarks/m/maze_recursion/README.md) returns the found flag and all mutated grid cells directly as little-endian signed-i32 words, including the mutations from unsuccessful searches. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/backtracking/MazeRecursion.java).

The pinned Java `MedianOfMatrix.median` ignores null rows, flattens the remaining values, and selects the lower median after signed sorting. [`median_of_matrix`](benchmarks/median_of_matrix/README.md) accepts unsorted rows and records the selected signed-i32 value in four little-endian bytes.

The pinned C++ `linear_probing` table uses zero for empty slots, `-1` tombstones, linear probing, duplicate insertion, and growth when its load reaches one half. [`linear_probing_hash_table`](benchmarks/l/linear_probing_hash_table/README.md) records bounded add, remove, internal find, hash, and display operations as signed-i64 words, including tombstone reuse and growth. The source-equivalent hash behavior is bounded to the pinned Apple Clang/libc++ target. [C++ source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/hashing/linear_probing_hash_table.cpp) · [additional source snapshot](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/hashing/linear_probing_hash_table.cpp).

The pinned Python `mixed_keyword` cipher removes duplicate key letters in first-seen order, lays the unique key and remaining alphabet into rows, then reads columns to build its substitution map. [`mixed_keyword_cypher`](benchmarks/m/mixed_keyword_cypher/README.md) preserves that default A–Z mapping, uppercases ASCII letters, and passes other ASCII plaintext bytes through unchanged. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/mixed_keyword_cypher.py).

The pinned C# `ListBasedQueue<T>` implements a linked FIFO queue with enqueue, dequeue, peek, clear, empty, and always-false full checks. [`list_based_queue`](benchmarks/l/list_based_queue/README.md) records each bounded operation as a two-word little-endian signed-i64 result and rejects traces that dequeue or peek while empty. [Pinned source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Queue/ListBasedQueue.cs).

The pinned Dart `ListQueue<T>` is a fixed ten-slot FIFO queue. [`list_queue`](benchmarks/l/list_queue/README.md) records enqueue, dequeue, and size traces in little-endian signed-i32 output; empty dequeues use a tagged result, and full enqueue attempts invalidate the trace. Its `hasElements()` method checks the backing-array length and is always true, so it is excluded. [Pinned source](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/data_structures/Queue/List_Queue.dart).

The pinned Dart and TypeScript `LinkedListStack<T>` implementations push and pop at the linked-list head and share size and `isEmpty` queries. [`linked_list_stack`](benchmarks/l/linked_list_stack/README.md) encodes those query results as little-endian signed-i32 pairs, excludes empty-pop traces, and caps stack depth at 64 in both source implementations. The TypeScript-only `top` method is outside the shared interface. [Dart source](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/data_structures/Stack/Linked_List_Stack.dart) · [TypeScript source](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/stack/linked_list_stack.ts).

The pinned C# `ListBasedStack<T>` uses a linked list, pushes constructor items in enumeration order, and treats the final enumerated item as the top. [`list_based_stack`](benchmarks/l/list_based_stack/README.md) records push, pop, peek, count, contains, and clear results as two-word little-endian signed-i64 records for bounded traces. [Pinned source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Stack/ListBasedStack.cs).

The pinned Java `LinearProbingHashMap` uses the inherited `Map.hash` masked integer index and wraparound linear probing; put may resize before finding an existing key, deletion rehashes the following cluster, and the map shrinks at the source threshold. [`linear_probing_hash_map`](benchmarks/l/linear_probing_hash_map/README.md) records these operations in a bounded byte-output trace, including key enumeration in ascending signed-integer order and null/error behavior. [Map source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/hashmap/hashing/LinearProbingHashMap.java) · [inherited Map helper](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/hashmap/hashing/Map.java).

The pinned Python `kruskal(num_nodes, edges)` stable-sorts original edge triples by weight and returns the accepted forest edges in scan order, preserving input order for ties. [`minimum_spanning_tree_kruskal`](benchmarks/m/minimum_spanning_tree_kruskal/README.md) captures that ordered forest output, including disconnected graphs, for bounded signed-i64 weights. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/minimum_spanning_tree_kruskal.py).

The pinned Python `GraphUndirectedWeighted.kruskal` scans neighbors by ascending vertex and input insertion order, then stable-sorts by weight. [`minimum_spanning_tree_kruskal2`](benchmarks/m/minimum_spanning_tree_kruskal2/README.md) preserves accepted edge order for connected graphs with canonical unique signed-i32 edges. [Pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/minimum_spanning_tree_kruskal2.py).

The pinned JavaScript `KeyPriorityQueue` implements keyed min-heap insertion, update, lookup, and removal; its strict priority comparisons determine tie behavior during sifting. [`key_priority_queue`](benchmarks/k/key_priority_queue/README.md) preserves those ordering rules over a bounded deterministic operation trace. [Pinned source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Heap/KeyPriorityQueue.js).

The pinned Java `MLFQScheduler` scans FIFO queues by level, runs one process from each nonempty queue per pass, and can run demoted processes again later in the same pass. [`mlfqscheduler`](benchmarks/m/mlfqscheduler/README.md) records ordered completion events while preserving ignored arrival times and final-queue requeue behavior. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/MLFQScheduler.java).

The pinned Python `MLFQ.multi_level_feedback_queue` performs one round-robin pass per early queue level and finishes the remaining processes in FIFO order. [`multi_level_feedback_queue`](benchmarks/m/multi_level_feedback_queue/README.md) records finish-order timing metrics with all arrivals fixed at time zero, avoiding the source's unusual nonzero-arrival current-time update.

The pinned Java and Python stack-with-queues sources place the top element at the front of the main queue; push transfers the existing queue behind the new item. [`stack_using_two_queues`](benchmarks/s/stack_using_two_queues/README.md) preserves that LIFO behavior and encodes empty peek as an explicit tagged result. [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/StackUsingTwoQueues.java) · [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/stack_using_two_queues.py).

The pinned Lua `linked_stack` exposes push, top, pop, and empty over a linked node chain. [`linked_stack`](benchmarks/l/linked_stack/README.md) preserves the source’s nil results for empty top/pop and continues the bounded operation trace after them. [Pinned source](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/linked_stack.lua).

The pinned Java `LCA` roots an undirected tree at vertex 0, records parent and depth with DFS, then raises the deeper query vertex and climbs both parent chains until they meet. [`lca`](benchmarks/l/lca/README.md) bounds the input to one validated tree of up to 64 vertices and returns the common ancestor ID for one query. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/LCA.java).

The pinned Java `johnsonAlgorithm` converts a directed adjacency matrix into an edge list, computes Bellman-Ford potentials, then runs Dijkstra from each vertex. [`johnsons_algorithm`](benchmarks/j/johnsons_algorithm/README.md) preserves zero as the absent-edge marker and bounds the domain to strongly connected graphs with no negative cycles and strictly positive reweighted edges. [Pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/graphs/JohnsonsAlgorithm.java).

The pinned C++ `list_array::list` inserts into an array before one selection sort, then recursively binary-searches and removes values while returning lookup indices and the final sorted array; duplicate hits follow the midpoint search. [`list_array`](benchmarks/l/list_array/README.md) captures bounded traces that stay within the source's defined capacity, ordering, and spare-slot behavior. [C-Plus-Plus source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/list_array.cpp) · [C-Plus-Plus-1 source](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/list_array.cpp).

## Logistic regression prediction

The pinned MATLAB-Octave `Predict.m` and `Sigmoid.m` helpers compute each row's sigmoid score from the supplied feature matrix and parameter vector. The bounded contract accepts 1–63 rows and 1–32 features, with feature and parameter values in `[-1000,1000]`; it sets bit `j` when row `j` has a nonnegative dot product. See the [guide](benchmarks/l/logistic_regression_predict/README.md) and pinned [prediction source](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/machine_learning/Logistic-Regression/Predict.m).

## Logistic regression training variants

The training candidates retain their source-specific update rules as separate benchmarks. Python [`logistic_regression_python_binary_gd`](benchmarks/l/logistic_regression_python_binary_gd/README.md) returns weights from zero-initialized full-batch mean-gradient updates without an intercept; see the pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/logistic_regression.py). Rust [`logistic_regression_rust_binary_gd`](benchmarks/l/logistic_regression_rust_binary_gd/README.md) returns a bias followed by weights from summed batch gradients; see the pinned [Rust trainer](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/machine_learning/logistic_regression.rs) and [gradient-descent update](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/machine_learning/optimization/gradient_descent.rs). C# [`logistic_regression_csharp_binary_gd`](benchmarks/l/logistic_regression_csharp_binary_gd/README.md) trains weights and an intercept with mean gradients, then returns one query probability; see the pinned [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/MachineLearning/LogisticRegression.cs). These are separate from MATLAB-Octave [`logistic_regression_cost_gradient`](benchmarks/l/logistic_regression_cost_gradient/README.md), which returns loss and the mean gradient for supplied parameters without training.

## Time simulation

The pinned Zig virtual clock schedules and cancels events, advances time inclusively, and resolves equal-time events by active slot order. The bounded scalar contract hashes action results and fired-event records, with at most 1024 active events and 4092 cumulative callbacks in a 4096-action trace. See the [guide](benchmarks/t/time_simulation/README.md) and pinned [Zig source](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/tiger_style/time_simulation.zig).

## MD2 digest

The pinned C# `Md2Digest.Digest` computes the standard RFC 1319 digest from raw bytes. [`md2_digest`](benchmarks/m/md2_digest/README.md) accepts an empty message and byte sequences up to 63 octets, and returns the 16 digest octets in order; its independent [oracle](benchmarks/md2_digest_oracle.py) and pinned [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Crypto/Digests/Md2Digest.cs) define the contract.

## Direct polynomial evaluation alias

The pinned JavaScript `Polynomial.evaluate` method maps to the existing [`polynomial_evaluation_direct`](benchmarks/p/polynomial_evaluation_direct/README.md) contract, which sums `coefficient_i * x^i` in ascending degree order for bounded integer inputs. The class’s `display()` method formats a string and is outside evaluation; see the pinned [JavaScript source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/Polynomial.js).

## Median-of-three quick sorter

The pinned C# `MedianOfThreeQuickSorter` selects the median of the left, middle, and right elements as its quicksort pivot. The [`median_of_three_quick_sorter`](benchmarks/m/median_of_three_quick_sorter/README.md) contract uses `sort_call` with zero through 256 signed-i64 values and a consistent total-order comparer; see the pinned [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6/Algorithms/Sorters/Comparison/MedianOfThreeQuickSorter.cs).

## Merge sort without extra merge space

The pinned Java `MergeSortNoExtraSpace.sort` recursively merges by packing selected values into the high part of existing elements with `maxElement = max + 1`, then restoring each value. [`merge_sort_no_extra_space`](benchmarks/m/merge_sort_no_extra_space/README.md) bounds arrays to 256 values in `0..32767`, keeping every packed intermediate within signed 32-bit range, and returns the sorted values as little-endian i32 bytes. See the [workload](benchmarks/m/merge_sort_no_extra_space/workload.json) and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/MergeSortNoExtraSpace.java).

## Procentual proximity scoring

The pinned Python `procentual_proximity` function normalizes each column by its minimum and maximum, applies each binary lower-is-better or higher-is-better weight, and accumulates row scores in column order. [`procentual_proximity`](benchmarks/p/procentual_proximity/README.md) emits each original row followed by its score as little-endian binary64 values, up to 4,608 bytes; see the pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/scoring_algorithm.py).

## Streaming median filter

The pinned Java `MedianFilter.filter` reports each causal trailing-window median in arrival order, retaining duplicates and averaging the two middle values for an even window. [`median_filter`](benchmarks/m/median_filter/README.md) bounds windows to 1–16, signals to 64 samples, and returns one binary64 median per sample; the similarly named Python image filter is a different algorithm. See the pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/streaming/MedianFilter.java).

## Binary mutation

The pinned MATLAB `Mutate(x, mu)` flips each binary gene when its supplied uniform draw is strictly below `mu`. The nine-language [`mutate`](benchmarks/m/mutate/README.md) package accepts one row vector and one draw per gene, making the source threshold operator deterministic while preserving per-position behavior; a valid empty genome succeeds with a nonnull zero-capacity output, while null output returns `-2` even for an empty result. See the [workload](benchmarks/m/mutate/workload.json) and pinned [MATLAB source](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/Genetic-Algorithm/Minimization%20of%20polynomial%20function/Mutate.m).

## Big integer multiplication

The Rust `multiply` source performs grade-school multiplication of canonical nonnegative decimal strings. [`big_integer_multiply`](benchmarks/b/big_integer_multiply/README.md) bounds each ASCII operand to 32 digits and returns the exact product as ASCII bytes, with at most 64 output bytes. The Go source with the same filename is tracked separately as a matrix-product alias. See the [workload](benchmarks/b/big_integer_multiply/workload.json) and pinned [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/big_integer/multiply.rs).

## String tokenization

The pinned AArch64 `stTokenize` routine splits printable ASCII at a selected comma, period, or colon and preserves empty tokens. [`tokenize_string`](benchmarks/t/tokenize_string/README.md) bounds text to 128 bytes and 19 tokens, then returns a count byte followed by NUL-separated copied text and a final NUL. See the [workload](benchmarks/t/tokenize_string/workload.json) and pinned [AArch64 source](https://github.com/TheAlgorithms/AArch64_Assembly/blob/cb138a856a3af14d3d3dfcd2743d43841eec566f/string/tokenize_string.s).

## Population sorting by cost

The pinned MATLAB `SortPopulation` orders population records by ascending `Cost` and keeps each payload attached to its cost. [`sort_population`](benchmarks/s/sort_population/README.md) uses distinct bounded costs and permutation IDs, returning sorted cost/ID pairs as little-endian signed 64-bit records. See the [workload](benchmarks/s/sort_population/workload.json) and pinned [MATLAB source](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/Genetic-Algorithm/Minimization%20of%20polynomial%20function/SortPopulation.m).

## Mean bias deviation percentage

The pinned Python `mbd(predict, actual)` reports signed mean prediction error relative to mean actual value, as a percentage, preserving its source expression order. [`mean_bias_deviation_percent`](benchmarks/m/mean_bias_deviation_percent/README.md) uses 1–64 bounded integer pairs and rejects a zero actual sum. See the [workload](benchmarks/m/mean_bias_deviation_percent/workload.json) and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/scoring_functions.py).

## Mass to moles

The pinned Python `mass_to_moles(mass, molar_mass)` rounds the binary64 quotient to two decimal places using Python's ties-to-even behavior. [`mass_to_moles`](benchmarks/m/mass_to_moles/README.md) bounds both integer arguments to 0–1000 with a positive molar mass and returns a finite sentinel for invalid inputs. See the [workload](benchmarks/m/mass_to_moles/workload.json) and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/molecular_chemistry.py).

## Schur complement

The pinned Python source computes `C - B.T @ inv(A) @ B` on its default inverse path. [`schur_complement`](benchmarks/s/schur_complement/README.md) bounds symmetric 2×2 `A` and scalar `B` and `C` blocks, rejects singular `A`, and includes a high magnitude cancellation case to account for binary64 inverse rounding. See the [workload](benchmarks/s/schur_complement/workload.json) and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/linear_algebra/src/schur_complement.py).

## Piecewise linear contrast stretch

The pinned Jupyter notebook maps each grayscale pixel through three ordered contrast-stretch segments using fixed breakpoints and output levels, then truncates to an unsigned byte. [`piecewise_linear_transform`](benchmarks/p/piecewise_linear_transform/README.md) covers the full 0–255 pixel range and excludes image loading and plotting. See the [workload](benchmarks/p/piecewise_linear_transform/workload.json) and pinned [notebook](https://github.com/TheAlgorithms/Jupyter/blob/ebf48b9d0373ae4caccd1d2fad54ad173dbac9e9/machine_learning/Piecewise/piecewise_linear_transform.ipynb).

## Moles to molecules

The pinned Python `moles_to_molecules` source multiplies binary64 moles by `6.022e23`, formats the product with `.4e`, then parses it back to binary64. [`moles_to_molecules`](benchmarks/m/moles_to_molecules/README.md) scales integer micro-moles by 1,000,000 and includes the 175-micro-mole formatting midpoint, which rounds to `1.0538e20` under Python's ties-to-even behavior. See the [workload](benchmarks/m/moles_to_molecules/workload.json) and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/molecular_chemistry.py).

## Single-point crossover

The pinned MATLAB-Octave helper selects a cut in the source range 1 through nVar-1, copies each parent's prefix, and swaps the suffixes. The [single_point_crossover guide](benchmarks/s/single_point_crossover/README.md) supplies the cut explicitly for deterministic cross-language calls and returns both children in one float64 slice. See the [workload](benchmarks/s/single_point_crossover/workload.json) and pinned [MATLAB-Octave source](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/Genetic-Algorithm/Minimization%20of%20polynomial%20function/SinglePointCrossover.m).

## Translator

The pinned C# Translator.Translate method grows a substring at each text position and takes the shortest exact key match. If no key matches at the current position, it drops the remaining suffix. The [translator guide](benchmarks/t/translator/README.md) bounds keys, values, and text to printable ASCII bytes and returns the concatenated replacement bytes. See the [workload](benchmarks/t/translator/workload.json) and pinned [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/DataCompression/Translator.cs).

## Spiral print

The pinned C++ spiralPrint and Python spiral_print_clockwise helpers traverse a rectangular matrix clockwise. The [spiral_print guide](benchmarks/s/spiral_print/README.md) uses matrices with 1–16 rows and 2–16 columns, excluding Python's one-column duplication and the separate spiral_traversal API. See the [workload](benchmarks/s/spiral_print/workload.json), pinned [C++ source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/spiral_print.cpp), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/spiral_print.py).

## Monoalphabetic substitution

The pinned Java `MonoAlphabetic` encrypts through an uppercase substitution key and decrypts through its inverse lookup. The [`mono_alphabetic` guide](benchmarks/m/mono_alphabetic/README.md) packs the operation, text length, 26-letter permutation, and uppercase text into an i64 array; it returns low-63-bit FNV-1a-64 over an unsigned little-endian output length followed by transformed bytes. See the [workload](benchmarks/m/mono_alphabetic/workload.json) and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/MonoAlphabetic.java).

## Monoalphabetic cipher with a supplied alphabet

The pinned PHP `MonoAlphabeticCipher` maps letters between a supplied uppercase alphabet and key, preserves case and spaces, and removes decimal digits. The [`mono_alphabetic_cipher` guide](benchmarks/m/mono_alphabetic_cipher/README.md) requires both strings to be permutations and hashes the transformed bytes with their unsigned little-endian length prefix. See the [workload](benchmarks/m/mono_alphabetic_cipher/workload.json) and pinned [PHP source](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Ciphers/MonoAlphabeticCipher.php).

## MSD radix string sorter

The pinned C# `MsdRadixStringSorter.Sort` uses stable most-significant-digit recursion on UTF-16 code units. The [`msd_radix_string_sorter` guide](benchmarks/m/msd_radix_string_sorter/README.md) bounds strings to bytes 0–255 and hashes the sorted strings with their lengths plus a little-endian string count. See the [workload](benchmarks/m/msd_radix_string_sorter/workload.json) and pinned [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sorters/String/MsdRadixStringSorter.cs).

## Mean shift

The pinned Python `mean_shift` shifts each candidate toward the mean of original points within its bandwidth window, preserving source-order summation and computing Euclidean distance as the sum of squared coordinate differences raised to `0.5`. It checks convergence in candidate order and keeps the previous candidates when all have converged, greedily merges candidates closer than the bandwidth, then labels each point by its nearest retained centroid with first-centroid tie handling. The [`mean_shift` guide](benchmarks/m/mean_shift/README.md) defines 1–16 points, 1–3 dimensions, and 1e-6 decision margins; all nine target-language ports return exact zero-based labels in input order. See the [workload](benchmarks/m/mean_shift/workload.json), [oracle](benchmarks/mean_shift_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/mean_shift.py).

## M-coloring on forests

The pinned Java method performs BFS greedy coloring by starting every vertex at color 1 and incrementing a neighbor when an edge joins equal colors; the benchmark restricts its input to simple undirected forests and records the routine's Boolean result rather than general exact m-colorability. The [`mcoloring` guide](benchmarks/m/mcoloring/README.md) packs zero-based adjacency masks, maps them to the source's one-based node indices, and emits 1 or 0 for a valid forest. All nine target-language ports preserve the pinned result, with invalid framing or cyclic graphs returning -1. See the [workload](benchmarks/m/mcoloring/workload.json), [oracle](benchmarks/mcoloring_oracle.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/backtracking/MColoring.java).

## Seeded Monte Carlo π estimation

The pinned Python estimator is benchmarked with an explicit 32-bit seed and a fresh CPython 3.12-compatible MT19937 stream per call, drawing x then y and returning one `4 * hits / simulations` value. All nine target-language ports implement the same seeded stream and exact-output contract. The contract defines a canonical binary64 `x*x + y*y <= 1.0` projection; it may rarely differ from the source's `x**2 + y**2` at rounding boundaries, and C, C++, and Nim builds disable floating-point contraction to preserve the projection under exact comparison. See the [`pi_monte_carlo_estimation` guide](benchmarks/p/pi_monte_carlo_estimation/README.md), [workload](benchmarks/p/pi_monte_carlo_estimation/workload.json), [oracle](benchmarks/pi_monte_carlo_estimation_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/pi_monte_carlo_estimation.py).

## Skew heap

The pinned Python `SkewHeap` implements a min-skew heap by merging the smaller root, inserting through a singleton merge, and removing the minimum by merging the old root's children. Iteration follows `list(heap)`: it drains values in ascending order, reinserts the sorted snapshot, and preserves duplicates; equal roots retain the first merge argument. The [`skew_heap` guide](benchmarks/s/skew_heap/README.md) bounds traces to 64 operations and 32 live values, returns query results as little-endian signed 64-bit bytes, and rejects empty `top` and `pop` operations. See the [workload](benchmarks/s/skew_heap/workload.json), [oracle](benchmarks/skew_heap_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/heap/skew_heap.py).

## Smoothsort

The pinned Python `smoothsort` builds Leonardo heaps, extracts their maximum roots from right to left, mutates the input list, and returns it in ascending order. The [`smoothsort` guide](benchmarks/s/smoothsort/README.md) accepts up to 64 signed-i64 values, preserves duplicates, and treats an empty list as a valid empty result. This candidate remains separate from [`smooth_sort`](benchmarks/smooth_sort/README.md) because matching names do not establish in-place ABI parity; nine target-language ports are available. See the [workload](benchmarks/s/smoothsort/workload.json), [oracle](benchmarks/smoothsort_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/smoothsort.py).

## Quadratic probing

The pinned Python `QuadraticProbing` hashes each key to `key % capacity`, then probes `(home + i*i) % capacity` beginning at `i=1`. Its collision helper compares occupied values with the home-slot index rather than the inserted key, so a displaced slot can be overwritten; a duplicate whose home slot is occupied elsewhere can also be inserted again. [`quadratic_probing`](benchmarks/q/quadratic_probing/README.md) bounds capacity to 5–31 and insertions to 0–3, preventing resize and ensuring the accepted probe routes terminate. Output contains the capacity and all slots as little-endian signed-i64 words, with -1 for empty slots and zero preserved as a key. The workload has 9 semantic cases and 8 ABI cases. All nine language ports are D58-cleared and integrated with strict workload validation and deterministic verifier coverage. See the [workload](benchmarks/q/quadratic_probing/workload.json), [oracle](benchmarks/quadratic_probing_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/hashing/quadratic_probing.py).

## Shuffled shift cipher

The pinned Python `ShuffledShiftCipher.encrypt` scans its 97-character alphabet, reverses each segment ending at a unique passcode breakpoint, and shifts plaintext by the positive alternating signed passcode sum or the passcode length fallback. [`shuffled_shift_cipher`](benchmarks/s/shuffled_shift_cipher/README.md) accepts an explicit 1–20 character ASCII alphanumeric passcode and 0–256 plaintext characters from that alphabet, returning raw ASCII ciphertext bytes. Malformed or null input returns -1 before output checks; for valid input, null output returns -2 even for empty plaintext, while empty plaintext with a non-null pointer and zero capacity succeeds. The workload has 21 semantic cases and 8 ABI cases, and all nine ports follow the bounded contract. See the [workload](benchmarks/s/shuffled_shift_cipher/workload.json), [oracle](benchmarks/shuffled_shift_cipher_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/shuffled_shift_cipher.py).

## Soboleva modified hyperbolic tangent

The pinned Python activation computes `(exp(a*x)-exp(-b*x))/(exp(c*x)+exp(-d*x))` elementwise, preserving numerator, denominator, and division order. [`soboleva_modified_hyperbolic_tangent`](benchmarks/s/soboleva_modified_hyperbolic_tangent/README.md) bounds coefficients to [-2,2] and samples to [-20,20], returning one binary64 value per sample with 1e-12 absolute and relative tolerances. The workload has 21 semantic cases and 6 ABI cases; all nine ports preserve the formula order, with malformed or null input returning -1 before null or short-output checks. See the [workload](benchmarks/s/soboleva_modified_hyperbolic_tangent/workload.json), [oracle](benchmarks/soboleva_modified_hyperbolic_tangent_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/activation_functions/soboleva_modified_hyperbolic_tangent.py).

## Project Euler 42 word counter (`solution42`)

The pinned Python solution reads the fixed Project Euler 42 `words.txt` fixture, processes only the first LF-, CRLF-, or CR-delimited line, and counts comma-separated words whose uppercase score is one of the first 100 triangular values. [`solution42`](benchmarks/s/solution42/README.md) passes the file bytes as one ASCII value per i64, accepts up to 16,384 bytes, and preserves duplicate tokens. The scalar adapter represents length zero as a null pointer, which is a valid empty file returning 0; a null pointer with positive length, overlong input, or a value outside ASCII returns -1. The 16,346-byte pinned fixture returns 162. All nine language ports are present, with strict workload validation and deterministic verifier coverage. See the [workload](benchmarks/s/solution42/workload.json), [oracle](benchmarks/solution42_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_042/solution42.py).

## LRU cache (`lru_cache2`)

The pinned C++ `LRUCache` moves a successful lookup to the most-recently-used head, inserts new keys there, and evicts the least-recently-used tail when full. [`lru_cache2`](benchmarks/l/lru_cache2/README.md) bounds capacity to 2–64 and traces to 256 operations, returning each operation result as a little-endian signed 64-bit value. Its safe domain uses distinct put keys and resident get keys to avoid source exception and update paths. See the [workload](benchmarks/l/lru_cache2/workload.json), [oracle](benchmarks/lru_cache2_oracle.py), and pinned [C++ source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/lru_cache2.cpp).

## MRU cache

The pinned Java `MRUCache<Integer, Integer>` keeps the most-recently-used entry at the linked-list tail, promotes hits and updates, and evicts that tail for a new put when full. [`mrucache`](benchmarks/m/mrucache/README.md) bounds capacity to 1–16 and traces to 128 operations; it hashes GET responses, including `-1` misses, with low-63-bit FNV-1a-64 over the framed signed-i32 response sequence. See the [workload](benchmarks/m/mrucache/workload.json), [oracle](benchmarks/mrucache_oracle.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/caches/MRUCache.java).

## Suffix automaton

The pinned Python `SuffixAutomaton` supports substring membership, overlapping occurrence counts, and counts of distinct nonempty substrings. [`suffix_automaton`](benchmarks/s/suffix_automaton/README.md) accepts ASCII text up to 256 bytes and up to 128 queries, preserves the source's empty-pattern behavior, and emits each query opcode with its signed-i64 result in nine bytes. See the [workload](benchmarks/s/suffix_automaton/workload.json), [oracle](benchmarks/suffix_automaton_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/suffix_automaton.py).

## Kruskal minimum spanning tree (`kruskal_mst`)

The pinned JavaScript and R implementations sort undirected weighted edges and use disjoint sets to accept cycle-free edges. [`kruskal_mst`](benchmarks/k/kruskal_mst/README.md) uses connected simple graphs with unique weights, then encodes the normalized MST edge set and total weight in a low-63-bit FNV-1a-64 result. See the [workload](benchmarks/k/kruskal_mst/workload.json), [independent Prim oracle](benchmarks/kruskal_mst_oracle.py), and pinned [JavaScript source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Graphs/KruskalMST.js) and [R source](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/Desktop/open-source/R/graph_algorithms/kruskal_mst.r).

## Mo's algorithm (`mos_algorithm`)

The pinned Java `MosAlgorithm` orders offline range queries by left blocks and alternates right-endpoint direction between blocks, then restores results to query-index order. [`mos_algorithm`](benchmarks/m/mos_algorithm/README.md) covers inclusive range sums and fixed-target frequencies, hashing the ordered signed-i32 results with the operation and query count. See the [workload](benchmarks/m/mos_algorithm/workload.json), [direct-scan oracle](benchmarks/mos_algorithm_oracle.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/MosAlgorithm.java).

## Project Euler problem 4 (`euler_problem_4`)

The pinned C `sol` program scans two three-digit factor ranges and returns their largest palindromic product. [`euler_problem_4`](benchmarks/e/euler_problem_4/README.md) keeps that exact three-digit case and adds one- and two-digit ranges for bounded workload coverage; Euler problems 6 and 7 are benchmarked separately. See the [workload](benchmarks/e/euler_problem_4/workload.json), [direct-enumeration oracle](benchmarks/euler_problem_4_oracle.py), and pinned [C source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/project_euler/problem_4/sol.c).

## Project Euler problem 6 (`euler_problem_6`)

The pinned C program computes the difference between the square of the sum and the sum of squares for 1 through 100. [`euler_problem_6`](benchmarks/e/euler_problem_6/README.md) exposes a bounded upper value from 1 to 100, preserving the exact source result at 100. See the [workload](benchmarks/e/euler_problem_6/workload.json), [closed-form oracle](benchmarks/euler_problem_6_oracle.py), and pinned [C source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/project_euler/problem_6/sol.c).

## Project Euler problem 7 (`euler_problem_7`)

The pinned C program uses an Eratosthenes sieve with an exclusive upper bound of 1,000,000 to find the 10,001st prime. [`euler_problem_7`](benchmarks/e/euler_problem_7/README.md) accepts a bounded 1-based prime ordinal while preserving the source result 104743. See the [workload](benchmarks/e/euler_problem_7/workload.json), [trial-division oracle](benchmarks/euler_problem_7_oracle.py), and pinned [C source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/project_euler/problem_7/sol.c).

## Persistent segment tree with lazy range updates (`persistent_seg_tree_lazy_prop`)

The pinned C++ sources preserve historical versions while applying inclusive range-add updates to the latest version and answering range sums on any existing version. [`persistent_seg_tree_lazy_prop`](benchmarks/p/persistent_seg_tree_lazy_prop/README.md) appends a version for every update, including a zero-delta update, and fingerprints the version count and query sums. See the [workload](benchmarks/p/persistent_seg_tree_lazy_prop/workload.json), [snapshot-based oracle](benchmarks/persistent_seg_tree_lazy_prop_oracle.py), and pinned [C++ source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/range_queries/persistent_seg_tree_lazy_prop.cpp) and [C++-1 source](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/range_queries/persistent_seg_tree_lazy_prop.cpp).

## Clojure persistent list queue (`clojure_persistent_list_queue`)

The pinned Clojure queue uses `conj` to place new values at the list head, `drop-last` to remove the oldest value, and the final list element for peeking. [`clojure_persistent_list_queue`](benchmarks/l/clojure_persistent_list_queue/README.md) records enqueue/dequeue sizes, empty peeks, emptiness checks, and the final FIFO contents in its trace hash. The separate C queue candidate is excluded because its length is uninitialized and its constructors are unsafe. See the [workload](benchmarks/l/clojure_persistent_list_queue/workload.json), [logical FIFO oracle](benchmarks/clojure_persistent_list_queue_oracle.py), and pinned [Clojure source](https://github.com/TheAlgorithms/Clojure/blob/a9c5bec14928cb22fd4d69e951edf5bd15e16a18/src/data_structures/queue/list.clj).

## Sparse table range minimum query (`sparse_table`)

The pinned C++ implementation builds an index-based sparse table and answers one inclusive range-minimum query, preserving the leftmost index when values tie. [`sparse_table`](benchmarks/s/sparse_table/README.md) uses the safe source-compatible array bound of 12,344 and follows the C++ index-returning variant; the Python value-returning variant and broken C++-1 implementation are separate or excluded. See the [workload](benchmarks/s/sparse_table/workload.json), [linear-scan oracle](benchmarks/sparse_table_oracle.py), and pinned [C++ source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/sparse_table.cpp).

## Merge-find set (`merge_find_set`)

The pinned Haskell disjoint set initializes every element from 0 through n−1, applies ordered union-by-rank merges, and returns the final query's representative. [`merge_find_set`](benchmarks/merge_find_set/README.md) preserves the source's equal-rank rule, which attaches the first root under the second, and does not compress paths. See the [workload](benchmarks/merge_find_set/workload.json), [iterative oracle](benchmarks/merge_find_set_oracle.py), and pinned [Haskell source](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/SpecializedStructure/MergeFindSet.hs).

## Trie with autocomplete and frequency search (`trie_multiple_search`)

The pinned C++ trie supports insertion, exact presence checks, lexicographic autocomplete, and frequency-ranked suggestions; delete is excluded. [`trie_multiple_search`](benchmarks/t/trie_multiple_search/README.md) preserves case-folding, deepest-prefix fallback, query-frequency updates, and reverse-lexicographic tie order in its low-63-bit FNV-1a-64 trace hash. See the [workload](benchmarks/t/trie_multiple_search/workload.json), [dictionary oracle](benchmarks/trie_multiple_search_oracle.py), and pinned [C++ source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/operations_on_datastructures/trie_multiple_search.cpp) and [C++-1 source](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/operations_on_datastructures/trie_multiple_search.cpp).

## Sliding-window aggregator (`sliding_window_aggregator`)

The pinned Java aggregator appends values to a fixed-capacity FIFO window, evicts the oldest value on overflow, and sums the retained items. [`sliding_window_aggregator`](benchmarks/s/sliding_window_aggregator/README.md) bounds capacity, count, and values so valid sums cannot collide with the `INT64_MIN` invalid-input sentinel. See the [workload](benchmarks/s/sliding_window_aggregator/workload.json), [FIFO-sum oracle](benchmarks/sliding_window_aggregator_oracle.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/buffers/SlidingWindowAggregator.java).

## Sorted list (`sorted_list`)

The pinned C# array-backed collection maintains ascending integer order with duplicates and supports insertion, presence checks, single-item removal, count queries, indexed reads, and clear. The benchmark uses a bounded operation trace and a weighted checksum of query results and final contents. [`sorted_list`](benchmarks/s/sorted_list/README.md) rejects malformed traces, out-of-range indices, and collection growth beyond 256 items. See the [workload](benchmarks/s/sorted_list/workload.json), [operation-trace oracle](benchmarks/sorted_list_oracle.py), and pinned [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/SortedList.cs).

## Sorted table (`sorted_table`)

The pinned Lua sorted table maintains a unique, ascending integer set with lookup, strict-neighbor, insertion/upsert, removal, range, iteration, emptiness, and clear operations. The benchmark hashes iterator outputs in yielded order and combines operation results with the final set in a bounded checksum. [`sorted_table`](benchmarks/s/sorted_table/README.md) specifies inclusive ranges and maps the integer upsert flag explicitly to Lua booleans. See the [workload](benchmarks/s/sorted_table/workload.json), [sorted-set trace oracle](benchmarks/sorted_table_oracle.py), and pinned [Lua source](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/sorted_set/sorted_table.lua).

## Radix tree (`radix_tree`)

The pinned Python radix tree stores lowercase ASCII words in compressed prefix paths and supports insert, exact find, and delete. The contract preserves the source's root-collapse lookup quirk after deletion, including repeated collapses that can grow an internal prefix beyond the 32-byte word limit; the workload covers a truncation-sensitive 34-byte prefix and a 35-byte collapsed prefix. It scores find/delete results by operation position. [`radix_tree`](benchmarks/r/radix_tree/README.md) bounds operation count and word length; see the [workload](benchmarks/r/radix_tree/workload.json), [semantic oracle](benchmarks/radix_tree_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/trie/radix_tree.py).

## Smoothsort (`smooth_sort`)

The pinned Java Smoothsort sorts signed integers in place in ascending order and returns a weighted checksum of the sorted values. The contract bounds arrays to 512 elements and values to ±1,000,000; empty arrays return zero, and duplicate stability is unobservable. [`smooth_sort`](benchmarks/s/smooth_sort/README.md) documents its 513-value valid frame and 514-value parse limit. See the [workload](benchmarks/s/smooth_sort/workload.json), [ascending-sort oracle](benchmarks/smooth_sort_oracle.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/SmoothSort.java).

## Momentum SGD (`momentum_sgd`)

The pinned Python optimizer keeps an independent velocity for each parameter ID. Each trace starts with fresh state, interleaves updates across IDs, applies `velocity = momentum*velocity - learning_rate*gradient`, and returns `params + velocity`; the result contains final parameters and velocities grouped by ID. The bounded contract uses equal-width finite binary64 vectors. Nine local language ports and runner/verifier integration are statically cleared. See [`momentum_sgd`](benchmarks/m/momentum_sgd/README.md), its [workload](benchmarks/m/momentum_sgd/workload.json), [oracle](benchmarks/momentum_sgd_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/optimizers/momentum_sgd.py).

## Lempel–Ziv compression (`lempel_ziv`)

The pinned Python `compress_data` routine consumes a bounded ASCII bit string and emits its dictionary codes, preserving the source's code-width transitions and zero extension of a final unmatched suffix. The benchmark excludes file framing, the gamma-coded file-size prefix, and byte stop-bit padding. All nine local language ports and runner/verifier integration are statically cleared. See [`lempel_ziv`](benchmarks/l/lempel_ziv/README.md), its [workload](benchmarks/l/lempel_ziv/workload.json), [oracle](benchmarks/lempel_ziv_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_compression/lempel_ziv.py).

## Lempel–Ziv decompression (`lempel_ziv_decompress`)

The pinned Python `decompress_data` routine consumes bounded ASCII code bits, preserves dictionary insertion and rebuild order, emits matched phrase expansions, and discards a final unmatched prefix. Semantic fixtures are generated by the pinned companion compressor, while outputs remain the decoder's source-specific results; the benchmark excludes file framing, headers, and padding. All nine local language ports and runner/verifier integration are statically cleared. See [`lempel_ziv_decompress`](benchmarks/l/lempel_ziv_decompress/README.md), its [workload](benchmarks/l/lempel_ziv_decompress/workload.json), [oracle](benchmarks/lempel_ziv_decompress_oracle.py), and pinned [Python decoder](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_compression/lempel_ziv_decompress.py).

## Spigot digits of pi (`spigotpi`)

The pinned Go `Spigot(n)` returns the requested leading decimal digits as ASCII, beginning with `3` and without a decimal point. The bounded package accepts `n` from 0 through 256 and preserves truncation: the independent Chudnovsky oracle renders guard digits, so `n=4` yields `3141`. D58 cleared the source contract and nine language ports; 97b cleared the `i64_array_bytes_output` runner/verifier wiring, including explicit null-input and null-output ABI cases, and README-linked build discovery for the language m/ paths. See [`spigotpi`](benchmarks/s/spigotpi/README.md), its [workload](benchmarks/s/spigotpi/workload.json), [oracle](benchmarks/spigotpi_oracle.py), and pinned [Go source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/pi/spigotpi.go).

## Shunting yard expression evaluation (`shunting_yard`)

The pinned Swift `ShuntingYard.evaluate(_:)` applies `^` before `*` and `/`, then `+` and `-`; power is right-associative and the other operators are left-associative. The bounded ASCII contract accepts complete binary expressions with nonnegative decimal literals and excludes unary operators, parentheses, exponent notation, and implicit multiplication. It rejects incomplete or unparsed expressions, division by zero, and invalid real powers. The pinned upstream C source is excluded because its precedence-stack implementation is incorrect; the nine local ports implement the valid Swift semantics. The README specifies stepwise binary64 decimal conversion, with each arithmetic operation rounded separately, ties-to-even, and reassociation/FMA disabled. D58 cleared the contract, workload, and oracle; 97b's final static review cleared all nine ports, oracle/workload/runner/verifier integration, README links and semantics, and README-linked builder/coverage source resolution. See [`shunting_yard`](benchmarks/s/shunting_yard/README.md), its [workload](benchmarks/s/shunting_yard/workload.json), [oracle](benchmarks/shunting_yard_oracle.py), and pinned [Swift source](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/algorithms/parsing/shunting_yard/shunting_yard.swift).

## Inverse of a matrix (`inverse_of_matrix`)

This benchmark compares Java scaled-pivot Gaussian elimination with Python determinant/cofactor inversion on 2×2 and 3×3 matrices whose signed integer coefficients represent exact q/16 values. The shared contract accepts only matrices with one strictly dominant coefficient per row and distinct dominant columns, yielding stable, nonsingular inputs; it returns the full inverse as row-major binary64 values. D58 added the contract, workload, and exact-rational oracle; 97b cleared all nine scaled-pivot ports and strict runner/verifier integration in its final static review. See [`inverse_of_matrix`](benchmarks/i/inverse_of_matrix/README.md), its [workload](benchmarks/i/inverse_of_matrix/workload.json), [oracle](benchmarks/inverse_of_matrix_oracle.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/matrix/InverseOfMatrix.java) and [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/inverse_of_matrix.py).

## Mandelbrot black-and-white rendering (`mandelbrot`)

The bounded contract compares the pinned C#, Java, JavaScript, and Python pixel recurrences over 1–16 pixel dimensions, q/16 view coordinates, and 2–64 iteration steps. It emits one black/white byte per pixel in source x-major traversal order; an escape on the final iteration is black. All nine source ports and strict runner/verifier/build integration are statically cleared. See [`mandelbrot`](benchmarks/m/mandelbrot/README.md), its [workload](benchmarks/m/mandelbrot/workload.json), [oracle](benchmarks/mandelbrot_oracle.py), and pinned [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/Mandelbrot.cs), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/Mandelbrot.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/Mandelbrot.js), and [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/fractals/mandelbrot.py) sources.

## Singly linked list operation trace (`singlylinkedlist`)

The pinned Go `Singly` supports ordered insertions, head/tail/position deletion, full reversal, and inclusive-range reversal. `DelByPos` preserves a source quirk: for a nonempty list both positions `current_length` and `current_length + 1` delete the tail; on an empty list position 1 returns `(0, false)`, while position zero is excluded. The bounded contract returns final list contents plus a `(success, value)` pair per operation. 97b and 99b statically cleared all nine node-pool ports and strict runner/verifier integration end to end, including the seeded/max-bound corpus and corrected 227-value malformed probe. See [`singlylinkedlist`](benchmarks/s/singlylinkedlist/README.md), its [workload](benchmarks/s/singlylinkedlist/workload.json), [oracle](benchmarks/singlylinkedlist_oracle.py), and pinned [Go source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/structure/linkedlist/singlylinkedlist.go).

## k-NN binary classification (`k_nn`)

The pinned R `knn_train`/`knn_predict` classification path predicts a binary factor class for one supplied query using unweighted, unnormalized squared Euclidean distance. The bounded contract uses 1–32 training rows, 1–8 integer features, odd `k`, and requires distinct query distances; labels are factor levels `0` then `1`, and the result is class ID 0 or 1. The workload contains seven semantic and eight ABI fixtures. 97b’s final static review cleared all nine ports in the pinned operation order and scalar runner validation/dispatch; the `NULL 0 -1` special probe is in `corpus()`, and the oracle dispatcher is direct. See [`k_nn`](benchmarks/k/k_nn/README.md), its [workload](benchmarks/k/k_nn/workload.json), [oracle](benchmarks/k_nn_oracle.py), and pinned [R source](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/machine_learning/k-NN.r).

## k-means clustering (`k_means_clust`)

The pinned Python `kmeans` performs one assignment-and-centroid-revision update from caller-supplied initial centroids (`maxiter=1`), excluding random initialization and convergence. The bounded contract accepts 1–16 points, 1–4 dimensions, 1–4 clusters, and integer coordinates in [-16,16]; it preserves NumPy `argmin` first-index distance-tie behavior and rejects inputs that leave any cluster empty. Output contains float64 point assignments followed by revised centroid means. Six semantic and ten ABI fixtures are recorded; 97b statically cleared all nine ports and strict runner/verifier integration, including semantic framing guards. See [`k_means_clust`](benchmarks/k/k_means_clust/README.md), its [workload](benchmarks/k/k_means_clust/workload.json), [oracle](benchmarks/k_means_clust_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/k_means_clust.py).

## LU decomposition (`lu_decompose`)

This benchmark computes a no-pivot Doolittle factorization of a caller-supplied square matrix, returning row-major `L` followed by row-major `U`. The bounded contract accepts dimensions 1–4 and integer-valued entries in [-8,8], rejecting matrices with a zero computed pivot; it preserves the pinned operation order. The C implementation is the primary source, with matching C++ and Julia routines as references. The C# `Lu.Decompose` operation and the related C++/C++-1, Python, and Java `lu_decomposition` candidates map to this no-pivot package on its bounded nonzero-pivot domain. C# `Lu.Eliminate` remains a separate [`lu_elimination`](benchmarks/l/lu_elimination/README.md) benchmark; 97b and 99b statically cleared its contract, workload, all nine ports, and strict runner/verifier integration. Dart's separate partial-pivoting LUP operation has its own [`lu_pivot_decomposition`](benchmarks/l/lu_pivot_decomposition/README.md) contract. The contract and all 16 fixtures are statically reviewed; 97b and 99b cleared all nine ports and strict runner/verifier integration end to end. See [`lu_decompose`](benchmarks/l/lu_decompose/README.md), its [workload](benchmarks/l/lu_decompose/workload.json), [oracle](benchmarks/lu_decompose_oracle.py), and pinned [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/numerical_methods/lu_decompose.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/lu_decomposition.h), and [Julia](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/matrix/lu_decompose.jl) sources.

## Pivoted LUP decomposition (`lu_pivot_decomposition`)

This package benchmarks only the pinned Dart `Matrix.decompose()` operation: partial pivoting with first-maximum tie handling, in-place elimination, and combined LU output. The bounded contract accepts dimensions 1–4 and integer matrix entries in [-8,8], requiring every selected pivot to be nonzero. Output is the combined LU matrix in row-major order followed by the full pivot vector; its final element is the dimension plus the number of row swaps. The result count is `n²+n+1`, and float64 outputs use absolute and relative tolerances of 1e-12. 97b and 99b cleared the frozen contract, oracle, fixtures, all nine language ports, and strict runner/verifier integration end to end. This pivoted operation is distinct from the no-pivot Doolittle [`lu_decompose`](benchmarks/l/lu_decompose/README.md) benchmark. See [`lu_pivot_decomposition`](benchmarks/l/lu_pivot_decomposition/README.md), its [workload](benchmarks/l/lu_pivot_decomposition/workload.json), [oracle](benchmarks/lu_pivot_decomposition_oracle.py), and pinned Dart [`Matrix.decompose()`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/lu_decomposition.dart).

## RSA cipher single-character encryption (`rsa_cipher`)

The pinned Python `encrypt_message` and matching Rust `encrypt_text` encrypt one caller-supplied ASCII code using textbook RSA, `ciphertext = code^exponent mod modulus`. The bounded contract accepts codes 0–127, exponents 1 through modulus−1, and moduli 128–65,535; the caller supplies the public key, and key generation and decryption are excluded. One ASCII character maps the Python little-endian byte block and Rust Unicode scalar to the same integer. The result is one signed-i64 ciphertext; the workload has eight semantic and nine ABI fixtures. 97b statically cleared all nine ports and strict runner/verifier integration end to end, including the Rust pinned-source guard. See [`rsa_cipher`](benchmarks/r/rsa_cipher/README.md), its [workload](benchmarks/r/rsa_cipher/workload.json), [oracle](benchmarks/rsa_cipher_oracle.py), and pinned [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/rsa_cipher.py) and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/rsa_cipher.rs) sources.

## Polynomial regression (`polynomial_regression`)

The pinned Python implementation fits a univariate polynomial with the SVD-based Moore–Penrose pseudoinverse of an increasing-power Vandermonde matrix, then predicts caller-supplied query points. The bounded contract covers degree 0–3, 1–5 distinct integer training abscissas in [-2,2], integer responses in [-32,32], and 1–4 query points; it returns float64 coefficients followed by predictions. 97b statically cleared the contract, all 15 fixtures, all nine ports, and strict runner/verifier integration, including semantic/ABI result typing and tuple-oracle invalid-length classification. See [`polynomial_regression`](benchmarks/p/polynomial_regression/README.md), its [workload](benchmarks/p/polynomial_regression/workload.json), [oracle](benchmarks/polynomial_regression_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/polynomial_regression.py).

## Large-number addition (`large_number`)

The pinned C++ `large_number::operator+=` adds two canonical nonnegative decimal strings using least-significant-first digit storage and base-10 carry, then emits the sum as most-significant-first ASCII bytes. The bounded contract accepts 1–64 digits per operand, allowing a leading zero only for the one-character value `0`; the output is at most 65 bytes. The separately overloaded `operator+`, key/representation variants, and non-digit constructor behavior are outside the workload. 97b and 80ac statically cleared the package and all 15 fixtures; 97b cleared all nine ports and strict runner/verifier integration end to end, including source, fixture, and error-precedence guards. See [`large_number`](benchmarks/l/large_number/README.md), its [workload](benchmarks/l/large_number/workload.json), [oracle](benchmarks/large_number_oracle.py), and pinned [C++ source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/large_number.h) with the matching [C++-1 source](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/large_number.h).

## Suffix-trie search (`suffix_trie`)

The pinned Python class named `SuffixTree` builds an uncompressed character trie containing every suffix, then searches by following the query path without checking a terminal marker; the observable operation is substring membership, and the empty pattern matches even empty text. The bounded contract accepts 7-bit ASCII text of length 0–64 and a pattern of length 0–16, returning 1 when found and 0 otherwise. All nine semantic and eight ABI fixtures match the direct oracle; 97b cleared the Python contract/source split and package. 97b statically cleared all nine ports and strict runner/verifier integration end to end. The Rust-only compressed construction candidate is tracked separately as [`suffix_tree`](benchmarks/s/suffix_tree/README.md) and does not provide this substring-search operation. See [`suffix_trie`](benchmarks/s/suffix_trie/README.md), its [workload](benchmarks/s/suffix_trie/workload.json), [oracle](benchmarks/suffix_trie_oracle.py), and pinned [Python source (`data_structures/suffix_tree/suffix_tree.py`)](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/suffix_tree/suffix_tree.py).

## Compressed suffix-tree construction (`suffix_tree`)

The pinned Rust `SuffixTree::new` inserts each bounded 7-bit ASCII suffix in increasing start-position order, splitting compressed edge labels at the first mismatch, then serializes the public node vector in insertion order with raw labels and child order. The contract/classification and seven semantic plus ten ABI fixtures are statically cleared by 97b and 80ac. 97b statically cleared all nine ports and strict runner/verifier integration end to end. This constructor does not add a terminal marker or expose substring search, so it is separate from the Python [`suffix_trie`](benchmarks/s/suffix_trie/README.md). See [`suffix_tree`](benchmarks/s/suffix_tree/README.md), its [workload](benchmarks/s/suffix_tree/workload.json), [oracle](benchmarks/suffix_tree_oracle.py), and pinned [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a4c939ec5163648458a8c2b46fd4c/src/string/suffix_tree.rs).

## Sherman–Morrison rank-one inverse update (`sherman_morrison`)

The pinned Python `Matrix.sherman_morrison` applies the rank-one inverse update to a supplied inverse matrix and column vectors, evaluating `vᵀ A_inverse` before the denominator dot product and preserving the source's left-associated matrix products. An exactly zero denominator returns the source `None` result, represented as an empty output; otherwise it returns the updated matrix in row-major order. The bounded contract uses dimensions 1–4 and finite, exactly integral binary64 matrix/vector entries in [-2,2]. The contract is frozen and 97b cleared the overflow-guarded oracle; the workload has seven semantic and thirteen ABI fixtures. 97b statically cleared all nine ports and strict runner/verifier integration end to end, including overflow guards and fixtures. See [`sherman_morrison`](benchmarks/s/sherman_morrison/README.md), its [workload](benchmarks/s/sherman_morrison/workload.json), [oracle](benchmarks/sherman_morrison_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/sherman_morrison.py).

## Skyline construction (`skyline_algorithm`)

The pinned Java `SkylineAlgorithm.produceSubSkyLines` computes the lower-left Pareto frontier of points already ordered by strictly increasing x, using the source's recursive divide-and-conquer split and merge while preserving input order. The bounded contract accepts 1–64 points with signed-i32 coordinates and positive y values; it does not sort inputs. Output is a count byte followed by source-order little-endian i32 coordinate pairs, bounded by 513 bytes. 97b statically cleared the contract, workload, oracle, all nine language ports, and strict runner/verifier integration, including ABI-symbol and recursive-merge fidelity. Eight semantic and fifteen ABI fixtures are recorded. This point-frontier algorithm is separate from [`max_increase_keeping_skyline`](benchmarks/m/max_increase_keeping_skyline/README.md), which modifies a building grid. See [`skyline_algorithm`](benchmarks/s/skyline_algorithm/README.md), its [workload](benchmarks/s/skyline_algorithm/workload.json), [oracle](benchmarks/skyline_algorithm_oracle.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/divideandconquer/SkylineAlgorithm.java).

## Shannon–Fano prefix-code construction (`shannon_fano`)

The pinned Java `ShannonFano.generateCodes` counts 7-bit ASCII symbols, sorts by descending frequency, then recursively splits the sorted range at the earliest boundary with the most balanced frequency sums. Equal positive frequencies for distinct symbols are rejected because Java's stable sort inherits unspecified `HashMap` iteration order; an exactly single-symbol input receives code `0`, while null and empty inputs both produce an empty map. The bounded contract accepts text of length 0–64 and serializes code entries in ascending symbol order, with output bounded to 111 bytes. The workload has eight semantic and thirteen ABI fixtures. 97b re-cleared the contract and source classification after D58 corrected the earliest-split-tie fixture. 97b statically cleared the corrected workload, all nine ports, and strict runner/verifier integration end to end. See [`shannon_fano`](benchmarks/s/shannon_fano/README.md), its [workload](benchmarks/s/shannon_fano/workload.json), [oracle](benchmarks/shannon_fano_oracle.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/compression/ShannonFano.java).

## Raw R linear regression (`linearregressionrawr`)

The pinned R `ols` routine constructs an intercept-plus-single-predictor design matrix and returns its SVD ordinary-least-squares coefficients. The bounded contract accepts 2–32 observations with finite, exact-integer binary64 inputs: predictor values in [-4,4] must sum to zero and be nonconstant, and responses lie in [-16,16]. The result is `[intercept, slope]`, compared with absolute tolerance 1e-9 and relative tolerance 1e-12. The workload contains eight semantic and eighteen ABI fixtures, and 97b approved the frozen contract, workload, and oracle. 97b statically cleared all nine language ports and strict runner/verifier integration end to end. See [`linearregressionrawr`](benchmarks/l/linearregressionrawr/README.md), its [workload](benchmarks/l/linearregressionrawr/workload.json), [oracle](benchmarks/linearregressionrawr_oracle.py), and pinned R [`ols` source](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/regression_algorithms/linearregressionrawr.r).

## McNaughton–Yamada–Thompson regular-expression matching (`mcnaughton_yamada_thompson`)

The pinned C implementation compiles a small regular-expression language into a Thompson epsilon-NFA and returns full-string acceptance: 1 for a match and 0 for a valid nonmatch. The empty pattern denotes epsilon; nonempty patterns use literals `a`, `b`, and `c`, implicit concatenation, alternation (`|`), postfix Kleene star (`*`), and parentheses. The bounded input uses patterns up to 16 bytes and text up to 32 bytes, with text bytes in ASCII 1–127 (NUL is excluded). It permits at most four NFA fragments and eight states, within the pinned source's ten-entry closure buffers. To preserve recursive `buildAST` behavior safely, every parsed substring whose first and last bytes are parentheses must have those parentheses enclose the entire substring; expressions violating this recursive parser-compatibility guard are rejected. 97b’s final package-wide static review cleared the corrected contract/oracle, all nine ports including C3, and strict runner/verifier integration end to end; MYT is complete. See the [package guide](benchmarks/mcnaughton_yamada_thompson/README.md), its [workload](benchmarks/mcnaughton_yamada_thompson/workload.json), [oracle](benchmarks/mcnaughton_yamada_thompson_oracle.py), and pinned [C source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/misc/mcnaughton_yamada_thompson.c).

## Playfair cipher (`playfair_cipher`)

The shared pinned Java and Python implementations build a 5×5 square, transform digraphs, and return a deterministic 63-bit FNV-1a hash of the resulting ASCII text. The bounded operation is `[operation, key_length, key_bytes..., text_length, text_bytes...]`: operation 0 encrypts and 1 decrypts; keys contain 0–25 uppercase ASCII letters except `J` (duplicates are allowed and first occurrences win); text contains 0–128 such bytes and must have even length. Encryption rejects adjacent repeated plaintext letters; decryption preserves `X` fillers. The contract and 25 workload cases are frozen and approved by 97b. 97b statically cleared all nine ports and strict runner/verifier integration end to end, including the BALLOONX correction. See [`playfair_cipher`](benchmarks/p/playfair_cipher/README.md), its [workload](benchmarks/p/playfair_cipher/workload.json), [oracle](benchmarks/playfair_cipher_oracle.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/PlayfairCipher.java) and [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/playfair_cipher.py).

## Kohonen SOM trace update (`kohonen_som_trace`)

The pinned C and C++ `kohonen_update_weights` routines perform one deterministic update on a one-dimensional chain. The benchmark selects the first best-matching unit by squared distance, clips its radius neighborhood, then applies the supplied learning rate to those weight rows; random initialization and the outer training schedule are excluded. 97b and 99b cleared all nine ports and strict runner/verifier integration. See the [guide](benchmarks/k/kohonen_som_trace/README.md), [workload](benchmarks/k/kohonen_som_trace/workload.json), and [oracle](benchmarks/kohonen_som_trace_oracle.py).

## Kohonen SOM topology update (`kohonen_som_topology`)

The pinned C and C++ update routines operate on a square two-dimensional grid. The contract selects the first nearest unit in x-major then y order, updates the clipped square neighborhood with the source Gaussian distance scale, and returns the minimum distance followed by the updated weights. 97b and 99b cleared all nine ports and strict runner/verifier integration. See the [guide](benchmarks/k/kohonen_som_topology/README.md), [workload](benchmarks/k/kohonen_som_topology/workload.json), and [oracle](benchmarks/kohonen_som_topology_oracle.py).

## Traveling-salesman bitmask dynamic programming (`traveling_salesman_bitmask`)

The pinned R `tsp_bitmask_dp` recurrence returns the minimum cost of a directed closed tour starting at city 0, visiting every city, and returning to city 0. The bounded contract accepts 2–10 cities and follows the source's ascending next-city order. Java's `dynamicProgramming` method maps to this package; its `bruteForce` operation remains a separate candidate. All nine portable implementations are present. See the [guide](benchmarks/t/traveling_salesman_bitmask/README.md), [workload](benchmarks/t/traveling_salesman_bitmask/workload.json), and [oracle](benchmarks/traveling_salesman_bitmask_oracle.py).

## Classical Gram–Schmidt QR decomposition (`qr_decompose`)

The pinned C and C++ helpers apply column-wise classical Gram–Schmidt and return row-major `Q` followed by row-major `R`. Its direct fixtures preserve the pinned projection order for bounded, nonsingular square matrices. Java's `qrdecomposition` candidate maps to the separate `qr_decomposition` factorization-property contract because its modified Gram–Schmidt factors are not guaranteed to match element by element. 97b cleared all nine ports and strict runner/verifier integration. See the [guide](benchmarks/q/qr_decompose/README.md), [workload](benchmarks/q/qr_decompose/workload.json), and [oracle](benchmarks/qr_decompose_oracle.py).

## QR factorization properties (`qr_decomposition`)

This shared property contract groups the pinned C/C++ classical Gram–Schmidt routines, Python Householder routine, and Java modified Gram–Schmidt implementation. It accepts square integer matrices in [-1,1] whose leading principal minors are all nonzero. Because these methods may return different valid factors, it checks reconstruction, orthogonality, and upper-triangular `R` rather than raw `Q`/`R` identity. 97b statically cleared the bounded contract, workload, all nine language ports, and runner/verifier integration. See the [guide](benchmarks/q/qr_decomposition/README.md), [workload](benchmarks/q/qr_decomposition/workload.json), and [oracle](benchmarks/qr_decomposition_oracle.py).

## Shuffle (`shuffle`)

The pinned Lua closure applies forward Fisher–Yates swaps, making one inclusive random draw for each index before the last. The portable contract supplies one bounded offset per iteration and replays the source-order swaps; it does not depend on Lua’s process-global, version-dependent random stream. 97b and 99b statically cleared the workload, all nine ports, and runner/verifier integration. See the [guide](benchmarks/s/shuffle/README.md), [workload](benchmarks/s/shuffle/workload.json), and [oracle](benchmarks/shuffle_oracle.py).

## LU elimination (`lu_elimination`)

The pinned C# `Lu.Eliminate` operation factors the square matrix with no-pivot Doolittle decomposition, then solves through forward and backward substitution. Its package keeps the solution vector distinct from [`lu_decompose`](benchmarks/l/lu_decompose/README.md), which returns the factors. 97b cleared the contract, workload, and oracle; all nine ports and runner/verifier integration are statically cleared end to end. See the [guide](benchmarks/l/lu_elimination/README.md), [workload](benchmarks/l/lu_elimination/workload.json), and [oracle](benchmarks/lu_elimination_oracle.py).

## Spirograph coordinates (`spirograph`)

The pinned C and C++ routines generate sampled spirograph points numerically; graphics, animation, and file output are excluded. The bounded contract accepts 1–32 points, marker ratio `l` in [0,1], inner-radius ratio `k` in [0.25,0.75], and 0–10 rotations, then returns interleaved `(x,y)` coordinates. It preserves the C source's cumulative angle updates and the C++ sources' direct `i*dt` calculation with an absolute tolerance of 1e-10. 97b and 99b statically cleared all nine ports and runner/verifier integration. See the [guide](benchmarks/s/spirograph/README.md), [workload](benchmarks/s/spirograph/workload.json), and [oracle](benchmarks/spirograph_oracle.py); pinned [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/graphics/spirograph.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graphics/spirograph.cpp), and [C++-1](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/graphics/spirograph.cpp) sources.



## Memoized function calls (`memoize`)

The pinned JavaScript wrapper serializes each fixed-arity integer argument tuple as its cache key, calls the callback on misses, and returns cached values on hits. The bounded contract creates a fresh cache per adapter call, emits each callback result, and appends the number of underlying callback evaluations. All nine language ports and runner/verifier integration are statically cleared. See the [guide](benchmarks/memoize/README.md), [workload](benchmarks/memoize/workload.json), and [oracle](benchmarks/memoize_oracle.py).

## LZ78 compression (`lz78`)

The pinned Java `LZ78.compress` operation builds phrases in creation order and emits `(prefix index, next character)` pairs, using NUL to finish a final partial phrase. The paired decompressor is outside the benchmark. All nine language ports and runner/verifier integration are statically cleared. See the [guide](benchmarks/l/lz78/README.md), [workload](benchmarks/l/lz78/workload.json), and [oracle](benchmarks/lz78_oracle.py).


## Q-learning update step (`q_learning`)

The pinned Python `update()` applies one deterministic Q-table update with explicit learning-rate and discount inputs. A terminal transition or empty next-action set uses a next-state maximum of zero; otherwise the maximum is taken as supplied, including negative values. The adapter creates fresh state per call and returns the updated value. All nine language ports and float64-slice runner/verifier integration are statically cleared. See the [guide](benchmarks/q/q_learning/README.md), [workload](benchmarks/q/q_learning/workload.json), [oracle](benchmarks/q_learning_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/q_learning.py).


## Sepia BGR pixel transform (`sepia`)

The pinned Python `make_sepia` mutates BGR pixels after computing grayscale in source order, then adds the factor to green and twice the factor to red with saturation at 255. The bounded contract uses channel levels `{0,64,128,255}` to keep grayscale truncation stable across ports, with dimensions 1–8 and factor 0–255. All nine language ports and runner/verifier integration are statically cleared. See the [guide](benchmarks/s/sepia/README.md), [workload](benchmarks/s/sepia/workload.json), [oracle](benchmarks/sepia_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/sepia.py).


## Sorted linked-list operation trace (`sorted_linked_list`)

The pinned Java and Python implementations provide sorted insert, search, and delete operations. The contract uses distinct signed-i32 keys, preserving ascending insertion and head/tail deletion behavior; it excludes Python merge and duplicate-removal helpers, along with duplicate inserts that can trigger the Python node-comparison failure. All nine ports and the i64 byte-output runner/verifier integration are statically cleared. See the [guide](benchmarks/s/sorted_linked_list/README.md), [workload](benchmarks/s/sorted_linked_list/workload.json), and [oracle](benchmarks/sorted_linked_list_oracle.py).


## Timeline event collection (`timeline`)

The pinned C# `Timeline<TValue>` constructor stable-sorts its initial events by tick time, while later `Add` calls append without re-sorting. The bounded trace preserves insertion-order value queries, sorted distinct before/after time queries, and source removal/count behavior; calendar-component filters and `AddNow` are excluded. All nine ports and the i64 byte-output runner/verifier integration are statically cleared. See the [guide](benchmarks/t/timeline/README.md), [workload](benchmarks/t/timeline/workload.json), and [oracle](benchmarks/timeline_oracle.py).


## Quadratic probing hash table (`quadratic_probing_hash_table`)

The pinned C++ table probes `(hash(key) + i²) % capacity`, reuses tombstones, and doubles while reinserting active keys in old-slot order; rehash follows the same add path and can trigger another resize. For reproducibility, the bounded positive-key contract defines `hash(key) = key` as a benchmark premise. It also preserves the source `find` helper behavior that reports an empty entry when a stored key occupies slot 0. All nine ports and the i64 byte-output runner/verifier integration are statically cleared. See the [guide](benchmarks/q/quadratic_probing_hash_table/README.md), [workload](benchmarks/q/quadratic_probing_hash_table/workload.json), and [oracle](benchmarks/quadratic_probing_hash_table_oracle.py).


## Weighted lottery process scheduling (`lottery_scheduling`)

The pinned Java scheduler selects each process by cumulative ticket ranges in current list order using its seeded `Random` stream, removes the selected process, and reports the schedule and timing outputs. The bounded contract preserves Java 48-bit seed initialization and `nextInt` rejection behavior. All nine ports and the i64 byte-output runner/verifier integration are statically cleared. See the [guide](benchmarks/l/lottery_scheduling/README.md), [workload](benchmarks/l/lottery_scheduling/workload.json), and [oracle](benchmarks/lottery_scheduling_oracle.py).


## Seeded random task scheduling (`random_scheduling`)

The pinned Java scheduler copies the task list and shuffles the copy with its injected `Random` instance. The contract uses integer IDs as opaque task names, preserves duplicate entries, and explicitly fixes Java’s 48-bit random stream and backward Fisher–Yates sequence for reproducibility. All nine ports and the i64 byte-output runner/verifier integration are statically cleared. See the [guide](benchmarks/r/random_scheduling/README.md), [workload](benchmarks/r/random_scheduling/workload.json), and [oracle](benchmarks/random_scheduling_oracle.py).


## Rat in a Maze (`rat_in_maze`)

The contract keeps the pinned Python and Rust maze APIs as separate variants: Python uses `0=open`, searches down/right/up/left between caller-supplied endpoints, and returns a route matrix; Rust uses `1=open`, searches right/down/left/up from a start to the bottom-right, and returns a boolean matrix. It preserves the Rust blocked-destination base-case behavior and maps both sources’ no-route outcomes to `-3`. All nine ports and the i64 byte-output runner/verifier integration are statically cleared. See the [guide](benchmarks/r/rat_in_maze/README.md), [workload](benchmarks/r/rat_in_maze/workload.json), and [oracle](benchmarks/rat_in_maze_oracle.py).

## SHA-2 digest variants (`sha2`)

The pinned Rust `sha2.rs` exposes SHA-224, SHA-256, SHA-384, SHA-512, SHA-512/224, and SHA-512/256. The bounded `i64_array_bytes_output` contract hashes up to 4,096 explicit message bytes and returns raw big-endian digest bytes; SHA-512/t uses its variant-specific initial state rather than truncating ordinary SHA-512. The README, workload, oracle, all nine language implementations, and runner/verifier integration are statically cleared. See the [guide](benchmarks/s/sha2/README.md), [workload](benchmarks/s/sha2/workload.json), [oracle](benchmarks/sha2_oracle.py), and pinned [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/hashing/sha2.rs).


## Realtime Statistics (`realtime_stats`)

The pinned C source provides anchored-mean and Welford methods with float32 state; the first reports sample variance and the second population variance. The C++ benchmark uses `stats_computer2<float>`, with float32 samples and double Welford state; its method 1 is excluded because fields are uninitialized. Each ABI call starts a fresh local stream, so the C functions’ process-static state does not persist across benchmark calls. C-Plus-Plus-1 duplicates the pinned C++ source. All nine ports and the float64 runner/verifier integration are statically cleared. See the [guide](benchmarks/r/realtime_stats/README.md), [workload](benchmarks/r/realtime_stats/workload.json), [oracle](benchmarks/realtime_stats_oracle.py), and pinned [C source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/numerical_methods/realtime_stats.c), [C++ source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/realtime_stats.cpp), and [C++-1 source](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/realtime_stats.cpp).


## 2-3-4 tree (`tree_234`)

The pinned C++ and C++-1 implementations provide a degree-2 B-tree with top-down splitting on insertion and borrowing/merging on deletion. The bounded trace records remove success values and the sorted final traversal; internal tree shape is not observable. All nine language ports and the byte-output runner/verifier integration are statically cleared, including the Rust degree-2 implementation. See the [guide](benchmarks/t/tree_234/README.md), [workload](benchmarks/t/tree_234/workload.json), and [oracle](benchmarks/tree_234_oracle.py), with pinned [C++ source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/tree_234.cpp) and [C++-1 source](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/tree_234.cpp).

## Local weighted least-squares prediction (`local_weighted_learning`)

The pinned Python implementation predicts each training response with Gaussian weighted least squares centered on that row. The bounded contract uses fixed-order binary64 kernel weights and normal-equation accumulation, then solves with partial pivoting and a deterministic pivot guard; the design matrix must have full column rank. Data loading and plotting are excluded. All nine language ports and the float64 runner/verifier integration are statically cleared. See the [guide](benchmarks/l/local_weighted_learning/README.md), [workload](benchmarks/l/local_weighted_learning/workload.json), [oracle](benchmarks/local_weighted_learning_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/local_weighted_learning/local_weighted_learning.py).

## Raw R K-means trainer (`kmeans_raw_r`)

The pinned R source samples distinct initial rows, then repeats first-nearest-center assignment and row-ordered coordinate means until centers stabilize. The benchmark supplies initial row indices to make the run deterministic, repairs the source convergence bookkeeping, and bounds iterations; empty and singleton clusters are rejected. All nine language ports and float64 runner/verifier null-input integration are statically cleared. See the [guide](benchmarks/k/kmeans_raw_r/README.md), [workload](benchmarks/k/kmeans_raw_r/workload.json), [oracle](benchmarks/kmeans_raw_r_oracle.py), and pinned [R source](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/clustering_algorithms/kmeans_raw_r.r).

## Shannon–Fano compressor (`shannon_fano_compressor`)

The pinned C# compressor counts ASCII symbols in first-occurrence order, then greedily selects symbols in that order while cumulative frequency stays at or below half the current node weight. Left and right recursion add 0 and 1; empty and single-symbol inputs preserve their source-specific encodings. The contract serializes compressed bits and the decoding table as bytes. All nine language ports and i64 byte-output runner/verifier integration are statically cleared; null input with length 0 produces the two-byte empty encoding, and the verifier covers a 19-word over-limit case. See the [guide](benchmarks/s/shannon_fano_compressor/README.md), [workload](benchmarks/s/shannon_fano_compressor/workload.json), [oracle](benchmarks/shannon_fano_compressor_oracle.py), and pinned [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/DataCompression/ShannonFanoCompressor.cs).

## SIR model derivative (`sir`)

The pinned Julia notebook defines the SIR right-hand side `dS = -beta*S*I`, `dI = beta*S*I - k*I`, and `dR = k*I`. The bounded contract accepts the state and parameters, returns the three derivatives in that order, and excludes DifferentialEquations solver trajectories and plotting. All nine ports, generated nonfinite probes, and float64 runner/verifier integration are statically cleared. See the [guide](benchmarks/s/sir/README.md), [workload](benchmarks/s/sir/workload.json), [oracle](benchmarks/sir_oracle.py), and pinned [Julia source](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1/pluto_notebooks/sir.jl).

## Linear discriminant analysis (`linear_discriminant_analysis`)

The pinned Python source is a one-dimensional pooled-Gaussian classifier: it computes class means and priors, a shared pooled variance, then chooses the first maximum class score. The bounded contract preserves source operation order and rejects inputs whose top score margin is below `1e-8`. The README, workload, oracle, generated nonfinite probes, all nine language ports, and float64 runner/verifier integration are statically cleared; each input position has NaN/+Inf/-Inf coverage. See the [guide](benchmarks/l/linear_discriminant_analysis/README.md), [workload](benchmarks/l/linear_discriminant_analysis/workload.json), [oracle](benchmarks/linear_discriminant_analysis_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/linear_discriminant_analysis.py).

## Pukall Cipher 1 (`trimaran_enc_pc1`)

The pinned Trimaran source implements Pukall Cipher 1 with a 16-bit state recurrence, a 32-byte evolving key, and a deterministic LCG byte stream. The bounded `i64_array_scalar` contract processes at most 2,048 bytes and preserves the source's plaintext-feedback ordering; its result reconstructs the source's final `d/e` pair. All nine ports and array-scalar runner/verifier integration are in place, with Alexander Pukall's requested attribution. See the [guide](benchmarks/t/trimaran_enc_pc1/README.md), [workload](benchmarks/t/trimaran_enc_pc1/workload.json), [oracle](benchmarks/trimaran_enc_pc1_oracle.py), and pinned [source](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/enc-pc1/pc1cod.c).

## McCat hierarchical 3D transforms (`mccat_08_main`)

The bounded McCat 08-main contract applies the source child and parent transforms in order, deduplicates first-seen points, sweeps the parent y-rotation by frame, and returns a weighted checksum of rounded coordinates. Nine language ports and scalar runner/verifier integration are in place. See the [guide](benchmarks/m/mccat_08_main/README.md), [workload](benchmarks/m/mccat_08_main/workload.json), and [oracle](benchmarks/mccat_08_main_oracle.py).

## McCat hull-contraction circle (`mccat_09_vor`)

McCat 09-vor contracts convex-hull vertices by the source's local circumradius priority and returns the final three-site circle. This core is distinct from the local Fortune sweep, quad-edge divide-and-conquer, and Bowyer-Watson triangulation algorithms. Nine language ports and scalar runner/verifier integration are in place. See the [guide](benchmarks/m/mccat_09_vor/README.md), [workload](benchmarks/m/mccat_09_vor/workload.json), and [oracle](benchmarks/mccat_09_vor_oracle.py).

## Espresso bounded minimization phases (`mallocbench_espresso`)

This profile preserves the Espresso source EXPAND and IRREDUNDANT phases for small single-output binary functions. It does not claim to reproduce the full multi-output PLA optimizer or its later phases. Nine language ports and scalar runner/verifier integration are in place. See the [guide](benchmarks/m/mallocbench_espresso/README.md), [workload](benchmarks/m/mallocbench_espresso/workload.json), and [oracle](benchmarks/mallocbench_espresso_oracle.py).

## Multiword anagram decomposition (`ptrdist_anagram`)

The Ptrdist program counts phrase decompositions into a supplied word list using a rarest-letter DFS pivot, packed frequency checks, and deferred non-pivot candidates. This differs from local single-word anagram checks and dictionary lookups. Nine language ports and scalar runner/verifier integration preserve Raymond Chen's redistribution notice and identify alterations. See the [guide](benchmarks/p/ptrdist_anagram/README.md), [workload](benchmarks/p/ptrdist_anagram/workload.json), and [oracle](benchmarks/ptrdist_anagram_oracle.py).

## Ptrdist SIM first-best local affine alignment (`ptrdist_sim_local_affine_alignment`)

This bounded profile follows SIM's initial full-matrix affine local-alignment scoring pass with its default integer-tenths substitution and gap scores. It returns the first-best score and excludes the launcher's iterative search for eight nonintersecting alignments, traceback, and file output. Nine clean-room ports retain source attribution and explicitly note that the pinned source has no redistribution grant. The scalar runner and verifier check the bounded recurrence against the independent dynamic-programming oracle. See the [guide](benchmarks/p/ptrdist_sim_local_affine_alignment/README.md), [workload](benchmarks/p/ptrdist_sim_local_affine_alignment/workload.json), and [oracle](benchmarks/ptrdist_sim_local_affine_alignment_oracle.py).

## Stanford Puzzle 3D packing search (`stanford_puzzle`)

The pinned puzzle fills a 5×5×5 box with fixed polycube orientations using first-empty-cell recursive backtracking. The bounded profile preserves the source order, piece-class availability, source index for the first hole, and the 2,005 recursive-call observation while allowing 1–100 passes. Nine language ports and scalar runner/verifier integration are in place; the pinned source has no explicit redistribution grant. See the [guide](benchmarks/p/stanford_puzzle/README.md), [workload](benchmarks/p/stanford_puzzle/workload.json), and [oracle](benchmarks/stanford_puzzle_oracle.py).

## MallocBench continued-fraction factorization (`mallocbench_cfrac`)

The bounded profile preserves CFRAC convergents, smooth-relation collection, GF(2) dependency search, and gcd factor extraction with multiplier fixed at 1. It rejects factor-base divisors as a domain precondition and omits partial relations, early aborts, multiplier search, and the restricted arbitrary-precision library. Nine language ports and scalar runner/verifier integration are in place. See the [guide](benchmarks/m/mallocbench_cfrac/README.md), [workload](benchmarks/m/mallocbench_cfrac/workload.json), and [oracle](benchmarks/mallocbench_cfrac_oracle.py).

## Approximate substring matching (`agrep_approx_substring_count`)

The bounded Prolangs-C profile streams a Levenshtein row with a free restart at each text byte, then counts end positions within the requested edit allowance. It supports insertion, deletion, and substitution errors, which distinguishes it from exact Bitap and whole-string edit distance. Nine independent language ports and scalar runner/verifier integration are in place; the pinned upstream source grants no redistribution license. See the [guide](benchmarks/a/agrep_approx_substring_count/README.md), [workload](benchmarks/a/agrep_approx_substring_count/workload.json), and [oracle](benchmarks/agrep_approx_substring_count_oracle.py).

## NPB serial data cube (`npb_serial_dc`)

The bounded NPB-serial `dc` profile groups and sums rows for every nonempty subset of up to five attributes, orders each view’s projected keys lexicographically, and checksums the results. It preserves the data-cube aggregation core while omitting external parameter files and generated data. Nine language ports and scalar runner/verifier integration retain the NAS Parallel Benchmarks 3.3 permission, attribution request, and warranty notice. See the [guide](benchmarks/n/npb_serial_dc/README.md), [workload](benchmarks/n/npb_serial_dc/workload.json), and [oracle](benchmarks/npb_serial_dc_oracle.py).

## DOE PathFinder ordered-label search (`doe_pathfinder_signature_search`)

The bounded graph contract checks whether a directed path can consume a requested node-label sequence in order. It preserves the source DFS’s optional label consumption and resets cycle state after each signature transition; this differs from ordinary shortest-path and path-existence algorithms. Nine language ports use an independent state-space BFS oracle, and the README records the Sandia attribution, U.S. Government rights, and LGPL terms selected by the source headers. See the [guide](benchmarks/d/doe_pathfinder_signature_search/README.md), [workload](benchmarks/d/doe_pathfinder_signature_search/workload.json), and [oracle](benchmarks/doe_pathfinder_signature_search_oracle.py).

## Kernighan–Lin netlist bisection (`ptrdist_ks`)

The Ptrdist `ks` profile uses the default unweighted Kernighan–Lin branch to divide an even set of modules into two balanced groups. It chooses opposite-side pairs by gain, then commits the best positive cumulative prefix of each paired-swap pass. This is distinct from subset-sum partition decisions. Nine clean-room ports and an independent recounting oracle are included; the pinned source has no explicit redistribution grant. See the [guide](benchmarks/p/ptrdist_ks/README.md), [workload](benchmarks/p/ptrdist_ks/workload.json), and [oracle](benchmarks/ptrdist_ks_oracle.py).

## Ptrdist YACR2 Maze1 dogleg choice (`ptrdist_yacr2_maze1_dogleg`)

This package isolates the source-ordered upper/lower, left/right dogleg choice for one YACR2 maze-routing column. It preserves inclusive segment-clear checks and the `-DTODD` branch order, with a bounded logical occupancy plane. It is one routing decision from the larger channel router. Nine clean-room ports and scalar suite integration are present; no explicit upstream redistribution grant was found. See the [guide](benchmarks/p/ptrdist_yacr2_maze1_dogleg/README.md), [workload](benchmarks/p/ptrdist_yacr2_maze1_dogleg/workload.json), and [oracle](benchmarks/ptrdist_yacr2_maze1_dogleg_oracle.py).

## Prolangs-C two-pass assembler (`prolangs_c_assembler`)

This bounded SIC/XE assembler preserves pass-one location and symbol assignment, pass-two forward-reference resolution, format-2 register encoding, format-3 addressing, `WORD` emission, and the source permission notice. It replaces source-line parsing and files with numeric records and a deterministic object-code checksum. Nine language ports and an independent oracle are included. See the [guide](benchmarks/p/prolangs_c_assembler/README.md), [workload](benchmarks/p/prolangs_c_assembler/workload.json), and [oracle](benchmarks/prolangs_c_assembler_oracle.py).

## Prolangs-C Bison nullable analysis (`prolangs_c_bison_nullable`)

This bounded grammar-analysis kernel computes the least set of nullable nonterminals using empty-production seeds and queue-based dependency propagation. Numeric production records replace text parsing, and the result is projected to a bit mask. Nine independent ports, a repeated-scan oracle, and scalar runner/verifier integration are included; the pinned Bison General Public License and source attribution are preserved. See the [guide](benchmarks/p/prolangs_c_bison_nullable/README.md), [workload](benchmarks/p/prolangs_c_bison_nullable/workload.json), and [oracle](benchmarks/prolangs_c_bison_nullable_oracle.py).

## Prolangs-C SIC/XE format-3/4 address decode (`prolangs_c_simulator_format3_4`)

This bounded execution-side helper decodes SIC/XE simple, immediate, indexed, base-relative, and PC-relative operand addresses from the instruction flags and registers. It preserves the simulator's SIC fallback and flag-processing order; operand-memory reads and indirect dereferences are outside this profile. Nine ports retain William Landi's permission notice and are registered in the scalar suite. See the [guide](benchmarks/p/prolangs_c_simulator_format3_4/README.md), [workload](benchmarks/p/prolangs_c_simulator_format3_4/workload.json), and [oracle](benchmarks/prolangs_c_simulator_format3_4_oracle.py).

## Prolangs-C SIC/XE arithmetic register shift (`prolangs_c_simulator_shiftr`)

This bounded instruction profile sign-extends a 24-bit register value while shifting right by the format-2 operand's encoded count. Its bit-position oracle preserves the source's repeated sign bit and register nibble validation. Nine ports retain William Landi's permission notice and are registered in the scalar suite. See the [guide](benchmarks/p/prolangs_c_simulator_shiftr/README.md), [workload](benchmarks/p/prolangs_c_simulator_shiftr/workload.json), and [oracle](benchmarks/prolangs_c_simulator_shiftr_oracle.py).

## Prolangs-C GNU Go group liberty count (`prolangs_c_gnugo_liberty_count`)

This bounded 19x19 Go-board kernel traverses the selected same-color group and counts each adjacent empty intersection once. Sparse stone records replace the original game's text and move processing. Nine language ports and scalar runner/verifier integration are included; the ports preserve the pinned source's GNU GPL version 1 grant. See the [guide](benchmarks/p/prolangs_c_gnugo_liberty_count/README.md), [workload](benchmarks/p/prolangs_c_gnugo_liberty_count/workload.json), and [oracle](benchmarks/prolangs_c_gnugo_liberty_count_oracle.py).

## Prolangs-C GNU Go suicide predicate (`prolangs_c_gnugo_suicide`)

This bounded move-decision kernel preserves GNU Go's source behavior after placing a candidate stone, including its rule that rejects suicide and the specified single-stone ko recapture. It counts individual own stones lost by the move and returns the source's accepted/rejected status; it is not a full Go rules engine. Nine language ports and scalar runner/verifier integration preserve the pinned GNU GPL version 1 grant. See the [guide](benchmarks/p/prolangs_c_gnugo_suicide/README.md), [workload](benchmarks/p/prolangs_c_gnugo_suicide/workload.json), and [oracle](benchmarks/prolangs_c_gnugo_suicide_oracle.py).

## TSVC s343 column-major compaction (`tsvc_s343_column_major_compaction`)

This clean-room profile scans separate row-major data and mask matrices by columns and packs each payload whose mask is positive. It preserves duplicates, exact little-endian i64 output, and the source scan order. Nine language ports and byte-output runner/verifier integration cover the bounded kernel; the README records the source reference and that no upstream license grant was found. See the [guide](benchmarks/t/tsvc_s343_column_major_compaction/README.md), [workload](benchmarks/t/tsvc_s343_column_major_compaction/workload.json), and [oracle](benchmarks/tsvc_s343_column_major_compaction_oracle.py).

## TSVC s281 reverse-coupled update (`tsvc_s281_reverse_coupled_update`)

This clean-room profile preserves `s281`'s ascending in-place updates while each step reads `A[n-i-1]`; later reads in a pass can therefore observe earlier writes. Bounded integer-valued inputs retain exact binary64 source behavior and emit the final A/B arrays as little-endian signed i64. Nine language ports and byte-output runner/verifier integration are included; the package documents the source attribution and the absence of an explicit upstream license grant. See the [guide](benchmarks/t/tsvc_s281_reverse_coupled_update/README.md), [workload](benchmarks/t/tsvc_s281_reverse_coupled_update/workload.json), and [oracle](benchmarks/tsvc_s281_reverse_coupled_update_oracle.py).

## SciMark2 SOR grid relaxation (`scimark2_sor`)

This package preserves the SciMark2-C in-place five-point stencil with fixed `omega=1.25`, row-major update order, and a fixed-point projection. That non-unit over-relaxation and 2D grid contract distinguishes it from the local `omega=1` Gauss-Seidel solver. Nine clean-room ports and an independent oracle are included; the pinned C subtree contains no explicit redistribution grant. See the [guide](benchmarks/s/scimark2_sor/README.md), [workload](benchmarks/s/scimark2_sor/workload.json), and [oracle](benchmarks/scimark2_sor_oracle.py).

## MediaBench G.721 u-law encoder (`mediabench_g721_encode`)

The bounded MediaBench profile encodes up to 16 u-law samples with the G.721 adaptive predictor and scale updates, resetting its state per call and packing the first code in the low nibble. It is distinct from the IMA/DVI `lac_adpcm` recurrence. Nine language ports retain the required Sun Microsystems notice, and the byte-output runner and verifier include workload and generated boundary cases. See the [guide](benchmarks/g/mediabench_g721_encode/README.md), [workload](benchmarks/g/mediabench_g721_encode/workload.json), and [oracle](benchmarks/mediabench_g721_encode_oracle.py).

## DOE RSBench Doppler microscopic lookup (`doe_rsbench_doppler_xs`)

This bounded profile isolates one source-order microscopic cross-section lookup with Doppler broadening, including the Abrarov approximation and the QUICK_W asymptotic branch. Fixed-point fixtures replace launcher-scale random initialization, material selection, threading, and I/O. Nine language ports retain the MIT notice; the float64 runner and verifier compare with absolute tolerance `1e-9` and relative tolerance `1e-12`. See the [guide](benchmarks/r/doe_rsbench_doppler_xs/README.md), [workload](benchmarks/r/doe_rsbench_doppler_xs/workload.json), and [oracle](benchmarks/doe_rsbench_doppler_xs_oracle.py).

## DOE SimpleMOC quadratic-source attenuation (`doe_simplemoc_quadratic_attenuation`)

This bounded profile isolates one default SimpleMOC quadratic-source segment update, including the pinned 353-interval exponential lookup, flux integral, fine-region tally, and outgoing angular flux. Nine language ports preserve binary32 expression order and the MIT notice; the float64 runner and verifier compare a checksum that observes both updated outputs. It is distinct from RSBench's Doppler-broadened cross-section lookup. See the [guide](benchmarks/d/doe_simplemoc_quadratic_attenuation/README.md), [workload](benchmarks/d/doe_simplemoc_quadratic_attenuation/workload.json), and [oracle](benchmarks/doe_simplemoc_quadratic_attenuation_oracle.py).

## DOE XSBench unionized-grid macroscopic cross-section lookup (`doe_xsbench_unionized_macro_xs`)

This bounded profile searches a prepared unionized energy grid, follows its per-nuclide pointer row, interpolates five microscopic cross-section channels, and accumulates the selected material in source order. It captures XSBench's macroscopic lookup path and is distinct from RSBench's Doppler-broadened microscopic lookup. Nine language ports retain the Argonne MIT notice; the float64 runner and verifier cover the bounded table layout and endpoint rules. See the [guide](benchmarks/x/doe_xsbench_unionized_macro_xs/README.md), [workload](benchmarks/x/doe_xsbench_unionized_macro_xs/workload.json), and [oracle](benchmarks/doe_xsbench_unionized_macro_xs_oracle.py).

## DOE miniGMG cell-centered restriction (`doe_minigmg_restriction`)

This bounded multigrid kernel averages each nonoverlapping 2×2×2 fine-grid block in source order and projects the coarse grid to a position-weighted squared checksum. Fractional means are preserved, so it measures the restriction arithmetic rather than integer-only downsampling. Nine ports retain miniGMG's BSD-style notice; the float64 runner and verifier cover the maximum 8×8×8 grid, fractional cases, malformed dimensions and cell bounds. See the [guide](benchmarks/d/doe_minigmg_restriction/README.md), [workload](benchmarks/d/doe_minigmg_restriction/workload.json), and [oracle](benchmarks/doe_minigmg_restriction_oracle.py).

## Prolangs-C football tie-breaks (`prolangs_football_tiebreaks`)

The bounded contract orders an unresolved record group by conference and team ID, compares exact winning fractions, then applies the source's H2H, division, and conference criteria, restarting at H2H after every strict subgroup split. Fixtures cover both initial ordering and recursive criterion restart. Nine language ports and an independent oracle are included. See the [guide](benchmarks/p/prolangs_football_tiebreaks/README.md), [workload](benchmarks/p/prolangs_football_tiebreaks/workload.json), and [oracle](benchmarks/prolangs_football_tiebreaks_oracle.py).

## Prolangs-C cdecl declarator parser (`prolangs_c_cdecl`)

This clean-room profile parses bounded ANSI-C declarations and serializes their base type, identifier, and pointer/array/function operators in identifier-outward order. The encoding preserves the distinction between arrays of pointers and pointers to arrays. The recursive-descent parser and workload exercise declarator binding and function-parameter forms; command processing, casts, qualifiers, and interactive I/O are excluded. No explicit upstream license grant was found, and no upstream parser text or comments are copied. Nine language ports and byte-output runner/verifier integration are included. See the [guide](benchmarks/p/prolangs_c_cdecl/README.md), [workload](benchmarks/p/prolangs_c_cdecl/workload.json), and [oracle](benchmarks/prolangs_c_cdecl_oracle.py).

## Prolangs-C SIC/XE loader relocation field addition (`prolangs_c_loader_relocation_add`)

This bounded helper adds a relocation delta to a fixed-width big-endian SIC/XE field, including the source's odd half-byte width rounding and low-field truncation on carry overflow. It is distinct from general radix conversion. Nine ports preserve William Landi's permission notice, and byte-output suite integration covers malformed input and capacity handling. See the [guide](benchmarks/p/prolangs_c_loader_relocation_add/README.md), [workload](benchmarks/p/prolangs_c_loader_relocation_add/workload.json), and [oracle](benchmarks/prolangs_c_loader_relocation_add_oracle.py).

## Prolangs-C numeric token conversion (`prolangs_c_numeric_token`)

This package isolates `lexer.c::Number`, including its integer, decimal fraction, exponent, and binary32 conversion behavior. It extracts one scanner helper from the full compiler; it does not model the complete compiler pipeline. Nine clean-room ports and byte-output suite integration are present, and the pinned directory provides no explicit license grant. See the [guide](benchmarks/p/prolangs_c_numeric_token/README.md), [workload](benchmarks/p/prolangs_c_numeric_token/workload.json), and [oracle](benchmarks/prolangs_c_numeric_token_oracle.py).

## cBench TIFF Floyd–Steinberg dithering (`cbench_tiffdither`)

This bounded grayscale image kernel applies source-order Floyd–Steinberg error diffusion, strict thresholding, and MSB-first packed output. It is distinct from the local Burkes dithering algorithm, which uses a different image representation and diffusion weights. Nine ports retain the Sam Leffler and Silicon Graphics permission notice; the byte-output runner and verifier cover signed division, row handling, packing, and capacity errors. See the [guide](benchmarks/c/cbench_tiffdither/README.md), [workload](benchmarks/c/cbench_tiffdither/workload.json), and [oracle](benchmarks/cbench_tiffdither_oracle.py).

## cBench TIFF median-cut palette construction (`cbench_consumer_tiffmedian`)

This bounded RGB quantization kernel forms a 5-bit-per-channel histogram, repeatedly splits the eligible box with greatest population along its longest range, shrinks both children, and emits palette midpoint colors in source box-list order. It is distinct from TIFF dithering and from image filters that do not construct a palette. Nine clean-room ports retain source provenance without claiming an upstream license grant; the byte-output runner and verifier cover the bounded RGB domain and palette capacity. See the [guide](benchmarks/c/cbench_consumer_tiffmedian/README.md), [workload](benchmarks/c/cbench_consumer_tiffmedian/workload.json), and [oracle](benchmarks/cbench_consumer_tiffmedian_oracle.py).

## cBench TIFF RGB-to-gray transform (`cbench_consumer_tiff2bw`)

This bounded pixel kernel converts each interleaved 8-bit RGB triplet with the source's fixed-point weights and emits one grayscale byte in input order. It is distinct from dithering and palette construction. Nine ports retain the full Sam Leffler and Silicon Graphics permission notice; the byte-output runner and verifier cover coefficient arithmetic, malformed RGB framing, and capacity errors. See the [guide](benchmarks/c/cbench_consumer_tiff2bw/README.md), [workload](benchmarks/c/cbench_consumer_tiff2bw/workload.json), and [oracle](benchmarks/cbench_consumer_tiff2bw_oracle.py).

## cBench bzip2 MTF and zero-run coding (`cbench_bzip2_mtf_rle`)

This bounded package isolates the bzip2 move-to-front stage and its RUNA/RUNB zero-run coding. Mode 0 maps an already sorted BWT last column to MTF/RUNA/RUNB/EOB bytes; mode 1 expands those tokens and inverse-MTFs the BWT column. It excludes the full BWT/Huffman codec, so it does not duplicate `pcompress2`. Nine ports retain bzip2/libbzip2 1.0.4's full Julian Seward notice. The byte-output runner and verifier cover both directions, the 32-byte block and 33-byte token limits, malformed streams, and output-capacity behavior. See the [guide](benchmarks/c/cbench_bzip2_mtf_rle/README.md), [workload](benchmarks/c/cbench_bzip2_mtf_rle/workload.json), and [oracle](benchmarks/cbench_bzip2_mtf_rle_oracle.py).

## cBench Blowfish CBC (`cbench_blowfish_cbc`)

This profile applies Eric Young's Blowfish CBC chaining to one through four blocks, with encryption and decryption directions and the two fixed source test keys. It is a distinct mode-specific operation from the existing Blowfish ECB package; it does not reproduce the file driver or the neighboring CFB64/OFB64 paths. Nine ports retain the complete Eric Young notice, including the required advertising acknowledgment and the restriction on changing derivative distribution terms. The byte-output runner and verifier cover key selection, IV chaining, malformed frames, and output-capacity errors. See the [guide](benchmarks/c/cbench_blowfish_cbc/README.md), [workload](benchmarks/c/cbench_blowfish_cbc/workload.json), and [oracle](benchmarks/cbench_blowfish_cbc_oracle.py).

## cBench Rijndael AES-256 block decryption (`cbench_security_rijndael_decrypt`)

This package adds the inverse AES-256 block primitive selected by the cBench `_d` launcher. It complements the existing encryption-only MiBench Rijndael port; the cBench CBC chaining, padding, file driver, and repeated dataset wrapper remain outside the bounded profile. Nine ports retain the complete Brian Gladman two-condition redistribution notice. The byte-output runner and verifier cover known-answer vectors, malformed bytes and lengths, null output, and capacity failures. See the [guide](benchmarks/c/cbench_security_rijndael_decrypt/README.md), [workload](benchmarks/c/cbench_security_rijndael_decrypt/workload.json), and [oracle](benchmarks/cbench_security_rijndael_decrypt_oracle.py).

## cBench Pratt–Boyer–Moore helper (`cbench_office_pratt_boyer_moore`)

This bounded string search ports the Public Domain `init_search`/`strsearch` helper from `pbmsrch_large.c`, preserving its endpoint skip table, terminal zero shift, and one-byte advance after a false endpoint match. It remains distinct from the local Horspool search and does not claim textbook full Boyer–Moore behavior. Nine ports, an independent oracle, and strict scalar-suite workload coverage are included. See the [guide](benchmarks/c/cbench_office_pratt_boyer_moore/README.md), [workload](benchmarks/c/cbench_office_pratt_boyer_moore/workload.json), and [oracle](benchmarks/cbench_office_pratt_boyer_moore_oracle.py).

## cBench Ispell word hash (`cbench_ispell_hash`)

This bounded helper uppercases ASCII letters, packs the first four bytes, then rotates the 32-bit state and XORs the remaining bytes before reducing by the caller's table size. It is distinct from cryptographic digest benchmarks such as `string_hash_equality`, which compares Keccak-256 outputs. Nine ports preserve the Ispell source's redistribution notice and use a documented ASCII conversion profile; the dictionary and spellchecker remain outside the package. See the [guide](benchmarks/c/cbench_ispell_hash/README.md), [workload](benchmarks/c/cbench_ispell_hash/workload.json), and [oracle](benchmarks/cbench_ispell_hash_oracle.py).

## cBench Ispell collision-chain lookup (`cbench_ispell_lookup_chain`)

This bounded dictionary lookup hashes a pre-normalized lowercase ASCII query, follows its bucket's linked collision chain, and returns the first exact word match. It exercises `lookup.c::lookup` and its chain traversal; the neighboring [`cbench_ispell_hash`](benchmarks/c/cbench_ispell_hash/README.md) package covers only the hash primitive. The package preserves the source's redistribution notice. See the [guide](benchmarks/i/cbench_ispell_lookup_chain/README.md), [workload](benchmarks/i/cbench_ispell_lookup_chain/workload.json), and [oracle](benchmarks/cbench_ispell_lookup_chain_oracle.py).

## cBench Ghostscript ROP3 truth-table operation (`cbench_ghostscript_rop3`)

This bounded one-pixel Boolean kernel selects one of 256 three-input raster operations using the `(T,S,D)` truth-table index and returns a 32-bit destination word. It excludes Ghostscript's raster traversal and page interpreter. Nine ports preserve the complete Aladdin Free Public License v5; its restrictive noncommercial distribution terms are called out in the guide. The algorithm is registered in the array-scalar suite. See the [guide](benchmarks/g/cbench_ghostscript_rop3/README.md), [workload](benchmarks/g/cbench_ghostscript_rop3/workload.json), and [oracle](benchmarks/ghostscript_rop3_oracle.py).

## cBench Ghostscript ROP3 idempotence predicate (`cbench_ghostscript_rop3_idempotence`)

This bounded scalar operation evaluates Ghostscript's `rop3_is_idempotent` macro for one 8-bit truth table. The package preserves the header macro's exact bit behavior, including its result for code `0xaa`, and distinguishes this predicate from the pixel-producing [`cbench_ghostscript_rop3`](benchmarks/g/cbench_ghostscript_rop3/README.md) operation. Nine ports preserve AFPL v5 and its restrictive noncommercial distribution terms. See the [guide](benchmarks/g/cbench_ghostscript_rop3_idempotence/README.md), [workload](benchmarks/g/cbench_ghostscript_rop3_idempotence/workload.json), and [oracle](benchmarks/ghostscript_rop3_idempotence_oracle.py).

## cBench Ghostscript ROP3 operand-usage mask (`cbench_ghostscript_rop3_operand_usage`)

This helper reports which D, S, and T inputs can affect an 8-bit ROP3 truth table, returning a three-bit usage mask; constant functions return zero. It is distinct from both pixel evaluation and idempotence testing. Nine ports preserve AFPL v5 and its restrictive noncommercial distribution terms. See the [guide](benchmarks/g/cbench_ghostscript_rop3_operand_usage/README.md), [workload](benchmarks/g/cbench_ghostscript_rop3_operand_usage/workload.json), and [oracle](benchmarks/ghostscript_rop3_operand_usage_oracle.py).

## cBench Ghostscript ROP3 truth-table transforms (`cbench_ghostscript_rop3_transform`)

This bounded helper applies one of 15 truth-table remappings from `gsropt.h`, including input inversion, pinning, swapping, conditional use of D, and output inversion. It transforms the operation code rather than evaluating pixels or testing truth-table properties. Nine ports preserve AFPL v5 and its restrictive noncommercial distribution terms. See the [guide](benchmarks/g/cbench_ghostscript_rop3_transform/README.md), [workload](benchmarks/g/cbench_ghostscript_rop3_transform/workload.json), and [oracle](benchmarks/ghostscript_rop3_transform_oracle.py).

## TSVC vbor nested-product kernel (`tsvc_vbor`)

This clean-room scalar profile preserves TSVC's source-shaped four nested products over six arrays and sums each per-index product. Integer-valued inputs in 0..2 keep the source binary64 intermediates exact, allowing all nine ports to use signed i64 arithmetic. The scalar runner and verifier include maximum-bound and malformed-input coverage; the README records source attribution and the absence of an explicit upstream license grant. See the [guide](benchmarks/t/tsvc_vbor/README.md), [workload](benchmarks/t/tsvc_vbor/workload.json), and [oracle](benchmarks/tsvc_vbor_oracle.py).

## Embench-IoT TAR filename search (`tarfind`)

This package scans bounded TAR-header filename fields in archive order and returns the first matching record for each query, with 255 marking misses. It isolates the source benchmark’s linear filename search while leaving archive payloads and unrelated header fields out of scope. Nine ports retain the target source’s MIT notice; the byte-output runner and verifier cover duplicate names, exact case-sensitive matches, misses, maximum bounds, and malformed frames. See the [guide](benchmarks/t/tarfind/README.md), [workload](benchmarks/t/tarfind/workload.json), and [oracle](benchmarks/tarfind_oracle.py).

## Embench-IoT quantized depthwise convolution (`depthconv`)

This package benchmarks the bounded per-channel int8 depthwise convolution profile from TensorFlow Lite Micro’s `DepthwiseConvPerChannel`: four vertical taps, 1–8 channels, input offset 128, per-channel bias and quantization, and signed-int8 activation clamping. It preserves the source rounding shift and byte representation while excluding the original benchmark harness. Nine clean-room ports include Apache-2.0 attribution; the byte-output runner and verifier validate source metadata, workload fixtures, boundary cases, and output capacity. See the [guide](benchmarks/d/depthconv/README.md), [workload](benchmarks/d/depthconv/workload.json), and [oracle](benchmarks/depthconv_oracle.py).

## Embench-IoT QRduino encoder snapshot (`qrduino`)

This bounded profile encodes nonzero ASCII bytes in QR byte mode using version 2-L, including data padding, Reed–Solomon parity, module placement, and mask candidate evaluation. It preserves the Embench verifier’s observable output: the first 22 row-packed bytes from the unmasked frame before format bits are applied, rather than the final QR symbol. Nine clean-room ports retain the pinned GPL-3.0-or-later attribution and are registered in the byte-output suite. See the [guide](benchmarks/q/qrduino/README.md), [workload](benchmarks/q/qrduino/workload.json), and [oracle](benchmarks/qrduino_oracle.py).

## Embench-IoT picojpeg grayscale block decoder (`picojpeg`)

This bounded decoder validates and reconstructs one 8×8 baseline grayscale JPEG block. It covers marker parsing, a restricted canonical Huffman stream, DC and AC coefficient decoding, dequantization, and inverse-DCT pixel output; color, multiple blocks, progressive scans, and the original repeated-image harness are excluded. Nine clean-room ports preserve the Embench GPL attribution and Rich Geldreich’s public-domain origin note. See the [guide](benchmarks/p/picojpeg/README.md), [workload](benchmarks/p/picojpeg/workload.json), and [oracle](benchmarks/picojpeg_oracle.py).

## Embench-IoT Statemate default settlement (`statemate`)

This profile repeats the fixed no-stimulus initialization and statechart settlement path of the generated car-window controller, returning the verifier-visible 64-byte Bitlist, 16 state identifier bytes, and three timer words. It does not implement stimulus-driven branches or a general StateChart runtime. Nine clean-room ports retain the pinned GPL-3.0-or-later attribution and are registered in the byte-output suite. See the [guide](benchmarks/s/statemate/README.md), [workload](benchmarks/s/statemate/workload.json), and [oracle](benchmarks/statemate_oracle.py).

## Embench-IoT slre regex search (`slre`)

This bounded search profile preserves leftmost matching, ordered top-level alternatives, dot matching, optional atoms, and start/end anchors, returning the exclusive match end. It is distinct from the existing whole-string `regex_match` benchmark; groups, character sets, escapes, `*`, and `+` remain outside this profile. Nine ports retain the pinned GPL-3.0-or-later license and upstream credits. See the [guide](benchmarks/s/slre/README.md), [workload](benchmarks/s/slre/workload.json), and [oracle](benchmarks/slre_oracle.py).

## Embench-IoT WikiSort block merge (`wikisort`)

This bounded stable-sort profile uses 16-item insertion runs, a 512-item cache for small merges, and block rotations with lower-bound partitions when the left run exceeds the cache. The 2,048-element maximum reaches the fallback path while keeping caller scratch allocation outside the timed call. Nine ports implement the documented source-shaped profile under the pinned GPL-3.0-or-later attribution. See the [guide](benchmarks/w/wikisort/README.md), [workload](benchmarks/w/wikisort/workload.json), and [oracle](benchmarks/wikisort_oracle.py).

## Embench-IoT bounded boosted-tree inference (`xgboost`)

This bounded inference profile evaluates a fixed six-tree, three-class synthetic model through the source-shaped threshold traversal and vote aggregation, including high-bit leaf IDs and lowest-index tie resolution. The embedded model is explicitly synthetic rather than copied from upstream MNIST data; training and the original test harness are excluded. Nine ports retain the pinned GPL-3.0-or-later notice. The scalar runner and verifier compare the workload's model arrays and fixtures with the independent oracle. See the [guide](benchmarks/x/xgboost/README.md), [workload](benchmarks/x/xgboost/workload.json), and [oracle](benchmarks/xgboost_oracle.py).

## Embench EDN lattice synthesis (`edn_lattice_synthesis`)

This fixed-point profile runs the source-order lattice synthesis recurrence and emits the final accumulator and updated state vector as signed 64-bit words. It preserves arithmetic shifts and short-range bounds, with all nine ports covered by the byte-output suite and the complete GPL and permission notice. See the [guide](benchmarks/e/edn_lattice_synthesis/README.md), [workload](benchmarks/e/edn_lattice_synthesis/workload.json), and [oracle](benchmarks/edn_lattice_synthesis_oracle.py).

## Embench EDN Q15 vector multiply-add (`edn_vec_mpy1`)

This fixed-point kernel updates each `y` value with the arithmetic-shifted Q15 product of the shared scaler and corresponding `x` value. The bounded workload checks negative shifts and signed output encoding across nine ports. See the [guide](benchmarks/e/edn_vec_mpy1/README.md), [workload](benchmarks/e/edn_vec_mpy1/workload.json), and [oracle](benchmarks/edn_vec_mpy1_oracle.py).

## Embench EDN cascaded IIR (`edn_iir_cascade`)

This profile applies ordered second-order Q15 sections, preserving the source's two-stage multiply-accumulate recurrence and per-section state shift. It emits the final sample and all updated section states from the bounded cascade. Nine ports are registered in the byte-output suite. See the [guide](benchmarks/e/edn_iir_cascade/README.md), [workload](benchmarks/e/edn_iir_cascade/workload.json), and [oracle](benchmarks/edn_iir_cascade_oracle.py).

## Embench EDN fixed-point JPEG forward DCT (`edn_jpeg_dct`)

This source-shaped kernel performs the row pass then column pass of a factorized 8×8 forward DCT, preserving signed-16 narrowing and fixed shifts. It is a fixed-point 2D factorization, distinct from the dense 1D MFCC DCT-II and the inverse DCT inside picojpeg. Nine ports are registered in the byte-output suite. See the [guide](benchmarks/e/edn_jpeg_dct/README.md), [workload](benchmarks/e/edn_jpeg_dct/workload.json), and [oracle](benchmarks/edn_jpeg_dct_oracle.py).

## Embench-IoT NSICHNEU Petri/T-Net transitions (`nsichneu`)

This bounded profile executes the generated NSicherNeu place transitions in source order, including the six P1 permutations, 120 P2 permutations, persistent markings across repeated runs, and verifier-sized P3 output. Nine ports preserve the pinned GPL-3.0-or-later attribution and are checked by an independent transition simulator in the byte-output suite. See the [guide](benchmarks/n/nsichneu/README.md), [workload](benchmarks/n/nsichneu/workload.json), and [oracle](benchmarks/nsichneu_oracle.py).

## Rodinia SRAD v2 diffusion update (`rodinia_srad_v2`)

This bounded profile executes the two SRAD v2 diffusion kernels over one 16×16 image block and preserves the pinned binary32 stores, unsuffixed-literal promotion points, and source coefficient-neighbor choices. It excludes random image generation, ROI statistics, and CUDA setup. Nine ports retain the complete BSD-3-Clause source notice; the scalar runner and verifier use the independent fixed-binary32 oracle. See the [guide](benchmarks/r/rodinia_srad_v2/README.md), [workload](benchmarks/r/rodinia_srad_v2/workload.json), and [oracle](benchmarks/rodinia_srad_v2_oracle.py).

## Rodinia Euler3D single-cell flux (`rodinia_euler3d_flux`)

This bounded kernel computes five conservative flux components for one cell across four faces, retaining the source order for real neighbors, wing walls, and far-field boundaries. Binary32 arithmetic and source constants are preserved, with the scalar suite checking a weighted fixed-point projection against an independent oracle. Nine ports include the full BSD-3-Clause source notice. See the [guide](benchmarks/r/rodinia_euler3d_flux/README.md), [workload](benchmarks/r/rodinia_euler3d_flux/workload.json), and [oracle](benchmarks/rodinia_euler3d_flux_oracle.py).

## Rodinia naive particle-filter transition (`rodinia_particlefilter_naive`)

This deterministic transition covers bounded motion prediction, observation likelihood weighting, centroid estimation, and source-order systematic resampling. It takes supplied normal draws, sample intensities, and resampling offset, excluding random video generation and CUDA setup. Nine ports retain the complete BSD-3-Clause notice and are wired to the scalar oracle suite. See the [guide](benchmarks/r/rodinia_particlefilter_naive/README.md), [workload](benchmarks/r/rodinia_particlefilter_naive/workload.json), and [oracle](benchmarks/rodinia_particlefilter_naive_oracle.py).

## Rodinia LavaMD screened particle interactions (`rodinia_lavamd`)

This bounded profile accumulates screened potential and force components for each supplied home particle against particles in the home box and one neighboring box, retaining the source arithmetic and iteration order. It replaces the launcher's 10-by-10-by-10 box workload with explicit boxes containing one to four particles. Nine ports preserve the complete University of Virginia three-condition BSD-style notice and are registered in the i64-array scalar suite. See the [guide](benchmarks/l/rodinia_lavamd/README.md), [workload](benchmarks/l/rodinia_lavamd/workload.json), and [oracle](benchmarks/rodinia_lavamd_oracle.py).

## Rodinia Myocyte CaM RHS (`rodinia_myocyte_cam_rhs`)

This bounded profile evaluates Rodinia Myocyte's `kernel_cam` state derivatives and calcium-buffer communication term in source order, returning their weighted checksum. It retains the complete University of Virginia BSD-3-Clause notice and is registered in the float64 suite. See the [guide](benchmarks/m/rodinia_myocyte_cam_rhs/README.md), [workload](benchmarks/m/rodinia_myocyte_cam_rhs/workload.json), and [oracle](benchmarks/rodinia_myocyte_cam_rhs_oracle.py).

## Rodinia Leukocyte GICOV ellipse score (`rodinia_leukocyte_gicov`)

This profile computes the source-order GICOV score for seven already projected directional-gradient rows, preserving binary32 summation and Welford sample-variance updates before taking the maximum. Image-gradient loads, ellipse-coordinate generation, dilation, and tracking are outside the kernel profile. Nine ports retain the full University of Virginia BSD-3-Clause notice and are registered in the float64 suite. See the [guide](benchmarks/r/rodinia_leukocyte_gicov/README.md), [workload](benchmarks/r/rodinia_leukocyte_gicov/workload.json), and [oracle](benchmarks/rodinia_leukocyte_gicov_oracle.py).

## Rodinia Heartwall normalized template match (`rodinia_heartwall_template_match`)

This bounded profile computes binary32 normalized correlation between an explicit template and image patches, then selects the first candidate with the greatest absolute score in column-major order. It differs from Leukocyte's GICOV ellipse score and unnormalized local convolution/correlation kernels. The direct patch accumulation order can round differently from Rodinia's integral-prefix reductions. Nine clean-room ports retain Rodinia's full University of Virginia BSD-3-Clause notice and are registered in the byte-output suite with independent scoring models. See the [guide](benchmarks/r/rodinia_heartwall_template_match/README.md), [workload](benchmarks/r/rodinia_heartwall_template_match/workload.json), and [oracle](benchmarks/rodinia_heartwall_template_match_oracle.py).

## Rodinia Streamcluster facility opening (`rodinia_streamcluster_pgain`)

This bounded profile performs one source-ordered `pgain` facility-opening decision, including center closures, point reassignment, and the objective checksum. It retains the Princeton and University of Virginia notices and is registered in the byte-output suite. See the [guide](benchmarks/s/rodinia_streamcluster_pgain/README.md), [workload](benchmarks/s/rodinia_streamcluster_pgain/workload.json), and [oracle](benchmarks/rodinia_streamcluster_pgain_oracle.py).

## Rodinia Pathfinder minimum-cost grid path (`rodinia_pathfinder`)

This bounded dynamic program accumulates cell costs row by row and returns the least cost in the final frontier, with same-column and neighboring-column transitions. The input grid is explicit and deterministic, while the source's pyramid-height chunk parameter remains part of the call contract. Nine ports retain Rodinia's BSD notice and are registered in the i64-array scalar suite. See the [guide](benchmarks/r/rodinia_pathfinder/README.md), [workload](benchmarks/r/rodinia_pathfinder/workload.json), and [oracle](benchmarks/rodinia_pathfinder_oracle.py).

## MiBench LAME long-block MDCT (`mibench_lame_mdct_long`)

This package isolates LAME's 18-sample long-block MDCT helper over already-windowed values and returns the 18 source-ordered coefficients. It excludes the MP3 filterbank and file/bitstream pipeline, retains the LGPL-2.0-or-later source notice, and registers the nine ports in the float64-slice suite. See the [guide](benchmarks/m/mibench_lame_mdct_long/README.md), [workload](benchmarks/m/mibench_lame_mdct_long/workload.json), and [oracle](benchmarks/mibench_lame_mdct_long_oracle.py).

## cBench consumer_mad inverse MDCT36 (`cbench_consumer_mad_imdct36`)

This package isolates libmad's 18-coefficient to 36-sample long-block inverse MDCT as a bounded binary64 cosine transform. It records that the profile is mathematically equivalent to the default fixed-point helper, without claiming bit-for-bit Q28 behavior; parsing, windowing, overlap-add, and polyphase synthesis remain outside the contract. Nine ports retain the GPL-2.0-or-later notice and are registered in the float64-slice suite. See the [guide](benchmarks/m/cbench_consumer_mad_imdct36/README.md), [workload](benchmarks/m/cbench_consumer_mad_imdct36/workload.json), and [oracle](benchmarks/cbench_consumer_mad_imdct36_oracle.py).

## cBench consumer_mad Layer III alias reduction (`cbench_consumer_mad_alias_reduce`)

This bounded libmad stage applies the pinned eight-pair alias-reduction butterfly at one to four adjacent subband boundaries. It preserves `FPM_DEFAULT`'s pre-rounded signed Q28 multiply and emits little-endian i32 outputs. Nine ports retain the GPL-2.0-or-later terms and are registered in the byte-output suite; the existing IMDCT profile covers a separate decoder stage. See the [guide](benchmarks/m/cbench_consumer_mad_alias_reduce/README.md), [workload](benchmarks/m/cbench_consumer_mad_alias_reduce/workload.json), and [oracle](benchmarks/cbench_consumer_mad_alias_reduce_oracle.py).

## cBench LAME stereo mid-side transform (`cbench_lame_mid_side`)

This package isolates LAME's per-spectral-pair left/right to mid/side transform from the conditional `convert_mdct` path. Its profile preserves the source pair-sum/pair-difference operation order and excludes granule assembly, MDCT, quantization, psychoacoustics, and bitstream writing. Nine ports retain the GPL-2.0-or-later notice and are registered in the float64-slice suite. See the [guide](benchmarks/m/cbench_lame_mid_side/README.md), [workload](benchmarks/m/cbench_lame_mid_side/workload.json), and [oracle](benchmarks/cbench_lame_mid_side_oracle.py).

## cBench LAME short-block MDCT (`cbench_consumer_lame_mdct_short`)

This package isolates `newmdct.c::mdct_short`, the three-window 6-point transform that places 18 output coefficients side by side. It recomputes the short-window coefficient table per call and keeps the source-ordered binary64 products and sums. Nine ports retain the LGPL-2.0-or-later notice and are registered in the float64-slice suite; the existing LAME MDCT profile covers the separate long-block transform. See the [guide](benchmarks/m/cbench_consumer_lame_mdct_short/README.md), [workload](benchmarks/m/cbench_consumer_lame_mdct_short/workload.json), and [oracle](benchmarks/cbench_consumer_lame_mdct_short_oracle.py).

## cBench LAME analysis window subband filterbank (`cbench_consumer_lame_window_subband`)

This package isolates `newmdct.c::window_subband`: it normalizes the pinned `enwindow` table, builds the source 16×31 cosine table, applies the 511-sample analysis window in source order, and returns all 32 bands as little-endian Q1000 integers. The bounded workload carries the exact source coefficient literals as scaled integers and uses a zero-sample fixture with hand-derived output. Nine ports retain the LGPL-2.0-or-later notice and are registered in the i64-array byte-output suite. See the [guide](benchmarks/m/cbench_consumer_lame_window_subband/README.md), [workload](benchmarks/m/cbench_consumer_lame_window_subband/workload.json), and [oracle](benchmarks/cbench_consumer_lame_window_subband_oracle.py).

## cBench RSynth natural glottal-source sample (`cbench_rsynth_natural_glottal_sample`)

This package returns one selected sample from RSynth's natural glottal-source recurrence with the pinned C binary32 rounding boundaries. It models one isolated pitch period and excludes the impulsive source, resonator, formant filters, dictionaries, speech input, and the text-to-speech pipeline. Nine ports use the cBench source's CMU public-domain designation while excluding its separately restricted dictionary data; the rights scope is retained in the package. See the [guide](benchmarks/m/cbench_rsynth_natural_glottal/README.md), [workload](benchmarks/m/cbench_rsynth_natural_glottal/workload.json), and [oracle](benchmarks/cbench_rsynth_natural_glottal_oracle.py).

## cBench RSynth impulsive glottal-source resonator sample (`cbench_rsynth_impulsive_glottal_sample`)

This package returns one selected sample from RSynth's binary32 impulsive doublet after the source's second-order resonator recurrence. It is distinct from the natural-source recurrence and excludes dictionaries, phone lists, speech input, and the full voice pipeline. Nine ports preserve the CMU public-domain notice and the separately restricted dictionary scope. See the [guide](benchmarks/m/cbench_rsynth_impulsive_glottal/README.md), [workload](benchmarks/m/cbench_rsynth_impulsive_glottal/workload.json), and [oracle](benchmarks/cbench_rsynth_impulsive_glottal_oracle.py).

## cBench RSynth three-sine pitch flutter (`cbench_rsynth_f0_flutter`)

This bounded helper adjusts F0 by the source's three-sine pitch perturbation, preserving the integer frequency quotient and truncation toward zero. It excludes synthesis state and all dictionary or speech data; nine clean-room ports retain RSynth's CMU public-domain notice and the separate dictionary restriction. See the [guide](benchmarks/m/cbench_rsynth_f0_flutter/README.md), [workload](benchmarks/m/cbench_rsynth_f0_flutter/workload.json), and [oracle](benchmarks/cbench_rsynth_f0_flutter_oracle.py).

## MediaBench GSM RPE grid selection (`mediabench_gsm_rpe_grid_selection`)

This bounded GSM kernel compares the four 3-spaced phases of a 40-sample residual, preserves arithmetic-shift energy calculation and lowest-grid tie selection, then emits the selected 13 samples. It retains the upstream copyright notice and registers in the byte-output suite. See the [guide](benchmarks/m/mediabench_gsm_rpe_grid_selection/README.md), [workload](benchmarks/m/mediabench_gsm_rpe_grid_selection/workload.json), and [oracle](benchmarks/mediabench_gsm_rpe_grid_selection_oracle.py).

## MediaBench GSM RPE grid positioning (`mediabench_gsm_rpe_grid_positioning`)

This bounded GSM kernel scatters 13 signed samples into one of four 40-sample residual grids at indices `grid + 3*i`, leaving other positions zero. It retains the upstream copyright notice and registers in the byte-output suite; the complete encoder and toast file wrapper remain outside the profile. See the [guide](benchmarks/m/mediabench_gsm_rpe_grid_positioning/README.md), [workload](benchmarks/m/mediabench_gsm_rpe_grid_positioning/workload.json), and [oracle](benchmarks/mediabench_gsm_rpe_grid_positioning_oracle.py).

## Rodinia HybridSort bounded histogram merge (`rodinia_hybridsort`)

This package preserves HybridSort's histogram partition and per-bucket merge-sort structure over explicit bounded inputs. It fixes uniform bins over the input range instead of Rodinia's adaptive quantile pivots, retains the Rodinia license and NVIDIA histogram notice, and is registered in the byte-output suite. See the [guide](benchmarks/r/rodinia_hybridsort/README.md), [workload](benchmarks/r/rodinia_hybridsort/workload.json), and [oracle](benchmarks/rodinia_hybridsort_oracle.py).

## Rodinia B+ tree point search (`rodinia_bplus_tree`)

The bounded profile routes queries through a single internal separator to one of two sorted leaf ranges and scores found records in source order. It preserves the separator-equality route, cites the pinned Rodinia source, retains its redistribution notice, and registers the nine ports in the scalar suite. See the [guide](benchmarks/b/rodinia_bplus_tree/README.md), [workload](benchmarks/b/rodinia_bplus_tree/workload.json), and [oracle](benchmarks/rodinia_bplus_tree_oracle.py).

## Rodinia MUMmerGPU maximal exact matches (`rodinia_mummergpu`)

This bounded DNA query reports all left- and right-maximal exact matches for one reference/query pair, preserving one-based coordinates and suffix-tree traversal order. It retains the subtree's full Artistic License text and is registered in the byte-output suite. See the [guide](benchmarks/m/rodinia_mummergpu/README.md), [workload](benchmarks/m/rodinia_mummergpu/workload.json), and [oracle](benchmarks/rodinia_mummergpu_oracle.py).

## TSVC indexed gather and scatter updates (`tsvc_indexed_gather_scatter`)

This package covers TSVC s491 scatter and s4113 gather-plus-scatter, preserving ascending loop order and last-write-wins behavior for repeated indices. The clean-room ports retain source attribution and explicitly make no upstream license claim; the byte-output suite checks packed i64 destinations and capacity boundaries. See the [guide](benchmarks/t/tsvc_indexed_gather_scatter/README.md), [workload](benchmarks/t/tsvc_indexed_gather_scatter/workload.json), and [oracle](benchmarks/tsvc_indexed_gather_scatter_oracle.py).

## TSVC s141 packed symmetric update (`tsvc_s141_packed_symmetric_update`)

This bounded kernel accumulates the lower triangle of a row-major matrix into packed symmetric storage, with an explicit repeated-round count. It is distinct from dense symmetric matrix multiplication and indexed gather/scatter; the clean-room ports document the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s141_packed_symmetric_update/README.md), [workload](benchmarks/t/tsvc_s141_packed_symmetric_update/workload.json), and [oracle](benchmarks/tsvc_s141_packed_symmetric_update_oracle.py).

## TSVC s131 forward-neighbor update (`tsvc_s131_forward_neighbor_update`)

This clean-room recurrence updates each array element from its right neighbor in ascending order for a bounded number of passes, preserving the source's within-pass read behavior and leaving the final element unchanged. The byte-output suite checks the packed i64 vector and boundary conditions; the README records s151 as a duplicate helper-based form and notes the missing upstream license grant. See the [guide](benchmarks/t/tsvc_s131_forward_neighbor_update/README.md), [workload](benchmarks/t/tsvc_s131_forward_neighbor_update/workload.json), and [oracle](benchmarks/tsvc_s131_forward_neighbor_update_oracle.py).

## TSVC s132 shifted-row update (`tsvc_s132_shifted_row_update`)

This bounded cross-row kernel updates target elements from the preceding element of another row plus a scaled vector, leaving target element zero unchanged. The clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s132_shifted_row_update/README.md), [workload](benchmarks/t/tsvc_s132_shifted_row_update/workload.json), and [oracle](benchmarks/tsvc_s132_shifted_row_update_oracle.py).

## TSVC s152 three-factor accumulation (`tsvc_s152_three_factor_accumulate`)

This bounded kernel multiplies three input factors and accumulates the result into an output vector over repeated passes, preserving per-element update order. The clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s152_three_factor_accumulate/README.md), [workload](benchmarks/t/tsvc_s152_three_factor_accumulate/workload.json), and [oracle](benchmarks/tsvc_s152_three_factor_accumulate_oracle.py).

## TSVC s161 mutually exclusive updates (`tsvc_s161_mutually_exclusive_updates`)

This bounded control-flow kernel updates either A at index i or C at i+1 according to B, preserving the ascending loop's dependency between successive indices. The clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s161_mutually_exclusive_updates/README.md), [workload](benchmarks/t/tsvc_s161_mutually_exclusive_updates/workload.json), and [oracle](benchmarks/tsvc_s161_mutually_exclusive_updates_oracle.py).

## TSVC s162 guarded shifted FMA (`tsvc_s162_guarded_shifted_fma`)

This bounded control-flow kernel preserves the scalar guard: k=0 leaves A unchanged, while k=1 updates A[i] from the next A slot plus B[i]*C[i] for the ascending prefix, leaving the final slot untouched. Its clean-room ports use an integer-exact domain and record that no explicit upstream license grant was found. See the [guide](benchmarks/t/tsvc_s162_guarded_shifted_fma/README.md), [workload](benchmarks/t/tsvc_s162_guarded_shifted_fma/workload.json), and [oracle](benchmarks/tsvc_s162_guarded_shifted_fma_oracle.py).

## TSVC s278 branch recomputation (`tsvc_s278_branch_recompute`)

This bounded control-flow kernel updates B or C based on the current A value, then recomputes A from the resulting state. It preserves the per-element branch and pass order, records the missing upstream license grant, and is registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s278_branch_recompute/README.md), [workload](benchmarks/t/tsvc_s278_branch_recompute/workload.json), and [oracle](benchmarks/tsvc_s278_branch_recompute_oracle.py).

## TSVC s279 nested branch recomputation (`tsvc_s279_nested_branch_recompute`)

This bounded control-flow kernel recomputes C on the positive-A branch; otherwise it updates B and conditionally updates C before the common A recomputation. Its nine clean-room language ports preserve the nested decision and record that no explicit upstream license grant was found. See the [guide](benchmarks/t/tsvc_s279_nested_branch_recompute/README.md), [workload](benchmarks/t/tsvc_s279_nested_branch_recompute/workload.json), and [oracle](benchmarks/tsvc_s279_nested_branch_recompute_oracle.py).

## TSVC s353 unrolled sparse SAXPY (`tsvc_s353_unrolled_sparse_saxpy`)

This bounded loop-rerolling kernel performs source-ordered `A[i] += alpha * B[index[i]]` updates in five-element chunks, preserving repeated gather indices. The clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s353_unrolled_sparse_saxpy/README.md), [workload](benchmarks/t/tsvc_s353_unrolled_sparse_saxpy/workload.json), and [oracle](benchmarks/tsvc_s353_unrolled_sparse_saxpy_oracle.py).

## TSVC s351 direct unrolled SAXPY (`tsvc_s351_direct_unrolled_saxpy`)

This bounded float64-slice profile preserves LoopRerolling s351's five consecutive direct-index `A[i] += alpha*B[i]` updates. The sparse gather in s353 is a distinct access pattern and remains covered by its own package; the dense dot-product s352 maps to s313. Nine clean-room ports record that no explicit TSVC redistribution grant was found. See the [guide](benchmarks/t/tsvc_s351_direct_unrolled_saxpy/README.md), [workload](benchmarks/t/tsvc_s351_direct_unrolled_saxpy/workload.json), and [oracle](benchmarks/tsvc_s351_direct_unrolled_saxpy_oracle.py).

## TSVC s452 index-weighted vector map (`tsvc_s452_index_weighted_vector_map`)

This bounded global-data-flow kernel computes `A[i] = B[i] + C[i] * (i + 1)` across an input vector. The clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s452_index_weighted_vector_map/README.md), [workload](benchmarks/t/tsvc_s452_index_weighted_vector_map/workload.json), and [oracle](benchmarks/tsvc_s452_index_weighted_vector_map_oracle.py).

## TSVC s471 ordered two-vector map (`tsvc_s471_ordered_two_vector_map`)

This bounded GlobalDataFlow profile preserves the source order at each index: `X[i] = B[i] + D[i]*D[i]`, then `B[i] = C[i] + D[i]*E[i]`. It exposes both final vectors, including the X write that the source later checks. The source's helper call is empty. Nine clean-room ports and an independent oracle use the byte-output ABI; the pinned TSVC source has no explicit redistribution grant. See the [guide](benchmarks/t/tsvc_s471_ordered_two_vector_map/README.md), [workload](benchmarks/t/tsvc_s471_ordered_two_vector_map/workload.json), and [oracle](benchmarks/tsvc_s471_ordered_two_vector_map_oracle.py).

## TSVC s126 matrix column recurrence (`tsvc_s126_matrix_column_recurrence`)

This bounded induction-variable kernel updates each matrix column from top to bottom, using the prior row's updated B value and skipping one coefficient after each column. Its clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s126_matrix_column_recurrence/README.md), [workload](benchmarks/t/tsvc_s126_matrix_column_recurrence/workload.json), and [oracle](benchmarks/tsvc_s126_matrix_column_recurrence_oracle.py).

## TSVC s128 strided coupled update (`tsvc_s128_strided_coupled_update`)

This bounded induction-variable kernel reads and rewrites even-indexed B entries while producing A, leaving odd B entries unchanged. Its clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s128_strided_coupled_update/README.md), [workload](benchmarks/t/tsvc_s128_strided_coupled_update/workload.json), and [oracle](benchmarks/tsvc_s128_strided_coupled_update_oracle.py).

## TSVC s127 fixed pair expansion (`tsvc_s127_fixed_pair_expansion`)

This bounded induction-variable kernel emits two ordered values for each input position, preserving the source's fixed 2x expansion. Its clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s127_fixed_pair_expansion/README.md), [workload](benchmarks/t/tsvc_s127_fixed_pair_expansion/workload.json), and [oracle](benchmarks/tsvc_s127_fixed_pair_expansion_oracle.py).

## TSVC s322 second-order recurrence (`tsvc_s322_second_order_recurrence`)

This bounded recurrence updates each A element from the preceding two A values and per-index B/C coefficients, preserving ascending in-place order. Its clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s322_second_order_recurrence/README.md), [workload](benchmarks/t/tsvc_s322_second_order_recurrence/workload.json), and [oracle](benchmarks/tsvc_s322_second_order_recurrence_oracle.py).

## TSVC s321 first-order recurrence (`tsvc_s321_first_order_recurrence`)

This bounded recurrence updates each A element from the already-updated predecessor and a per-index B coefficient, preserving ascending in-place order. Its clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s321_first_order_recurrence/README.md), [workload](benchmarks/t/tsvc_s321_first_order_recurrence/workload.json), and [oracle](benchmarks/tsvc_s321_first_order_recurrence_oracle.py).

## TSVC s323 coupled recurrence (`tsvc_s323_coupled_recurrence`)

This bounded coupled recurrence updates A from the previous B value and then updates B from the new A value, preserving source order. Its clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s323_coupled_recurrence/README.md), [workload](benchmarks/t/tsvc_s323_coupled_recurrence/workload.json), and [oracle](benchmarks/tsvc_s323_coupled_recurrence_oracle.py).

## TSVC s114 transposed lower-triangle update (`tsvc_s114_transposed_lower_triangle_update`)

This bounded matrix kernel overwrites each strict lower-triangle A entry with its transposed upper-triangle value plus the matching B entry, preserving source row and column order. The clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s114_transposed_lower_triangle_update/README.md), [workload](benchmarks/t/tsvc_s114_transposed_lower_triangle_update/workload.json), and [oracle](benchmarks/tsvc_s114_transposed_lower_triangle_update_oracle.py).

## TSVC s211 ordered neighbor rewrite (`tsvc_s211_ordered_neighbor_rewrite`)

This bounded two-array recurrence updates interior A and B elements in ascending order: each A write reads the already-updated left B neighbor, while each B write reads the not-yet-updated right B neighbor. The clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s211_ordered_neighbor_rewrite/README.md), [workload](benchmarks/t/tsvc_s211_ordered_neighbor_rewrite/workload.json), and [oracle](benchmarks/tsvc_s211_ordered_neighbor_rewrite_oracle.py).

## TSVC s115 upper-triangular SAXPY elimination (`tsvc_s115_upper_triangular_saxpy_elimination`)

This bounded codelet updates later A entries in ascending j/i order with `A[i] -= U[j,i] * A[j]`. The carried updated A values make the nested triangular sweep observable; this is an elimination update, not triangular substitution. Nine clean-room ports use small integer bounds that remain exact in both TSVC precision variants. No explicit redistribution grant was found. See the [guide](benchmarks/t/tsvc_s115_upper_triangular_saxpy_elimination/README.md), [workload](benchmarks/t/tsvc_s115_upper_triangular_saxpy_elimination/workload.json), and [oracle](benchmarks/tsvc_s115_upper_triangular_saxpy_elimination_oracle.py).

## TSVC s116 unrolled in-place product chain (`tsvc_s116_unrolled_product_chain`)

This profile preserves s116's five sequential unrolled assignments, including their in-place neighbor dependencies and the unwritten sentinel at each chunk's end. The bounded contract uses lengths `5*blocks+1` and ±1 values so every intermediate is exact in both source precision families. Nine clean-room ports are provided; the TSVC launcher initialization, timing loop, and checker are excluded. No explicit redistribution grant was found. See the [guide](benchmarks/t/tsvc_s116_unrolled_product_chain/README.md), [workload](benchmarks/t/tsvc_s116_unrolled_product_chain/workload.json), and [oracle](benchmarks/tsvc_s116_unrolled_product_chain_oracle.py).

## TSVC s118 triangular convolution recurrence (`tsvc_s118_triangular_convolution_recurrence`)

This profile preserves s118's ascending triangular coefficient recurrence: each `A[i]` accumulates `BB[j,i] * A[i-j-1]` in source order, consuming previously updated A entries. Its bounded contract is distinct from ordinary convolution and keeps intermediates exactly representable in both TSVC precision families. Nine clean-room ports are provided; launcher initialization, repetition/timing, and checker behavior are excluded. No explicit redistribution grant was found. See the [guide](benchmarks/t/tsvc_s118_triangular_convolution_recurrence/README.md), [workload](benchmarks/t/tsvc_s118_triangular_convolution_recurrence/workload.json), and [oracle](benchmarks/tsvc_s118_triangular_convolution_recurrence_oracle.py).

## TSVC s1119 same-column matrix prefix recurrence (`tsvc_s1119_same_column_matrix_prefix`)

This bounded row-major profile applies `A[i,j] = A[i-1,j] + B[i,j]` in ascending row/column order, exposing independent column recurrences across the full matrix. It is distinct from the 1-D s131 neighbor update, s132's shifted single-row update, and s119's diagonal predecessor recurrence. Nine clean-room ports use small values exact in both TSVC precision families. No explicit redistribution grant was found. See the [guide](benchmarks/t/tsvc_s1119_same_column_matrix_prefix/README.md), [workload](benchmarks/t/tsvc_s1119_same_column_matrix_prefix/workload.json), and [oracle](benchmarks/tsvc_s1119_same_column_matrix_prefix_oracle.py).

## TSVC s232 triangular row square recurrence (`tsvc_s232_triangular_row_square_recurrence`)

This profile preserves the lower-triangular loop and its in-place row dependency: `A[j,i] = A[j,i-1]^2 + B[j,i]` for `1<=i<=j<n`. It is a nonlinear triangular recurrence, distinct from the linear row/column scans. A small domain bounds intermediates exactly for both source precision families. Nine clean-room ports are provided; the upstream initializer/timing/checker are excluded and no explicit redistribution grant was found. See the [guide](benchmarks/t/tsvc_s232_triangular_row_square_recurrence/README.md), [workload](benchmarks/t/tsvc_s232_triangular_row_square_recurrence/workload.json), and [oracle](benchmarks/tsvc_s232_triangular_row_square_recurrence_oracle.py).

## TSVC s1213 ordered neighbor array map (`tsvc_s1213_ordered_neighbor_array_map`)

This bounded profile preserves s1213's ascending pair of writes: `A[i]=B[i-1]+C[i]`, then `B[i]=A[i+1]*D[i]`. The updated B value feeds the next A update, while the A lookahead remains from the previous step; both final vectors are returned. Nine clean-room ports use inputs exact in both TSVC precision variants. No explicit redistribution grant was found. See the [guide](benchmarks/t/tsvc_s1213_ordered_neighbor_array_map/README.md), [workload](benchmarks/t/tsvc_s1213_ordered_neighbor_array_map/workload.json), and [oracle](benchmarks/tsvc_s1213_ordered_neighbor_array_map_oracle.py).

## TSVC s233/s2233 paired matrix prefix recurrences (`tsvc_s233_s2233_matrix_prefix`)

This mode-dispatched package preserves the shared same-column A recurrence and both source B variants: s233 uses an ascending horizontal row prefix, while s2233 uses an ascending vertical column prefix. It returns both full matrices in row-major order. Nine clean-room ports use small values exact in both source precision families; initialization, timing, and checker harnesses are excluded. No explicit redistribution grant was found. See the [guide](benchmarks/t/tsvc_s233_s2233_matrix_prefix/README.md), [workload](benchmarks/t/tsvc_s233_s2233_matrix_prefix/workload.json), and [oracle](benchmarks/tsvc_s233_s2233_matrix_prefix_oracle.py).

## TSVC s235 fused vector and matrix recurrence (`tsvc_s235_fused_vector_matrix_recurrence`)

This profile preserves s235's outer column order: update `A[i]` with the vector product, then run the ascending matrix-row recurrence using that updated scalar. It returns both A and the final matrix so the fused dependency is observable. Nine clean-room ports use small exact values; TSVC initialization and timing repetitions are excluded. No explicit redistribution grant was found. See the [guide](benchmarks/t/tsvc_s235_fused_vector_matrix_recurrence/README.md), [workload](benchmarks/t/tsvc_s235_fused_vector_matrix_recurrence/workload.json), and [oracle](benchmarks/tsvc_s235_fused_vector_matrix_recurrence_oracle.py).

## TSVC s1113 feedback-anchor addition (`tsvc_s1113_feedback_anchor_add`)

This profile reads A[n/2] on every ascending iteration and overwrites that same anchor when the loop reaches it, so later outputs observe the updated value. That source-order feedback makes it distinct from s113’s invariant anchor. Nine clean-room ports are registered with bounded exact inputs; no explicit TSVC redistribution grant was found. See the [guide](benchmarks/t/tsvc_s1113_feedback_anchor_add/README.md), [workload](benchmarks/t/tsvc_s1113_feedback_anchor_add/workload.json), and [oracle](benchmarks/tsvc_s1113_feedback_anchor_add_oracle.py).

## TSVC s113 invariant-anchor addition (`tsvc_s113_invariant_anchor_add`)

This profile preserves the fixed A[0] anchor while adding it to B[i] for i>0, leaving A[0] unchanged. It differs from s1113, whose anchor is updated during the ascending pass, and from s293’s pure broadcast. Nine clean-room ports use a bounded exact integer domain; no explicit TSVC redistribution grant was found. See the [guide](benchmarks/t/tsvc_s113_invariant_anchor_add/README.md), [workload](benchmarks/t/tsvc_s113_invariant_anchor_add/workload.json), and [oracle](benchmarks/tsvc_s113_invariant_anchor_add_oracle.py).

## TSVC s1112 reverse constant-offset map (`tsvc_s1112_reverse_constant_offset_map`)

This source profile walks backward through the vector and assigns `A[i] = B[i] + 1`, overwriting every A entry. Its constant-offset operation is distinct from s112’s shifted neighbor addition. Nine clean-room ports have bounded integer inputs; no explicit TSVC redistribution grant was found. See the [guide](benchmarks/t/tsvc_s1112_reverse_constant_offset_map/README.md), [workload](benchmarks/t/tsvc_s1112_reverse_constant_offset_map/workload.json), and [oracle](benchmarks/tsvc_s1112_reverse_constant_offset_map_oracle.py).

## TSVC s1111 stride-two polynomial map (`tsvc_s1111_stride_two_polynomial_map`)

This profile preserves s1111’s left-associated five-term polynomial expression, including the repeated D×B term, while writing only even positions of A. It is distinct from s111’s odd-neighbor update and pointwise FMA kernels. Nine clean-room ports use bounded integer inputs; no explicit TSVC redistribution grant was found. See the [guide](benchmarks/t/tsvc_s1111_stride_two_polynomial_map/README.md), [workload](benchmarks/t/tsvc_s1111_stride_two_polynomial_map/workload.json), and [oracle](benchmarks/tsvc_s1111_stride_two_polynomial_map_oracle.py).

## TSVC s119 diagonal matrix recurrence (`tsvc_s119_diagonal_matrix_recurrence`)

This bounded row-major recurrence writes each interior A cell from its northwest diagonal predecessor plus the matching B value, preserving the top row and left column. The in-place traversal order is explicit and differs from s2111’s left-plus-above wavefront. Nine clean-room ports use a caller-seeded profile because the pinned initializer zeros the source matrices; no explicit TSVC redistribution grant was found. See the [guide](benchmarks/t/tsvc_s119_diagonal_matrix_recurrence/README.md), [workload](benchmarks/t/tsvc_s119_diagonal_matrix_recurrence/workload.json), and [oracle](benchmarks/tsvc_s119_diagonal_matrix_recurrence_oracle.py).

## TSVC s2111 wavefront addition recurrence (`tsvc_s2111_wavefront_add_recurrence`)

This bounded row-major matrix recurrence replaces each interior cell with its already-updated left neighbor plus the value above. The package exposes caller-provided boundary seeds because the pinned launcher initializes the matrix to zero; this profile projection is documented in its guide. Nine clean-room ports record that no explicit upstream license grant was found. See the [guide](benchmarks/t/tsvc_s2111_wavefront_add_recurrence/README.md), [workload](benchmarks/t/tsvc_s2111_wavefront_add_recurrence/workload.json), and [oracle](benchmarks/tsvc_s2111_wavefront_add_recurrence_oracle.py).

## TSVC s212 next-element dependency (`tsvc_s212_next_element_dependency`)

This bounded recurrence scales A at the current index, then accumulates the still-unmodified next A element into B, preserving source statement order over repeated passes. The clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s212_next_element_dependency/README.md), [workload](benchmarks/t/tsvc_s212_next_element_dependency/workload.json), and [oracle](benchmarks/tsvc_s212_next_element_dependency_oracle.py).

## TSVC vif masked assignment (`tsvc_vif_masked_assignment`)

This bounded vector codelet copies B into A only where the source predicate `B[i] > 0` holds, leaving other destination values unchanged. The clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_vif_masked_assignment/README.md), [workload](benchmarks/t/tsvc_vif_masked_assignment/workload.json), and [oracle](benchmarks/tsvc_vif_masked_assignment_oracle.py).

## Embench-IoT Montgomery product (`embench_aha_mont64`)

This bounded scalar kernel returns the reduced Montgomery-domain product `a*b*R^-1 mod m` for odd `m` and fixed radix `R=2^64`. It measures one Montgomery reduction on caller-supplied residues, distinct from ordinary modular multiplication and from the source benchmark’s GCD setup, exponentiation loop, and repeat harness. Nine clean-room ports record the pinned GPL-3.0-or-later provenance without copying source text; the scalar runner and verifier check the bounded contract and fixtures. See the [guide](benchmarks/a/embench_aha_mont64/README.md), [workload](benchmarks/a/embench_aha_mont64/workload.json), and [oracle](benchmarks/embench_aha_mont64_oracle.py).


## TSVC s257 column-coupled matrix update (`tsvc_s257_column_coupled_update`)

This clean-room scalar profile preserves s257's source-order in-place dependency: each matrix-row update overwrites the shared column scalar, which feeds the next row and later column. Bounded integer-valued inputs preserve exact binary64 behavior, and the nine ports use signed i64 arithmetic. The scalar runner and verifier cover the maximum matrix, multiple passes, malformed frames, and null input; the README records source attribution and the absence of an explicit upstream license grant. See the [guide](benchmarks/t/tsvc_s257_column_coupled_update/README.md), [workload](benchmarks/t/tsvc_s257_column_coupled_update/workload.json), and [oracle](benchmarks/tsvc_s257_column_coupled_update_oracle.py).

## TSVC s273 dependent conditional update (`tsvc_s273_dependent_conditional_update`)

This clean-room scalar profile preserves the order-sensitive sequence that updates A, tests that new A value to decide whether to update B, then uses it again to update C. The bounded integer domain keeps the source binary64 operations exact across all nine signed-i64 ports. The scalar runner and verifier cover both branch outcomes, a later-pass branch transition, maximum bounds, malformed frames, and null input; the README records source attribution and the absence of an explicit upstream license grant. See the [guide](benchmarks/t/tsvc_s273_dependent_conditional_update/README.md), [workload](benchmarks/t/tsvc_s273_dependent_conditional_update/workload.json), and [oracle](benchmarks/tsvc_s273_dependent_conditional_update_oracle.py).

## TSVC s331 last-negative scan (`tsvc_s331_last_negative_index`)

This clean-room scalar profile scans the full vector and returns the one-based position of the last negative value, matching s331's `j` update and `temp = j+1` projection. It is distinct from first-match equality search. The bounded integer-valued inputs preserve the predicate in both the double and float `Searching` families; s332's first-above-threshold early-exit codelet remains outside this package. The runner and verifier validate the pinned TSVC metadata, rights note, fixtures, and nine ports, and generate bounded maximum-size and malformed cases. No explicit upstream TSVC license grant was found; the package makes no upstream license claim. See the [guide](benchmarks/t/tsvc_s331_last_negative_index/README.md), [workload](benchmarks/t/tsvc_s331_last_negative_index/workload.json), and [oracle](benchmarks/tsvc_s331_last_negative_index_oracle.py).

## DOE miniAMR 7-point and 27-point stencil averages (`doe_miniamr_stencil_average`)

This three-dimensional block kernel averages either the center and six axis neighbors or all 27 cells in each 3×3×3 neighborhood. It preserves source traversal and summation order, writes every interior result to a work buffer, then copies the staged values into the block before computing a position-weighted checksum. Nine language ports and an independent oracle cover both stencil branches, bounded haloed blocks, and malformed inputs. The package retains the Sandia source header and LGPL-2.1-or-later notice. See the [guide](benchmarks/d/doe_miniamr_stencil_average/README.md), [workload](benchmarks/d/doe_miniamr_stencil_average/workload.json), and [oracle](benchmarks/doe_miniamr_stencil_average_oracle.py).

## Rodinia forward integer 5/3 2D DWT (`rodinia_dwt2d`)

This bounded profile follows Rodinia's `-f -5` path: grayscale normalization, integer LeGall 5/3 lifting, vertical then horizontal passes, and recursive low-low decomposition. It emits source-ordered row-major wavelet-band chunks as signed i32 little-endian bytes. Nine clean-room ports and an independent oracle cover small divisible dimensions, recursive levels, signed-division edge cases, and output-capacity errors. The package preserves the pinned source notices and Rodinia citation request. See the [guide](benchmarks/r/rodinia_dwt2d/README.md), [workload](benchmarks/r/rodinia_dwt2d/workload.json), and [oracle](benchmarks/rodinia_dwt2d_oracle.py).

## VersaBench DIS R-tree child selection (`versabench_dbms_choose_entry`)

This bounded database helper chooses the existing child whose 4D bounding box gains the least volume when combined with an incoming box, keeping the first child on ties. The nine clean-room ports preserve pinned source attribution and document the absent redistribution grant. See the [guide](benchmarks/d/versabench_dbms_choose_entry/README.md), [workload](benchmarks/d/versabench_dbms_choose_entry/workload.json), and [oracle](benchmarks/versabench_dbms_choose_entry_oracle.py).

## TSVC s3111 positive-value sum (`tsvc_s3111_positive_value_sum`)

This bounded reduction sums only values greater than zero, retaining the conditional branch that distinguishes it from an ordinary array sum. Its clean-room ports record the missing upstream license grant and are registered in the scalar suite. See the [guide](benchmarks/t/tsvc_s3111_positive_value_sum/README.md), [workload](benchmarks/t/tsvc_s3111_positive_value_sum/workload.json), and [oracle](benchmarks/tsvc_s3111_positive_value_sum_oracle.py).

## TSVC s313 dot-product reduction (`tsvc_s313_dot_product_reduction`)

This bounded reduction accumulates `A[i] * B[i]` left to right, matching TSVC's s313 source loop. Inputs are integer-valued binary64 numbers, so the same profile covers the double and float launcher families with exact results. Nine clean-room ports and an independent oracle are registered in the float64 slice suite. The pinned TSVC source has no explicit redistribution grant; the package retains attribution and records that limitation. See the [guide](benchmarks/t/tsvc_s313_dot_product_reduction/README.md), [workload](benchmarks/t/tsvc_s313_dot_product_reduction/workload.json), and [oracle](benchmarks/tsvc_s313_dot_product_reduction_oracle.py).

## TSVC s275 conditional column AXPY recurrence (`tsvc_s275_column_conditional_axpy_recurrence`)

For each matrix column whose top-row guard is positive, this bounded kernel applies an ascending, in-place `A[j,i] = A[j-1,i] + B[j,i]*C[j,i]` chain. It preserves the source's column-outer traversal and guard behavior and returns the full final matrix. Nine clean-room ports and an independent oracle are registered in the float64 slice suite; the integer-valued domain is exact in both TSVC precision variants. The pinned source has no explicit redistribution grant. See the [guide](benchmarks/t/tsvc_s275_column_conditional_axpy_recurrence/README.md), [workload](benchmarks/t/tsvc_s275_column_conditional_axpy_recurrence/workload.json), and [oracle](benchmarks/tsvc_s275_column_conditional_axpy_recurrence_oracle.py).

## TSVC s111 odd-index neighbor update (`tsvc_s111_odd_index_neighbor_update`)

This bounded vector update copies A and replaces odd positions with `A[i-1] + B[i]`, matching s111's stride-two loop; even positions remain unchanged. Its odd-only write set distinguishes it from s131's all-index forward-neighbor update. Nine clean-room ports and an independent oracle are registered in the float64 slice suite. The pinned TSVC source has no explicit redistribution grant; attribution and rights limits are recorded in the package. See the [guide](benchmarks/t/tsvc_s111_odd_index_neighbor_update/README.md), [workload](benchmarks/t/tsvc_s111_odd_index_neighbor_update/workload.json), and [oracle](benchmarks/tsvc_s111_odd_index_neighbor_update_oracle.py).

## TSVC `vtvtv` triple-product map (`tsvc_vtvtv_triple_product_map`)

This bounded ControlLoops codelet emits `(A[i] * B[i]) * C[i]` in ascending order, preserving the source expression's left-associative binary64 order. It is distinct from s152's additive triple-product accumulation and s241's coupled A/B update. Nine clean-room ports and an independent oracle are registered in the float64 slice suite. The pinned source has no explicit redistribution grant; the package records attribution and the rights limitation. See the [guide](benchmarks/t/tsvc_vtvtv_triple_product_map/README.md), [workload](benchmarks/t/tsvc_vtvtv_triple_product_map/workload.json), and [oracle](benchmarks/tsvc_vtvtv_triple_product_map_oracle.py).

## TSVC `vtv` elementwise vector product (`tsvc_vtv_elementwise_product`)

This bounded ControlLoops profile repeats the ascending in-place update `A[i] *= B[i]` and returns the complete A vector. It is an elementwise map, distinct from s312's scalar product reduction and `vtvtv`'s three-factor map. Nine clean-room ports and an independent oracle use the byte-output ABI; the pinned TSVC source has no explicit redistribution grant. See the [guide](benchmarks/t/tsvc_vtv_elementwise_product/README.md), [workload](benchmarks/t/tsvc_vtv_elementwise_product/workload.json), and [oracle](benchmarks/tsvc_vtv_elementwise_product_oracle.py).

## TSVC `vpvpv` three-vector addition update (`tsvc_vpvpv_three_vector_add`)

This bounded ControlLoops profile repeats `A[i] += B[i] + C[i]`, preserving the source's ascending index and pass order while exposing the updated A vector. It is distinct from two-input matrix addition and dense SAXPY. Nine clean-room ports and an independent oracle use the byte-output ABI; the source has no explicit redistribution grant. See the [guide](benchmarks/t/tsvc_vpvpv_three_vector_add/README.md), [workload](benchmarks/t/tsvc_vpvpv_three_vector_add/workload.json), and [oracle](benchmarks/tsvc_vpvpv_three_vector_add_oracle.py).

## TSVC s451 binary64 sine/cosine vector map (`tsvc_s451_sincos_vector_map`)

This GlobalDataFlow codelet emits `sin(B[i]) + cos(C[i])` for each position using the double-precision source path. It is distinct from scalar trigonometric utilities and s452's index-weighted arithmetic map; the float launcher's `sinf`/`cosf` precision profile is outside this package. Nine clean-room ports and an independent oracle are registered in the float64 slice suite with a 1e-14 comparison tolerance. The pinned TSVC source has no explicit redistribution grant; the package records attribution and the rights limitation. See the [guide](benchmarks/t/tsvc_s451_sincos_vector_map/README.md), [workload](benchmarks/t/tsvc_s451_sincos_vector_map/workload.json), and [oracle](benchmarks/tsvc_s451_sincos_vector_map_oracle.py).

## TSVC s221 partially recursive fused update (`tsvc_s221_partial_recursive_fused_update`)

This LoopRestructuring codelet first applies `A[i] += C[i]*D[i]`, then advances a dependent B chain with the updated A and D. The ascending order and updated-value dependency make it distinct from independent per-column recurrences and single-array neighbor updates. Nine clean-room ports and an independent oracle are registered in the float64 slice suite; bounded integer intermediates remain exact in binary32 and binary64. The pinned TSVC source has no explicit redistribution grant; see the package rights note. See the [guide](benchmarks/t/tsvc_s221_partial_recursive_fused_update/README.md), [workload](benchmarks/t/tsvc_s221_partial_recursive_fused_update/workload.json), and [oracle](benchmarks/tsvc_s221_partial_recursive_fused_update_oracle.py).

## TSVC s222 interleaved square recurrence (`tsvc_s222_interleaved_square_recurrence`)

This bounded float64-slice profile preserves s222's ordered add, square-recurrence update, and subtract statements. It supplies E's seed explicitly because the pinned initializer leaves E at static zero, making that recurrence unobservable in the source default. The recurrence is distinct from existing linear neighbor recurrences; bounded exact inputs also preserve the interleaved cancellation. The pinned TSVC source has no explicit redistribution grant, so the nine ports are clean-room. s317's repeated fixed-factor product is treated as a specialization of the existing s312 product reduction rather than a separate package. See the [guide](benchmarks/t/tsvc_s222_interleaved_square_recurrence/README.md), [workload](benchmarks/t/tsvc_s222_interleaved_square_recurrence/workload.json), and [oracle](benchmarks/tsvc_s222_interleaved_square_recurrence_oracle.py).

## TSVC s124 conditional FMA map (`tsvc_s124_conditional_fma_map`)

This bounded induction-variable kernel selects B when positive and C otherwise, then adds D times E at each position. Nine clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s124_conditional_fma_map/README.md), [workload](benchmarks/t/tsvc_s124_conditional_fma_map/workload.json), and [oracle](benchmarks/tsvc_s124_conditional_fma_map_oracle.py).

## TSVC s123 conditional pair expansion (`tsvc_s123_conditional_pair_expansion`)

This bounded induction-variable kernel emits `B[i]+D[i]*E[i]` for every position and inserts `C[i]+D[i]*E[i]` when C is positive. It returns the actual output count and preserves per-index order. Nine clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s123_conditional_pair_expansion/README.md), [workload](benchmarks/t/tsvc_s123_conditional_pair_expansion/workload.json), and [oracle](benchmarks/tsvc_s123_conditional_pair_expansion_oracle.py).

## TSVC s122 reverse-strided gather-add (`tsvc_s122_reverse_strided_gather_add`)

This bounded induction-variable kernel adds a reverse sequential B stream to A positions selected by a runtime start and stride. It preserves untouched A entries and returns the complete A vector. Nine clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s122_reverse_strided_gather_add/README.md), [workload](benchmarks/t/tsvc_s122_reverse_strided_gather_add/workload.json), and [oracle](benchmarks/tsvc_s122_reverse_strided_gather_add_oracle.py).

## TSVC s125 flattened matrix FMA (`tsvc_s125_matrix_flattened_fma`)

This bounded induction-variable kernel visits matrix cells in row-major order and emits `AA + BB*CC` for each cell. Nine clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s125_matrix_flattened_fma/README.md), [workload](benchmarks/t/tsvc_s125_matrix_flattened_fma/workload.json), and [oracle](benchmarks/tsvc_s125_matrix_flattened_fma_oracle.py).

## TSVC s2101 diagonal matrix FMA (`tsvc_s2101_diagonal_matrix_fma`)

This bounded row-major matrix kernel updates `AA[i,i] += BB[i,i]*CC[i,i]` in ascending diagonal order and leaves off-diagonal cells unchanged. It differs from s125's full-matrix FMA. Nine clean-room ports document the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s2101_diagonal_matrix_fma/README.md), [workload](benchmarks/t/tsvc_s2101_diagonal_matrix_fma/workload.json), and [oracle](benchmarks/tsvc_s2101_diagonal_matrix_fma_oracle.py).

## TSVC s2102 identity matrix initialization (`tsvc_s2102_identity_matrix_initialize`)

This bounded column-major initialization clears each matrix column and then sets its diagonal element to one, returning the full row-major identity matrix as little-endian signed i64 values. Repeated passes preserve the source loop's reset behavior. It is distinct from s2101's diagonal FMA. Nine clean-room ports document the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s2102_identity_matrix_initialize/README.md), [workload](benchmarks/t/tsvc_s2102_identity_matrix_initialize/workload.json), and [oracle](benchmarks/tsvc_s2102_identity_matrix_initialize_oracle.py).

## TSVC s312 array product (`tsvc_s312_array_product`)

This bounded reduction multiplies every factor in order, using 1 for an empty array. Nine clean-room ports record the missing upstream license grant and are registered in the scalar suite. See the [guide](benchmarks/t/tsvc_s312_array_product/README.md), [workload](benchmarks/t/tsvc_s312_array_product/workload.json), and [oracle](benchmarks/tsvc_s312_array_product_oracle.py).

## TSVC s315 maximum with index (`tsvc_s315_maximum_with_index`)

This bounded reduction returns the maximum value and the first zero-based index where it occurs. Nine clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s315_maximum_with_index/README.md), [workload](benchmarks/t/tsvc_s315_maximum_with_index/workload.json), and [oracle](benchmarks/tsvc_s315_maximum_with_index_oracle.py).

## TSVC s318 strided absolute maximum with index (`tsvc_s318_strided_absolute_maximum_with_index`)

This bounded reduction scans a correctly sized physical span at a caller-selected stride and returns the maximum sampled magnitude with its first logical index. It differs from `abs_max`'s signed-element result and from s315's signed maximum. Nine clean-room ports record that no explicit upstream TSVC license grant was found and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s318_strided_absolute_maximum_with_index/README.md), [workload](benchmarks/t/tsvc_s318_strided_absolute_maximum_with_index/workload.json), and [oracle](benchmarks/tsvc_s318_strided_absolute_maximum_with_index_oracle.py).

## TSVC s319 coupled reductions (`tsvc_s319_coupled_reductions`)

This bounded fused reduction emits two pointwise sums per input position, then a combined total in source order. Nine clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s319_coupled_reductions/README.md), [workload](benchmarks/t/tsvc_s319_coupled_reductions/workload.json), and [oracle](benchmarks/tsvc_s319_coupled_reductions_oracle.py).

## TSVC s241 cross-coupled product map (`tsvc_s241_cross_coupled_product_map`)

This bounded two-array kernel updates A and B in ascending order, combining a three-factor product with the old next A value. Nine clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s241_cross_coupled_product_map/README.md), [workload](benchmarks/t/tsvc_s241_cross_coupled_product_map/workload.json), and [oracle](benchmarks/tsvc_s241_cross_coupled_product_map_oracle.py).

## TSVC s243 ordered lookahead update (`tsvc_s243_ordered_lookahead_update`)

This bounded two-array kernel preserves s243's source-ordered A/B lookahead updates and leaves the final pair unchanged. Nine clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s243_ordered_lookahead_update/README.md), [workload](benchmarks/t/tsvc_s243_ordered_lookahead_update/workload.json), and [oracle](benchmarks/tsvc_s243_ordered_lookahead_update_oracle.py).

## TSVC s244 false dependence cycle break (`tsvc_s244_false_dependence_cycle_break`)

This bounded one-sweep kernel preserves s244's source statement order and emits a trace of intermediate stores that later iterations overwrite. Nine clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s244_false_dependence_cycle_break/README.md), [workload](benchmarks/t/tsvc_s244_false_dependence_cycle_break/workload.json), and [oracle](benchmarks/tsvc_s244_false_dependence_cycle_break_oracle.py).

## TSVC s1244 polynomial neighbor sum (`tsvc_s1244_polynomial_neighbor_sum`)

This bounded two-array kernel applies s1244's polynomial update to A, then adds the saved old next-A value into D in ascending order. The final A and D entries remain unchanged. Nine clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s1244_polynomial_neighbor_sum/README.md), [workload](benchmarks/t/tsvc_s1244_polynomial_neighbor_sum/workload.json), and [oracle](benchmarks/tsvc_s1244_polynomial_neighbor_sum_oracle.py).

## TSVC s242 fused prefix update (`tsvc_s242_fused_prefix_update`)

This bounded float64-slice kernel preserves NodeSplitting s242's seed at A[0], then scans upward while fusing B/C/D additions and scalar s1/s2 into each prefix update in source order. Integer-valued inputs keep both float and double results exact. Nine clean-room ports record the absent upstream modification grant. The s341 one-dimensional positive-value pack is reviewed as a stable-compaction specialization of s343; s2244 is a related transient next-slot overwrite pattern covered by s244's store-trace profile. See the [guide](benchmarks/t/tsvc_s242_fused_prefix_update/README.md), [workload](benchmarks/t/tsvc_s242_fused_prefix_update/workload.json), and [oracle](benchmarks/tsvc_s242_fused_prefix_update_oracle.py).

## TSVC s1221 lag-four additive recurrence (`tsvc_s1221_lag4_add_recurrence`)

This bounded recurrence updates B from B four positions earlier plus A, forming four independent additive chains. Its integer-valued domain is exact for both TSVC float families. Nine clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s1221_lag4_add_recurrence/README.md), [workload](benchmarks/t/tsvc_s1221_lag4_add_recurrence/workload.json), and [oracle](benchmarks/tsvc_s1221_lag4_add_recurrence_oracle.py).

## TSVC s332 first above threshold (`tsvc_s332_first_above_threshold`)

This bounded search stops at the first value strictly above its threshold, returning its index and value or the source no-match sentinels. It is distinct from s331's full scan for the last negative value. See the [guide](benchmarks/t/tsvc_s332_first_above_threshold/README.md), [workload](benchmarks/t/tsvc_s332_first_above_threshold/workload.json), and [oracle](benchmarks/tsvc_s332_first_above_threshold_oracle.py).

## TSVC s442 indexed square accumulate (`tsvc_s442_indexed_square_accumulate`)

This bounded kernel uses an index tag to choose one of four arrays, then adds that value's square into A over repeated ascending passes. All four branches are represented, with bounded integer values that stay exact. See the [guide](benchmarks/t/tsvc_s442_indexed_square_accumulate/README.md), [workload](benchmarks/t/tsvc_s442_indexed_square_accumulate/workload.json), and [oracle](benchmarks/tsvc_s442_indexed_square_accumulate_oracle.py).

## VersaBench DIS R-tree partition entries (`versabench_dbms_partition_entries`)

This bounded split helper selects the pair of entries with the largest 4D union volume, then assigns the remaining entries to two groups in source order. See the [guide](benchmarks/d/versabench_dbms_partition_entries/README.md), [workload](benchmarks/d/versabench_dbms_partition_entries/workload.json), and [oracle](benchmarks/versabench_dbms_partition_entries_oracle.py).

## VersaBench DIS R-tree consistent key (`versabench_dbms_consistent_key`)

This bounded predicate checks whether two closed 4D boxes intersect, including touching faces, edges, and points. See the [guide](benchmarks/d/versabench_dbms_consistent_key/README.md), [workload](benchmarks/d/versabench_dbms_consistent_key/workload.json), and [oracle](benchmarks/versabench_dbms_consistent_key_oracle.py).

## VersaBench DIS R-tree keys union (`versabench_dbms_keys_union`)

This bounded helper returns the minimum 4D bounding box containing a list of keys. See the [guide](benchmarks/d/versabench_dbms_keys_union/README.md), [workload](benchmarks/d/versabench_dbms_keys_union/workload.json), and [oracle](benchmarks/versabench_dbms_keys_union_oracle.py).

## VersaBench DIS R-tree query (`versabench_dbms_query`)

This bounded tree traversal prunes branches by closed 4D box intersection and emits matching leaf record IDs in depth-first entry order. See the [guide](benchmarks/d/versabench_dbms_query/README.md), [workload](benchmarks/d/versabench_dbms_query/workload.json), and [oracle](benchmarks/versabench_dbms_query_oracle.py).

## VersaBench DIS R-tree insert entry (`versabench_dbms_insert_entry`)

This bounded success-path profile follows recursive minimum-enlargement descent, inserts into a leaf with room, and recomputes bounding boxes back up the path. Overflow and split handling remain outside the profile. See the [guide](benchmarks/d/versabench_dbms_insert_entry/README.md), [workload](benchmarks/d/versabench_dbms_insert_entry/workload.json), and [oracle](benchmarks/versabench_dbms_insert_entry_oracle.py).

## VersaBench DIS R-tree delete entry (`versabench_dbms_delete_entry`)

This bounded one-level deletion profile prunes child MBRs by closed 4D intersection, removes matching leaf records, unlinks empty children, and recomputes surviving MBRs. See the [guide](benchmarks/d/versabench_dbms_delete_entry/README.md), [workload](benchmarks/d/versabench_dbms_delete_entry/workload.json), and [oracle](benchmarks/versabench_dbms_delete_entry_oracle.py).

## VersaBench DIS R-tree root contraction (`versabench_dbms_contract_root`)

This bounded root-normalization step repeatedly promotes a sole child after deletion, then converts an empty internal root to an empty leaf. It is separate from leaf deletion and child MBR updates. See the [guide](benchmarks/d/versabench_dbms_contract_root/README.md), [workload](benchmarks/d/versabench_dbms_contract_root/workload.json), and [oracle](benchmarks/versabench_dbms_contract_root_oracle.py).

## VersaBench DIS R-tree penalty (`versabench_dbms_penalty`)

This bounded insertion helper computes the directional 4D volume enlargement from adding one box to another. See the [guide](benchmarks/d/versabench_dbms_penalty/README.md), [workload](benchmarks/d/versabench_dbms_penalty/workload.json), and [oracle](benchmarks/versabench_dbms_penalty_oracle.py).

## VersaBench DIS R-tree valid attributes (`versabench_dbms_valid_attributes`)

This bounded record validator checks attribute codes, binary32 key payloads, and the source's null/non-null rules for non-key attributes. It preserves the source-level distinction between invalid data and malformed framing. See the [guide](benchmarks/d/versabench_dbms_valid_attributes/README.md), [workload](benchmarks/d/versabench_dbms_valid_attributes/workload.json), and [oracle](benchmarks/versabench_dbms_valid_attributes_oracle.py).

## VersaBench DIS R-tree valid index key (`versabench_dbms_valid_index_key`)

This bounded predicate checks strict lower-to-upper endpoint order for four binary32 dimensions, preserving the source's NaN, signed-zero, and infinity comparison behavior. See the [guide](benchmarks/d/versabench_dbms_valid_index_key/README.md), [workload](benchmarks/d/versabench_dbms_valid_index_key/workload.json), and [oracle](benchmarks/versabench_dbms_valid_index_key_oracle.py).

## TSVC s453 recurrence-weighted scale (`tsvc_s453_recurrence_weighted_scale`)

This bounded kernel advances a scalar recurrence by two and uses it to scale each B value, preserving the source's recurrence dependency. Nine clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s453_recurrence_weighted_scale/README.md), [workload](benchmarks/t/tsvc_s453_recurrence_weighted_scale/workload.json), and [oracle](benchmarks/tsvc_s453_recurrence_weighted_scale_oracle.py).

## TSVC s342 conditional unpack (`tsvc_s342_conditional_unpack`)

This bounded packing kernel replaces positive-mask positions in A with successive values from packed B, retaining every unselected A position. It models one loop-body sweep and returns the full final A vector. Nine clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s342_conditional_unpack/README.md), [workload](benchmarks/t/tsvc_s342_conditional_unpack/workload.json), and [oracle](benchmarks/tsvc_s342_conditional_unpack_oracle.py).

## TSVC s258 wrapped scalar expansion (`tsvc_s258_wrapped_scalar_expansion`)

This bounded scalar-ABI profile preserves s258's conditional scalar refresh, carry across false branches, and two output expansions. The values remain exact in the Expansion double and float families. See the [guide](benchmarks/t/tsvc_s258_wrapped_scalar_expansion/README.md), [workload](benchmarks/t/tsvc_s258_wrapped_scalar_expansion/workload.json), and [oracle](benchmarks/tsvc_s258_wrapped_scalar_expansion_oracle.py).

## TSVC s2251 carried-scalar expansion (`tsvc_s2251_carried_scalar_expansion`)

This one-sweep profile preserves s2251's carried scalar and its exact write order: A is written from the previous scalar, the scalar reads the pre-update B and C values, then B is updated from the new A and D. The contract returns final A followed by final B; its bounded integer-valued recurrence is exact in the Expansion double and float families. The nine clean-room ports record that no explicit upstream modification or redistribution grant was found. See the [guide](benchmarks/t/tsvc_s2251_carried_scalar_expansion/README.md), [workload](benchmarks/t/tsvc_s2251_carried_scalar_expansion/workload.json), and [oracle](benchmarks/tsvc_s2251_carried_scalar_expansion_oracle.py).

## TSVC s1251 per-element dual update (`tsvc_s1251_per_element_dual_update`)

This bounded Expansion profile saves `B[i]+C[i]`, then updates B from the original A and D, and writes A from the saved sum times E. It returns final A followed by final B and preserves the per-position statement order. Nine clean-room ports note that the pinned source has no explicit redistribution grant. The nearby s254/s255 circular moving averages are related to existing moving-average packages; the distinct forward dependency in s3251 has its own package. See the [guide](benchmarks/t/tsvc_s1251_per_element_dual_update/README.md), [workload](benchmarks/t/tsvc_s1251_per_element_dual_update/workload.json), and [oracle](benchmarks/tsvc_s1251_per_element_dual_update_oracle.py).

## TSVC s3251 forward-shifted array expansion (`tsvc_s3251_forward_shifted_array_expansion`)

This bounded Expansion profile preserves the ascending `A[i+1]` dependency followed by `B[i]` and `D[i]` updates. The output returns final A, B, and D, exposing the carried forward dependency and untouched tail entries. The input arrays are explicit; the source's `s251` initializer (A zero, B one, C/D/E reciprocal values) is documented but not imposed, and integer-valued inputs keep both TSVC precision families exact. Nine clean-room ports record the absent explicit redistribution grant. See the [guide](benchmarks/t/tsvc_s3251_forward_shifted_array_expansion/README.md), [workload](benchmarks/t/tsvc_s3251_forward_shifted_array_expansion/workload.json), and [oracle](benchmarks/tsvc_s3251_forward_shifted_array_expansion_oracle.py).

## TSVC s261 shifted cross-array update (`tsvc_s261_shifted_cross_array_update`)

This one-sweep profile updates A from the previous C value, then scales C in place so later iterations observe the changed neighbor. It returns final A and C as packed i64 vectors. See the [guide](benchmarks/t/tsvc_s261_shifted_cross_array_update/README.md), [workload](benchmarks/t/tsvc_s261_shifted_cross_array_update/workload.json), and [oracle](benchmarks/tsvc_s261_shifted_cross_array_update_oracle.py).

## TSVC s251 scalar square expansion (`tsvc_s251_scalar_square_expansion`)

This bounded expansion computes a per-element temporary `B+C*D` and writes its square to A. The temporary resets for each index; it is not a recurrence. Nine clean-room ports record the missing upstream license grant and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s251_scalar_square_expansion/README.md), [workload](benchmarks/t/tsvc_s251_scalar_square_expansion/workload.json), and [oracle](benchmarks/tsvc_s251_scalar_square_expansion_oracle.py).

## TSVC s252 adjacent product pair sum (`tsvc_s252_adjacent_product_pair_sum`)

This bounded vector kernel adds each adjacent pair of products, carrying the previous product rather than the previous output. See the [guide](benchmarks/t/tsvc_s252_adjacent_product_pair_sum/README.md), [workload](benchmarks/t/tsvc_s252_adjacent_product_pair_sum/workload.json), and [oracle](benchmarks/tsvc_s252_adjacent_product_pair_sum_oracle.py).

## TSVC s256 array expansion (`tsvc_s256_array_expansion`)

This bounded nested sweep preserves the row-seeded recurrence for A and writes each column of C from the corresponding B cell and row factor D. It returns the final A vector and matrix, and is distinct from s257's coupled matrix/scalar recurrence. Nine clean-room ports record that no explicit upstream TSVC license grant was found and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s256_array_expansion/README.md), [workload](benchmarks/t/tsvc_s256_array_expansion/workload.json), and [oracle](benchmarks/tsvc_s256_array_expansion_oracle.py).

## TSVC s253 conditional affine update (`tsvc_s253_conditional_affine_update`)

This bounded multi-pass kernel conditionally computes `A[i]-B[i]*D[i]`, adds it to C, and stores it back into A, so the updated state controls later passes. It is distinct from s273's dependent negative-value branch, s278's sign-controlled assignment, and s124's nonmutating map. Nine clean-room ports record that no explicit upstream TSVC license grant was found and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s253_conditional_affine_update/README.md), [workload](benchmarks/t/tsvc_s253_conditional_affine_update/workload.json), and [oracle](benchmarks/tsvc_s253_conditional_affine_update_oracle.py).

## TSVC s274 dependent conditional overwrite (`tsvc_s274_dependent_conditional_overwrite`)

This bounded multi-pass kernel computes `A[i]=C[i]+E[i]*D[i]`, then either adds A into B when A is positive or overwrites A with `D[i]*E[i]`. It differs from s273's conditional state update and s278's branch on the prior A value. Nine clean-room ports record that no explicit upstream TSVC license grant was found and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s274_dependent_conditional_overwrite/README.md), [workload](benchmarks/t/tsvc_s274_dependent_conditional_overwrite/workload.json), and [oracle](benchmarks/tsvc_s274_dependent_conditional_overwrite_oracle.py).

## TSVC s272 thresholded dual accumulation (`tsvc_s272_threshold_dual_accumulate`)

This bounded multi-pass kernel updates A by `C[i]*D[i]` and B by `C[i]*C[i]` when E meets the inclusive threshold. Its E-controlled paired updates differ from the adjacent s273–s274 branch contracts. Nine clean-room ports document that no explicit upstream TSVC license grant was found and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s272_threshold_dual_accumulate/README.md), [workload](benchmarks/t/tsvc_s272_threshold_dual_accumulate/workload.json), and [oracle](benchmarks/tsvc_s272_threshold_dual_accumulate_oracle.py).

## TSVC s271 positive-branch AXPY (`tsvc_s271_positive_branch_axpy`)

This bounded multi-pass kernel updates A by `B[i]*C[i]` only when B is strictly positive. Zero and negative B values leave A untouched; repeated passes preserve the same branch mask because B is not modified. Nine clean-room ports note that no explicit upstream TSVC license grant was found and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s271_positive_branch_axpy/README.md), [workload](benchmarks/t/tsvc_s271_positive_branch_axpy/workload.json), and [oracle](benchmarks/tsvc_s271_positive_branch_axpy_oracle.py).

## TSVC s2711 nonzero-branch AXPY (`tsvc_s2711_nonzero_branch_axpy`)

This bounded ControlFlow profile applies `A[i] += B[i] * C[i]` when `B[i] != 0`, including negative B values. That condition is distinct from s271's positive-only branch. Nine clean-room ports preserve attribution and the source-rights limitation; the package is registered in the byte-output suite with primary and independent oracles. See the [guide](benchmarks/t/tsvc_s2711_nonzero_branch_axpy/README.md), [workload](benchmarks/t/tsvc_s2711_nonzero_branch_axpy/workload.json), and [oracle](benchmarks/tsvc_s2711_nonzero_branch_axpy_oracle.py).

## TSVC s2712 comparison-gated AXPY (`tsvc_s2712_comparison_gated_axpy`)

This bounded ControlFlow profile applies `A[i] += B[i]*C[i]` only when the current A is strictly greater than B, reevaluating the comparison on each ascending-index pass. Its state-dependent mask differs from s271's fixed positive-B mask; s2711's nonzero-B mask is a related predicate sibling and is not claimed as an exact duplicate. Nine clean-room ports note the absent explicit TSVC redistribution grant. See the [guide](benchmarks/t/tsvc_s2712_comparison_gated_axpy/README.md), [workload](benchmarks/t/tsvc_s2712_comparison_gated_axpy/workload.json), and [oracle](benchmarks/tsvc_s2712_comparison_gated_axpy_oracle.py).

## TSVC s2710 nested scalar/vector branch update (`tsvc_s2710_nested_scalar_vector_branch_update`)

This bounded ControlFlow profile preserves s2710's `A[i] > B[i]` branch, distinct A/B/C writes, and scalar `x > 0` decision in the else arm. Its n≥11 range selects the pinned source's `LEN > 10` C-accumulation branch. Nine clean-room ports record that no explicit TSVC redistribution grant was found. See the [guide](benchmarks/t/tsvc_s2710_nested_scalar_vector_branch_update/README.md), [workload](benchmarks/t/tsvc_s2710_nested_scalar_vector_branch_update/workload.json), and [oracle](benchmarks/tsvc_s2710_nested_scalar_vector_branch_update_oracle.py).

## TSVC s1279 nested conditional accumulation (`tsvc_s1279_nested_conditional_accumulation`)

This bounded ControlFlow profile adds `D[i]*E[i]` to C only when both strict predicates `A[i] < 0` and `B[i] > A[i]` hold. It leaves A, B, D, and E unchanged, exposing a nested conditional accumulation distinct from s2711's nonzero-B AXPY and s2710's branch-dependent state updates. Nine clean-room ports record that no explicit TSVC redistribution grant was found. See the [guide](benchmarks/t/tsvc_s1279_nested_conditional_accumulation/README.md), [workload](benchmarks/t/tsvc_s1279_nested_conditional_accumulation/workload.json), and [oracle](benchmarks/tsvc_s1279_nested_conditional_accumulation_oracle.py).

## TSVC s2275 interleaved matrix/vector AXPY (`tsvc_s2275_matrix_vector_axpy_interleave`)

This bounded ControlFlow codelet sweeps each matrix column with `AA[j][i] += BB[j][i]*CC[j][i]`, then overwrites `A[i] = B[i]+C[i]*D[i]`. It exposes both outputs and preserves the pinned column-by-column order, differing from s275's conditional recurrence down each column. Nine clean-room ports record that no explicit upstream redistribution grant was found. See the [guide](benchmarks/t/tsvc_s2275_matrix_vector_axpy_interleave/README.md), [workload](benchmarks/t/tsvc_s2275_matrix_vector_axpy_interleave/workload.json), and [oracle](benchmarks/tsvc_s2275_matrix_vector_axpy_interleave_oracle.py).

## TSVC s482 break-after-update prefix sweep (`tsvc_s482_break_after_update`)

This bounded ControlFlow profile updates each visited A element by `B[i]*C[i]` before applying the strict `C[i] > B[i]` break. The prefix update is repeated from index zero each pass. It is related to first-match scans such as s332, but those scans do not mutate the visited prefix. Nine clean-room ports record that no explicit upstream redistribution grant was found. See the [guide](benchmarks/t/tsvc_s482_break_after_update/README.md), [workload](benchmarks/t/tsvc_s482_break_after_update/workload.json), and [oracle](benchmarks/tsvc_s482_break_after_update_oracle.py).

## TSVC s1281 elementwise dual update (`tsvc_s1281_elementwise_dual_update`)

This bounded CrossingThresholds profile evaluates `(B[i]*C[i] + A[i]*D[i]) + E[i]`, then writes `A[i]=x-1` followed by `B[i]=x` on each ascending-index pass. It exposes both updated arrays, unlike s281's reverse-index coupled recurrence, and preserves the source's expression and write order. Nine clean-room ports note that no explicit TSVC redistribution grant was found. See the [guide](benchmarks/t/tsvc_s1281_elementwise_dual_update/README.md), [workload](benchmarks/t/tsvc_s1281_elementwise_dual_update/workload.json), and [oracle](benchmarks/tsvc_s1281_elementwise_dual_update_oracle.py).

## TSVC s293 first-element broadcast (`tsvc_s293_first_element_broadcast`)

This bounded CrossingThresholds codelet copies the original `A[0]` value to every array position in ascending order. It is a source-level broadcast kernel, not a cyclic-neighbor average; s292's three-element wraparound average is a window-size variant related to s291 and is not counted as a separate algorithm package. Nine clean-room ports record that no explicit TSVC redistribution grant was found. See the [guide](benchmarks/t/tsvc_s293_first_element_broadcast/README.md), [workload](benchmarks/t/tsvc_s293_first_element_broadcast/workload.json), and [oracle](benchmarks/tsvc_s293_first_element_broadcast_oracle.py).

## TSVC s441/s443 D-sign branch updates (`tsvc_s441_s443_d_sign_branch_updates`)

This mode-dispatched ControlFlow profile implements s441's three-way D sign test (`D<0`: add B*C; `D==0`: add B²; `D>0`: add C²) and s443's two-way test (`D<=0`: add B*C; otherwise add B²). The separate modes preserve the source's different predicates and expressions, unlike s442's indexed square selection. Nine clean-room ports use bounded integer-valued inputs and document that no explicit upstream redistribution grant was found. See the [guide](benchmarks/t/tsvc_s441_s443_d_sign_branch_updates/README.md), [workload](benchmarks/t/tsvc_s441_s443_d_sign_branch_updates/workload.json), and [oracle](benchmarks/tsvc_s441_s443_d_sign_branch_updates_oracle.py).

## TSVC s276 index-split AXPY (`tsvc_s276_index_split_axpy`)

This bounded multi-pass kernel chooses C or D using the source cutoff `i+1 < floor(n/2)`, then updates A by `B[i]` times that coefficient. The branch depends only on the loop index and preserves two coefficient regions, including the source's small-n boundary. Nine clean-room ports document that no explicit TSVC license grant was found and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s276_index_split_axpy/README.md), [workload](benchmarks/t/tsvc_s276_index_split_axpy/workload.json), and [oracle](benchmarks/tsvc_s276_index_split_axpy_oracle.py).

## TSVC s277 guarded carry update (`tsvc_s277_guarded_carry_update`)

This bounded multi-pass kernel skips each iteration when A[i] is nonnegative, conditionally updates A[i] when B[i] is negative, and then writes a computed value into B[i+1]. That carried write affects later loop iterations and later passes. Nine clean-room ports document that no explicit TSVC license grant was found and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_s277_guarded_carry_update/README.md), [workload](benchmarks/t/tsvc_s277_guarded_carry_update/workload.json), and [oracle](benchmarks/tsvc_s277_guarded_carry_update_oracle.py).

## MediaBench MPEG-2 motion-vector component (`mediabench_mpeg2_motion_vector_component`)

This bounded profile implements one MPEG-2 motion-vector component update, including signed delta calculation and one wrap into the legal predictor interval. It excludes VLC parsing and decoder state. The ports are clean-room, with source redistribution and patent caveats recorded in the package notice. See the [guide](benchmarks/m/mediabench_mpeg2_motion_vector_component/README.md), [workload](benchmarks/m/mediabench_mpeg2_motion_vector_component/workload.json), and [oracle](benchmarks/mediabench_mpeg2_motion_vector_component_oracle.py).

## TSVC s424 alias-overlap feedback (`tsvc_s424_alias_overlap_feedback`)

This scalar profile models the source-ordered sweep over a 64-element alias displacement, where each write can feed later reads. Its bounded integer domain preserves the Equivalencing double and float behavior exactly. See the [guide](benchmarks/t/tsvc_s424_alias_overlap_feedback/README.md), [workload](benchmarks/t/tsvc_s424_alias_overlap_feedback/workload.json), and [oracle](benchmarks/tsvc_s424_alias_overlap_feedback_oracle.py).

## TSVC s423 offset-64 anti-dependence (`tsvc_s423_antidependence_offset64`)

This scalar profile reads each offset-64 value before a later iteration overwrites that location, then returns the updated prefix checksum. Its read-before-overwrite direction is distinct from s424's forward alias feedback, where earlier writes feed later reads. Bounded integer-valued inputs preserve the Equivalencing double and float results exactly; the ports are clean-room because no explicit upstream redistribution grant was found. See the [guide](benchmarks/t/tsvc_s423_antidependence_offset64/README.md), [workload](benchmarks/t/tsvc_s423_antidependence_offset64/workload.json), and [oracle](benchmarks/tsvc_s423_antidependence_offset64_oracle.py).

## IDEA CFB64 stream encryption and decryption (`idea_cfb64`)

This bounded PGP profile supports both IDEA CFB64 directions, feeding ciphertext back as the next keystream state and preserving a partial final segment without padding. One package covers the paired cBench `security_pgp_d` encryption and `security_pgp_e` decryption helpers, avoiding duplicate benchmark ids for the same mode. It is distinct from the fixed-block IDEA ECB encryption/decryption benchmark. The package records both sources' noncommercial-use statements and the absence of an explicit source redistribution grant. See the [guide](benchmarks/p/idea_cfb64/README.md), [workload](benchmarks/p/idea_cfb64/workload.json), and [oracle](benchmarks/idea_cfb64_oracle.py).

## LLUBenchmark list traversal and growth (`llubenchmark_list_traversal_growth`)

This bounded workload traverses and dirties linked-list counts, accumulates their values, and appends nodes according to the source's fractional growth schedule. Index-linked storage preserves each list's order while bounding the node pool. See the [guide](benchmarks/l/llubenchmark_list_traversal_growth/README.md), [workload](benchmarks/l/llubenchmark_list_traversal_growth/workload.json), and [oracle](benchmarks/llubenchmark_list_traversal_growth_oracle.py).

## TSVC s171 stride-indexed accumulation (`tsvc_s171_stride_indexed_accumulate`)

This one-sweep kernel adds each B value into A at an affine-stride destination and preserves the untouched gap slots. The bounded profile covers the pinned contiguous launcher shape and strides 2 through 4; it is distinct from the arbitrary-index gather/scatter profile. See the [guide](benchmarks/t/tsvc_s171_stride_indexed_accumulate/README.md), [workload](benchmarks/t/tsvc_s171_stride_indexed_accumulate/workload.json), and [oracle](benchmarks/tsvc_s171_stride_indexed_accumulate_oracle.py).

## TSVC s4114 reverse-index gather FMA (`tsvc_s4114_reverse_index_gather_fma`)

This bounded dense-output map computes A[i] = B[i] + C[n-1-IP[i]]*D[i] in one ascending sweep, preserving s4114's reverse-index gather. It differs from s4113/s491's indirect LHS scatters and s4117's fixed C[i/2] gather. The profile fixes the launcher lower bound to n1=1, omits s4114's dead k+=5 update, and uses clean-room ports because no explicit upstream TSVC license grant was found. See the [guide](benchmarks/t/tsvc_s4114_reverse_index_gather_fma/README.md), [workload](benchmarks/t/tsvc_s4114_reverse_index_gather_fma/workload.json), and [oracle](benchmarks/tsvc_s4114_reverse_index_gather_fma_oracle.py).

## TSVC s4115 indexed gather product-sum (`tsvc_s4115_indexed_gather_product_sum`)

This bounded source-order reduction sums `A[i] * B[indexes[i]]`, allowing repeated gather indexes. It is distinct from s4114 and s4117's output-vector maps, the `vag` indexed copy, and s4113/s491's scatter updates. Its nine clean-room ports record that no explicit upstream TSVC license grant was found and are registered in the array-scalar suite. See the [guide](benchmarks/t/tsvc_s4115_indexed_gather_product_sum/README.md), [workload](benchmarks/t/tsvc_s4115_indexed_gather_product_sum/workload.json), and [oracle](benchmarks/tsvc_s4115_indexed_gather_product_sum_oracle.py).

## TSVC vag indexed gather-copy (`tsvc_vag_indexed_gather_copy`)

This bounded indexed copy emits `values[indexes[i]]` in ascending output order and permits duplicate indexes. It differs from s4113/s491's indirect LHS scatter operations, s4114's reverse-index gather FMA, and s4117's fixed paired gather map. Nine clean-room ports record that no explicit upstream TSVC license grant was found and are registered in the byte-output suite. See the [guide](benchmarks/t/tsvc_vag_indexed_gather_copy/README.md), [workload](benchmarks/t/tsvc_vag_indexed_gather_copy/workload.json), and [oracle](benchmarks/tsvc_vag_indexed_gather_copy_oracle.py).

## TSVC s4117 pair-replicated gather map (`tsvc_s4117_pair_replicated_gather_map`)

This one-sweep map reuses each C value for two adjacent outputs and multiplies it by the corresponding D value before adding B. It is distinct from s171's affine-stride scatter update and the explicit arbitrary-index gather/scatter profile. See the [guide](benchmarks/t/tsvc_s4117_pair_replicated_gather_map/README.md), [workload](benchmarks/t/tsvc_s4117_pair_replicated_gather_map/workload.json), and [oracle](benchmarks/tsvc_s4117_pair_replicated_gather_map_oracle.py).

## MiBench JPEG YCbCr to RGB (`mibench_jpeg_ycbcr_to_rgb`)

This profile isolates the JPEG decoder's 8-bit fixed-point color-conversion kernel, including its distinct green-channel rounding and output clamping. It is separate from grayscale decoding and RGB-to-gray conversion. See the [guide](benchmarks/m/mibench_jpeg_ycbcr_to_rgb/README.md), [workload](benchmarks/m/mibench_jpeg_ycbcr_to_rgb/workload.json), and [oracle](benchmarks/mibench_jpeg_ycbcr_to_rgb_oracle.py).

## cBench IJG JPEG 2x2 fancy upsampling (`cbench_consumer_jpeg_h2v2_fancy_upsample`)

This bounded component-plane kernel performs IJG's twofold horizontal and vertical triangle-filter interpolation, including its explicit edge formulas, replicated top/bottom context rows, and fixed-point `+8`/`+7` rounding. It is distinct from YCbCr-to-RGB conversion and grayscale block decoding, which do not spatially upsample component planes. The package retains the IJG notice and documents the adaptation boundary; JPEG parsing, context-buffer control, other sampling ratios, IDCT, color conversion, and the complete cBench decoder remain outside the profile. Nine language ports are registered in the byte-output runner and independent verifier, which cover workload fixtures and generated dimension, malformed-input, null-output, and capacity cases. See the [guide](benchmarks/m/cbench_consumer_jpeg_h2v2_fancy_upsample/README.md), [workload](benchmarks/m/cbench_consumer_jpeg_h2v2_fancy_upsample/workload.json), and [oracle](benchmarks/cbench_consumer_jpeg_h2v2_fancy_upsample_oracle.py).

## Parboil TPACF cross-correlation histogram (`parboil_tpacf_cross_correlation`)

This bounded kernel pairs two Cartesian point sets, computes source-ordered binary32 dot products, and counts them in Parboil's 20 logarithmic angular bins. It produces a histogram, distinct from one-dimensional signal cross-correlation or spatial-neighbor search. See the [guide](benchmarks/p/parboil_tpacf_cross_correlation/README.md), [workload](benchmarks/p/parboil_tpacf_cross_correlation/workload.json), and [oracle](benchmarks/parboil_tpacf_cross_correlation_oracle.py).

## Parboil MRI-Q one-voxel Fourier accumulation (`parboil_mri_q`)

This package preserves Parboil MRI-Q's two-pass complex-magnitude preparation and source-order binary32 phase/Q recurrence for up to four k-space records at one voxel. It serializes the completed result as a pair of little-endian signed Q1000 integers, with the quantization boundary documented in the contract. It is distinct from TPACF's angular pair histogram; the full spatial grid, file loading, and reconstruction remain outside this profile. See the [guide](benchmarks/p/parboil_mri_q/README.md), [workload](benchmarks/p/parboil_mri_q/workload.json), and [oracle](benchmarks/parboil_mri_q_oracle.py).

## Parboil MRI Cartesian gridding (`parboil_mri_gridding`)

This bounded CPU kernel applies Parboil's non-LUT Kaiser-Bessel weighting to up to four already-mapped samples on a 3×3×3 grid, accumulating complex values and sample density before returning a Q1000-weighted checksum. It differs from MRI-Q's Fourier recurrence and TPACF's angular pair histogram. Nine clean-room ports retain the Illinois Open Source License and are registered in the array-scalar suite. See the [guide](benchmarks/p/parboil_mri_gridding/README.md), [workload](benchmarks/p/parboil_mri_gridding/workload.json), and [oracle](benchmarks/parboil_mri_gridding_oracle.py).

## Parboil cutcp cutoff-potential lattice (`parboil_cutcp`)

This bounded kernel maps up to four point charges onto a small 3D lattice, preserving Parboil's binary32 spatial-cell hash, reverse insertion-chain traversal, cutoff clipping, and source-order tapered q/r accumulation. It uses half-cell atom placement to avoid zero distance without adding a source-side guard, then serializes each completed potential as signed little-endian Q1000 i32. The package is distinct from MRI-Q Fourier accumulation and TPACF pair histograms; atom parsing and the subsequent `remove_exclusions` pass are excluded. Nine clean-room ports retain the Illinois license notice and are registered in the byte-output runner and independent verifier. See the [guide](benchmarks/p/parboil_cutcp/README.md), [workload](benchmarks/p/parboil_cutcp/workload.json), and [oracle](benchmarks/parboil_cutcp_oracle.py).

## Parboil SAD hierarchical motion search (`parboil_sad`)

This bounded video kernel compares one current 16×16 macroblock with the reference image at every source displacement in the 33×33 search window. It sums all seven hierarchical block-size SAD levels, including Parboil's edge-clamped reference coordinates and candidate order. This is distinct from local mean-absolute-error metrics, which compare aligned arrays without motion search or multi-level block aggregation. Nine clean-room ports retain the full Illinois Open Source License and are registered in the array-scalar suite. See the [guide](benchmarks/p/parboil_sad/README.md), [workload](benchmarks/p/parboil_sad/workload.json), and [oracle](benchmarks/parboil_sad_oracle.py).

## Parboil seven-point Laplacian stencil (`parboil_stencil_laplacian`)

This bounded 3D stencil repeats the pinned CPU source's binary32 seven-point Laplacian update on 3×3×3 through 5×5×5 grids while keeping boundary cells fixed. It preserves the x-fast layout, source traversal and neighbor order, and binary32 scaling. Its negative center coefficient and lack of a center-value carry distinguish it from local heat-diffusion and seven-point averaging kernels. Nine ports retain the Illinois Open Source License and are registered in the float64 slice suite. See the [guide](benchmarks/p/parboil_stencil_laplacian/README.md), [workload](benchmarks/p/parboil_stencil_laplacian/workload.json), and [oracle](benchmarks/parboil_stencil_laplacian_oracle.py).

## Parboil LBM D3Q19 stream/collide (`parboil_lbm`)

This bounded profile executes one source-ordered D3Q19 step on a 3×3×3 LDC grid with one fluid cell, collision and bounce-back boundaries, then returns a weighted fixed-point checksum. It preserves binary32 moment operations and the pinned double-macro equilibrium products; the source does not specify compiler floating-point flags, so the workload documents its assumed rounding behavior. Nine clean-room ports retain the Illinois Open Source License and are registered in the array-scalar suite. The reduced profile excludes full-grid setup, input files, repeated simulation, and timing. See the [guide](benchmarks/p/parboil_lbm/README.md), [workload](benchmarks/p/parboil_lbm/workload.json), and [oracle](benchmarks/parboil_lbm_oracle.py).

## Parboil histogram (`parboil_histo`)

This bounded standalone histogram clears and scans the same sample array on each requested pass, incrementing byte-sized bins up to 255. It exposes frequency counts as raw bytes and differs from histogram logic used internally by other image algorithms. Nine clean-room ports retain the Illinois Open Source License and are registered in the byte-output suite. See the [guide](benchmarks/p/parboil_histo/README.md), [workload](benchmarks/p/parboil_histo/workload.json), and [oracle](benchmarks/parboil_histo_oracle.py).

## Parboil JDS sparse matrix-vector product (`parboil_spmv_jds`)

This bounded kernel consumes validated Jagged Diagonal Storage, performs source-ordered binary32 multiply-accumulation by row rank, and scatters results through the row permutation. It is distinct from sparse-matrix format classification and dense matrix multiplication. Nine clean-room ports retain the Illinois Open Source License and are registered in the byte-output suite. COO parsing, symmetric conversion, file I/O, and repeated timing are outside the profile. See the [guide](benchmarks/p/parboil_spmv_jds/README.md), [workload](benchmarks/p/parboil_spmv_jds/workload.json), and [oracle](benchmarks/parboil_spmv_jds_oracle.py).

## PAQ8p bounded adaptive context mixer (`paq8p_context_mixer`)

This package isolates PAQ8p's nested adaptive Mixer using a bounded trace of caller-provided stretched features and binary context selectors. It preserves source fixed-point prediction, training, and update timing; context generation, the arithmetic coder, and the complete compressor remain outside scope. Nine ports retain the GPL-2.0-or-later terms and are registered in the byte-output suite. See the [guide](benchmarks/p/paq8p_context_mixer/README.md), [workload](benchmarks/p/paq8p_context_mixer/workload.json), and [oracle](benchmarks/paq8p_context_mixer_oracle.py).

## ParGeo bichromatic closest pair (`pargeo_bichromatic_closest_pair`)

This bounded 2D query builds one KD-tree per point color and uses squared AABB lower bounds to prune cross-tree closest-pair search. The integer profile measures the same bichromatic operation while keeping the result exact and bounded. Nine language ports retain the full MIT license and source attribution; the independent oracle uses direct all-pairs comparison. The package is registered in the byte-output suite. See the [guide](benchmarks/p/pargeo_bichromatic_closest_pair/README.md), [workload](benchmarks/p/pargeo_bichromatic_closest_pair/workload.json), and [oracle](benchmarks/pargeo_bichromatic_closest_pair_oracle.py).

## GraphAIBench GCN normalized-neighbor aggregation (`graphai_gcn_aggregation`)

This bounded CSR kernel computes per-vertex feature sums weighted by caller-supplied left and right inverse-degree normalization values. It preserves row and neighbor order, returns zero vectors for isolated vertices, and excludes graph loading, normalization setup, training, and GPU scheduling. Nine clean-room ports retain the pinned MIT notice and use the float64 slice ABI; the package oracle follows edge-first accumulation while the verifier independently reduces each feature row. See the [guide](benchmarks/g/graphai_gcn_aggregation/README.md), [workload](benchmarks/g/graphai_gcn_aggregation/workload.json), [oracle](benchmarks/graphai_gcn_aggregation_oracle.py), and [GraphAIBench crosswalk](benchmarks/GRAPHAIBENCH_COVERAGE.md).

## GraphAIBench GraphSAGE mean-neighbor aggregation (`graphai_sage_aggregation`)

This bounded CSR kernel computes each vertex's mean outgoing-neighbor feature vector in the source edge order, returning zeros for isolated vertices. It excludes graph loading, training, backpropagation, and parallel scheduling; its binary64 slice arithmetic is a precision projection of the source's float aggregator. Nine clean-room ports retain the pinned MIT notice and are registered in the float64 slice suite. See the [guide](benchmarks/g/graphai_sage_aggregation/README.md), [workload](benchmarks/g/graphai_sage_aggregation/workload.json), [oracle](benchmarks/graphai_sage_aggregation_oracle.py), and [GraphAIBench crosswalk](benchmarks/GRAPHAIBENCH_COVERAGE.md).

## GraphAIBench GAT attention aggregation (`graphai_gat_aggregation`)

This bounded CSR profile computes source and neighbor attention projections, applies the source's leaky-ReLU slope, normalizes scores with per-row softmax, and accumulates weighted neighbor features in edge order. It excludes training, dropout, weight initialization, and multi-head setup; nine clean-room ports retain the MIT notice and use the float64 slice suite with an independent verifier oracle. See the [guide](benchmarks/g/graphai_gat_aggregation/README.md), [workload](benchmarks/g/graphai_gat_aggregation/workload.json), [oracle](benchmarks/graphai_gat_aggregation_oracle.py), and [GraphAIBench crosswalk](benchmarks/GRAPHAIBENCH_COVERAGE.md).

## GraphAIBench deterministic frontier sampler (`graphai_frontier_sampler`)

This profile expands input roots through three ordered CSR frontiers using explicit per-child edge choices, returning every sampled vertex. It retains the source's branching-with-replacement operation while bounding the source fanouts 15/10/10 to 3/2/2 so output fits the suite ABI; process-global randomness and subgraph materialization are excluded. Nine clean-room ports retain the MIT notice and are wired to the float64 slice suite with an independent verifier oracle. See the [guide](benchmarks/g/graphai_frontier_sampler/README.md), [workload](benchmarks/g/graphai_frontier_sampler/workload.json), [oracle](benchmarks/graphai_frontier_sampler_oracle.py), and [GraphAIBench crosswalk](benchmarks/GRAPHAIBENCH_COVERAGE.md).

## GraphAIBench collaborative-filtering SGD sweep (`graphai_cf_sgd_sweep`)

This bounded profile performs one synchronous user-to-item rating residual pass, accumulates user factor errors in CSR order, and applies the source's regularized update to every factor from the pre-sweep matrix. It supplies deterministic initial factors, reduces the source's K=20 to k≤4, and runs one sweep in place of the default multi-iteration training loop. Nine clean-room ports retain the MIT notice and use the float64 slice suite with an independent verifier. See the [guide](benchmarks/g/graphai_cf_sgd_sweep/README.md), [workload](benchmarks/g/graphai_cf_sgd_sweep/workload.json), [oracle](benchmarks/graphai_cf_sgd_sweep_oracle.py), and [GraphAIBench crosswalk](benchmarks/GRAPHAIBENCH_COVERAGE.md).

## GraphAIBench complete-linkage graph HAC (`graphai_hac_complete_linkage`)

This bounded profile repeatedly merges the active cluster pair with the highest similarity, preserving one-sided edges and applying minimum linkage to shared neighbors. It returns the source-shaped parent/similarity record for each dendrogram node. Connected simple graphs have at most eight vertices and pairwise-distinct integer edge weights, so the ports can replace the source heap with a deterministic full scan without merge-score ties. Nine clean-room ports retain GraphAIBench's MIT notice and use the byte-output ABI; the package oracle uses original-vertex cluster sets, while the independent verifier updates a dense quotient matrix. See the [guide](benchmarks/g/graphai_hac_complete_linkage/README.md), [workload](benchmarks/g/graphai_hac_complete_linkage/workload.json), [oracle](benchmarks/graphai_hac_complete_linkage_oracle.py), and [GraphAIBench crosswalk](benchmarks/GRAPHAIBENCH_COVERAGE.md).

## MediaBench IJG JPEG optimal Huffman table (`mediabench_jpeg_optimal_huffman_table`)

This package isolates IJG JPEG 6a's optimal Huffman table generation from sparse symbol-frequency counts, including the pseudo-symbol, source tie order, 16-bit length limiting, and source-ordered output symbols. It does not encode image blocks or produce JPEG files. Nine language ports preserve the IJG attribution and redistribution terms and are registered in the byte-output suite. See the [guide](benchmarks/m/mediabench_jpeg_optimal_huffman_table/README.md), [workload](benchmarks/m/mediabench_jpeg_optimal_huffman_table/workload.json), and [oracle](benchmarks/mediabench_jpeg_optimal_huffman_table_oracle.py).

## GAPBS ordered triangle count (`gapbs_ordered_triangle_count`)

This bounded graph kernel counts each unordered triangle once using the pinned GAPBS `OrderedCount` neighbor-intersection traversal on simple undirected graphs. The contract supplies adjacency matrices and omits the source's degree-based relabel heuristic. Nine ports and scalar runner/verifier integration are included with the BSD-3-Clause source notice. See the [guide](benchmarks/t/gapbs_ordered_triangle_count/README.md), [workload](benchmarks/t/gapbs_ordered_triangle_count/workload.json), and [oracle](benchmarks/gapbs_ordered_triangle_count_oracle.py).

## GAPBS Brandes betweenness centrality (`gapbs_betweenness_centrality`)

This bounded graph kernel runs unweighted Brandes BFS and reverse dependency accumulation for an explicit ordered source list, then returns a quantized vertex-weighted checksum. It is separate from minimum-eccentricity graph centrality and from triangle counting. Nine language ports are registered in the scalar suite with the BSD-3-Clause source notice. See the [guide](benchmarks/b/gapbs_betweenness_centrality/README.md), [workload](benchmarks/b/gapbs_betweenness_centrality/workload.json), and [oracle](benchmarks/gapbs_betweenness_centrality_oracle.py).

## GAPBS delta-stepping single-source shortest paths (`gapbs_delta_step_sssp`)

This bounded directed shortest-path kernel preserves GAPBS's distinct δ-stepping bucket schedule, including repeated relaxation within the current delta bucket and stale-entry checks. It returns all source distances as little-endian i64 values alongside the existing Dijkstra and Bellman–Ford profiles. Nine language ports are registered in the byte-output suite with the BSD-3-Clause source notice; the independent oracle uses Bellman–Ford. See the [guide](benchmarks/d/gapbs_delta_step_sssp/README.md), [workload](benchmarks/d/gapbs_delta_step_sssp/workload.json), and [oracle](benchmarks/gapbs_delta_step_sssp_oracle.py).

## GAPBS Afforest connected components (`gapbs_afforest_components`)

This bounded undirected-graph profile preserves Afforest's sampled-neighbor linking, pointer compression, frequent-sample selection, and final edge pass, with caller-supplied deterministic samples and a guard that keeps the bounded skip exact. It returns the minimum vertex ID for every connected component as little-endian i64 labels. Nine ports retain the BSD-3-Clause notice and are registered in the byte-output suite; the independent verifier uses disjoint sets rather than Afforest or the package oracle's traversal. See the [guide](benchmarks/a/gapbs_afforest_components/README.md), [workload](benchmarks/a/gapbs_afforest_components/workload.json), and [oracle](benchmarks/gapbs_afforest_components_oracle.py).

## GAPBS Shiloach–Vishkin connected components (`gapbs_shiloach_vishkin_components`)

This bounded undirected-graph profile preserves GAPBS Shiloach–Vishkin's min-max root hooking and parent compression with deterministic single-worker scan order. It returns the minimum vertex ID for each component as little-endian i64 labels. Nine ports retain the BSD-3-Clause notice and are registered in the byte-output suite; the independent verifier uses disjoint sets rather than the package's stack traversal or the source's hook sweeps. See the [guide](benchmarks/a/gapbs_shiloach_vishkin_components/README.md), [workload](benchmarks/a/gapbs_shiloach_vishkin_components/workload.json), and [oracle](benchmarks/gapbs_shiloach_vishkin_components_oracle.py).

## GAPBS pull Gauss–Seidel PageRank (`gapbs_pagerank_pull_gs`)

This bounded directed-graph profile preserves GAPBS `PageRankPullGS`'s in-place binary32 update order, making it distinct from the repository's synchronous binary64 PageRank profiles. It returns a weighted scalar checksum after exactly the requested number of iterations. Nine language ports are registered in the scalar suite with the BSD-3-Clause source notice; the independent verifier rounds every binary32 state update. See the [guide](benchmarks/p/gapbs_pagerank_pull_gs/README.md), [workload](benchmarks/p/gapbs_pagerank_pull_gs/workload.json), and [oracle](benchmarks/gapbs_pagerank_pull_gs_oracle.py).

## SAGA-Bench incremental graph analytics (`saga_incremental_analytics`)

This bounded insertion-only profile exposes SAGA's six incremental update modes: BFS, weighted SSSP, PageRank, minimum-label connected components, widest paths, and maximum-label components. Each call receives a mode-valid pre-state for the base graph, or an all-`-1` fresh state only when the base graph has no edges, then repairs state after inserting an edge batch. The ABI validates numeric framing; state validity is a caller precondition, and the workload validator checks each successful fixture against its base-graph state. Nine ports and an independent oracle are registered in the byte-output suite with the SAGA BSD-2-Clause notice. See the [guide](benchmarks/s/saga_incremental_analytics/README.md), [workload](benchmarks/s/saga_incremental_analytics/workload.json), [oracle](benchmarks/saga_incremental_analytics_oracle.py), and [SAGA crosswalk](benchmarks/SAGA_BENCH_COVERAGE.md).

## MAFFT Falign FFT lag correlation (`mafft_falign_fft_lag_correlation`)

This package isolates MAFFT's launcher-default `fftscore=1` profile: one complex feature per residue from standardized Miyata polarity and volume, followed by FFT cross-correlation and source lag ordering. It returns the bounded score profile before anchor extraction and alignment DP. Nine ports retain the BSD notice and are registered in the float64 slice suite; the independent oracle uses direct lag sums. See the [guide](benchmarks/m/mafft_falign_fft_lag_correlation/README.md), [workload](benchmarks/m/mafft_falign_fft_lag_correlation/workload.json), and [oracle](benchmarks/mafft_falign_fft_lag_correlation_oracle.py).

## BEEBS masked bit compression (`beebs_bit_compress`)

This bounded 32-bit bit-gather operation packs data bits selected by an arbitrary mask into consecutive low-order result positions. BEEBS `compress1` through `compress4` are four implementations of the same core; they are represented by one package and remain distinct from [`select_bits`](benchmarks/s/select_bits/README.md), which extracts a contiguous bit interval. Nine clean-room ports retain the GPL-3.0-or-later source notice and are registered in the i64 array-scalar suite. See the [guide](benchmarks/b/beebs_bit_compress/README.md), [workload](benchmarks/b/beebs_bit_compress/workload.json), [oracle](benchmarks/beebs_bit_compress_oracle.py), and [BEEBS crosswalk](benchmarks/BEEBS_COVERAGE.md).

## BEEBS Nettle CAST-128 one-block encryption (`beebs_nettle_cast128`)

This bounded profile expands a 128-bit key and encrypts one 64-bit block in CAST-128 ECB mode without padding or chaining. It is a distinct cipher from the local AES, DES/3DES, Blowfish, IDEA, TEA, and stream-cipher profiles. Nine clean-room ports use the RFC 2144 algorithm and S-box tables without copying Nettle or BEEBS implementation text; package attribution records the pinned BEEBS GPL-3.0-or-later file notice and RFC royalty-free statement. It is registered in the byte-output suite. See the [guide](benchmarks/b/beebs_nettle_cast128/README.md), [workload](benchmarks/b/beebs_nettle_cast128/workload.json), [oracle](benchmarks/beebs_nettle_cast128_oracle.py), and [BEEBS crosswalk](benchmarks/BEEBS_COVERAGE.md).

## BEEBS LCD digit-to-segment lookup (`beebs_lcdnum`)

This bounded profile maps five raw byte values through the pinned LCD seven-segment table after masking each with `0x0f`, returning five masks in source order. It makes the first five conversions explicit output bytes; the source's volatile port scans, last five ignored scans, and absent output verifier are harness exclusions. Nine clean-room ports retain the pinned GPL-3.0-or-later attribution and are registered in the byte-output suite. See the [guide](benchmarks/l/beebs_lcdnum/README.md), [workload](benchmarks/l/beebs_lcdnum/workload.json), [oracle](benchmarks/beebs_lcdnum_oracle.py), and [BEEBS crosswalk](benchmarks/BEEBS_COVERAGE.md).

## BEEBS FASTA weighted sequence generation (`beebs_fasta`)

This package materializes the three FASTA records intended by the pinned BEEBS generator: a repeated ALU sequence of length `2n`, `3n` IUB weighted symbols, and `5n` human-frequency symbols. It preserves the source-order binary32 probability accumulation, the shared LCG stream, and 60-symbol line wrapping. The bounded profile accepts `[n, initial_lcg_state]` with `1≤n≤1000` and `0≤initial_lcg_state≤139967`, resetting the original static seed for each call. The source comments out both its headers and body writes and has no verifier, so this package explicitly exposes a projected byte stream rather than claiming that the benchmark emits or checks it. Nine clean-room ports retain both the source GPL-3.0-or-later license and the embedded Benchmark Game Revised BSD notice. See the [guide](benchmarks/f/beebs_fasta/README.md), [workload](benchmarks/f/beebs_fasta/workload.json), [oracle](benchmarks/beebs_fasta_oracle.py), and [BEEBS crosswalk](benchmarks/BEEBS_COVERAGE.md).

## GBBS single-source widest path (`gbbs_ss_widest_path`)

This bounded directed-graph profile computes the maximum bottleneck capacity from one source to every vertex using the max-min path algebra. It preserves GBBS `SSWidestPath`'s strict capacity-increase rule and monotone priority order in a deterministic single-worker projection, returning `INT32_MAX` for the source and zero for unreachable vertices. It is distinct from min-plus shortest paths such as Dijkstra and delta-stepping. Nine clean-room ports retain the pinned MIT license; the package oracle uses max-min closure and the independent verifier uses repeated edge relaxation. See the [guide](benchmarks/w/gbbs_ss_widest_path/README.md), [workload](benchmarks/w/gbbs_ss_widest_path/workload.json), [oracle](benchmarks/gbbs_ss_widest_path_oracle.py), and [GBBS crosswalk](benchmarks/GBBS_COVERAGE.md).

## GBBS k-core decomposition (`gbbs_k_core_decomposition`)

This bounded simple-undirected profile returns one core number per vertex by repeatedly removing the current minimum-degree shell and clamping surviving residual degrees to that shell value. It preserves the pinned `KCore` core-number update while replacing parallel degree buckets with deterministic sequential shell processing. Nine clean-room ports retain GBBS's MIT notice and are wired to the byte-output suite; the package oracle uses induced-subset search and the independent verifier uses threshold peeling. GraphAIBench's serial k-core entry is a stub, so both source families share this single kernel package. See the [guide](benchmarks/g/gbbs_k_core_decomposition/README.md), [workload](benchmarks/g/gbbs_k_core_decomposition/workload.json), [oracle](benchmarks/gbbs_k_core_decomposition_oracle.py), and [GBBS crosswalk](benchmarks/GBBS_COVERAGE.md).

## GBBS fixed four-clique count (`gbbs_k_clique_count`)

This profile counts every four-vertex clique once using GBBS's source-supported `-k 4 --directType ORIGINAL` orientation and outgoing-neighborhood intersections. It is distinct from triangle counting and maximal-clique enumeration. Nine clean-room ports retain the MIT notice and use the byte-output suite; the independent verifier enumerates vertex combinations against an adjacency matrix. See the [guide](benchmarks/g/gbbs_k_clique_count/README.md), [workload](benchmarks/g/gbbs_k_clique_count/workload.json), [oracle](benchmarks/gbbs_k_clique_count_oracle.py), and [GBBS crosswalk](benchmarks/GBBS_COVERAGE.md).

## GBBS label-propagation clustering (`gbbs_label_propagation_clustering`)

This bounded one-sweep profile initializes each vertex label to its ID, visits vertices in ascending order, and immediately updates each non-isolate to its most frequent current neighbor label, using the greatest label to break ties. It preserves the source's asynchronous update rule while fixing a deterministic serial order and one iteration. Nine clean-room ports retain the MIT notice and use the byte-output suite; the independent verifier uses dense adjacency counts. See the [guide](benchmarks/g/gbbs_label_propagation_clustering/README.md), [workload](benchmarks/g/gbbs_label_propagation_clustering/workload.json), [oracle](benchmarks/gbbs_label_propagation_clustering_oracle.py), and [GBBS crosswalk](benchmarks/GBBS_COVERAGE.md).

## GBBS undirected five-cycle count (`gbbs_five_cycle_count`)

This exact kernel counts each simple undirected five-cycle once up to rotation and reversal. It is distinct from arbitrary-length directed cycle enumeration. Nine clean-room ports retain the MIT notice and use the byte-output suite; the independent verifier scans canonical paths from the edge set. See the [guide](benchmarks/g/gbbs_five_cycle_count/README.md), [workload](benchmarks/g/gbbs_five_cycle_count/workload.json), [oracle](benchmarks/gbbs_five_cycle_count_oracle.py), and [GBBS crosswalk](benchmarks/GBBS_COVERAGE.md).

## GBBS CoSimRank pair similarity (`gbbs_cosimrank_pair_similarity`)

This bounded directed profile advances two source probability vectors for up to four rounds and adds their inner product with discount 0.5. Outdegrees are restricted to 1, 2, or 4 so all state uses exact dyadic arithmetic; nine clean-room ports encode the score as one binary64 byte pattern. The MIT notice is retained, and the package is wired to the byte-output suite with an independent exact-rational verifier. See the [guide](benchmarks/g/gbbs_cosimrank_pair_similarity/README.md), [workload](benchmarks/g/gbbs_cosimrank_pair_similarity/workload.json), [oracle](benchmarks/gbbs_cosimrank_pair_similarity_oracle.py), and [GBBS crosswalk](benchmarks/GBBS_COVERAGE.md).

## GBBS Tarjan–Vishkin biconnectivity (`gbbs_biconnectivity`)

This bounded simple-undirected profile returns a canonical block label for every input edge, with bridges as one-edge blocks. It preserves the source's spanning-forest, preorder, low/high reachability, critical-edge removal, and residual-component stages while fixing deterministic traversal and labels. Nine clean-room ports retain GBBS's MIT notice and are registered in the byte-output suite; the independent verifier uses a separate edge-removal characterization. See the [guide](benchmarks/g/gbbs_biconnectivity/README.md), [workload](benchmarks/g/gbbs_biconnectivity/workload.json), [oracle](benchmarks/gbbs_biconnectivity_oracle.py), and [GBBS crosswalk](benchmarks/GBBS_COVERAGE.md).

## GBBS Charikar approximate densest subgraph (`gbbs_charikar_densest_subgraph`)

This bounded profile uses GBBS's minimum-degree shell order and returns the maximum average degree among its induced suffixes, preserving Charikar's 2-approximation operation. The BKV12 package uses a distinct simultaneous density-threshold peeling recurrence for the same density objective. Nine clean-room ports retain the MIT notice and use the float64 suite with an independent verifier. See the [guide](benchmarks/g/gbbs_charikar_densest_subgraph/README.md), [workload](benchmarks/g/gbbs_charikar_densest_subgraph/workload.json), [oracle](benchmarks/gbbs_charikar_densest_subgraph_oracle.py), and [GBBS crosswalk](benchmarks/GBBS_COVERAGE.md).

## GBBS BKV12 approximate densest subgraph (`gbbs_bkv12_densest_subgraph`)

This bounded profile measures induced average degree, removes all vertices at or below `(1+epsilon)` times that density in each round, and returns the largest round-boundary density. It differs from Charikar's minimum-degree shell order and suffix scan. Nine clean-room ports retain the MIT notice and use the float64 suite with an exact integer-threshold source oracle plus an active-induced-graph verifier. See the [guide](benchmarks/g/gbbs_bkv12_densest_subgraph/README.md), [workload](benchmarks/g/gbbs_bkv12_densest_subgraph/workload.json), [oracle](benchmarks/gbbs_bkv12_densest_subgraph_oracle.py), and [GBBS crosswalk](benchmarks/GBBS_COVERAGE.md).

## GBBS GreedyPlusPlus approximate densest subgraph (`gbbs_greedy_plus_plus_densest_subgraph`)

This bounded profile runs 20 adaptive-load degeneracy sweeps, increasing each vertex's persistent load by its later-neighbor count and scanning every suffix for average degree. Those repeated load updates distinguish it from Charikar's one-pass shell order and BKV12's threshold-selected batches. Nine clean-room ports retain the MIT notice and use the float64 suite with source-stage and independent active-set verifiers. See the [guide](benchmarks/g/gbbs_greedy_plus_plus_densest_subgraph/README.md), [workload](benchmarks/g/gbbs_greedy_plus_plus_densest_subgraph/workload.json), [oracle](benchmarks/gbbs_greedy_plus_plus_densest_subgraph_oracle.py), and [GBBS crosswalk](benchmarks/GBBS_COVERAGE.md).

## GBBS Goodrich–Pszona degeneracy ordering (`gbbs_goodrich_pszona_degeneracy_order`)

This bounded profile preserves the source's default `epsilon=0.001`; at the package's vertex bound the batch size is one, so it repeatedly removes the current minimum-degree vertex with deterministic ID ties and returns inverse ranks. Nine clean-room ports retain GBBS's MIT notice and are registered in the byte-output suite with an independent verifier. See the [guide](benchmarks/g/gbbs_goodrich_pszona_degeneracy_order/README.md), [workload](benchmarks/g/gbbs_goodrich_pszona_degeneracy_order/workload.json), [oracle](benchmarks/gbbs_goodrich_pszona_degeneracy_order_oracle.py), and [GBBS crosswalk](benchmarks/GBBS_COVERAGE.md).

## GBBS Barenboim–Elkin degeneracy ordering (`gbbs_barenboim_elkin_degeneracy_order`)

This bounded profile estimates density with the source's BKV12 routine, derives a degree cutoff using epsilon 0.1, removes all vertices below the cutoff in batches, and forces one removal when a batch is empty. It is distinct from Goodrich–Pszona's one-at-a-time minimum-degree ordering. Nine clean-room ports retain the MIT notice and are registered in the byte-output suite with source-stage and active-edge verifier models. See the [guide](benchmarks/g/gbbs_barenboim_elkin_degeneracy_order/README.md), [workload](benchmarks/g/gbbs_barenboim_elkin_degeneracy_order/workload.json), [oracle](benchmarks/gbbs_barenboim_elkin_degeneracy_order_oracle.py), and [GBBS crosswalk](benchmarks/GBBS_COVERAGE.md).

## GBBS randomized-greedy maximal matching (`gbbs_maximal_matching`)

This bounded graph profile makes GBBS's edge-priority greedy matching reproducible with an explicit total rank order. It returns a maximal matching, not a maximum-cardinality one; local Hopcroft–Karp and Kuhn profiles therefore have different objectives. Nine clean-room ports retain the MIT notice and use the byte-output suite with an independent round-based verifier. See the [guide](benchmarks/g/gbbs_maximal_matching/README.md), [workload](benchmarks/g/gbbs_maximal_matching/workload.json), [oracle](benchmarks/gbbs_maximal_matching_oracle.py), and [GBBS crosswalk](benchmarks/GBBS_COVERAGE.md).

## GBBS SCAN structural clustering (`gbbs_scan_structural_clustering`)

This bounded index-based SCAN profile finds core components by closed-neighborhood structural similarity, then attaches non-core vertices to their best eligible core. It is distinct from DBSCAN and label propagation. Nine clean-room ports retain the MIT notice and use the byte-output suite with an independent verifier. See the [guide](benchmarks/g/gbbs_scan_structural_clustering/README.md), [workload](benchmarks/g/gbbs_scan_structural_clustering/workload.json), [oracle](benchmarks/gbbs_scan_structural_clustering_oracle.py), and [GBBS crosswalk](benchmarks/GBBS_COVERAGE.md).

## GBBS Yoshida recursive MIS query (`gbbs_yoshida_query_mis`)

This package exposes one recursive query from GBBS Yoshida MIS, including its hash-derived vertex priorities, early exit, and cumulative visit cutoff with an explicit unknown result. It is distinct from Pannotia's local-minimum-priority rounds. Nine clean-room ports retain the MIT notice and use the byte-output suite with an independent work-count verifier. See the [guide](benchmarks/g/gbbs_yoshida_query_mis/README.md), [workload](benchmarks/g/gbbs_yoshida_query_mis/workload.json), [oracle](benchmarks/gbbs_yoshida_query_mis_oracle.py), and [GBBS crosswalk](benchmarks/GBBS_COVERAGE.md).

## GBBS approximate set cover (`gbbs_approximate_set_cover`)

This bounded profile preserves the MANISBPT11 highest-bucket refinement and winner-threshold selection on symmetric set-element masks, replacing each random permutation with a reproducible cyclic set-ID priority. It is distinct from graph minimum vertex cover. Nine clean-room ports retain GBBS's MIT notice and are registered in the byte-output suite with a source-shaped oracle plus independent element-to-winner verifier. See the [guide](benchmarks/g/gbbs_approximate_set_cover/README.md), [workload](benchmarks/g/gbbs_approximate_set_cover/workload.json), [oracle](benchmarks/gbbs_approximate_set_cover_oracle.py), and [GBBS crosswalk](benchmarks/GBBS_COVERAGE.md).

## GBBS MPX low-diameter decomposition (`gbbs_low_diameter_decomposition`)

This bounded profile preserves MPX's exponentially scheduled center batches and one-edge-per-round multi-source frontier growth, returning a center ID for each vertex. It fixes the launcher's beta at 0.2, disables optional permutation, and resolves same-round conflicts by lowest center ID. Nine clean-room ports retain the MIT notice and are registered in the byte-output suite with a source-stage oracle plus an independent all-pairs-distance verifier. See the [guide](benchmarks/g/gbbs_low_diameter_decomposition/README.md), [workload](benchmarks/g/gbbs_low_diameter_decomposition/workload.json), [oracle](benchmarks/gbbs_low_diameter_decomposition_oracle.py), and [GBBS crosswalk](benchmarks/GBBS_COVERAGE.md).

## GBBS Shiloach–Vishkin spanning forest (`gbbs_shiloach_vishkin_spanning_forest`)

This bounded simple-undirected profile records the input edge that witnesses each Shiloach–Vishkin min-root hook and returns a whole-graph forest edge mask. It shares a hooking recurrence with connected-components labeling but exposes distinct edge-witness output; weighted MST and single-source BFS tree profiles also have different contracts. Nine clean-room ports retain the MIT notice and are registered in the byte-output suite with source-stage and independent component-connectivity oracles. See the [guide](benchmarks/g/gbbs_shiloach_vishkin_spanning_forest/README.md), [workload](benchmarks/g/gbbs_shiloach_vishkin_spanning_forest/workload.json), [oracle](benchmarks/gbbs_shiloach_vishkin_spanning_forest_oracle.py), and [GBBS crosswalk](benchmarks/GBBS_COVERAGE.md).

## Pannotia local-minimum-priority maximal independent set (`pannotia_local_minimum_mis`)

This bounded profile implements Pannotia's simultaneous strict local-minimum priority rounds for MIS, equivalent to one increasing-priority greedy pass when priorities are distinct. The portable contract supplies the priority ordering explicitly in place of the runtime-specific `srand(7)` sequence. Nine language ports retain the full AMD notice and are registered in the byte-output suite; the verifier independently simulates active-set rounds. GBBS `RandomGreedy` maps to this same algorithm and is not a duplicate package. See the [guide](benchmarks/p/pannotia_local_minimum_mis/README.md), [workload](benchmarks/p/pannotia_local_minimum_mis/workload.json), [oracle](benchmarks/pannotia_local_minimum_mis_oracle.py), and [Pannotia crosswalk](benchmarks/PANNOTIA_COVERAGE.md).

## Pannotia priority-extrema graph coloring (`pannotia_priority_coloring`)

This package covers `coloring_max` and `coloring_maxmin` as two modes: each round colors strict local maxima, and maxmin also colors local minima with the adjacent color ID. Only colored vertices leave the uncolored graph, preserving the pinned kernels' round semantics; degree-one vertices are excluded because the source skips their neighbor comparison. Nine ports retain the full AMD notice and are registered in the byte-output suite with an independent dense-neighbor verifier. See the [guide](benchmarks/p/pannotia_priority_coloring/README.md), [workload](benchmarks/p/pannotia_priority_coloring/workload.json), [oracle](benchmarks/pannotia_priority_coloring_oracle.py), and [Pannotia crosswalk](benchmarks/PANNOTIA_COVERAGE.md).

## GARDENIA sparse symmetric Gauss–Seidel (`gardenia_symgs`)

This bounded CSR profile preserves GARDENIA's row order and forward/reverse color-class sweep schedule, using explicit matrix and starting vectors because the pinned host leaves its weights uninitialized. Nine clean-room ports retain the MIT notice and use the float64 slice suite with an independent verifier oracle. It differs from dense Gauss–Seidel and fixed-grid SOR/Seidel recurrences. See the [guide](benchmarks/g/gardenia_symgs/README.md), [workload](benchmarks/g/gardenia_symgs/workload.json), [oracle](benchmarks/gardenia_symgs_oracle.py), and [GARDENIA crosswalk](benchmarks/GARDENIA_COVERAGE.md).

## GARDENIA sequential matrix-factorization SGD (`gardenia_sgd`)

This bounded profile updates user and item factors immediately after every rating in ascending user and CSR row order, so later ratings use the already changed factors. That in-place recurrence differs from GraphAIBench's synchronous error accumulation and update sweep. Nine clean-room ports retain GARDENIA's MIT notice and use the float64 slice suite with an independent verifier oracle. See the [guide](benchmarks/g/gardenia_sgd/README.md), [workload](benchmarks/g/gardenia_sgd/workload.json), [oracle](benchmarks/gardenia_sgd_oracle.py), and [GARDENIA crosswalk](benchmarks/GARDENIA_COVERAGE.md).

## GARDENIA forward–backward–trim SCC (`gardenia_fb_trim_scc`)

This bounded directed-graph profile applies zero-in/out-degree trimming, deterministic pivot reachability, and recursive forward/backward partitioning to produce canonical SCC labels. It captures the documented FB-Trim kernel while excluding CUDA scheduling and hashing. Nine clean-room ports retain GARDENIA's MIT notice and are registered in the byte-output suite; an independent verifier checks mutual reachability. See the [guide](benchmarks/g/gardenia_fb_trim_scc/README.md), [workload](benchmarks/g/gardenia_fb_trim_scc/workload.json), [oracle](benchmarks/gardenia_fb_trim_scc_oracle.py), and [GARDENIA crosswalk](benchmarks/GARDENIA_COVERAGE.md).

## GARDENIA Gebremedhin–Manne graph coloring (`gardenia_gm_vertex_coloring`)

This bounded profile preserves iterative speculative first-fit coloring and conflict requeueing, with deterministic source-order phases. Nine clean-room ports retain GARDENIA's MIT notice and use the byte-output suite; its independent verifier applies a separate descending-order greedy coloring. See the [guide](benchmarks/g/gardenia_gm_vertex_coloring/README.md), [workload](benchmarks/g/gardenia_gm_vertex_coloring/workload.json), [oracle](benchmarks/gardenia_gm_vertex_coloring_oracle.py), and [GARDENIA crosswalk](benchmarks/GARDENIA_COVERAGE.md).

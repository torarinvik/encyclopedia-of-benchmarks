# Algorithm source inventory

Checked 2026-10-14 against pinned default-branch commits from 34 non-archived TheAlgorithms algorithm repositories. The inventory contains 6,158 source files and 3,831 normalized filename candidates. Of those, 865 names occur in at least two source repositories. Each source commit and file path is linked in [`catalog/algorithm-candidates.json`](catalog/algorithm-candidates.json).

## How to read this inventory

Each candidate is based on a normalized source filename, with camelCase converted to snake_case. The list is a discovery aid: matching filenames do not prove that implementations use the same algorithm, input contract, edge cases, or output. Unreviewed filename candidates remain marked `unreviewed_filename_match` in the JSON until their implementations are inspected. One hundred seventy filename candidates now have reviewed semantics and 125 unique benchmark contracts: nine search algorithms, thirty-one sorting algorithms, thirty-three scalar algorithms, twenty-one conversion algorithms, eight graph algorithms, one array algorithm, one tree traversal, one binary-search-tree operation algorithm, three combinatorial algorithms, five dynamic-programming algorithms, three string algorithms, one postfix-expression evaluation algorithm, one stack-operation algorithm, one queue-operation algorithm, one two-stack queue algorithm, one linked list operation algorithm, one doubly linked list operation algorithm, one trie operation algorithm, one segment-tree range-query operation algorithm, and one fractional-knapsack greedy algorithm. The `letter_combination` filename is recorded as an alias of `letter_combinations_of_phone_number`; `edit_distance`, `levenshtein`, and `levenshteindistance` alias `levenshtein_distance`; `coin_change_topdown` aliases `coin_change`; `lcs` aliases `longest_common_subsequence`; `decimal_to_any` aliases `decimal_to_any_base`; `int_to_base` and `base_x` alias `decimal_to_any_base`; `arbitrary_base` aliases `any_base_to_any_base`; `int_to_negative_binary_base` aliases `base_neg2_conversion`; and `prime_sieve`, `prime_sieve_eratosthenes`, `eratosthenes_sieve`, `sieve_er`, `sieve2`, and `odd_sieve` alias `sieve_of_eratosthenes`; `bogo_sorter` and `bogosort` alias `bogo_sort`; `greatest_common_divisor` aliases `gcd`; and `least_common_multiple` aliases `lcm`; `circular_queue` aliases `queue`; `singly_linked_list` aliases `linked_list`; `knapsack` aliases `knapsack_zero_one_tabulation` for its 0/1 variants; `fractional_knapsack_2` aliases `fractional_knapsack`. Tests, examples, benchmarks, documentation, scripts, build output, and vendor directories are omitted. Project Euler `solN` files include their problem number in the candidate name.

AArch64 Assembly paths are included only as discovery references. They are architecture-specific and are not portable benchmark implementations. Any benchmark derived from those algorithms still needs a portable implementation for each target.

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
| `pigeonhole_sort` | `c/`, `cpp/`, `rust/` | 8 |
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

## Tenth reviewed candidate: bubble sort

`bubble_sort` appears in 25 source repositories and in the direct C, C++, Rust, and Zig folders. The checked C and C++ versions compare adjacent elements, swap out-of-order pairs, and stop when a pass makes no swaps. The local ports preserve that stable ascending behavior over signed 64-bit values; see [`benchmarks/b/bubble_sort/README.md`](benchmarks/b/bubble_sort/README.md).

## Eleventh reviewed candidate: insertion sort

`insertion_sort` appears in 24 source repositories and in the direct C, C++, Rust, and Zig folders. The checked C and C++ versions maintain a sorted prefix by shifting larger values and inserting each key. Nine-language ports and the workload are in [`benchmarks/i/insertion_sort/README.md`](benchmarks/i/insertion_sort/README.md).

## Twelfth reviewed candidate: selection sort

`selection_sort` appears in 19 source repositories and in the direct C, Rust, and Zig folders. The checked C version selects the minimum value from each remaining suffix and swaps it into place. Its shared workload and nine-language ports are in [`benchmarks/s/selection_sort/README.md`](benchmarks/s/selection_sort/README.md).

## Thirteenth reviewed candidate: Shell sort

`shell_sort` appears in 15 source repositories and in the direct C, C++, and Rust folders. The checked C version uses a halving gap sequence; the local contract standardizes that sequence and in-place ascending sorting. See [`benchmarks/s/shell_sort/README.md`](benchmarks/s/shell_sort/README.md).

## Fourteenth reviewed candidate: Comb sort

`comb_sort` appears in 14 source repositories and in the direct C, C++, and Rust folders. The inspected C and C++ versions shrink the comparison gap by a factor near 1.3, with differing termination details. The local ports use an integer 10/13 shrink and finish after a gap-one pass makes no swaps. See [`benchmarks/c/comb_sort/README.md`](benchmarks/c/comb_sort/README.md).

## Fifteenth reviewed candidate: Gnome sort

`gnome_sort` appears in 16 source repositories and in the direct C, C++, and Rust folders. The C implementation can access before the first element; the C++ implementation guards that boundary. The local ports start at the first valid adjacent pair and preserve equal-value order. See [`benchmarks/g/gnome_sort/README.md`](benchmarks/g/gnome_sort/README.md).

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

`cycle_sort` appears in 10 source repositories and in the direct C, C++, and Rust folders. The inspected versions count smaller values to locate each item and rotate values through their destinations, while their APIs differ. The local ports use the same in-place signed 64-bit contract and guard duplicate skips. See [`benchmarks/c/cycle_sort/README.md`](benchmarks/c/cycle_sort/README.md).

## Twenty-second reviewed candidate: Stooge sort

`stooge_sort` appears in 8 source repositories and in the direct C, C++, and Rust folders. The inspected implementations compare range endpoints and recursively sort overlapping two-thirds ranges three times. The local workload uses small lengths because the algorithm grows at roughly `O(n^2.71)`. See [`benchmarks/s/stooge_sort/README.md`](benchmarks/s/stooge_sort/README.md).

## Twenty-third reviewed candidate: Merge sort

`merge_sort` appears in 26 source repositories and in the direct C, C++, Rust, and Zig folders. The inspected implementations use stable divide-and-conquer merging but allocate temporary storage differently. The local contract uses stable bottom-up passes and a reusable scratch buffer allocated outside timing. See [`benchmarks/m/merge_sort/README.md`](benchmarks/m/merge_sort/README.md).

## Twenty-fourth reviewed candidate: Counting sort

`counting_sort` appears in 13 source repositories and in the direct C, C++, and Rust folders. The inspected implementations differ in key domain and whether they mutate or return a new array. The local contract sorts signed 64-bit keys in `[-128, 128]` with a shared 257-counter histogram. See [`benchmarks/c/counting_sort/README.md`](benchmarks/c/counting_sort/README.md).

## Twenty-fifth reviewed candidate: Radix sort

`radix_sort` appears in 14 source repositories and in the direct C, C++, Rust, and Zig folders. The checked C and C++ examples use decimal passes on nonnegative integers, while Rust sorts unsigned values. The local ports use stable byte-wise passes with a sign-order transform for signed 64-bit keys. See [`benchmarks/r/radix_sort/README.md`](benchmarks/r/radix_sort/README.md).

## Twenty-sixth reviewed candidate: Bucket sort

`bucket_sort` appears in 10 source repositories and in the direct C, C++, and Rust folders. The inspected implementations use fixed integer buckets, normalized floating-point buckets, and input-sized buckets for nonnegative integers, respectively. The local ports use 256 stable buckets keyed by the high byte of an order-preserving signed 64-bit representation, then insertion-sort each bucket. See [`benchmarks/b/bucket_sort/README.md`](benchmarks/b/bucket_sort/README.md).

## Target folders without a source repository

The current source snapshot has no matching TheAlgorithms repository for `c3/`, `odin/`, or `v/`. Elisa is a custom language whose compiler lives in the neighboring `Elisa-compiler` project, and it also has no upstream collection. These folders need ports for whichever candidates we select. The direct source matches are limited to C, C++, Nim, Rust, and Zig.

## Next inventory pass

Continue promoting filename candidates to confirmed algorithms by checking source behavior and contracts. Then define shared workloads, record source and license details, and add ports where the selected target language has no suitable implementation.

[`catalog/coverage.py`](catalog/coverage.py) audits every candidate against all nine implementation paths and its guide/workload, resolving documented aliases to their canonical benchmark. Run `python3 catalog/coverage.py --output build/catalog-coverage.json` for the complete backlog. `--require-complete` fails while any candidate still needs review or files. This is a file and review audit; runtime correctness and discovery of multiple algorithms within an upstream file still need their own evidence.

## Twenty-seventh reviewed candidate: Bead sort

`bead_sort` appears in nine source repositories, including an AArch64 assembly example, and in the direct C, C++, and Rust folders. The inspected C and C++ implementations allocate a bead matrix, while Rust uses nested vectors; all require nonnegative values. The local ports keep the bead-height and gravity model for values in `[0, 63]`, using 64 reusable counters across all nine languages. See [`benchmarks/b/bead_sort/README.md`](benchmarks/b/bead_sort/README.md).

## Twenty-eighth reviewed candidate: Pigeonhole sort

`pigeonhole_sort` appears in eight source repositories and in the direct C, C++, and Rust folders. C discovers the range dynamically, C++ returns a fixed-size array and uses a zero sentinel, and Rust allocates separate hole and repeat vectors. The local ports use 257 counters for the shared signed key range `[-128, 128]`. See [`benchmarks/p/pigeonhole_sort/README.md`](benchmarks/p/pigeonhole_sort/README.md).

## Twenty-ninth reviewed candidate: Strand sort

`strand_sort` appears in six source repositories and in the direct C++ and Rust folders. The checked implementations extract nondecreasing subsequences and merge each into an accumulated sorted result. The local ports use flat arrays and a caller-provided strand buffer, allocated outside timing. See [`benchmarks/s/strand_sort/README.md`](benchmarks/s/strand_sort/README.md).

## Thirtieth reviewed candidate: Cocktail sort

`cocktail_sort` appears in seven source repositories, including an AArch64 assembly example, and directly in the C folder. The C implementation makes forward and backward adjacent-swap passes, shrinks the active bounds, and stops when a pass makes no swaps. The local ports use the same stable bidirectional strategy across all nine target languages. See [`benchmarks/c/cocktail_sort/README.md`](benchmarks/c/cocktail_sort/README.md).

## Thirty-first reviewed candidate: Cocktail shaker sort

`cocktail_shaker_sort` appears in four source repositories and directly in Rust. It uses the same bidirectional adjacent-swap family as `cocktail_sort`, but the inspected Rust source scans the full range each round instead of shrinking bounds. The local entry preserves the upstream name and implementation pattern across all nine target languages. See [`benchmarks/c/cocktail_shaker_sort/README.md`](benchmarks/c/cocktail_shaker_sort/README.md).

## Thirty-second reviewed candidate: Bitonic sort

`bitonic_sort` appears in six source repositories and directly in the C++ and Rust folders. The inspected implementations use recursive compare-and-swap merges and require power-of-two input lengths. The local ports preserve that constraint and expose one ascending in-place contract across all nine target languages. See [`benchmarks/b/bitonic_sort/README.md`](benchmarks/b/bitonic_sort/README.md).


## Thirty-third reviewed candidate: Exchange sort

`exchange_sort` appears in four source repositories and directly in Rust. The inspected Rust implementation compares each element with every later element and immediately swaps when that later value is smaller. Nine-language ports preserve this exchange pattern under the shared signed 64-bit in-place contract. See [exchange_sort guide](benchmarks/e/exchange_sort/README.md).

## Thirty-fourth reviewed candidate: Recursive selection sort

`selection_sort_recursive` appears in four source repositories and directly in C and C++. The inspected implementations recursively find the minimum in the active suffix, place it at the front, and recurse on the remaining suffix. The benchmark keeps both recursive steps and caps workload length at 256 to bound stack depth. See [recursive selection sort guide](benchmarks/s/selection_sort_recursive/README.md).


## Thirty-fifth reviewed candidate: Introsort

`intro_sort` appears in four source repositories and directly in Rust. The inspected implementation combines quicksort partitioning, insertion sort for short ranges, and heapsort when the recursion budget expires. The local ports calculate the shared 2 floor(log2(n)) depth budget using integer operations so every language uses the same portable rule. See [the introsort guide](benchmarks/i/intro_sort/README.md).

## Thirty-sixth reviewed candidate: Dutch national flag sort

`dutch_national_flag_sort` appears in four source repositories and directly in Rust. The inspected Rust and Python versions use a three-way partition for the values 0, 1, and 2. The local contract preserves that domain restriction and provides nine in-place ports. See [the Dutch national flag sort guide](benchmarks/d/dutch_national_flag_sort/README.md).


## Thirty-seventh reviewed candidate: Tim sort

`tim_sort` appears in eight source repositories and directly in C++ and Rust. The inspected C++ source insertion-sorts runs of 32 before merging them bottom-up; the Rust implementation also uses insertion runs and merges, with a different run-size calculation. The shared nine-language contract follows the explicit 32-item C++ structure and allocates one reusable scratch buffer before timing. See [the Tim sort guide](benchmarks/t/tim_sort/README.md).


## Thirty-eighth reviewed candidate: Recursive bubble sort

`recursive_bubble_sort` appears in three source repositories and directly in C++. The inspected implementation performs an adjacent-swap pass, then recurses on the shorter prefix without an early-exit check. The shared workload caps the recursive length at 256. See [the recursive bubble sort guide](benchmarks/r/recursive_bubble_sort/README.md).

## Thirty-ninth reviewed candidate: Circle sort

`circle_sort` appears in three source repositories, including Java and Python. The inspected versions compare mirrored elements in recursive halves and repeat full passes until no swaps occur. Nine-language ports use the same ascending signed 64-bit contract. See [the circle sort guide](benchmarks/c/circle_sort/README.md).

## Fortieth reviewed candidate: Factorial

`factorial` appears in 22 source repositories, including C, C++, Rust, and Zig. The inspected C example prints arbitrary-precision digits, while C++ uses recursion and limits its input to 20. The shared scalar contract returns exact signed 64-bit results for `0..20` and `-1` outside that range. Nine-language iterative ports and an explicit workload are in [the factorial guide](benchmarks/f/factorial/README.md).

## Forty-first reviewed candidate: Fibonacci

`fibonacci` appears in 20 source repositories, including C, C++, and Rust. Their indexing conventions and variants differ: the C example uses a one-based argument and naive recursion, C++ uses zero-based naive recursion, and Rust contains several variants. The shared scalar contract defines `F(0) = 0`, `F(1) = 1`, computes through `F(92)` in signed 64-bit arithmetic, and returns `-1` outside that input range. See [the Fibonacci guide](benchmarks/f/fibonacci/README.md).

## Forty-second reviewed candidate: Aliquot sum

`aliquot_sum` appears in 12 source repositories, including C++, Nim, and Rust. The reviewed implementations scan all candidate proper divisors, with different input types and zero behavior. Nine-language ports preserve that scan and define signed 64-bit results, zero and one, negative input, and accumulator overflow. See [the aliquot sum guide](benchmarks/a/aliquot_sum/README.md).

## Forty-third reviewed candidate: Armstrong number

`armstrong_number` appears in 12 source repositories, including C, C++, and Rust. The reviewed implementations use different integer widths and integer or floating-point exponentiation. The nine local ports use exact decimal digit powers across the signed 64-bit input range and prevent sum overflow. See [the Armstrong number guide](benchmarks/a/armstrong_number/README.md).

## Forty-fourth reviewed candidate: Bellman–Ford

`bellman_ford` appears in 11 source repositories, including C, C++, and Rust. The inspected implementations use different graph representations and integer/result conventions. The shared directed edge-list contract reports source-reachable negative cycles and signed 64-bit addition overflow explicitly, and keeps reachability separate from distance storage. All nine target-language ports pass the same graph corpus. See [the Bellman–Ford guide](benchmarks/b/bellman_ford/README.md).

## Forty-fifth reviewed candidate: Dijkstra

`dijkstra` appears in 10 source repositories and directly in C, C++, and Rust. The inspected sources use adjacency-matrix selection, a priority queue, and an ordered set, respectively. The local flat-edge-list contract uses nonnegative signed 64-bit weights, separate reachability flags, and checked distance addition; it rejects negative weights and gives all nine ports the same no-allocation selection variant. See [the Dijkstra guide](benchmarks/d/dijkstra/README.md).

## Forty-sixth reviewed candidate: Hamming distance

`hamming_distance` appears in 13 source repositories, including direct C, C++, and Rust files. The C source implements the string form, while C++ and Rust also provide an unsigned 64-bit integer form. The shared contract selects the bitwise integer variant, counts all 64 positions, and records two unsigned inputs. Nine portable implementations and a binary-scalar verifier are in [the Hamming distance guide](benchmarks/h/hamming_distance/README.md).

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

The inspected TheAlgorithms sources under `edit_distance`, `levenshtein_distance`, `levenshtein`, and `levenshteindistance` names all compute unit-cost insertion, deletion, and substitution distance. The Go source exposes weights, which are fixed to one for this benchmark. Its ASCII-byte contract makes the source languages' byte and character indexing agree; adjacent transpositions remain a separate Damerau–Levenshtein algorithm. The nine ports passed 4,531 oracle inputs, including every pair of binary strings through length five, random pairs, malformed encodings, and maximum-length inputs. The `levenshtein` and `levenshteindistance` candidate filenames share this one contract. See [the Levenshtein distance guide](benchmarks/l/levenshtein_distance/README.md).

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

Four TheAlgorithms repositories contain an `is_even` implementation. The inspected Java source uses a bit test, while JavaScript, Python, and TypeScript use parity or validate integer inputs. The shared contract returns `1` for even and `0` for odd signed 64-bit integers, including `INT64_MIN`. All nine ports are checked against dense and deterministic full-width inputs. See [the is-even guide](benchmarks/i/is_even/README.md).

## Sixty-third reviewed benchmark algorithm: Decimal to binary

Eleven TheAlgorithms repositories contain a `decimal_to_binary` implementation, including two C++ repositories. They convert by division/remainder, bit operations, or recursive decomposition; zero and negative-input behavior varies. The shared contract writes binary digits for nonnegative signed 64-bit inputs into a caller-provided byte buffer. All nine ports include `INT64_MAX` and reject negatives. See [the decimal-to-binary guide](benchmarks/d/decimal_to_binary/README.md).

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

The binomial coefficient appears in six pinned source repositories. Their implementations include Pascal-triangle, recursive, and multiplicative formulations. The local contract uses the standard `C(n,k)` definition, returns 0 when `k > n`, and bounds `n` at 66 so every exact result fits signed 64-bit output. All nine ports passed 5,057 pairs against Python's arbitrary-precision `math.comb`. See [the binomial-coefficient guide](benchmarks/b/binomial_coefficient/README.md).

## Seventy-ninth reviewed benchmark algorithm: Find minimum

The `find_min` candidate appears in seven source repositories. The inspected Python source provides iterative and recursive scans, while the Dart example prints the result and assumes a nonempty list. The local contract scans signed 64-bit arrays of up to 512 values and returns the minimum. All nine ports passed 4,432 oracle arrays, including signed boundaries and invalid lengths. See [the find-minimum guide](benchmarks/f/find_min/README.md).

## Eightieth reviewed benchmark algorithm: Find maximum

The `find_max` candidate appears in five source repositories. The inspected Python source provides iterative and divide-and-conquer scans and rejects empty lists. The local contract scans signed 64-bit arrays of up to 512 values and returns the maximum. All nine ports passed 4,432 oracle arrays, including signed boundaries and invalid lengths. See [the find-maximum guide](benchmarks/f/find_max/README.md).

## Eighty-first reviewed benchmark algorithm: Decimal to octal

Six pinned repositories contain decimal-to-octal conversion sources. They vary in prefix and negative-input behavior; the C console implementation also does not print zero. The local byte-output contract emits prefix-free octal digits for nonnegative signed 64-bit inputs, with explicit negative and buffer-capacity results. All nine ports passed 4,620 oracle inputs. See [the decimal-to-octal guide](benchmarks/d/decimal_to_octal/README.md).

## Eighty-second reviewed benchmark algorithm: Decimal to hexadecimal

Six pinned repositories contain decimal-to-hexadecimal conversion sources. The local contract normalizes case and prefix differences to lowercase, prefix-free digits for nonnegative signed 64-bit inputs and uses the shared byte-output ABI. All nine ports passed 4,621 oracle inputs. See [the decimal-to-hexadecimal guide](benchmarks/d/decimal_to_hexadecimal/README.md).

## Eighty-third reviewed benchmark algorithm: Octal to decimal

Six pinned repositories contain octal-to-decimal conversion sources. Their interfaces range from strings to numeric digit encodings; the shared contract uses a most-significant-first array of octal digits, validates each digit, and caps the length at 21 so the result fits signed 64-bit. All nine ports passed 5,117 oracle arrays, including exhaustive short inputs, deterministic random values, malformed digits, and the maximum result. See [the octal-to-decimal guide](benchmarks/o/octal_to_decimal/README.md).

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

The pinned C and C++ sources initialize an adjacency matrix and apply the triple-loop recurrence; Rust returns a map of all-pairs distances. The benchmark normalizes these graph APIs to a bounded edge-list input and a requested source row, with checked signed 64-bit arithmetic and reachable negative-cycle errors. All nine portable ports pass exhaustive small-graph and deterministic larger-graph checks. See [the Floyd–Warshall guide](benchmarks/f/floyd_warshall/README.md).


## One hundred first reviewed benchmark algorithm: Topological sort

The pinned C and C++ sources use visited-only depth-first postorder and do not reliably reject cycles; the C implementation also uses a fixed 40-node stack. The pinned Rust source uses Kahn's algorithm and reports cycles. The benchmark fixes a portable graph-order contract with deterministic FIFO Kahn ordering, coalesced duplicate edges, and explicit cycle handling. All nine language ports passed exhaustive graphs through three vertices, randomized graph cases, malformed inputs, and maximum-size workloads. See [the topological-sort guide](benchmarks/t/topological_sort/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/graphs/topological_sort.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/topological_sort.cpp), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/topological_sort.rs).


## One hundred second reviewed benchmark algorithm: Breadth-first search

The pinned C++ source supports directed or bidirectional edges and returns the visited set; the Rust source returns traversal history only through a requested target. The local contract standardizes a full directed traversal from a selected start, with ascending-neighbor order and byte-encoded output. The verifier exhausts all directed graphs through three vertices for every start and checks random, malformed, and boundary cases across nine languages. See [the breadth-first-search guide](benchmarks/b/breadth_first_search/README.md). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/breadth_first_search.cpp) and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/breadth_first_search.rs).

## One hundred third reviewed benchmark algorithm: Depth-first search

The pinned C++ source recursively traverses an undirected graph; the Rust implementation named DFS uses a deque as a stack and stops at a requested target. The local contract provides a full directed traversal in recursive preorder, encoded as vertex bytes. All nine ports are checked against exhaustive small graphs and deterministic larger inputs. See [the depth-first-search guide](benchmarks/d/depth_first_search/README.md). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/depth_first_search.cpp) and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/depth_first_search.rs).


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

The pinned inventory finds doubly linked list implementations in 14 repositories. They share a bidirectional linked structure, but expose different combinations of positional insertion/deletion, operations at either end, removal by value, search, reversal, and size. The benchmark normalizes common list operations to append, prepend, pop from either end, remove the first matching value, contains, and length. It uses a bounded index-based node pool with a free list to keep the representation portable across all nine target languages. All nine implementations passed 4,902 oracle traces and recorded 21 workload cases each. See [the doubly linked list guide](benchmarks/d/doubly_linked_list/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/linked_list/doubly_linked_list.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/doubly_linked_list.cpp), [C++ additional repository](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/doubly_linked_list.cpp), [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/LinkedList/DoublyLinkedList/DoublyLinkedList.cs), [Elixir](https://github.com/TheAlgorithms/Elixir/blob/6212e7e905ec2d2687e7f6e9e4b07b7fabb40f19/lib/data_structures/doubly_linked_list.ex), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/DoublyLinkedList.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Linked-List/DoublyLinkedList.js), [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/DoublyLinkedList.php), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/doubly_linked_list.py), [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/linked_list_algorithms/doubly_linked_list.r), [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/linked_lists/doubly_linked_list.rb), [Swift](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/data_structures/doubly_linked_list/DoublyLinkedList.swift), [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/list/doubly_linked_list.ts), [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/dataStructures/doublyLinkedList.zig).

## One hundred twentieth reviewed benchmark algorithm: Linked list

The pinned `linked_list` sources include singly linked lists, doubly linked lists, and an interface; the `singly_linked_list` candidate includes nine additional repositories. Their APIs range from head and tail insertion and deletion to indexed access, search, and reversal. The canonical benchmark standardizes a shared operation trace over a bounded singly linked node pool; removing the tail walks the forward links to find its predecessor. `singly_linked_list` aliases this contract to share one workload. All nine portable implementations passed 4,902 oracle traces and recorded 21 workload cases each. See [the linked list guide](benchmarks/l/linked_list/README.md). Upstream references cover each of the 18 pinned source files: [C-Plus-Plus](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/linked_list.cpp), [C++ additional repository](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/linked_list.cpp), [Clojure](https://github.com/TheAlgorithms/Clojure/blob/a9c5bec14928cb22fd4d69e951edf5bd15e16a18/src/data_structures/lists/linked_list.clj), [Dart](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/data_structures/linked_list/linked_list.dart), [Julia](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/data_structures/linked_list.jl), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/linked_list.rs), [Swift](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/data_structures/Linked%20List/LinkedList.swift), [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/list/linked_list.ts), [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/dataStructures/linkedList.zig), [C-Sharp](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/LinkedList/SinglyLinkedList/SinglyLinkedList.cs), [Elixir](https://github.com/TheAlgorithms/Elixir/blob/6212e7e905ec2d2687e7f6e9e4b07b7fabb40f19/lib/data_structures/singly_linked_list.ex), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/SinglyLinkedList.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Linked-List/SinglyLinkedList.js), [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/SinglyLinkedList.php), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/singly_linked_list.py), [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/linked_list_algorithms/singly_linked_list.r), [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/linked_lists/singly_linked_list.rb), [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/list/singly_linked_list.ts).

## One hundred twenty-first reviewed benchmark algorithm: Binary search tree

The pinned sources implement ordered insertion, search, deletion, extrema, and traversal, but duplicate handling and deletion details vary. The benchmark chooses unique-key set semantics, where duplicate insertion returns zero without changing the tree, and uses an in-order predecessor when deleting a key with two children. All nine portable implementations passed 3,173 oracle traces and recorded 21 workload cases each. See [the binary search tree guide](benchmarks/b/binary_search_tree/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/binary_trees/binary_search_tree.c), [C-Plus-Plus](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/binary_search_tree.cpp), [C++ additional repository](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/binary_search_tree.cpp), [C-Sharp](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/BinarySearchTree/BinarySearchTree.cs), [Haskell](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/BinaryTree/BinarySearchTree.hs), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Tree/BinarySearchTree.js), [Lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/sorted_set/binary_search_tree.lua), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/binary_search_tree.py), [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/data_structures/binary_search_tree.r), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/binary_search_tree.rs), [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/tree/binary_search_tree.ts), [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/search/binarySearchTree.zig).


## One hundred twenty-second reviewed benchmark algorithm: Trie

The 11 pinned sources share prefix-tree storage and exact-word lookup, but vary in alphabet handling, duplicate insertion, deletion, prefix operations, and multiplicity. The benchmark standardizes lowercase ASCII words and unique-word set semantics, with insert, delete, exact search, prefix presence, prefix count, and total size operations. It supports empty words and prefix queries, and bounds inputs to 1,024 values and words to 128 characters. All nine portable implementations passed 3,435 oracle traces per language and recorded all 23 workload cases. See [the trie guide](benchmarks/t/trie/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/trie/trie.c), [C-Sharp](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Tries/Trie.cs), [F-Sharp](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/DataStructures/Trie.fs), [Go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/structure/trie/trie.go), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/Trie.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Tree/Trie.js), [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/Trie/Trie.php), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/trie/trie.py), [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/tries/trie.rb), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/trie.rs), and [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/dataStructures/trie.zig).


## One hundred twenty-third reviewed benchmark algorithm: Fractional knapsack

The pinned C++ copies, Java, Lua, two Python files, and Rust sources rank items by value-to-weight ratio and allow taking a fraction of an item. The generic knapsack filename group is mixed: its Go, Java, Python, Ruby, Rust, Solidity, TypeScript, and Zig sources cover 0/1 knapsack, the two C++ files implement fractional knapsack, and Python also offers an optional unbounded mode. The catalog aliases the generic filename to the existing 0/1 benchmark and cross-lists the C++ files here. This benchmark compares exact integer ratios and returns the optimum scaled by one million, truncated to six decimal places. All nine portable implementations passed 6,793 exact-rational oracle traces per language and recorded all 25 workload cases. The Python `fractional_knapsack_2` filename aliases this benchmark. See [the fractional-knapsack guide](benchmarks/f/fractional_knapsack/README.md). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/greedy_algorithms/knapsack.cpp), [additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/greedy_algorithms/knapsack.cpp), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/greedyalgorithms/FractionalKnapsack.java), [Lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/knapsack/fractional_knapsack.lua), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/greedy_methods/fractional_knapsack.py), [additional Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/greedy_methods/fractional_knapsack_2.py), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/fractional_knapsack.rs).
## One hundred twenty-fourth reviewed benchmark algorithm: Segment tree range queries

The nine pinned sources implement segment trees for associative range aggregation, with different examples using sums, minima, maxima, or caller-selected operations. C++ and JavaScript use sums; C and Rust demonstrate min or generic operations; Lua and PHP accept a selected combine operation; Python demonstrates range assignment and maximum queries. C# provides the sum query structure, and Java supports point assignments and sum queries. The shared benchmark standardizes point assignment and inclusive range queries for sum, minimum, or maximum, with one aggregate mode per trace. Nine portable implementations passed 23,474 direct-array oracle traces per language and recorded all 28 workload cases. See [the segment-tree guide](benchmarks/s/segment_tree/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/binary_trees/segment_tree.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/segment_tree.cpp), [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/SegmentTrees/SegmentTree.cs), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/SegmentTree.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Tree/SegmentTree.js), [Lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/segment_tree.lua), [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/SegmentTree/SegmentTree.php), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/segment_tree.py), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/segment_tree.rs).

## One hundred twenty-fifth reviewed benchmark algorithm: Pascal triangle

The seven pinned sources generate the first N rows of Pascal’s triangle. The C++ copies print a centered layout; Java, JavaScript, Python, R, and Rust construct row values, with Rust using 32-bit integers. The shared benchmark hashes every coefficient in row-major order and limits the triangle to 30 rows, which keeps all coefficients and the Rust recurrence’s intermediate products within signed 32-bit range. Nine portable implementations passed 322 exact-binomial oracle traces per language and recorded all 14 workload cases. See [the Pascal-triangle guide](benchmarks/p/pascal_triangle/README.md). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/pascal_triangle.cpp), [additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/others/pascal_triangle.cpp), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PascalTriangle.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/PascalTriangle.js), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/pascal_triangle.py), [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/mathematics/pascal_triangle.r), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/pascal_triangle.rs).

## One hundred twenty-sixth reviewed benchmark algorithm: Union-find

The pinned `union_find`, `disjoint_set`, and `disjoint_set_union` sources track the same partitioning algorithm. Their APIs use zero-based or one-based indices, arbitrary payloads, or explicit nodes; their merge heuristics use path compression, path halving, union by rank, union by size, or member-list merging. The benchmark standardizes a bounded zero-based integer universe with union, connectivity, and component-count operations, then checks the final partition without relying on representative IDs. All nine portable implementations passed 9,381 exhaustive, randomized, malformed, and boundary traces per language and recorded all 10 workload cases. `disjoint_set` and `disjoint_set_union` alias this shared benchmark contract. See [the union-find guide](benchmarks/u/union_find/README.md). Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/misc/union_find.c), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/UnionFind.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Search/UnionFind.js), [Lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/union_find.lua), [Rust union-find](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/union_find.rs), [Swift](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/data_structures/union_find/union_find.swift), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/disjoint_set.cpp), [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/DisjointSet/DisjointSet.cs), [Julia](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/data_structures/disjoint_set/disjoint_set.jl), [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/DisjointSets/DisjointSet.php), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/disjoint_set/disjoint_set.py), [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/disjoint_set/disjoint_set.ts), [Java disjoint-set union](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/disjointsetunion/DisjointSetUnion.java), and [Rust disjoint-set union](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/disjoint_set_union.rs).

## One hundred twenty-seventh reviewed benchmark algorithm: Fenwick tree

The seven pinned sources in C++ (two repositories), Java, JavaScript, Julia, Python, and Rust share point additions and prefix or range sums. Public indexing and range boundaries differ, and Python also supports point assignment. The benchmark standardizes zero-based point additions and inclusive range queries. All nine portable implementations passed 5,818 exhaustive, randomized, malformed, and boundary traces per language and recorded all 10 workload cases. See [the Fenwick-tree guide](benchmarks/f/fenwick_tree/README.md). Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/range_queries/fenwick_tree.cpp), [additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/range_queries/fenwick_tree.cpp), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/FenwickTree.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Trees/FenwickTree.js), [Julia](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/data_structures/fenwick_tree.jl), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/fenwick_tree.py), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/fenwick_tree.rs).

## One hundred twenty-eighth reviewed benchmark algorithm: Ceiling

The eight pinned sources in C-Sharp, Java, Julia, Mojo, Python, Ruby, Rust, and Zig aim to compute the mathematical ceiling function, but their numeric domains and conversion behavior differ. The benchmark standardizes batches of exact rational values with bounded signed numerators and positive denominators, avoiding floating-point rounding and narrow integer conversions. All nine portable implementations passed 1,928 exhaustive, randomized, malformed, and boundary inputs per language and recorded all 11 workload cases. See [the ceiling guide](benchmarks/c/ceil/README.md). Upstream references: [C-Sharp](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/Ceil.cs), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Ceil.java), [Julia](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/ceil.jl), [Mojo](https://github.com/TheAlgorithms/Mojo/blob/de31759cab02892cb7ccc7767d97fc000b10fcae/maths/ceil.mojo), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/ceil.py), [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/ceil.rb), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/ceil.rs), and [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/math/ceil.zig).

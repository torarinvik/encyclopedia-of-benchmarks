# Benchmarking

Every compared implementation must use the same algorithm contract and workload cases. Search benchmarks use the read-only ABI below, except for the explicitly mutable sentinel-search entry point:

```c
int64_t algorithm_name(const int64_t *values, size_t length, int64_t target);
```

In-place sorting benchmarks expose a mutable array and length:

```c
void algorithm_name(int64_t *values, size_t length);
```

Merge sort, bucket sort, radix sort, counting sort, and Tim sort take caller-provided scratch storage:

```c
void algorithm_name(int64_t *values, int64_t *scratch, size_t length);
```

Compile these runners with `-DBENCHMARK_WITH_SCRATCH`. The runner allocates scratch before timing and reuses it for warmups and samples. `-DBENCHMARK_SCRATCH_EXTRA=<n>` reserves additional counter slots beyond the input length: merge, strand sort, and Tim sort use `0`, bead sort uses `64`, bucket and radix sort use `256`, and counting and pigeonhole sort use `257`. Scratch allocation stays outside the timed call.

Scalar benchmarks use a single signed 64-bit input and result:

```c
int64_t algorithm_name(int64_t input);
```

`lcm_sum` accepts inputs from `1` through `65535` and returns the sum of `LCM(i, n)` for all `i` in `1..=n`; it returns `-1` outside that range.

`sum_of_digits` accepts signed 32-bit input, ignores the negative sign, returns the decimal digit sum, and returns `-1` outside the signed 32-bit range.

`perfect_square` accepts any signed 64-bit integer and returns `1` exactly for nonnegative perfect squares; negative inputs and other values return `0`.

`perfect_cube` returns `1` for exact integer cubes, including negative cubes and zero, and `0` otherwise. Its input range is `[-1,000,000,000,000, 1,000,000,000,000]`; out-of-range values return `-1`. Integer binary search keeps all cube intermediates in range. See [`benchmarks/p/perfect_cube/README.md`](benchmarks/p/perfect_cube/README.md).

`abs` uses the scalar ABI and the exported symbol `abs_i64`. It returns the magnitude for every signed 64-bit input except `INT64_MIN`, which returns `-1` because its positive magnitude does not fit the result type.

`perfect_number` returns `1` when an input equals the sum of its positive proper divisors, `0` for values below two and non-perfect values, and `-1` above `1,000,000,000,000`. The ports scan factor pairs using division for an overflow-safe square-root bound. See [`benchmarks/p/perfect_number/README.md`](benchmarks/p/perfect_number/README.md).

`next_prime_number` accepts inputs from `-4096` through `4096` and returns the smallest prime strictly greater than the input. Inputs below two return `2`; out-of-range inputs return `-1`. Candidate primality uses trial division through the square root. See [`benchmarks/n/next_prime_number/README.md`](benchmarks/n/next_prime_number/README.md).

`catalan_number` returns exact `C(n)` for indices `0..=35` and `-1` outside that range. Its ports use the integer ratio recurrence with greatest-common-divisor cancellation, preserving exact signed 64-bit arithmetic. See [`benchmarks/c/catalan_number/README.md`](benchmarks/c/catalan_number/README.md).

Binary scalar benchmarks use two 64-bit input words and an integer result:

```c
int64_t algorithm_name(uint64_t left, uint64_t right);
```

Hamming distance uses unsigned 64-bit values and returns a value from `0` to `64`; GCD returns the greatest common divisor of two nonnegative signed 64-bit values; LCM returns the least common multiple or `-1` if the result exceeds `INT64_MAX`; and `binomial_coefficient` computes `C(n,k)` for `n <= 66`, returning 0 when `k > n` and `-1` when `n` exceeds 66. `addition_without_arithmetic` records signed 32-bit operands and passes negative values to the C ABI as their unsigned 64-bit two's-complement words; it returns the exact sum when that sum fits signed 32-bit range and `-1` otherwise. Binary scalar result records retain the signed workload inputs in `workload.input_values`. See [`benchmarks/b/binomial_coefficient/README.md`](benchmarks/b/binomial_coefficient/README.md) and [`benchmarks/a/addition_without_arithmetic/README.md`](benchmarks/a/addition_without_arithmetic/README.md).

Array scalar benchmarks take a read-only sequence of nonnegative signed 64-bit values and return an integer:

```c
int64_t algorithm_name(const int64_t *values, size_t length);
```

LCM of N numbers returns `1` for an empty sequence, `0` if any value is zero, and `-1` when the exact positive result exceeds `INT64_MAX`. `find_min` and `find_max` scan 1..512 signed 64-bit values and return the minimum or maximum; empty or oversized arrays return `-1`. Their result records store `input_length` and the complete array in `workload.input_values`.

`knapsack_zero_one_tabulation` uses the same array scalar ABI. Its packed input is `[capacity, item_count, weight_0, value_0, ...]`, with capacity `0..512`, item count `0..128`, weights `1..4096`, and values `0..1,000,000,000`. It returns the maximum value achievable without exceeding capacity, or `-1` for malformed input. The implementation visits capacities in descending order for each item so each item is selected at most once.

`binary_to_decimal` uses the array scalar ABI with an array of `1..63` most-significant-first bits. Every element must be `0` or `1`; it returns the corresponding signed 64-bit value or `-1` for malformed input.

Floating-point triple benchmarks use three binary64 inputs and a binary64 result:

```c
double algorithm_name(double first, double second, double parameter);
```

LERP uses `start + t * (end - start)`, with finite endpoints in `[-10^12, 10^12]` and `t` in `[0, 1]`. Results allow absolute error up to `1e-12 * max(1, |start|, |end|)` to account for floating-point rounding.

Bellman–Ford and Dijkstra use a directed edge-list ABI with caller-provided distance and reachability buffers:

```c
int64_t bellman_ford(const int64_t *edges,
                     size_t vertices, size_t edge_count, size_t source,
                     int64_t *distances, uint8_t *reachable);
```

Each edge is three signed 64-bit values `(origin, destination, weight)`. A successful call returns `0`; reachable vertices have exact signed 64-bit distances and unreachable vertices have a separate zero reachability flag. Bellman–Ford reports `-1` for a source-reachable negative cycle, `-2` for signed 64-bit addition overflow, and `-3` for an invalid source, endpoint, or empty-graph shape. Dijkstra requires nonnegative weights and reports `-2` for overflow, `-3` for invalid graph shape, and `-4` for a negative edge. See the [Bellman–Ford guide](benchmarks/b/bellman_ford/README.md) and [Dijkstra guide](benchmarks/d/dijkstra/README.md) for the complete contracts and timing details.

The portable C11 runner in `benchmarks/harness/scalar_runner.c` checks the expected result, runs warmups, times repeated calls with C `clock()` process CPU time, and writes JSON for `benchmarks/run_scalar.py`. Scalar result records set `input_length` to `null` and store the input under `input_value`.

The portable C11 search runner in `benchmarks/harness/runner.c` checks results, runs warmups, times searches with C `clock()` process CPU time, and writes JSON through `benchmarks/run.py`. The sort runner in `benchmarks/harness/sort_runner.c` prepares deterministic input and a `qsort` reference outside timing, copies the same input before each sample, times one sort call, then checks the complete sorted output. Use `benchmarks/run_sort.py` to append its JSON Lines records. Both runners use `-DBENCHMARK_FUNCTION=<algorithm_name>` and default output to `results/<letter>/<algorithm>/<language>.jsonl`.

`sentinel_linear_search` modifies the final input slot temporarily to install its sentinel, then restores it. Its C ABI takes a mutable pointer; compile the shared runner with both `-DBENCHMARK_FUNCTION=sentinel_linear_search` and `-DBENCHMARK_MUTABLE_INPUT`. The other search entries use a read-only pointer.

Sort records set `target` and `target_comparisons_per_sample` to `null`, because those search-specific fields do not apply. Each sort sample has one invocation; workload generation, input copying, reference sorting, output validation, and JSON serialization stay outside the timed interval.

## Build the current C and C++ implementations

Run commands from the repository root. The examples use portable optimization flags and contain no CPU-specific tuning.

```sh
mkdir -p build
cc -std=c11 -O3 -DNDEBUG -DBENCHMARK_FUNCTION=linear_search benchmarks/harness/runner.c c/l/linear_search.c -o build/linear_search_c
```

```sh
mkdir -p build
cc -std=c11 -O3 -DNDEBUG -DBENCHMARK_FUNCTION=linear_search -c benchmarks/harness/runner.c -o build/linear_search_runner.o
c++ -std=c++17 -O3 -DNDEBUG -c cpp/l/linear_search.cpp -o build/linear_search_impl.o
c++ build/linear_search_runner.o build/linear_search_impl.o -o build/linear_search_cpp
```

Then record a run. Compiler metadata is supplied explicitly because compiler naming and version reporting differ across toolchains.

```sh
python3 benchmarks/run.py \
  --algorithm linear_search \
  --language c \
  --source c/l/linear_search.c \
  --executable build/linear_search_c \
  --compiler cc \
  --compiler-version "$(cc --version | head -n 1)" \
  --build-flags '-std=c11 -O3 -DNDEBUG -DBENCHMARK_FUNCTION=linear_search' \
  --build-command 'cc -std=c11 -O3 -DNDEBUG -DBENCHMARK_FUNCTION=linear_search benchmarks/harness/runner.c c/l/linear_search.c -o build/linear_search_c'
```

For another search algorithm, use its same-named exported function and define it when compiling the runner. For example, the binary-search workload uses an ascending array and the same ABI:

```sh
cc -std=c11 -O3 -DNDEBUG -DBENCHMARK_FUNCTION=binary_search benchmarks/harness/runner.c c/b/binary_search.c -o build/binary_search_c
```

## Build and record a sort benchmark

The C and C++ examples use the same mutable sorting ABI and standard, portable compiler flags:

```sh
cc -std=c11 -O3 -DNDEBUG -DBENCHMARK_FUNCTION=bubble_sort benchmarks/harness/sort_runner.c c/b/bubble_sort.c -o build/bubble_sort_c
```

```sh
cc -std=c11 -O3 -DNDEBUG -DBENCHMARK_FUNCTION=bubble_sort -c benchmarks/harness/sort_runner.c -o build/bubble_sort_runner.o
c++ -std=c++17 -O3 -DNDEBUG -c cpp/b/bubble_sort.cpp -o build/bubble_sort_impl.o
c++ build/bubble_sort_runner.o build/bubble_sort_impl.o -o build/bubble_sort_cpp
```

Record the C implementation with:

```sh
python3 benchmarks/run_sort.py \
  --algorithm bubble_sort \
  --language c \
  --source c/b/bubble_sort.c \
  --executable build/bubble_sort_c \
  --compiler cc \
  --compiler-version "$(cc --version | head -n 1)" \
  --build-flags '-std=c11 -O3 -DNDEBUG -DBENCHMARK_FUNCTION=bubble_sort' \
  --build-command 'cc -std=c11 -O3 -DNDEBUG -DBENCHMARK_FUNCTION=bubble_sort benchmarks/harness/sort_runner.c c/b/bubble_sort.c -o build/bubble_sort_c'
```

Replace language, source, compiler details, and build command for other implementations. A linked executable must export the same C ABI symbol. The current ports declare this ABI. The shared ABI builder provides object/archive and link recipes for scalar, scratch-free sorting, and shortest-path algorithms in all nine languages. Search build recipes for C3, Elisa, Nim, Odin, Rust, V, and Zig still need to be documented. For a scratch-free sort such as bogo sort, build both the timing runner and checker with:

```sh
python3 benchmarks/build_abi.py --family sort --algorithm bogo_sort --language rust --with-checker
```

## Build and record a scalar benchmark

The factorial C implementation uses the shared scalar ABI and portable compiler flags:

```sh
mkdir -p build
cc -std=c11 -O3 -DNDEBUG -DBENCHMARK_FUNCTION=factorial benchmarks/harness/scalar_runner.c c/f/factorial.c -o build/factorial_c
```

Record one result per factorial workload case with:

```sh
python3 benchmarks/run_scalar.py \
  --algorithm factorial \
  --language c \
  --source c/f/factorial.c \
  --executable build/factorial_c \
  --compiler cc \
  --compiler-version "$(cc --version | head -n 1)" \
  --build-flags '-std=c11 -O3 -DNDEBUG -DBENCHMARK_FUNCTION=factorial' \
  --build-command 'cc -std=c11 -O3 -DNDEBUG -DBENCHMARK_FUNCTION=factorial benchmarks/harness/scalar_runner.c c/f/factorial.c -o build/factorial_c'
```

Use the same runner for Fibonacci or another scalar implementation by changing the function name, source, compiler details, and build command. Scalar workload files specify per-case expected results and repetitions per sample. They use the same machine and build provenance fields as search and sort records.

### Build ABI language ports

[`benchmarks/build_abi.py`](benchmarks/build_abi.py) compiles a single implementation, compiles the matching C11 harness separately, and links the C ABI executable. It accepts the language folder names from the repository (`c`, `c3`, `cpp`, `elisa`, `nim`, `odin`, `rust`, `v`, and `zig`). The compatibility wrapper [`benchmarks/build_scalar.py`](benchmarks/build_scalar.py) keeps the shorter unary scalar command:

```sh
python3 benchmarks/build_scalar.py --algorithm aliquot_sum --language nim
```

The scalar wrapper writes to `build/scalar/<letter>/<algorithm>/<language>/scalar_runner`, with `.exe` on Windows. The generic builder takes an explicit ABI family (`scalar`, `binary_scalar`, `float64_triple`, `float64_unary`, `i64_array_scalar`, `i64_array_bytes_output`, `i64_scalar_bytes_output`, `shortest_path`, `tree_level_order`, `tree_symmetric`, or `tree_scalar`) and selects the matching harness:

```sh
python3 benchmarks/build_abi.py --family shortest_path --algorithm bellman_ford --language rust
```

For Hamming distance, GCD, or LCM, build the binary scalar family:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm hamming_distance --language rust
```

For an array scalar algorithm such as LCM of N numbers, use:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm lcm_of_n_numbers --language rust
```

For packed ASCII-string edit distance, use the same array-scalar family and runner as LCM of N numbers:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar \
  --algorithm levenshtein_distance --language rust --with-checker
python3 benchmarks/run_i64_array_scalar.py \
  --build-manifest build/i64_array_scalar/l/levenshtein_distance/rust/build.json
```

Digit-array decoders such as `octal_to_decimal` and `hexadecimal_to_decimal` use this family as well. Each contract defines its accepted digit range, input length, overflow behavior, and invalid-input result.

For an array algorithm that writes byte output into a caller-provided buffer, use:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output \
  --algorithm letter_combinations_of_phone_number --language rust --with-checker
python3 benchmarks/run_i64_array_bytes_output.py \
  --build-manifest build/i64_array_bytes_output/letter_combinations_of_phone_number/rust/build.json
```

The same `i64_array_bytes_output` family supports binary, octal, and hexadecimal digit-array conversions. The binary decoders accept up to 63 bits, octal decoders accept up to 21 octal digits, and hexadecimal decoders accept up to 16 nibbles subject to the signed 64-bit bound. The converters write prefix-free output. The harness accepts arrays up to 4,096 values so verifiers can submit overlength cases and confirm rejection; each algorithm enforces its own documented contract.

For a scalar algorithm that writes bytes into a caller-provided buffer, use the `i64_scalar_bytes_output` family. `decimal_to_binary`, `decimal_to_octal`, and `decimal_to_hexadecimal` share this ABI. Their workloads declare radix 2, 8, or 16; the recorder emits prefix-free digits (lowercase for hexadecimal) and checks caller-buffer capacity.

```sh
python3 benchmarks/build_abi.py --family i64_scalar_bytes_output \
  --algorithm decimal_to_binary --language rust --with-checker
python3 benchmarks/run_i64_scalar_bytes_output.py \
  --build-manifest build/i64_scalar_bytes_output/d/decimal_to_binary/rust/build.json
```

For LERP's binary64 triple ABI, use:

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm lerp --language rust
```

For indexed binary-tree traversal, use the `tree_level_order` family. The harness allocates output, level-offset, and queue buffers before timing:

```sh
python3 benchmarks/build_abi.py --family tree_level_order \
  --algorithm level_order_traversal --language rust --with-checker
python3 benchmarks/run_tree_level_order.py \
  --build-manifest build/tree_level_order/level_order_traversal/rust/build.json
```

For recursive binary-tree symmetry checks, the `tree_symmetric` family passes a flat indexed node table and root index to the implementation:

```sh
python3 benchmarks/build_abi.py --family tree_symmetric \
  --algorithm symmetric_tree --language rust --with-checker
python3 benchmarks/run_tree_symmetric.py \
  --build-manifest build/tree_symmetric/s/symmetric_tree/rust/build.json
```

For recursive indexed-tree algorithms that return one integer, use `tree_scalar`. The implementation receives the flat node table, node count, and root index, then returns the scalar result. [Maximum depth](benchmarks/m/max_depth/README.md), [maximum ancestor difference](benchmarks/m/max_ancestor_diff/README.md), [balanced-tree checking](benchmarks/b/balanced_binary_tree/README.md), [maximum path sum](benchmarks/b/binary_tree_maximum_path_sum/README.md), [sum of left leaves](benchmarks/s/sum_of_left_leaves/README.md), and [univalued-tree checking](benchmarks/u/univalued_binary_tree/README.md) use this family:

```sh
python3 benchmarks/build_abi.py --family tree_scalar \
  --algorithm max_depth --language rust --with-checker
python3 benchmarks/run_tree_scalar.py \
  --build-manifest build/tree_scalar/m/max_depth/rust/build.json
```

The binary scalar output is `build/binary_scalar/<letter>/<algorithm>/<language>/binary_scalar_runner`. Graph output is `build/shortest_path/<letter>/<algorithm>/<language>/shortest_path_runner`. `build.json` in each directory records the source hash, compiler version or executable fingerprint, compiler flags, exact compile and link argument lists, runtime library link flags reported by Rust, executable hashes, and harness hashes. Pass `--compiler` to choose a compiler executable, and `--cc` to choose the C harness compiler. Elisa needs the custom compiler executable on `PATH` or an explicit path:

```sh
python3 benchmarks/build_scalar.py --algorithm armstrong_number --language elisa --compiler /absolute/path/to/elisac
```

These recipes use ordinary optimization, generic/baseline CPU settings where available, and no host-specific instruction tuning. V emits a C object with garbage collection disabled; Nim emits a static library without its main function and with memory management disabled. Rust builds as a static library and records the native link flags reported by `rustc`, including the panic runtime dependencies needed by bounds-checked code. The scalar, Bellman–Ford, and tree traversal functions use caller-owned storage and allocate no memory. The recipes require a GCC/Clang-compatible C toolchain; platform toolchain configuration, archive naming, and installed SDKs still apply. They have been exercised on macOS AArch64; portability of the source does not imply that every compiler/OS/architecture combination has been run.

### Check scalar correctness and recording

[`benchmarks/verify_bogo_sort.py`](benchmarks/verify_bogo_sort.py) builds all nine implementations, checks every relative-order and duplicate pattern through length six, adds signed and deterministic random cases, and runs the workload through the timing recorder. [`benchmarks/verify_scalar.py`](benchmarks/verify_scalar.py) builds all nine implementations of thirteen scalar algorithms, including signum, `is_even`, double factorial, power of two, and prime check. It checks the real exported C ABI against independent Python oracles, then runs each published workload through the timing harness and JSONL recorder. The oracles use `math.factorial`, fast doubling, prime factorization, decimal strings with arbitrary-precision powers, direct sign and parity checks, exact double-factorial products, and integer square roots for primality. Dense and deterministic random inputs supplement the published workload boundaries. The linear aliquot scan is checked on practical positive inputs, rather than attempting to scan near the signed 64-bit maximum.

```sh
python3 benchmarks/verify_scalar.py --elisa-compiler /absolute/path/to/elisac
```

[`benchmarks/verify_miller_rabin.py`](benchmarks/verify_miller_rabin.py) checks the fixed-base Miller–Rabin implementation against trial division for every input from 0 through 100,000, seeded values across the signed 32-bit domain, boundary values, and the published workload in all nine languages. It also checks that every recorded workload result matches the exported scalar ABI.

Hamming distance uses [`benchmarks/run_binary_scalar.py`](benchmarks/run_binary_scalar.py) and the binary scalar build manifest:

```sh
python3 benchmarks/run_binary_scalar.py \
  --build-manifest build/binary_scalar/h/hamming_distance/rust/build.json
```

[`benchmarks/verify_binary_scalar.py`](benchmarks/verify_binary_scalar.py) checks Hamming distance, GCD, and LCM in all nine languages. It covers every pair of 8-bit inputs, boundary patterns, deterministic random inputs, and each published workload. The GCD and LCM oracles use Stein's algorithm, independently of the ports' Euclidean remainder loops.

[`benchmarks/verify_i64_array_scalar.py`](benchmarks/verify_i64_array_scalar.py) checks LCM of N numbers in all nine languages against Python's arbitrary-precision `math.lcm`. It covers exhaustive short arrays, boundary pairs and singletons, deterministic random arrays, and each published workload. [`benchmarks/verify_activity_selection.py`](benchmarks/verify_activity_selection.py) checks activity-selection counts against an independent weighted-interval dynamic-programming oracle, with exhaustive small schedules, deterministic random schedules, signed time boundaries, and malformed layouts. [`benchmarks/verify_word_break.py`](benchmarks/verify_word_break.py) checks packed lowercase text and dictionary inputs against a memoized recursive oracle, exhausts all short binary strings and dictionary subsets, and checks deterministic longer inputs plus malformed layouts in all nine languages.

[`benchmarks/verify_longest_increasing_subsequence.py`](benchmarks/verify_longest_increasing_subsequence.py) checks strict LIS length against an independent binary-search tails oracle. Its corpus exhausts short sequences over a three-value alphabet, adds deterministic signed arrays and i64 boundaries, and checks the maximum and first unsupported lengths in all nine languages.

[`benchmarks/verify_coin_change.py`](benchmarks/verify_coin_change.py) checks minimum-coin change against a breadth-first shortest-path oracle. It exhausts small denomination lists, adds deterministic inputs and malformed packed cases, and checks amount and denomination-count limits in all nine languages.

[`benchmarks/verify_longest_common_subsequence.py`](benchmarks/verify_longest_common_subsequence.py) checks LCS length against an independent full-table oracle. It exhausts all pairs of binary-alphabet sequences through length five, then checks deterministic random pairs, maximum-length sequences, malformed packed inputs, and the published workload in all nine languages.
[`benchmarks/verify_knuth_morris_pratt.py`](benchmarks/verify_knuth_morris_pratt.py) checks first-match byte indices against Python byte search, including all pairs of binary-alphabet sequences through length five, malformed packed inputs, deterministic random pairs, long near-matches, and the published workload in all nine languages.
[`benchmarks/verify_isogram.py`](benchmarks/verify_isogram.py) checks case-insensitive ASCII letter uniqueness with spaces ignored, exhaustive case-and-space sequences, invalid bytes, deterministic random sequences, maximum lengths, and the published workload in all nine languages.
[`benchmarks/verify_boyer_moore_search.py`](benchmarks/verify_boyer_moore_search.py) checks the bad-character first-match index against Python byte search, including exhaustive binary strings through length five, invalid packed inputs, random sequences, maximum-length near-matches, and the workload in all nine languages.
[`benchmarks/verify_trapped_rainwater.py`](benchmarks/verify_trapped_rainwater.py) checks the prefix/suffix-maxima volume against an independent oracle, with exhaustive short height profiles, random and boundary profiles, invalid values, maximum lengths, and the workload in all nine languages.

[`benchmarks/verify_rabin_karp.py`](benchmarks/verify_rabin_karp.py) checks pattern presence against a naive substring oracle. It covers all pairs of short binary-alphabet sequences, deterministic random pairs, maximum lengths, malformed packed inputs, and a crafted rolling-hash collision in all nine languages.

[`benchmarks/verify_sieve_of_eratosthenes.py`](benchmarks/verify_sieve_of_eratosthenes.py) checks the prime count against trial division for every supported limit from 0 through 4096, plus invalid signed inputs and the published workload in all nine languages.

[`benchmarks/verify_linear_sieve.py`](benchmarks/verify_linear_sieve.py) checks the linear-sieve prime count against trial division for every limit from 0 through 4096, plus invalid signed inputs and the published workload in all nine languages.

[`benchmarks/verify_sieve_of_atkin.py`](benchmarks/verify_sieve_of_atkin.py) checks the Atkin-sieve prime count against trial division for every limit from 0 through 4096, plus invalid signed inputs and the published workload in all nine languages.

[`benchmarks/verify_next_prime_number.py`](benchmarks/verify_next_prime_number.py) checks the next-prime result against trial division for every input from -4096 through 4096, plus invalid signed inputs and the published workload in all nine languages.

[`benchmarks/verify_perfect_cube.py`](benchmarks/verify_perfect_cube.py) checks perfect cubes against an exact-integer Newton oracle, including every supported cube and its neighbors, deterministic random inputs, and the published workload in all nine languages.

[`benchmarks/verify_binomial_coefficient.py`](benchmarks/verify_binomial_coefficient.py) checks `C(n,k)` against Python's arbitrary-precision `math.comb` for every pair in the supported domain, plus unsigned 64-bit boundaries and the published workload in all nine languages.

[`benchmarks/verify_unique_paths.py`](benchmarks/verify_unique_paths.py) checks every grid from 0 through 36 in each dimension, unsigned 64-bit boundary pairs, deterministic random dimensions, and the published workload against Python's arbitrary-precision binomial oracle in all nine languages.

[`benchmarks/verify_find_min_max.py`](benchmarks/verify_find_min_max.py) checks array minimum and maximum against Python's built-in operations, with exhaustive short arrays, signed boundaries, deterministic random inputs, and the published workloads in all nine languages.

[`benchmarks/verify_i64_array_bytes_output.py`](benchmarks/verify_i64_array_bytes_output.py) checks the phone keypad Cartesian product against Python's `itertools.product`, including exhaustive sequences through length four, longer deterministic sequences, invalid digits, overlength inputs, and insufficient output capacity.

[`benchmarks/verify_i64_scalar_bytes_output.py`](benchmarks/verify_i64_scalar_bytes_output.py) checks decimal-to-binary output against Python integer formatting, including exhaustive values through 4,096, deterministic full-width values, negative inputs, signed boundaries, and insufficient buffer capacity.

[`benchmarks/verify_tree_level_order.py`](benchmarks/verify_tree_level_order.py) checks indexed-tree BFS values and level boundaries against an independent oracle. It covers every ordered tree shape through seven nodes, deterministic random trees, larger chains and complete trees, invalid roots, and undersized buffers.

[`benchmarks/verify_symmetric_tree.py`](benchmarks/verify_symmetric_tree.py) checks recursive mirrored-pair comparisons against an independent iterative oracle. It covers every ordered tree shape through seven nodes, deterministic random trees, signed boundary values, invalid roots, and mirrored chains reaching the documented recursion bound.

[`benchmarks/verify_max_ancestor_diff.py`](benchmarks/verify_max_ancestor_diff.py) checks the recursive path-minimum/path-maximum traversal against an independent iterative oracle. It covers every ordered tree shape through seven nodes, deterministic random trees, signed boundary values, invalid indexes, nonzero roots, and a chain reaching the documented recursion bound.

[`benchmarks/verify_max_depth.py`](benchmarks/verify_max_depth.py) checks recursive maximum depth against an independent iterative tree traversal. It covers every ordered tree shape through seven nodes, deterministic random trees, empty trees, invalid indexes, nonzero roots, and a chain reaching the documented recursion bound.

[`benchmarks/verify_balanced_binary_tree.py`](benchmarks/verify_balanced_binary_tree.py) checks recursive height-balance results against an independent iterative postorder oracle. It covers every ordered tree shape through seven nodes, deterministic random trees, empty trees, internally unbalanced subtrees, invalid indexes, and a chain reaching the documented recursion bound.

[`benchmarks/verify_sum_of_left_leaves.py`](benchmarks/verify_sum_of_left_leaves.py) checks recursive left-leaf sums against an independent iterative oracle. It covers every ordered tree shape through seven nodes, deterministic random trees, negative leaf values, a valid result of `-1`, invalid indexes and values, and larger trees with many left leaves.

[`benchmarks/verify_univalued_binary_tree.py`](benchmarks/verify_univalued_binary_tree.py) checks recursive value comparisons against an independent iterative tree oracle. It covers every ordered tree shape through seven nodes, deterministic random trees, signed 64-bit extremes, invalid indexes, and a 1,023-node path.

[`benchmarks/verify_binary_tree_maximum_path_sum.py`](benchmarks/verify_binary_tree_maximum_path_sum.py) checks recursive downward gains and best complete paths against an independent iterative postorder oracle. It covers every ordered tree shape through seven nodes, deterministic random trees, all-negative trees, best paths that exclude the root, invalid inputs, and 1,023-node path and complete-tree workloads.

[`benchmarks/verify_next_greater_nodes.py`](benchmarks/verify_next_greater_nodes.py) checks the forward-scan next-greater-node algorithm against a monotonic-stack oracle, with exhaustive short sequences, deterministic full-range inputs, a 4,096-node workload, invalid values, and insufficient output capacity.

[`benchmarks/verify_float64_triple.py`](benchmarks/verify_float64_triple.py) checks LERP in all nine languages against a high-precision decimal oracle and applies the documented input-scaled tolerance to finite binary64 values.

The `float64_unary` ABI family measures one-input binary64 algorithms such as [square root](benchmarks/s/square_root/README.md). `benchmarks/run_float64_unary.py` records results against each workload's expected value and relative tolerance.

```sh
python3 benchmarks/verify_binary_scalar.py --elisa-compiler /absolute/path/to/elisac
```

Use `--algorithms` or `--languages` to select a subset, `--jobs` to limit compiler concurrency, and `--build-dir` to choose the artifact directory. A missing compiler or a failed case fails the verification; languages are not silently skipped. The default report is `build/scalar/verification.json`; it records the host, source and corpus hashes, checker counts, workload record counts, and build manifest paths. Verification records use one repetition and one sample to check the recording flow; they are not performance measurements suitable for comparing languages.

Bellman–Ford uses [`benchmarks/run_shortest_path.py`](benchmarks/run_shortest_path.py) and requires the matching build manifest:

```sh
python3 benchmarks/run_shortest_path.py \
  --build-manifest build/shortest_path/b/bellman_ford/rust/build.json
```

[`benchmarks/verify_shortest_path.py`](benchmarks/verify_shortest_path.py) checks the nine ports against an arbitrary-precision Floyd–Warshall oracle. Its corpus includes the 31 published workload cases, exhaustive small graphs, deterministic random graphs, reversed edge orders, invalid endpoints, and signed 64-bit boundaries.

```sh
python3 benchmarks/verify_shortest_path.py --elisa-compiler /absolute/path/to/elisac
```

[`benchmarks/verify_dijkstra.py`](benchmarks/verify_dijkstra.py) checks Dijkstra against a heap-based oracle using the same ABI harness and recorder:

```sh
python3 benchmarks/verify_dijkstra.py --elisa-compiler /absolute/path/to/elisac
```

Search workloads default to seven samples and two warmup rounds. Repetitions are chosen from a workload-specific comparison model; override these with `--samples`, `--warmups`, and `--target-comparisons`. Search samples reuse the same read-only array. Sort workloads also default to seven samples and two warmups, but time one sort per sample after preparing a fresh copy. Both workflows exclude process startup, input generation, correctness checks, and JSON serialization; sort timing also excludes input copying and reference sorting.

Search, sort, scalar, array byte-output, shortest-path, and tree traversal result records follow [`benchmarks/results.schema.json`](benchmarks/results.schema.json). Sort, scalar, array, graph, and tree records leave the search target and comparison count null. All runners use `clock()`, so samples are process CPU time and timer resolution depends on the C runtime. Compare runs on the same host and runtime when studying small differences. Each record includes the timer resolution.

Do not use `-march=native`, Intel-specific intrinsics, or other host-specific tuning for the portable baseline. A separately labeled optimized variant can be added later, with its exact compiler flags recorded separately.


[`benchmarks/verify_sorted_array_to_bst.py`](benchmarks/verify_sorted_array_to_bst.py) checks the C LeetCode 108 tree construction against an independent preorder serializer, including every subset of a small key set, deterministic arrays, invalid ordering and range cases, the maximum input length, and insufficient output capacity in all nine languages.


[`benchmarks/verify_duplicate_zeros.py`](benchmarks/verify_duplicate_zeros.py) checks fixed-length zero duplication and output bytes against an independent array oracle, including exhaustive short arrays, seeded longer inputs, malformed values, and output-capacity handling in all nine languages.

[`benchmarks/verify_sorted_list_to_bst.py`](benchmarks/verify_sorted_list_to_bst.py) checks the C LeetCode 109 tree construction against an independent serializer, including exhaustive nondecreasing sequences, duplicate keys, signed boundaries, maximum length, and output-capacity handling in all nine languages.


[`benchmarks/verify_path_sum.py`](benchmarks/verify_path_sum.py) checks root-to-leaf path sums against an independent indexed-tree oracle, including every binary-tree shape through four nodes over small node values and target sums, deterministic larger trees, malformed structures, and signed target boundaries in all nine languages.

## Longest Chunked Palindrome Decomposition

The C LeetCode 1147 candidate is cataloged under its algorithm name. The contract accepts 0 to 128 ASCII byte values in 1..127. All nine ports passed 10,361 cases each against a memoized exhaustive-cut oracle, including all strings through length eight over a three-symbol alphabet, deterministic random strings, the length boundary, malformed bytes, and 15 workload records. Run python3 benchmarks/verify_longest_chunked_palindrome_decomposition.py --elisa-compiler /absolute/path/to/elisac to reproduce the check.

## Distance Between Bus Stops

The pinned C LeetCode 1184 candidate is cataloged under its algorithm name. The packed input contains two endpoint indices and 1 to 64 distances. All nine ports passed 5,271 routes each against an exact summation oracle, including every endpoint pair and distance array through four stops, seeded random routes, invalid inputs, and 17 workload records. Run python3 benchmarks/verify_distance_between_bus_stops.py --elisa-compiler /absolute/path/to/elisac to reproduce the check.

## Maximum Number of Balloons

The pinned C LeetCode 1189 candidate is cataloged under its algorithm name. The contract accepts 0 to 256 lowercase ASCII letters. All nine ports passed 20,054 cases each against a frequency-count oracle, including all strings through length six over the required-letter alphabet, deterministic random strings, length and byte boundaries, and 14 workload records. Run python3 benchmarks/verify_max_number_of_balloons.py --elisa-compiler /absolute/path/to/elisac to reproduce the check.

## Unique Occurrences

The pinned C LeetCode 1207 candidate is cataloged under its algorithm name. The contract accepts 0 to 1,000 signed values in -1,000..1,000. All nine ports passed 10,365 cases each against an independent frequency oracle, including all arrays through length eight over a three-value alphabet, deterministic random arrays, signed boundaries, invalid values, the length limit, and 13 workload records. Run python3 benchmarks/verify_unique_occurrences.py --elisa-compiler /absolute/path/to/elisac to reproduce the check.

## Smallest Divisor

The pinned C LeetCode 1283 candidate is cataloged under its algorithm name. Its packed input contains the threshold followed by 1 to 256 positive values bounded at 1,000,000. All nine ports passed 5,797 cases each against a direct scan of candidate divisors, including exhaustive short arrays, random inputs, infeasible thresholds, signed and length boundaries, and 14 workload records. Run python3 benchmarks/verify_smallest_divisor.py --elisa-compiler /absolute/path/to/elisac to reproduce the check.

## Number of Subarrays With Odd Sum

The pinned C LeetCode 1524 candidate is cataloged under its algorithm name. It returns the odd-sum contiguous subarray count modulo 1,000,000,007 for up to 100,000 signed 32-bit values. All nine ports passed 10,358 cases each, including exhaustive short inputs, signed boundaries, random arrays, and the maximum-length input boundary. Run python3 benchmarks/verify_number_of_subarrays_with_odd_sum.py --elisa-compiler /absolute/path/to/elisac to reproduce the check.

## Close Strings

The pinned C LeetCode 1657 candidate is cataloged under its algorithm name. It accepts two lowercase ASCII strings packed after their lengths. All nine ports passed 15,168 pairs each, including all pairs through length four over a three-letter alphabet, random and maximum-length strings, malformed layouts, and 14 workload records. Run python3 benchmarks/verify_close_strings.py --elisa-compiler /absolute/path/to/elisac to reproduce the check.

## Halves Are Alike

The pinned C LeetCode 1704 candidate is cataloged under its algorithm name. Its contract accepts even-length ASCII letters, and the empty string returns true. All nine ports passed 16,797 cases each, including every even string through length six over a mixed-case vowel/consonant alphabet, random strings, malformed bytes, and 13 workload records. Run python3 benchmarks/verify_halves_are_alike.py --elisa-compiler /absolute/path/to/elisac to reproduce the check.

## Check If Array Is Sorted and Rotated

The pinned C LeetCode 1752 candidate is cataloged under its algorithm name. Its contract accepts 0 to 256 signed 32-bit values. All nine ports passed 3,805 arrays each against a sort-and-rotation oracle, including exhaustive short arrays, random signed values, boundaries, and 14 workload records. Run python3 benchmarks/verify_check_if_array_is_sorted_and_rotated.py --elisa-compiler /absolute/path/to/elisac to reproduce the check.

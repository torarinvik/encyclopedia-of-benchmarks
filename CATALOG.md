# Algorithm source inventory

Checked 2026-10-14 against pinned default-branch commits from 34 non-archived TheAlgorithms algorithm repositories. The inventory contains 6,158 source files and 3,831 normalized filename candidates. Of those, 865 names occur in at least two source repositories. Each source commit and file path is linked in [`catalog/algorithm-candidates.json`](catalog/algorithm-candidates.json).

## How to read this inventory

Each candidate is based on a normalized source filename, with camelCase converted to snake_case. The list is a discovery aid: matching filenames do not prove that implementations use the same algorithm, input contract, edge cases, or output. Candidates remain marked `unreviewed_filename_match` in the JSON until their implementations are inspected; `linear_search`, `binary_search`, and `exponential_search` have reviewed contracts. Tests, examples, benchmarks, documentation, scripts, build output, and vendor directories are omitted. Project Euler `solN` files include their problem number in the candidate name.

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

## Target folders without a source repository

The current source snapshot has no matching TheAlgorithms repository for `c3/`, `odin/`, or `v/`. Elisa is a custom language whose compiler lives in the neighboring `Elisa-compiler` project, and it also has no upstream collection. These folders need ports for whichever candidates we select. The direct source matches are limited to C, C++, Nim, Rust, and Zig.

## Next inventory pass

Continue promoting filename candidates to confirmed algorithms by checking source behavior and contracts. Then define shared workloads, record source and license details, and add ports where the selected target language has no suitable implementation.

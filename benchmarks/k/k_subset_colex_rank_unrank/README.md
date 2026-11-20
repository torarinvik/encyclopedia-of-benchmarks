# Fixed-size subset colex rank and unrank

This package benchmarks the combinadic bijection between fixed-size subsets
and integer ranks in colexicographic order. It provides both the direct rank
formula and greedy inverse. The colex order compares subsets from the largest
element toward the smallest.

## Contract

The exported `k_subset_colex_rank_unrank` function uses the
`i64_array_bytes_output` ABI. Input is one of:

- `[0,n,k,a0,...,a(k-1)]` to rank a subset. Indices are zero-based and must be
  strictly increasing in `[0,n)`.
- `[1,n,k,r]` to unrank an integer `r` in `[0,binomial(n,k))`.

The accepted domain is `0<=n<=16` and `0<=k<=n`. Both `n=0,k=0` and `k=0`
for any `n` are valid and map to rank zero and the empty subset. The
`k=n` case has one subset and rank zero. Maximum valid/parseable input lengths
are 19/20 signed-i64 words.

Both modes return `[rank,a0,...,a(k-1)]` as little-endian signed-i64 words.
The maximum is 17 words or 136 bytes. Malformed frames and values return `-1`;
null or insufficient output storage returns `-2`. Input/domain validation
precedes output-capacity handling, and errors write no bytes.

The primary ranks by `sum(binomial(ai,i+1))` and un-ranks by greedily removing
the largest feasible binomial term from order `k` down to 1. The independent
reference enumerates subsets recursively in colex order and selects or counts
their ordinal. The primary is O(k²) for ranking and O(n*k²) worst case for
unranking with bounded binomial arithmetic; the enumeration reference is
O(binomial(n,k)*k). Workspace is capped at 1,024 bytes.

## Distinction

Local `gray_code_k_combinations` and `subset_combinations` enumerate subsets
in particular orders; `combinations_with_repetition_lexicographic` handles
multisets in lexicographic order. `permutation_and_combination` emits a
lexicographic combination sequence. None maps fixed-size subsets to and from
their colex integer rank using the combinadic binomial representation.

## Sources and rights

The procedure follows Kreher and Stinson, *Combinatorial Algorithms:
Generation, Enumeration, and Search*, §2.3.2, Algorithms 2.9–2.10. A second
description and boundary discussion appears in Genitrini and Pepin,
[“Unranking Small Combinations of a Large Set in Co-Lexicographic Order”](https://doi.org/10.3390/a15020036), §2.1. Sources provide algorithm
descriptions only. No source code, prose, examples, or fixtures are reused.

## Language ports

- [C](../../../c/k/k_subset_colex_rank_unrank.c)
- [C3](../../../c3/k/k_subset_colex_rank_unrank.c3)
- [C++](../../../cpp/k/k_subset_colex_rank_unrank.cpp)
- [Elisa](../../../elisa/k/k_subset_colex_rank_unrank.elisa)
- [Mojo](../../../mojo/k/k_subset_colex_rank_unrank.mojo)
- [Nim](../../../nim/k/k_subset_colex_rank_unrank.nim)
- [Odin](../../../odin/k/k_subset_colex_rank_unrank.odin)
- [Rust](../../../rust/k/k_subset_colex_rank_unrank.rs)
- [V](../../../v/k/k_subset_colex_rank_unrank.v)
- [Zig](../../../zig/k/k_subset_colex_rank_unrank.zig)

The benchmark is registered with the `i64_array_bytes_output` runner and
verifier. No programs, tests, scripts, helpers/checkers, builds, compilers,
profilers, or benchmarks were run.

# Landau–Vishkin k-difference endpoint matching

This profile reports every text endpoint at which some substring ending there
is within `k` unit-cost insertions, deletions, or substitutions of the complete
pattern. It measures the Landau–Vishkin furthest-reaching diagonal recurrence.
The primary reference and native ports use a bounded direct scan for each
longest-common-extension step; they do not build the suffix tree/LCA structure
used by the paper's accelerated implementation.

## Contract

The `i64_array_bytes_output` input is exactly
`[m,n,k, pattern_symbols..., text_symbols...]`. The pattern has 1–16 symbols,
the text has 0–32 symbols, and `k` is 0–2 with `k < m`. Each symbol is an
integer from 0 through 3. The valid input limit is 51 words and the parser
limit is 52 words; the extra parseable word allows a trailing-value rejection
fixture. A valid call emits `n` bytes in increasing endpoint order. Byte `j`
is 1 iff some nonempty substring ending at text position `j+1` has edit
distance at most `k`; otherwise it is 0. An empty text therefore emits zero
bytes. Malformed input returns `-1`; a null output buffer or capacity below
`n` returns `-2` without writing. A nonnull output with capacity zero is valid
when `n=0`.

## Algorithm

For diagonal `d` and edit count `e`, `L[d,e]` stores the furthest pattern
prefix length reached with exactly `e` edits, after extending across the
following exact-match run. From the previous cost layer, the unextended
candidate is

```text
r = max(L[d,e-1] + 1, L[d-1,e-1], L[d+1,e-1] + 1)
L[d,e] = min(m, r extended by the longest exact match on diagonal d)
```

The three terms represent substitution, insertion into the text, and deletion
from the pattern. The serial initialization uses `L[d,-1]=-1` and the
negative-diagonal seeds described by Landau and Vishkin. For every state with
`L[d,e]=m`, the corresponding one-based endpoint is `d+m`; the output byte for
that endpoint is set if it lies in `1..n`. Multiple state witnesses set the
same byte, so endpoint flags are unique and ordered by text position. The
bounded implementation uses direct character comparisons for the exact-match
extension. It keeps the diagonal frontier recurrence but does not claim the
paper's suffix-tree/LCA preprocessing time bound.

The primary algorithm costs at most `O((n+1)(k+1)m)` symbol comparisons under
this direct-extension implementation. The independent reference uses a
streaming Levenshtein row with a free restart at each text position, costing
`O(mn)` time and `O(m)` workspace. This is distinct from the local
[`agrep_approx_substring_count`](../agrep_approx_substring_count/README.md)
profile: that package uses the streaming-row kernel and returns one scalar
count, while this package exercises the diagonal-frontier/LCE recurrence and
returns the complete endpoint mask.

## Provenance and rights

The algorithm is attributed to Landau and Vishkin's *Fast String Matching
with k Differences*, JCSS 37(1), 1988, pp. 63–78,
[DOI 10.1016/0022-0000(88)90045-1](https://doi.org/10.1016/0022-0000(88)90045-1).
The serial recurrence and LCE formulation are also described in *Fast
Parallel and Serial Approximate String Matching*, Journal of Algorithms
10(2), 1989, pp. 157–169,
[DOI 10.1016/0196-6774(89)90010-2](https://doi.org/10.1016/0196-6774(89)90010-2).
The Encyclopedia crosswalk is Gonzalo Navarro, *Approximate String Matching*,
2nd edition, Chapter 363,
[DOI 10.1007/978-1-4939-2864-4_363](https://doi.org/10.1007/978-1-4939-2864-4_363).
The chapter is contextual attribution; the operational recurrence is credited
to the Landau–Vishkin papers. Chapter 188 is not used as the source of this
recurrence.

The package uses published algorithm ideas only. Its input/output contract,
fixtures, references, and ten implementations were written independently;
no upstream source code, comments, examples, or tests are redistributed. See
[RIGHTS.md](RIGHTS.md) for the source and reuse note.

The fixed frontier has at most 37 diagonals and four cost columns, or 1,184
bytes as signed 64-bit entries. With at most 32 staged output bytes and bounded
local state, the declared workspace cap is 4,096 bytes.

## Files

| Language | Source |
|---|---|
| C | [c/l/landau_vishkin_k_difference_pattern_matching.c](../../../c/l/landau_vishkin_k_difference_pattern_matching.c) |
| C3 | [c3/l/landau_vishkin_k_difference_pattern_matching.c3](../../../c3/l/landau_vishkin_k_difference_pattern_matching.c3) |
| C++ | [cpp/l/landau_vishkin_k_difference_pattern_matching.cpp](../../../cpp/l/landau_vishkin_k_difference_pattern_matching.cpp) |
| Elisa | [elisa/l/landau_vishkin_k_difference_pattern_matching.elisa](../../../elisa/l/landau_vishkin_k_difference_pattern_matching.elisa) |
| Mojo | [mojo/l/landau_vishkin_k_difference_pattern_matching.mojo](../../../mojo/l/landau_vishkin_k_difference_pattern_matching.mojo) |
| Nim | [nim/l/landau_vishkin_k_difference_pattern_matching.nim](../../../nim/l/landau_vishkin_k_difference_pattern_matching.nim) |
| Odin | [odin/l/landau_vishkin_k_difference_pattern_matching.odin](../../../odin/l/landau_vishkin_k_difference_pattern_matching.odin) |
| Rust | [rust/l/landau_vishkin_k_difference_pattern_matching.rs](../../../rust/l/landau_vishkin_k_difference_pattern_matching.rs) |
| V | [v/l/landau_vishkin_k_difference_pattern_matching.v](../../../v/l/landau_vishkin_k_difference_pattern_matching.v) |
| Zig | [zig/l/landau_vishkin_k_difference_pattern_matching.zig](../../../zig/l/landau_vishkin_k_difference_pattern_matching.zig) |

The package-local static files are [workload.json](workload.json),
[primary_oracle.py](primary_oracle.py), [independent_oracle.py](independent_oracle.py),
[verify_workload.py](verify_workload.py), [check_inventory.py](check_inventory.py),
[INVENTORY.md](INVENTORY.md), and [INVENTORY.json](INVENTORY.json). The shared
`i64_array_bytes_output` runner/verifier, catalog, and Chapter 363 crosswalk are
integrated.

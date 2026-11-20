# RosettaCodeData popular-title audit: score 28

## Source and method

This pass uses only score/title metadata from the pinned RosettaCodeData
[`popular-tasks` revision
`1d475861d7141ef2fafff293d9339f56e4b0f5db`](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks),
raw lines 1318–1334. No Rosetta task pages, task text, examples, tests,
submissions, or source were consulted. Local comparisons used package paths,
catalog entries, and package contracts.

## Candidate dispositions

| Score/title | Local comparison | Disposition |
| --- | --- | --- |
| 28 — Zeckendorf arithmetic | [`zeckendorf_addition`](../../z/zeckendorf_addition/README.md) implements bounded direct normalization of canonical Fibonacci-weight bit vectors. | Covered for the concrete addition operation; the title does not pin another arithmetic operation. |
| 28 — Ultra-useful primes | No definition or search interval is specified by title metadata. | Excluded: number property and enumeration method are under-specified. |
| 28 — Three-word location | No geocoding dataset, tokenization, or location-code algorithm is identified. | Excluded: title is not a self-contained algorithm specification. |
| 28 — Special characters | The title names a broad string/character demonstration. | Excluded: no exact classification or transformation procedure is pinned. |
| 28 — Simulated annealing | [`simulated_annealing`](../simulated_annealing/README.md) and related optimization packages already cover deterministic bounded annealing replays. | Covered. |
| 28 — Sierpinski curve | [`sierpinski_triangle`](../sierpinski_triangle/README.md) emits recursive triangle outlines; [`sierpinski_carpet`](../sierpinski_carpet/README.md) emits a ternary-cell raster. Neither emits Wirth's closed A/B/C/D recursive curve. | Selected: distinct closed-curve direction trace from Wirth §3.3. |
| 28 — Set right adjacent bits | Existing bit primitives include [`swap_adjacent_bits`](../swap_adjacent_bits/README.md), but the title does not define which right-side bit run or boundary should be set. | Excluded: the intended bit operation is ambiguous from title metadata alone. |
| 28 — Permutations with some identical elements | [`alphabetic_anagrams`](../../a/alphabetic_anagrams/README.md), [`permutation_unique_string`](../../p/permutation_unique_string/README.md), and [`heaps_algorithm`](../../h/heaps_algorithm/README.md) cover multiset ranking/enumeration or position permutations. | Covered at the multiset-permutation kernel level; no new algorithm is pinned. |
| 28 — Multiplicatively perfect numbers | No target definition, input window, or factorization procedure is specified. | Excluded: under-specified number-class search. |
| 28 — Mastermind | The title does not select a solver, feedback convention, candidate space, or strategy. | Excluded: multiple materially different algorithms fit the title. |
| 28 — Lunar arithmetic | The title names a nonstandard arithmetic family but not which operation or representation to benchmark. | Excluded: operation contract under-specified. |
| 28 — Index finite lists of positive integers | No ranking/encoding convention is provided by the title. | Excluded: multiple indexing bijections fit the title. |
| 28 — Eertree | [`eertree`](../../e/eertree/README.md) and [`palindromic_partition_series_links`](../../p/palindromic_partition_series_links/README.md) already include the palindromic-tree structure. | Covered. |
| 28 — Distributed programming | This is a broad systems-programming category, not one algorithm. | Excluded: no bounded kernel pinned. |
| 28 — Compiler code generator | The title does not specify a source language, target instruction set, or lowering algorithm. | Excluded: under-specified. |
| 28 — Bron–Kerbosch algorithm | [`bron_kerbosch`](../../b/bron_kerbosch/README.md) implements bounded maximal-clique enumeration. | Covered. |

The chosen title is resolved to one concrete mathematical variant by the
independent source reference in the package README. The score list is used for
discovery only; this audit does not claim that every Rosetta task variant is
represented locally.

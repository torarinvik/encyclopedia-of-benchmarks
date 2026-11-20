# RosettaCodeData popular-title audit: scores 31–29

## Source and method

The audit uses only score/title metadata in the pinned
[RosettaCodeData `popular-tasks` revision `1d475861d7141ef2fafff293d9339f56e4b0f5db`](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks), lines 1251–1317. No Rosetta task pages, text, examples, tests, submissions, or implementations were consulted. Local comparisons used package paths and README contracts.

## Concrete algorithm candidates

| Score/title | Local comparison | Disposition |
| --- | --- | --- |
| 31 — Vigenère cipher cryptanalysis | [`vigenere_cipher`](../../v/vigenere_cipher/README.md) encodes/decodes; cryptanalysis may mean several attacks and the title does not pin one. | Excluded: method under-specified by title. |
| 31 — Upside-down numbers | [`strobogrammatic_number`](../../s/strobogrammatic_number/README.md) checks whether a digit string is invariant under 180-degree rotation. | Covered/duplicate for the predicate profile. |
| 31 — Twin primes whose sum is square | [`twin_prime`](../../t/twin_prime/README.md) already checks a prime pair; the title adds a square filter but does not pin a search domain or distinct method. | Excluded as a property filter over existing primality/twin-pair operations. |
| 31 — Substring primes | No one substring-generation/prime-selection procedure is identifiable from the title. | Excluded: under-specified. |
| 31 — Radical of an integer | Prime-factorization packages expose the factors; [`sum_of_multiplicative_function_large`](../../s/sum_of_multiplicative_function_large/README.md) explicitly includes the radical as `f(p^e)=p` in its multiplicative-function family. | Excluded: direct factor-product specialization, not a new kernel. |
| 31 — Percolation mean run density | No lattice, boundary, sampling, run direction, or estimate convention is pinned by the title. | Excluded: model and method under-specified. |
| 31 — Orbital elements | No state-vector convention or conversion direction is specified by the title. | Excluded: contract under-specified. |
| 31 — Modified random distribution | No distribution or modification is identified. | Excluded: under-specified. |
| 31 — Matrix-chain multiplication | [`matrix_chain_multiplication`](../../m/matrix_chain_multiplication/README.md) is present. | Covered/duplicate. |
| 31 — Check Machin-like formulas | The title does not select a formula family, precision, or validation test. | Excluded: under-specified. |
| 30 — Word ladder | [`word_ladder`](../../w/word_ladder/README.md), [`word_ladder_dfs`](../../w/word_ladder_dfs/README.md), and shortest-path word-ladder packages already cover ladder search variants. | Covered by existing word-ladder contracts. |
| 30 — Walsh matrix | [`fast_walsh_hadamard_transform`](../../f/fast_walsh_hadamard_transform/README.md) covers the same Walsh–Hadamard sign structure; matrix-output wording alone does not pin a new method. | Excluded as a representation variant. |
| 30 — Round-robin tournament schedule | Local [`round_robin`](../round_robin/README.md) schedules CPU jobs; [`tournament_sort`](../../t/tournament_sort/README.md) sorts. Neither constructs one-factors/opponent tables for all-play-all pairings. | Selected: distinct circle-method schedule generation. |
| 30 — Polynomial derivative | No exact package path was found, but the title describes a coefficient-wise transform and does not select a substantive method beyond the defining rule. | Not selected in favor of the higher-coverage circle-method kernel. |
| 30 — Pisano period | [`pisano_period`](../../p/pisano_period/README.md) is present. | Covered/duplicate. |
| 30 — N-body problem | [`n_body_simulation`](../../n/n_body_simulation/README.md) is present. | Covered/duplicate. |
| 30 — Image convolution | [`image_convolution`](../../i/image_convolution/README.md) is present. | Covered/duplicate. |
| 30 — Fermat pseudoprimes | [`fermat_prime_checker`](../../f/fermat_prime_checker/README.md) already profiles Fermat-style primality behavior. | Covered by the existing Fermat test family. |
| 30 — Boyer–Moore string search | [`boyer_moore`](../../b/boyer_moore/README.md) implements the bad-character and good-suffix search. | Covered/duplicate. |
| 29 — Sphenic numbers | [`sphenic_number`](../../s/sphenic_number/README.md) is present. | Covered/duplicate. |
| 29 — Practical numbers | The title names a number class but does not select among divisor-sum tests, factor-sequence algorithms, or enumeration bounds. | Not selected: no source-backed method pinned by title metadata. |
| 29 — Permutations rank | [`myrvold_ruskey_permutation_unrank`](../../m/myrvold_ruskey_permutation_unrank/README.md) already profiles permutation ranking/unranking structure; the title does not pin an order convention. | Not selected: ranking convention is unspecified. |
| 29 — K-means++ clustering | [`kmeans_plus_plus_seeding`](../../k/kmeans_plus_plus_seeding/README.md) already profiles the distinctive D² seeding stage. | Covered at the algorithmic kernel level. |
| 29 — Gradient descent | Local gradient-descent and regression-optimization packages already cover fixed-step, stochastic, sequential, and mini-batch variants. | Covered by existing optimization profiles. |
| 29 — Formal power series | Multiple formal-series packages cover distinct operations; the title alone does not pin one. | Excluded: broad family title. |
| 29 — ADFGVX cipher | [`adfgvx_cipher`](../../a/adfgvx_cipher/README.md) is present. | Covered/duplicate. |

## Remaining titles in the audited slice

These title-only entries were also checked. The operation is a language/runtime
feature, output-format demonstration, UI/I/O/graphics task, game/puzzle without
a single pinned solver, or a number/domain property whose title does not
specify a bounded procedure. They were not treated as a unique algorithm
reservation.

- **Score 31:** `Table creation`; `Print-itself`; `Monads-List-monad`;
  `Matrix-digital-rain`; `Fixed-length-records`; `File-size-distribution`.
- **Score 30:** `Vibrating-rectangles`; `Sum-data-type`;
  `Solve-triangle-solitaire-puzzle`; `Solve-a-Hopido-puzzle`; `Sine-wave`;
  `Reverse-the-gender-of-a-string`; `Quoting-constructs`; `Ormiston-pairs`;
  `Nautical-bell`; `Logistic-curve-fitting-in-epidemiology`;
  `Hunt-the-Wumpus`; `Extreme-primes`;
  `Distribution-of-0-digits-in-factorial-series`;
  `Composite-numbers-k-with-no-single-digit-factors-whose-factors-are-all-substrings-of-k`;
  `Active-Directory-Connect`.
- **Score 29:** `Yahoo-search-interface`; `Sokoban`; `Smallest-numbers`;
  `Singly-linked-list-Element-removal`; `Simulate-input-Keyboard`;
  `Sign-of-an-integer-signum-`; `Sierpinski-square-curve`;
  `Self-contained-numbers`; `Safe-addition`; `Record-sound`;
  `Random-number-generator-included-`; `Numbers-which-are-not-the-sum-of-distinct-squares`;
  `Naming-conventions`; `Metallic-ratios`; `Markov-chain-text-generator`;
  `Lucky-and-even-lucky-numbers`; `Function-frequency`;
  `Compare-sorting-algorithms-performance`; `Arena-storage-pool`;
  `Anaprimes`.

Additional local matches among those entries include [`signum`](../../s/signum/README.md),
the K-means++ seeders, existing formal-series and gradient-descent families,
and generic list-removal/storage profiles. Other special-number and
simulation titles were not promoted because the title alone does not pin the
variant, input window, or output operation. This screen is discovery evidence,
not a claim that every task variant in the slice is implemented locally.

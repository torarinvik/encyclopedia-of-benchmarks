# Hajiaghayi–Sorkin Algorithm A for random 3-SAT

This bounded profile implements Algorithm A in Section 3 of Hajiaghayi and
Sorkin’s “The Satisfiability Threshold of Random 3-SAT Is at Least 3.52.”
It repeatedly makes one degree-based variable assignment, then unit-propagates
until no unit clause remains. It does not backtrack.

## Contract

- ABI: `i64_array_bytes_output`. Input is `[n,m,3*m signed one-based
  literals]`, grouped into clauses in their original order. A positive literal
  `v` means variable `v`; a negative literal `-v` means its negation.
- Bounds: `3 <= n <= 12`, `0 <= m <= 32`; every input clause has exactly
  three literals on three distinct variables. Input length is exactly
  `2 + 3*m`, at most 98 words. Duplicate clauses are allowed.
- At each free step, count positive (`i`) and negative (`j`) appearances of
  every unset variable in the current residual formula. If any variable is
  pure (`i == 0` or `j == 0`, including an unseen variable), choose the
  lowest-ID pure variable. Otherwise maximize `(|i-j|, i+j)` lexicographically
  and choose the lowest-ID variable with that score. The paper says this
  identifies one unordered degree pair; this ID rule fixes the remaining
  choice among variables having that pair.
- Preserve Algorithm A’s printed branch exactly: set the selected variable
  **True when `i < j`, and False otherwise**. Since the paper defines `i` as
  positive appearances and `j` as negative appearances, standard Boolean
  semantics make the less-frequent polarity true when `i != j`; equality
  selects False. The paper does not state a different polarity convention.
  The implementation follows the printed condition rather than changing it
  to a majority-polarity rule.
- After that free assignment, repeatedly choose the first current unit clause
  in original formula order and set its literal true. Satisfied clauses are
  removed and the assigned literal’s negation is removed from other clauses.
  If any clause becomes empty, stop with failure immediately. Otherwise keep
  choosing free variables until all variables are assigned; there is no
  backtracking.
- Output is `[success_bit, assignment[0..n)]`, little-endian signed-i64
  words. Assignment values are `1` for True, `-1` for False, and `0` for
  unset variables on a failed trace. Successful traces assign every variable.
  Invalid input returns `-1`; null output or insufficient capacity returns
  `-2` without writing. Maximum output is 104 bytes.

The explicit tie rules make the source’s arbitrary choices reproducible.
They do not change the degree-pair selection rule or the printed assignment
condition.

This procedure is distinct from
[`random_3sat_greedy_dpll`](../random_3sat_greedy_dpll/README.md): that profile
forces an existing unit clause before a free choice and otherwise sets the
most frequent signed literal true. Algorithm A first selects a variable,
prioritizes any pure variable, and ranks non-pure variables by polarity
discrepancy then total degree. It also differs from
[`random_planted_3sat_majority_vote`](../random_planted_3sat_majority_vote/README.md),
which assigns each variable once from the initial majority polarity and does
not reduce or propagate clauses. `random_planted_3sat_k_opt` performs bounded
local search from that majority assignment and is also a different profile.

## Sources and provenance

The procedure appears in “Thresholds of Random k-SAT,” Chapter 423 of the
*Encyclopedia of Algorithms*, DOI
[10.1007/978-1-4939-2864-4_423](https://doi.org/10.1007/978-1-4939-2864-4_423).
Its primary source is MohammadTaghi Hajiaghayi and Gregory B. Sorkin,
[“The Satisfiability Threshold of Random 3-SAT Is at Least 3.52”](https://doi.org/10.48550/arXiv.math/0310193),
arXiv:math/0310193, Section 3, Algorithm A. The source defines an `(i,j)`
variable as having `i` positive and `j` negative appearances, then prints
“set v True if i < j and False otherwise.” This package records that literal
condition and its standard Boolean interpretation because the resulting
polarity is easy to mistake for a majority rule.

The book and paper provide algorithm provenance, not a source-code license.
This package was written independently from their algorithm descriptions and
includes no copied source code or book prose. See [`RIGHTS.md`](RIGHTS.md).

| Language | Port |
|---|---|
| C | `c/r/random_3sat_hajiaghayi_sorkin_algorithm_a.c` |
| C3 | `c3/r/random_3sat_hajiaghayi_sorkin_algorithm_a.c3` |
| C++ | `cpp/r/random_3sat_hajiaghayi_sorkin_algorithm_a.cpp` |
| Elisa | `elisa/r/random_3sat_hajiaghayi_sorkin_algorithm_a.elisa` |
| Mojo | `mojo/r/random_3sat_hajiaghayi_sorkin_algorithm_a.mojo` |
| Nim | `nim/r/random_3sat_hajiaghayi_sorkin_algorithm_a.nim` |
| Odin | `odin/r/random_3sat_hajiaghayi_sorkin_algorithm_a.odin` |
| Rust | `rust/r/random_3sat_hajiaghayi_sorkin_algorithm_a.rs` |
| V | `v/r/random_3sat_hajiaghayi_sorkin_algorithm_a.v` |
| Zig | `zig/r/random_3sat_hajiaghayi_sorkin_algorithm_a.zig` |

The package has a mutable-clause primary oracle and a separate oracle that
rebuilds residual clauses from the original formula after each assignment.
Shared suite registration is handled separately.

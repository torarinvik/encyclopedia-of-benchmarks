# Schuler randomized general-CNF SAT

This package implements a bounded, supplied-randomness profile of Rainer
Schuler's randomized general-CNF algorithm. The source is Section 2 of
“An algorithm for the satisfiability problem of formulas in conjunctive normal
form,” *Journal of Algorithms* 54 (2005), DOI
[`10.1016/j.jalgor.2004.04.012`](https://doi.org/10.1016/j.jalgor.2004.04.012),
presented in *Encyclopedia of Algorithms*, Chapter 133,
[`10.1007/978-1-4939-2864-4_133`](https://doi.org/10.1007/978-1-4939-2864-4_133).
The PPZ subroutine follows Paturi, Pudlák, and Zane, “Satisfiability Coding
Lemma,” FOCS 1997, DOI
[`10.1109/SFCS.1997.646146`](https://doi.org/10.1109/SFCS.1997.646146).

## Contract

- ABI: `i64_array_bytes_output`. Input is a packed signed-i64 frame:
  `[n,m,(clause_length,literal...)*, tape_row*(n+1)]`.
- Bounds: `1 <= n <= 6`, `1 <= m <= 4`; each clause has 1 through `n`
  literals and no variable repeats within it. The exact valid frame has at most
  121 words. A tape row is `permutation[n], random_bits[n], clause_choice`.
- Literals are signed, one-based variable IDs: positive `v` is `x_v`, negative
  `-v` is `not x_v`. Clause and literal order are preserved.
- At each recursive call with `m0` remaining clauses, set
  `k = 1 + ceil_strict(log2(m0))`, where `ceil_strict` is the least integer
  strictly greater than its argument. This is `m0.bit_length() + 1`, including
  when `m0` is a power of two. Truncate each clause to its first `k` literals
  and run one PPZ attempt on that formula. PPZ visits every variable not fixed
  by an ancestor, in the supplied permutation order, including variables absent
  from the truncated formula. For each such variable, use its bit at that
  position in the permutation filtered to unfixed variables unless a unit
  clause forces a value. A positive unit clause takes priority over a negative
  unit clause. Variables absent from the formula therefore consume a random
  guess and are included in a successful PPZ assignment. When recursion reaches
  an empty formula, it returns the fixed branch values and defaults remaining
  values to false.
- On PPZ failure, stop with failure if every remaining clause has fewer than
  `k` literals. Otherwise, enumerate remaining clauses of length at least `k`
  in their current order. The row's zero-based `clause_choice` selects one of
  these clauses uniformly in the source algorithm; this deterministic profile
  supplies the choice directly. Falsify its first `k` literals, simplify the
  original current formula with those assignments, and recurse. A choice
  outside the current eligible set is malformed and returns `-1`.
- Each tape row gives a permutation of `1..n`, exactly `n` bits in `{0,1}`, and
  a choice in `[0,m)`. There are `n+1` rows, enough for every possible
  fixed-variable recursion. In PPZ, bits are indexed by position in the
  supplied permutation after filtering out ancestor-fixed variables, not by
  variable ID. A unit-forced variable ignores the bit at its position; an
  absent variable uses it as a random guess. Unused tape rows and bits remain
  part of the validated input frame.
- Output is six little-endian signed-i64 words:
  `[found,assignment_mask,calls,unit_forces,random_guesses,max_depth]`.
  Mask bit `v-1` gives `x_v`; failed solves emit mask zero. `calls` counts
  recursive calls, including terminal calls; force and guess totals include all
  PPZ attempts, including guesses of variables absent from the shortened
  formula; root depth is zero.
- Malformed input returns `-1`. Null output or capacity below 48 bytes returns
  `-2` without writing. Otherwise the result is 48 bytes. Input is fully
  validated and the bounded solve is completed before output-capacity handling.
- The random permutation, PPZ bits, and branch choices are supplied by the
  caller. This benchmark measures one deterministic trace and makes no
  probability, expected-time, or randomized success guarantee.

## Distinction from local SAT profiles

This is a randomized general-CNF method with PPZ attempts and recursive
falsification of a selected clause prefix. It differs from
[`procedure_s_general_cnf_sat`](../../p/procedure_s_general_cnf_sat/README.md),
which exhaustively checks shortened clauses and explores source-order branches;
from [`random_3sat_greedy_dpll`](../../r/random_3sat_greedy_dpll/README.md),
which performs a deterministic no-backtrack unit-first trace; and from
[`random_3sat_hajiaghayi_sorkin_algorithm_a`](../../r/random_3sat_hajiaghayi_sorkin_algorithm_a/README.md),
which uses current degree pairs and pure-variable priority for 3-CNF.

## References and files

- Schuler's primary algorithm: [`primary_oracle.py`](primary_oracle.py).
- Independent assignment-vector/iterative reference: [`independent_oracle.py`](independent_oracle.py).
- Bounded fixtures: [`workload.json`](workload.json).
- Clean-room provenance: [`RIGHTS.md`](RIGHTS.md).
- Port inventory: [`INVENTORY.md`](INVENTORY.md).
- The ports implement the same exported symbol,
  `schuler_randomized_general_cnf_sat`.

| Language | Port |
|---|---|
| C | [`c/s/schuler_randomized_general_cnf_sat.c`](../../../c/s/schuler_randomized_general_cnf_sat.c) |
| C3 | [`c3/s/schuler_randomized_general_cnf_sat.c3`](../../../c3/s/schuler_randomized_general_cnf_sat.c3) |
| C++ | [`cpp/s/schuler_randomized_general_cnf_sat.cpp`](../../../cpp/s/schuler_randomized_general_cnf_sat.cpp) |
| Elisa | [`elisa/s/schuler_randomized_general_cnf_sat.elisa`](../../../elisa/s/schuler_randomized_general_cnf_sat.elisa) |
| Mojo | [`mojo/s/schuler_randomized_general_cnf_sat.mojo`](../../../mojo/s/schuler_randomized_general_cnf_sat.mojo) |
| Nim | [`nim/s/schuler_randomized_general_cnf_sat.nim`](../../../nim/s/schuler_randomized_general_cnf_sat.nim) |
| Odin | [`odin/s/schuler_randomized_general_cnf_sat.odin`](../../../odin/s/schuler_randomized_general_cnf_sat.odin) |
| Rust | [`rust/s/schuler_randomized_general_cnf_sat.rs`](../../../rust/s/schuler_randomized_general_cnf_sat.rs) |
| V | [`v/s/schuler_randomized_general_cnf_sat.v`](../../../v/s/schuler_randomized_general_cnf_sat.v) |
| Zig | [`zig/s/schuler_randomized_general_cnf_sat.zig`](../../../zig/s/schuler_randomized_general_cnf_sat.zig) |

No executable checks have been run for this package.

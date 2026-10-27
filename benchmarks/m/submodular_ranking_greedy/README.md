# Submodular-ranking greedy

This package implements the chapter's greedy algorithm for submodular ranking
(SR), not only its min-sum set-cover special case. On each step it chooses the
unscheduled element `e` maximizing

`sum_i (f_i(A ∪ {e}) - f_i(A)) / (1 - f_i(A))`,

where `A` is the already scheduled set and functions with `f_i(A)=1` are
omitted. Equal scores choose the smallest element ID. The package returns the
element order, each function's first completion time, and the sum of those
times. The explicit table input makes each function's value and marginal
available without an external oracle.

## Contract

ABI: `i64_array_bytes_output`. Input is `[n,m, table_0[0..2^n), ...,
table_(m-1)[0..2^n)]`. Tables are indexed by subset bitmask. A value `v`
represents `f(A)=v/8`; every table must satisfy `f(∅)=0`, `f([n])=1`,
nonnegativity, monotonicity, and diminishing returns (submodularity).

- `1 <= n <= 5`, `1 <= m <= 4`; maximum valid input is 130 signed-i64 words.
- Selection scores use exact rational arithmetic for the shared values. IDs
  are zero-based and ties go to the lowest ID.
- Output is `[sum_of_first_completion_times, order[n], completion_times[m]]`
  as little-endian signed-i64 words, at most 80 bytes. A function completes
  at the first prefix with table value 8.
- Invalid framing, bounds, or function tables return `-1`. Null output or
  short capacity returns `-2` before writing.

The profile covers the source-described greedy SR rule on explicit finite
tables. It does not implement the chapter's LP rounding, alternative
approximation algorithms, or prove an approximation guarantee. The chapter
does not grant a code license; all implementations are clean-room from the
published mathematical rule, without copied text or code. See [RIGHTS.md](RIGHTS.md).

Source: Sungjin Im, “Min-Sum Set Cover and Its Generalizations,”
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_806`](https://doi.org/10.1007/978-1-4939-2864-4_806),
Theorem 3 discussion. The earlier [`min_sum_set_cover_greedy`](../min_sum_set_cover_greedy/README.md)
package covers only the set-valued special case where each function is a
Boolean indicator that some member has been scheduled.

| Language | Port |
| --- | --- |
| C | `c/m/submodular_ranking_greedy.c` |
| C3 | `c3/m/submodular_ranking_greedy.c3` |
| C++ | `cpp/m/submodular_ranking_greedy.cpp` |
| Elisa | `elisa/m/submodular_ranking_greedy.elisa` |
| Nim | `nim/m/submodular_ranking_greedy.nim` |
| Odin | `odin/m/submodular_ranking_greedy.odin` |
| Rust | `rust/m/submodular_ranking_greedy.rs` |
| V | `v/m/submodular_ranking_greedy.v` |
| Zig | `zig/m/submodular_ranking_greedy.zig` |

See [workload.json](workload.json), [primary oracle](../../submodular_ranking_greedy_oracle.py),
and [independent verifier oracle](../../submodular_ranking_greedy_verifier_oracle.py).

# Reservation: fractional programming by ratio bisection and knapsack DP

**Status:** Ten clean-room language ports and package-local artifacts are
written; scalar runner/verifier and root catalog integration are complete. The shared coverage ledger
records this contract before package source files were added. No programs,
scripts, tests, or checkers have been run.

## Contract

Use `i64_array_scalar` with input `[n,W,(a_i,b_i)*n]`. Accept
`1<=n<=12`, `1<=W<=32`, `0<=a_i<=1000`, `1<=b_i<=8`, and
`W<=sum(b_i)`. Return
`floor(1,000,000 * max_{S: sum(b_i)>=W}(sum(a_i)/sum(b_i)))`. Invalid,
null, malformed, or out-of-domain input returns `-1`. The maximum valid and
parseable input lengths are 26 and 27 signed 64-bit words.

## Methods and distinction

The primary searches the integer scaled ratio threshold `q` in
`0..=1,000,000,000`. For a candidate `q`, it maximizes
`sum(1,000,000*a_i-q*b_i)` among subsets whose denominator sum is at least
`W`. This feasibility problem is solved by 0/1 knapsack DP over denominator
sums capped at `W`, using two rows so each item is used at most once. The
predicate is feasible exactly when the best transformed score at `W` is
nonnegative. The returned threshold is the floor of the optimum times one
million. Complexity is `O(n*W*log(1,000,000,001))` time and `O(W)` space.

The independent reference enumerates all subsets, filters by total
denominator, compares ratios by integer cross-products, and floors the winning
scaled ratio. It does not use binary search or knapsack DP.

This denominator-threshold binary-search/knapsack workload is distinct from
[`dinkelbach_fixed_cardinality_ratio`](../../d/dinkelbach_fixed_cardinality_ratio/README.md),
which requires exactly `K` items and uses iterative Dinkelbach updates with a
top-`K` residual selector. OI Wiki's fractional-programming article discusses
both the binary-search transform and the separate Dinkelbach method.

## Provenance and rights

Method discovery and context: [OI Wiki, Fractional Programming](https://oi-wiki.org/misc/frac-programming/),
which states [CC BY-SA 4.0 and SATA terms](https://oi-wiki.org/intro/faq/).
Only the algorithm idea is used; no
source code, prose, examples, or tests are copied. The local contract,
references, fixtures, and ports are independently authored.

The package contains ten native ports, two references, a bounded workload,
README/RIGHTS/INVENTORY notes, and package-local static checker sources.
The scalar suite and root catalog integration are complete.

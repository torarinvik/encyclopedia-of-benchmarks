# Project Euler Problem 21: Amicable pair sum

## Contract

For an integer exclusive limit `n` in `2..=10000`, visit each `a` in `2..n-1`. Let `b` be the sum of the positive proper divisors of `a`. If `b > a` and the sum of the positive proper divisors of `b` is `a`, add both `a` and `b` to the result. A partner `b` is included even when `b >= n`. Invalid limits return `-1`.

For example, `n = 221` returns `504` because the pair `(220, 284)` qualifies, and `n = 1210` returns `2898` because both `(220, 284)` and `(1184, 1210)` qualify. The result is the sum of both members for every qualifying pair whose smaller member is below `n`.

The ports use divisor-pair scans for proper-divisor sums. The limit bounds the number of candidates and all accumulated results fit a signed 64-bit integer. The workload pins the canonical `n = 10000` result at `31626`.

This contract differs from [`problem21`](../problem21/README.md), which sums only amicable values strictly below the limit, and from [`amicable_pairs_below`](../../a/amicable_pairs_below/README.md), which includes only pairs whose two members are below the limit.

## Workload

[`workload.json`](workload.json) covers small limits, partner-at-limit and partner-above-limit cases, later pairs, the canonical limit, and invalid signed-i64 inputs.

## TheAlgorithms reference

- JavaScript [`Problem021.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Project-Euler/Problem021.js) imports [`AliquotSum.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/AliquotSum.js). The source scans `a = 2..n-1`, and when `b = d(a) > a` and `d(b) = a`, adds both values. The helper and source are pinned at commit `5c39e87a9a31f279c60f830ad74a845e4788a517`.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem21_pair_sum.c](../../../c/p/problem21_pair_sum.c) |
| C3 | [c3/p/problem21_pair_sum.c3](../../../c3/p/problem21_pair_sum.c3) |
| C++ | [cpp/p/problem21_pair_sum.cpp](../../../cpp/p/problem21_pair_sum.cpp) |
| Elisa | [elisa/p/problem21_pair_sum.elisa](../../../elisa/p/problem21_pair_sum.elisa) |
| Nim | [nim/p/problem21_pair_sum.nim](../../../nim/p/problem21_pair_sum.nim) |
| Odin | [odin/p/problem21_pair_sum.odin](../../../odin/p/problem21_pair_sum.odin) |
| Rust | [rust/p/problem21_pair_sum.rs](../../../rust/p/problem21_pair_sum.rs) |
| V | [v/p/problem21_pair_sum.v](../../../v/p/problem21_pair_sum.v) |
| Zig | [zig/p/problem21_pair_sum.zig](../../../zig/p/problem21_pair_sum.zig) |

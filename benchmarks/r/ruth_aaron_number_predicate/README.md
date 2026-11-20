# Ruth–Aaron number predicate

This package evaluates one bounded predicate: for `1 <= n <= 100000`, return `1` exactly when the sum of the prime factors of `n`, **counting multiplicity**, equals the corresponding sum for `n+1`; otherwise return `0`. The `i64_array_scalar` ABI accepts exactly `[n]`. Null, malformed, wrong-length, or out-of-range input returns `-1`.

For example, `8=2·2·2` has factor sum 6 and `9=3·3` also has factor sum 6, so 8 returns 1. The repeated-factor convention matters: `24` is not a match (`2+2+2+3=9`, while `5+5=10`), although 24 appears in the distinct-prime-factor variant.

## Algorithms and bounds

The primary reference and all ten native ports factor `n` and `n+1` independently by trial division. For each divisor from 2 while `d <= remaining/d`, they add `d` once for each division; any remainder greater than 1 contributes its final prime factor. The loop condition avoids computing a potentially overflowing square. Its time is `O(sqrt(n))` trial divisors for each of the two adjacent values and its scratch state is constant.

The independent reference uses a least-prime-factor sieve through `n+1`, then repeatedly removes the stored least factor to compute both sums. Its work is `O(n log log n)` for the sieve and `O(log n)` factor removals. A native table with 100002 signed 64-bit entries would occupy 800016 bytes; the declared 1048576-byte workspace leaves 248560 bytes for indices and local state. Python reference object overhead is outside the native suite workspace measurement.

For every positive integer `m`, the sum of its prime factors with multiplicity is at most `m`: it is equal for a prime, and for a composite the product of its prime factors dominates their sum. Thus the compared sums are each at most 100001 and are safely representable in signed i64. The result is exactly 0 or 1, with `-1` reserved for invalid input.

## Sources and distinction

Eric Weisstein's [MathWorld “Ruth-Aaron Pair” entry](https://mathworld.wolfram.com/Ruth-AaronPair.html) defines consecutive pairs by equal prime-factor sums and explicitly distinguishes the convention that counts multiplicities. It gives repeated-factor examples including 5, 8, 15, 77, 125, 714, and 948. The pinned [RosettaCodeData popular-task index at commit `1d475861d7141ef2fafff293d9339f56e4b0f5db`](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks) was used only for title discovery (score-24 band). No task prose, code, examples, or tests were copied. See [`RIGHTS.md`](RIGHTS.md).

Local prime-factorization and prime-filter packages expose different results. This benchmark compares two adjacent integers under the multiplicity-counting prime-factor-sum function; the conjunction is not represented by the individual factorization or primality benchmarks.

## Package artifacts

The primary trial-division reference is [`primary_oracle.py`](primary_oracle.py); the structurally independent least-prime-factor reference is [`independent_oracle.py`](independent_oracle.py). The bounded fixtures and invalid-frame cases are in [`workload.json`](workload.json). Package contents are summarized in [`INVENTORY.md`](INVENTORY.md) and [`INVENTORY.json`](INVENTORY.json); [`check_inventory.py`](check_inventory.py) and [`verify_workload.py`](verify_workload.py) provide static review helpers. The package is registered in the shared scalar runner and verifier; these tools were not run.

## Language ports

| Language | Source |
|---|---|
| C | [`c/r/ruth_aaron_number_predicate.c`](../../../c/r/ruth_aaron_number_predicate.c) |
| C3 | [`c3/r/ruth_aaron_number_predicate.c3`](../../../c3/r/ruth_aaron_number_predicate.c3) |
| C++ | [`cpp/r/ruth_aaron_number_predicate.cpp`](../../../cpp/r/ruth_aaron_number_predicate.cpp) |
| Elisa | [`elisa/r/ruth_aaron_number_predicate.elisa`](../../../elisa/r/ruth_aaron_number_predicate.elisa) |
| Mojo | [`mojo/r/ruth_aaron_number_predicate.mojo`](../../../mojo/r/ruth_aaron_number_predicate.mojo) |
| Nim | [`nim/r/ruth_aaron_number_predicate.nim`](../../../nim/r/ruth_aaron_number_predicate.nim) |
| Odin | [`odin/r/ruth_aaron_number_predicate.odin`](../../../odin/r/ruth_aaron_number_predicate.odin) |
| Rust | [`rust/r/ruth_aaron_number_predicate.rs`](../../../rust/r/ruth_aaron_number_predicate.rs) |
| V | [`v/r/ruth_aaron_number_predicate.v`](../../../v/r/ruth_aaron_number_predicate.v) |
| Zig | [`zig/r/ruth_aaron_number_predicate.zig`](../../../zig/r/ruth_aaron_number_predicate.zig) |

All package artifacts received source-only review. No programs or validation helpers were run.

# Dividuus number predicate

For a positive decimal integer `n`, this benchmark returns `1` exactly when all four of these values divide `n`: the sum of its decimal digits, the product of its decimal digits, its digital root, and its multiplicative digital root. Otherwise it returns `0`. The bounded `i64_array_scalar` ABI accepts exactly `[n]` for `1 <= n <= 100000`; invalid, null, wrong-length, or out-of-range input returns `-1`.

The product counts every digit occurrence. For example, 624 has digit sum 12, digit product 48, digital root 3, and multiplicative digital root 6; all four divide 624, so the result is 1. If any digit is zero, the digit product is zero and the predicate returns 0 because divisibility by zero is undefined. The implementation also returns 0 if a nonzero initial product reduces to multiplicative digital root 0; no remainder operation is attempted with a zero divisor.

## Algorithms and bounds

The primary reference and ten language ports extract decimal digits numerically with `% 10` and division by 10. They compute the sum and product, repeatedly apply digit sum for the digital root and digit product for the multiplicative digital root, reject zero divisors, then check the four remainders.

The independent reference forms a decimal digit vector from the number's string representation, uses a vector sum and product fold, computes the digital root with the modulo-nine identity, and reduces the product through successive string-digit products. These references therefore use different digit extraction and digital-root procedures.

For `n <= 100000`, there are at most six decimal digits; the only six-digit valid value is 100000 and has a zero digit. Thus a nonzero digit product is at most `9^5 = 59049`, the digit sum is at most 45, and both roots are at most 9. All intermediate values and outputs fit signed i64. Native ports use constant scalar state; the workspace cap is 256 bytes. The workload's largest valid and parseable frames are one and two i64 words.

## Sources and distinctness

[OEIS A118575](https://oeis.org/A118575) gives the Dividuus definition, known values, and an example for 624. It excludes zero-digit inputs in its listed computation; this package makes the resulting zero-product behavior explicit as false. The standard component definitions for [digital root](https://mathworld.wolfram.com/DigitalRoot.html) and [multiplicative digital root](https://mathworld.wolfram.com/MultiplicativeDigitalRoot.html) are cross-referenced with MathWorld. The pinned [RosettaCodeData popular-task index at commit `1d475861d7141ef2fafff293d9339f56e4b0f5db`](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks) was used only to discover the task title in the score-24 band. No task text, code, examples, or tests were copied; the contract and fixtures are clean-room.

Local packages cover some components separately: `digital_root`, `spy_number` (digit-sum equals digit-product), `harshad_number` (divisibility by digit sum), and multiplicative `number_persistence`. This profile tests their four-way divisibility conjunction, including digital-root and multiplicative-root divisors, which none of those component contracts measures.

## Package artifacts

The numeric digit-scan primary reference is [`primary_oracle.py`](primary_oracle.py); [`independent_oracle.py`](independent_oracle.py) uses decimal digit vectors and the digital-root congruence. [`workload.json`](workload.json) pins published terms, zero cases, boundary values, and invalid framing. Package metadata is in [`INVENTORY.md`](INVENTORY.md) and [`INVENTORY.json`](INVENTORY.json), with static helpers [`check_inventory.py`](check_inventory.py) and [`verify_workload.py`](verify_workload.py). The package is registered in the shared `i64_array_scalar` runner and verifier.

## Language ports

| Language | Source |
|---|---|
| C | [`c/r/dividuus_number_predicate.c`](../../../c/r/dividuus_number_predicate.c) |
| C3 | [`c3/r/dividuus_number_predicate.c3`](../../../c3/r/dividuus_number_predicate.c3) |
| C++ | [`cpp/r/dividuus_number_predicate.cpp`](../../../cpp/r/dividuus_number_predicate.cpp) |
| Elisa | [`elisa/r/dividuus_number_predicate.elisa`](../../../elisa/r/dividuus_number_predicate.elisa) |
| Mojo | [`mojo/r/dividuus_number_predicate.mojo`](../../../mojo/r/dividuus_number_predicate.mojo) |
| Nim | [`nim/r/dividuus_number_predicate.nim`](../../../nim/r/dividuus_number_predicate.nim) |
| Odin | [`odin/r/dividuus_number_predicate.odin`](../../../odin/r/dividuus_number_predicate.odin) |
| Rust | [`rust/r/dividuus_number_predicate.rs`](../../../rust/r/dividuus_number_predicate.rs) |
| V | [`v/r/dividuus_number_predicate.v`](../../../v/r/dividuus_number_predicate.v) |
| Zig | [`zig/r/dividuus_number_predicate.zig`](../../../zig/r/dividuus_number_predicate.zig) |

All package artifacts are reviewed statically. No programs or validation helpers are run.

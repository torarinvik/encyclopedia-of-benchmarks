# Numbers with prime divisor count other than two

## Contract

The exported `numbers_with_prime_divisor_count_not_two` function accepts one
signed 64-bit integer `[exclusive_limit]`, with `1 <= exclusive_limit <= 1000`.
It returns, in strictly increasing order, every positive integer `n` satisfying
`1 <= n < exclusive_limit` whose number of positive divisors is prime and not
2. Each result is encoded as one little-endian signed 64-bit word, without a
count prefix or terminator. The return value is the byte count; an empty list
returns zero. Invalid input returns `-1`; a null output pointer or a buffer too
short for the complete result returns `-2` without writing. ABI:
`i64_array_bytes_output`, symbol
`numbers_with_prime_divisor_count_not_two(i64*,length,u8*,capacity)`.

The baseline task bound is the strict range `n < 1000`, represented by
`exclusive_limit=1000`. A smaller valid limit returns the corresponding
prefix. The only qualifying values under 1000 are
`4, 9, 16, 25, 49, 64, 81, 121, 169, 289, 361, 529, 625, 729, 841, 961`.
For `n = product(p_i^e_i)`, its divisor count is `product(e_i+1)`. If that
count is prime and not 2, only one prime factor can occur and its exponent is
one less than an odd prime. Below 1000, only exponents 2, 4, and 6 fit; the
listed values are precisely the corresponding prime powers. Thus the exact
maximum output is 16 words (128 bytes).

## Algorithm and distinction

The primary ports initialize a `uint16` divisor-count table and increment the
count of every multiple of each divisor below the exclusive limit. They scan
the table in ascending order, test each count by trial division, and omit
count 2. The table has 1000 entries and uses 2000 bytes; the 4096-byte
workspace cap leaves 2096 bytes for fixed scalar bookkeeping and alignment.
Output is first counted, capacity-checked, then written directly, so errors
never leave a partial list. Each count is at most 999 and fits `uint16`.

The independent reference counts divisor pairs separately for every `n` and
applies its own trial-division primality check. This filtered list differs from
[`number_of_positive_divisors`](../number_of_positive_divisors/README.md),
which returns `tau(n)` for one input, and
[`divisors_count_sequence`](../../d/divisors_count_sequence/README.md), which
emits divisor counts by sequence index. Prime-count benchmarks count primes
in a range; this profile emits the numbers selected by their divisor counts.

The divisor-count formula is documented by [CP-Algorithms, “Number of
divisors / sum of divisors”](https://cp-algorithms.com/algebra/divisors.html);
the primality helper follows the elementary [trial division
test](https://cp-algorithms.com/algebra/primality_tests.html). The task title
was found in the [pinned RosettaCodeData popular-title index at commit
`1d475861d7141ef2fafff293d9339f56e4b0f5db`](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks).
The maintainer-supplied pinned task specification establishes the listed-number
semantics; no task code or examples were reused.

## Workload and references

[`workload.json`](workload.json) includes empty prefixes, the first qualifying
value, short prefixes, the baseline `exclusive_limit=1000`, invalid bounds and
arities, null input/output, and insufficient output capacity. The two
independent method references and static inventory sources are listed in
[`INVENTORY.md`](INVENTORY.md). They have not been run.

## Language ports

| Language | Source |
|---|---|
| C | [`c/n/numbers_with_prime_divisor_count_not_two.c`](../../../c/n/numbers_with_prime_divisor_count_not_two.c) |
| C3 | [`c3/n/numbers_with_prime_divisor_count_not_two.c3`](../../../c3/n/numbers_with_prime_divisor_count_not_two.c3) |
| C++ | [`cpp/n/numbers_with_prime_divisor_count_not_two.cpp`](../../../cpp/n/numbers_with_prime_divisor_count_not_two.cpp) |
| Elisa | [`elisa/n/numbers_with_prime_divisor_count_not_two.elisa`](../../../elisa/n/numbers_with_prime_divisor_count_not_two.elisa) |
| Mojo | [`mojo/n/numbers_with_prime_divisor_count_not_two.mojo`](../../../mojo/n/numbers_with_prime_divisor_count_not_two.mojo) |
| Nim | [`nim/n/numbers_with_prime_divisor_count_not_two.nim`](../../../nim/n/numbers_with_prime_divisor_count_not_two.nim) |
| Odin | [`odin/n/numbers_with_prime_divisor_count_not_two.odin`](../../../odin/n/numbers_with_prime_divisor_count_not_two.odin) |
| Rust | [`rust/n/numbers_with_prime_divisor_count_not_two.rs`](../../../rust/n/numbers_with_prime_divisor_count_not_two.rs) |
| V | [`v/n/numbers_with_prime_divisor_count_not_two.v`](../../../v/n/numbers_with_prime_divisor_count_not_two.v) |
| Zig | [`zig/n/numbers_with_prime_divisor_count_not_two.zig`](../../../zig/n/numbers_with_prime_divisor_count_not_two.zig) |

# Modular Bernoulli numbers

## Contract

The input is the single signed 64-bit integer `[N]`, with `0 <= N <= 32`.
Return `B_0, ..., B_N` modulo 998244353. Each value is encoded as one unsigned
32-bit little-endian integer, so a successful call writes `4 * (N + 1)` bytes
and returns that byte count. Invalid input returns `-1`; a null output or
insufficient output capacity returns `-2` without writing.

The Library Checker task asks for all values through `N` and permits
`N <= 500000`. This cross-language profile uses a deliberately bounded
quadratic recurrence, so it caps `N` at 32. With `B_0 = 1`, it uses

`B_m = -(m + 1)^(-1) * sum(binomial(m + 1, k) * B_k, k = 0..m-1) mod p`.

The modular inverses needed by the recurrence exist throughout this bound
and are computed with Fermat exponentiation. The binomial coefficient is
advanced across each row, for `O(N^2 + N log p)` time and `O(N)` workspace.
The ports write only after validating the input and output capacity.

## Distinctness

No modular Bernoulli-number recurrence was found in the local packages. The
existing `power_sum` counts subsets of distinct integer powers, while
`randomized_rounding_bernoulli` replays Bernoulli rounding decisions; neither
computes the Bernoulli number sequence.

Official task: [Library Checker — Bernoulli Number](https://github.com/yosupo06/library-checker-problems/blob/master/number_theory/bernoulli_number/task.md).

## Files

| Language | Port |
|---|---|
| C | [`c/b/bernoulli_number.c`](../../../c/b/bernoulli_number.c) |
| C3 | [`c3/b/bernoulli_number.c3`](../../../c3/b/bernoulli_number.c3) |
| C++ | [`cpp/b/bernoulli_number.cpp`](../../../cpp/b/bernoulli_number.cpp) |
| Elisa | [`elisa/b/bernoulli_number.elisa`](../../../elisa/b/bernoulli_number.elisa) |
| Nim | [`nim/b/bernoulli_number.nim`](../../../nim/b/bernoulli_number.nim) |
| Odin | [`odin/b/bernoulli_number.odin`](../../../odin/b/bernoulli_number.odin) |
| Rust | [`rust/b/bernoulli_number.rs`](../../../rust/b/bernoulli_number.rs) |
| V | [`v/b/bernoulli_number.v`](../../../v/b/bernoulli_number.v) |
| Zig | [`zig/b/bernoulli_number.zig`](../../../zig/b/bernoulli_number.zig) |
| Mojo | [`mojo/b/bernoulli_number.mojo`](../../../mojo/b/bernoulli_number.mojo) |

The bounded workload is in [`workload.json`](workload.json). The independent
exact-rational oracle is [`benchmarks/bernoulli_number_oracle.py`](../../bernoulli_number_oracle.py).

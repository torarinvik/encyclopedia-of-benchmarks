# Fortunate numbers

For one-based `n`, let `P_n` be the product of the first `n` primes. This profile returns the least integer `m > 1` for which `P_n + m` is prime. It bounds `n` to `1..=10` and searches offsets `m=2..64` in ascending order. An invalid input returns `-1`; exhausting the bounded search returns the distinct sentinel `-2`.

## Contract and bounds

The `i64_array_scalar` ABI takes exactly `[n]`. The largest primorial is `P_10=6,469,693,230`; even `P_10+64=6,469,693,294` is safely within signed 64-bit range. The first ten outputs are `3,5,7,13,23,17,19,23,37,61`, matching [OEIS A005235](https://oeis.org/A005235). All ten terms find a result within the fixed offset limit. The `-2` sentinel defines behavior if a bounded profile later includes an index whose offset is beyond the cap.

The primary ports generate primes and test each candidate with integer trial division, avoiding a square operation by checking `d <= x/d`. They use scalar state and a 128-byte workspace cap. The independent reference uses a small sieve to form `P_n`, then a segmented sieve over the candidate interval, with at most 80,435 base flags and 63 interval flags. This avoids repeating the primary's per-candidate trial-division procedure.

## Distinctness and provenance

The local [`primorial_numbers_sequence`](../primorial_numbers_sequence/README.md) returns `P_n` itself. The local Euclid–Mullin package returns a least prime factor of `P_n+1`, and the Sylvester sequence returns the full product-plus-one value. Fortunate numbers instead search for the first prime at a positive offset greater than one from the primorial.

The definition follows Eric Weisstein, [“Fortunate Prime,” MathWorld](https://mathworld.wolfram.com/FortunatePrime.html), which defines the offset by the next prime after the Euclid number `P_n+1`. [OEIS A005235](https://oeis.org/A005235) states the least-`m>1` definition and records the initial values. These sources were used for mathematical definition and sequence verification only; no code, task text, or tests were copied. See [`RIGHTS.md`](RIGHTS.md).

## Workload and inventory

[`workload.json`](workload.json) pins the first ten published terms, the maximum supported index, malformed frames, and signed 64-bit boundaries. Primary and independent references, static inventory, and ten ports are listed in [`INVENTORY.md`](INVENTORY.md). The `i64_array_scalar` runner/verifier and shared catalog registration are integrated.

## Language ports

| Language | Source |
|---|---|
| C | [`c/f/fortunate_numbers.c`](../../../c/f/fortunate_numbers.c) |
| C3 | [`c3/f/fortunate_numbers.c3`](../../../c3/f/fortunate_numbers.c3) |
| C++ | [`cpp/f/fortunate_numbers.cpp`](../../../cpp/f/fortunate_numbers.cpp) |
| Elisa | [`elisa/f/fortunate_numbers.elisa`](../../../elisa/f/fortunate_numbers.elisa) |
| Mojo | [`mojo/f/fortunate_numbers.mojo`](../../../mojo/f/fortunate_numbers.mojo) |
| Nim | [`nim/f/fortunate_numbers.nim`](../../../nim/f/fortunate_numbers.nim) |
| Odin | [`odin/f/fortunate_numbers.odin`](../../../odin/f/fortunate_numbers.odin) |
| Rust | [`rust/f/fortunate_numbers.rs`](../../../rust/f/fortunate_numbers.rs) |
| V | [`v/f/fortunate_numbers.v`](../../../v/f/fortunate_numbers.v) |
| Zig | [`zig/f/fortunate_numbers.zig`](../../../zig/f/fortunate_numbers.zig) |

Package files have received source-only review. No programs or validation helpers were run.

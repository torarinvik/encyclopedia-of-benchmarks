# Generalized Chinese remainder theorem

This package benchmarks the CP-Algorithms method for congruences whose moduli may share factors. Each modulus is decomposed into prime powers. For each prime, the strongest supplied prime-power congruence is retained; all weaker congruences for that prime are checked for consistency. The remaining distinct-prime-power moduli are pairwise coprime and can be combined by CRT.

## Contract

The i64_array_scalar input is [Q,r0,m0,...], where 1<=Q<=4. Each modulus is in 2..64, each residue is canonical in [0,m), and the product of all supplied moduli is at most 16,777,216. Return the least nonnegative solution modulo the least common multiple of the moduli. Return -2 when the system is inconsistent and -1 for malformed or out-of-profile input. Valid input lengths are 3, 5, 7, or 9 words; length 10 is parseable for trailing-word rejection.

The primary reference consolidates constraints by prime power, then combines the retained coprime moduli. The independent reference merges the original congruences in order using the extended Euclidean algorithm, without factoring moduli. The primary uses O(Q*M + M log M) arithmetic work and O(M) fixed workspace, where M=64; the independent reference uses O(Q log M) arithmetic work and constant auxiliary space. All values remain within signed 64-bit bounds.

## Provenance and rights

The clean-room implementation follows the “Solution for not coprime moduli” section in [CP-Algorithms — Chinese Remainder Theorem](https://cp-algorithms.com/algebra/chinese-remainder-theorem.html#solution-for-not-coprime-moduli). CP-Algorithms is licensed CC BY-SA 4.0. This package uses the algorithm description only; it does not copy upstream code, prose, examples, or problem statements. See [RIGHTS.md](RIGHTS.md) and [workload.json](workload.json).

## Language ports

| Language | Source |
|---|---|
| C | [generalized_chinese_remainder_theorem.c](../../../c/g/generalized_chinese_remainder_theorem.c) |
| C3 | [generalized_chinese_remainder_theorem.c3](../../../c3/g/generalized_chinese_remainder_theorem.c3) |
| C++ | [generalized_chinese_remainder_theorem.cpp](../../../cpp/g/generalized_chinese_remainder_theorem.cpp) |
| Elisa | [generalized_chinese_remainder_theorem.elisa](../../../elisa/g/generalized_chinese_remainder_theorem.elisa) |
| Mojo | [generalized_chinese_remainder_theorem.mojo](../../../mojo/g/generalized_chinese_remainder_theorem.mojo) |
| Nim | [generalized_chinese_remainder_theorem.nim](../../../nim/g/generalized_chinese_remainder_theorem.nim) |
| Odin | [generalized_chinese_remainder_theorem.odin](../../../odin/g/generalized_chinese_remainder_theorem.odin) |
| Rust | [generalized_chinese_remainder_theorem.rs](../../../rust/g/generalized_chinese_remainder_theorem.rs) |
| V | [generalized_chinese_remainder_theorem.v](../../../v/g/generalized_chinese_remainder_theorem.v) |
| Zig | [generalized_chinese_remainder_theorem.zig](../../../zig/g/generalized_chinese_remainder_theorem.zig) |

The shared `i64_array_scalar` runner and verifier register this workload. No programs or checks have been run.

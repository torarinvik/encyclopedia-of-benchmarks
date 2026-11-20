# Continued fraction convergents

Given finite simple continued-fraction coefficients, emit the numerator and denominator of every successive convergent. For coefficients a0, a1, ..., each prefix is evaluated by the recurrence p_k = a_k*p_(k-1)+p_(k-2), q_k = a_k*q_(k-1)+q_(k-2), initialized with p_-2=0, p_-1=1, q_-2=1, q_-1=0.

## Contract

The i64_array_bytes_output input is [Q,a0,...,a(Q-1)]. Require 1<=Q<=16, -1000<=a0<=1000, and 1<=a_i<=8 for i>0. Emit 2Q signed 64-bit values in order as [p0,q0,p1,q1,...], using little-endian bytes. Success returns 16Q. Invalid input returns -1; null output or capacity below 16Q returns -2 without writing. Valid input lengths are 2 through 17 words; length 18 is parseable for trailing-word rejection. The bounds keep all numerator and denominator recurrence values within signed 64-bit range.

The primary reference follows the linear convergent recurrence in O(Q) time and O(1) auxiliary space. The independent reference evaluates each coefficient prefix from the tail in O(Q^2) total time. The ports stage no dynamic data and use fixed scalar recurrence state.

## Provenance and rights

The method follows the “Convergents” section of [CP-Algorithms — Continued fractions](https://cp-algorithms.com/algebra/continued-fractions.html#convergents), licensed CC BY-SA 4.0. This package uses the recurrence description only; all contracts, references, fixtures, and code are independently written. No code, prose, or examples were copied. See [RIGHTS.md](RIGHTS.md) and [workload.json](workload.json).

## Language ports

| Language | Source |
|---|---|
| C | [continued_fraction_convergents.c](../../../c/c/continued_fraction_convergents.c) |
| C3 | [continued_fraction_convergents.c3](../../../c3/c/continued_fraction_convergents.c3) |
| C++ | [continued_fraction_convergents.cpp](../../../cpp/c/continued_fraction_convergents.cpp) |
| Elisa | [continued_fraction_convergents.elisa](../../../elisa/c/continued_fraction_convergents.elisa) |
| Mojo | [continued_fraction_convergents.mojo](../../../mojo/c/continued_fraction_convergents.mojo) |
| Nim | [continued_fraction_convergents.nim](../../../nim/c/continued_fraction_convergents.nim) |
| Odin | [continued_fraction_convergents.odin](../../../odin/c/continued_fraction_convergents.odin) |
| Rust | [continued_fraction_convergents.rs](../../../rust/c/continued_fraction_convergents.rs) |
| V | [continued_fraction_convergents.v](../../../v/c/continued_fraction_convergents.v) |
| Zig | [continued_fraction_convergents.zig](../../../zig/c/continued_fraction_convergents.zig) |

The shared byte-output suite registration is maintained separately.

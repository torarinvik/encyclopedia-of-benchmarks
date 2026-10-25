# Embench AHA Montgomery multiply

This package is a clean-room bounded implementation of the Montgomery reduction primitive used by Embench-IoT's aha-mont64. It is distinct from the repository's generic modular multiplication and from the source benchmark's full fourth-power correctness loop. No source code or source comments have been copied.

## Contract

Export embench_aha_mont64 using the i64_array_scalar ABI. Input is exactly [a, b, m], where m is odd and 3 <= m <= 2^63-1, and 0 <= a,b < m. Interpret a and b as Montgomery-domain residues. The return value is the reduced Montgomery product a*b*R^-1 mod m with fixed R=2^64, in [0,m). Invalid frames or values return -1.

The ports calculate mprime=-m^-1 mod 2^64, form the exact 128-bit product using 32-bit limbs, apply Montgomery reduction, handle the possible 65th quotient bit, and conditionally subtract the modulus. The odd-modulus and <2^63 bounds make the 64-bit input/output ABI safe and keep signed conversion unambiguous.

The upstream benchmark additionally computes the Montgomery parameters with extended binary GCD, evaluates (a*b)^4 mod m through repeated reductions, computes a conventional modular result, and compares the two under Embench's repeat/scaling harness. This bounded package takes a, b, and m directly and measures the individual Montgomery multiplication operation; it excludes the GCD setup, exponentiation loop, workload constants, and harness.

## Provenance and rights

- Upstream: https://github.com/embench/embench-iot
- Pin: commit 09c2ed8c3b7008c95d08b038de4a3f6dc103ed70
- Source: src/aha-mont64/mont64.c, symbol montmul. The source identifies itself as GPL-3.0-or-later and attributes the benchmark to James Pallister and Jeremy Bennett.
- Embench repository license: GPL-3.0; see upstream COPYING: https://github.com/embench/embench-iot/blob/09c2ed8c3b7008c95d08b038de4a3f6dc103ed70/COPYING

These ports were independently written from the mathematical operation and source-level contract. They do not copy or translate the GPL source implementation or comments. The upstream license and attribution are recorded here for provenance; this README does not claim to relicense the upstream program.

workload.json records source pin, bounds, and fixtures. embench_aha_mont64_oracle.py is an independent arbitrary-precision model using the mathematical Montgomery result.

| Language | Port |
|---|---|
| C | c/a/embench_aha_mont64.c |
| C3 | c3/a/embench_aha_mont64.c3 |
| C++ | cpp/a/embench_aha_mont64.cpp |
| Elisa | elisa/a/embench_aha_mont64.elisa |
| Nim | nim/a/embench_aha_mont64.nim |
| Odin | odin/a/embench_aha_mont64.odin |
| Rust | rust/a/embench_aha_mont64.rs |
| V | v/a/embench_aha_mont64.v |
| Zig | zig/a/embench_aha_mont64.zig |

No runtime or compiler verification is claimed.

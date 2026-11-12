# Polynomial root finding

This package returns all distinct roots in `F_998244353` of a supplied
polynomial. Roots are emitted in ascending order, regardless of multiplicity.

## Bounded contract

The input is `[N,f_0,...,f_N]` in ascending coefficient order, with
`0<=N<=8`, coefficients in `[0,998244352]`, and nonzero leading coefficient.
The output is `[root_count, root_0, ...]`, encoded as little-endian signed
64-bit integers. The maximum input is 10 words and maximum output is 72 bytes.
Malformed input returns `-1`; valid input with null or undersized output
returns `-2` without writes.

## Algorithms

The ports compute `gcd(f,x^p-x)` modulo `f`, which removes repeated factors
and retains exactly the roots in the base field. They split this squarefree
product with Cantor-Zassenhaus quadratic-character tests using deterministic
polynomial candidates seeded from the coefficients. Each factor gets 32
candidate attempts before a deterministic fallback scans shifts `x+c` over
the field. For any two distinct roots, the quadratic-character correlation
of `x+c` at those roots is `-1`; therefore at least one shift separates them.
This gives a correctness-preserving fallback, though its worst case scans the
fixed field. With the tiny degree bound, ordinary candidate attempts are
expected to split factors quickly.

The independent oracle determines the number of roots in the base field from
`deg(gcd(f,x^p-x))`, then evaluates the polynomial at field elements in
increasing order until it has found that many roots. Its worst-case cost is
`O(pN)`, so it is intended only for the small, named workload fixtures.

## Source and rights

Official statement: [Library Checker — Polynomial Root Finding](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/polynomial_root_finding/task.md).
Official limits: [info.toml](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/polynomial_root_finding/info.toml).
The official task permits `N<=4000`; this clean-room profile uses `N<=8`.
See [RIGHTS.md](RIGHTS.md) for the source repository license note.

Workload and static package inventory: [workload.json](workload.json) and
[verify_workload.py](verify_workload.py). The workload is registered with the
shared byte-output runner and independent verifier.

| Language | Source |
|---|---|
| C | [c/p/polynomial_root_finding.c](../../../c/p/polynomial_root_finding.c) |
| C3 | [c3/p/polynomial_root_finding.c3](../../../c3/p/polynomial_root_finding.c3) |
| C++ | [cpp/p/polynomial_root_finding.cpp](../../../cpp/p/polynomial_root_finding.cpp) |
| Elisa | [elisa/p/polynomial_root_finding.elisa](../../../elisa/p/polynomial_root_finding.elisa) |
| Mojo | [mojo/p/polynomial_root_finding.mojo](../../../mojo/p/polynomial_root_finding.mojo) |
| Nim | [nim/p/polynomial_root_finding.nim](../../../nim/p/polynomial_root_finding.nim) |
| Odin | [odin/p/polynomial_root_finding.odin](../../../odin/p/polynomial_root_finding.odin) |
| Rust | [rust/p/polynomial_root_finding.rs](../../../rust/p/polynomial_root_finding.rs) |
| V | [v/p/polynomial_root_finding.v](../../../v/p/polynomial_root_finding.v) |
| Zig | [zig/p/polynomial_root_finding.zig](../../../zig/p/polynomial_root_finding.zig) |

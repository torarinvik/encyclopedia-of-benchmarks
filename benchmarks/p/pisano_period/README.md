# Pisano period

Return the least positive period of the Fibonacci sequence modulo a positive
integer `m`. This measures period search, not one Fibonacci value. The local
[`fibonacci_matrix_exponentiation`](../fibonacci_matrix_exponentiation/README.md)
package computes `F(n) mod m` for a supplied index using binary matrix
exponentiation; it does not determine the period.

## Contract

The `i64_array_scalar` input is exactly `[m]`, with `1<=m<=64`. Length one is
the only valid frame; length two is accepted for parsing and rejected as a
trailing-word probe. Null, malformed, or out-of-range input returns `-1`.

Define `F_0=0`, `F_1=1`, and `F_(n+2)=F_(n+1)+F_n`. Return the least positive
`k` for which `(F_k mod m,F_(k+1) mod m)=(0,1 mod m)`. The initial pair
`(0,1 mod m)` is not itself accepted as an answer; at least one transition is
performed. For `m=1`, both initial residues are zero and the conventional
Pisano period is one.

The primary ports iterate the modular pair and stop at its first return. The
independent reference scans `k=1..6m` and computes each consecutive Fibonacci
pair by fast doubling. Wall's bound `pi(m)<=6m` makes the search complete for
the supported domain. The bound is inclusive.

## Sources and provenance

- [OEIS A001175](https://oeis.org/A001175) catalogs Pisano periods.
- [MathWorld, “Pisano Period”](https://mathworld.wolfram.com/PisanoPeriod.html)
  defines the least positive period and cites Wall (1960) and Wrench (1969).
- Peele and Stanica, [“Matrix Powers of Column-Justified Pascal Triangles and
  Fibonacci Sequences”](https://www.fq.math.ca/Scanned/40-2/peele.pdf), notes
  the general `6m` period bound and cites the solution by Freyd and Brown to
  American Mathematical Monthly problem E3410. Freyd and Brown's solution is
  [E3410](https://doi.org/10.2307/2325076).
- [CP-Algorithms, “Fibonacci Numbers”](https://cp-algorithms.com/algebra/fibonacci-numbers.html)
  gives the doubling identities used by the independent reference.
- The [Algovault README index](https://github.com/sgtlaugh/algovault) was used
  only to discover its “Pisano Period” title. No repository implementation
  code was read or reused.

The implementations and workload are clean-room. See [RIGHTS.md](RIGHTS.md).

## Workload and inventory

[`workload.json`](workload.json) covers modulus one, familiar small periods,
the `6m` bound at modulus ten, the maximum supported modulus, and malformed
frames. [`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py) use different search methods.
The source inventory and static checker are listed in
[`INVENTORY.md`](INVENTORY.md); the checker has not been run.

## Language ports

| Language | Source |
|---|---|
| C | [`c/p/pisano_period.c`](../../../c/p/pisano_period.c) |
| C3 | [`c3/p/pisano_period.c3`](../../../c3/p/pisano_period.c3) |
| C++ | [`cpp/p/pisano_period.cpp`](../../../cpp/p/pisano_period.cpp) |
| Elisa | [`elisa/p/pisano_period.elisa`](../../../elisa/p/pisano_period.elisa) |
| Mojo | [`mojo/p/pisano_period.mojo`](../../../mojo/p/pisano_period.mojo) |
| Nim | [`nim/p/pisano_period.nim`](../../../nim/p/pisano_period.nim) |
| Odin | [`odin/p/pisano_period.odin`](../../../odin/p/pisano_period.odin) |
| Rust | [`rust/p/pisano_period.rs`](../../../rust/p/pisano_period.rs) |
| V | [`v/p/pisano_period.v`](../../../v/p/pisano_period.v) |
| Zig | [`zig/p/pisano_period.zig`](../../../zig/p/pisano_period.zig) |

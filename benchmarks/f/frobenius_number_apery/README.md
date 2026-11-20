# Frobenius number by residue shortest paths

This package computes the largest nonnegative integer that cannot be written
as a nonnegative integer combination of a bounded set of positive
denominations. It uses an Apéry set represented by shortest distances in a
residue graph.

## Contract

- ABI: `i64_array_scalar`; symbol: `frobenius_number_apery`.
- Input is `[m, c_0, ..., c_(m-1)]`, with exactly `m+1` signed 64-bit words.
- `2 <= m <= 4`; each denomination is an integer from 2 through 16; values
  must be distinct and have greatest common divisor 1. Denominations may be
  supplied in any order.
- Return the Frobenius number, the greatest nonnegative integer not expressible
  as a nonnegative combination of the denominations. Invalid framing or
  out-of-domain inputs return `-1`.
- The primary chooses `a=min(c_i)` and runs dense Dijkstra over residues
  `0..a-1`; a denomination `c` supplies an edge from residue `r` to
  `(r+c) mod a` of weight `c`. Its shortest distance `w[r]` is the least
  representable number in that residue. The Frobenius number is
  `max_r(w[r])-a`.
- Since `a<=15`, every reachable residue has a shortest simple path of at most
  `a-1` edges. Every edge costs at most 16, so `max(w)<=224` and the answer is
  at most `16(a-1)-a=15a-16<=209`. The bound is attained by denominations
  `{15,16}`. All valid results fit signed 64-bit arithmetic.
- The primary performs at most `a` scans of `a` residues and relaxes at most
  `m` edges per selected residue: `O(m*a^2)` time and `O(a)` state. The
  independent reference performs boolean unbounded reachability DP through
  amount 224: `O(m*224)` time and 225 boolean states. Native primary ports use
  128 bytes for 16 i64 distances and 16 bytes for visited flags. Odin copies
  at most four denominations into another 32-byte fixed array, and V copies
  the at most six-word frame into a 48-byte fixed array; Mojo stores the same
  distance and visited payloads in two bounded 16-slot lists. The largest
  explicit native state payload is 192 bytes; the declared kernel workspace
  cap is 256 bytes, excluding the caller-owned input frame and allocator
  bookkeeping.

The Apéry set used here stores, for each residue modulo the least generator,
the least representable number in that residue. The set has one member per
residue when the generators have gcd 1, and the Frobenius number equals its
maximum minus the modulus. This differs from [`minimum_coin_change_combinations`](../../m/minimum_coin_change_combinations/README.md),
[`minimum_coin_change_greedy`](../../m/minimum_coin_change_greedy/README.md),
and [`dynamic_coin_change_solver`](../../d/dynamic_coin_change_solver/README.md),
which find or count representations of one supplied amount; this profile finds
the greatest amount with no representation.

## Source and provenance

The RosettaCodeData popular-title index was used only to discover the
“Frobenius numbers” title. The algorithm contract follows the Apéry-set
characterization and Frobenius formula stated by J. L. Ramírez Alfonsín and
Ø. J. Rødseth, “Numerical Semigroups: Apéry Sets and Hilbert Series,”
*Semigroup Forum* 79(2) (2009), 323–340, and the original formula of Brauer
and Shockley, “On a problem of Frobenius,” *Journal für die reine und
angewandte Mathematik* 211 (1962), 215–220. The paper describes the least
representative in each residue and gives `F=max(Apéry)-a`.

- [Ramírez Alfonsín and Rødseth paper](https://imag.umontpellier.fr/~ramirez/Frobenius-Hilbert.pdf)
- [Ramírez Alfonsín publication record](https://doi.org/10.1007/s00233-009-9133-5)
- [Brauer and Shockley article record](https://doi.org/10.1515/crll.1962.211.215)
- [RosettaCodeData title index](https://raw.githubusercontent.com/acmeism/RosettaCodeData/main/popular-tasks)

The ports and fixtures are clean-room descriptions of the mathematical
method. No Rosetta Code code, task prose, or fixture values were copied.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/f/frobenius_number_apery.c`](../../../c/f/frobenius_number_apery.c) |
| C3 | [`c3/f/frobenius_number_apery.c3`](../../../c3/f/frobenius_number_apery.c3) |
| C++ | [`cpp/f/frobenius_number_apery.cpp`](../../../cpp/f/frobenius_number_apery.cpp) |
| Elisa | [`elisa/f/frobenius_number_apery.elisa`](../../../elisa/f/frobenius_number_apery.elisa) |
| Mojo | [`mojo/f/frobenius_number_apery.mojo`](../../../mojo/f/frobenius_number_apery.mojo) |
| Nim | [`nim/f/frobenius_number_apery.nim`](../../../nim/f/frobenius_number_apery.nim) |
| Odin | [`odin/f/frobenius_number_apery.odin`](../../../odin/f/frobenius_number_apery.odin) |
| Rust | [`rust/f/frobenius_number_apery.rs`](../../../rust/f/frobenius_number_apery.rs) |
| V | [`v/f/frobenius_number_apery.v`](../../../v/f/frobenius_number_apery.v) |
| Zig | [`zig/f/frobenius_number_apery.zig`](../../../zig/f/frobenius_number_apery.zig) |

`primary_oracle.py` and `independent_oracle.py` provide independent bounded
references. The ten ports are registered in the shared `i64_array_scalar`
runner and verifier.

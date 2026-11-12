# SPLASH-2-inspired direct water interaction scan

This bounded profile isolates an all-pairs intermolecular force-accumulation
shape associated with SPLASH-2 Water-Nsquared. It is an algorithmic projection,
not a reproduction of the SPLASH water force field, predictor-corrector
integrator, periodic simulation, or synchronization scheme. The benchmark uses
a newly specified rational pair law so that every port and oracle can compute
the same bounded integer result without relying on a molecular-dynamics
runtime.

## Contract

- ABI: `i64_array_bytes_output`; exported symbol: `splash2_water_nsquared`.
- Input: `[N,G,R,(x,y,z,q)*]`. `N` is 0..64, `G` is 1..8, `R` is 1..4,
  coordinates are integers in `[0,G*R)`, and each integer charge `q` is in
  -4..4. The box is nonperiodic.
- The direct method visits every unordered pair `i<j`. Let `d=(xj-xi,yj-yi,zj-zi)`,
  `r2=d·d`, and `R2=R*R`. Pairs with `r2 >= R2` contribute nothing. For each
  accepted pair, define `U = qi*qj*(R2-r2)/((1+r2)*(1+R2))` and force on `i`
  `F_i = -2*qi*qj*d/(1+r2)^2`; force on `j` is `-F_i`.
- Scale each pair's potential and each force component independently by
  1,000,000 and truncate the signed quotient toward zero before accumulation.
  Output is `[Fx,Fy,Fz]` for each molecule in input order, then total scaled
  potential, then accepted-pair count, as little-endian signed 64-bit words.
- Output size is exactly `8*(3*N+2)` bytes (16..1552). Invalid input returns
  `-1`; a null or undersized output buffer returns `-2` without writes.

The direct scan costs `O(N^2)` pair checks, with `O(N)` molecule and force
storage. Its `water_spatial` counterpart uses the same pair law and contract
with a 27-cell neighbor search. The local gravity benchmarks use inverse-square
Newtonian laws, and LavaMD uses an exponential screened interaction, so their
force models and outputs differ.

The primary oracle independently evaluates each pair using integer rational
numerators and denominators, then applies signed truncation toward zero. It
enumerates all `i<j` pairs directly, including rejected cutoff pairs.

## Provenance and rights

SPLASH-2 describes Water-Nsquared as a molecular-dynamics workload whose
intermolecular-force phase examines molecule pairs under a cutoff. The source
reference below supports that algorithmic context only; its physical force
model is not used by this bounded profile. All formulas, workload fixtures,
ports, and oracle code here were written independently.

- [SPLASH-2 Water-Nsquared source overview](https://github.com/staceyson/splash2/blob/master/codes/apps/water-nsquared/interf.C)
- [SPLASH-2 benchmark description](https://pages.cs.wisc.edu/~markhill/restricted/isca95_splash2.pdf)

The referenced 1994 Stanford source states a non-commercial use permission and
restricts redistribution of its code. This package does not include or copy that
source code. It records the source only as provenance for the high-level
all-pairs/cutoff workload concept.

## Ports

| Language | Source |
|---|---|
| C | [`c/s/splash2_water_nsquared.c`](../../../c/s/splash2_water_nsquared.c) |
| C3 | [`c3/s/splash2_water_nsquared.c3`](../../../c3/s/splash2_water_nsquared.c3) |
| C++ | [`cpp/s/splash2_water_nsquared.cpp`](../../../cpp/s/splash2_water_nsquared.cpp) |
| Elisa | [`elisa/s/splash2_water_nsquared.elisa`](../../../elisa/s/splash2_water_nsquared.elisa) |
| Mojo | [`mojo/s/splash2_water_nsquared.mojo`](../../../mojo/s/splash2_water_nsquared.mojo) |
| Nim | [`nim/s/splash2_water_nsquared.nim`](../../../nim/s/splash2_water_nsquared.nim) |
| Odin | [`odin/s/splash2_water_nsquared.odin`](../../../odin/s/splash2_water_nsquared.odin) |
| Rust | [`rust/s/splash2_water_nsquared.rs`](../../../rust/s/splash2_water_nsquared.rs) |
| V | [`v/s/splash2_water_nsquared.v`](../../../v/splash2_water_nsquared.v) |
| Zig | [`zig/s/splash2_water_nsquared.zig`](../../../zig/s/splash2_water_nsquared.zig) |

The independent oracle is [`splash2_water_nsquared_oracle.py`](../../splash2_water_nsquared_oracle.py).

# Bareiss fraction-free determinant

This benchmark computes the exact signed determinant of a small square integer
matrix using pivoted Bareiss elimination. It uses the Sylvester-identity update
to keep every elimination value integral, with cubic work in the matrix
dimension. This is distinct from the repository's [`determinant`](../determinant/README.md)
cofactor-expansion benchmark and from determinant routines over finite fields,
which use arithmetic with modular inverses or residue-specific elimination.

The `i64_array_scalar` input is `[N, row-major N*N entries]`, where
`1 <= N <= 8` and each entry is in `[-4,4]`. The return value is the exact
signed determinant. Malformed input returns `INT64_MIN`. The maximum valid and
parseable frame lengths are 65 and 66 signed 64-bit values. Hadamard's bound
keeps every result within `[-268435456,268435456]`; intermediate fraction-free
products also fit signed 64-bit arithmetic at these bounds. The declared
workspace is 4096 bytes.

The primary method performs row-pivoted Bareiss elimination. At each stage it
updates a trailing entry with `(pivot * entry - column_factor * pivot_row_entry)`
divided exactly by the previous pivot. It tracks the sign of row exchanges and
returns zero when the remaining pivot column has no nonzero candidate. The
independent oracle evaluates the Leibniz determinant by enumerating column
permutations and applying inversion parity.

The algorithm is based on Erwin H. Bareiss, “Sylvester's identity and multistep
integer-preserving Gaussian elimination,” *Mathematics of Computation* 22(103),
1968, [official AMS paper](https://www.ams.org/mcom/1968-22-103/S0025-5718-1968-0226829-0/S0025-5718-1968-0226829-0.pdf),
[DOI](https://doi.org/10.1090/S0025-5718-1968-0226829-0). The ports are clean-room
implementations of the mathematical method; no paper code or prose is copied.

Package files include a bounded workload, primary and independent Python
oracles, and a static ten-port inventory checker. The scalar suite validates
the fixture and generated matrices against both algorithms. No programs,
tests, checkers, scripts, builds, compilers, or benchmarks were run while
preparing this package.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/b/bareiss_determinant.c`](../../../c/b/bareiss_determinant.c) |
| C3 | [`c3/b/bareiss_determinant.c3`](../../../c3/b/bareiss_determinant.c3) |
| C++ | [`cpp/b/bareiss_determinant.cpp`](../../../cpp/b/bareiss_determinant.cpp) |
| Elisa | [`elisa/b/bareiss_determinant.elisa`](../../../elisa/b/bareiss_determinant.elisa) |
| Mojo | [`mojo/b/bareiss_determinant.mojo`](../../../mojo/b/bareiss_determinant.mojo) |
| Nim | [`nim/b/bareiss_determinant.nim`](../../../nim/b/bareiss_determinant.nim) |
| Odin | [`odin/b/bareiss_determinant.odin`](../../../odin/b/bareiss_determinant.odin) |
| Rust | [`rust/b/bareiss_determinant.rs`](../../../rust/b/bareiss_determinant.rs) |
| V | [`v/b/bareiss_determinant.v`](../../../v/b/bareiss_determinant.v) |
| Zig | [`zig/b/bareiss_determinant.zig`](../../../zig/b/bareiss_determinant.zig) |

Static package review: [`verify_bareiss_determinant_package.py`](verify_bareiss_determinant_package.py).

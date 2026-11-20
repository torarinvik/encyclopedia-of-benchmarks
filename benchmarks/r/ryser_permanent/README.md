# Ryser matrix permanent

Compute the exact signed permanent of a small square integer matrix. The
permanent sums one product for every row-to-column bijection, without the
alternating permutation signs used by a determinant. This is distinct from the
local cofactor-expansion [`determinant`](../../d/determinant/README.md) and
fraction-free [`bareiss_determinant`](../../b/bareiss_determinant/README.md)
profiles; those return a different matrix function.

## Contract

The `i64_array_scalar` input is `[N,row-major N*N entries]`, with `1<=N<=8`
and entries in `[-4,4]`. The frame must contain exactly `1+N*N` signed 64-bit
values. The result is the exact signed 64-bit permanent. Malformed input
returns `INT64_MIN`. The maximum valid and parseable lengths are 65 and 66
words. A result has absolute value at most `8!*4^8 = 2,642,411,520`; the
Ryser intermediate sum is also safely within signed 64-bit range because each
row sum has magnitude at most 32 and there are at most 256 terms.

The primary evaluates Ryser's inclusion-exclusion sum over all subsets of
columns in binary-reflected Gray-code order. Between adjacent subsets one
column changes, so each row sum is updated by one matrix entry before forming
the next product. This takes `O(N*2^N)` arithmetic operations. The independent
reference enumerates all `N!` column permutations and adds each unsigned
product from the permanent's definition.

## Sources and provenance

The formula and Gray-code update are described in Eric W. Weisstein,
[“Ryser Formula,” Wolfram MathWorld](https://mathworld.wolfram.com/RyserFormula.html).
The independent permanent definition and its distinction from the determinant
appear in the [MIT permanent lecture notes](https://people.csail.mit.edu/rrw/presentations/DHMTW12final.pdf).
The RosettaGit task-title index entry “Determinant and permanent” was used only
to discover this missing operation. Ports are clean-room implementations of
the cited algorithm ideas; no task statement, submission, source code, or
prose was copied. See [RIGHTS.md](RIGHTS.md) for attribution details.

## Workload and source review

[`workload.json`](workload.json) covers singleton, identity, signed entries,
nontrivial 3-by-3 and maximum-size matrices, zero output, malformed frames,
and null input. [`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py) implement the two separate
methods. [`verify_ryser_permanent_package.py`](verify_ryser_permanent_package.py)
contains static workload, provenance, and ten-port inventory checks. The
package has not been executed or benchmarked.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/r/ryser_permanent.c`](../../../c/r/ryser_permanent.c) |
| C3 | [`c3/r/ryser_permanent.c3`](../../../c3/r/ryser_permanent.c3) |
| C++ | [`cpp/r/ryser_permanent.cpp`](../../../cpp/r/ryser_permanent.cpp) |
| Elisa | [`elisa/r/ryser_permanent.elisa`](../../../elisa/r/ryser_permanent.elisa) |
| Mojo | [`mojo/r/ryser_permanent.mojo`](../../../mojo/r/ryser_permanent.mojo) |
| Nim | [`nim/r/ryser_permanent.nim`](../../../nim/r/ryser_permanent.nim) |
| Odin | [`odin/r/ryser_permanent.odin`](../../../odin/r/ryser_permanent.odin) |
| Rust | [`rust/r/ryser_permanent.rs`](../../../rust/r/ryser_permanent.rs) |
| V | [`v/r/ryser_permanent.v`](../../../v/r/ryser_permanent.v) |
| Zig | [`zig/r/ryser_permanent.zig`](../../../zig/r/ryser_permanent.zig) |

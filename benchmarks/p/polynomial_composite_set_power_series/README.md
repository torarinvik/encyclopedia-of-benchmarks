# Polynomial composition in a set power series

This benchmark evaluates the univariate polynomial f(z) = sum(a[k] z^k) at an
N-variable set power series s in the square-zero algebra x_j^2 = 0. It returns
all coefficients in increasing dense mask order, modulo 998244353.

The bounded profile has 0 <= N <= 4 and zero through eight polynomial
coefficients. Its primary algorithm uses Horner composition with subset
convolution, in O(M*3^N) time and O(2^N) workspace. The independent oracle
expands each power directly by assigning every variable to no factor or to one
of the ordered copies of s, in O(M + sum_(k=1)^(M-1) k*(k+1)^N) time for
this bounded profile.

Input words are [M, N, a_0, ..., a_(M-1), b_0, ..., b_(2^N-1)]. Coefficients
must be residues from 0 through 998244352; M=0 is the zero polynomial. A valid
input has at most 26 signed 64-bit words, while parsers bound initial
inspection at 27 words and then require exact shape. Output has 2^N
little-endian signed 64-bit residues, at most 128 bytes. The ABI returns the
exact output byte count on success, -1 for malformed input, and -2 for a null
output or insufficient capacity. Errors do not write output. Maximum working
storage is 512 bytes.

The operation and official limits come from Library Checker’s
[task statement](https://github.com/yosupo06/library-checker-problems/blob/master/set_power_series/polynomial_composite_set_power_series/task.md)
and [parameter file](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/set_power_series/polynomial_composite_set_power_series/info.toml).

| Language | Port |
|---|---|
| C | [c/p/polynomial_composite_set_power_series.c](../../../c/p/polynomial_composite_set_power_series.c) |
| C3 | [c3/p/polynomial_composite_set_power_series.c3](../../../c3/p/polynomial_composite_set_power_series.c3) |
| C++ | [cpp/p/polynomial_composite_set_power_series.cpp](../../../cpp/p/polynomial_composite_set_power_series.cpp) |
| Elisa | [elisa/p/polynomial_composite_set_power_series.elisa](../../../elisa/p/polynomial_composite_set_power_series.elisa) |
| Mojo | [mojo/p/polynomial_composite_set_power_series.mojo](../../../mojo/p/polynomial_composite_set_power_series.mojo) |
| Nim | [nim/p/polynomial_composite_set_power_series.nim](../../../nim/p/polynomial_composite_set_power_series.nim) |
| Odin | [odin/p/polynomial_composite_set_power_series.odin](../../../odin/p/polynomial_composite_set_power_series.odin) |
| Rust | [rust/p/polynomial_composite_set_power_series.rs](../../../rust/p/polynomial_composite_set_power_series.rs) |
| V | [v/p/polynomial_composite_set_power_series.v](../../../v/p/polynomial_composite_set_power_series.v) |
| Zig | [zig/p/polynomial_composite_set_power_series.zig](../../../zig/p/polynomial_composite_set_power_series.zig) |

The [primary oracle](primary_oracle.py) and [independent oracle](independent_oracle.py)
provide the fixture models in [workload.json](workload.json). The static port and
fixture inventory checker is [verify_workload.py](verify_workload.py). This package
is registered in the shared byte-output runner and verifier.

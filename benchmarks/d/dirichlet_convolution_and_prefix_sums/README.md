# Dirichlet convolution prefix sums on quotient values

Given `N` and the cumulative values `F(q)=sum_{i<=q} f(i)` and
`G(q)=sum_{i<=q} g(i)` for every distinct `q=floor(N/x)`, return
`H(q)=sum_{ij<=q} f(i)g(j) mod 998244353` in ascending quotient order. The
local profile uses one case per ABI call and `1<=N<=64`; it accepts the
officially required positive residues `1..998244352`.

For a fixed output value `x`, group indices `i` by `q=floor(x/i)`. Each group
is the interval `[floor(x/(q+1))+1, floor(x/q)]`, so its `f` sum is a difference
of two supplied prefix values. The primary computes
`H(x)=sum_q (F(floor(x/q))-F(floor(x/(q+1))))*G(q)` over quotient blocks. The
independent oracle uses the commutativity of Dirichlet convolution and groups
the `j` indices instead, multiplying `g`-interval sums by `F(q)`. Both run in
`O(|Q_N|^2)` time and use `O(|Q_N|)` auxiliary space for this bounded profile.

The input is `[N,F(q_0),...,F(q_(K-1)),G(q_0),...,G(q_(K-1))]`, where the
`q_i` are the sorted values in `Q_N`. Output is one little-endian signed i64
residue for each `q_i`. The local limits are 31 valid input words, 32
parseable words, 120 output bytes, and 1024 workspace bytes. Invalid input
returns `-1`; null or short output returns `-2` without writing. The official
task supports `N<=10^12` and a stream of cases; this bounded profile represents
each case as a separate call.

This is distinct from [`gcd_convolution`](../../g/gcd_convolution/README.md)
and [`lcm_convolution`](../../l/lcm_convolution/README.md), whose indices are
combined by GCD or LCM, and from
[`sum_of_multiplicative_function_large`](../../s/sum_of_multiplicative_function_large/README.md),
which sums a specified multiplicative-function family. Here both input
functions are arbitrary and are supplied by their quotient-set prefix values.

Source: [Library Checker — Dirichlet Convolution and Prefix Sums](https://github.com/yosupo06/library-checker-problems/blob/master/number_theory/dirichlet_convolution_and_prefix_sums/task.md),
[official limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/number_theory/dirichlet_convolution_and_prefix_sums/info.toml),
and [problem proposal](https://github.com/yosupo06/library-checker-problems/issues/1336).
The upstream repository is Apache-2.0. This benchmark uses only the mathematical
contract and algorithm description; the ports and fixtures are clean-room.
See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the two oracle
modules, and the static package checker.

| Language | Port |
|---|---|
| C | [`c/d/dirichlet_convolution_and_prefix_sums.c`](../../../c/d/dirichlet_convolution_and_prefix_sums.c) |
| C3 | [`c3/d/dirichlet_convolution_and_prefix_sums.c3`](../../../c3/d/dirichlet_convolution_and_prefix_sums.c3) |
| C++ | [`cpp/d/dirichlet_convolution_and_prefix_sums.cpp`](../../../cpp/d/dirichlet_convolution_and_prefix_sums.cpp) |
| Elisa | [`elisa/d/dirichlet_convolution_and_prefix_sums.elisa`](../../../elisa/d/dirichlet_convolution_and_prefix_sums.elisa) |
| Mojo | [`mojo/d/dirichlet_convolution_and_prefix_sums.mojo`](../../../mojo/d/dirichlet_convolution_and_prefix_sums.mojo) |
| Nim | [`nim/d/dirichlet_convolution_and_prefix_sums.nim`](../../../nim/d/dirichlet_convolution_and_prefix_sums.nim) |
| Odin | [`odin/d/dirichlet_convolution_and_prefix_sums.odin`](../../../odin/d/dirichlet_convolution_and_prefix_sums.odin) |
| Rust | [`rust/d/dirichlet_convolution_and_prefix_sums.rs`](../../../rust/d/dirichlet_convolution_and_prefix_sums.rs) |
| V | [`v/d/dirichlet_convolution_and_prefix_sums.v`](../../../v/d/dirichlet_convolution_and_prefix_sums.v) |
| Zig | [`zig/d/dirichlet_convolution_and_prefix_sums.zig`](../../../zig/d/dirichlet_convolution_and_prefix_sums.zig) |

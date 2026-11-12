# Square Root of a Formal Power Series

This package computes one formal square root of the first `N` coefficients of
a series over `F_998244353`. The official task allows `1<=N<=500000`; this
bounded profile uses `1<=N<=64`.

## Contract and root selection

The `i64_array_bytes_output` call accepts `[N, a_0, ..., a_(N-1)]`, with each
coefficient in `[0,998244352]`. It returns coefficients `b_0` through
`b_(N-1)` such that `g(x)^2 = f(x) mod x^N`. When roots exist, the package
selects one deterministically: if `f` is zero modulo `x^N`, choose `g=0`; if
the first nonzero coefficient is `a_v`, require even `v=2s` and choose the
least nonnegative modular square root of `a_v` as `b_s`. The remaining
constrained coefficients follow uniquely from the coefficient recurrence;
unconstrained coefficients above the required shifted degree are zero. This
fixes the sign ambiguity allowed by the official task.

If no root exists, the output is one signed 64-bit value `-1` and the call
returns 8 bytes. A valid root result contains `N` signed 64-bit values and
returns `8*N` bytes. Malformed input returns `-1`; a null output or capacity
below `8*N` returns `-2`, without writes. The full `8*N` capacity is required
even when the input has no root. Output integers are little-endian and all
successful root coefficients are canonical residues in `[0,998244352]`.
The maximum valid input has 65 words, the maximum parseable input has 66
words, the output is at most 512 bytes, and workspace is bounded at 1,024
bytes.

## Algorithm

The primary implementation finds the leading coefficient's canonical square
root with Tonelli-Shanks, then solves each next coefficient from
`2*b_s*b_(s+k) = a_(2s+k) - sum(b_(s+i)*b_(s+k-i), i=1..k-1)` modulo the
prime. The recurrence costs `O(N^2)` and is bounded to at most 1,953 inner
cross terms at `N=64`. The independent oracle uses Cipolla's finite-field
square-root construction and the binomial expansion of `sqrt(1+u)` with
direct truncated polynomial products.

## Provenance and rights

The operation and official limits come from Library Checker's [Square Root
of Formal Power Series task](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/sqrt_of_formal_power_series/task.md),
its [parameter file](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/sqrt_of_formal_power_series/info.toml),
and the upstream [Apache-2.0 license](https://github.com/yosupo06/library-checker-problems/blob/master/LICENSE).
The local bound, canonical root rule, workload, oracles, documentation, and
ports are clean-room work based on the mathematical operation; no upstream
source code, prose, tests, or expected output files were reused. See
[`RIGHTS.md`](RIGHTS.md).

[`workload.json`](workload.json) lists fixtures and ABI bounds.
[`verify_workload.py`](verify_workload.py) statically checks fixture/oracle
agreement, rights, and all ten source paths without launching the ports.
The workload is registered with the shared byte-output runner and verifier. No
programs, tests, or checkers were run during suite integration.

## Ports

| Language | Source |
|---|---|
| C | [`c/s/sqrt_of_formal_power_series.c`](../../../c/s/sqrt_of_formal_power_series.c) |
| C3 | [`c3/s/sqrt_of_formal_power_series.c3`](../../../c3/s/sqrt_of_formal_power_series.c3) |
| C++ | [`cpp/s/sqrt_of_formal_power_series.cpp`](../../../cpp/s/sqrt_of_formal_power_series.cpp) |
| Elisa | [`elisa/s/sqrt_of_formal_power_series.elisa`](../../../elisa/s/sqrt_of_formal_power_series.elisa) |
| Mojo | [`mojo/s/sqrt_of_formal_power_series.mojo`](../../../mojo/s/sqrt_of_formal_power_series.mojo) |
| Nim | [`nim/s/sqrt_of_formal_power_series.nim`](../../../nim/s/sqrt_of_formal_power_series.nim) |
| Odin | [`odin/s/sqrt_of_formal_power_series.odin`](../../../odin/s/sqrt_of_formal_power_series.odin) |
| Rust | [`rust/s/sqrt_of_formal_power_series.rs`](../../../rust/s/sqrt_of_formal_power_series.rs) |
| V | [`v/s/sqrt_of_formal_power_series.v`](../../../v/s/sqrt_of_formal_power_series.v) |
| Zig | [`zig/s/sqrt_of_formal_power_series.zig`](../../../zig/s/sqrt_of_formal_power_series.zig) |

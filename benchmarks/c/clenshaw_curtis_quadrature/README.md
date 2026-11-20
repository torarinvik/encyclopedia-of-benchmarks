# Clenshaw–Curtis quadrature

This package evaluates the bounded closed Clenshaw–Curtis rule from [NIST DLMF §3.5(iv), Eq. 3.5.16](https://dlmf.nist.gov/3.5.E16). It is a fixed interpolatory quadrature rule on Chebyshev–Lobatto nodes, not a Gaussian rule or an adaptive refinement procedure. Existing Romberg, Simpson, Weddle, Gauss–Kronrod, and Gaussian–Legendre profiles therefore cover different methods. `chebyshev_clenshaw_evaluation` evaluates a polynomial and does not integrate samples.

## Contract

Input is `[n, f0, ..., fn]`, with even `n` in `2..=16`. The samples correspond in this exact order to `x_k = cos(k*pi/n)`, for `k=0..n`, so the sequence of nodes descends from `1` to `-1`. Each sample must be finite and satisfy `abs(f_k) <= 1000`. The result is the integral estimate over `[-1,1]`; the benchmark does not evaluate a function or compute the nodes.

For each sample index `k`, the primary computes

```text
w_k = (g_k / n) * (1 - sum(j=1..n/2,
      (b_j / (4*j*j - 1)) * cos((2*j*k*pi)/n)))
g_k = 1 at k=0,n; otherwise 2
b_j = 1 at j=n/2; otherwise 2
result = sum(k=0..n, w_k*f_k)
```

All sums proceed in ascending index order and use left-to-right binary64 additions. Each cosine argument is evaluated as `(((2*j)*k)*pi)/n`; the weight is then formed in the written order, followed by the outer weighted sum in ascending `k`. Ports must not use fast-math reassociation. `n=2` is included and `n=16` is the largest rule.

The independent reference uses the DCT-I Chebyshev coefficients from the Lobatto-node discrete orthogonality formula in [DLMF §3.11(ii), Eq. 3.11.9](https://dlmf.nist.gov/3.11.E9), then integrates the Chebyshev series using [Eq. 3.11.11](https://dlmf.nist.gov/3.11.E11): odd modes integrate to zero, `integral(T_j)=2/(1-j*j)` for even `j`, and the two endpoint coefficients have half weight. This computes the same interpolating polynomial through a coefficient transform rather than forming the Clenshaw–Curtis nodal weights.

The ABI uses `float64_slice_io`. Valid frames have `n+2` words, at most 18; the parser accepts a maximum framing length of 19 so a trailing-word error is testable. Success writes one float64 and returns `1`. Malformed or null input returns `-1`; valid input with null output or capacity below one returns `-2` without writes. Input errors take precedence. The output comparison uses absolute tolerance `1e-9` and relative tolerance `1e-12`.

The primary evaluates a nested sum for each of `n+1` nodes, so it uses O(n²) time and O(1) internal scratch. The DCT-I independent reference also uses O(n²) time and O(n) coefficient scratch. The workload's one element / eight byte workspace entry describes the caller-provided output buffer.

See [`workload.json`](workload.json), [`RIGHTS.md`](RIGHTS.md), the [primary weight reference](primary_oracle.py), and the [independent DCT-I reference](independent_oracle.py). The package-local static inventory helper is [`check_inventory.py`](check_inventory.py); the fixture/reference agreement helper is [`verify_workload.py`](verify_workload.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/clenshaw_curtis_quadrature.c`](../../../c/c/clenshaw_curtis_quadrature.c) |
| C3 | [`c3/c/clenshaw_curtis_quadrature.c3`](../../../c3/c/clenshaw_curtis_quadrature.c3) |
| C++ | [`cpp/c/clenshaw_curtis_quadrature.cpp`](../../../cpp/c/clenshaw_curtis_quadrature.cpp) |
| Elisa | [`elisa/c/clenshaw_curtis_quadrature.elisa`](../../../elisa/c/clenshaw_curtis_quadrature.elisa) |
| Mojo | [`mojo/c/clenshaw_curtis_quadrature.mojo`](../../../mojo/c/clenshaw_curtis_quadrature.mojo) |
| Nim | [`nim/c/clenshaw_curtis_quadrature.nim`](../../../nim/c/clenshaw_curtis_quadrature.nim) |
| Odin | [`odin/c/clenshaw_curtis_quadrature.odin`](../../../odin/c/clenshaw_curtis_quadrature.odin) |
| Rust | [`rust/c/clenshaw_curtis_quadrature.rs`](../../../rust/c/clenshaw_curtis_quadrature.rs) |
| V | [`v/c/clenshaw_curtis_quadrature.v`](../../../v/c/clenshaw_curtis_quadrature.v) |
| Zig | [`zig/c/clenshaw_curtis_quadrature.zig`](../../../zig/c/clenshaw_curtis_quadrature.zig) |

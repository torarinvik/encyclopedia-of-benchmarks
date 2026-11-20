# Fornberg finite-difference weights

Generate the weights for one derivative order at one point on an arbitrary
ordered set of distinct grid nodes, using Fornberg's triangular recurrence over
the finite field `F_998244353`.

## Contract

The `i64_array_bytes_output` input is `[n,m,xbar,x0,...,x(n-1)]`. Require
`1<=n<=8`, `0<=m<=min(3,n-1)`, canonical residues in `[0,998244352]` for
`xbar` and every node, pairwise-distinct nodes, and exactly `n+3` input words.
The evaluation point may equal a node, and node order is significant to the
recurrence's leading-subset updates. Maximum valid and parseable frames are 11
and 12 words.

On success, emit `[n,c0,...,c(n-1)]` as little-endian signed-i64 words, where
`ci` is the coefficient multiplying the function value at `xi` in the
order-`m` derivative formula at `xbar`. The success result is `8*(n+1)` bytes,
at most 72. Invalid, null, noncanonical, duplicate-node, wrong-order, or
trailing-frame input returns `-1` with no output. A null output or insufficient
capacity returns `-2` with no output. Input validity is checked before output
capacity. All arithmetic is modulo `998244353`; node differences are invertible
because the nodes are distinct.

The native recurrence keeps an 8-by-4 coefficient table (256 bytes), one
four-entry saved row (32 bytes), up to 72 bytes of Elisa result staging, scalar
recurrence state, and alignment margin within a 512-byte workspace cap. It
performs `O(n^2*m + n^2 log p)` modular operations using
Fermat inverses for field divisions. The
independent reference constructs the derivative moment system and solves it by
Gauss-Jordan elimination in `O(n^3 + n log p)` operations and `O(n^2)` scratch.

## Source and distinction

Bengt Fornberg's paper, [“Generation of Finite Difference Formulas on
Arbitrarily Spaced Grids”](https://doi.org/10.1090/S0025-5718-1988-0935077-0),
§2 gives the two triangular recurrences, requires distinct ordered nodes, and
allows the evaluation point to coincide with a node. The [author-hosted paper
PDF](https://www.colorado.edu/amath/sites/default/files/attached-files/mathcomp_88_fd_formulas.pdf)
is the algorithm source. NIST DLMF [§3.4](https://dlmf.nist.gov/3.4) provides
related finite-difference context for equally spaced nodes.

This is not a duplicate of `barycentric_lagrange_evaluation`, which evaluates
one interpolating polynomial value using barycentric rational sums, or of
`polynomial_interpolation` and `newton_divided_difference_interpolation`,
which construct or evaluate polynomial representations. This package exposes
Fornberg's node-by-node derivative-weight recurrence and returns its weight
vector. The algorithm is re-expressed from the mathematical recurrence; no
implementation code, paper prose, or published tables are copied. See
[`RIGHTS.md`](RIGHTS.md).

## Package artifacts

`workload.json` pins exact weight vectors, framing failures, null paths, and
the maximum-output/capacity boundary. `primary_oracle.py` implements the
triangular recurrence; `independent_oracle.py` solves the polynomial moment
system. `verify_workload.py` and `check_inventory.py` provide static package
APIs; neither is required during ordinary source review.

| Language | Source |
|---|---|
| C | [fornberg_finite_difference_weights.c](../../../c/f/fornberg_finite_difference_weights.c) |
| C3 | [fornberg_finite_difference_weights.c3](../../../c3/f/fornberg_finite_difference_weights.c3) |
| C++ | [fornberg_finite_difference_weights.cpp](../../../cpp/f/fornberg_finite_difference_weights.cpp) |
| Elisa | [fornberg_finite_difference_weights.elisa](../../../elisa/f/fornberg_finite_difference_weights.elisa) |
| Mojo | [fornberg_finite_difference_weights.mojo](../../../mojo/f/fornberg_finite_difference_weights.mojo) |
| Nim | [fornberg_finite_difference_weights.nim](../../../nim/f/fornberg_finite_difference_weights.nim) |
| Odin | [fornberg_finite_difference_weights.odin](../../../odin/f/fornberg_finite_difference_weights.odin) |
| Rust | [fornberg_finite_difference_weights.rs](../../../rust/f/fornberg_finite_difference_weights.rs) |
| V | [fornberg_finite_difference_weights.v](../../../v/f/fornberg_finite_difference_weights.v) |
| Zig | [fornberg_finite_difference_weights.zig](../../../zig/f/fornberg_finite_difference_weights.zig) |

The package is registered with the shared `i64_array_bytes_output` runner,
independent verifier, and catalog. No programs, tests, scripts, helpers,
checkers, builds, compilers, profilers, or benchmarks have been run.

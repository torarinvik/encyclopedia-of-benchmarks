# Concave/arbitrary min-plus convolution

This package implements the Library Checker operation
`c[k] = min(a[i] + b[j])` for `i+j=k`, where `a` is discrete concave and `b`
is arbitrary. Input is `[N,M,a[0..N),b[0..M)]`; `1<=N,M<=32`, values are in
`[0,1_000_000_000]`, and adjacent differences of `a` are nonincreasing.

## Bounded algorithm profile

This is distinct from the convex/arbitrary package's single row-minimum
divide-and-conquer. A global reversed argmin bound is incorrect on the
convolution's staircase domain: when `N=1`, every output has the unique
minimizer `j=k`, which increases. The reference solution instead transposes
the concave operand into a staircase matrix. This package clean-room ports
that method's structure:

1. Partition the output-index/arbitrary-index staircase into rectangles.
2. On a rectangle wholly inside the feasible region, use monotone minima after
   reversing the arbitrary-index coordinate for the concave operand.
3. For a boundary rectangle, directly scan it when the dimension-difference
   product is below 1000; otherwise split the longer dimension at the moving
   staircase boundary and recurse.

The bounded implementation uses the same direct-scan cutoff and boundary
splitting rule as the reviewed reference structure. This profile does not claim
a generalized asymptotic bound beyond the bounded 32-element inputs.

The ABI is `i64_array_bytes_output`, symbol
`min_plus_convolution_concave_arbitrary`. Invalid frames, values, or
nonconcave `a` return `-1` before output checks. Valid input with null output
or capacity below `8*(N+M-1)` returns `-2` without writes. Success returns
`N+M-1` little-endian signed 64-bit values. Maximum valid input is 66 words,
parseable limit 67, and output staging bound 504 bytes.

## Source and rights

The source is the Apache-2.0 licensed Library Checker repository:
[task](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/min_plus_convolution_concave_arbitrary/task.md),
[limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/min_plus_convolution_concave_arbitrary/info.toml),
[reference solution structure](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/min_plus_convolution_concave_arbitrary/sol/correct.cpp),
[repository license](https://github.com/yosupo06/library-checker-problems/blob/master/LICENSE).
See [RIGHTS.md](RIGHTS.md). The verifier oracle uses independent direct scans.

## Package files

Workload fixtures: [workload.json](workload.json). Primary oracle:
[`min_plus_convolution_concave_arbitrary_oracle.py`](../../min_plus_convolution_concave_arbitrary_oracle.py).
Independent verifier oracle:
[`min_plus_convolution_concave_arbitrary_verifier_oracle.py`](../../min_plus_convolution_concave_arbitrary_verifier_oracle.py).

## Language ports

| Language | Port |
|---|---|
| C | [`c/m/min_plus_convolution_concave_arbitrary.c`](../../../c/m/min_plus_convolution_concave_arbitrary.c) |
| C3 | [`c3/m/min_plus_convolution_concave_arbitrary.c3`](../../../c3/m/min_plus_convolution_concave_arbitrary.c3) |
| C++ | [`cpp/m/min_plus_convolution_concave_arbitrary.cpp`](../../../cpp/m/min_plus_convolution_concave_arbitrary.cpp) |
| Elisa | [`elisa/m/min_plus_convolution_concave_arbitrary.elisa`](../../../elisa/m/min_plus_convolution_concave_arbitrary.elisa) |
| Mojo | [`mojo/m/min_plus_convolution_concave_arbitrary.mojo`](../../../mojo/m/min_plus_convolution_concave_arbitrary.mojo) |
| Nim | [`nim/m/min_plus_convolution_concave_arbitrary.nim`](../../../nim/m/min_plus_convolution_concave_arbitrary.nim) |
| Odin | [`odin/m/min_plus_convolution_concave_arbitrary.odin`](../../../odin/m/min_plus_convolution_concave_arbitrary.odin) |
| Rust | [`rust/m/min_plus_convolution_concave_arbitrary.rs`](../../../rust/m/min_plus_convolution_concave_arbitrary.rs) |
| V | [`v/m/min_plus_convolution_concave_arbitrary.v`](../../../v/m/min_plus_convolution_concave_arbitrary.v) |
| Zig | [`zig/m/min_plus_convolution_concave_arbitrary.zig`](../../../zig/m/min_plus_convolution_concave_arbitrary.zig) |

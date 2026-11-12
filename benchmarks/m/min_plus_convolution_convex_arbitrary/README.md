# Convex/arbitrary min-plus convolution

This package implements the one-dimensional operation in the Library Checker
task `min_plus_convolution_convex_arbitrary`:

`c[k] = min(a[i] + b[j])` over `i+j=k`, for `0 <= k < N+M-1`.

The first sequence `a` is discrete convex: its adjacent differences are
nondecreasing. The second sequence is arbitrary. The primary oracle and ports
use monotone divide-and-conquer minima over the Monge cost matrix
`a[k-j] + b[j]`; equal minima choose the smallest `j`. The verifier oracle
uses a direct scan for each output index. This bounded profile uses `1<=N,M<=32`
and entries in `[0,1_000_000_000]`.

## ABI

The symbol and package ID are `min_plus_convolution_convex_arbitrary`, using
`i64_array_bytes_output`. Input is `[N,M,a[0..N),b[0..M)]`. A malformed frame,
out-of-range value, or nonconvex `a` returns `-1`. For valid input, a null
output or capacity below `8*(N+M-1)` returns `-2`. Errors write no output.
Successful output is `N+M-1` signed 64-bit values in little-endian order.
Maximum valid input length is 66 words; the parseable framing limit is 67.
Maximum output and staging buffer are 504 bytes.

The convex/convex task has a distinct linear-time algorithm: merge the two
nondecreasing first-difference sequences and prefix-sum the merged slopes.
That method is different from the monotone divide-and-conquer minima used here
and belongs in a separate benchmark. The approach is described in the
[AtCoder algorithm lecture on min-plus convolution](https://info.atcoder.jp/entry/algorithm_lectures/min_plus_convolution).
Concave/arbitrary is also **not** included: its feasible indices form a
staircase, so the global row-minimum bounds used by this package do not apply.

## Source and rights

The source is the Apache-2.0 licensed Library Checker repository:
[task statement](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/min_plus_convolution_convex_arbitrary/task.md),
[task limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/min_plus_convolution_convex_arbitrary/info.toml),
[repository license](https://github.com/yosupo06/library-checker-problems/blob/master/LICENSE).
Implementations here are clean-room and do not reproduce source code or task
prose. See [RIGHTS.md](RIGHTS.md).

Workload fixtures are in [workload.json](workload.json). The primary and
independent oracles are
[`min_plus_convolution_convex_arbitrary_oracle.py`](../../min_plus_convolution_convex_arbitrary_oracle.py)
and
[`min_plus_convolution_convex_arbitrary_verifier_oracle.py`](../../min_plus_convolution_convex_arbitrary_verifier_oracle.py).

## Language ports

| Language | Port |
|---|---|
| C | [`c/m/min_plus_convolution_convex_arbitrary.c`](../../../c/m/min_plus_convolution_convex_arbitrary.c) |
| C3 | [`c3/m/min_plus_convolution_convex_arbitrary.c3`](../../../c3/m/min_plus_convolution_convex_arbitrary.c3) |
| C++ | [`cpp/m/min_plus_convolution_convex_arbitrary.cpp`](../../../cpp/m/min_plus_convolution_convex_arbitrary.cpp) |
| Elisa | [`elisa/m/min_plus_convolution_convex_arbitrary.elisa`](../../../elisa/m/min_plus_convolution_convex_arbitrary.elisa) |
| Mojo | [`mojo/m/min_plus_convolution_convex_arbitrary.mojo`](../../../mojo/m/min_plus_convolution_convex_arbitrary.mojo) |
| Nim | [`nim/m/min_plus_convolution_convex_arbitrary.nim`](../../../nim/m/min_plus_convolution_convex_arbitrary.nim) |
| Odin | [`odin/m/min_plus_convolution_convex_arbitrary.odin`](../../../odin/m/min_plus_convolution_convex_arbitrary.odin) |
| Rust | [`rust/m/min_plus_convolution_convex_arbitrary.rs`](../../../rust/m/min_plus_convolution_convex_arbitrary.rs) |
| V | [`v/m/min_plus_convolution_convex_arbitrary.v`](../../../v/m/min_plus_convolution_convex_arbitrary.v) |
| Zig | [`zig/m/min_plus_convolution_convex_arbitrary.zig`](../../../zig/m/min_plus_convolution_convex_arbitrary.zig) |

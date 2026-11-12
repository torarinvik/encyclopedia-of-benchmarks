# Convex/convex min-plus convolution

This package computes the one-dimensional min-plus convolution of two discrete
convex integer sequences:

`c[k] = min(a[i] + b[j])` over `i + j = k`, for `0 <= k < N + M - 1`.

Both input sequences have nondecreasing adjacent differences. Their first
difference sequences are therefore sorted already. The ports merge those two
slope sequences and prefix-sum from `a[0] + b[0]`, taking `O(N+M)` time. This
is materially different from the neighboring convex/arbitrary package, which
uses monotone divide-and-conquer minima, and from concave/arbitrary convolution,
which has a clipped feasible-index staircase. Matrix min-plus products and
APSP packages also have different inputs and outputs.

The local profile bounds both dimensions to `1..128` and entries to
`0..1,000,000,000`. Input is `[N,M,a[0..N),b[0..M)]`. The symbol is
`min_plus_convolution_convex_convex`, using `i64_array_bytes_output`. Success
returns the number of output bytes and writes `N+M-1` little-endian signed
64-bit values. Invalid dimensions, frames, values, or convexity return `-1`;
valid input with a null output or insufficient capacity returns `-2`. Errors
leave output untouched. The maximum valid and parseable input lengths are 258
and 259 words; the maximum staged output is 2,040 bytes.

The official task permits dimensions up to 524,288 and values through
1,000,000,000. The reduced local bound keeps the independent direct oracle
bounded at `O(NM)` while still giving the linear-time ports a substantial
workload.

## Provenance and rights

The operation and official limits come from the Apache-2.0 licensed Library
Checker repository. The linear slope-merge derivation follows the explanation
in AtCoder's [Algorithm Lecture on convex min-plus convolution]. No upstream
implementation code is copied; the ports and both oracle paths are clean-room.
See [RIGHTS.md](RIGHTS.md).

- [Library Checker task](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/min_plus_convolution_convex_convex/task.md)
- [Library Checker limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/min_plus_convolution_convex_convex/info.toml)
- [AtCoder Algorithm Lecture on min-plus convolution](https://info.atcoder.jp/entry/algorithm_lectures/min_plus_convolution)

The direct oracle scans feasible pairs for each output index. The independent
verifier constructs output by merging slopes. The workload and package checker
compare both paths, including malformed input and output-capacity behavior:
[`workload.json`](workload.json),
[`min_plus_convolution_convex_convex_oracle.py`](../../min_plus_convolution_convex_convex_oracle.py),
[`min_plus_convolution_convex_convex_verifier_oracle.py`](../../min_plus_convolution_convex_convex_verifier_oracle.py),
[`verify_workload.py`](verify_workload.py).

## Language ports

| Language | Port |
|---|---|
| C | [`c/m/min_plus_convolution_convex_convex.c`](../../../c/m/min_plus_convolution_convex_convex.c) |
| C3 | [`c3/m/min_plus_convolution_convex_convex.c3`](../../../c3/m/min_plus_convolution_convex_convex.c3) |
| C++ | [`cpp/m/min_plus_convolution_convex_convex.cpp`](../../../cpp/m/min_plus_convolution_convex_convex.cpp) |
| Elisa | [`elisa/m/min_plus_convolution_convex_convex.elisa`](../../../elisa/m/min_plus_convolution_convex_convex.elisa) |
| Mojo | [`mojo/m/min_plus_convolution_convex_convex.mojo`](../../../mojo/m/min_plus_convolution_convex_convex.mojo) |
| Nim | [`nim/m/min_plus_convolution_convex_convex.nim`](../../../nim/m/min_plus_convolution_convex_convex.nim) |
| Odin | [`odin/m/min_plus_convolution_convex_convex.odin`](../../../odin/m/min_plus_convolution_convex_convex.odin) |
| Rust | [`rust/m/min_plus_convolution_convex_convex.rs`](../../../rust/m/min_plus_convolution_convex_convex.rs) |
| V | [`v/m/min_plus_convolution_convex_convex.v`](../../../v/m/min_plus_convolution_convex_convex.v) |
| Zig | [`zig/m/min_plus_convolution_convex_convex.zig`](../../../zig/m/min_plus_convolution_convex_convex.zig) |

[Algorithm Lecture on convex min-plus convolution]: https://info.atcoder.jp/entry/algorithm_lectures/min_plus_convolution

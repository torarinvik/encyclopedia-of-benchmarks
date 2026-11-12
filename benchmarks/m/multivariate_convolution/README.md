# Truncated multivariate convolution

This package implements Library Checker `multivariate_convolution`, multiplying
coefficient arrays modulo each `x_axis^N_axis`. The resulting quotient is
truncated: a pair whose coordinate sum reaches an axis dimension contributes
nothing to the output. Coefficients are reduced modulo the fixed prime
998244353.

This is not the cyclic profile in
[`multivariate_convolution_cyclic`](../multivariate_convolution_cyclic/README.md):
that package uses the quotient by `(1-x_axis^N_axis)` and wraps coordinate
sums instead of discarding them, with a task-supplied prime coefficient field.

The bounded profile accepts at most three axes with product of dimensions at
most 32. Axis 0 varies fastest in the flattened arrays. Each port enumerates
all coefficient pairs, decodes their coordinates, and discards out-of-box
sums. This is O(P²), at most 1024 pair visits; it does not claim the scale of
the task's large transform algorithms.

## ABI

Symbol: `multivariate_convolution`, ABI `i64_array_bytes_output`. Input is
`[K,dimensions[K],f[P],g[P]]`, where `P` is the dimension product; for `K=0`,
`P=1`. Each dimension is at least 2 and `P<=32`; coefficients are in
`[0,998244352]`. Invalid input returns `-1` before capacity checks. Valid
input with null output or capacity below `8*P` returns `-2` without writes.
Success writes `P` little-endian signed 64-bit coefficients. Maximum valid
input is 68 words, parseable limit 69, output maximum 256 bytes.

## Source and rights

The operation and coefficient modulus come from the Apache-2.0 licensed
Library Checker repository: [task](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/multivariate_convolution/task.md),
[limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/multivariate_convolution/info.toml),
[repository license](https://github.com/yosupo06/library-checker-problems/blob/master/LICENSE).
The bounded ports are clean-room. See [RIGHTS.md](RIGHTS.md).

Workload: [workload.json](workload.json). Primary oracle:
[`multivariate_convolution_oracle.py`](../../multivariate_convolution_oracle.py);
independent checker oracle:
[`multivariate_convolution_verifier_oracle.py`](../../multivariate_convolution_verifier_oracle.py).

## Ports

| Language | Source |
|---|---|
| C | [`c/m/multivariate_convolution.c`](../../../c/m/multivariate_convolution.c) |
| C3 | [`c3/m/multivariate_convolution.c3`](../../../c3/m/multivariate_convolution.c3) |
| C++ | [`cpp/m/multivariate_convolution.cpp`](../../../cpp/m/multivariate_convolution.cpp) |
| Elisa | [`elisa/m/multivariate_convolution.elisa`](../../../elisa/m/multivariate_convolution.elisa) |
| Mojo | [`mojo/m/multivariate_convolution.mojo`](../../../mojo/m/multivariate_convolution.mojo) |
| Nim | [`nim/m/multivariate_convolution.nim`](../../../nim/m/multivariate_convolution.nim) |
| Odin | [`odin/m/multivariate_convolution.odin`](../../../odin/m/multivariate_convolution.odin) |
| Rust | [`rust/m/multivariate_convolution.rs`](../../../rust/m/multivariate_convolution.rs) |
| V | [`v/m/multivariate_convolution.v`](../../../v/m/multivariate_convolution.v) |
| Zig | [`zig/m/multivariate_convolution.zig`](../../../zig/m/multivariate_convolution.zig) |

# Cyclic multivariate convolution

This package implements Library Checker `multivariate_convolution_cyclic`,
multiplying coefficient arrays modulo each `1-x_axis^N_axis`. Coordinate sums
wrap modulo each dimension. The coefficient field is modulo an input prime
`p`; every dimension must divide `p-1` as in the task.

This is separate from [truncated multivariate convolution](../multivariate_convolution/README.md):
the truncated quotient discards out-of-box terms over fixed modulus 998244353,
while this cyclic quotient wraps each exponent and uses the input prime. Those
are distinct quotient algebras and the official cyclic task's divisibility
condition supports a multidimensional Fourier-transform approach.

The bounded profile uses `2<=p<=97`, at most three dimensions, and dimension
product `P<=32`. Axis 0 varies fastest. Each port directly enumerates all
coefficient pairs and wraps every coordinate; this O(P²) implementation visits
at most 1024 pairs and makes no claim to multidimensional-NTT scale.

## ABI

Symbol: `multivariate_convolution_cyclic`, ABI `i64_array_bytes_output`.
Input is `[p,K,dimensions[K],f[P],g[P]]`, where `P` is the dimension product;
`K=0` means `P=1`. Dimensions are at least 2 and divide `p-1`; coefficients
are in `[0,p-1]`. Invalid input returns `-1` before capacity checks. Valid
input with null output or capacity below `8*P` returns `-2` without writes.
Success writes `P` little-endian signed 64-bit coefficients modulo p. Maximum
valid input is 69 words, parseable limit 70, output maximum 256 bytes.

## Source and rights

The operation and field constraints come from the Apache-2.0 licensed Library
Checker repository: [task](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/multivariate_convolution_cyclic/task.md),
[limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/multivariate_convolution_cyclic/info.toml),
[repository license](https://github.com/yosupo06/library-checker-problems/blob/master/LICENSE).
The bounded ports are clean-room. See [RIGHTS.md](RIGHTS.md).

Workload: [workload.json](workload.json). Primary oracle:
[`multivariate_convolution_cyclic_oracle.py`](../../multivariate_convolution_cyclic_oracle.py);
independent checker oracle:
[`multivariate_convolution_cyclic_verifier_oracle.py`](../../multivariate_convolution_cyclic_verifier_oracle.py).

## Ports

| Language | Source |
|---|---|
| C | [`c/m/multivariate_convolution_cyclic.c`](../../../c/m/multivariate_convolution_cyclic.c) |
| C3 | [`c3/m/multivariate_convolution_cyclic.c3`](../../../c3/m/multivariate_convolution_cyclic.c3) |
| C++ | [`cpp/m/multivariate_convolution_cyclic.cpp`](../../../cpp/m/multivariate_convolution_cyclic.cpp) |
| Elisa | [`elisa/m/multivariate_convolution_cyclic.elisa`](../../../elisa/m/multivariate_convolution_cyclic.elisa) |
| Mojo | [`mojo/m/multivariate_convolution_cyclic.mojo`](../../../mojo/m/multivariate_convolution_cyclic.mojo) |
| Nim | [`nim/m/multivariate_convolution_cyclic.nim`](../../../nim/m/multivariate_convolution_cyclic.nim) |
| Odin | [`odin/m/multivariate_convolution_cyclic.odin`](../../../odin/m/multivariate_convolution_cyclic.odin) |
| Rust | [`rust/m/multivariate_convolution_cyclic.rs`](../../../rust/m/multivariate_convolution_cyclic.rs) |
| V | [`v/m/multivariate_convolution_cyclic.v`](../../../v/m/multivariate_convolution_cyclic.v) |
| Zig | [`zig/m/multivariate_convolution_cyclic.zig`](../../../zig/m/multivariate_convolution_cyclic.zig) |

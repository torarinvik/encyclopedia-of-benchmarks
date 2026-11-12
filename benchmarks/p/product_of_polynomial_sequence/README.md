# Product of a Polynomial Sequence

This package multiplies a supplied sequence of nonzero polynomials over
F_998244353 and returns the full coefficient vector in ascending degree order.
It measures polynomial multiplication arranged as a balanced product tree,
not merely one convolution call.

## Bounded contract

The `i64_array_bytes_output` input is `[K, d_0, a_0, ..., a_(d0), ...]`.
There are `0<=K<=6` polynomials, each of degree `0<=d_i<=4`, with every
coefficient in `[0,998244352]` and every leading coefficient nonzero. The
coefficient arrays use ascending degree order. The maximum valid input has 37
signed 64-bit words; one extra parseable word is accepted for validation, so
the maximum parseable input is 38 words.

The output contains the `1+sum(d_i)` coefficients of the product as
little-endian signed 64-bit words. For the empty sequence (`K=0`), the empty
product is 1 and the output is the single coefficient `[1]`. Success returns
the output byte count. Malformed input returns `-1`; a valid call with a null
output or capacity below the actual output size returns `-2` and writes no
bytes. The maximum output is 200 bytes. The fixed coefficient buffers use at
most 1,536 bytes of workspace.

The ports repeatedly multiply adjacent pairs and carry an unmatched final
polynomial to the next level. For `K` input polynomials whose total degree is
`D`, naive convolution costs `O((D+K)^2 log(K+2))` coefficient operations
over the balanced levels. The extra `K` term accounts for constant-only
factors. The fixed bounded buffers hold at most 1,450 bytes of polynomial
coefficients and lengths. Each product term is reduced modulo 998244353 before
the next term is added, so accumulation stays within signed 64-bit range.

The primary oracle follows the same balanced tree. The independent oracle
multiplies the inputs from left to right. This task is distinct from a single
polynomial convolution because it includes sequence-level product-tree
construction and handles any number of factors, including the empty product.

## Source and suite

The official operation allows an empty sequence and bounds the sum of all
degrees at 500000; see the [task statement](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/product_of_polynomial_sequence/task.md)
and [official limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/product_of_polynomial_sequence/info.toml).
The local profile uses small degrees so the same naive pairwise multiplication
is portable across all ten languages. The repository is Apache-2.0; see
[RIGHTS.md](RIGHTS.md). Workload and static package inventory are in
[workload.json](workload.json) and [verify_workload.py](verify_workload.py).
Shared suite registration is complete in the `i64_array_bytes_output` runner
and verifier. No programs, tests, checkers, builds, compilers, or benchmarks
were run during integration.

## Ports

| Language | Source |
|---|---|
| C | [c/p/product_of_polynomial_sequence.c](../../../c/p/product_of_polynomial_sequence.c) |
| C3 | [c3/p/product_of_polynomial_sequence.c3](../../../c3/p/product_of_polynomial_sequence.c3) |
| C++ | [cpp/p/product_of_polynomial_sequence.cpp](../../../cpp/p/product_of_polynomial_sequence.cpp) |
| Elisa | [elisa/p/product_of_polynomial_sequence.elisa](../../../elisa/p/product_of_polynomial_sequence.elisa) |
| Mojo | [mojo/p/product_of_polynomial_sequence.mojo](../../../mojo/p/product_of_polynomial_sequence.mojo) |
| Nim | [nim/p/product_of_polynomial_sequence.nim](../../../nim/p/product_of_polynomial_sequence.nim) |
| Odin | [odin/p/product_of_polynomial_sequence.odin](../../../odin/p/product_of_polynomial_sequence.odin) |
| Rust | [rust/p/product_of_polynomial_sequence.rs](../../../rust/p/product_of_polynomial_sequence.rs) |
| V | [v/p/product_of_polynomial_sequence.v](../../../v/p/product_of_polynomial_sequence.v) |
| Zig | [zig/p/product_of_polynomial_sequence.zig](../../../zig/p/product_of_polynomial_sequence.zig) |

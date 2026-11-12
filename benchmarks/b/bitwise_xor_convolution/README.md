# Bitwise XOR Convolution

This package computes the Library Checker operation
`c[k] = sum(a[i] * b[j] for i xor j == k) mod 998244353`.
The [official task](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/bitwise_xor_convolution/task.md)
allows `0 <= N <= 20`; this local profile bounds `N <= 8` and accepts two
arrays of length `2^N` with coefficients in `[0, 998244353)`.

## Algorithm and distinction

The ports apply the XOR Walsh–Hadamard transform to both inputs, multiply the
transformed coefficients pointwise, transform the product again, and multiply
each result by `(2^N)^-1 mod 998244353`. The work is `O(N*2^N)` with two
fixed 256-element arrays. The independent oracle enumerates all ordered input
pairs directly in `O(4^N)` time; its verifier counterpart scans each output
index independently.

This is a distinct operation from
[`fast_walsh_hadamard_transform`](../f/fast_walsh_hadamard_transform/README.md):
that benchmark returns one forward or inverse transform, while this one
accepts two coefficient arrays, performs the pointwise product between their
transforms, applies the inverse normalization, and returns their XOR-indexed
convolution.

## Bounded ABI contract

The symbol is `bitwise_xor_convolution` with ABI `i64_array_bytes_output`.
Input is `[N, a[0..2^N), b[0..2^N)]`; output is one little-endian signed-64
residue per index. The maximum valid input is 513 words, output is 2,048
bytes, and workspace is 4,096 bytes. Invalid frames or coefficients return
`-1`; valid input with null output or insufficient capacity returns `-2`
without writing.

See [workload.json](workload.json), the [primary direct oracle](../../bitwise_xor_convolution_oracle.py),
the [independent direct verifier oracle](../../bitwise_xor_convolution_verifier_oracle.py),
and [verify_workload.py](verify_workload.py).

## Provenance and rights

The Library Checker task and official limits are available in the
[`yosupo06/library-checker-problems` repository](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/bitwise_xor_convolution/task.md)
and its [limits file](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/bitwise_xor_convolution/info.toml).
The repository uses Apache-2.0. This package reuses the task definition only;
all ports and oracles are clean-room. See [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Port |
|---|---|
| C | [`c/b/bitwise_xor_convolution.c`](../../../c/b/bitwise_xor_convolution.c) |
| C3 | [`c3/b/bitwise_xor_convolution.c3`](../../../c3/b/bitwise_xor_convolution.c3) |
| C++ | [`cpp/b/bitwise_xor_convolution.cpp`](../../../cpp/b/bitwise_xor_convolution.cpp) |
| Elisa | [`elisa/b/bitwise_xor_convolution.elisa`](../../../elisa/b/bitwise_xor_convolution.elisa) |
| Mojo | [`mojo/b/bitwise_xor_convolution.mojo`](../../../mojo/b/bitwise_xor_convolution.mojo) |
| Nim | [`nim/b/bitwise_xor_convolution.nim`](../../../nim/b/bitwise_xor_convolution.nim) |
| Odin | [`odin/b/bitwise_xor_convolution.odin`](../../../odin/b/bitwise_xor_convolution.odin) |
| Rust | [`rust/b/bitwise_xor_convolution.rs`](../../../rust/b/bitwise_xor_convolution.rs) |
| V | [`v/b/bitwise_xor_convolution.v`](../../../v/b/bitwise_xor_convolution.v) |
| Zig | [`zig/b/bitwise_xor_convolution.zig`](../../../zig/b/bitwise_xor_convolution.zig) |

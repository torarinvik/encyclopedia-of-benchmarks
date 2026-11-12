# Modular polynomial convolution

This benchmark follows the [Library Checker Convolution task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/convolution_mod/task.md)
and its [official parameters](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/convolution_mod/info.toml).
Only the task definition and algorithm family are used; the ports and direct
oracle are clean-room implementations.

## Contract

Input is `[N, M, a_0, ..., a_(N-1), b_0, ..., b_(M-1)]`. The official task
allows both lengths through 524288; this local profile bounds each length to
256. Coefficients are canonical residues in `[0, 998244353)`. Output is the
full linear product in increasing degree order,
`c_k = sum(a_i*b_j for i+j=k) mod 998244353`, encoded as little-endian signed
64-bit integers. Invalid input returns `-1`. A null or undersized output
buffer returns `-2` without writing output.

The largest result has 511 coefficients (4,088 bytes). The ports pad to a
power-of-two transform length no greater than 512 and use two fixed arrays,
for 8,192 bytes of working storage.

## Algorithm

The ports use an iterative radix-2 number theoretic transform over the prime
998244353 with primitive root 3. They transform both zero-padded coefficient
arrays, multiply pointwise, apply the inverse transform, and scale by the
inverse transform length. This computes the exact modular linear convolution
in `O(L log L)` time for padded length `L`.

The [independent Python oracle](../../convolution_mod_oracle.py) uses direct
nested-loop coefficient accumulation in `O(N*M)` time and does not use a
transform. The package workload covers singleton and unequal lengths, impulse
placement, modular wraparound, zero coefficients, invalid frames and residues,
and output-buffer errors.

## Distinction from related benchmarks

The existing [`convolution`](../convolution/README.md) package computes an
exact integer product with nested loops; [`convolution_fft`](../convolution_fft/README.md)
uses floating-point arithmetic; and [`number_theoretic_transform`](../../n/number_theoretic_transform/README.md)
returns a forward transform rather than multiplying polynomials. This package
measures the complete modular product using NTTs.

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/convolution_mod.c`](../../../c/c/convolution_mod.c) |
| C3 | [`c3/c/convolution_mod.c3`](../../../c3/c/convolution_mod.c3) |
| C++ | [`cpp/c/convolution_mod.cpp`](../../../cpp/c/convolution_mod.cpp) |
| Elisa | [`elisa/c/convolution_mod.elisa`](../../../elisa/c/convolution_mod.elisa) |
| Mojo | [`mojo/c/convolution_mod.mojo`](../../../mojo/c/convolution_mod.mojo) |
| Nim | [`nim/c/convolution_mod.nim`](../../../nim/c/convolution_mod.nim) |
| Odin | [`odin/c/convolution_mod.odin`](../../../odin/c/convolution_mod.odin) |
| Rust | [`rust/c/convolution_mod.rs`](../../../rust/c/convolution_mod.rs) |
| V | [`v/c/convolution_mod.v`](../../../v/c/convolution_mod.v) |
| Zig | [`zig/c/convolution_mod.zig`](../../../zig/c/convolution_mod.zig) |

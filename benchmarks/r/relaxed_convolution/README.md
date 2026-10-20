# Relaxed convolution

This package models online polynomial multiplication: at step `q`, the pair
`a[q]`, `b[q]` arrives and the algorithm finalizes the coefficient
`c[q] = sum(a[j] * b[q-j]) mod 998244353`. The ports follow NyaanNyaan's
dyadic relaxed-convolution schedule, including the single low-block phase and
the paired cross-block phases. Since the portable workload is capped at 16
coefficients, each scheduled block product uses direct modular products rather
than the upstream implementation's cached NTTs. This keeps the same online
coefficient schedule while bounding the implementation and exposing its
distinct incremental behavior; it is not a general convolution benchmark.

## Contract

The exported `relaxed_convolution` entry point uses `i64_array_bytes_output`.
Input is `[n, a[0..n-1], b[0..n-1]]`; `n` is 1 through 16 and all coefficients
are canonical residues in `0..998244352`. The returned vector contains the
first `n` coefficients of the ordinary product, in order and modulo
`998244353`. Each result is an unsigned 32-bit little-endian word, so output
size is exactly `4*n` bytes (maximum 64). Malformed input returns `-1` before
output checks. Null output or capacity below `4*n` returns `-2` without
writing. Success returns `4*n`.

The independent [`relaxed_convolution_oracle.py`](../../relaxed_convolution_oracle.py)
computes each coefficient directly from its full prefix sum. The package
[`workload.json`](workload.json) includes singleton, sparse, dense, and
boundary vectors.

## Pinned source and license

The schedule and coefficient update semantics are based on NyaanNyaan's
[`ntt/relaxed-convolution.hpp`](https://github.com/NyaanNyaan/library/blob/b3981adc80a800b2584980b01821324ea6c77183/ntt/relaxed-convolution.hpp)
at commit `b3981adc80a800b2584980b01821324ea6c77183`. The repository's
[`LICENSE`](https://github.com/NyaanNyaan/library/blob/b3981adc80a800b2584980b01821324ea6c77183/LICENSE)
is CC0 1.0 Universal; its complete text is bundled in [`LICENSE.txt`](LICENSE.txt).
These bounded ports are fresh implementations of the schedule.

## Ports

| Language | Port |
|---|---|
| C | [`c/r/relaxed_convolution.c`](../../../c/r/relaxed_convolution.c) |
| C3 | [`c3/r/relaxed_convolution.c3`](../../../c3/r/relaxed_convolution.c3) |
| C++ | [`cpp/r/relaxed_convolution.cpp`](../../../cpp/r/relaxed_convolution.cpp) |
| Elisa | [`elisa/r/relaxed_convolution.elisa`](../../../elisa/r/relaxed_convolution.elisa) |
| Nim | [`nim/r/relaxed_convolution.nim`](../../../nim/r/relaxed_convolution.nim) |
| Odin | [`odin/r/relaxed_convolution.odin`](../../../odin/r/relaxed_convolution.odin) |
| Rust | [`rust/r/relaxed_convolution.rs`](../../../rust/r/relaxed_convolution.rs) |
| V | [`v/r/relaxed_convolution.v`](../../../v/r/relaxed_convolution.v) |
| Zig | [`zig/r/relaxed_convolution.zig`](../../../zig/r/relaxed_convolution.zig) |

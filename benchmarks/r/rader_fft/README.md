# Rader FFT

This package implements a bounded five-point complex forward DFT using the Rader permutation and cyclic-convolution method. It follows the indexing structure of NyaanNyaan's `RaderNTT::ntt`, adapted from modular NTT arithmetic to binary64 complex values. The convolution is evaluated with zero-padded length-eight radix-2 FFTs; the DFT itself is not evaluated by a direct summation in the ports.

## Contract

- ABI: `float64_slice_io`. Input is exactly ten finite float64 values representing five complex samples as interleaved `[real0, imag0, ..., real4, imag4]`.
- Each real and imaginary component must be in `[-100,100]`. The transform is the unnormalized forward DFT, `X[k] = sum(x[n] * exp(-2*pi*i*k*n/5), n=0..4)`. Output uses the same interleaved order for `X[0]` through `X[4]`.
- The primitive root is `2` modulo `5`, giving the input permutation `[1,2,4,3]`; the reversed kernel powers are `[1,3,4,2]`. The linear convolution of these four-element sequences is padded to eight, transformed, multiplied pointwise, inverse transformed, and folded modulo four. This reproduces the Rader cyclic convolution.
- Return `10` on success. Invalid input returns `-1`; a null output or output capacity below ten returns `-2`. Errors write nothing. Workspace is two padded complex arrays of length eight plus a ten-element staged result.
- Compare output with absolute and relative tolerances of `1e-10`.

## Source and license

The source is NyaanNyaan/library [`ntt/rader-ntt.hpp`](https://github.com/NyaanNyaan/library/blob/b3981adc80a800b2584980b01821324ea6c77183/ntt/rader-ntt.hpp), symbol `RaderNTT::ntt`, pinned at commit `b3981adc80a800b2584980b01821324ea6c77183`. That implementation uses a primitive-root permutation, an inverse-power kernel, arbitrary convolution, and folds the convolution into the transform output. This package ports those Rader mechanics to a fixed-size complex forward DFT. The upstream repository is licensed CC0 1.0 Universal; the full license text is included in [`LICENSE.txt`](LICENSE.txt).

The separate [oracle](../../rader_fft_oracle.py) computes the five-point DFT directly and does not use the Rader convolution path.

## Workload

[`workload.json`](workload.json) includes zero, impulse, constant, and phase-sensitive inputs, plus malformed-length and component-bound cases.

## Implementations

| Language | Port |
|---|---|
| C | [`c/r/rader_fft.c`](../../../c/r/rader_fft.c) |
| C3 | [`c3/r/rader_fft.c3`](../../../c3/r/rader_fft.c3) |
| C++ | [`cpp/r/rader_fft.cpp`](../../../cpp/r/rader_fft.cpp) |
| Elisa | [`elisa/r/rader_fft.elisa`](../../../elisa/r/rader_fft.elisa) |
| Nim | [`nim/r/rader_fft.nim`](../../../nim/r/rader_fft.nim) |
| Odin | [`odin/r/rader_fft.odin`](../../../odin/r/rader_fft.odin) |
| Rust | [`rust/r/rader_fft.rs`](../../../rust/r/rader_fft.rs) |
| V | [`v/r/rader_fft.v`](../../../v/r/rader_fft.v) |
| Zig | [`zig/r/rader_fft.zig`](../../../zig/r/rader_fft.zig) |

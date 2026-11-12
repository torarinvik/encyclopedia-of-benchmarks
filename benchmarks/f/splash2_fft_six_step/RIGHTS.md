# Rights and provenance

The pinned SPLASH-2 `fft.C` file carries a Stanford University 1994 notice. Its header permits use, copying, and modification for non-commercial purposes but says redistribution of the upstream software, in whole or part, is forbidden without prior written permission. This repository does not copy, adapt, or redistribute the upstream source, its comments, or its implementation details. The ten ports are clean-room implementations of the published six-step algorithm, using explicit input, a sequential contract, ordinary matrix transposes, radix-2 row transforms, and the mathematical twiddle formula.

References:

- [Pinned SPLASH-2 `fft.C`](https://github.com/staceyson/splash2/blob/be64f8e4840fc29ff4c076c3f747e27fdb55ac68/codes/kernels/fft/fft.C)
- [Pinned SPLASH-2 FFT README](https://github.com/staceyson/splash2/blob/be64f8e4840fc29ff4c076c3f747e27fdb55ac68/codes/kernels/fft/README.fft)
- [David H. Bailey, “FFTs in External or Hierarchical Memory”](https://www.davidhbailey.com/dhbpapers/fftq.pdf)
- [Woo, Singh, and Hennessy, ASPLOS-VI paper](https://doi.org/10.1145/195470.195547)

No third-party source license is asserted for the new files in this package.

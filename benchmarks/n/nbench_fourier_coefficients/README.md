# NBench Fourier coefficients

Compute the first `n` Fourier coefficients for the source waveform `(x+1)^x` over `[0,2]`, using 200-step trapezoidal integration. The `A[0]` term is divided by two; for each harmonic `i=1..n-1`, compute cosine `A[i]` and sine `B[i]` terms at `omega=i*pi`.

## Contract

The `i64_array_float64` ABI accepts `[n]`, with integer `n` from 1 through 16. The parser accepts one extra input value to reject trailing data. Invalid or null input returns `-1e300`. The result is a deterministic scalar projection that keeps the computed coefficient vector observable: `sum((i+1)*A[i], i=0..n-1) + sum(i*B[i], i=1..n-1)`. Compare with absolute tolerance `1e-10` and relative tolerance `1e-12`.

The source integration operation order is preserved: initialize with the half-weighted lower endpoint, accumulate interior points using repeated `x += dx`, then add the half-weighted upper endpoint and multiply by `dx`.

## Upstream attribution and terms

This bounded implementation is based on ANSIbench's NBench BYTEmark source `nbench/src/nbench1.c` (`DoFPUTransIteration`, `TrapezoidIntegrate`, and `thefunction`) at [nfinit/ansibench commit `ef90abd09d7b7bb1f2809f896d6f67fb9724bebe`](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/nbench/src/nbench1.c). NBench credits Rick Grehan/BYTE Magazine for BYTEmark and Uwe F. Mayer for the Linux/Unix port. No source blocks are copied.

The upstream BYTEmark notice makes its source, executable, and documentation available “as is” and disclaims warranties and liability. Preserve that notice and attribution when redistributing derived work; the upstream package is commonly tagged `freedist`, not a standard permissive license. See the copied [LICENSE](LICENSE) notice.

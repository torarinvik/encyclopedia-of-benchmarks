# TSVC s313 dot-product reduction

This package implements the source-order reduction `dot += A[i] * B[i]` from TSVC `s313`. It covers the `Reductions-dbl` and `Reductions-flt` codelets at pinned commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38` (`TSVC/tsc.inc`, `s313`; launchers `TSVC/Reductions-dbl/info.sh` and `TSVC/Reductions-flt/info.sh`). The upstream source initializes its arrays through TSVC's deterministic initializer and repeats the loop for timing. This bounded profile takes both vectors explicitly and performs one pass.

Input is `[n, A[0..n), B[0..n)]`, with `1 <= n <= 64`; both vectors contain integer-valued finite binary64 values in `[-1000,1000]`. Output is one binary64 sum, accumulated left to right in source order. This domain makes products and sums exactly representable and gives matching results for the float and double codelets. Invalid input returns `-1`; null or short output capacity returns `-2` after input validation. The profile uses the `float64_slice_io` ABI.

The ports are clean-room implementations. TSVC attributes its non-four-digit loops to David Callahan, Jack Dongarra, and David Levine. No explicit redistribution grant was found in the pinned source or repository materials reviewed; this package does not copy upstream code or comments and makes no upstream license or endorsement claim.

See [workload.json](workload.json) and the [independent oracle](../../tsvc_s313_dot_product_reduction_oracle.py). Nine ports are provided in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig.

# Newton reciprocal square root of a formal power series

This in-progress benchmark computes `g` over F_998244353 such that `g(0)=1` and `f*g² = 1 mod x^N`. The unit-constant condition makes that solution unique and avoids a modular square-root selection policy.

The `i64_array_bytes_output` input is `[N,f_0,...,f_(N-1)]`, with `1<=N<=64`, each coefficient in `0..998244352`, and `f_0=1`. Success writes N little-endian i64 residues and returns `8*N`; malformed or null input returns -1, and valid input with a null or insufficient output buffer returns -2 without writes. Maximum valid and parseable input lengths are 65 and 66 words, and output is at most 512 bytes.

Starting at `g=1 mod x`, each iteration doubles the correct precision using `g <- g*(3-f*g²)/2` in the truncated field-series ring. Direct schoolbook multiplication gives O(N²) field operations across the doubling stages and O(N) storage. This differs from the local [`sqrt_of_formal_power_series`](../../s/sqrt_of_formal_power_series/README.md), which solves for a square root by coefficient recurrence, and [`newton_reciprocal_fps`](../newton_reciprocal_fps/README.md), which computes a reciprocal without a square root.

The method is based on the mathematical description in [FLINT](https://flintlib.org/doc/acb_poly/index.html); no source code or prose was copied. The primary oracle uses Newton iteration and the independently validating reference uses a derivative-based coefficient recurrence. Drafts in all ten languages, workload, package checker, and byte-output suite registration are present. Nothing has been run; further review remains necessary.

The generated verifier source includes a maximum-length alternating-series
identity and a highest-degree correction case, in addition to random series.
These checks have not been run.

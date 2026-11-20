# k-mismatch longest-extension table

This package computes the generalized longest-extension values `LP_k(p)` for
each suffix start `p` and each mismatch budget `k`. It isolates the extension
table used by approximate-repeat algorithms; it does not enumerate tandem
repetitions or runs.

## Contract

The exported function is `k_mismatch_longest_extension_table` with the
`i64_array_bytes_output` ABI. Input is exactly `[n,K,w0,...,w(n-1)]`, where
`1 <= n <= 64`, `0 <= K <= 4`, and each text symbol is in `0..25`. Positions
`p` are one-based from 1 through `n`. For each `(p,k)`, the result is the
largest `j` from 0 through `n-p+1` such that the prefixes of length `j` at
text positions 0 and `p-1` have Hamming distance at most `k`. Thus a
zero-length match is valid, `p=1` returns `n` for every budget, and every row
is clipped at its suffix boundary.

Output is the row-major table
`LP_0(1),...,LP_K(1), LP_0(2),...,LP_K(n)` as raw unsigned bytes, with no
header. The largest result is 64, so each value fits in one byte. Input
validation precedes output pointer/capacity checks. Invalid input returns
`-1`; null output or insufficient capacity returns `-2`; errors write no
bytes. The largest valid input is 66 i64 words, the parser bound is 67 words,
and the maximum output is 320 bytes. Workspace is capped at 8,192 bytes,
excluding caller buffers. A widest 64-bit-index implementation keeps at most
7,496 bytes of fixed table/result entries live, including the rank buffer used
during a doubling round; the remaining space covers local scalars and array
descriptors. Elisa and the compact Rust port use less storage.

The primary builds a suffix array by rank-doubling, computes adjacent LCPs
with Kasai's method, and indexes LCP range minima in a sparse table. Each
`LP_k(p)` row starts with an exact LCE. To extend from budget `k-1` to `k`, it
skips the next mismatching symbol and performs another exact LCE; if the
suffix boundary was already reached, the row value stays there. The
independent reference instead scans every candidate prefix directly and
counts mismatches. The primary's bounded suffix-array construction is
`O(n^2 log n)` with insertion sorting of rank pairs; LCP/RMQ preprocessing is
`O(n log n)`, and table construction uses `O(n(K+1))` constant-time LCE
jumps. The direct reference uses `O(n^2(K+1))` symbol comparisons in this
bounded profile.

## Source and distinction

The chapter's `LP_k(p)` definition and use in approximate tandem-repeat
search are in Chapter 24, “Approximate Tandem Repeats,” of the *Encyclopedia
of Algorithms* ([DOI 10.1007/978-1-4939-2864-4_24](https://doi.org/10.1007/978-1-4939-2864-4_24)). The operational LCE-jump idea is described by R. Kolpakov and G. Kucherov, “Finding Approximate Repetitions under Hamming Distance” ([DOI 10.1016/S0304-3975(02)00448-6](https://doi.org/10.1016/S0304-3975(02)00448-6)). The chapter describes suffix-tree/LCA support; this benchmark uses a bounded suffix-array/LCP/RMQ realization of exact LCE queries.

Local packages such as [`approximate_tandem_k_repetitions`](../../a/approximate_tandem_k_repetitions/README.md), [`approximate_tandem_k_runs`](../../a/approximate_tandem_k_runs/README.md), and [`approximate_tandem_k_edit_repeats`](../../a/approximate_tandem_k_edit_repeats/README.md) measure repeat enumeration or run extraction. They do not return the per-suffix `LP_k(p)` table, so this package measures a distinct reusable kernel. All ten language implementations and both references are clean-room work based on the cited algorithm ideas; no source code or published examples are copied.

See [workload.json](workload.json), [RIGHTS.md](RIGHTS.md), and
[INVENTORY.md](INVENTORY.md). Shared suite/catalog registration remains with
the repository integrator.

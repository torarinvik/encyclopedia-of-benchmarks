# Package inventory

Algorithm: `lanczos_symmetric_tridiagonalization`  
Source: NIST DLMF §3.2(vi), Eqs. 3.2.21–3.2.22.  
ABI: `float64_slice_io`.  
Input: `[n,k,A_row_major]`, symmetric integer matrix entries in `[-4,4]`,
`1<=k<=n<=4`; initial vector is fixed to `e_1`.  
Input frame lengths: 18 valid / 19 parseable maximum.  
Output: `[k,alpha_1..alpha_k,beta_2..beta_k]`, at most 8 float64 elements.  
Output workspace: 8 elements / 64 bytes. Primary scratch cap: 256 bytes.  
Status: `-1` malformed, `-2` null/short output, `-3` recurrence breakdown.  
Breakdown threshold: any required beta `<=2^-40` or nonfinite. In this integer
matrix domain, exact nonzero betas are bounded below by `1/256`; the diagonal
fixture covers exact breakdown, and no accepted input can sit at the threshold.  
Comparison: absolute `1e-9`, relative `1e-12`.

Native ports:

- `c/l/lanczos_symmetric_tridiagonalization.c`
- `c3/l/lanczos_symmetric_tridiagonalization.c3`
- `cpp/l/lanczos_symmetric_tridiagonalization.cpp`
- `elisa/l/lanczos_symmetric_tridiagonalization.elisa`
- `mojo/l/lanczos_symmetric_tridiagonalization.mojo`
- `nim/l/lanczos_symmetric_tridiagonalization.nim`
- `odin/l/lanczos_symmetric_tridiagonalization.odin`
- `rust/l/lanczos_symmetric_tridiagonalization.rs`
- `v/l/lanczos_symmetric_tridiagonalization.v`
- `zig/l/lanczos_symmetric_tridiagonalization.zig`

The primary reference uses the three-term recurrence. The independent
reference forms a Krylov power basis with two-pass modified Gram–Schmidt and
extracts the projected matrix coefficients. The package inventory helper
checks native paths, metadata, input/output framing, and the Elisa bounded-view
style without compiling or running ports.

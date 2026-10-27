# Felsenstein substitution likelihood

This package ports the chapter's conditional-likelihood recurrence for one
observed binary site on a supplied rooted full binary tree. It is a bounded
component of the chapter's statistical multiple-alignment discussion; it does
not implement sequence alignment, indels, or a multiple-HMM composition.

Input is a signed-i64 array `[leaf_count, postorder_tokens...]`. There are 1–8
leaves. A leaf token is `[0, observed_state]`, where the state is 0 or 1. An
internal-node token is `[1, left_edge_mode, right_edge_mode]`, where each edge
mode is 0 or 1. Tokens are in postorder: each internal node consumes the two
most recent subtrees, with the right subtree popped first. The token stream
must describe exactly one full binary tree with the stated leaf count.

Mode 0 is the identity transition matrix. Mode 1 is the binary symmetric
matrix `[[3/4,1/4],[1/4,3/4]]`. At an internal node, for each parent state,
the two child conditional likelihoods are transitioned independently and
multiplied. The root prior is uniform, so the site likelihood is
`(L_root(0)+L_root(1))/2`. The implementation keeps exact integer numerators
with denominator four per edge and returns the likelihood multiplied by
`2^30`; this is integral for the supported tree bounds.

Input is bounded to 38 words and output is one little-endian signed-i64 word
(8 bytes). Fixed workspace is 4096 bytes. Invalid input returns `-1`; null
output or capacity below 8 returns `-2` without writes.

Source: “Statistical Multiple Alignment,” Encyclopedia of Algorithms, DOI
10.1007/978-1-4939-2864-4_400, `OEBPS/AChap400.html`, Felsenstein's
conditional-likelihood recurrence (Eq. 6) and root likelihood (Eq. 7). The
two-state alphabet, two rational transition modes, one-site leaves, postorder
framing, and fixed scale are bounded profile choices. The chapter does not
specify source code or grant a source-code license; these ports are clean-room.

Primary and independent verifier oracles:
`benchmarks/felsenstein_substitution_likelihood_oracle.py` and
`benchmarks/felsenstein_substitution_likelihood_verifier_oracle.py`.

| Language | Port |
|---|---|
| C | `c/s/felsenstein_substitution_likelihood.c` |
| C3 | `c3/s/felsenstein_substitution_likelihood.c3` |
| C++ | `cpp/s/felsenstein_substitution_likelihood.cpp` |
| Elisa | `elisa/s/felsenstein_substitution_likelihood.elisa` |
| Nim | `nim/s/felsenstein_substitution_likelihood.nim` |
| Odin | `odin/s/felsenstein_substitution_likelihood.odin` |
| Rust | `rust/s/felsenstein_substitution_likelihood.rs` |
| V | `v/s/felsenstein_substitution_likelihood.v` |
| Zig | `zig/s/felsenstein_substitution_likelihood.zig` |

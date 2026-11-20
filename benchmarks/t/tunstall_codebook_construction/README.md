# Tunstall codebook construction

This package benchmarks the bounded greedy construction of a Tunstall
variable-to-fixed source codebook for a memoryless source. Begin with the root
as an internal node and one leaf for each alphabet symbol. Repeatedly split the
highest-probability leaf into one child per symbol until the dictionary has the
largest full K-ary leaf count `M <= 2^B` satisfying `M = 1 (mod K-1)`. Ties
select the lexicographically smallest alphabet-index phrase. The resulting
dictionary is prefix-free and each phrase maps to a fixed `B`-bit codeword
space; unused codewords are permitted when the full-tree leaf count is below
`2^B`.

Input is `[K, B, weight_0, ..., weight_(K-1)]`. `K` is 2..4, `B` is 2..4,
weights are positive integers, and their sum `W` is at most 8. The frame is
exact, with maximum valid length 6 words and a 7-word parseable frame for
trailing-data rejection. Weights define exact symbol probabilities
`weight_i / W`; no floating-point arithmetic is used. Null or malformed input
returns `-1`.

The expected number of source symbols per dictionary phrase is
`E[L] = sum(P(node))` over every internal node, including the root. Tree depth
is at most 15. The ports compare leaf probabilities after scaling them to the
common denominator `W^15`; an internal node at depth `d` contributes
`product(path_weights) * W^(16-d)` to `S = W^16 * E[L]`. There are at most 15
internal nodes and `W <= 8`, so `S <= 15 * 8^16`. The scalar result is
`M * (15 * 8^16 + 1) + S`, whose maximum is 71,776,119,061,217,296 and fits in
signed 64-bit arithmetic.

The primary oracle uses a bounded tree array and a linear scan of current
leaves, comparing exact common-denominator probabilities. The independent
oracle keeps current leaves in a heap ordered by exact rational probability
and phrase. Both use the published Tunstall rule but different selection
representations.

This algorithm is distinct from local Huffman and Shannon–Fano packages, which
assign variable-length codewords to fixed source symbols. It differs from BPE,
which merges frequent byte-token pairs in observed text; from Sequitur, which
maintains grammar-wide digram and rule-utility constraints; and from LZ77,
LZ78, LZW, and LZ-End, which parse text using prior occurrences or dictionary
phrases rather than a supplied memoryless probability model.

The method is described in the MIT 6.441 [Tunstall-code notes](https://web.mit.edu/6.441/spring06/handout/sup/Tunstall_codes_-_Notes_1.pdf),
which cite Brian P. Tunstall's Georgia Tech thesis, “Synthesis of Noiseless
Compression Codes.” Only algorithmic ideas are used; the contract, tie policy,
implementations, references, and fixtures are independently authored.

Language ports: [C](../../../c/t/tunstall_codebook_construction.c),
[C3](../../../c3/t/tunstall_codebook_construction.c3),
[C++](../../../cpp/t/tunstall_codebook_construction.cpp),
[Elisa](../../../elisa/t/tunstall_codebook_construction.elisa),
[Mojo](../../../mojo/t/tunstall_codebook_construction.mojo),
[Nim](../../../nim/t/tunstall_codebook_construction.nim),
[Odin](../../../odin/t/tunstall_codebook_construction.odin),
[Rust](../../../rust/t/tunstall_codebook_construction.rs),
[V](../../../v/t/tunstall_codebook_construction.v), and
[Zig](../../../zig/t/tunstall_codebook_construction.zig).

No programs, tests, scripts, checkers, builds, compilers, profilers, or
benchmarks were run while preparing this package.

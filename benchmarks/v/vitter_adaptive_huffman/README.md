# Vitter adaptive Huffman coding (Algorithm A)

This package measures Vitter's one-pass dynamic Huffman update. The tree uses
bottom-up, left-to-right implicit numbering and keeps equal-weight leaves
before equal-weight internal nodes. Its update groups nodes into weight/type
blocks and uses SlideAndIncrement to move a node across the next eligible
block before increasing its weight. This is distinct from FGK's repeated
highest-numbered equal-weight interchange.

## Contract

- ABI: `i64_array_bytes_output`; input `[n, symbols...]`, `0<=n<=64`, symbols
  in `0..15`. The maximum valid frame is 65 words and parser bound is 66.
- The code stream is emitted online. Each symbol uses its current tree path;
  first occurrences append the four-bit symbol id after the NYT path.
- Output is an eight-byte little-endian bit count followed by MSB-first packed
  code bits. Unused low bits in the last byte are zero. Maximum output is 160
  bytes; workspace metadata is 4096 bytes. Invalid input returns `-1`; null
  or undersized output returns `-2` without writes.
- The alphabet remains fixed at 16 symbols. On the final unseen symbol, the
  NYT leaf is reused as that symbol's leaf.

The primary reference uses an explicit implicit-order scan and block slide.
The independent reference stores object nodes, derives the level order from
the tree shape, and scans the eligible blocks directly. The workload includes
a short sequence where Algorithm A and FGK emit different streams.

## Sources and rights

The [NIST DADS Vitter entry](https://xlinux.nist.gov/dads/HTML/vittersAlgorithm.html)
lists Jeffrey Scott Vitter, “Design and Analysis of Dynamic Huffman Codes,”
*Journal of the ACM* 34(4), 825–845 (1987), and “Algorithm 673: Dynamic Huffman
Coding,” *ACM Transactions on Mathematical Software* 15(2), 158–167 (1989).
The [1987 paper](https://www.cs.utexas.edu/~plaxton/c/337/05f/projects/1/Vitter87.pdf)
describes Algorithm A's implicit numbering, leaf-before-internal invariant,
block leaders, and SlideAndIncrement operation. FGK's distinct update rule is
described in [Knuth's 1985 paper](https://doi.org/10.1016/0196-6774(85)90036-7).
Only algorithm descriptions were consulted; no source code, tests, figures, or
examples were copied. See [RIGHTS.md](RIGHTS.md).

Language ports are in `a/adaptive_huffman_pair` under each supported language
root. Each shared language source exports both the Vitter symbol and the
separate `fgk_adaptive_huffman` symbol.

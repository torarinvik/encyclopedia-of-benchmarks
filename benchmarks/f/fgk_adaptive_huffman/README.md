# FGK adaptive Huffman coding

This package measures the one-pass FGK update rule. It maintains a Huffman
tree with the sibling property, swapping the current node with the highest
numbered eligible node of equal weight before incrementing along the path.
New symbols are sent through the NYT (not yet transmitted) path followed by a
four-bit symbol id in a fixed 16-symbol alphabet.

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

The primary reference keeps a numeric node-order list and swaps nodes in place.
The independent reference uses object nodes, recursive path extraction, and
full scans to find equal-weight leaders. Workloads include a short sequence on
which FGK and Vitter produce different code streams.

## Sources and rights

The [NIST DADS FGK entry](https://xlinux.nist.gov/dads/HTML/algorithmFGK.html)
points to Donald E. Knuth, “Dynamic Huffman Coding,” *Journal of Algorithms*
6(2), 163–180 (1985), [DOI 10.1016/0196-6774(85)90036-7](https://doi.org/10.1016/0196-6774(85)90036-7).
Jeffrey Scott Vitter’s [1987 analysis](https://www.cs.utexas.edu/~plaxton/c/337/05f/projects/1/Vitter87.pdf)
also describes FGK and contrasts its update steps with Algorithm A. Only
algorithm descriptions were consulted; code and examples were not copied.
See [RIGHTS.md](RIGHTS.md).

Language ports are in `a/adaptive_huffman_pair` under each supported language
root. Each shared language source exports both this FGK symbol and the separate
`vitter_adaptive_huffman` symbol.

# Rights and provenance

The algorithm was derived from the method description in NIST DADS,
[“order-preserving Huffman coding”](https://xlinux.nist.gov/dads/HTML/orderPreservingHuffmanCoding.html).
The page attributes the historical context to Graefe, “Implementing Sorting
in Database Systems,” [DOI 10.1145/1132960.1132964](https://doi.org/10.1145/1132960.1132964).

This package is an independent implementation of the short algorithmic idea.
It does not reuse source code, comments, prose, examples, or tests. The
leftmost choice among tied adjacent pairs is a profile convention introduced
here for deterministic cross-language behavior. The package does not claim
that the greedy method is an optimal alphabetic code.

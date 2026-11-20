# Rights and provenance

This package uses the method description in the NIST Dictionary of Algorithms
and Data Structures entry for [hash heap](https://xlinux.nist.gov/dads/HTML/hashheap.html)
and its linked definition of an [order-preserving linear hash](https://xlinux.nist.gov/dads/HTML/linearhash.html).
NIST attributes the hash-heap proposal to Chris L. Kuszmaul's 13 January 1999
`comp.theory` post; the original post was not located during this audit. The
NIST definition is the available operational source.

The source specifies monotone bucket mapping and a heap per bucket, but does
not specify full-bucket behavior or a particular mapping formula. This
benchmark resolves those open choices as profile bounds: a fixed total arena
large enough for every permitted operation, `floor(key*B/U)`, min-heaps, and
stable `(key,insertion-operation-index)` ordering. No source code, examples,
figures, or prose are reused. All ten ports, fixtures, and references were
written independently from the stated contract.

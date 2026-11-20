# Rights and provenance

This package is an independent implementation of the standard quotient-filter
algorithm. The algorithm is described in Bender et al., “Don't Thrash: How to
Cache Your Hash on Flash,” §3 and Figure 3, and its SQF operation invariants
are cross-checked against Geil, Farach-Colton, and Owens, “Quotient Filters:
Approximate Membership Queries on the GPU,” §III-A and Algorithms 1 and 3.
The papers are cited for algorithmic provenance only. No source code,
comments, implementation structure, prose, examples, or test fixtures were
copied.

The bounded profile makes its own deterministic choices where the general
filter leaves implementation details open: 8 slots, 3 quotient bits, 5
remainder bits, a six-copy load cap, stable placement after equal remainders,
and status-only output. Fingerprints are supplied by the caller, so this
profile does not claim a probabilistic false-positive rate for any hash
function. It implements the standard SQF representation, not RSQF, CQF, or a
GPU bulk-build variant.

Sources:

- Bender, Farach-Colton, Johnson, Kraner, and Kuszmaul, [“Don't Thrash: How to Cache
  Your Hash on Flash”](https://doi.org/10.14778/2350229.2350275), §3 and
  Figure 3.
- Geil, Farach-Colton, and Owens, [“Quotient Filters: Approximate Membership
  Queries on the GPU”](https://doi.org/10.1109/IPDPS.2018.00055), §III-A,
  Algorithms 1 and 3.

These package files are newly authored. No third-party implementation or test
material is included; the cited papers are attributed as algorithm sources
and are not relicensed here.

# Rights and provenance

This package is a clean-room implementation of a bounded deterministic ECM
stage-1 factor-detection profile. It does not copy source code, examples, test
cases, or prose from upstream projects.

The Library Checker repository is identified as Apache-2.0; the in-progress
“Factorize (Large)” proposal is used only to discover the algorithm family and
the large-factorization motivation. The mathematical method is based on H. W.
Lenstra, Jr., “Factoring integers with elliptic curves,” *Annals of
Mathematics* 126 (1987), and the x-only Montgomery ladder arithmetic is based
on Peter L. Montgomery, “Speeding the Pollard and elliptic curve methods of
factorization,” *Mathematics of Computation* 48 (1987).

The local workload, bounded contract, language ports, and oracle code were
written independently. This package makes no claim to implement the full
in-progress Library Checker factorization task or its `N <= 10^38` profile.

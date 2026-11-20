# Rights and provenance

The algorithm name and catalog description come from the [NIST DADS Adaptive
Heap Sort entry](https://xlinux.nist.gov/dads/HTML/adaptiveHeapSort.html),
accessed 16 November 2026. DADS describes an RBST selecting heap candidates
and cites Christos Levcopoulos and Ola Petersson, [*Adaptive
Heapsort*](https://doi.org/10.1006/jagm.1993.1021), *Journal of Algorithms*
14(3), 395–413 (1993).

The cited method is described in detail as a deterministic min Cartesian tree
with a binary heap containing only the roots of unreported subtrees. An
accessible scholarly restatement is Haeupler et al., [*Fast and Simple Sorting
Using Partial Information*](https://arxiv.org/abs/2404.04552), which identifies
this as Levcopoulos–Petersson adaptive heapsort. That detailed description
does not use randomization. The DADS RBST wording and the detailed LP93
Cartesian-tree description are therefore recorded as a source-description
mismatch; this package follows the detailed LP93 method because it is the
algorithm explicitly attributed by DADS and its frontier-heap role matches
DADS's candidate-selection summary.

The ports were written from the algorithm description. No source code or prose
from DADS, the 1993 paper, or the 2024 paper was copied.

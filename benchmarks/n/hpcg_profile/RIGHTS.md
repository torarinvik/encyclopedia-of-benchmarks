# Rights and clean-room provenance

The bounded algorithmic profile is based on the written HPCG descriptions:
the official HPCG 3.1 repository README identifies fixed-count double-precision
multigrid-preconditioned CG with a symmetric Gauss–Seidel smoother, and the
official overview lists SpMV, vector updates, dot products, local symmetric
Gauss–Seidel, sparse triangular solves, and nested coarse-grid levels.
[Repository README](https://github.com/hpcg-benchmark/hpcg/blob/master/README.md)
and [official overview](https://www.hpcg-benchmark.org/index.html).

The language ports and Python oracles were independently written from those
published algorithm descriptions. They do not copy upstream implementation
code, comments, report prose, or benchmark reference output. The supplied CSR
input, one aggregate-pair coarse level, small iteration bound, fixtures, and
output contract are repository-specific. The package does not claim to be an
official HPCG implementation, reproduce HPCG's distributed execution, or
carry HPCG endorsement.

# Rights and provenance

This package is a clean-room implementation of an incremental 3D convex-hull
algorithm. It uses the KACTL geometry content index as a discovery index and
the algorithm references below for the mathematical method. It does not copy
KACTL, paper code, source comments, examples, or test data.

- KACTL geometry chapter index, listing `3dHull.h`:
  https://raw.githubusercontent.com/kth-competitive-programming/kactl/main/content/geometry/chapter.tex
- C. Bradford Barber, David P. Dobkin, and Hannu Huhdanpaa, “The Quickhull
  Algorithm for Convex Hulls,” ACM Transactions on Mathematical Software,
  22(4), 469–483 (1996), DOI: https://doi.org/10.1145/235815.235821

The bounded input contract, fixtures, exact determinant oracles, and all
language ports in this package were authored for this repository. No
third-party code or data is bundled.

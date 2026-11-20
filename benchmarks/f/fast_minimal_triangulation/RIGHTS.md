# Source and reuse

The benchmark is a clean-room implementation of the recursive fast minimal
triangulation (FMT) algorithmic method discussed in Encyclopedia of Algorithms
Chapter 142 and described operationally by Heggernes, Telle, and Villanger,
[“Computing Minimal Triangulations in Time O(n^α log n) = o(n^2.376)”](https://doi.org/10.1137/S0895480104445010).
The paper and encyclopedia chapter are used as mathematical references only.
No source code, prose passages, paper examples, or test fixtures are copied.
All package code, bounded contract, and fixtures are independently authored.

The profile intentionally measures the recursive neighborhood-saturation
kernel with a deterministic singleton pivot. It does not implement or claim
the paper's fast balanced selection and matrix-multiplication acceleration.

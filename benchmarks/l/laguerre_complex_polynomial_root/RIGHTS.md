# Rights and provenance

The benchmark is a clean-room implementation of Laguerre's polynomial root
iteration. Its discovery source is the `indy256/codelibrary` repository and its
`cpp/numeric/polynom-roots.cpp` example, which are distributed under the
repository's [UNLICENSE](https://github.com/indy256/codelibrary/blob/main/UNLICENSE).
This package does not copy source code, comments, fixtures, or output data from
that repository.

Algorithm equations are written from the mathematical description in
[Numerical Recipes, Chapter 9.5](https://www.cec.uchile.cl/cinetica/pcordero/MC_libros/NumericalRecipesinC.pdf),
and standard complex Laguerre root-finding formulas. The ports use the
standard relation `H=(P'/P)^2-P''/P`; the upstream
discovery example's differing expression is not reproduced. The workload,
oracles, documentation, and ten language implementations were authored for
this benchmark suite.

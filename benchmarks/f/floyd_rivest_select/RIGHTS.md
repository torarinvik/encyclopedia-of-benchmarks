# Source and rights

- Algorithm source: Robert W. Floyd and Ronald L. Rivest, “Algorithm 489:
  The Algorithm SELECT—for Finding the i-th Smallest of N Elements,”
  *Communications of the ACM* 18(3), 173 (1975),
  [DOI 10.1145/360680.360694](https://doi.org/10.1145/360680.360694).
- Analysis: Floyd and Rivest, “Expected Time Bounds for Selection,”
  *Communications of the ACM* 18(3), 165–172 (1975),
  [author-hosted paper](https://people.csail.mit.edu/rivest/pubs/FR75a.pdf).
- The benchmark reimplements the rank-centered sample-window idea from
  Algorithm 489. The bounded profile pins its small-array cutoff, rounding,
  duplicate-safe partition, interface, and tie behavior. The code and fixtures
  are original clean-room work; no paper source code is redistributed.

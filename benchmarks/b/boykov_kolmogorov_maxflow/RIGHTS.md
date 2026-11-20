# Source and rights

- Algorithm source: Yuri Boykov and Vladimir Kolmogorov, “An Experimental
  Comparison of Min-Cut/Max-Flow Algorithms for Energy Minimization,”
  *IEEE Transactions on Pattern Analysis and Machine Intelligence* 26(9),
  1124–1137 (2004), [DOI 10.1109/TPAMI.2004.60](https://doi.org/10.1109/TPAMI.2004.60).
- The grow, augment, and adopt phases are also summarized in the
  [Boost.Graph documentation](https://www.boost.org/doc/libs/develop/libs/graph/doc/html/graph/algorithms/network_flow/boykov_kolmogorov_max_flow.html).
- The benchmark reimplements the two-tree max-flow algorithm with deterministic
  bounded tie rules. Its interface, residual-matrix representation, fixtures,
  independent cut oracle, and ports are original clean-room work; no paper or
  library source code is redistributed.

# Rights and provenance

The package contains clean-room implementations of the standard 1-dimensional
Weisfeiler–Lehman color-refinement algorithm. NetworkX's GitHub repository and
its official graph-hash documentation were used to discover and identify the
method. The exact digest implementation, source code, examples, and prose are
not copied.

The algorithm description is supported by NetworkX's
[`weisfeiler_lehman_graph_hash` reference](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.graph_hashing.weisfeiler_lehman_graph_hash.html)
and Shervashidze et al., [“Weisfeiler-Lehman Graph Kernels”](https://jmlr.org/papers/v12/shervashidze11a.html).
This benchmark returns canonical integer colors and does not implement
NetworkX's cryptographic digest output.

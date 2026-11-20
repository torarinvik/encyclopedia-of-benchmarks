# Rights and provenance

This is a clean-room implementation of the general dense-graph Kosaraju
method. Discovery and method context are cited in the package README:
Library Checker proposal #1373, the cplib-cpp packed-row SCC reference, and
maspypy's bitset SCC reference. The independent oracle is based on Tarjan's
strongly connected component method (R. E. Tarjan, “Depth-first search and
linear graph algorithms,” *SIAM Journal on Computing* 1(2), 1972,
[DOI 10.1137/0201010](https://doi.org/10.1137/0201010)).

No implementation code, problem text, examples, or fixtures were copied from
those references. The contract, ten ports, two references, fixtures, and prose
were written for this repository. The discovery proposal has no popularity
score field; the workload records that as `null` rather than treating the
issue-list comment count as a score. This package does not redistribute
third-party source material.

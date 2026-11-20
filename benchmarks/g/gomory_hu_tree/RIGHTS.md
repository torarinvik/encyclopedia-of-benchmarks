# Rights and provenance

The algorithmic basis is Gomory and Hu, “Multi-Terminal Network Flows,”
*Journal of the Society for Industrial and Applied Mathematics* 9(4),
551–570 (1961), [DOI 10.1137/0109047](https://doi.org/10.1137/0109047). The
parent-update construction used by this profile is Gusfield's non-contraction
variant, described in “Very Simple Methods for All Pairs Network Flow
Analysis,” *SIAM Journal on Computing* 19(1), 143–155 (1990),
[DOI 10.1137/0219009](https://doi.org/10.1137/0219009).

The [pinned TheAlgorithms/Java `GomoryHuTree.java` implementation](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/GomoryHuTree.java)
was consulted as an implementation reference for the parent updates and
Edmonds–Karp integration. That repository is licensed under the
[MIT License](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/LICENSE),
which requires preserving its copyright and permission notice when copies or
substantial portions of its software are distributed.

The benchmark ports, oracles, workload, and prose were independently authored
from the algorithm descriptions. No source code, examples, figures, or
explanatory prose from the papers or pinned Java file were copied into this
package. The pinned implementation is cited for provenance and behavioral
comparison only. If a future change incorporates or translates substantial
code from it, include the MIT copyright and permission notice with that
derived material. This package does not reproduce the papers' text or figures.

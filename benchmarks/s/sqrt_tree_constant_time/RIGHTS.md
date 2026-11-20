# Rights and provenance

The power-of-two Sqrt Tree query method is based on the algorithm description
in CP-Algorithms' [Sqrt Tree article](https://cp-algorithms.com/data_structures/sqrt-tree.html#optimizing-the-query-complexity),
published under CC BY-SA 4.0. The article is used as an idea source; its code
and prose were not copied. The ten language ports, Python references, and
fixtures are clean-room implementations and hand-authored data.

This package is distinct from the local recursive Sqrt Tree contract: it uses
equal power-of-two blocks, a compact whole-block summary per layer, and a
precomputed highest-differing-bit-to-layer map to achieve O(1) queries. It is
also distinct from the local sparse table's O(n log n) interval table.

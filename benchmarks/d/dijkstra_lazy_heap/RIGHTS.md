# Rights and provenance

The algorithm source is CP-Algorithms, “Dijkstra on sparse graphs”:
<https://cp-algorithms.com/graph/dijkstra_sparse.html>. The page identifies
its content as CC BY-SA 4.0. This package uses only the algorithm idea of
keeping immutable distance/vertex records, pushing a new record after a
strict relaxation, and skipping records whose key has gone stale. No source
code, examples, or prose were copied. All package prose, contracts, fixtures,
oracle implementations, and language ports were independently authored.

The primary Python oracle uses the lazy min-heap frontier. The independent
oracle uses Bellman–Ford with arbitrary-precision distances and separately
checks signed-i64 overflow, so it does not duplicate the primary's queue
discipline.

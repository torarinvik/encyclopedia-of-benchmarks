# Rights and provenance

The primary method is based on the ordinary simple-cycle subset-DP description
in the [OI Wiki ring-counting article](https://oi-wiki.org/graph/rings-count/).
The page is available under CC BY-SA 4.0 with the OI Wiki SATA requirement;
the article is credited for algorithm context. No source code, prose,
examples, fixtures, or tests were copied. All ports, the workload, and both
references are independently written for this bounded benchmark.

The independent reference fixes a canonical cycle orientation and uses DFS;
it does not reuse the primary subset-state recurrence.

# Rights and provenance

The algorithm choice and counting description are based on the four-cycle
section of the [OI Wiki ring-counting article](https://oi-wiki.org/graph/rings-count/).
The page is available under CC BY-SA 4.0 with the OI Wiki SATA requirement;
the source is credited here for method context. No source code, prose, examples,
fixtures, or tests were copied. The ten native implementations, bounded
workload, primary oracle, and independent oracle were written for this package.

The local [`counting_c4`](../counting_c4/README.md) package uses a different
task: it returns one result per input edge ID on an undirected multigraph. This
package counts simple-graph four-cycle edge sets once and returns one scalar.

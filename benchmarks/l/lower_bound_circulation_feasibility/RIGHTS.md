# Rights and provenance

The source used to identify the algorithm is CP-Algorithms, “Flow with
demands”: <https://cp-algorithms.com/graph/flow_with_demands.html>.
The article identifies its content as CC BY-SA 4.0. This package uses only
the standard algorithmic idea of converting lower-bounded flow constraints
into a maximum-flow instance with a super-source and super-sink. No source
code, examples, or prose were copied. The package contract, workload,
oracles, and ten language ports were independently authored.

The independent exhaustive oracle checks all bounded edge-flow assignments
and conservation constraints rather than applying the transformation. It is
included as an independent verification reference, not as a port of the
article's implementation.

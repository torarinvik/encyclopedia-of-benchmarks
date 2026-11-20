# Provenance and rights

The algorithm source is Phil Bagwell, *Fast Functional Lists, Hash-Lists,
Deques and Variable Length Arrays* (EPFL technical report, 2002),
<https://lampwww.epfl.ch/papers/techlists.pdf>, §4, Fig. 7, and §4.1. Section 4
provides the selected `r=0.25`, equal-sided 2D block profile, its `s=8`
starting layout, and the rule to begin a larger linked level after a level is
full. The level-header predecessor links and lookup traversal are a clean-room
operationalization of Fig. 7; the report's diagram and growth description are
not presented as indexing pseudocode.

The report is cited for algorithm provenance only. No source implementation,
report prose, figure, benchmark data, or protected examples are copied. The
contract, workload, Python references, and ten language ports are newly
written. The report's source license was not identified.

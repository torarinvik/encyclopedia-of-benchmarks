# Rights and provenance

This clean-room benchmark follows the algorithmic description of the
strength-of-connection network-erosion measure in Chapter 598 of the
*Encyclopedia of Algorithms*, DOI
[10.1007/978-1-4939-2864-4_598](https://doi.org/10.1007/978-1-4939-2864-4_598),
and the original paper by Colin Campbell, Juilee Thakar, and Réka Albert,
[“Network Analysis Reveals Cross-links of the Immune Pathways Activated by
Bacteria and Allergen,” *Physical Review E* 84, 031929
(2011)](https://doi.org/10.1103/PhysRevE.84.031929).

The publications remain under their publishers' copyrights. This repository
uses algorithm descriptions only; ports, references, test data, and metadata
are original. No source code, prose, figures, or example data were copied.
The profile fixes a shortest-path tie order, uses exact rational output, and
limits the procedure to distinct endpoints on bounded simple directed graphs
with positive unit arcs. The source SoC procedure does not distinguish path
signs; this profile omits sign labels and fixes all arcs positive.

The chapter's displayed normalization denominators for the `i != j` and
`i == j` branches appear reversed relative to the original paper. This profile
uses the paper's `i != j` normalization `(N + 2) / 2`, which its complete-graph
argument shows makes the maximum score equal to one. The `i == j` shortest-cycle
branch is outside this profile.

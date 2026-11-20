# Rights and provenance

This is an independently written clean-room profile of the dual-decomposition
algorithm described by Strandmark and Kahl in their [CVPR 2010 paper](https://doi.org/10.1109/CVPR.2010.5539886),
available from [Lund University](https://lucris.lub.lu.se/ws/portalfiles/portal/3989365/1580403.pdf).
The portal states that copyright and moral rights remain with the authors or
other copyright owners. This package uses the paper's algorithmic ideas only;
it copies no paper text, figures, source code, or evaluation instances.

The package fixes a bounded two-way overlap profile, exact fixed-point
`tau=1/k` updates, maximal sink-side min-cut ties, and a finite iteration cap.
It does not reproduce the paper's parallel/distributed runtime, reuse of
Boykov–Kolmogorov search trees, or Section 4 empirical step-length heuristic.

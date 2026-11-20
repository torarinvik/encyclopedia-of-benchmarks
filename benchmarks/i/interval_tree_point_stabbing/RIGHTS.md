# Provenance and rights

The benchmark algorithm is a clean-room implementation of the interval-tree
augmentation described in CLRS §14.3, with NIST DADS used as a topic index.
The algorithmic idea is a BST ordered by interval low endpoints augmented by
the maximum high endpoint in each subtree. No third-party source code,
comments, prose, fixtures, or tests are copied into the package. The native
ports and workload are authored for this repository.

The third edition presents interval trees in §14.3; the fourth edition
renumbers that topic to §17.3. The publisher page identifies the fourth
edition without hosting or redistributing the book text.

Sources:

- The MIT Press, *Introduction to Algorithms*, fourth edition: <https://mitpress.mit.edu/9780262046305/introduction-to-algorithms/>
- NIST DADS interval-tree entry: <https://xlinux.nist.gov/dads/HTML/intervaltree.html>

This note records algorithm provenance, not a license grant for the cited
book. No source-code license is relied upon.

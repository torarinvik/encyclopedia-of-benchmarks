# Rights and provenance

This benchmark is based on the three-state perfect-phylogeny problem discussed
in Jesper Jansson, “Perfect Phylogeny (Bounded Number of States),”
*Encyclopedia of Algorithms*, Chapter 288, DOI
[10.1007/978-1-4939-2864-4_288](https://doi.org/10.1007/978-1-4939-2864-4_288),
and the operational reduction by Dan Gusfield and Yufeng Wu, “The Three-state
Perfect Phylogeny Problem Reduces to 2-SAT,” §2, DOI
[10.4310/CIS.2009.v9.n4.a1](https://doi.org/10.4310/CIS.2009.v9.n4.a1).

The ports implement the expanded-character clauses and SCC decision procedure
independently, with package-authored preprocessing for characters observing
fewer than three states. The workload and references are independently authored; no
source code, figures, or examples are copied. The cited works remain under
their respective copyright and publication terms. This attribution does not
assert a license for their contents or for this clean-room benchmark package.

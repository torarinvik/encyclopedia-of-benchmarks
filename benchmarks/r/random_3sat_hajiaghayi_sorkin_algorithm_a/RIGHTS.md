# Rights and provenance

Algorithm attribution: MohammadTaghi Hajiaghayi and Gregory B. Sorkin,
“The Satisfiability Threshold of Random 3-SAT Is at Least 3.52,”
arXiv:math/0310193, Section 3, Algorithm A, DOI
10.48550/arXiv.math/0310193. The encyclopedia chapter context is “Thresholds
of Random k-SAT,” Chapter 423, DOI 10.1007/978-1-4939-2864-4_423.

The paper and chapter are used for algorithm attribution and behavioral
specification only. The ports, references, and workload in this package are
independently written for this repository. No source code, chapter prose, or
third-party workload data is included, and no license over the source works
is asserted.

The package preserves the paper’s printed assignment test `True iff i < j`
for positive degree `i` and negative degree `j`. Under standard Boolean
semantics this selects the less-frequent polarity as true; no alternate
literal convention is specified in Section 3.

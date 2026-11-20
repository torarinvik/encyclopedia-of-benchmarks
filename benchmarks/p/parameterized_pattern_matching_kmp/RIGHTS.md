# Rights and provenance

The algorithmic method is based on the published modified-KMP procedure in
Amir, Farach, and Muthukrishnan, “Alphabet Dependence in Parameterized
Matching,” §2, DOI
[`10.1016/0020-0190(94)90086-8`](https://doi.org/10.1016/0020-0190(94)90086-8).
The package's Encyclopedia crosswalk is Moshe Lewenstein, “Parameterized
Pattern Matching,” Chapter 282, DOI
[`10.1007/978-1-4939-2864-4_282`](https://doi.org/10.1007/978-1-4939-2864-4_282).

The references, native ports, workload, and documentation were independently
written for this repository. They use the source's algorithmic ideas and
mathematical rules only; they reproduce no source code, examples, tests,
figures, or expressive prose. The independent oracle uses direct bijection
checks per window rather than KMP.

# Rights and provenance

The multiply-shift family is specified from the mathematical description in
Dietzfelbinger, Hagerup, Katajainen, and Penttonen, “A Reliable Randomized
Algorithm for the Closest-Pair Problem,” *Journal of Algorithms* 25(1),
19–51 (1997), DOI [10.1006/jagm.1997.0873](https://doi.org/10.1006/jagm.1997.0873).
The [NIST DADS multiplication-method entry](https://xlinux.nist.gov/dads/HTML/multiplicationMethod.html)
is used as a discovery and contrast source only; it describes a different
irrational-constant method.

The paper is copyrighted. Only the published mathematical method is used.
No source code, comments, prose, figures, or test fixtures are copied or
adapted. The workload is independently authored from small arithmetic cases.
This repository's ports and references are clean-room work. Caller-supplied
odd multipliers model members of the family; the benchmark does not implement
a random-number generator or claim that a deterministic fixture measures
statistical collision quality.

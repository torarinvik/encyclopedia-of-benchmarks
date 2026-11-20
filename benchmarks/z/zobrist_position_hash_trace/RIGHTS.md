# Rights and provenance

Algorithm attribution is to Albert L. Zobrist, “A New Hashing Method with
Application for Game Playing,” University of Wisconsin Computer Sciences
Department Technical Report #88, April 1970,
[report PDF](https://research.cs.wisc.edu/techreports/1970/TR88.pdf). The
[NIST DADS tabulation-hashing entry](https://xlinux.nist.gov/dads/HTML/tabulationHashing.html)
provides the general XOR-of-feature-table-values definition and lists Zobrist
as a related application.

The primary report is cited for algorithm provenance, not as a license grant.
No published source code, comments, prose, task text, examples, or fixtures
were reused. The benchmark uses a local caller-supplied key table and fresh
fixtures. The ten language ports and two references were independently
written from the XOR feature/update rule. No claim is made about external
implementation licensing or the collision quality of caller-provided keys.

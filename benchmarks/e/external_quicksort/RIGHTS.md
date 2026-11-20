# Rights and provenance

The benchmark records the algorithm described in the public NIST DADS entry
for [external quicksort](https://xlinux.nist.gov/dads/HTML/externalQuicksort.html).
For implementation mechanics, the authors also consulted the entry's linked
Gonnet and Baeza-Yates *Handbook of Algorithms and Data Structures* reference,
[`446.sort.c`](https://users.dcc.uchile.cl/~rbaeza/handbook/algs/4/446.sort.c.html).

Only the algorithmic procedure was used as reference. No source code, tests,
problem statement, or examples were copied. The ten language ports, workload,
and Python references are clean-room benchmark material. The workload fixtures
are hand-authored bounded cases. The primary oracle is an original semantic
reference implementation; the independent oracle uses Python's built-in
integer ordering.

This file records provenance; it does not grant or imply a license for the
external references. See their source pages for their respective terms.

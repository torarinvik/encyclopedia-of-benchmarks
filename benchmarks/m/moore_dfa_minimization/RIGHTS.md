# Rights and provenance

The implementation is a clean-room expression of Moore's DFA state-refinement
method. Algorithmic behavior was derived from Edward F. Moore, “Gedanken-
Experiments on Sequential Machines,” *Automata Studies* (1956),
[DOI 10.1515/9781400882618-006](https://doi.org/10.1515/9781400882618-006),
and cross-checked against the NIST DADS
[finite-state-machine minimization entry](https://xlinux.nist.gov/dads/HTML/finitestmmin.html).
The DADS page is used for discovery and terminology; it does not supply code
for this package.

No source code, comments, prose, examples, test cases, or fixtures were copied
from those sources or from other implementations. The independent reference
uses pair distinguishability rather than the primary's class-signature
refinement.

# Rights and provenance

- **Algorithm description:** SciPy, [`scipy.optimize.ridder` reference](https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.ridder.html), citing C. F. J. Ridders, “A New Algorithm for Computing a Single Root of a Real Continuous Function,” *IEEE Transactions on Circuits and Systems* 26 (1979), 979–980.
- **Discovery and use:** the reference was consulted for the method identity, bracketed-root operation, and citation to the original paper. The Ridders update was implemented from its mathematical description. No source code, examples, tests, or task prose were copied.
- **Local work:** the four polynomial callbacks, integer-scaled float64 ABI, endpoint and capacity rules, workload, oracles, package documentation, and ten ports are original clean-room benchmark material.
- **License note:** SciPy is distributed under BSD-3-Clause; see its [license](https://github.com/scipy/scipy/blob/main/LICENSE.txt). This package does not incorporate SciPy code. The original paper is cited for attribution, not reproduced.

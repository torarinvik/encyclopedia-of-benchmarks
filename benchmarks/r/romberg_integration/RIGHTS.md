# Rights and provenance

- **Algorithm description:** [GNU Scientific Library — Romberg integration](https://www.gnu.org/software/gsl/doc/html/integration.html#romberg-integration), which describes successive trapezoid grids with halved spacing and repeated Richardson extrapolation.
- **Discovery and use:** the GSL manual was consulted for the method identity, recurrence structure, and qualitative domain of smooth integrands. No GSL source code, prose, example inputs, or tests were copied.
- **Local work:** the four fixed callbacks, integer-scaled float64 ABI, error and capacity semantics, workload, oracle pair, documentation, and ten ports are original clean-room benchmark material.
- **License note:** GSL is distributed under the GNU General Public License; see its [license page](https://www.gnu.org/software/gsl/). This package does not incorporate GSL code. The GSL manual is cited as an algorithm reference only.

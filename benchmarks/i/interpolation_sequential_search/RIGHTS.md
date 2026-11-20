# Rights and provenance

The algorithm identification follows the NIST Dictionary of Algorithms and
Data Structures entry for [interpolation-sequential search](https://xlinux.nist.gov/dads/HTML/interpsequen.html),
which describes estimating a location from the first and last array elements
and then using linear search to locate the target. The local contract defines
one estimate and a directional scan on strictly increasing signed integers.
It is distinct from repeatedly narrowing the interval by interpolation.

All code, workload fixtures, oracle logic, and explanatory prose in this
package were written independently. No upstream code, tests, examples, or
prose were copied.

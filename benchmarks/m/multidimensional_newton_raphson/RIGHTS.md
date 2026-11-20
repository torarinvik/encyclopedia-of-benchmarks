# Provenance and rights

The algorithmic idea is the standard Newton-Raphson correction for a system of
simultaneous nonlinear equations, using the Jacobian matrix. Method context is
Chen and Strader, “A normalized multidimensional Newton-Raphson method,”
*International Journal of Control* 12(2), 273–279 (1970), available through
[NASA NTRS](https://ntrs.nasa.gov/api/citations/19780021877/downloads/19780021877.pdf).
The paper is copyrighted. Only the general mathematical method is used as an
idea source; no source code, explanatory prose, paper equation layout,
examples, fixtures, tests, figures, or task content are reproduced.

The benchmark's bounded system, input/output contract, ten native ports,
workload, references, and documentation were independently authored. The
formulas and notation in the package describe its own bounded system and
contract. It explicitly measures the ordinary coupled Jacobian update and
makes no claim that it includes the paper's separate normalization transforms.

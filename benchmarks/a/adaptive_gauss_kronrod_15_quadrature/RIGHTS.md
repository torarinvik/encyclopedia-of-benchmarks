# Provenance and rights

The clean-room benchmark profile uses the high-level Gauss–Kronrod and adaptive interval-selection descriptions in the [GNU Scientific Library numerical-integration manual](https://www.gnu.org/software/gsl/doc/html/integration.html). The manual's documentation is made available under the GNU Free Documentation License; its source code has separate GNU licenses. This repository uses the algorithm description only and does not copy GSL source, test cases, or prose. The language ports, workload, and oracles are original implementations and data for this bounded benchmark contract.

The Gauss and Kronrod abscissae and weights are standard numerical quadrature constants. The benchmark's fixed functions and closed-form antiderivatives are included only to make the bounded workload deterministic and independently verifiable.

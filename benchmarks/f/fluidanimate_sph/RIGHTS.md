# Rights and provenance

This profile is a clean-room implementation of the bounded mathematical
contract documented in this package. Its algorithmic provenance is the
smoothed-particle hydrodynamics density, pressure, and viscosity description
for PARSEC Fluidanimate in the [PARSEC characterization paper](https://www.cs.princeton.edu/techreports/2008/811.pdf).
The [source mirror](https://gem5.googlesource.com/public/gem5-resources/+/refs/heads/develop/src/parsec/disk-image/parsec/parsec-benchmark/pkgs/apps/fluidanimate/src/serial.cpp)
and [constants header](https://gem5.googlesource.com/public/gem5-resources/+/refs/heads/develop/src/parsec/disk-image/parsec/parsec-benchmark/pkgs/apps/fluidanimate/src/fluid.hpp)
are linked for attribution and formula/parameter reference only.

No upstream source code, comments, prose, or benchmark input data is included
in the ports, workload, oracles, or documentation. The original
[`src/COPYRIGHT`](https://gem5.googlesource.com/public/gem5-resources/+/refs/heads/develop/src/parsec/disk-image/parsec/parsec-benchmark/pkgs/apps/fluidanimate/src/COPYRIGHT)
names Intel Corp. (2007) but gives no standalone license grant. Although the
PARSEC repository root carries a [BSD-3-Clause license](https://github.com/csail-csg/parsec/blob/master/LICENSE),
the suite documentation notes application-specific terms can differ. This
package claims no license grant for upstream Fluidanimate code; its files are
original clean-room implementations of the stated equations.

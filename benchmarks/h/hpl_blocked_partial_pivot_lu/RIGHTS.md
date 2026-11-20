# Rights and provenance

This package is a clean-room implementation of a bounded algorithmic profile
based on the algorithm description in Netlib's official [HPL documentation](https://netlib.sandia.gov/benchmark/hpl/algorithm.html).
The algorithm description is used as a source of ideas and method selection;
no HPL source code, prose, benchmark input, or generated artifact is copied
into these ports. The profile explicitly excludes HPL's MPI distribution,
communication, look-ahead, and tuning machinery.

All package references, fixtures, and ten language ports were written for this
repository. The documentation and links identify provenance and do not imply
that this package is part of, endorsed by, or a substitute for HPL.

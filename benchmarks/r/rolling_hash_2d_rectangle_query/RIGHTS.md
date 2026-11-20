# Rights and provenance

The algorithm idea is based on the public description of Nyaan's
[Two-Dimensional Rolling Hash](https://nyaannyaan.github.io/library/string/rolling-hash-2d.hpp),
which describes row and column powers, a two-dimensional prefix-hash table,
and four-corner extraction of rectangular hashes. The source library uses its
own hash type and runtime-selected bases; this benchmark independently fixes
the row base to 31, the column base to 37, and the modulus to 1,000,000,007.

All ports, workload cases, oracle logic, contract text, and documentation in
this package are clean-room authored. No upstream code, tests, examples, or
prose are copied. The hash is treated as a deterministic fingerprint with
possible collisions, not as an exact representation of a rectangle.

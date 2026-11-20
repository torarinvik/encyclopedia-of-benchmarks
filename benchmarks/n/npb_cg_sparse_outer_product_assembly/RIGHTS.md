# Rights and clean-room provenance

The benchmark specification is based on the mathematical procedure in D.
Bailey et al., *The NAS Parallel Benchmarks*, NASA Ames Technical Report
RNR-94-007, §2.2.3. The NASA NPB 3.4.4 archive is cited as an implementation
behavior cross-check for the anchor insertion/replacement and sparse
coordinate coalescing behavior.

The benchmark implementations, reference routines, fixtures, and explanatory
text are independently written. No NASA source code, comments, source text, or
test fixtures are copied. PRNG behavior and random-vector sampling are outside
the benchmark ABI; deterministic vectors are supplied directly by each input.
The source-version difference in the geometric weight schedule is described in
the README and workload, and this profile follows the report's endpoint
definition.

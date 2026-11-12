# Rights and clean-room provenance

The profile is based on the algorithmic specification in D. Bailey et al.,
*The NAS Parallel Benchmarks*, NASA Ames NAS Technical Report RNR-94-007,
March 1994, §3.3.2. The report supplies the high-level 3-D regular block
operator and SSOR steps used as the algorithmic source.

The language ports and Python oracles are independently written from that
published description. They do not copy NASA sample source, comments, report
prose, or reference-output tables. This bounded local profile supplies an
explicit coefficient family and does not claim to reproduce the PDE setup,
forcing, boundary construction, full NPB-LU timestep schedule, official class
run, or NASA endorsement.

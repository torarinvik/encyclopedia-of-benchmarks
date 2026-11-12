# Rights and clean-room provenance

The algorithmic profile is based on the written description in D. Bailey et
al., *The NAS Parallel Benchmarks*, NASA Ames NAS Technical Report RNR-94-007,
March 1994, §2.2.3. The report is cited as the source for the benchmark's
high-level algorithm and expected output concepts.

The ports and Python oracles in this package are independently written from
that algorithmic description. They do not copy NASA sample source, source-code
comments, report prose, or benchmark reference output tables. This local
bounded profile accepts an explicit CSR matrix and does not include the
canonical `makea` generator; it does not claim to be an official NASA NPB
implementation or carry NASA endorsement.


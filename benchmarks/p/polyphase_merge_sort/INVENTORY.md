# Static package inventory

- `workload.json` defines the bounded `sort_call` contract, run size, tape
  layout, and fixtures.
- `primary_oracle.py` is an iterative bottom-up mergesort reference.
- `independent_oracle.py` is an insertion-sort reference.
- `verify_workload.py` statically inspects package metadata, fixtures, docs,
  and the ten source-port inventory; it has not been run.
- `benchmarks/verify_polyphase_merge_sort.py` provides exhaustive short-array,
  boundary, maximum-size, seeded-random, and workload checks through the
  shared sort checker and recorder; it has not been run.
- Ten language source ports are listed in the package checker.
- `external_merge_sorter` uses balanced bottom-up passes in two sequential
  stores; the local k-sorted merge packages only merge pre-sorted inputs.
  Neither implements the uneven Fibonacci distribution and exhausted-tape
  rotation that identify this profile.
- The generic `sort_call` recorder in `benchmarks/run_sort.py`, dedicated
  verifier in `benchmarks/verify_polyphase_merge_sort.py`, and root catalog and
  coverage entries are present. No programs, tests, scripts, checkers, builds,
  compilers, profilers, or benchmarks were run.

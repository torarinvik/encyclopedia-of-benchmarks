# External Quicksort inventory

- `README.md`: bounded `sort_call` contract, algorithm summary, distinction,
  language links, and source attribution.
- `RIGHTS.md`: source provenance and clean-room implementation note.
- `workload.json`: standard input lengths, bounded profile, semantic fixtures,
  and source metadata.
- `primary_oracle.py`: fixed-buffer endpoint quicksort reference.
- `independent_oracle.py`: independent built-in-order reference.
- `verify_workload.py`: package-local static contract, fixture, documentation,
  verifier-presence, and ten-port inventory checker.
- `c/e/external_quicksort.c`
- `c3/e/external_quicksort.c3`
- `cpp/e/external_quicksort.cpp`
- `elisa/e/external_quicksort.elisa`
- `mojo/e/external_quicksort.mojo`
- `nim/e/external_quicksort.nim`
- `odin/e/external_quicksort.odin`
- `rust/e/external_quicksort.rs`
- `v/e/external_quicksort.v`
- `zig/e/external_quicksort.zig`
- `benchmarks/verify_external_quicksort.py`: dedicated sort checker and
  workload recorder verifier; it has not been run.

The generic `build_abi.py` and `run_sort.py` paths provide shared `sort_call`
integration. This package and its catalog entries have not been built or
executed.

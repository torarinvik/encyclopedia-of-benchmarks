# Static inventory

`round_robin_tournament_schedule` has native source paths for C, C3, C++,
Elisa, Mojo, Nim, Odin, Rust, V, and Zig. The package includes two reference
constructions, a bounded byte-output workload, rights/provenance notes, and a
title-only score-slice audit.

The accepted frame is one i64 word (`team_count` 2 through 8); a two-word frame
is parseable and malformed. Output is at most 58 bytes, and the fixed opponent
table plus ring scratch fits the 128-byte workspace cap. The workload covers
even and odd schedules, byes, maximum output, malformed framing, null buffers,
and short output capacity.

`check_inventory.py` and `verify_workload.py` provide static metadata and
fixture-reconciliation APIs. Neither has been run. Shared suite and catalog
registration remain root-owned.

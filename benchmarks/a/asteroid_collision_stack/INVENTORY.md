# Static inventory

The package provides the `asteroid_collision_stack` C ABI in ten languages:
C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig. The package-local
inventory records all source paths and artifacts.

The input frame is at most 65 words when valid and at most 66 words when
parseable. Output is at most 65 bytes. Native scratch is capped at 512 bytes.
The workload covers survivor ordering, divergent motion, smaller/equal/larger
collision outcomes, cascade behavior, full-boundary framing, malformed input,
null pointers, and short capacity. Primary and independent references use
separate traversals.

`check_inventory.py` and `verify_workload.py` provide static source/metadata and
fixture reconciliation APIs. They have not been run. The byte-output runner
and verifier, root README, and catalog now register this package.

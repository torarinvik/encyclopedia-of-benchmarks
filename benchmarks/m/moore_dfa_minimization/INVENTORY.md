# Package inventory

The package uses `i64_array_scalar` and exports `moore_dfa_minimization`.
Its source map lists C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig.
The accepted frame is 4–28 i64 words; a one-word overlong frame is parseable
for rejection. The packed positive result contains 3-bit state class labels,
the strict refinement round count, and the final class count. Fixed scratch
stays within 4,096 bytes.

Package artifacts are listed in `INVENTORY.json`: primary Moore refinement,
independent pair-distinguishability reference, workload, rights note, README,
static inventory checker, and workload validator. Runner, verifier, catalog,
and coverage registration are complete. Source files were statically reviewed only; no
programs, tests, scripts, helpers, checkers, builds, compilers, profilers, or
benchmarks were run.

# Rights and provenance

The operation, sampling-point convention, modulus, and official bound are
attributed to Library Checker’s `shift_of_sampling_points_of_polynomial` task
and its Apache-2.0 task repository. This benchmark uses only the task contract
and mathematical operation. Its bounded profile, implementation, workload,
oracles, and documentation are clean-room work; no upstream source code,
tests, fixtures, or prose were copied.

The local profile restricts `N` and `M` to 16 so the finite-difference
recurrence and direct Lagrange oracle remain small in every supported language.

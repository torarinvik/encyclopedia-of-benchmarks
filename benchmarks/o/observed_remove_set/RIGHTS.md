# Rights and provenance

The benchmark is based on the add-wins observed-remove set state machine
described by TheAlgorithms/Java's `ORSet.java`, in the repository's MIT-licensed
tree. The source is used only to identify the algorithm and its operations.
The Java `Pair` implementation relies on object identity equality, which does
not give equal tag values matching behavior across independently created
objects; this benchmark does not copy that implementation. No source code,
prose, tests, or fixtures were copied.

The ports, bounded contract, references, workload, and documentation are
independently authored. UUIDs are replaced with deterministic value-based tags
`(element, creator_replica, creator_local_sequence)` so the benchmark has
repeatable results across all supported languages.

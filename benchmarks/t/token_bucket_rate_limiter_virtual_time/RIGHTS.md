# Rights and provenance

The benchmark uses the token-bucket state machine described by
TheAlgorithms/Java's `TokenBucket.java`, in the repository's MIT-licensed
tree. The source is used only to identify the refill-before-admission
algorithm. No Java source code, prose, tests, or fixtures were copied.

The ports, bounded contract, two references, workload, and documentation are
independently authored. Wall-clock timing and synchronization are replaced by
explicit integer elapsed-time inputs so every language sees the same trace.

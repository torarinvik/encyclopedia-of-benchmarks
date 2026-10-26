# PPSZ bounded 3-SAT trace

This package implements one deterministic trace of the PPSZ algorithm described in Timon Hertli's *Encyclopedia of Algorithms* chapter “Unique k-SAT and General k-SAT,” DOI [`10.1007/978-1-4939-2864-4_680`](https://doi.org/10.1007/978-1-4939-2864-4_680). The chapter's random assignment and variable order are supplied as workload inputs so the trace is reproducible.

## Bounded contract

- ABI: `i64_array_bytes_output`; input is `[n,m,clause_literals[3m],permutation[n],guess_bits[n]]`. Literals are signed one-based variable IDs: `v` is positive and `-v` is negative. Every clause contains three literals over distinct variables.
- `3 <= n <= 8`, `0 <= m <= 12`; the permutation lists each variable ID in `[0,n)` once, and each guess bit is 0 or 1. Let `t=floor(log2(n))`. A `t`-implied assignment is one fixed by every satisfying assignment of some nonempty set of at most `t` clauses under the current partial assignment. The implementation checks this definition by exhaustive assignment enumeration.
- For each variable in the supplied permutation, repeatedly assign the lowest-index currently unassigned variable that is implied by a clause subset. Ties use the lowest numeric clause-subset mask. If no such implication exists, guess the current variable using its supplied bit if still unset. An inconsistent partial assignment has no implications; later unset variables are still filled from their supplied guess bits. This deterministic tie policy makes one trace exact.
- Output is `[satisfiable_bit,assignment[0..n)]`, in little-endian signed-i64 words. A final assignment that satisfies every input clause returns 1; otherwise it returns 0. Maximum input is 54 words and output is 72 bytes.
- This profile preserves the PPSZ variable-forcing and guess sequence on bounded 3-CNF. Supplying one permutation and one guess vector does not claim the randomized success probability, unique-solution promise, or running-time theorem from the chapter.

## Provenance and rights

Source attribution: Timon Hertli, “Unique k-SAT and General k-SAT,” *Encyclopedia of Algorithms*, DOI `10.1007/978-1-4939-2864-4_680`. The chapter and summarized research remain copyrighted. This is a clean-room implementation of the described algorithm; no source code, prose, or figures are copied, and no source-code license is asserted. See [`RIGHTS.md`](RIGHTS.md).

## Package files

- [`workload.json`](workload.json)
- [primary bit-mask oracle](../../ppsz_k_sat_trace_oracle.py)
- [independent recursive-assignment verifier](../../ppsz_k_sat_trace_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/p/ppsz_k_sat_trace.c`](../../../c/p/ppsz_k_sat_trace.c) |
| C3 | [`c3/p/ppsz_k_sat_trace.c3`](../../../c3/p/ppsz_k_sat_trace.c3) |
| C++ | [`cpp/p/ppsz_k_sat_trace.cpp`](../../../cpp/p/ppsz_k_sat_trace.cpp) |
| Elisa | [`elisa/p/ppsz_k_sat_trace.elisa`](../../../elisa/p/ppsz_k_sat_trace.elisa) |
| Nim | [`nim/p/ppsz_k_sat_trace.nim`](../../../nim/p/ppsz_k_sat_trace.nim) |
| Odin | [`odin/p/ppsz_k_sat_trace.odin`](../../../odin/p/ppsz_k_sat_trace.odin) |
| Rust | [`rust/p/ppsz_k_sat_trace.rs`](../../../rust/p/ppsz_k_sat_trace.rs) |
| V | [`v/p/ppsz_k_sat_trace.v`](../../../v/p/ppsz_k_sat_trace.v) |
| Zig | [`zig/p/ppsz_k_sat_trace.zig`](../../../zig/p/ppsz_k_sat_trace.zig) |

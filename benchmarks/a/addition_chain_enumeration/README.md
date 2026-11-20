# Unrestricted shortest addition-chain enumeration

For a bounded positive target, find its minimum addition-chain length and count
all chains at that length, split into Brauer (star) chains and non-Brauer
chains. Each new term is a strictly larger sum of two earlier terms; a Brauer
step additionally uses the immediately preceding term as one addend.

## Contract

The exported symbol is `addition_chain_enumeration` in the
`i64_array_bytes_output` ABI. Input is exactly `[target]`, with
`1 <= target <= 31`. Output is three signed 64-bit little-endian words:
`[minimum_length, brauer_chain_count, non_brauer_chain_count]`, always 24 bytes.
Malformed or out-of-profile input returns `-1`; a null output or capacity below
24 bytes returns `-2`. Errors do not write output.

For target 1, the empty chain has length zero and is counted as one Brauer
chain. For larger targets, the search starts at the doubling lower bound and
increases the allowed length until the target is reachable. At each level it
enumerates each distinct legal next value once, prunes prefixes that cannot
reach the target by repeated doubling, and counts all shortest chains.

The bounded search is exponential in chain length; each extension considers
at most `O(L^2)` pairs from a chain of length `L`. The primary uses
iterative-deepening depth-first search with a single mutable chain. The
independent verifier builds breadth-first frontiers of distinct chains and
classifies each complete chain directly. The workload's concrete fixtures use
small targets selected independently of the source task; a separate boundary
profile exercises the upper target.

## Relationship to existing benchmarks

[`problem122`](../../p/problem122/README.md) searches only star chains and sums
their minimum lengths over a target prefix. [`knuth_power_tree`](../../k/knuth_power_tree/README.md)
shares first discoveries in a deterministic tree and can return a nonoptimal
chain. This profile instead computes the unrestricted minimum and counts both
classes of optimal chains, so it benchmarks a distinct enumeration task.

See [`workload.json`](workload.json) and [`RIGHTS.md`](RIGHTS.md) for the
bounded profile and attribution. The ten ports are listed below.

| Language | Source |
|---|---|
| C | [`c/a/addition_chain_enumeration.c`](../../../c/a/addition_chain_enumeration.c) |
| C3 | [`c3/a/addition_chain_enumeration.c3`](../../../c3/a/addition_chain_enumeration.c3) |
| C++ | [`cpp/a/addition_chain_enumeration.cpp`](../../../cpp/a/addition_chain_enumeration.cpp) |
| Elisa | [`elisa/a/addition_chain_enumeration.elisa`](../../../elisa/a/addition_chain_enumeration.elisa) |
| Mojo | [`mojo/a/addition_chain_enumeration.mojo`](../../../mojo/a/addition_chain_enumeration.mojo) |
| Nim | [`nim/a/addition_chain_enumeration.nim`](../../../nim/a/addition_chain_enumeration.nim) |
| Odin | [`odin/a/addition_chain_enumeration.odin`](../../../odin/a/addition_chain_enumeration.odin) |
| Rust | [`rust/a/addition_chain_enumeration.rs`](../../../rust/a/addition_chain_enumeration.rs) |
| V | [`v/a/addition_chain_enumeration.v`](../../../v/a/addition_chain_enumeration.v) |
| Zig | [`zig/a/addition_chain_enumeration.zig`](../../../zig/a/addition_chain_enumeration.zig) |

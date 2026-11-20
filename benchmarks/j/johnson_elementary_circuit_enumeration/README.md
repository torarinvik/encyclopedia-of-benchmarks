# Johnson elementary circuit enumeration

Enumerate every elementary directed circuit once using Johnson's
output-sensitive algorithm. Each iteration restricts attention to a
strongly-connected component, chooses that component's least-numbered vertex
as the circuit root, and uses blocked vertices with dependency sets to avoid
repeating fruitless path searches. Once all circuits for that root have been
reported, the search advances to vertices with larger labels.

This benchmarks the blocked-set algorithm, which is distinct from the local
[`directed_simple_cycles`](../directed_simple_cycles/README.md) path-search
implementation. The reference implementation enumerates canonical simple
paths directly and does not use Johnson's SCC or blocked-set pruning.

## Contract

Input is `[n,m,(u,v)*m]`, representing a simple loopless directed graph with
vertices `0..n-1`. Bounds are `1<=n<=8` and `0<=m<=24`. Self-loops,
duplicate arcs, invalid endpoints, and incorrect lengths are rejected. A valid
graph may have no circuits; its result is zero. A 50-value input is the
maximum valid frame, and the maximum parseable frame is 51 values.

For each circuit, rotate its directed vertex sequence so its smallest vertex
comes first. Its code is `sum((v_i+1)*9^i)` over that sequence. The scalar
result is `circuit_count*1,000,000,000,000 + sum(circuit_code)`. Direction is
preserved, so opposite orientations count as separate circuits when both
exist. A safe result upper bound is `16,064,691,498,654,720`, derived from all
circuits in the complete eight-vertex digraph; the workload's 24-arc limit
makes the actual reachable maximum lower. Scratch state is bounded to 4,096
bytes.

Johnson's procedure has `O((n+m)(c+1))` time for `c` reported circuits. All
ten language ports use Tarjan SCC discovery; the primary reference uses
Kosaraju's two-pass SCC algorithm. The independent reference searches all
canonical simple paths and is intended only for this small bounded workload.

The algorithm description follows Donald B. Johnson's [paper on finding all
elementary circuits of a directed graph](https://doi.org/10.1137/0204007).
Only the algorithm idea was consulted. The contract, workload, references,
and language ports are independently authored.

| Language | Port |
|---|---|
| C | [c/j/johnson_elementary_circuit_enumeration.c](../../../c/j/johnson_elementary_circuit_enumeration.c) |
| C3 | [c3/j/johnson_elementary_circuit_enumeration.c3](../../../c3/johnson_elementary_circuit_enumeration.c3) |
| C++ | [cpp/j/johnson_elementary_circuit_enumeration.cpp](../../../cpp/johnson_elementary_circuit_enumeration.cpp) |
| Elisa | [elisa/j/johnson_elementary_circuit_enumeration.elisa](../../../elisa/j/johnson_elementary_circuit_enumeration.elisa) |
| Mojo | [mojo/j/johnson_elementary_circuit_enumeration.mojo](../../../mojo/johnson_elementary_circuit_enumeration.mojo) |
| Nim | [nim/j/johnson_elementary_circuit_enumeration.nim](../../../nim/johnson_elementary_circuit_enumeration.nim) |
| Odin | [odin/j/johnson_elementary_circuit_enumeration.odin](../../../odin/johnson_elementary_circuit_enumeration.odin) |
| Rust | [rust/j/johnson_elementary_circuit_enumeration.rs](../../../rust/johnson_elementary_circuit_enumeration.rs) |
| V | [v/j/johnson_elementary_circuit_enumeration.v](../../../v/johnson_elementary_circuit_enumeration.v) |
| Zig | [zig/j/johnson_elementary_circuit_enumeration.zig](../../../zig/johnson_elementary_circuit_enumeration.zig) |

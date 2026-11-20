# Hypercube edge monotonicity tester

This package implements the standard edge tester for coordinatewise
monotonicity on the Boolean hypercube. One trial samples a uniform hypercube
edge, queries its two endpoints in lower-to-upper order, and rejects if the
function decreases along that edge. Chakrabarty and Seshadhri give the edge
tester and its query guarantee for the hypercube; this profile makes the
sampled edge tape explicit for deterministic replay.

## Bounded contract

- ABI: `i64_array_bytes_output`; symbol `hypercube_edge_monotonicity_tester`.
- Input: `[n,q,f(0),...,f(2^n-1),v0,i0,...,v(q-1),i(q-1)]`.
- `1<=n<=6`, `1<=q<=32`. The Boolean truth table uses the integer point as
  its index, with coordinate zero in the least significant bit. Each tape
  pair has vertex `v` in `[0,2^n)` and coordinate `i` in `[0,n)`.
- Each pair samples vertex `v` and coordinate `i`; the edge is canonicalized
  to `low = v with bit i cleared` and `high = low with bit i set`. Uniform
  independent choices of `v` and `i` induce a uniform undirected hypercube
  edge. The test queries both values and rejects if `f(low)>f(high)`.
- Process samples in tape order and stop at the first violation. Output is
  `[accept_bit,rounds_executed,oracle_query_calls]`, counting two query calls
  per evaluated round, including repeats across rounds. The tape and fixed
  `q` are caller supplied, so the profile makes no soundness or
  epsilon-to-query-count claim.
- Maximum valid input is 130 signed-i64 words; up to 131 words are parsed to
  reject trailing input. Output is three little-endian signed
  i64 words (24 bytes). Invalid input returns `-1`; null or short output
  returns `-2` without writes. Workspace is bounded to 1,024 bytes.

This differs from local [`monotonic_array`](../../m/monotonic_array/README.md),
which checks whether a one-dimensional sequence is nondecreasing or
nonincreasing. The edge tester checks a Boolean function against the product
partial order and may reject after observing one sampled local violation.

The primary oracle stops on the first source-order violation. The independent
oracle computes the complete edge-violation trace before deriving the visible
stopping prefix.

## Source and rights

The package follows Deeparnab Chakrabarty, “Monotonicity Testing,”
*Encyclopedia of Algorithms*, Chapter 699, DOI
[10.1007/978-1-4939-2864-4_699](https://doi.org/10.1007/978-1-4939-2864-4_699),
and the explicit hypercube edge tester of Deeparnab Chakrabarty and C.
Seshadhri, “Optimal Bounds for Monotonicity and Lipschitz Testing over
Hypercubes and Hypergrids,” STOC 2013, §1.1 and §2
([arXiv:1204.0849](https://arxiv.org/abs/1204.0849),
[DOI 10.1145/2488608.2488661](https://doi.org/10.1145/2488608.2488661)).
These sources are used for attribution and algorithm semantics only. This
package reuses no code, prose, figures, or fixtures; see [`RIGHTS.md`](RIGHTS.md).

## Package files

- [`workload.json`](workload.json)
- [primary reference](primary_oracle.py)
- [independent reference](independent_oracle.py)
- [fixture reference verifier](verify_workload.py)
- [static inventory checker](check_inventory.py)
- [`INVENTORY.md`](INVENTORY.md) and [`inventory.json`](inventory.json)

| Language | Port |
|---|---|
| C | [`c/h/hypercube_edge_monotonicity_tester.c`](../../../c/h/hypercube_edge_monotonicity_tester.c) |
| C3 | [`c3/h/hypercube_edge_monotonicity_tester.c3`](../../../c3/h/hypercube_edge_monotonicity_tester.c3) |
| C++ | [`cpp/h/hypercube_edge_monotonicity_tester.cpp`](../../../cpp/h/hypercube_edge_monotonicity_tester.cpp) |
| Elisa | [`elisa/h/hypercube_edge_monotonicity_tester.elisa`](../../../elisa/h/hypercube_edge_monotonicity_tester.elisa) |
| Mojo | [`mojo/h/hypercube_edge_monotonicity_tester.mojo`](../../../mojo/h/hypercube_edge_monotonicity_tester.mojo) |
| Nim | [`nim/h/hypercube_edge_monotonicity_tester.nim`](../../../nim/h/hypercube_edge_monotonicity_tester.nim) |
| Odin | [`odin/h/hypercube_edge_monotonicity_tester.odin`](../../../odin/h/hypercube_edge_monotonicity_tester.odin) |
| Rust | [`rust/h/hypercube_edge_monotonicity_tester.rs`](../../../rust/h/hypercube_edge_monotonicity_tester.rs) |
| V | [`v/h/hypercube_edge_monotonicity_tester.v`](../../../v/h/hypercube_edge_monotonicity_tester.v) |
| Zig | [`zig/h/hypercube_edge_monotonicity_tester.zig`](../../../zig/h/hypercube_edge_monotonicity_tester.zig) |

The shared byte-output suite registers both references, fixtures, bounds, and
package metadata. No programs, tests, scripts, checkers, builds, compilers,
profilers, or benchmarks were run.

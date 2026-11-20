# Riordan number

This package returns the exact `n`th Riordan number, which counts length-`n`
Motzkin paths that start and end at height zero, never go below zero, and do
not take a horizontal step at ground level.

## Contract

- ABI: `i64_array_scalar`; symbol: `riordan_number`.
- Input is exactly `[n]`, with `0<=n<=30`; malformed framing or values outside
  the domain return `-1`.
- `R_0=1`, `R_1=0`, and for `n>=2`,
  `(n+1)R_n=(n-1)(2R_(n-1)+3R_(n-2))`.
- The primary fills a bottom-up table and performs at most 29 recurrence
  updates. Its largest recurrence numerator is below `1.4e13`, and the largest
  result is `R_30=439,742,222,071`; both fit signed i64.
- The independent reference computes `R_n=t(n,0)-t(n,-1)`, the difference of
  central trinomial coefficients. It counts unrestricted up/flat/down walks
  by ending height, with at most `3^30=205,891,132,094,649` walks in any
  intermediate count, below signed-i64 maximum.
- The primary table uses 31 i64 values (248 bytes); the declared native
  workspace cap is 512 bytes, including bounded container overhead in Mojo.

This is distinct from the local Motzkin-number profile: Motzkin counts all
nonnegative excursions, while Riordan paths prohibit horizontal steps at
height zero.

## Source and provenance

The RosettaCodeData popular-title index was used to discover “Riordan numbers.”
Chen, Deng, and Yang give the Riordan path definition and prove the recurrence
used by the primary. Callan gives the independent central-trinomial difference
identity. The ports, oracle implementations, and fixtures are clean-room
material; no task code, prose, or fixture values were copied.

- [Chen, Deng, and Yang, “Riordan Paths and Derangements”](https://arxiv.org/abs/math/0602298)
- [Callan, “Riordan Numbers Are Differences of Trinomial Coefficients”](https://pages.stat.wisc.edu/~callan/notes/riordan/riordan.pdf)
- [OEIS A005043](https://oeis.org/A005043)
- [RosettaCodeData popular-tasks index](https://raw.githubusercontent.com/acmeism/RosettaCodeData/main/popular-tasks)

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/r/riordan_number.c`](../../../c/r/riordan_number.c) |
| C3 | [`c3/r/riordan_number.c3`](../../../c3/r/riordan_number.c3) |
| C++ | [`cpp/r/riordan_number.cpp`](../../../cpp/r/riordan_number.cpp) |
| Elisa | [`elisa/r/riordan_number.elisa`](../../../elisa/r/riordan_number.elisa) |
| Mojo | [`mojo/r/riordan_number.mojo`](../../../mojo/r/riordan_number.mojo) |
| Nim | [`nim/r/riordan_number.nim`](../../../nim/r/riordan_number.nim) |
| Odin | [`odin/r/riordan_number.odin`](../../../odin/r/riordan_number.odin) |
| Rust | [`rust/r/riordan_number.rs`](../../../rust/r/riordan_number.rs) |
| V | [`v/r/riordan_number.v`](../../../v/r/riordan_number.v) |
| Zig | [`zig/r/riordan_number.zig`](../../../zig/r/riordan_number.zig) |

The package has two independent references, bounded workloads, and static
inventory metadata. The shared scalar runner and verifier register its
primary and independent references, workload bounds, workspace cap, and null
input cases.

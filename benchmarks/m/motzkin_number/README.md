# Motzkin number

This package returns the exact `n`th Motzkin number, the number of Motzkin
excursions of length `n` (steps up, level, and down that never go below height
zero and end at height zero).

## Contract

- ABI: `i64_array_scalar`; symbol: `motzkin_number`.
- Input is exactly `[n]`, with `0<=n<=30`; malformed framing or values outside
  the domain return `-1`.
- `M_0=M_1=1`, and for `n>=2`,
  `M_n=M_(n-1)+sum(M_i*M_(n-2-i), i=0..n-2)`.
- The primary fills a bottom-up table through the requested index. It performs
  at most `30*29/2=435` convolution products and stores 31 signed 64-bit
  values (248 bytes). Since all terms are nonnegative and each partial sum is
  bounded by `M_30=1,697,385,471,211`, all primary arithmetic fits i64.
- The independent reference uses
  `M_n=sum(binomial(n,2k)*Catalan(k), k=0..floor(n/2))`. For `n<=30`, each
  binomial factor is at most `binomial(30,15)=155,117,520`, each Catalan factor
  is at most `Catalan(15)=9,694,845`, and even 16 copies of their product are
  below `2.5e16`, safely inside signed i64. The reference computes binomial
  coefficients and Catalan values from factorial-free multiplicative formulas.
- The independent reference uses `O(n^2)` arithmetic operations because it
  recomputes each binomial coefficient multiplicatively; its temporary state
  is constant-sized.
- Native primary workspace is one 31-entry i64 table (248 bytes); the declared
  cap is 512 bytes, including bounded container overhead in the Mojo port.

This sequence profile differs from the local Catalan-number, factorial,
integer-partition, and Entringer-number profiles: it evaluates the Motzkin
recurrence and returns a single exact sequence term.

## Source and provenance

The RosettaCodeData popular-title index was used only to discover the
“Motzkin numbers” task. Donaghey and Shapiro give the Motzkin generating
function equation and its combinatorial interpretations in “Motzkin Numbers,”
*Journal of Combinatorial Theory, Series A* 23(3) (1977), 291–301. The
independent binomial-Catalan form is a separate coefficient formula for the
same generating function. The OEIS entry is cited only to cross-reference the
sequence and its bounded maximum value.

- [Donaghey and Shapiro paper](https://doi.org/10.1016/0097-3165(77)90020-6)
- [OEIS A001006](https://oeis.org/A001006)
- [RosettaCodeData popular-tasks index](https://raw.githubusercontent.com/acmeism/RosettaCodeData/main/popular-tasks)

The language ports, references, and fixtures are clean-room material. No task
code, prose, or fixture values were copied.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/m/motzkin_number.c`](../../../c/m/motzkin_number.c) |
| C3 | [`c3/m/motzkin_number.c3`](../../../c3/m/motzkin_number.c3) |
| C++ | [`cpp/m/motzkin_number.cpp`](../../../cpp/m/motzkin_number.cpp) |
| Elisa | [`elisa/m/motzkin_number.elisa`](../../../elisa/m/motzkin_number.elisa) |
| Mojo | [`mojo/m/motzkin_number.mojo`](../../../mojo/m/motzkin_number.mojo) |
| Nim | [`nim/m/motzkin_number.nim`](../../../nim/m/motzkin_number.nim) |
| Odin | [`odin/m/motzkin_number.odin`](../../../odin/m/motzkin_number.odin) |
| Rust | [`rust/m/motzkin_number.rs`](../../../rust/m/motzkin_number.rs) |
| V | [`v/m/motzkin_number.v`](../../../v/m/motzkin_number.v) |
| Zig | [`zig/m/motzkin_number.zig`](../../../zig/m/motzkin_number.zig) |

The package contains two independent references, bounded workloads, and static
inventory metadata. The shared scalar runner and verifier register the primary
and independent references, workload bounds, workspace cap, and null-input
cases.

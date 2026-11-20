# NegaFibonacci representation

This package encodes signed integers with the unique nonadjacent expansion
over negatively indexed Fibonacci weights. It is a clean-room bounded profile
for the candidate reserved in the algorithm coverage ledger.

## Contract

The exported symbol is `negafibonacci_representation` in the
`i64_array_bytes_output` family. Input is exactly one signed 64-bit integer
`[value]` with `-1000 <= value <= 1000`. Let `F_1=1`, `F_2=1`, and
`F_k=F_(k-1)+F_(k-2)`. The negatively indexed weights are
`F_-k=(-1)^(k+1) F_k` for `1<=k<=17`, so they begin
`1,-1,2,-3,5,-8,...,1597`.

Output is the ASCII bit string `c_r...c_1` for
`value = sum(c_k * F_-k)`, where every `c_k` is 0 or 1 and no two adjacent
coefficients are 1. Leading zeroes are omitted; zero is encoded as `0`.
Examples include `1 -> 1`, `-1 -> 10`, `4 -> 10010`, and `-4 -> 1010`.
Because the nonadjacent representation is unique, this is the canonical
representation, not a separate sign/magnitude wrapper. Invalid input returns
`-1`; null output or capacity below the complete string length returns `-2`;
errors write no bytes. The maximum output is 17 bytes. The declared 640-byte
workspace covers the fixed local tables and staged output used by the ports.

## Algorithm and bounds

The ports compute the interval of values expressible using the first `k`
weights. With `I_0=I_-1=[0,0]`, the recurrence is
`I_k = I_(k-1) union (F_-k + I_(k-2))`. For this alternating Fibonacci
sequence, the two intervals are disjoint or adjacent and their union is an
integer interval. Starting at `k=17`, the encoder tests whether the remaining
value lies in `F_-k + I_(k-2)`. If so, it emits 1, subtracts `F_-k`, and
forces the next lower coefficient to 0; otherwise it emits 0. It then
continues toward `k=1`. The resulting interval is
`I_17=[-1596,2584]`, which contains the complete input range.

For this fixed bound, interval construction and encoding take `O(17)` time
and `O(17)` auxiliary words. The primary reference uses this interval
recurrence. The independent reference enumerates every legal 17-bit mask,
decodes each by direct signed-weight summation, and indexes the unique code;
it does not use interval selection.

This differs from [`fibonacci_integer_code`](../fibonacci_integer_code/README.md),
which encodes only nonnegative integers as ordinary Zeckendorf bits for
`value+1`, followed by a sentinel. Here signed values use alternating
negative-index weights and nonadjacency supplies the unique finite form.

## Workload and files

[`workload.json`](workload.json) covers zero, both signs, short canonical
examples, both endpoints, malformed length/range, and insufficient output
capacity. References are [`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py). The package-local
[`check_inventory.py`](check_inventory.py) checks only required artifact
presence and is provided for later integration; it has not been run.

## Implementations

| Language | Source |
|---|---|
| C | [`c/n/negafibonacci_representation.c`](../../../c/n/negafibonacci_representation.c) |
| C3 | [`c3/n/negafibonacci_representation.c3`](../../../c3/n/negafibonacci_representation.c3) |
| C++ | [`cpp/n/negafibonacci_representation.cpp`](../../../cpp/n/negafibonacci_representation.cpp) |
| Elisa | [`elisa/n/negafibonacci_representation.elisa`](../../../elisa/n/negafibonacci_representation.elisa) |
| Mojo | [`mojo/n/negafibonacci_representation.mojo`](../../../mojo/n/negafibonacci_representation.mojo) |
| Nim | [`nim/n/negafibonacci_representation.nim`](../../../nim/n/negafibonacci_representation.nim) |
| Odin | [`odin/n/negafibonacci_representation.odin`](../../../odin/n/negafibonacci_representation.odin) |
| Rust | [`rust/n/negafibonacci_representation.rs`](../../../rust/n/negafibonacci_representation.rs) |
| V | [`v/n/negafibonacci_representation.v`](../../../v/n/negafibonacci_representation.v) |
| Zig | [`zig/n/negafibonacci_representation.zig`](../../../zig/n/negafibonacci_representation.zig) |

## Sources

M. W. Bunder, “Zeckendorf Representations Using Negative Fibonacci Numbers,”
*The Fibonacci Quarterly* 30(2), 1992, pp. 111–115,
[paper](https://www.mathstat.dal.ca/FQ/Scanned/30-2/bunder.pdf). Bunder proves
existence and uniqueness for nonconsecutive negative-index Fibonacci terms
and gives a constructive algorithm. The package specifies its bounded
interval-selection profile directly and does not reproduce the paper's text
or code. [OEIS A215022](https://oeis.org/A215022) records the bit orientation
and independently published small representation values. The Codewars title
is a discovery lead only; no task text, examples, tests, or submissions are
used.

See [RIGHTS.md](RIGHTS.md) for provenance and reuse boundaries.

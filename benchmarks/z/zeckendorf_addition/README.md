# Zeckendorf vector addition

This profile adds two canonical Zeckendorf bit vectors directly, without
decoding them to ordinary integers. It is a different operation from
[`fibonacci_integer_code`](../fibonacci_integer_code/README.md), which encodes
each integer input independently and appends a self-delimiting sentinel.

## Contract

The exported function is `zeckendorf_addition` in the
`i64_array_bytes_output` ABI family. Its input is
`[len_a, bits_a..., len_b, bits_b...]`. Each length is 1 through 64. Bits are
listed from highest Fibonacci weight to lowest. For a vector of length `m`,
bit `i` has weight `F_(m-1-i)`, where this package uses `F0=1`, `F1=2`, and
`Fk=F(k-1)+F(k-2)`. A nonzero vector starts with `1`, contains only `0` and
`1`, and has no adjacent `1` bits. Zero has the one-bit vector `0`; low-weight
trailing zeroes are allowed.

Output is the canonical high-weight-first ASCII bit vector for the sum, with
leading zeroes removed. Zero is output as `0`. Invalid frames or noncanonical
operands return `-1`. A null output or insufficient capacity returns `-2`;
errors write no bytes. The maximum valid frame is 130 signed 64-bit words; 131
words are parseable so an extra trailing word can be rejected safely. The
result has at most 66 bytes. The workspace cap is 256 bytes and covers one
66-byte working digit vector and scalar/index temporaries; input and caller
output buffers are excluded.

No truncation is performed: oversized vectors, malformed framing, and
noncanonical operands return `-1`. Only high-weight leading zeroes are removed
from the result; low-weight trailing zeroes in inputs retain their ordinary
meaning. A 64-bit operand is at most `F64-1 = 27,777,890,035,287`, so the sum
is at most `55,555,780,070,574`, below `2^46`. The native normalization never
accumulates that value; it updates only digits in the bounded alphabet 0..3.

## Three-pass method

The two vectors are right-aligned and added digit by digit, producing digits
in `{0,1,2}`. Since each operand is canonical, any `2` in this sum is
isolated. A leading zero is added and one left-to-right pass uses a four-digit
window. With `x` equal to 0, 1, or 2, the rewrites are:

| Window | Replacement |
|---|---|
| `020x` | `100(x+1)` |
| `030x` | `110(x+1)` |
| `021x` | `110x` |
| `012x` | `101x` |

The final one to three digits use the finite-boundary cleanup from the paper:
`030→111`, `020→101`, `0120→1010`, `03→11`, `02→10`, and `012→101` when
their stated suffix pattern is present. This profile also closes the terminal
case `021→110`, the three-digit restriction of the paper's `021x→110x` rule
when there is no fourth stored digit. This value-preserving finite-width
closure is needed for `6+7`; the paper's listed suffix cases omit it. The
cleanup leaves a binary intermediate string. Before the second stage, another
high-order zero is retained so a carry can expand beyond the intermediate
width. A right-to-left pass and then a left-to-right pass apply `011→100`.
Leading zeroes are stripped at the end.

The extra stage-two sentinel matters for `4+4`: `101 + 101` becomes
`1011` after stage one; with the sentinel, `01011` normalizes to `10000`.
The terminal closure matters for `6+7`: the paper's four-digit pass leaves
`10021`, the finite-width rule changes the suffix `021` to `110`, and stage
two normalizes the sentinel-prefixed `010110` to `100000`.
For maximum input width `L`, each operand is less than `F_L` under the
package indexing, and `2*F_L` is less than `F_(L+2)`, so the sum fits in
`L+2` canonical positions.
Each of the three rewrite passes scans a linear number of positions, so the
profile takes `O(L)` time and `O(L)` working space.

The primary reference implements the three passes. The independent reference
decodes each input by a Fibonacci-weight sum, adds the resulting integers,
then uses greedy largest-weight selection to encode the answer. This provides
a separate way to check the same bounded contract.

## Sources and implementation files

The pinned [RosettaCodeData popular-task index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
supplied the discovery title “Zeckendorf arithmetic” only. The normalization details follow Connor
Ahlbach, Jeremy Usatine, Christiane Frougny, and Nicholas Pippenger,
“Efficient Algorithms for Zeckendorf Arithmetic,” *The Fibonacci Quarterly*
51(3), 2013, 248–254, [paper PDF](https://www.fq.math.ca/Papers1/51-3/AhlbachUsatineFrougnyPippenger.pdf),
[DOI](https://doi.org/10.1080/00150517.2013.12427944). See [RIGHTS.md](RIGHTS.md)
for provenance and reuse boundaries.

| Language | Source |
|---|---|
| C | [`c/z/zeckendorf_addition.c`](../../../c/z/zeckendorf_addition.c) |
| C3 | [`c3/z/zeckendorf_addition.c3`](../../../c3/z/zeckendorf_addition.c3) |
| C++ | [`cpp/z/zeckendorf_addition.cpp`](../../../cpp/z/zeckendorf_addition.cpp) |
| Elisa | [`elisa/z/zeckendorf_addition.elisa`](../../../elisa/z/zeckendorf_addition.elisa) |
| Mojo | [`mojo/z/zeckendorf_addition.mojo`](../../../mojo/z/zeckendorf_addition.mojo) |
| Nim | [`nim/z/zeckendorf_addition.nim`](../../../nim/z/zeckendorf_addition.nim) |
| Odin | [`odin/z/zeckendorf_addition.odin`](../../../odin/z/zeckendorf_addition.odin) |
| Rust | [`rust/z/zeckendorf_addition.rs`](../../../rust/z/zeckendorf_addition.rs) |
| V | [`v/z/zeckendorf_addition.v`](../../../v/z/zeckendorf_addition.v) |
| Zig | [`zig/z/zeckendorf_addition.zig`](../../../zig/z/zeckendorf_addition.zig) |

The fixtures in [`workload.json`](workload.json) include the two-position
expansion edge case, unequal operand widths, the maximum 130-word valid frame,
a 131-word trailing-frame rejection, null input/output, malformed-input
precedence over a null output, invalid canonical forms and framing, and
output-capacity failure. The references are
[`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py). Static inventory artifacts
are [`INVENTORY.md`](INVENTORY.md), [`INVENTORY.json`](INVENTORY.json), and
[`check_inventory.py`](check_inventory.py); none has been executed.

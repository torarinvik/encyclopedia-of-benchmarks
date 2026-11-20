# Knuth Algorithm D big-integer division

This profile divides canonical unsigned decimal integers with normalized
base-1,000,000,000 limbs. It uses the operation in Library Checker’s
[`division_of_big_integers`](https://github.com/yosupo06/library-checker-problems/blob/master/big_integer/division_of_big_integers/task.md)
task and the quotient-limb method described as Knuth’s Algorithm D in the
[FLINT integer-division notes](https://fredrikj.net/fdoc/html/algorithms/integers/division.html).
The ports are clean-room implementations; no upstream source code, problem
prose, tests, or fixtures are copied.

## Contract

Input is an i64 array `[len_a, len_b, ascii_a..., ascii_b...]`. Each length is
1 through 64, the packed input contains exactly `2 + len_a + len_b` values,
and each operand is canonical unsigned ASCII decimal. The dividend may be
zero; the divisor must be positive. A multi-digit operand cannot start with
zero. Invalid input returns `-1`.

On success, the output is the canonical decimal quotient, a colon, and the
canonical decimal remainder, with no NUL terminator. The returned value is the
number of output bytes. A null or undersized output returns `-2` without
writing output. Input is at most 130 i64 values and output is at most 129
bytes. The fixed local profile is intentionally small; the official task has
much larger operand limits.
The declared fixed workspace is 521 bytes across the four limb arrays,
normalized dividend and divisor storage, and staged output.

## Algorithm

Decimal input is accumulated into little-endian base-1,000,000,000 limbs. For
multi-limb divisors, the divisor is scaled so its top limb is large enough for
the quotient estimate to be bounded. Each quotient limb is estimated from the
top dividend limbs, refined against the next divisor limb, then applied by
multiply-subtract. If subtraction goes negative, the estimate is reduced and
the divisor is added back. The remainder is divided by the normalization
factor. One-limb divisors use a high-to-low single-limb pass. The multi-limb
division work is quadratic in the limb count. The current digit-by-digit
decimal-to-limb parser updates every existing limb for each input digit, so
parsing is quadratic in the digit count; serialization is linear. Auxiliary
storage is fixed by the eight-limb cap.

This is a different computational kernel from the existing
[`long_division`](../../l/long_division/README.md), which accepts only bounded
machine integers and obtains each decimal quotient digit by repeated
subtraction. Arbitrary-precision size and returning the remainder are useful
contract extensions, but the reason for this profile is the normalized
multi-limb quotient-estimation algorithm.

## References and artifacts

- Primary reference: [`primary_oracle.py`](primary_oracle.py), an independent
  Python implementation of the base-limb Algorithm D steps.
- Independent reference: [`benchmarks/knuth_big_integer_division_oracle.py`](../../knuth_big_integer_division_oracle.py),
  which uses Python’s built-in arbitrary-precision `divmod`.
- Deterministic fixtures and bounded workload: [`workload.json`](workload.json).
- Attribution and clean-room note: [`RIGHTS.md`](RIGHTS.md).
- Static source inventory: [`INVENTORY.md`](INVENTORY.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/k/knuth_big_integer_division.c`](../../../c/k/knuth_big_integer_division.c) |
| C3 | [`c3/k/knuth_big_integer_division.c3`](../../../c3/k/knuth_big_integer_division.c3) |
| C++ | [`cpp/k/knuth_big_integer_division.cpp`](../../../cpp/k/knuth_big_integer_division.cpp) |
| Elisa | [`elisa/k/knuth_big_integer_division.elisa`](../../../elisa/k/knuth_big_integer_division.elisa) |
| Mojo | [`mojo/k/knuth_big_integer_division.mojo`](../../../mojo/k/knuth_big_integer_division.mojo) |
| Nim | [`nim/k/knuth_big_integer_division.nim`](../../../nim/k/knuth_big_integer_division.nim) |
| Odin | [`odin/k/knuth_big_integer_division.odin`](../../../odin/k/knuth_big_integer_division.odin) |
| Rust | [`rust/k/knuth_big_integer_division.rs`](../../../rust/k/knuth_big_integer_division.rs) |
| V | [`v/k/knuth_big_integer_division.v`](../../../v/k/knuth_big_integer_division.v) |
| Zig | [`zig/k/knuth_big_integer_division.zig`](../../../zig/k/knuth_big_integer_division.zig) |

The `i64_array_bytes_output` runner and verifier register the symbol, workload,
primary Algorithm D reference, independent `divmod` oracle, and fixtures. The
package-local static verifier checks workload bounds, source inventory, and
fixture agreement without launching language ports.

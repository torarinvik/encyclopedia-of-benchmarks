# Signed decimal big integer addition

This package adds two signed, arbitrary-length decimal integers represented as
canonical ASCII byte strings. The operation compares magnitudes and then uses a
right-to-left carry pass for equal signs or a borrow pass for opposite signs.
No machine integer is used to hold an operand.

The profile fills a local gap: [`binary_addition`](../../b/binary_addition/README.md)
adds unsigned binary strings, [`big_integer_multiply`](../../b/big_integer_multiply/README.md)
multiplies unsigned decimal strings, and [`long_division`](../../l/long_division/README.md)
divides bounded scalar values. None implements signed decimal addition with
magnitude comparison and cancellation.

## Bounded contract

The `i64_array_bytes_output` entry point is
`addition_of_big_integers(input, length, output, capacity)`. Input is packed as
`[len_a, len_b, ascii_a..., ascii_b...]`. Each operand has 1 to 33 bytes and at
most 32 decimal digits. It is canonical signed decimal: an optional leading
minus is allowed; a plus sign, leading zeroes, and negative zero are invalid;
zero is exactly `0`. Input length must equal `2 + len_a + len_b`.

Success writes the canonical sum as ASCII bytes without a NUL terminator and
returns the byte count. The maximum output is 34 bytes, covering a minus sign
and a 33-digit magnitude. Invalid input returns `-1`; a null output or capacity
smaller than the result returns `-2`. Errors leave output unchanged. The input
is capped at 68 signed 64-bit values.

The primary oracle performs decimal digit-array addition and subtraction. The
independent oracle validates the text separately, converts operands to Python
integers, and uses native arbitrary-precision addition. `workload.json`
contains signed, carry, borrow, cancellation, maximum-width, invalid-input,
null-buffer, and capacity fixtures. `verify_workload.py` statically checks the
fixture contract and cross-checks both oracles; it does not launch benchmark
ports.

## Provenance and rights

The operation was discovered in Library Checker's [Addition of Big Integers
task](https://github.com/yosupo06/library-checker-problems/blob/master/big_integer/addition_of_big_integers/task.md)
and its [parameter file](https://github.com/yosupo06/library-checker-problems/blob/master/big_integer/addition_of_big_integers/info.toml).
Those files specify integer addition and official size limits. This project
uses the task metadata for discovery and defines a separate bounded byte ABI.
Implementations, oracles, and fixtures here are independently written; no
upstream implementation, test data, or task prose is reused. The upstream
repository is Apache-2.0; see [`RIGHTS.md`](RIGHTS.md).

## Implementations

| Language | Source |
|---|---|
| C | [`c/a/addition_of_big_integers.c`](../../../c/a/addition_of_big_integers.c) |
| C3 | [`c3/a/addition_of_big_integers.c3`](../../../c3/a/addition_of_big_integers.c3) |
| C++ | [`cpp/a/addition_of_big_integers.cpp`](../../../cpp/a/addition_of_big_integers.cpp) |
| Elisa | [`elisa/a/addition_of_big_integers.elisa`](../../../elisa/a/addition_of_big_integers.elisa) |
| Mojo | [`mojo/a/addition_of_big_integers.mojo`](../../../mojo/a/addition_of_big_integers.mojo) |
| Nim | [`nim/a/addition_of_big_integers.nim`](../../../nim/a/addition_of_big_integers.nim) |
| Odin | [`odin/a/addition_of_big_integers.odin`](../../../odin/a/addition_of_big_integers.odin) |
| Rust | [`rust/a/addition_of_big_integers.rs`](../../../rust/a/addition_of_big_integers.rs) |
| V | [`v/a/addition_of_big_integers.v`](../../../v/a/addition_of_big_integers.v) |
| Zig | [`zig/a/addition_of_big_integers.zig`](../../../zig/a/addition_of_big_integers.zig) |

Shared suite imports, oracle maps, bounds, and byte-output corpus registration
are owned by the repository integrator.

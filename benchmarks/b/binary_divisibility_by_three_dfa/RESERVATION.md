# Reservation: streaming binary divisibility-by-three DFA

**Status:** Confirmed distinct candidate; ten clean-room ports and local
package artifacts are complete, and central suite integration is in place.
No package checks, programs, builds, compilers, tests, or benchmarks have been
run.

## Exact contract

Use `i64_array_bytes_output`. Input is `[L, bit_0, ..., bit_(L-1)]`, with
`1 <= L <= 4096`, MSB-first order, and every bit in `{0,1}`. Leading zeroes are
allowed and included in `L`. Valid calls emit one byte, `1` iff the represented
value is divisible by three and `0` otherwise, then return `1`. Null input,
malformed framing, an out-of-range `L`, or an invalid bit returns `-1` before
output checks. Null output or capacity below one returns `-2`; errors do not
write output. Maximum valid input length is 4097 words and maximum parseable
length is 4098 words. The workload declares one 64-byte auxiliary-workspace
cap, excluding input and output buffers.

## Methods and distinctness

Primary method: maintain `r` in `{0,1,2}`, initialized to zero, and update
`r=(2*r+bit) mod 3` for each input bit. Accept iff the final remainder is zero.
This takes `O(L)` time and constant auxiliary state.

Independent reference: use the alternating-sign bit sum because
`2 == -1 (mod 3)`. For an MSB-first stream of length `L`, sum bit `i` with sign
`(-1)^(L-1-i)` and test whether the result is zero modulo three.

`binary_to_decimal` materializes the represented integer and is locally bounded
to 63 bits by signed-i64 output. This profile scans up to 4096 bits in fixed
state. `is_divisible` consumes two numeric scalar operands and uses integer
remainder; it does not evaluate a binary stream. The input representation,
state space, and long-stream bound make this a distinct benchmark workload.

## Provenance and rights

The title/tag discovery lead was the public Codewars listing entry “Binary
multiple of 3.” Its listing was used only to discover the algorithm; no task
text, example, tests, submission, or code was read or reused. Method context is
Cornell CS 4810 lecture notes:
https://www.cs.cornell.edu/kozen/Papers/481.pdf . Ports, references, fixture
contract, and package documentation are clean-room.

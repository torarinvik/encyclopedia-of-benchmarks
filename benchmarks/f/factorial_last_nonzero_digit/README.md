# Last nonzero decimal digit of a factorial

Return the final nonzero decimal digit of `n!`. This computes one decimal digit,
not the number of trailing zeroes and not the full factorial.

## Contract

- The `i64_array_scalar` input is exactly `[n]`, with `0 <= n <= INT64_MAX`.
- Return the last nonzero decimal digit of `n!`; `0!` is defined as `1`.
- Invalid, null, empty, or trailing-word input returns `-1`.
- The output is in `0..9` for every valid input.

## Methods

The primary iteratively applies
`D(n) = D(floor(n/5)) * D(n mod 5) * 2^floor(n/5) mod 10`, starting with
`D(0..4) = 1, 1, 2, 6, 4`. At each step, division by five shortens the input;
the power of two only depends on the quotient modulo four. This takes
`O(log_5(n+1))` time and `O(1)` extra space.

The independent reference uses the base-five digit product. If
`n = sum_i a_i*5^i` and `n >= 2`, it returns
`6 * product_i(a_i! * 2^(i*a_i)) mod 10`; `n=0` and `n=1` both return 1.
This follows a different calculation from the iterative quotient recurrence.

## Sources and provenance

The public [Codewars title listing](https://www.codewars.com/kata?tags=Algorithms%2CNumber+Theory)
was used only to discover the candidate. The method is independently grounded
in Gregory P. Dresden, [“Three Transcendental Numbers From the Last Non-Zero
Digits of n^n, F_n, and n!”](https://dresden.academic.wlu.edu/files/2017/08/lnzd2.pdf),
and [OEIS A008904](https://oeis.org/A008904). No Codewars problem text, code,
examples, tests, submissions, or fixtures are used. The implementations and
workload are clean-room work based on the mathematical formulas.

See [`RIGHTS.md`](RIGHTS.md) for provenance and [`workload.json`](workload.json)
for bounded valid and invalid fixtures. [`verify_workload.py`](verify_workload.py)
is a static package validator and has not been run.

## Language ports

| Language | Source |
|---|---|
| C | [`c/f/factorial_last_nonzero_digit.c`](../../../c/f/factorial_last_nonzero_digit.c) |
| C3 | [`c3/f/factorial_last_nonzero_digit.c3`](../../../c3/f/factorial_last_nonzero_digit.c3) |
| C++ | [`cpp/f/factorial_last_nonzero_digit.cpp`](../../../cpp/f/factorial_last_nonzero_digit.cpp) |
| Elisa | [`elisa/f/factorial_last_nonzero_digit.elisa`](../../../elisa/f/factorial_last_nonzero_digit.elisa) |
| Mojo | [`mojo/f/factorial_last_nonzero_digit.mojo`](../../../mojo/f/factorial_last_nonzero_digit.mojo) |
| Nim | [`nim/f/factorial_last_nonzero_digit.nim`](../../../nim/f/factorial_last_nonzero_digit.nim) |
| Odin | [`odin/f/factorial_last_nonzero_digit.odin`](../../../odin/f/factorial_last_nonzero_digit.odin) |
| Rust | [`rust/f/factorial_last_nonzero_digit.rs`](../../../rust/f/factorial_last_nonzero_digit.rs) |
| V | [`v/f/factorial_last_nonzero_digit.v`](../../../v/f/factorial_last_nonzero_digit.v) |
| Zig | [`zig/f/factorial_last_nonzero_digit.zig`](../../../zig/f/factorial_last_nonzero_digit.zig) |

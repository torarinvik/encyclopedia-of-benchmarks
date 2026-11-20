# Carmichael lambda function

This package computes Carmichael's function `lambda(n)`, the exponent of the
unit group modulo `n`: the least positive integer `e` such that
`a^e = 1 (mod n)` for every residue `a` coprime to `n`. It is separate from
[`euler_totient`](../../e/euler_totient/README.md), which counts those units,
and from [`carmichael_number`](../carmichael_number/README.md), which tests a
composite-number property. The name explicitly means the Carmichael function;
it is unrelated to the Liouville function, which is also sometimes denoted by
the Greek letter lambda.

## Contract

- ABI: `i64_array_scalar`; symbol: `carmichael_lambda_function`.
- Input `[n]`, with `1<=n<=1024`, exact length one. The maximum valid and
  parseable lengths are one and two words.
- Return `lambda(n)` in `1..1023`. Null, malformed, or out-of-range input
  returns `-1`.
- The convention is `lambda(1)=1`; in particular, `lambda(2)=1`,
  `lambda(4)=2`, and `lambda(2^k)=2^(k-2)` for `k>=3`.

## Algorithm and independent reference

The primary factors `n` by trial division. For each odd prime power `p^a`, it
uses `lambda(p^a)=p^(a-1)(p-1)`. For powers of two it uses the values above.
It combines the prime-power results by least common multiple. The primary
takes `O(sqrt(n))` trial divisions and `O(1)` auxiliary space.

The independent reference enumerates all units modulo `n`, finds each unit's
multiplicative order by repeated multiplication, and takes the LCM of those
orders. This follows the group-exponent definition directly instead of using
prime-power formulas. Its worst-case work is `O(n^2)` modular multiplications;
the bound `n<=1024` caps this direct reference at roughly one million steps.

The factorization and prime-power rules follow Theorem 22 in Richard A.
Wilson's [Queen Mary University cryptography notes](https://webspace.maths.qmul.ac.uk/r.a.wilson/MAS335/cn7.pdf).
The definition and values including `lambda(1)` are also summarized by
[Wolfram MathWorld](https://mathworld.wolfram.com/CarmichaelFunction.html).
The package uses the mathematical rules only; all code, fixtures, and prose
are clean-room.

See [`workload.json`](workload.json), [`primary_oracle.py`](primary_oracle.py),
[`independent_oracle.py`](independent_oracle.py),
[`check_inventory.py`](check_inventory.py), and [`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [carmichael_lambda_function.c](../../../c/c/carmichael_lambda_function.c) |
| C3 | [carmichael_lambda_function.c3](../../../c3/c/carmichael_lambda_function.c3) |
| C++ | [carmichael_lambda_function.cpp](../../../cpp/c/carmichael_lambda_function.cpp) |
| Elisa | [carmichael_lambda_function.elisa](../../../elisa/c/carmichael_lambda_function.elisa) |
| Mojo | [carmichael_lambda_function.mojo](../../../mojo/c/carmichael_lambda_function.mojo) |
| Nim | [carmichael_lambda_function.nim](../../../nim/c/carmichael_lambda_function.nim) |
| Odin | [carmichael_lambda_function.odin](../../../odin/c/carmichael_lambda_function.odin) |
| Rust | [carmichael_lambda_function.rs](../../../rust/c/carmichael_lambda_function.rs) |
| V | [carmichael_lambda_function.v](../../../v/c/carmichael_lambda_function.v) |
| Zig | [carmichael_lambda_function.zig](../../../zig/c/carmichael_lambda_function.zig) |

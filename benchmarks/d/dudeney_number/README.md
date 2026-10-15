# Dudeney number

A positive integer is Dudeney when its cube root equals the sum of its decimal digits. The benchmark uses an exact integer cube-root search followed by a decimal digit sum.

## Contract

- Uses the signed 64-bit scalar ABI: `int64_t dudeney_number(int64_t input)`.
- Valid inputs are `1..=2,147,483,647`, matching the positive Java `int` domain.
- Return `1` when the input is a perfect cube and its integer cube root equals its decimal digit sum; otherwise return `0`.
- Inputs outside the valid range return `-1`. The source throws for nonpositive inputs; the shared ABI represents that invalid input with `-1`.

## Source semantics

The benchmark follows the pinned [TheAlgorithms Java `DudeneyNumber`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/DudeneyNumber.java). The source estimates the cube root with `Math.round(Math.pow(n, 1.0 / 3.0))`, checks that the rounded value cubes exactly to `n`, then compares it with the decimal digit sum. The ports use an integer binary search for the exact cube root; on the bounded positive `int` domain this performs the same perfect-cube and digit-sum test without relying on floating-point rounding. Nonpositive source inputs throw `IllegalArgumentException`; the shared scalar contract maps them to `-1`.

## Workload and build

[`workload.json`](workload.json) covers known Dudeney numbers, perfect cubes that are not Dudeney, non-cubes, the signed `int` upper boundary, and invalid inputs. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_scalar.py --algorithm dudeney_number --language c
python3 benchmarks/run_scalar.py --algorithm dudeney_number
```

The nine implementations are in `c/d/dudeney_number.c`, `c3/d/dudeney_number.c3`, `cpp/d/dudeney_number.cpp`, `elisa/d/dudeney_number.elisa`, `nim/d/dudeney_number.nim`, `odin/d/dudeney_number.odin`, `rust/d/dudeney_number.rs`, `v/d/dudeney_number.v`, and `zig/d/dudeney_number.zig`.

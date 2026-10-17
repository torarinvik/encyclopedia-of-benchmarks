# Seeded Monte Carlo π estimation

This benchmark measures a deterministic, portable projection of the pinned
Python `estimate_pi` routine with an explicit seed. It counts points from the
unit square that fall in the quarter unit circle and returns one binary64
estimate.

## Contract

The `float64_slice_io` input is exactly `[number_of_simulations, seed]`. Both
values must be finite, exact binary64 integers. The simulation count is from 1
through 100,000; the seed is from 0 through 4,294,967,295 inclusive. The
wrapper converts each accepted value to an integer before calling the source,
so a missing seed and the Python function's unseeded default are outside this
workload.

For each call, initialize a fresh CPython-compatible MT19937 generator from
the integer seed. For this 32-bit seed domain, CPython splits the seed into one
little-endian 32-bit key word and initializes MT19937 with `init_by_array`;
seed zero is the one-word key `[0]`. `random()` consumes two tempered 32-bit
words: take the upper 27 bits of the first and upper 26 bits of the second,
combine them as `(a * 2^26 + b) / 2^53`, and return that binary64 value in
`[0,1)`. Each trial draws x first and y second. No global or operating-system
random state participates.

The pinned predicate is `x**2 + y**2 <= 1`, evaluated in that order with the
boundary included. This benchmark defines a canonical binary64 multiplication
projection of that predicate, `x*x + y*y <= 1.0`, with left-to-right addition.
It may differ from CPython's platform `pow` result for rare rounding-boundary
inputs; the selected fixed-seed fixtures were compared with the pinned
expression and have the same hit counts. C, C++, and Nim implementations must
disable floating-point contraction so the multiplication and addition round
separately; Nim passes this requirement to its C backend.
Let `hits` be the number of points satisfying the benchmark predicate; the
result is `4 * hits / number_of_simulations`, returned as one binary64 output
element. The contract uses zero absolute and relative tolerance.

Malformed, non-finite, fractional, out-of-range, null, or incorrectly sized
input returns -1. A null output pointer or capacity below one element returns
-2 after input validation and writes no output. A valid call returns 1 and
writes the estimate. The maximum valid input contains two binary64 elements;
the maximum parseable input contains three, allowing a trailing-value case.

## Pinned source

- TheAlgorithms/Python [`pi_monte_carlo_estimation.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/pi_monte_carlo_estimation.py), method `estimate_pi`, commit `e1a2a8b016001309a73d5fec4818c35cca139795`
- CPython 3.12.0's [MT19937 implementation](https://github.com/python/cpython/blob/v3.12.0/Modules/_randommodule.c) defines the integer seeding and 53-bit `random()` construction used by this contract.

## Workload

The workload is [`workload.json`](workload.json); the independent MT19937 and
Monte Carlo oracle is [`benchmarks/pi_monte_carlo_estimation_oracle.py`](../../pi_monte_carlo_estimation_oracle.py).

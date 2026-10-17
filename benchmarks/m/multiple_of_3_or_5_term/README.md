# Multiple of 3 or 5 term filter

This benchmark follows the one-term helper in the pinned MATLAB-Octave [`project-euler/Problem1/multiple.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/project-euler/Problem1/multiple.m). It returns a number when that number is divisible by 3 or 5 and returns zero otherwise. It does not sum a range of multiples.

## Contract

- Input is a signed 64-bit integer `n` in `0..=1,000,000,000`.
- Return `n` when `n % 3 == 0` or `n % 5 == 0`; otherwise return `0`.
- Inputs outside the domain return `-1`.
- Zero is in-domain and returns zero.

The benchmark uses the shared signed-integer `scalar_call` ABI. The source asserts that the input is nonnegative; the upper bound is the benchmark's domain. The independent oracle is [`multiple_of_3_or_5_term_oracle.py`](../../multiple_of_3_or_5_term_oracle.py).

## Workload and build

[`workload.json`](workload.json) covers zero, multiples of each divisor and their overlap, a nonmultiple, and both sides of the input domain.

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm multiple_of_3_or_5_term --language rust --with-checker
python3 benchmarks/run_scalar.py --build-manifest build/scalar/m/multiple_of_3_or_5_term/rust/build.json
python3 benchmarks/verify_scalar.py --algorithms multiple_of_3_or_5_term --languages rust
```

## Pinned source

- [MATLAB `multiple.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/project-euler/Problem1/multiple.m)


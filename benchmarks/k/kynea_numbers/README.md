# Kynea numbers

Computes the one-based Kynea number using the pinned Dart source's expression.

## Contract

- Uses the unary scalar ABI: `int64_t kynea_numbers(int64_t index)`.
- Indices in `[1, 31]` are accepted. Values outside that range return `-1`.
- For index `n`, first compute `value = (1 << n) + 1`, then `value * value`, then subtract two.
- The sequence begins `7, 23, 79, 287, 1087, 4223, ...`; `n=31` returns `4,611,686,022,722,355,199`, which fits signed 64-bit. The next value at `n=32` exceeds `INT64_MAX`.

## Source semantics

The benchmark follows pinned [TheAlgorithms Dart `Kynea_numbers.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/Kynea_numbers.dart). Its `nthKyneaNumber` function uses a one-based index and evaluates `(1 << n) + 1`, squares that value, and subtracts two. The benchmark preserves this operation order and returns `-1` outside the bounded signed-64-bit domain. Index 32 is excluded because its exact result does not fit signed 64-bit.

This indexed formula is distinct from the nearby power-of-two predicates and sequence benchmarks: it returns the Kynea number itself rather than testing whether an input is a power or generating a different sequence.

## Workload and build

[`workload.json`](workload.json) covers the first terms, larger indices, the largest valid index, and invalid inputs. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm kynea_numbers --language c
python3 benchmarks/run_scalar.py --build-manifest build/scalar/k/kynea_numbers/c/build.json
```

The nine implementations are in `c/k/kynea_numbers.c`, `c3/k/kynea_numbers.c3`, `cpp/k/kynea_numbers.cpp`, `elisa/k/kynea_numbers.elisa`, `nim/k/kynea_numbers.nim`, `odin/k/kynea_numbers.odin`, `rust/k/kynea_numbers.rs`, `v/k/kynea_numbers.v`, and `zig/k/kynea_numbers.zig`.

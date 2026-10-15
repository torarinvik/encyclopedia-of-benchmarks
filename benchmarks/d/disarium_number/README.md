# Disarium number

A Disarium number equals the sum of each decimal digit raised to its one-based position from the left. For example, `135 = 1¹ + 3² + 5³`.

## Contract

- Input is a signed 64-bit integer in `[1, 99,999,999]`. Zero, negative values, and values above the bound return `-1`.
- Return `1` when the sum of digit powers equals the input, and `0` otherwise.
- The bound matches the pinned Java source's positive `int` domain while keeping the largest possible sum, `8 × 9⁸`, within signed 32-bit range. Implementations extract digits from right to left while counting positions down from the digit count, which assigns the same one-based positions as a left-to-right scan.

The benchmark follows the pinned [TheAlgorithms Java source `DisariumNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/DisariumNumber.java). It rejects nonpositive inputs; the benchmark represents such invalid inputs with `-1` in the scalar ABI.

[`workload.json`](workload.json) covers known Disarium values, nearby nonmatches, the upper bound, and invalid inputs. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_scalar.py --algorithm disarium_number --language c
python3 benchmarks/run_scalar.py --algorithm disarium_number
```

Implementations: `c/d/disarium_number.c`, `c3/d/disarium_number.c3`, `cpp/d/disarium_number.cpp`, `elisa/d/disarium_number.elisa`, `nim/d/disarium_number.nim`, `odin/d/disarium_number.odin`, `rust/d/disarium_number.rs`, `v/d/disarium_number.v`, and `zig/d/disarium_number.zig`.

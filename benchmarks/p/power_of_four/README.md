# Power of four

Check whether an integer is a positive power of four. A valid value has one set bit, and that bit is at an even zero-based position.

## Contract

- Input is a signed 64-bit scalar in the signed 32-bit range.
- Return `1` for `4^k` with `k >= 0` and `0` for other in-range integers.
- Values outside the signed 32-bit range return `-1`.
- Zero and negative values return zero.

The implementation uses portable integer masks and bit operations. It does not depend on machine-specific instructions.

## Workload and verification

[`workload.json`](workload.json) covers zero, negative values, powers of four through the maximum signed-32-bit power, other powers of two, nearby values, and out-of-range inputs. [`verify_scalar.py`](../../verify_scalar.py) includes the algorithm in its scalar oracle and boundary/random corpus across all nine languages.

```sh
python3 benchmarks/verify_scalar.py --algorithms power_of_four --elisa-compiler /absolute/path/to/elisac
```

Build and record with the `scalar` ABI family. Sources are under `p/` in `c/`, `c3/`, `cpp/`, `elisa/`, `nim/`, `odin/`, `rust/`, `v/`, and `zig/`.

## Reviewed TheAlgorithms source

- [Java `PowerOfFour.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PowerOfFour.java) checks for one set bit and then uses the `0x55555555` mask to require an even bit position.

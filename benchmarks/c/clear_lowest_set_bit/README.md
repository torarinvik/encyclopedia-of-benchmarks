# Clear lowest set bit

Clears the least significant one bit of a nonnegative 32-bit integer.

## Contract

- Uses the unary scalar ABI: `int64_t clear_lowest_set_bit(int64_t value)`.
- Inputs in `[0, 2,147,483,647]` are accepted. Values outside that range return `-1`.
- Returns `value & (value - 1)`; zero returns zero.
- Results stay in the input range and fit signed 64-bit.

## Source semantics

The pinned Java `LowestSetBit.clearLowestSetBit(int)` method clears only the
least significant set bit. It is distinct from `lowest_set_bit`, which
isolates and returns that bit, and `clear_leftmost_set_bit`, which clears the
highest set bit. This benchmark uses the Java method's nonnegative int32
domain; negative and wider scalar ABI inputs map to `-1`.

Source: [Java `LowestSetBit.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/LowestSetBit.java).

## Workload and build

[`workload.json`](workload.json) covers zero, single-bit and mixed-bit
values, the int32 maximum, and invalid inputs. Build and record with the scalar
ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm clear_lowest_set_bit --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/c/clear_lowest_set_bit/rust/build.json
```

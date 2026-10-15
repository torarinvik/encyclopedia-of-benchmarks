# Rotate Left 32

Circularly rotate an unsigned 32-bit word to the left.

## Contract

- The binary scalar input is `[value, shift]`. `value` is in `[0, 4,294,967,295]`; `shift` is in `[0, 2,147,483,647]`.
- Normalize the shift modulo 32 and rotate the 32-bit word left. Return the result as an unsigned numeric value in `[0, 4,294,967,295]`.
- Invalid inputs return `-1`, which is outside the result range.
- Runtime and auxiliary space are both `O(1)`.

The benchmark follows Java `BitRotate.rotateLeft` and Python `rotate_left32`. Java returns a signed `int`; the benchmark interprets those same 32 result bits as an unsigned value so the operation has one portable result representation. Python's helper masks to the low 32 input bits; the bounded input is the shared domain. Both sources require a nonnegative shift and normalize it modulo 32.

Build and record with the existing `binary_scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm rotate_left32 --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/r/rotate_left32/rust/build.json
```

## Pinned sources

- [Java `BitRotate.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/BitRotate.java)
- [Python `rotate_bits.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/rotate_bits.py)

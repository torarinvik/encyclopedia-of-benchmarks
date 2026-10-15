# Any-to-any base conversion

Convert a decimal-encoded number from one base to another, using the divide-and-remainder method in the pinned Java source. The shared `i64_array_scalar` ABI takes `[source_number, source_base, destination_base]` and returns the destination digits encoded as a base-10 integer.

## Contract

- `source_number` is from 0 through 999,999,999. Its decimal digits represent the input number; for example, `1101` with base 2 means binary 1101.
- Both bases are from 2 through 10. Every source digit must be less than the source base.
- The converted result is also returned as a decimal-encoded integer and must be at most 999,999,999. Conversions whose encoded output needs more than nine digits return `-1`.
- Input must contain exactly three signed 64-bit values. Invalid input returns `-1`.
- Zero converts to zero.

These bounds keep the intermediate operations within the Java source's signed 32-bit range while rejecting invalid base digits and unrepresentable encoded outputs.

## Reference source

- [TheAlgorithms Java `AnytoAny.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/AnytoAny.java)

`workload.json` covers conversions between several bases, zero, invalid digits and bases, malformed lengths, and an output that exceeds the decimal-encoding bound.

Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm anyto_any --language LANGUAGE
python3 benchmarks/run_i64_array_scalar.py --algorithm anyto_any
```

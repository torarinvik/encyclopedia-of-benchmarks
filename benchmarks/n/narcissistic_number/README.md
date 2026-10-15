# Narcissistic Number Enumeration

Find all narcissistic numbers below an exclusive upper limit. A number is included when it equals the sum of each decimal digit raised to the number of digits. Results are returned in ascending order; zero is included for every positive limit.

## Contract

- A nonpositive limit returns an empty list.
- Limits from 1 through 100,000 enumerate values in `[0, limit)`. Larger limits return `-1`.
- The output buffer contains each result as an 8-byte big-endian signed integer, with no terminator. The return value is the number of bytes written.
- If the output buffer is too small, return `-2` before writing. The contract's maximum result fits in the 256-byte shared ABI buffer.
- The ports memoize digit powers while scanning the candidate range; the cache is local to each call.

## Source

The pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/narcissistic_number.py) enumerates the exclusive range and memoizes digit powers. The portable C ABI uses a bounded limit and explicit byte order for its result list.

Build and record with the shared scalar byte-output ABI:

```sh
python3 benchmarks/build_abi.py --family i64_scalar_bytes_output --algorithm narcissistic_number --language rust
python3 benchmarks/run_i64_scalar_bytes_output.py --build-manifest build/i64_scalar_bytes_output/n/narcissistic_number/rust/build.json
```

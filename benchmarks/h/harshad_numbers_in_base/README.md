# Harshad numbers in a base

This benchmark preserves the pinned [TheAlgorithms/Python enumeration](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/harshad_numbers.py). Given a limit and base, it returns every positive integer below the limit that is divisible by the sum of its digits in that base.

## Contract

- Input is `[limit, base]` as signed 64-bit integers. The base must be 2 through 36, and the benchmark bounds the limit above by 10,000.
- A negative limit and limits 0 or 1 produce an empty result, matching the source. Larger limits and invalid bases return `-1`.
- Results are returned as uppercase base strings, each followed by a NUL byte. The return value is the number of output bytes, including NUL separators. An insufficient output buffer returns `-2` before writing.
- The source validates the base before its negative-limit check. The packed ABI maps its invalid-base exception to `-1`.
- Each candidate number is checked by summing its base digits and testing divisibility. Runtime is O(limit log limit); auxiliary space is O(log limit) for converting each selected value.

The enumeration uses the same digit-sum predicate as `is_harshad_number_in_base`, but returns the entire ascending list below the limit. It is separate from a single-number predicate. The output encoding makes the source's list of uppercase strings observable through the shared `i64_array_bytes_output` ABI.

## Workload and build

[`workload.json`](workload.json) covers source examples, negative and empty limits, a bounded upper-limit case, and invalid bases and lengths. The runner oracle compares the exact NUL-delimited bytes.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm harshad_numbers_in_base --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/h/harshad_numbers_in_base/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/h/harshad_numbers_in_base.c`](../../../c/h/harshad_numbers_in_base.c) |
| C3 | [`c3/h/harshad_numbers_in_base.c3`](../../../c3/h/harshad_numbers_in_base.c3) |
| C++ | [`cpp/h/harshad_numbers_in_base.cpp`](../../../cpp/h/harshad_numbers_in_base.cpp) |
| Elisa | [`elisa/h/harshad_numbers_in_base.elisa`](../../../elisa/h/harshad_numbers_in_base.elisa) |
| Nim | [`nim/h/harshad_numbers_in_base.nim`](../../../nim/h/harshad_numbers_in_base.nim) |
| Odin | [`odin/h/harshad_numbers_in_base.odin`](../../../odin/h/harshad_numbers_in_base.odin) |
| Rust | [`rust/h/harshad_numbers_in_base.rs`](../../../rust/h/harshad_numbers_in_base.rs) |
| V | [`v/h/harshad_numbers_in_base.v`](../../../v/h/harshad_numbers_in_base.v) |
| Zig | [`zig/h/harshad_numbers_in_base.zig`](../../../zig/h/harshad_numbers_in_base.zig) |

## Upstream source

- [TheAlgorithms/Python `harshad_numbers.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/harshad_numbers.py)

# Barcode validator

## Contract

This benchmark exposes the pinned Python module's numeric `get_check_digit` and `is_valid` functions through a packed input `[operation, barcode]`. Operation `0` returns the check digit; operation `1` returns validity as `1` or `0`. The number is a nonnegative signed 64-bit integer. Malformed arrays, unsupported selectors, and negative or out-of-range values return `-1`.

`get_check_digit` discards the final decimal digit, then scans the remaining digits from right to left, multiplying by 3, 1, 3, 1, and so on. It returns `(10 - (sum % 10)) % 10`. `is_valid` accepts exactly those numeric values whose decimal representation has 13 digits and whose last digit equals the computed check digit. The workload uses integers, as the source functions do; textual leading zeroes are lost when `get_barcode` parses its input to an integer, so they do not affect the length test.

The source's `get_check_digit` does not terminate for negative numbers because Python floor division keeps a negative value at `-1`; negative values are outside this shared contract. The credit-card validator candidates use different checksum rules and are not aliases for this 13-digit barcode check.

## Workload and recording

[`workload.json`](workload.json) includes the source examples, valid and invalid 13-digit codes, shorter values, zero, and invalid packed inputs. It uses the `i64_array_scalar` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm barcode_validator --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/b/barcode_validator/rust/build.json
```

The shared scalar-array recorder validates this oracle and records the nine ports with the workload cases.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/barcode_validator.c`](../../../c/b/barcode_validator.c) |
| C3 | [`c3/b/barcode_validator.c3`](../../../c3/b/barcode_validator.c3) |
| C++ | [`cpp/b/barcode_validator.cpp`](../../../cpp/b/barcode_validator.cpp) |
| Elisa | [`elisa/b/barcode_validator.elisa`](../../../elisa/b/barcode_validator.elisa) |
| Nim | [`nim/b/barcode_validator.nim`](../../../nim/b/barcode_validator.nim) |
| Odin | [`odin/b/barcode_validator.odin`](../../../odin/b/barcode_validator.odin) |
| Rust | [`rust/b/barcode_validator.rs`](../../../rust/b/barcode_validator.rs) |
| V | [`v/b/barcode_validator.v`](../../../v/b/barcode_validator.v) |
| Zig | [`zig/b/barcode_validator.zig`](../../../zig/b/barcode_validator.zig) |

## Pinned source

- Python [`barcode_validator.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/barcode_validator.py)

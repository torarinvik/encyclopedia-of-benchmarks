# Weight conversions

This benchmark captures the six formatted string results in the pinned Ruby
`conversions/weight_conversions.rb` source. It remains separate from
[`weight_conversion`](../weight_conversion/README.md), which implements a
different numeric conversion API with eleven units and factor tables.

## Contract

Input is a signed-i64 array `[operation, amount]`. The amount is an integer in
`[-1,000,000, 1,000,000]`; operation codes are:

| Code | Pinned Ruby method | Operation |
|---:|---|---|
| 0 | `kilogram_to_gram` | `amount * 1000` |
| 1 | `gram_to_kilogram` | `amount / 1000` |
| 2 | `pound_to_ounce` | `amount * 16` |
| 3 | `ounce_to_pound` | `amount / 16` |
| 4 | `kilogram_to_pound` | `(amount * 2.205).round(2)` |
| 5 | `pound_to_kilogram` | `(amount / 2.205).round(2)` |

The byte output is the exact ASCII string with a trailing NUL. Its returned
length excludes the terminator. Ruby integer division floors for negative
values, so the two division operations preserve that behavior. The rounded
float outputs keep Ruby's shortest two-decimal representation: integral
results include `.0`, one decimal digit stays one digit, and other results use
two digits. Malformed input returns `-1`; an output buffer shorter than the
string plus terminator returns `-2` without writing.

The pinned [Ruby source](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/conversions/weight_conversions.rb)
includes sample calls and error demonstrations. This benchmark normalizes
inputs to integers and models each conversion's returned string, not the
module's `puts` side effects.

All nine ports use the `i64_array_bytes_output` ABI. The workload covers all
six methods, source examples, negative division and rounding, amount limits,
malformed selectors and lengths, and an insufficient output buffer.
The fixed workspace is 64 bytes, including the NUL terminator.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/w/weight_conversions.c](../../../c/w/weight_conversions.c) |
| C3 | [c3/w/weight_conversions.c3](../../../c3/w/weight_conversions.c3) |
| C++ | [cpp/w/weight_conversions.cpp](../../../cpp/w/weight_conversions.cpp) |
| Elisa | [elisa/w/weight_conversions.elisa](../../../elisa/w/weight_conversions.elisa) |
| Nim | [nim/w/weight_conversions.nim](../../../nim/w/weight_conversions.nim) |
| Odin | [odin/w/weight_conversions.odin](../../../odin/w/weight_conversions.odin) |
| Rust | [rust/w/weight_conversions.rs](../../../rust/w/weight_conversions.rs) |
| V | [v/w/weight_conversions.v](../../../v/w/weight_conversions.v) |
| Zig | [zig/w/weight_conversions.zig](../../../zig/w/weight_conversions.zig) |

## Build and verification

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm weight_conversions --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/w/weight_conversions/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm weight_conversions --languages rust
```

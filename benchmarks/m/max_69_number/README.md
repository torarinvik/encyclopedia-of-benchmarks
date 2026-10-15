# Maximum 69 number

Changes the leftmost decimal digit `6` to `9` to maximize a positive number whose digits are all 6 or 9.

## Contract

- Uses the unary signed 64-bit scalar ABI.
- Accepted inputs are positive values through 999,999,999,999,999,999 whose decimal digits are only `6` and `9`.
- Returns the value with its first (most significant) `6` changed to `9`.
- The pinned Ruby method returns `nil` when no digit is `6`. The scalar ABI cannot return nil, so all-9 inputs map to `-1`. Inputs outside the stated domain also map to `-1`.
- The ports inspect decimal digits from most significant to least significant using powers of ten, which has the same first-6 replacement behavior as the source's string conversion and left-to-right character scan.

## Source semantics

This follows pinned [TheAlgorithms Ruby `max_69_number.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/max_69_number.rb). `max_number` converts the input to a string, splits it into characters, replaces the first `'6'` with `'9'`, then returns the joined number. It returns nil if the string contains no `'6'`. The source comment specifies positive inputs made only of digits 6 and 9; the benchmark makes that domain explicit and uses `-1` for invalid values and the source's nil result.

## Workload and build

[`workload.json`](workload.json) covers a one-digit input, first/middle/last replacement positions, all-9 inputs, and invalid values.

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm max_69_number --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/m/max_69_number/rust/build.json
```

The implementations are in `c/m/max_69_number.c`, `c3/m/max_69_number.c3`, `cpp/m/max_69_number.cpp`, `elisa/m/max_69_number.elisa`, `nim/m/max_69_number.nim`, `odin/m/max_69_number.odin`, `rust/m/max_69_number.rs`, `v/m/max_69_number.v`, and `zig/m/max_69_number.zig`.

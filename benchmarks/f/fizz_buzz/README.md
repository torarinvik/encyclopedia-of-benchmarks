# Fizz Buzz

Generate the classic Fizz Buzz token sequence for integers 1 through an inclusive upper bound. Multiples of three produce `Fizz`, multiples of five produce `Buzz`, and multiples of both produce `FizzBuzz`; other values are written in decimal.

## Contract

The `i64_scalar_bytes_output` ABI takes `n` in `[1, 512]` and writes the tokens for `1..=n` as ASCII, separated by one space and followed by a trailing space. The return value is the byte length. Invalid bounds return `-1`; a buffer shorter than the output returns `-2` without writing. Valid calls must provide output storage. The maximum bound keeps output below the runner’s byte limit.

The pinned Python function accepts a start and an inclusive end, defaults its documented example to start at one, and returns the sequence as a space-delimited string with a trailing space. The Ruby array and hash versions return the same token sequence as strings; the Dart source prints the fixed sequence from 1 through 100. The benchmark fixes the start at one and compares the shared token sequence as bytes.

## Workload and source

[`workload.json`](workload.json) covers ordinary numbers, each substitution, combined substitutions, the upper bound, and invalid values.

The shared scalar-bytes runner generates the inclusive sequence with its trailing-space output and checks every workload record.

- Dart [`FizzBuzz.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/other/FizzBuzz.dart)
- Python [`fizz_buzz.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/fizz_buzz.py)
- Ruby array [`fizz_buzz.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/fizz_buzz.rb)
- Ruby hash [`fizz_buzz.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/hash_table/fizz_buzz.rb)

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_scalar_bytes_output --algorithm fizz_buzz --language rust
python3 benchmarks/run_i64_scalar_bytes_output.py --build-manifest build/i64_scalar_bytes_output/f/fizz_buzz/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/f/fizz_buzz.c`](../../../c/f/fizz_buzz.c) |
| C3 | [`c3/f/fizz_buzz.c3`](../../../c3/f/fizz_buzz.c3) |
| C++ | [`cpp/f/fizz_buzz.cpp`](../../../cpp/f/fizz_buzz.cpp) |
| Elisa | [`elisa/f/fizz_buzz.elisa`](../../../elisa/f/fizz_buzz.elisa) |
| Nim | [`nim/f/fizz_buzz.nim`](../../../nim/f/fizz_buzz.nim) |
| Odin | [`odin/f/fizz_buzz.odin`](../../../odin/f/fizz_buzz.odin) |
| Rust | [`rust/f/fizz_buzz.rs`](../../../rust/f/fizz_buzz.rs) |
| V | [`v/f/fizz_buzz.v`](../../../v/f/fizz_buzz.v) |
| Zig | [`zig/f/fizz_buzz.zig`](../../../zig/f/fizz_buzz.zig) |

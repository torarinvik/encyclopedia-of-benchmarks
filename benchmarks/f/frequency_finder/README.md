# Frequency Finder

This benchmark ports the pinned Python `english_freq_match_score` function. It scores how closely the message's most frequent and least frequent letters match the source's `ETAOIN` order. The helper frequency-order string is an internal calculation and is not the benchmark result.

## Contract

The `i64_array_scalar` input is a raw array of ASCII bytes; the ABI length is the message length. Array lengths from 0 through 1,024 are valid, and an empty array is a valid empty message. Values must be from 0 through 127. ASCII lowercase letters are converted to uppercase; only `A` through `Z` contribute to the counts. All other ASCII values are ignored. Over-bound lengths or values outside ASCII return `-1`.

The implementation counts all 26 letters, including letters with zero occurrences. It orders letters by count descending, then by `ETAOIN.find(letter)` descending for ties. The score is the number of letters from `ETAOIN[:6]` found in the first six ordered letters plus the number from `ETAOIN[-6:]` found in the last six. The result is from 0 through 12. The source's `english_letter_freq` dictionary is not used by the scoring function.

The workload caps valid message length at 1,024 bytes and admits up to 1,025 values so one over-bound input can be checked. The pinned Python implementation accepts strings; this benchmark covers its ASCII subset.

## Workload and verification

[`workload.json`](workload.json) covers empty input, case folding, punctuation and control values, tie ordering, the maximum input, and invalid bytes or lengths. The independent oracle is [`benchmarks/frequency_finder_oracle.py`](../../frequency_finder_oracle.py).

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm frequency_finder --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/f/frequency_finder/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms frequency_finder
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/f/frequency_finder.c`](../../../c/f/frequency_finder.c) |
| C3 | [`c3/f/frequency_finder.c3`](../../../c3/f/frequency_finder.c3) |
| C++ | [`cpp/f/frequency_finder.cpp`](../../../cpp/f/frequency_finder.cpp) |
| Elisa | [`elisa/f/frequency_finder.elisa`](../../../elisa/f/frequency_finder.elisa) |
| Nim | [`nim/f/frequency_finder.nim`](../../../nim/f/frequency_finder.nim) |
| Odin | [`odin/f/frequency_finder.odin`](../../../odin/f/frequency_finder.odin) |
| Rust | [`rust/f/frequency_finder.rs`](../../../rust/f/frequency_finder.rs) |
| V | [`v/f/frequency_finder.v`](../../../v/f/frequency_finder.v) |
| Zig | [`zig/f/frequency_finder.zig`](../../../zig/f/frequency_finder.zig) |

## TheAlgorithms reference

- [Python `frequency_finder.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/frequency_finder.py)

# Flash Sort

Sort a bounded array of signed integers with the Flash Sort distribution and permutation phases, followed by insertion sort within the classes.

## Contract

- ABI: `i64_array_bytes_output`; each input element is one signed integer.
- Valid lengths are 0, 1, and 3 through 64. Length 2 is excluded because the pinned Java and JavaScript versions compute `floor(0.45 * 2) == 0` classes and do not handle a nonconstant two-element array. The Python version clamps the class count to one.
- Each value is in `-1,000,000..=1,000,000`. Invalid lengths or values return `-1`.
- Output is the ascending sequence encoded as little-endian signed i32 values. The maximum output is 256 bytes. Insufficient output capacity returns `-2` before writing.
- The implementations use the source default classification ratio of 0.45. They compute the class index with exact bounded integer arithmetic; the final insertion pass guarantees the same ascending result.

## Source and workload

This package covers [TheAlgorithms/Java `FlashSort.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/FlashSort.java), [TheAlgorithms/JavaScript `FlashSort.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Sorts/FlashSort.js), and [TheAlgorithms/Python `flash_sort.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/flash_sort.py). All three return values in ascending order after a final insertion-sort pass. The Python source also accepts floats; this benchmark uses a common bounded integer domain so every port has exact, reproducible input and output.

The Java implementation applies `compareTo(min)` both when estimating its normalization factor and when assigning classes. For integer inputs this reduces the classification to the minimum and nonminimum classes; the final insertion sort still produces the sorted result. The ports use the numeric range for class assignment while preserving the shared output contract. The workload covers empty and singleton arrays, source examples, negative values, duplicates, the maximum length, invalid length 2, insufficient output capacity, and value/length bounds.

Build and record Rust with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm flash_sort --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/f/flash_sort/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm flash_sort --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/flash_sort.c`](../../../c/f/flash_sort.c) |
| C3 | [`c3/f/flash_sort.c3`](../../../c3/f/flash_sort.c3) |
| C++ | [`cpp/f/flash_sort.cpp`](../../../cpp/f/flash_sort.cpp) |
| Elisa | [`elisa/f/flash_sort.elisa`](../../../elisa/f/flash_sort.elisa) |
| Nim | [`nim/f/flash_sort.nim`](../../../nim/f/flash_sort.nim) |
| Odin | [`odin/f/flash_sort.odin`](../../../odin/f/flash_sort.odin) |
| Rust | [`rust/f/flash_sort.rs`](../../../rust/f/flash_sort.rs) |
| V | [`v/f/flash_sort.v`](../../../v/f/flash_sort.v) |
| Zig | [`zig/f/flash_sort.zig`](../../../zig/f/flash_sort.zig) |

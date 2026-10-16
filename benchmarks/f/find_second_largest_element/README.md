# Find Second Largest Element

This benchmark ports the JavaScript `secondLargestElement` function from TheAlgorithms/JavaScript. It returns the greatest value strictly below the array maximum, so duplicate copies of the maximum are skipped.

## Contract

- The `i64_array_scalar` input is `[n, values[0], ..., values[n-1]]` with exact length `n + 1`.
- `n` is in `2..10,000`; each value is a signed 32-bit integer. Valid arrays contain at least two distinct values.
- The result is the second-largest **distinct** value as a signed 64-bit integer. Malformed inputs, values outside int32, and arrays without two distinct values return `INT64_MIN`.
- The source initializes its candidate to `-Number.MAX_VALUE` and returns that when there is no second distinct value. That no-answer case is excluded from the valid domain because it cannot be represented by the integer result ABI. The size cap also keeps JavaScript's `Math.max(...array)` spread within a practical argument count.

This differs from kth-largest selection, where duplicates occupy separate ranks: for `[7, 9, 9]`, this function returns `7`.

## Pinned source

- JavaScript [`FindSecondLargestElement.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Sorts/FindSecondLargestElement.js)

## Workload and build

[`workload.json`](workload.json) includes duplicate maxima, negative values, int32 boundaries, and invalid inputs. It uses `i64_array_scalar`:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm find_second_largest_element --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/f/find_second_largest_element/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms find_second_largest_element
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/f/find_second_largest_element.c`](../../../c/f/find_second_largest_element.c) |
| C3 | [`c3/f/find_second_largest_element.c3`](../../../c3/f/find_second_largest_element.c3) |
| C++ | [`cpp/f/find_second_largest_element.cpp`](../../../cpp/f/find_second_largest_element.cpp) |
| Elisa | [`elisa/f/find_second_largest_element.elisa`](../../../elisa/f/find_second_largest_element.elisa) |
| Nim | [`nim/f/find_second_largest_element.nim`](../../../nim/f/find_second_largest_element.nim) |
| Odin | [`odin/f/find_second_largest_element.odin`](../../../odin/f/find_second_largest_element.odin) |
| Rust | [`rust/f/find_second_largest_element.rs`](../../../rust/f/find_second_largest_element.rs) |
| V | [`v/f/find_second_largest_element.v`](../../../v/f/find_second_largest_element.v) |
| Zig | [`zig/f/find_second_largest_element.zig`](../../../zig/f/find_second_largest_element.zig) |

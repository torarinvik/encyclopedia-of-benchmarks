# Find Min Iterator

This benchmark ports the default-selector path of JavaScript `FindMinIterator`: return the smallest item from an iterable.

## Contract

The `i64_array_scalar` input is `[count, value_0, ..., value_(count-1)]`. The count is 0 through 128, every value is a nonnegative signed 32-bit integer, and the packed input must contain exactly `count + 1` values. A nonempty input returns its minimum. The source returns JavaScript `undefined` for an empty iterable; this scalar contract maps that no-value result to `-1`, which cannot collide with a valid value in the bounded domain. Malformed counts, packing, or values also return `-1`.

The source accepts arbitrary iterables, JavaScript comparison-compatible values, and an optional selector callback. This benchmark restricts the input to an array of nonnegative i32 integers and covers the default no-selector branch so comparisons are exact and portable across all nine target languages.

## Source

The source is [`FindMinIterator.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/FindMinIterator.js), pinned at commit `5c39e87a9a31f279c60f830ad74a845e4788a517`. Its default path iterates once, initializes the minimum from the first item, and updates it when a smaller item appears. The upstream repository is licensed under [MIT](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/LICENSE).

[`workload.json`](workload.json) covers empty and singleton iterables, ordering patterns, repeated minima, i32 boundaries, the 128-item limit, and malformed packed inputs. The independent oracle is [`find_min_iterator_oracle.py`](../../find_min_iterator_oracle.py).

## Build, record, and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm find_min_iterator --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/f/find_min_iterator/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms find_min_iterator
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/f/find_min_iterator.c`](../../../c/f/find_min_iterator.c) |
| C3 | [`c3/f/find_min_iterator.c3`](../../../c3/f/find_min_iterator.c3) |
| C++ | [`cpp/f/find_min_iterator.cpp`](../../../cpp/f/find_min_iterator.cpp) |
| Elisa | [`elisa/f/find_min_iterator.elisa`](../../../elisa/f/find_min_iterator.elisa) |
| Nim | [`nim/f/find_min_iterator.nim`](../../../nim/f/find_min_iterator.nim) |
| Odin | [`odin/f/find_min_iterator.odin`](../../../odin/f/find_min_iterator.odin) |
| Rust | [`rust/f/find_min_iterator.rs`](../../../rust/f/find_min_iterator.rs) |
| V | [`v/f/find_min_iterator.v`](../../../v/f/find_min_iterator.v) |
| Zig | [`zig/f/find_min_iterator.zig`](../../../zig/f/find_min_iterator.zig) |

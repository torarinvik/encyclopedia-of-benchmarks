# Number appearing odd times

Given an integer array in which one value appears an odd number of times and
every other value appears an even number of times, return that odd-frequency
value. The ports preserve the pinned Java implementation's XOR fold. If the
frequency condition is not met, the implementation still returns the XOR of
all values; it does not validate the frequency assumption.

## Contract

- Uses the `i64_array_scalar` ABI with 1 through 4,096 values.
- Each input value must fit a signed 32-bit integer, matching the Java `int[]`
  source. The XOR result is sign-extended to the ABI's signed 64-bit output.
- Return `-2,147,483,649` for empty arrays, arrays longer than 4,096, or values
  outside signed 32-bit range. This sentinel is outside the valid output range
  `INT32_MIN..INT32_MAX`.
- Under the source precondition, the result is the single value with odd
  frequency. Runtime is O(n), with O(1) extra space.

## Source semantics

The pinned Java `findOddOccurrence` initializes an `int` accumulator to zero
and XORs every array element into it. Equal values cancel in pairs, leaving the
unique odd-frequency value. The benchmark bounds inputs to signed 32-bit values
because Java stores each element in `int`.

## Workload and build

[`workload.json`](workload.json) covers unique odd-frequency values, negative
and boundary values, and invalid lengths or element values.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm number_appearing_odd_times --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/n/number_appearing_odd_times/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/n/number_appearing_odd_times.c`](../../../c/n/number_appearing_odd_times.c) |
| C3 | [`c3/n/number_appearing_odd_times.c3`](../../../c3/n/number_appearing_odd_times.c3) |
| C++ | [`cpp/n/number_appearing_odd_times.cpp`](../../../cpp/n/number_appearing_odd_times.cpp) |
| Elisa | [`elisa/n/number_appearing_odd_times.elisa`](../../../elisa/n/number_appearing_odd_times.elisa) |
| Nim | [`nim/n/number_appearing_odd_times.nim`](../../../nim/n/number_appearing_odd_times.nim) |
| Odin | [`odin/n/number_appearing_odd_times.odin`](../../../odin/n/number_appearing_odd_times.odin) |
| Rust | [`rust/n/number_appearing_odd_times.rs`](../../../rust/n/number_appearing_odd_times.rs) |
| V | [`v/n/number_appearing_odd_times.v`](../../../v/n/number_appearing_odd_times.v) |
| Zig | [`zig/n/number_appearing_odd_times.zig`](../../../zig/n/number_appearing_odd_times.zig) |

## TheAlgorithms reference

- [Java `NumberAppearingOddTimes.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/NumberAppearingOddTimes.java)

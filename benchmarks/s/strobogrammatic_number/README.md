# Strobogrammatic number

Checks whether an ASCII digit string is unchanged by a 180-degree rotation.

## Contract

- Uses the `i64_array_scalar` ABI: `int64_t strobogrammatic_number(const int64_t *bytes, size_t length)`.
- Input is a raw array of ASCII code points, with no terminator, bounded to 0..64 bytes. Values outside ASCII or a longer array are malformed packed inputs and return `-1`.
- Return `1` when the string matches under the source mapping `0→0`, `1→1`, `6→9`, `8→8`, `9→6`; otherwise return `0`.
- The empty string returns `1`, matching the source's two-pointer loop over an empty input. Leading zeroes are allowed because the source accepts a string, not a parsed integer. Whitespace is not trimmed.

## Source semantics

The benchmark follows the pinned [TheAlgorithms Java `StrobogrammaticNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/StrobogrammaticNumber.java). Its method compares the left character's mapped rotation to the right character while moving inward, and rejects characters outside the map. The source's prose says `609` is not strobogrammatic, but the executable map/check returns true for `609`; this benchmark follows the implementation. The shared contract restricts characters to ASCII so the array ABI represents the input portably. Non-ASCII values and oversized arrays return `-1` as malformed packed inputs; ordinary unmapped characters return `0`.

## Workload and build

[`workload.json`](workload.json) covers empty input, fixed points, mirrored pairs, leading zeroes, unmapped characters, and the length boundary. Build and record with the array scalar ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm strobogrammatic_number --language c
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/s/strobogrammatic_number/c/build.json
```

The nine implementations are in `c/s/strobogrammatic_number.c`, `c3/s/strobogrammatic_number.c3`, `cpp/s/strobogrammatic_number.cpp`, `elisa/s/strobogrammatic_number.elisa`, `nim/s/strobogrammatic_number.nim`, `odin/s/strobogrammatic_number.odin`, `rust/s/strobogrammatic_number.rs`, `v/s/strobogrammatic_number.v`, and `zig/s/strobogrammatic_number.zig`.

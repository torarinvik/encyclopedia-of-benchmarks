# One’s complement

Flip every bit in a nonempty binary string while preserving its length. This follows the pinned Java `OnesComplement.onesComplement` method.

## Contract

- Input is an array of 1 to 64 signed 64-bit values, each equal to the ASCII code for `0` (48) or `1` (49).
- Output is the same-length byte string with each bit flipped.
- Empty, overlength, null nonempty, or malformed input returns `-1` without writing output.
- Insufficient output capacity or a null output pointer for nonempty input returns `-2` without writing output.
- Successful calls return the number of bytes written. The workspace holds 64 bytes.

The Java method throws for null, empty, or nonbinary strings. This bounded contract represents the string as ASCII byte values and reports invalid input through the benchmark sentinel.

## Workload and oracle

[`workload.json`](workload.json) covers single bits, mixed and repeated values, leading and trailing zeroes, the maximum length, malformed bytes, empty input, overlength input, and insufficient output capacity. The independent oracle is [`ones_complement_oracle.py`](../../ones_complement_oracle.py).

Pinned source: [TheAlgorithms/Java `OnesComplement.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/OnesComplement.java).

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm ones_complement --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm ones_complement
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm ones_complement
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/o/ones_complement.c`](../../../c/o/ones_complement.c) |
| C3 | [`c3/o/ones_complement.c3`](../../../c3/o/ones_complement.c3) |
| C++ | [`cpp/o/ones_complement.cpp`](../../../cpp/o/ones_complement.cpp) |
| Elisa | [`elisa/o/ones_complement.elisa`](../../../elisa/o/ones_complement.elisa) |
| Nim | [`nim/o/ones_complement.nim`](../../../nim/o/ones_complement.nim) |
| Odin | [`odin/o/ones_complement.odin`](../../../odin/o/ones_complement.odin) |
| Rust | [`rust/o/ones_complement.rs`](../../../rust/o/ones_complement.rs) |
| V | [`v/o/ones_complement.v`](../../../v/o/ones_complement.v) |
| Zig | [`zig/o/ones_complement.zig`](../../../zig/o/ones_complement.zig) |

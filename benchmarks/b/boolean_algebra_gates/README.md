# Boolean algebra gates

Evaluate one of the six Boolean gates in the pinned Java source over a bounded list of Boolean inputs.

## Contract

- Uses the `i64_array_scalar` ABI with input `[gate_code, count, bit0, bit1, ...]`.
- Gate codes are `0` AND, `1` OR, `2` NOT, `3` XOR, `4` NAND, and `5` NOR.
- `count` must match the number of following bits and be in `[0, 4096]`. Each bit must be exactly `0` or `1`.
- NOT is unary and requires exactly one bit. The other gates accept empty input lists, matching the Java loops: AND and NOR return `1`; OR, XOR, and NAND return `0`.
- Valid outputs are `0` or `1`; malformed arrays, codes, counts, or bits return `-1`.

The pinned [Java `BooleanAlgebraGates.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/BooleanAlgebraGates.java) defines AND, OR, XOR, NAND, and NOR over `List<Boolean>` and NOT over one Boolean. This package encodes those class methods as one operation code plus a flat integer array.

## Workload and ABI

[`workload.json`](workload.json) exhausts all Boolean inputs of lengths zero through three for each list gate, both NOT inputs, selected longer lists, and malformed inputs.

Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm boolean_algebra_gates --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/b/boolean_algebra_gates/rust/build.json
```

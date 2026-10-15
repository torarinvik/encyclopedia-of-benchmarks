# Pronic Number

This package checks whether an integer is a pronic number, meaning it can be written as `m * (m + 1)` for a nonnegative integer `m`. Zero is pronic. For positive inputs, the ports take `floor(sqrt(n))` and check whether the adjacent product equals `n`.

## Shared contract

The scalar ABI accepts a signed 64-bit integer but supports the shared source domain `0..2,147,483,647`. This upper bound matches Java's `int` input and keeps the JavaScript/TypeScript `number` checks exact. Return `1` for pronic values and `0` for other supported values. Negative inputs and values above the supported maximum return `-1`, an ABI sentinel that cannot collide with a valid result.

The pinned sources agree on all nonnegative integer inputs in this shared range. Their behavior outside it differs: Python and TypeScript reject non-integers; TypeScript also throws for negative inputs, while JavaScript, Java, Python, and Go return false for negative integers. Java accepts only `int`; the other sources can express larger integers, subject to their own numeric representations. Those inputs are outside this common benchmark contract.

Java's `PronicNumber` contains both a linear helper and the public square-root method `isPronicNumber(int)`; this benchmark corresponds to the public O(1) method. The boolean source results are encoded as signed 64-bit `1` or `0`.

## Workload and build

[`workload.json`](workload.json) includes zero, small pronic and non-pronic values, the largest pronic value in the supported range with its neighbors, the signed 32-bit maximum, and invalid ABI inputs. Build a port with `python3 benchmarks/build_scalar.py --algorithm pronic_number --language LANGUAGE`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/pronic_number.c`](../../../c/p/pronic_number.c) |
| C3 | [`c3/p/pronic_number.c3`](../../../c3/p/pronic_number.c3) |
| C++ | [`cpp/p/pronic_number.cpp`](../../../cpp/p/pronic_number.cpp) |
| Elisa | [`elisa/p/pronic_number.elisa`](../../../elisa/p/pronic_number.elisa) |
| Nim | [`nim/p/pronic_number.nim`](../../../nim/p/pronic_number.nim) |
| Odin | [`odin/p/pronic_number.odin`](../../../odin/p/pronic_number.odin) |
| Rust | [`rust/p/pronic_number.rs`](../../../rust/p/pronic_number.rs) |
| V | [`v/p/pronic_number.v`](../../../v/p/pronic_number.v) |
| Zig | [`zig/p/pronic_number.zig`](../../../zig/p/pronic_number.zig) |

## TheAlgorithms references

- [JavaScript `IsPronic.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/IsPronic.js)
- [Java `PronicNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PronicNumber.java)
- [Python `pronic_number.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/pronic_number.py)
- [TypeScript `pronic_number.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/pronic_number.ts)
- [Go `pronicnumber.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/pronicnumber.go)

# Happy number

A positive integer is happy when repeatedly replacing it with the sum of the squares of its decimal digits eventually reaches 1. Floyd's cycle detection distinguishes numbers that enter a cycle without allocating a set.

## Contract

The input is a signed 64-bit integer. Values from 1 through `INT64_MAX` return `1` for happy and `0` for unhappy. Zero and negative values are outside the positive-integer definition and return `-1`.

Each port computes the digit-square transform and uses Floyd's tortoise-and-hare cycle detection in O(log n) time with O(1) extra space.

## Source review

The Java and Python candidates implement the standard digit-square definition. The two pinned C++ copies sum the digits until one digit remains, which is a digital-root test and misclassifies standard happy numbers such as 7. They are recorded as reviewed source candidates, but the benchmark follows the standard definition.

## Reproduce

```sh
python3 benchmarks/build_scalar.py --algorithm happy_number --language c
python3 benchmarks/run_scalar.py --algorithm happy_number
python3 benchmarks/verify_scalar.py --algorithms happy_number --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```

The shared scalar verifier checks the small integer range, deterministic random signed 64-bit inputs, known happy/unhappy values, and the full signed boundaries against a set-based oracle.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/happy_number.c`](../../../c/h/happy_number.c) |
| C3 | [`c3/h/happy_number.c3`](../../../c3/h/happy_number.c3) |
| C++ | [`cpp/h/happy_number.cpp`](../../../cpp/h/happy_number.cpp) |
| Elisa | [`elisa/h/happy_number.elisa`](../../../elisa/h/happy_number.elisa) |
| Nim | [`nim/h/happy_number.nim`](../../../nim/h/happy_number.nim) |
| Odin | [`odin/h/happy_number.odin`](../../../odin/h/happy_number.odin) |
| Rust | [`rust/h/happy_number.rs`](../../../rust/h/happy_number.rs) |
| V | [`v/h/happy_number.v`](../../../v/h/happy_number.v) |
| Zig | [`zig/h/happy_number.zig`](../../../zig/h/happy_number.zig) |

## TheAlgorithms references

- [C++ `happy_number.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/happy_number.cpp) and [additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/others/happy_number.cpp)
- [Java `HappyNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/HappyNumber.java)
- [Python `happy_number.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/happy_number.py)

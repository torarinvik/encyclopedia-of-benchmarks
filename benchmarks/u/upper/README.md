# Uppercase ASCII letters

## Contract

Convert every lowercase ASCII letter `a..z` to uppercase and preserve all other accepted bytes. Input is an ASCII byte array of length 0 through 256. Byte values must be `0..127` and may not be ASCII whitespace (`9..13` or `32`); excluding whitespace aligns the pinned F# implementation, which splits and rejoins words, with the Java, JavaScript, and Python implementations that preserve separators. Invalid length or byte values return `-1`; insufficient output capacity returns `-2`; success returns the input length and writes the transformed string without a terminator.

The existing `capitalize` benchmark changes only the initial character. This benchmark uppercases every lowercase ASCII letter.

The shared `run_i64_array_bytes_output.py` runner checks accepted-byte conversions and rejects out-of-domain inputs before timing.

Run the independent cross-language verifier with:

```sh
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm upper
```

The shared ABI is:

```c
int64_t upper(const int64_t *input, size_t length,
              uint8_t *output, size_t output_capacity);
```

## Workload

[`workload.json`](workload.json) covers empty input, mixed case, punctuation, digits, non-ASCII and whitespace rejection, and the maximum length.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/u/upper.c`](../../../c/u/upper.c) |
| C3 | [`c3/u/upper.c3`](../../../c3/u/upper.c3) |
| C++ | [`cpp/u/upper.cpp`](../../../cpp/u/upper.cpp) |
| Elisa | [`elisa/u/upper.elisa`](../../../elisa/u/upper.elisa) |
| Nim | [`nim/u/upper.nim`](../../../nim/u/upper.nim) |
| Odin | [`odin/u/upper.odin`](../../../odin/u/upper.odin) |
| Rust | [`rust/u/upper.rs`](../../../rust/u/upper.rs) |
| V | [`v/u/upper.v`](../../../v/u/upper.v) |
| Zig | [`zig/u/upper.zig`](../../../zig/u/upper.zig) |

## Upstream references

- [F# `Upper.fs`](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Strings/Upper.fs)
- [Java `Upper.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/Upper.java)
- [JavaScript `Upper.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/Upper.js)
- [Python `upper.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/upper.py)

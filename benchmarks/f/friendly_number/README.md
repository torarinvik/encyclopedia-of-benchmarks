# Friendly number pair

Check whether two positive integers have the same abundancy index, the ratio
of the sum of all positive divisors to the number.

## Contract

- Inputs use the `binary_scalar` ABI. Each input is in `[0, 1,000,000]`.
- Return `1` when `sigma(a) * b == sigma(b) * a`, where `sigma(n)` is the sum
  of all positive divisors of `n`; otherwise return `0`.
- Zero is in range and returns `0`, matching the pinned Java source's explicit
  `a <= 0 || b <= 0` guard. Inputs outside the valid range, including negative
  values encoded by the runner as two's-complement `uint64`, return `-1`.
- The bound keeps the Java source's `int` divisor sums and `long` cross
  products within range. The ports preserve the source's paired-divisor scan
  through the integer square root and compare cross-products exactly rather
  than dividing into floating point.

## Pinned source and related candidate

The pinned [Java `FriendlyNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/FriendlyNumber.java)
rejects nonpositive inputs, sums divisors in pairs through `sqrt(n)`, then
compares `sigma(a) * b` with `sigma(b) * a`. Equal positive inputs therefore
return true.

The separate JavaScript `friendly_numbers` candidate appears to implement this
same predicate, but it rejects equal and zero inputs and its divisor loop omits
`n/2` for even `n`. It is flagged for alias review rather than represented as
a second benchmark.

## Workload and build

[`workload.json`](workload.json) covers known friendly pairs, unequal
abundancy indices, equal inputs, zero, and both supported bounds. Build and
record with:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm friendly_number --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/f/friendly_number/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/f/friendly_number.c`](../../../c/f/friendly_number.c) |
| C3 | [`c3/f/friendly_number.c3`](../../../c3/f/friendly_number.c3) |
| C++ | [`cpp/f/friendly_number.cpp`](../../../cpp/f/friendly_number.cpp) |
| Elisa | [`elisa/f/friendly_number.elisa`](../../../elisa/f/friendly_number.elisa) |
| Nim | [`nim/f/friendly_number.nim`](../../../nim/f/friendly_number.nim) |
| Odin | [`odin/f/friendly_number.odin`](../../../odin/f/friendly_number.odin) |
| Rust | [`rust/f/friendly_number.rs`](../../../rust/f/friendly_number.rs) |
| V | [`v/f/friendly_number.v`](../../../v/f/friendly_number.v) |
| Zig | [`zig/f/friendly_number.zig`](../../../zig/f/friendly_number.zig) |

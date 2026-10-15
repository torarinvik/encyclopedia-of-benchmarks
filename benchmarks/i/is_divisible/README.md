# Is divisible

This benchmark checks whether an integer dividend has zero remainder when
divided by an integer divisor.

## Contract

- Inputs use the `binary_scalar` ABI. The dividend is in `0..=1,000,000,000`;
  the divisor is in `1..=1,000,000,000`.
- Return `1` when `dividend % divisor == 0`, otherwise return `0`.
- Inputs outside those bounds, including a zero divisor, return `-1`.

The pinned JavaScript and TypeScript sources agree on the supported domain and
use remainder equality. Their zero-divisor behavior differs: JavaScript returns
false, while TypeScript throws. The contract excludes zero divisors and uses a
single `-1` sentinel for out-of-domain calls. Both sources also apply the same
remainder check to negative integers, but the benchmark uses nonnegative words
so the signed source values map directly to the existing binary scalar ABI.

## Pinned sources

- [JavaScript `IsDivisible.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/IsDivisible.js)
- [TypeScript `is_divisible.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/is_divisible.ts)

## Workload and build

[`workload.json`](workload.json) covers divisible and nondivisible pairs,
divisibility by one, a zero dividend, and invalid values. Build and record with:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm is_divisible --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/i/is_divisible/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/i/is_divisible.c`](../../../c/i/is_divisible.c) |
| C3 | [`c3/i/is_divisible.c3`](../../../c3/i/is_divisible.c3) |
| C++ | [`cpp/i/is_divisible.cpp`](../../../cpp/i/is_divisible.cpp) |
| Elisa | [`elisa/i/is_divisible.elisa`](../../../elisa/i/is_divisible.elisa) |
| Nim | [`nim/i/is_divisible.nim`](../../../nim/i/is_divisible.nim) |
| Odin | [`odin/i/is_divisible.odin`](../../../odin/i/is_divisible.odin) |
| Rust | [`rust/i/is_divisible.rs`](../../../rust/i/is_divisible.rs) |
| V | [`v/i/is_divisible.v`](../../../v/i/is_divisible.v) |
| Zig | [`zig/i/is_divisible.zig`](../../../zig/i/is_divisible.zig) |

# Shuffle array

This package keeps three pinned source behaviors as explicit variants. The
Java and TypeScript sources use reverse Fisher–Yates with runtime randomness;
the Ruby source's final `shuffle` definition performs a deterministic
half-interleave. They are not aliases.

## Contract

The `i64_array_bytes_output` input begins with `[variant, n]`. `n` is from 0
through 32. Variant `0` is reverse Fisher–Yates: it is followed by `n` signed
i32 values, then `max(n-1, 0)` caller-supplied draw indices in execution order
for `i = n-1` down to `1`. Each draw index `j` must satisfy `0 <= j <= i`; the
port swaps `values[i]` with `values[j]`. Supplying the draws preserves the
source's shuffle steps while making each workload reproducible across
languages.

Variant `1` is Ruby's half-interleave. It is followed by `2*n` signed i32
values, interpreted as `[x1, ..., xn, y1, ..., yn]`, and returns
`[x1, y1, ..., xn, yn]`. In the pinned Ruby file, the final of three
same-named `shuffle` definitions is the active two-pointer implementation;
the other definitions compute the same mapping.

The input length must be exact: variant `0` uses `2+n+max(n-1, 0)` words and
variant `1` uses `2+2*n`. The maximum valid input is 66 words; one additional
word is accepted for malformed-length cases. Values must fit signed i32.

Output is little-endian signed i64 words `[result_count, result_values...]`.
The result count is `n` for variant `0` and `2*n` for variant `1`. The maximum
output is 65 words (520 bytes). Malformed or out-of-domain input returns `-1`.
Input validation precedes output validation; a null output buffer or capacity
below the encoded output size returns `-2` without writing bytes, including
for an empty result (which still has its count word). Capacity is measured in
bytes and success returns bytes written.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Independent oracle: [`benchmarks/shuffle_array_oracle.py`](../../shuffle_array_oracle.py)

## ABI and ports

The ports use `i64_array_bytes_output`; output capacity is in bytes. Build and
record the Rust port with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm shuffle_array --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/s/shuffle_array/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm shuffle_array --languages rust
```

| Language | Source |
| --- | --- |
| C | [`c/s/shuffle_array.c`](../../../c/s/shuffle_array.c) |
| C3 | [`c3/s/shuffle_array.c3`](../../../c3/s/shuffle_array.c3) |
| C++ | [`cpp/s/shuffle_array.cpp`](../../../cpp/s/shuffle_array.cpp) |
| Elisa | [`elisa/s/shuffle_array.elisa`](../../../elisa/s/shuffle_array.elisa) |
| Nim | [`nim/s/shuffle_array.nim`](../../../nim/s/shuffle_array.nim) |
| Odin | [`odin/s/shuffle_array.odin`](../../../odin/s/shuffle_array.odin) |
| Rust | [`rust/s/shuffle_array.rs`](../../../rust/s/shuffle_array.rs) |
| V | [`v/s/shuffle_array.v`](../../../v/s/shuffle_array.v) |
| Zig | [`zig/s/shuffle_array.zig`](../../../zig/s/shuffle_array.zig) |

## Pinned sources

- [TheAlgorithms/Java `ShuffleArray.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/ShuffleArray.java)
- [TheAlgorithms/TypeScript `shuffle_array.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/other/shuffle_array.ts)
- [TheAlgorithms/Ruby `shuffle_array.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/shuffle_array.rb)

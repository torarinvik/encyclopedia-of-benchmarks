# Sock merchant

Counts how many matching pairs can be formed from socks grouped by color.

## Contract

- Uses the array scalar ABI: `int64_t sock_merchant(const int64_t *colors, size_t length)`.
- The array length is in `[0, 512]`; color IDs are in `[0, 4095]`. Malformed inputs return `-1`.
- Returns `sum(count(color) / 2)` using integer division. Unpaired socks do not contribute.
- An empty array returns `0`, matching the source's empty `Counter` sum.

## Source semantics

The benchmark follows pinned [TheAlgorithms Python `sock_merchant.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/sock_merchant.py). It builds a `Counter` over all color labels, divides each frequency by two with floor division, and sums those pair counts. The shared array ABI carries nonnegative signed 64-bit values; this benchmark narrows labels to `[0, 4095]` while preserving equality and pair-count semantics. The ports use a zeroed bounded frequency table for that label domain rather than a dynamic hash table.

## Workload and build

[`workload.json`](workload.json) covers empty and singleton arrays, repeated and odd frequencies, multiple colors, the maximum label, and malformed values. Build and record with the array scalar ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm sock_merchant --language c
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/s/sock_merchant/c/build.json
```

The nine implementations are in `c/s/sock_merchant.c`, `c3/s/sock_merchant.c3`, `cpp/s/sock_merchant.cpp`, `elisa/s/sock_merchant.elisa`, `nim/s/sock_merchant.nim`, `odin/s/sock_merchant.odin`, `rust/s/sock_merchant.rs`, `v/s/sock_merchant.v`, and `zig/s/sock_merchant.zig`.

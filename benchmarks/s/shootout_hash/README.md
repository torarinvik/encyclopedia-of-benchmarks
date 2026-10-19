# Shootout hash

This package ports `Shootout/hash` from the pinned
[`lac-dcc/Benchmarks` source](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/hash)
at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher compiles
`hash.c` with `-lm` and supplies no run options, so the source uses its default
`LENGTH` of 3,500,000. `SMALL_PROBLEM_SIZE` is not enabled.

For input `n`, the driver inserts keys for values 1 through `n` using
lowercase hexadecimal text, then searches values `n` down to 1 using decimal
text. It prints the number of successful lookups. The bounded scalar contract
accepts 0 through 3,500,000; invalid inputs return `-1`. Input zero selects the
source's smallest bucket size, 53. Otherwise, the table uses the first listed
prime that is at least `n`; the launcher profile uses 6,291,469 buckets. The
source hash folds each key byte as `hash = 5 * hash + byte`, reduces modulo the
bucket count, and keeps collision chains in insertion order.

The language ports preserve the prime bucket choice, byte hash, chained
inserts, and descending string lookups with index backed nodes. The original
launcher profile returns `356799`. The independent oracle counts decimal
strings whose same digits, interpreted in base 16, identify an inserted key;
it does not construct or query a hash table.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/shootout_hash.c](../../../c/s/shootout_hash.c) |
| C3 | [c3/shootout_hash.c3](../../../c3/s/shootout_hash.c3) |
| C++ | [cpp/shootout_hash.cpp](../../../cpp/s/shootout_hash.cpp) |
| Elisa | [elisa/shootout_hash.elisa](../../../elisa/s/shootout_hash.elisa) |
| Nim | [nim/shootout_hash.nim](../../../nim/s/shootout_hash.nim) |
| Odin | [odin/shootout_hash.odin](../../../odin/s/shootout_hash.odin) |
| Rust | [rust/shootout_hash.rs](../../../rust/s/shootout_hash.rs) |
| V | [v/shootout_hash.v](../../../v/s/shootout_hash.v) |
| Zig | [zig/shootout_hash.zig](../../../zig/s/shootout_hash.zig) |

Run the shared scalar suite with:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm shootout_hash --language c
python3 benchmarks/run_scalar.py --build-manifest build/scalar/s/shootout_hash/c/build.json
python3 benchmarks/verify_scalar.py --algorithms shootout_hash --languages c
```

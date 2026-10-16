# Hash Set

This package ports the pinned C [`hash_set.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/hash_set/hash_set.c) and its [`hash_set.h`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/hash_set/hash_set.h).

## Contract

The `i64_array_scalar` input is `[add_count, add_ids..., query_count, query_ids...]`. Both counts are in `[0,64]`; each ID is in `[0,63]`. Each ID represents the exact ASCII string `key<ID>`, with one stable object reused for every add and query of that ID, matching the C source's pointer-identity comparison. The source's default capacity is 1024. These 64 strings map to distinct source buckets, so valid inputs do not enter its resize path. Repeated adds of the same ID are idempotent. Deletion is outside this bounded contract because the source clears a slot without decrementing its length.

The result is the low 63 bits of FNV-1a-64 over signed-i64 little-endian words `[set_length, contains(query_0), ..., contains(query_m-1)]`, where each membership value is `0` or `1`. The FNV offset basis is `14695981039346656037` and the prime is `1099511628211`. Invalid shape, count, or ID returns `-1`.

The independent oracle is [`hash_set_oracle.py`](../../hash_set_oracle.py); fixtures are in [`workload.json`](workload.json).

## Implementations

| Language | Port |
|---|---|
| C | [`c/h/hash_set.c`](../../../c/h/hash_set.c) |
| C3 | [`c3/h/hash_set.c3`](../../../c3/h/hash_set.c3) |
| C++ | [`cpp/h/hash_set.cpp`](../../../cpp/h/hash_set.cpp) |
| Elisa | [`elisa/h/hash_set.elisa`](../../../elisa/h/hash_set.elisa) |
| Nim | [`nim/h/hash_set.nim`](../../../nim/h/hash_set.nim) |
| Odin | [`odin/h/hash_set.odin`](../../../odin/h/hash_set.odin) |
| Rust | [`rust/h/hash_set.rs`](../../../rust/h/hash_set.rs) |
| V | [`v/h/hash_set.v`](../../../v/h/hash_set.v) |
| Zig | [`zig/h/hash_set.zig`](../../../zig/h/hash_set.zig) |

Build and record with the `i64_array_scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm hash_set --language rust --with-checker
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/h/hash_set/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithm hash_set --languages rust
```

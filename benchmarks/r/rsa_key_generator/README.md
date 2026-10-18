# RSA key generator

This benchmark follows the pinned Python `generate_key` function and its Rabin–Miller, GCD, and modular-inverse helpers. Randomness is made explicit as a bounded sequence of `random.randrange` return values, consumed in the exact order requested by the source. The benchmark measures key construction only; the separate file-writing wrapper is outside the contract.

## Contract

The `i64_array_scalar` input is `[key_size, draw_count, draws...]`. `key_size` is 2 through 20 and `draw_count` is 0 through 1,024. The packed length must be exactly `2 + draw_count`; valid frames contain at most 1,026 values, and the parser admits 1,027 values so one over-bound draw count can be rejected. Each draw is a supplied result for the next source `random.randrange(low, high)` call. When consumed, the value must be in that call's half-open range. Unused trailing draws are ignored after the source has constructed its key pair.

The draw sequence drives both calls to `generate_large_prime(key_size)`, including the source helper's trial division and five-round Rabin–Miller checks, then the repeated exponent selection in `generate_key`. The source permits `p == q`; this contract preserves that behavior. It also preserves its tuple order: public key `(n, e)` and private key `(n, d)`, with `n = p*q`, `phi = (p-1)*(q-1)`, and `d` the modular inverse of `e` modulo `phi`.

The signed 64-bit result is the low 63 bits of FNV-1a-64 over the four returned tuple values `(n, e, n, d)`, each encoded as an eight-byte little-endian signed integer. Invalid packing, out-of-domain values, a consumed draw outside its requested range, or draw-stream exhaustion returns `-1`. The key-size bound keeps every tuple component inside signed 64-bit range and gives the draw stream a fixed maximum size.

The packed input makes the helper's randomness reproducible without changing which candidates are tested or which Miller–Rabin rounds and exponent retries occur. The benchmark does not test Python's PRNG state. It does not invoke `make_key_files`, create files, or measure file-system behavior.

## Pinned source and workload

The source is TheAlgorithms/Python at commit `e1a2a8b016001309a73d5fec4818c35cca139795`: [`rsa_key_generator.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/rsa_key_generator.py), [`rabin_miller.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/rabin_miller.py), [`cryptomath_module.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/cryptomath_module.py), and [`greatest_common_divisor.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/greatest_common_divisor.py).

[`workload.json`](workload.json) covers the smallest key sizes, repeated exponent selection, candidate rejection by trial division and Rabin–Miller, five successful Miller–Rabin rounds, equal primes, malformed frames, and exhausted or invalid draw streams. The independent oracle is [`rsa_key_generator_oracle.py`](../../rsa_key_generator_oracle.py).

## Language ports

| Language | Source |
| --- | --- |
| C | [rsa_key_generator.c](../../../c/r/rsa_key_generator.c) |
| C3 | [rsa_key_generator.c3](../../../c3/r/rsa_key_generator.c3) |
| C++ | [rsa_key_generator.cpp](../../../cpp/r/rsa_key_generator.cpp) |
| Elisa | [rsa_key_generator.elisa](../../../elisa/r/rsa_key_generator.elisa) |
| Nim | [rsa_key_generator.nim](../../../nim/r/rsa_key_generator.nim) |
| Odin | [rsa_key_generator.odin](../../../odin/r/rsa_key_generator.odin) |
| Rust | [rsa_key_generator.rs](../../../rust/r/rsa_key_generator.rs) |
| V | [rsa_key_generator.v](../../../v/r/rsa_key_generator.v) |
| Zig | [rsa_key_generator.zig](../../../zig/r/rsa_key_generator.zig) |

# DJB2 64-bit hash

This benchmark ports DJB2 from the pinned C source. It starts with `5381` and applies `hash = hash * 33 + byte` to each byte of a NUL-terminated string. The packed ABI uses `[n, bytes...]`, with `n` from 0 through 3 and each byte in 1 through 127; zero is excluded because the C source stops at the first NUL. The packed length must be exactly `n + 1`. Empty input returns 5381. Invalid layouts or byte values return -1.

The C source returns `uint64_t`; the Python candidate masks its result to 32 bits. On the shared three-byte domain, even three bytes of value 127 produce only 193,519,618, so both widths return the same exact value, which also fits the signed `i64` ABI. Longer strings could make the C and Python outputs differ, so they are outside this shared contract. The C source's published `Hello World` example is therefore outside the benchmark's input bound.

This is distinct from the separate 8-bit XOR checksum `hash_xor8`.

Pinned source: [TheAlgorithms/C `hash/hash_djb2.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/hash/hash_djb2.c).

The independent oracle is [`hash_djb2_oracle.py`](../../hash_djb2_oracle.py). The workload is in [`workload.json`](workload.json).

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm hash_djb2 --language c
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/h/hash_djb2/c/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms hash_djb2
```

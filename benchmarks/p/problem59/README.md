# Project Euler Problem 59

## Contract

The pinned Python source reads comma-separated ciphertext from `p059_cipher.txt`, tries all three-letter lowercase XOR keys, removes keys that produce non-ASCII text, then applies common-word filters in this order: `the`, `be`, `to`, `of`, `and`, `in`, `that`, `have`. It stops filtering when one candidate remains; if filtering leaves multiple candidates, it returns the first in key order, matching the pinned source.

The benchmark bundles the pinned 1,455-byte ciphertext in [`workload.json`](workload.json) and passes it as an integer array to each language. Ports preserve key order and filter order. Valid arrays contain 1..4,096 bytes; arrays outside that bound or containing values outside 0..255 return `-1`. The source dataset returns `129448` and resolves to key `exp`.

Each language exports an array-scalar function equivalent to:

```c
int64_t problem59(const int64_t *ciphertext, size_t length);
```

## Workload

[`workload.json`](workload.json) embeds the data bytes, the canonical sum, and invalid array boundaries. The verifier checks the canonical ciphertext against a Python arbitrary-precision XOR oracle.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_059/sol1.py)
- Cipher data [`p059_cipher.txt`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_059/p059_cipher.txt)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem59.c](../../../c/p/problem59.c) |
| C3 | [c3/p/problem59.c3](../../../c3/p/problem59.c3) |
| C++ | [cpp/p/problem59.cpp](../../../cpp/p/problem59.cpp) |
| Elisa | [elisa/p/problem59.elisa](../../../elisa/p/problem59.elisa) |
| Nim | [nim/p/problem59.nim](../../../nim/p/problem59.nim) |
| Odin | [odin/p/problem59.odin](../../../odin/p/problem59.odin) |
| Rust | [rust/p/problem59.rs](../../../rust/p/problem59.rs) |
| V | [v/p/problem59.v](../../../v/p/problem59.v) |
| Zig | [zig/p/problem59.zig](../../../zig/p/problem59.zig) |

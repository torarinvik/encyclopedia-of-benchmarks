# Prime Numbers

## Contract

Return every prime number from 2 through an inclusive limit, in ascending order, encoded as comma-separated ASCII decimal bytes. The C ABI accepts a signed 64-bit limit from 0 through 80. Negative or larger limits return `-1`. If the output buffer cannot hold the complete encoding, the function returns `-2`; otherwise it returns the number of bytes written. Limits 0 and 1 produce an empty result.

The local ports use trial division through the square root for each candidate. This gives all nine languages the same algorithm and output contract. The pinned source group includes trial-division generators in Python and Rust, and a linear sieve in the C++1 repository. The second Python file with this filename supplies `is_prime` and `next_prime` helpers rather than a prime-list generator; that separate operation is cataloged under `next_prime_number`.

## Workload and measurement

[`workload.json`](workload.json) covers empty results, small lists, composite and prime limits, the largest supported limit, and invalid boundaries. The scalar byte-output runner checks results before timing and hashes each returned byte sequence. It runs two warmup batches and records nine samples of 100 calls per case.

[`benchmarks/verify_prime_numbers.py`](../../verify_prime_numbers.py) exhausts all valid limits, checks exact and insufficient output capacities, and tests signed boundary inputs against a separate trial-division oracle. The verification report records the host and source hashes; it does not claim that every platform has been tested.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/p/prime_numbers.c`](../../../c/p/prime_numbers.c) | Portable local implementation |
| C3 | [`c3/p/prime_numbers.c3`](../../../c3/p/prime_numbers.c3) | Portable local implementation |
| C++ | [`cpp/p/prime_numbers.cpp`](../../../cpp/p/prime_numbers.cpp) | Local implementation; upstream C++ source below |
| Elisa | [`elisa/p/prime_numbers.elisa`](../../../elisa/p/prime_numbers.elisa) | Local implementation for the custom Elisa compiler |
| Nim | [`nim/p/prime_numbers.nim`](../../../nim/p/prime_numbers.nim) | Portable local implementation |
| Odin | [`odin/p/prime_numbers.odin`](../../../odin/p/prime_numbers.odin) | Portable local implementation |
| Rust | [`rust/p/prime_numbers.rs`](../../../rust/p/prime_numbers.rs) | Local implementation; upstream Rust source below |
| V | [`v/p/prime_numbers.v`](../../../v/p/prime_numbers.v) | Portable local implementation |
| Zig | [`zig/p/prime_numbers.zig`](../../../zig/p/prime_numbers.zig) | Portable local implementation |

## TheAlgorithms references

- [C++ `prime_numbers`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2849e8d1a8d926e171cc5b39f97759/math/prime_numbers.cpp)
- [C++1 `prime_numbers` linear sieve](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/prime_numbers.cpp)
- [Python `prime_numbers`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/prime_numbers.py)
- [Python `is_prime` and `next_prime` helpers](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/hashing/number_theory/prime_numbers.py)
- [Rust `prime_numbers`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/prime_numbers.rs)

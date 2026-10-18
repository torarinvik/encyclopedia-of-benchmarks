# Classical order-finding factor search

The pinned JavaScript function is named `ShorsAlgorithm`, but it is a classical order-finding sketch. It selects integer bases, searches for their multiplicative order, and applies the even-order gcd factor step. This benchmark preserves that control flow; it does not model quantum circuits or measurements.

## Contract

The ABI is `i64_array_scalar`. Input is the signed 64-bit integer array `[N, attempt_count, g0, g1, ...]`. `N` is from 2 through 255, `attempt_count` is from 1 through 16, and the array contains exactly `2 + attempt_count` values. Each supplied base `g` must be in `[2, N]`. The maximum valid input length is 18 and the maximum parseable length is 19.

The source chooses `g = floor(Math.random() * (N - 1)) + 2`, so every integer in `[2, N]` is possible, including `N`. The workload supplies that selected base stream directly and processes bases in order. If `gcd(g, N) != 1`, return that gcd immediately. Otherwise find the smallest `p >= 1` for which `g^p mod N == 1`; an odd `p` moves to the next base. For even `p`, compute `y = g^(p/2) mod N`. If either `y+1` or `y-1` is divisible by `N`, move to the next base. Otherwise return `gcd(y+1,N)` when it is not 1, and return `gcd(y-1,N)` otherwise, matching the source branch order.

The JavaScript source forms full `BigInt` powers. This bounded adapter calculates their remainders modulo `N`: congruence checks, divisibility checks, and gcds with `N` are unchanged by reducing the power modulo `N`. Since `g` is coprime to `N`, the order is at most `N-1`; the bounded search covers the full source order range. If the supplied finite stream yields no factor, return `-1`. The source's in-domain trivial return is retained: a supplied base equal to `N` returns `N` immediately. Other returned values are proper nontrivial factors.

Malformed framing, a null input pointer, an out-of-range modulus, attempt count, or base returns `-1`. The null-input probe declares length 3. The output is one signed 64-bit integer.

The independent oracle is [`../../shors_algorithm_oracle.py`](../../shors_algorithm_oracle.py); [`workload.json`](workload.json) defines deterministic base streams, retries, exhaustion, and boundary cases.

## Language ports

| Language | Port |
|---|---|
| C | [`c/s/shors_algorithm.c`](../../../c/s/shors_algorithm.c) |
| C3 | [`c3/s/shors_algorithm.c3`](../../../c3/s/shors_algorithm.c3) |
| C++ | [`cpp/s/shors_algorithm.cpp`](../../../cpp/s/shors_algorithm.cpp) |
| Elisa | [`elisa/s/shors_algorithm.elisa`](../../../elisa/s/shors_algorithm.elisa) |
| Nim | [`nim/s/shors_algorithm.nim`](../../../nim/s/shors_algorithm.nim) |
| Odin | [`odin/s/shors_algorithm.odin`](../../../odin/s/shors_algorithm.odin) |
| Rust | [`rust/s/shors_algorithm.rs`](../../../rust/s/shors_algorithm.rs) |
| V | [`v/s/shors_algorithm.v`](../../../v/s/shors_algorithm.v) |
| Zig | [`zig/s/shors_algorithm.zig`](../../../zig/s/shors_algorithm.zig) |

## Pinned source

- JavaScript [`ShorsAlgorithm.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/ShorsAlgorithm.js).

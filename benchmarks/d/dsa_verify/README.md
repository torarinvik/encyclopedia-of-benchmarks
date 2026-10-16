# Bounded DSA signature verification

This contract ports the deterministic `Verify` operation from the pinned Go DSA package. It covers only verification. Parameter/key generation and signing use `crypto/rand` and are not benchmarked here.

## Contract

Input is `[p,q,g,y,r,s,message_length,message_bytes...]`. `p` is prime in `[5,251]`; `q` is prime, divides `p-1`; `g` has exact order `q`; and `y` is a member of that subgroup. The signature components satisfy `1 <= r,s < q`. The message has up to 8 bytes and is interpreted big-endian, matching Go's `big.Int.SetBytes`. A valid signature returns 1, an invalid signature returns 0, and malformed inputs return -1.

The verifier follows the source equation: `w=s^-1 mod q`, `u1=H(m)w mod q`, `u2=rw mod q`, and `v=(g^u1*y^u2 mod p) mod q`, then compares `v` with `r`. Small prime bounds make every intermediate safe in signed 64-bit arithmetic; message reduction is performed byte-by-byte. This is an algorithm comparison contract, not a security recommendation.

[`workload.json`](workload.json) includes valid and altered signatures/messages, an empty message, invalid subgroup parameters, malformed signatures, and the maximum message size. The verifier adds deterministic valid parameter/signature cases.

Pinned source: [TheAlgorithms/Go `dsa.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/cipher/dsa/dsa.go).

| Language | Port |
|---|---|
| C | `c/d/dsa_verify.c` |
| C3 | `c3/d/dsa_verify.c3` |
| C++ | `cpp/d/dsa_verify.cpp` |
| Elisa | `elisa/d/dsa_verify.elisa` |
| Nim | `nim/d/dsa_verify.nim` |
| Odin | `odin/d/dsa_verify.odin` |
| Rust | `rust/d/dsa_verify.rs` |
| V | `v/d/dsa_verify.v` |
| Zig | `zig/d/dsa_verify.zig` |

Verify with `python3 benchmarks/verify_i64_array_scalar.py --algorithms dsa_verify`.

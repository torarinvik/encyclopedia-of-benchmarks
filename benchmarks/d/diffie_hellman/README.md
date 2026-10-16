# Diffie–Hellman shared secret

This benchmark captures the shared-secret modular-exponentiation core of the pinned Diffie–Hellman implementations. Given a generator, two positive private exponents, and a prime modulus, it computes Alice's public value and then raises that value to Bob's exponent modulo the same prime. This is distinct from one modular-exponentiation call because the contract models the exchange between two parties.

The benchmark excludes random secret generation, predefined large-group selection, public-key text encodings, the Python/Rust public-key subgroup check, and the Python SHA-256 wrapper. It returns the shared integer itself, so it makes no security claim and is intended only for algorithm benchmarking.

## Contract

Input is `[generator, alice_secret, bob_secret, prime]`, all signed 64-bit integers. Require `2 <= prime <= 6,700,417`, require `prime` to be prime, and require each of the other three values to be in `[1, prime - 1]`. Invalid input or a malformed array returns `-1`. The result is `pow(pow(generator, alice_secret, prime), bob_secret, prime)`, in `[0, prime)`. Products are below `4.5 × 10^13`, and trial division validates primality in at most 2,588 steps. The bound includes the fixed prime used by the Go key-exchange source.

## Reproduce

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm diffie_hellman --language c
python3 benchmarks/run_i64_array_scalar.py --algorithm diffie_hellman
python3 benchmarks/verify_diffie_hellman.py
```

Upstream references: [Go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/cipher/diffiehellman/diffiehellmankeyexchange.go), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/DiffieHellman.java), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/diffie_hellman.py), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/diffie_hellman.rs).

# Palindrome

This benchmark checks whether an exact ASCII sequence reads the same from both ends. The upstream filename covers different contracts: C checks an integer, Java and Python include exact string checks, and Rust's string function ignores non-alphanumeric characters and ASCII case. This benchmark uses the exact string variant.

## Contract

The input is an array of ASCII code points, with at most 4,096 values in `[0, 127]`. The result is `1` when the sequence is an exact palindrome and `0` otherwise. Case, spaces, punctuation, and control characters are significant. Empty input is a palindrome. Invalid values or oversized arrays return `-1`.

Each implementation first validates the full input, then compares mirrored values. It uses O(n) time and O(1) extra space.

## Reproduce

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm palindrome --language c
python3 benchmarks/run_i64_array_scalar.py --algorithm palindrome
python3 benchmarks/verify_palindrome.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```

The verifier checks every sequence through length six over a small alphabet, deterministic random and boundary cases, malformed values, size limits, and all published workloads.

Upstream references: [Java exact string methods](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/Palindrome.java), [Python exact string variants](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/palindrome.py), [Rust normalized string variant](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/palindrome.rs), and [C numeric variant](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/palindrome.c).

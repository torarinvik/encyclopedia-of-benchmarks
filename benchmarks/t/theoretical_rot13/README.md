# Theoretical ROT13

This variant rotates lowercase ASCII letters `a` through `z` by thirteen places. Uppercase letters, punctuation, digits, and other ASCII values are copied unchanged. Inputs are at most 66 non-NUL 7-bit ASCII values (`1` through `127`); invalid values return `-1`, and an output buffer that is too small returns `-2`.

The benchmark follows the pinned Rust `theoretical_rot13` source and uses the shared `i64_array_bytes_output` ABI. It is distinct from the standard case-preserving [ROT13 benchmark](../rot13/README.md), which rotates both uppercase and lowercase letters. All nine ports passed 16,758 oracle inputs per language and recorded 10 workload cases. Run `python3 benchmarks/verify_rot13.py --algorithms theoretical_rot13` to check all nine language ports.

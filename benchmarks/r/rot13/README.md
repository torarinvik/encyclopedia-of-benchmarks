# ROT13

ROT13 rotates ASCII letters by thirteen places. The benchmark preserves letter case, leaves other ASCII values unchanged, and treats input and output as same-length byte sequences. The accepted input is at most 66 non-NUL 7-bit ASCII values (`1` through `127`); invalid values return `-1`, and a too-small output buffer returns `-2`.

The pinned C, Go, JavaScript, and Python implementations preserve case. The pinned Rust `rot13` implementation uppercases the input first, while Rust's `another_rot13` implements the case-preserving mapping. The shared contract follows the standard case-preserving operation; the lower-case-only `theoretical_rot13` candidate remains distinct. `another_rot13` is recorded as an alias because it implements the same mapping.

The workload covers empty input, both alphabets, wraparound, mixed text, punctuation and digits, the maximum input length, and invalid byte values. The portable implementations use the `i64_array_bytes_output` ABI. Each variant passed 16,758 oracle inputs per language and recorded 10 workload cases. Run `python3 benchmarks/verify_rot13.py` to check both ROT13 variants across all nine languages.

## Upstream references

- [C `rot13.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/cipher/rot13.c)
- [Go `rot13.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/cipher/rot13/rot13.go)
- [JavaScript `ROT13.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Ciphers/ROT13.js)
- [Python `rot13.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/rot13.py)
- [Rust `rot13.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/rot13.rs)
- [Rust `another_rot13.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/another_rot13.rs)
- [Rust `theoretical_rot13.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/theoretical_rot13.rs)

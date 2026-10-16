# ChaCha20 block function

This benchmark implements the pinned Rust source's ChaCha20 block function. It accepts exactly sixteen state words, each represented as a signed 64-bit input in the unsigned 32-bit range. The function performs ten column/diagonal double rounds with 32-bit wrapping arithmetic, adds the initial state, and writes the resulting sixteen words as 64 little-endian bytes. This measures the block core, without key or nonce parsing or stream handling.

Inputs with the wrong length or an out-of-range word return `-1`. A valid input with fewer than 64 output bytes returns `-2`; success returns `64`.

The RFC 8439 block test vector is included as a fixed workload case. The pinned upstream implementation is [TheAlgorithms/Rust `chacha.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/chacha.rs).

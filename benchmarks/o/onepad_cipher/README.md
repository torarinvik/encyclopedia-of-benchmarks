# Onepad cipher

Reproduce the pinned Python `Onepad` arithmetic transform with a fixed key supplied by the workload. For each character code point `p` and key integer `k`, encryption computes `(p + k) * k`. Decryption recovers `p` from the ciphertext and key.

## Contract

- Input is `[mode, length, data..., key...]`, with equal `length`-element data and key arrays. Mode `0` encrypts plaintext code points; mode `1` decrypts ciphertext integers.
- Length is `0..1024`; plaintext and decrypted text are printable ASCII code points `32..126`; each key value is `1..300`, matching the inclusive range used by Python's `random.randint(1, 300)`.
- The benchmark supplies the key explicitly so random key generation is outside the measured transform. Encryption outputs each ciphertext integer as eight little-endian bytes. Decryption outputs the recovered ASCII text bytes.
- Invalid mode, shape, character, key, or ciphertext returns `-1`; insufficient output capacity returns `-2`.
- The bounded arithmetic uses constant space and takes `O(n)` time.

The Python source encrypts a string with freshly generated per-character keys and returns both ciphertext and key arrays. Its decrypt method consumes those arrays and iterates over key length. This workload fixes the random key as input and requires equal data and key lengths to make both operations deterministic and well-defined.

## Relationship to other ciphers

This is the Python source's multiply-and-add arithmetic transform. It is separate from [`vernam_cipher`](../../v/vernam_cipher/README.md), which repeats a key over uppercase letters and adds modulo 26, and from `one_time_pad_cipher`, which XORs byte arrays.

## Workload and recording

The cases cover empty input, the pinned `Hello` example, punctuation, both transform directions, malformed arrays, and invalid key or text values. All nine ports use `i64_array_bytes_output`.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm onepad_cipher --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/o/onepad_cipher/rust/build.json
```

## Pinned source

- [Python `onepad_cipher.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/onepad_cipher.py)
- [Vernam cipher contract](../../v/vernam_cipher/README.md)
- [Bytewise one-time pad contract](../one_time_pad_cipher/README.md)

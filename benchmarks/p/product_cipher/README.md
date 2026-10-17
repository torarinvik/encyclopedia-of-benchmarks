# Product Cipher

This benchmark implements the final ciphertext transform from the pinned Java ProductCipher demonstration. It applies the source's character shift and slash padding, then emits the padded text column by column. Console prompts, matrix display, and the demonstration's reverse/decryption transcript are omitted.

## Contract

The i64_array_bytes_output input is a signed 64-bit array:

    [n, text_length, byte_0, ..., byte_(text_length-1)]

The length must be exactly 2 + text_length. n is 1 through 64; text_length is 0 through 256. Each input byte is ASCII 0 through 127, except CR (13) and LF (10), which Scanner.nextLine() treats as line separators. ASCII DEL (127) is valid.

Each input byte represents one Java UTF-16 code unit. The source adds 5 to every code unit, then appends '/' (byte 47) until the shifted text length is divisible by n. It emits padded[i + j*n] for i from 0 through n-1 and j from 0 through padded_length/n-1. Output bytes store the numeric code unit values directly; this avoids platform-dependent UTF-8 encoding. Shifted bytes range from 5 through 132.

The result is the number of ciphertext bytes written. Empty text returns 0 and writes nothing, including when output is null or has zero capacity. For nonempty text, null or insufficient output capacity returns -2 without writes. Invalid input returns -1. The maximum valid input has 258 values; the parser limit is 259. Maximum padded output is 315 bytes, reached with n=63 and text_length=256.

## Workload and oracle

The shared workload covers shift and transposition ordering, slash padding, n larger than the text, control bytes, DEL, the maximum input/output bounds, malformed input, CR/LF rejection, and insufficient output capacity. The independent reference implementation is benchmarks/product_cipher_oracle.py.

Build an implementation and its ABI checker with:

    python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm product_cipher --language rust --with-checker

## Implementations

| Language | Source |
| --- | --- |
| C | c/p/product_cipher.c |
| C3 | c3/p/product_cipher.c3 |
| C++ | cpp/p/product_cipher.cpp |
| Elisa | elisa/p/product_cipher.elisa |
| Nim | nim/p/product_cipher.nim |
| Odin | odin/p/product_cipher.odin |
| Rust | rust/p/product_cipher.rs |
| V | v/p/product_cipher.v |
| Zig | zig/p/product_cipher.zig |

## Related benchmarks

This is distinct from caesar_cipher, which rotates English letters and leaves other ASCII bytes unchanged. transposition_cipher uses the Python keyed-stride route transform, returns the original length, and does not slash-pad. columnar_transposition reads unpadded ragged columns in the sorted order of a letter key.

## Reviewed source

The source is [TheAlgorithms/Java ProductCipher.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/ProductCipher.java) at commit e43ec3897e48f23843972d02cd05a5bb1b6864a2.

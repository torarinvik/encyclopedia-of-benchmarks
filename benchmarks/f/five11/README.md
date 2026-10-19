# BitBench five11

`five11` decodes BitBench's packet stream and sums every 11-bit channel value. The stream starts with an unsigned 16-bit, most-significant-bit-first packet count. Each packet has a 5-bit channel count, that many 11-bit unsigned values, then enough ignored pad bits to reach the next byte boundary. Bits are read most-significant first. The source ignores bytes after the declared packet records, including the tail of its supplied fixture.

The bounded `i64_array_scalar` input is a signed 64-bit array containing byte values in `[0, 255]`. It must contain at least the two-byte packet count, may contain at most 13,523 bytes, and declares at most 451 packets. Truncated packet fields are invalid and return `-1`; invalid byte values and larger inputs also return `-1`. Trailing bytes are accepted and ignored after the final padded packet. The result is the sum of the decoded values, from 0 through 28,619,107.

The launcher passes the binary `input-file`, which is preserved in this package. It declares 451 packets, occupies 13,523 bytes, and decodes to the pinned reference result `2003051`; the decoder consumes 6,392 bytes and ignores the rest. The source repeats decode-and-sum 10,000 times before printing the final sum. Each port retains those 10,000 passes while accumulating the channel values directly.

The independent Python oracle is [`benchmarks/five11_oracle.py`](../../five11_oracle.py). The pinned source and launcher are [`five11.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BitBench/five11/five11.c) and [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BitBench/five11/info.sh) at revision `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`.

Build a port with the `i64_array_scalar` ABI family, for example:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm five11 --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/f/five11/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms five11 --languages rust
```

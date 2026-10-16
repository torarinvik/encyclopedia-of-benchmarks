# Simple Blockchain

This package benchmarks the pinned [TheAlgorithms/Python blockchain source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/blockchain/simple_blockchain.py). It deterministically creates and mines the genesis block and up to seven linked blocks, then applies the source `Blockchain.is_valid` checks to the completed chain.

For each block, the SHA-256 preimage is the UTF-8 encoding of the exact separator-free concatenation `index + timestamp + data + previous_hash + nonce`. The timestamp is an integer-second input converted to Python float text (`N.0`). Genesis is index `0`, data `Genesis Block`, previous hash `0`; each later index and previous hash are derived from its position and the preceding digest. Mining tests nonce values `0` through `4095`, in order, and accepts the first digest with the requested one or two leading zeroes. The source validator starts at block 1, checking the previous-hash link, difficulty prefix, and recomputed current hash; it does not validate the genesis block.

## ABI

All nine ports use `i64_array_bytes_output`. The input is the signed-i64 vector:

```text
[difficulty, chain_len, genesis_timestamp_sec,
 (timestamp_sec, data_len, ASCII_byte...)* (chain_len - 1)]
```

`chain_len` includes genesis and is 1 through 8. Timestamps are 0 through 2,147,483,647. Each later block has 0 through 64 data bytes, each in 0 through 127. Input must be consumed exactly. The largest valid input contains 465 signed-i64 values, or 3,720 packed bytes.

On success, the output buffer contains these fields in order: status `0` as signed little-endian i64; `chain_len` as signed little-endian i64; then, for every block, its index, timestamp seconds, and nonce as signed little-endian i64 values followed by its 64 lowercase hexadecimal hash bytes; finally, the source validation result (`1`) as signed little-endian i64. The function returns the output byte count, which is `24 + 88 * chain_len` and at most 728 bytes. An invalid input returns `-1`; an insufficient output buffer returns `-2`; exhausting all 4,096 nonce attempts for any block returns `-3`. Error results write no output bytes. The entire chain is built and validated in local storage before the capacity check and any output write.

See [`workload.json`](workload.json) for bounds, cases, and buffer sizes. The independent oracle is [`simple_blockchain_oracle.py`](../../simple_blockchain_oracle.py).

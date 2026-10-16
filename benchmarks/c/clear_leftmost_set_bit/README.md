# Clear leftmost set bit

Clears the highest set bit of a nonnegative 32-bit integer.

## Contract

- Uses the unary scalar ABI: `int64_t clear_leftmost_set_bit(int64_t value)`.
- Inputs in `[0, 2,147,483,647]` are accepted. Values outside that range return `-1`.
- Returns the input with its highest set bit cleared. Zero returns zero.
- Results stay in the input range and fit signed 64-bit.

## Source semantics

The benchmark follows pinned [TheAlgorithms Java `ClearLeftmostSetBit.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/ClearLeftmostSetBit.java). The method scans a positive integer right until zero, counts its bit width, builds `~(1 << (width - 1))`, and ANDs that mask with the input. For zero, Java masks the negative shift distance to 31, but the resulting AND still returns zero; the ports handle that case directly. The source accepts Java `int`, and this benchmark restricts inputs to the nonnegative int32 range where the documented scan has the same meaning. Negative and wider ABI inputs map to `-1`.

## Workload and build

[`workload.json`](workload.json) covers zero, single-bit and mixed-bit values, the int32 limit, and invalid inputs. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm clear_leftmost_set_bit --language c
python3 benchmarks/run_scalar.py --build-manifest build/scalar/c/clear_leftmost_set_bit/c/build.json
```

Verify the nine ports against the independent bit-mask oracle with
`python3 benchmarks/verify_scalar.py --algorithms clear_leftmost_set_bit`.

The nine implementations are in `c/c/clear_leftmost_set_bit.c`, `c3/c/clear_leftmost_set_bit.c3`, `cpp/c/clear_leftmost_set_bit.cpp`, `elisa/c/clear_leftmost_set_bit.elisa`, `nim/c/clear_leftmost_set_bit.nim`, `odin/c/clear_leftmost_set_bit.odin`, `rust/c/clear_leftmost_set_bit.rs`, `v/c/clear_leftmost_set_bit.v`, and `zig/c/clear_leftmost_set_bit.zig`.

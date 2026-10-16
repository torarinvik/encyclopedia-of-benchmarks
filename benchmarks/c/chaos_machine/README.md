# Chaos machine

The pinned Python module combines a five-element logistic map with a xorshift generator. Its state persists between `push()` and `pull()` calls, and the command-line example supplies random seeds. This benchmark resets the machine per invocation and passes the seeds and pull count as input, making each workload deterministic.

## Contract

- The `i64_array_bytes_output` ABI accepts `[seed_count, seed_0, ..., seed_(n-1), pull_count]`. `seed_count` is from 0 through 64, each seed is from 0 through 1,000,000, and `pull_count` is from 0 through 64.
- Seeds update the five buffer and parameter entries sequentially, preserving the source's in-place logistic-map transitions. Every transition rounds to ten decimal places using ties-to-even, matching Python's `round(value, 10)` on IEEE-754 binary64 values.
- Each pull performs three logistic-map transitions, applies the source xorshift steps, and returns the low 32 bits. Results are encoded as four little-endian bytes per pull.
- Invalid input returns `-1`; insufficient output capacity returns `-2` without writing. A successful call returns the number of bytes written, up to 256.

[`workload.json`](workload.json) includes reset-state pulls, one and multiple seeds, zero pulls, maximum state and output sizes, invalid inputs, and an output-capacity failure. The verifier checks 329 oracle inputs and all 14 workload cases. All nine language ports passed. The rounding helper uses integer arithmetic over the binary64 representation; it needs no CPU-specific instructions.

```sh
python3.12 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm chaos_machine --language rust
python3.12 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/c/chaos_machine/rust/build.json
python3.12 benchmarks/verify_i64_array_bytes_output.py --algorithm chaos_machine
```

| Language | Source |
| --- | --- |
| C | [`c/c/chaos_machine.c`](../../../c/c/chaos_machine.c) |
| C3 | [`c3/c/chaos_machine.c3`](../../../c3/c/chaos_machine.c3) |
| C++ | [`cpp/c/chaos_machine.cpp`](../../../cpp/c/chaos_machine.cpp) |
| Elisa | [`elisa/c/chaos_machine.elisa`](../../../elisa/c/chaos_machine.elisa) |
| Nim | [`nim/c/chaos_machine.nim`](../../../nim/c/chaos_machine.nim) |
| Odin | [`odin/c/chaos_machine.odin`](../../../odin/c/chaos_machine.odin) |
| Rust | [`rust/c/chaos_machine.rs`](../../../rust/c/chaos_machine.rs) |
| V | [`v/c/chaos_machine.v`](../../../v/c/chaos_machine.v) |
| Zig | [`zig/c/chaos_machine.zig`](../../../zig/c/chaos_machine.zig) |

## TheAlgorithms reference

- [Python `chaos_machine.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/hashes/chaos_machine.py)

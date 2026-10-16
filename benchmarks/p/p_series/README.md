# P-series

The pinned Python `p_series(nth_term, power)` converts both inputs to integers and returns a list of strings: `"1"`, then `"1 / k^power"` for each `k` from 2 through `nth_term`. Nonpositive term counts return an empty list. The source's special empty-string input and Python-only conversion behavior are outside this bounded integer-array ABI.

## Contract

- The `i64_array_bytes_output` ABI accepts exactly `[nth_term, power]`.
- `nth_term` is bounded to -256 through 256, and `power` to 0 through 7. Out-of-range values or the wrong array length return `-1`.
- Nonpositive `nth_term` returns zero output bytes. Positive inputs emit each source list item as one ASCII line, including the source spacing around `/`; for example, `[5, 2]` emits `1\n1 / 4\n1 / 9\n1 / 16\n1 / 25\n`.
- A positive input requires enough output capacity for the full byte sequence. Insufficient capacity returns `-2` without writing. The maximum bounded output is 4,953 bytes.

[`workload.json`](workload.json) covers empty and one-term series, powers zero and seven, multi-digit denominators, the maximum term count, invalid inputs, and a one-byte-short output-capacity case.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm p_series --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/p/p_series/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm p_series
```

| Language | Source |
| --- | --- |
| C | [`c/p/p_series.c`](../../../c/p/p_series.c) |
| C3 | [`c3/p/p_series.c3`](../../../c3/p/p_series.c3) |
| C++ | [`cpp/p/p_series.cpp`](../../../cpp/p/p_series.cpp) |
| Elisa | [`elisa/p/p_series.elisa`](../../../elisa/p/p_series.elisa) |
| Nim | [`nim/p/p_series.nim`](../../../nim/p/p_series.nim) |
| Odin | [`odin/p/p_series.odin`](../../../odin/p/p_series.odin) |
| Rust | [`rust/p/p_series.rs`](../../../rust/p/p_series.rs) |
| V | [`v/p/p_series.v`](../../../v/p/p_series.v) |
| Zig | [`zig/p/p_series.zig`](../../../zig/p/p_series.zig) |

## TheAlgorithms reference

- [Python `p_series.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/series/p_series.py)

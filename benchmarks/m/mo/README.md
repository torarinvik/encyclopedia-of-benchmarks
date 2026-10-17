# Mo's distinct range queries

This benchmark ports the offline range-query program in both pinned C++ sources. It preserves their query ordering and frequency-count algorithm, while replacing console input/output with the benchmark ABI.

## Contract

- The ABI is `i32_array_bytes_output`. Input is `[n, values[n], q, (left, right)*q]` as signed-i32 words, with exactly `2 + n + 2*q` words. `n` is 1–64, values are 0–255, and `q` is 0–64. Every query uses the source's 1-based inclusive bounds and must satisfy `1 <= left <= right <= n`.
- The source chooses `ceil(sqrt(n))` as its block size, sorts queries by left block and then ascending right endpoint, and moves a half-open active window while updating per-value frequencies. Each answer is the number of distinct values in its query. Answers are restored to input query order; equivalent sort keys do not affect the answer values. The source keeps frequency, answer, and result arrays in globals, so the benchmark resets them for each independent call.
- Output contains exactly `q` distinct-count values as raw little-endian signed-i32 bytes, with no count prefix. Success returns the output byte length; the maximum is 256 bytes. With `q=0`, a non-null output pointer and capacity 0 succeed with an empty output and result 0.
- Malformed, out-of-range, or null input returns `-1` before output checks. A null output pointer or capacity below `4*q` returns `-2` without writes, including when `q=0`; the zero-query success case still requires a non-null pointer. The largest valid input is 194 words; one extra word is allowed for malformed-input parsing.

The workload covers repeated values, singleton and full-array queries, block boundaries, queries that sort differently from input order, the zero-query case, maximum input/output, malformed bounds and framing, and output-buffer errors. See [workload.json](workload.json) and the independent [oracle](../../mo_oracle.py).

The source files are [TheAlgorithms/C-Plus-Plus `mo.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/range_queries/mo.cpp) and the matching [TheAlgorithms/C-Plus-Plus-1 `mo.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/range_queries/mo.cpp). Both are pinned at their respective commits; the C-Plus-Plus-1 copy has the same algorithm and relies on transitive headers in its standalone source.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i32_array_bytes_output --algorithm mo --language rust
python3 benchmarks/run_i32_array_bytes_output.py --build-manifest build/i32_array_bytes_output/m/mo/rust/build.json
python3 benchmarks/verify_i32_array_bytes_output.py --algorithm mo --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/m/mo.c](../../../c/m/mo.c) |
| C3 | [c3/m/mo.c3](../../../c3/m/mo.c3) |
| C++ | [cpp/m/mo.cpp](../../../cpp/m/mo.cpp) |
| Elisa | [elisa/m/mo.elisa](../../../elisa/m/mo.elisa) |
| Nim | [nim/m/mo.nim](../../../nim/m/mo.nim) |
| Odin | [odin/m/mo.odin](../../../odin/m/mo.odin) |
| Rust | [rust/m/mo.rs](../../../rust/m/mo.rs) |
| V | [v/m/mo.v](../../../v/m/mo.v) |
| Zig | [zig/m/mo.zig](../../../zig/m/mo.zig) |

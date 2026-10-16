# Proper fractions

The pinned Python `proper_fractions(denominator)` returns the reduced proper fractions for one denominator, in ascending numerator order. This bounded integer-array ABI represents each list item as one ASCII line. Negative denominators raise a source `ValueError`; the benchmark maps invalid ABI inputs to `-1`.

## Contract

- The `i64_array_bytes_output` ABI accepts exactly `[denominator]`, with denominator in 0 through 256. Invalid length or bounds return `-1`.
- Denominators 0 and 1 return an empty byte string. For a positive denominator `d`, emit `n/d\n` for each `1 <= n < d` whose greatest common divisor with `d` is 1, preserving ascending numerator order.
- Insufficient output capacity returns `-2` without writing. The largest bounded output is 1,892 bytes.

[`workload.json`](workload.json) covers empty results, prime and composite denominators, the largest output, capacity failure, and invalid inputs.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm proper_fractions --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/p/proper_fractions/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm proper_fractions
```

| Language | Source |
| --- | --- |
| C | [`c/p/proper_fractions.c`](../../../c/p/proper_fractions.c) |
| C3 | [`c3/p/proper_fractions.c3`](../../../c3/p/proper_fractions.c3) |
| C++ | [`cpp/p/proper_fractions.cpp`](../../../cpp/p/proper_fractions.cpp) |
| Elisa | [`elisa/p/proper_fractions.elisa`](../../../elisa/p/proper_fractions.elisa) |
| Nim | [`nim/p/proper_fractions.nim`](../../../nim/p/proper_fractions.nim) |
| Odin | [`odin/p/proper_fractions.odin`](../../../odin/p/proper_fractions.odin) |
| Rust | [`rust/p/proper_fractions.rs`](../../../rust/p/proper_fractions.rs) |
| V | [`v/p/proper_fractions.v`](../../../v/p/proper_fractions.v) |
| Zig | [`zig/p/proper_fractions.zig`](../../../zig/p/proper_fractions.zig) |

## TheAlgorithms reference

- [Python `proper_fractions.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/numerical_analysis/proper_fractions.py)

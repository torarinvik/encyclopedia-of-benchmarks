# Padovan sequence

Computes the indexed term of the Padovan sequence with the iterative recurrence used by the pinned sources.

## Contract

- Uses the unary scalar ABI: `int64_t padovan_sequence(int64_t index)`.
- Indices in `[0, 156]` are accepted. Values outside that range return `-1`.
- Returns `P(0)=P(1)=P(2)=1` and `P(n)=P(n-2)+P(n-3)` for `n >= 3`.
- `P(156) = 8,125,799,229,398,355,841` fits signed 64-bit; `P(157) = 10,764,392,156,149,521,358` exceeds `INT64_MAX`.

## Source semantics

The benchmark follows pinned [TheAlgorithms Java `PadovanSequence.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PadovanSequence.java) and [TheAlgorithms Python `padovan_sequence.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/padovan_sequence.py). Both use the same seeds and recurrence. Java rejects negative indices and returns a signed `long`; Python rejects negative indices and uses arbitrary-precision integers. The benchmark maps invalid indices to `-1` and limits valid terms to the largest index whose result fits signed 64-bit, avoiding Java overflow at index 157.

The related `perrin_number` benchmark has the same recurrence but different seeds (`3, 0, 2`), so it computes a distinct sequence.

## Workload and build

[`workload.json`](workload.json) covers seed values, representative later terms, the signed 64-bit boundary, and invalid indices. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm padovan_sequence --language c
python3 benchmarks/run_scalar.py --build-manifest build/scalar/p/padovan_sequence/c/build.json
```

The nine implementations are in `c/p/padovan_sequence.c`, `c3/p/padovan_sequence.c3`, `cpp/p/padovan_sequence.cpp`, `elisa/p/padovan_sequence.elisa`, `nim/p/padovan_sequence.nim`, `odin/p/padovan_sequence.odin`, `rust/p/padovan_sequence.rs`, `v/p/padovan_sequence.v`, and `zig/p/padovan_sequence.zig`.

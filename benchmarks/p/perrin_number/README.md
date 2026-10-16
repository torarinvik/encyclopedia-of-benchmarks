# Perrin number

Computes the indexed term of the Perrin sequence using its iterative recurrence.

## Contract

- Uses the unary scalar ABI: `int64_t perrin_number(int64_t index)`.
- Indices in `[0, 155]` are accepted. Values outside that range return `-1`.
- Returns the sequence with `P(0)=3`, `P(1)=0`, `P(2)=2`, and `P(n)=P(n-2)+P(n-3)` for `n >= 3`.
- `P(155) = 8,494,359,425,057,768,732` fits signed 64-bit; `P(156) = 11,252,630,465,665,182,714` exceeds `INT64_MAX`.

## Source semantics

The benchmark follows pinned [TheAlgorithms Java `PerrinNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PerrinNumber.java). Its `perrin` method returns the nth term with initial values `3, 0, 2` and then adds the terms two and three places earlier. The related Padovan sequence uses the same recurrence but different initial values, so it is a distinct sequence. The Java source rejects negative indices; this benchmark maps negative and above-bound inputs to `-1` and bounds the result to signed 64-bit.

## Workload and build

[`workload.json`](workload.json) covers the initial terms, representative later terms, the signed 64-bit boundary, and invalid indices. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm perrin_number --language c
python3 benchmarks/run_scalar.py --build-manifest build/scalar/p/perrin_number/c/build.json
```

The nine implementations are in `c/p/perrin_number.c`, `c3/p/perrin_number.c3`, `cpp/p/perrin_number.cpp`, `elisa/p/perrin_number.elisa`, `nim/p/perrin_number.nim`, `odin/p/perrin_number.odin`, `rust/p/perrin_number.rs`, `v/p/perrin_number.v`, and `zig/p/perrin_number.zig`.

Verify the nine ports against the independent indexed-recurrence oracle with `python3 benchmarks/verify_scalar.py --algorithms perrin_number`.

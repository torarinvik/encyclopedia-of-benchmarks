# FreeBench Hopfield neural network

This benchmark ports the default FreeBench path for an associative-memory
Hopfield network: decode bipolar patterns, form the off-diagonal Hebbian
weight matrix, apply continuous delta learning at rate `0.5`, then check which
patterns are recalled. The source's default sequence is `readvector`,
`checkham`, `generateT(MODE_ALL)`, `delta(0.5)` with continuous neurons, and
`storecheck`.

## Bounded contract

- ABI: `i64_array_scalar`, symbol `freebench_neural_hopfield`.
- Input is `[width, height, pattern_count, (label, cell*)*]`. There are exactly
  10 patterns. Each record has an uppercase ASCII label and `width*height`
  cells in source row-major order; `1` corresponds to `X`, and `-1` to `.`.
- Dimensions are each 1 through 8, and the neuron count is 2 through 8.
  Every pattern must be identical and bipolar. This is an intentionally
  convergence-proven subdomain of the source behavior. For a shared vector
  `p`, the Hebbian matrix produces field `10*(N-1)*p[i]` at each neuron, with
  magnitude at least 10. The source continuous recall therefore returns the
  same signs on the first outer iteration; delta corrections are all zero,
  so training exits after one pass. `storecheck` marks all 10 patterns stored.
- The pinned `test.in` uses distinct patterns, and the source `delta` loop has
  no iteration bound. Static inspection does not establish that profile's
  termination, so the bounded workload accepts the repeated-pattern domain
  with the one-pass convergence proof above.
- The result is the number of stored patterns, 10 for valid inputs. Invalid
  framing, dimensions, labels, cells, or nonidentical patterns return `-1`.
  A defensive `-2` is reserved for an unexpected failure to converge within
  the one-pass bound; the accepted domain proves that branch unreachable.
- The nine ports still execute the source-ordered Hebbian matrix build,
  continuous recall, delta update, and final store check. The independent
  oracle validates the convergence invariant directly instead of reproducing
  the ports' float32 matrix loops.

## Workload and build

[`workload.json`](workload.json) includes two- and eight-neuron profiles,
mixed bipolar signs, and malformed headers, records, and labels. The verifier
also generates deterministic repeated-pattern cases and malformed cells,
extra values, and inter-pattern mismatches within the same bounded domain.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm freebench_neural_hopfield --language rust --with-checker
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/f/freebench_neural_hopfield/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms freebench_neural_hopfield --languages rust
```

## Provenance and rights

The pinned `neural.c` header identifies “(C) 1996, 2001 Fredrik Warg” and says
the program began as a neural-networks course assignment and was modified for
FreeBench. The pinned directory contains no separate `LICENSE` file, and the
header contains no redistribution grant. No upstream license is inferred.
These ports and the oracle are independently written from the observed
algorithm and do not copy the C implementation or its letter-pattern data.

- [`neural.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/neural/neural.c)
- [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/neural/info.sh)

## Language ports

| Language | Source |
| --- | --- |
| C | [c/f/freebench_neural_hopfield.c](../../../c/f/freebench_neural_hopfield.c) |
| C3 | [c3/f/freebench_neural_hopfield.c3](../../../c3/f/freebench_neural_hopfield.c3) |
| C++ | [cpp/f/freebench_neural_hopfield.cpp](../../../cpp/f/freebench_neural_hopfield.cpp) |
| Elisa | [elisa/f/freebench_neural_hopfield.elisa](../../../elisa/f/freebench_neural_hopfield.elisa) |
| Nim | [nim/f/freebench_neural_hopfield.nim](../../../nim/f/freebench_neural_hopfield.nim) |
| Odin | [odin/f/freebench_neural_hopfield.odin](../../../odin/f/freebench_neural_hopfield.odin) |
| Rust | [rust/f/freebench_neural_hopfield.rs](../../../rust/f/freebench_neural_hopfield.rs) |
| V | [v/f/freebench_neural_hopfield.v](../../../v/f/freebench_neural_hopfield.v) |
| Zig | [zig/f/freebench_neural_hopfield.zig](../../../zig/f/freebench_neural_hopfield.zig) |

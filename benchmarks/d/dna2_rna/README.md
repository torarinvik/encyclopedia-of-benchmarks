# DNA to RNA transcription

Convert an uppercase ASCII sequence to RNA by replacing each `T` with `U` and preserving every other letter. This follows TheAlgorithms/Julia's `dna2rna` candidate.

## Contract

- Input is `[mode, byte...]`, with total length 1 through 1001. The only accepted mode is `0`; the payload is at most 1000 ASCII bytes.
- The payload may contain uppercase ASCII letters `A` through `Z`, allowing source symbols such as `N` to pass through. Empty input is valid. Invalid modes, bytes, or lowercase/nonletter symbols return `-1`.
- Output has the same number of bytes. `T` becomes `U`; every other accepted letter is preserved. Output is length-delimited without a terminating NUL. Insufficient output capacity returns `-2`.
- The Julia function itself applies replacement to any string; this benchmark bounds its input to uppercase ASCII so all ports share one byte-level contract.
- This direct replacement is distinct from `rna_transcription`, which complements the input bases, and from `dna`, which returns the complementary DNA strand.

## Workload

[`workload.json`](workload.json) covers the empty sequence, the pinned source mapping, unchanged bases, preserved uppercase symbols, a longer sequence, invalid input, and an unsupported mode. The nine ports use the shared `i64_array_bytes_output` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm dna2_rna --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/d/dna2_rna/rust/build.json
```

## Reviewed source

- [Julia `dna2_rna.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/project_rosalind/dna2_rna.jl)

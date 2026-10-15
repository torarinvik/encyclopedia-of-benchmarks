# DNA strand complement

Return the second DNA strand by complementing each nucleotide: `A ↔ T` and `C ↔ G`. This follows TheAlgorithms/Python's `dna` candidate.

## Contract

- Input is `[mode, byte...]`, with total length 1 through 1001. The only accepted mode is `0`; the payload is at most 1000 ASCII bytes.
- The payload may contain only uppercase `A`, `C`, `G`, and `T`. Empty input is valid. Invalid modes, bytes, or symbols return `-1`.
- Output is the same number of bytes, with `A → T`, `T → A`, `C → G`, and `G → C`. Output is length-delimited without a terminating NUL. Insufficient output capacity returns `-2`.
- This is distinct from `rna_transcription`, which emits RNA bases (`A → U`, `T → A`, `C → G`, `G → C`), and from `dna2_rna`, which only changes `T` to `U`.

## Workload

[`workload.json`](workload.json) covers the empty strand, the pinned source examples, all four nucleotide mappings, a longer sequence, malformed symbols and byte values, and an unsupported mode. The nine ports use the shared `i64_array_bytes_output` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm dna --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/d/dna/rust/build.json
```

## Reviewed source

- [Python `dna.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/dna.py)

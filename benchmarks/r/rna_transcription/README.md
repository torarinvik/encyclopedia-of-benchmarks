# RNA transcription

Transcribe a bounded uppercase DNA sequence into its complementary RNA sequence. This follows the `to_rna` mapping in TheAlgorithms/C: `A → U`, `C → G`, `G → C`, and `T → A`.

## Contract

- Input is `[mode, byte...]`, with total length 1 through 1001. The only accepted mode is `0`; the payload is at most 1000 ASCII bytes.
- The payload may contain only uppercase `A`, `C`, `G`, and `T`. Empty input is valid. Invalid modes, bytes, or symbols return `-1`.
- Output is the same number of bytes, using the mapping above. Output is length-delimited and has no terminating NUL. Insufficient output capacity returns `-2`.
- The C candidate's switch leaves other symbols unwritten and returns an allocated buffer without appending a NUL. This benchmark normalizes those behaviors into strict validation and an explicit byte count.

## Related candidates

The similarly named candidates have different mappings and remain separate algorithms: Python's `dna` returns the complementary DNA strand (`A ↔ T`, `C ↔ G`), while Julia's `dna2rna` replaces only `T` with `U` and preserves the other symbols. Neither is an alias of this complementary DNA-to-RNA transcription.

- [C `rna_transcription.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/exercism/rna_transcription/rna_transcription.c)
- [Python `dna.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/dna.py)
- [Julia `dna2_rna.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/project_rosalind/dna2_rna.jl)

## Workload

[`workload.json`](workload.json) covers the empty sequence, the Python `dna` examples' shared inputs (which also distinguish the mappings), each nucleotide, a longer strand, lowercase and ambiguous symbols, invalid byte values, and an unsupported mode. The nine ports use the shared `i64_array_bytes_output` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm rna_transcription --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/r/rna_transcription/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm rna_transcription --languages rust
```

# Reverse complement

Reverse a DNA sequence and complement every nucleotide. This is the Julia Rosalind operation `map(x -> rules[x], reverse(s))`, with `A ↔ T` and `C ↔ G`.

## Contract

- Input is a byte array containing an uppercase DNA sequence of at most 1,000 bases. Only `A`, `C`, `G`, and `T` are accepted; the empty sequence is valid.
- Output is the reverse complement: reverse the sequence order, then apply the DNA complement mapping. The output has the same byte length.
- Invalid lengths or symbols return `-1`; insufficient output capacity returns `-2`. Output is length-delimited and has no terminating NUL.

This operation remains distinct from the existing benchmarks: `reverse_string_in_place` reverses arbitrary bytes without complementing them; `rna_transcription` preserves sequence order while mapping DNA bases to complementary RNA (`A → U`, `C → G`, `G → C`, `T → A`); and Python's `dna` candidate complements a DNA strand without reversing it. Reverse complement performs both reverse and DNA complement.

The pinned Julia source documents a 1,000-base input bound and uses a dictionary lookup, which fails on symbols outside `A/C/G/T`. This contract makes that alphabet explicit and returns `-1` for invalid symbols.

## Workload

[`workload.json`](workload.json) covers empty input, each base, complement pairs, a standard longer sequence, maximum length, lowercase, ambiguous and RNA symbols, out-of-range values, and length overflow.

## Reviewed sources

- [Julia `reverse_complement.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/project_rosalind/reverse_complement.jl)
- [C `reverse_string_in_place.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/344.c)
- [C `rna_transcription.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/exercism/rna_transcription/rna_transcription.c)
- [Python `dna.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/dna.py)

Build with the `i64_array_bytes_output` ABI family and record with `benchmarks/run_i64_array_bytes_output.py`.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm reverse_complement --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm reverse_complement
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm reverse_complement --languages rust
```

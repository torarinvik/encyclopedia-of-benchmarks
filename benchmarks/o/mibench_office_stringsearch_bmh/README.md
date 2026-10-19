# MiBench office-stringsearch: case-sensitive BMH stage

This package implements the case-sensitive `bmh_init` / `bmh_search` Boyer-Moore-Horspool matcher from pinned `bmhsrch.c`. The pinned header calls this implementation public domain and credits Raymond Gardner (July 1992). The full launcher compiles three other search implementations as well (`bmhasrch.c`, `bmhisrch.c`, and `pbmsrch.c`), with a separate demonstration workload; this package covers only the selected BMH kernel and is therefore partial/related to the launcher entry. The full source attribution is bundled in [`LICENSE.txt`](LICENSE.txt).

## Pinned source

Pinned to [`lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/commit/5d7b75df749241efa7a6e6f5be613d3fcc5cce38):

- [`MiBench/office-stringsearch/bmhsrch.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/office-stringsearch/bmhsrch.c) contains `bmh_init` and `bmh_search` and declares the implementation public domain by Raymond Gardner.
- [`MiBench/office-stringsearch/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/office-stringsearch/info.sh) selects `bmhasrch.c`, `bmhisrch.c`, `bmhsrch.c`, and `pbmsrch.c`.

## Contract

The exported symbol is `mibench_office_stringsearch_bmh` with the `i64_array_bytes_output` ABI. Input is `[text_length, pattern_length, text bytes..., pattern bytes...]`. Text length is 0–128, pattern length is 1–32, and each byte is printable ASCII 32–126. The lengths must exactly frame the input. Empty patterns and malformed frames return `-1`.

The kernel returns the first exact, case-sensitive occurrence of the pattern in the text. It uses a 256-entry bad-character shift table and compares each candidate from right to left, following the pinned Boyer-Moore-Horspool semantics. A valid search that finds no match produces offset `-1`. Success writes that offset as one little-endian signed 64-bit value and returns 8 bytes. Null output or capacity below 8 returns `-2`; errors leave output untouched.

The bounded printable-byte domain excludes NUL so the source's C-string `strlen` initialization and explicit text length remain consistent. All ports are modified derivatives of the pinned public-domain implementation; attribution and the bounded ABI adaptation are stated in source comments.

## Files

- [`workload.json`](workload.json) records pinned provenance, semantics, and fixtures.
- [`LICENSE.txt`](LICENSE.txt) preserves the pinned public-domain declaration and attribution.
- [`mibench_office_stringsearch_bmh_oracle.py`](../../mibench_office_stringsearch_bmh_oracle.py) provides an independent linear-search reference.

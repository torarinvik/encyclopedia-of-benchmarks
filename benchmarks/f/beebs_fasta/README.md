# `beebs_fasta`

This package represents the deterministic weighted nucleotide-generation core
of BEEBS FASTA. For input `[n, initial_lcg_state]`, it emits three FASTA
records: the source ALU sequence repeated to `2n` symbols, `3n` IUB symbols
selected from source-order cumulative weights, and `5n` human-frequency
symbols. Each record body wraps at 60 symbols and ends with a newline. The
default source state is 42; this bounded ABI makes the state an explicit input
and resets it at the start of every call so calls are independently
reproducible.

The pinned BEEBS benchmark sets `n` to 1000, uses a persistent static LCG state,
and comments out its header and sequence writes. This package projects the
generator's intended FASTA stream into observable output bytes; it does not
claim that BEEBS itself emitted those bytes or verified them. Probabilities
and the random ratio follow the source's binary32 accumulation and selection
order. The maximum count is 1000, and the maximum result/workspace is 10,245
bytes.

The ABI symbol is `beebs_fasta` in the `i64_array_bytes_output` family. Input
must contain exactly two signed 64-bit values: `n` in `[1, 1000]` and initial
LCG state in `[0, 139967]`. Length mismatch, null input, or out-of-range values
return `-1`. A null output pointer or output capacity below the exact result
length returns `-2`. Errors write no output. Valid calls return the number of
ASCII bytes written.

## Source and rights

The source is pinned to [`mageec/beebs` `src/fasta/libfasta.c`](https://github.com/mageec/beebs/blob/049ded9f3aeb5591f553879d3a0376b8614e9422/src/fasta/libfasta.c)
at commit `049ded9f3aeb5591f553879d3a0376b8614e9422`. Its header declares
GPL-3.0-or-later and includes the Benchmark Game Revised BSD notice, copyright
2004–2009 Brent Fulgham. See [LICENSE.txt](LICENSE.txt) and [NOTICE.txt](NOTICE.txt)
for the retained license texts. The nine ports are independently written
implementations of the described bounded profile; no upstream implementation
code was copied or translated.

## Files

- `workload.json` records the pinned source, input/output bounds, and fixtures.
- `../../beebs_fasta_oracle.py` is the independent reference implementation.
- Ports are in `c/f`, `c3/f`, `cpp/f`, `elisa/f`, `nim/f`, `odin/f`, `rust/f`,
  `v/f`, and `zig/f`.

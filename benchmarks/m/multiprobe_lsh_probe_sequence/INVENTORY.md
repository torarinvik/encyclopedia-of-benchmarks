# Static package inventory

- Algorithm: `multiprobe_lsh_probe_sequence`
- ABI: `i64_array_bytes_output`
- Input: `[m,width,count,lower_distance[m]]`; `1<=m<=4`, `1<=width<=1000`, each distance is in `0..width`, and `0<=count<=3^m-1`.
- Input length: at most 7 i64 words; output: at most 80 mask bytes; declared workspace cap: 4096 bytes.
- Invalid input returns `-1`; a null or insufficient output buffer returns `-2`; errors do not write output.
- The primary heap oracle generates signed-choice subsets in score, population-count, and mask order. The independent oracle enumerates ternary coordinate vectors and sorts them by the same contract key.
- The bounded maximum has eight signed choices, 255 possible nonempty masks, and 80 valid nonempty coordinate perturbations.
- The workload has eight fixed cases for regular output, ties, invalid generated ancestors, zero output, capacity/null handling, malformed distances/counts, and null input.

## Native paths

| Language | Path |
|---|---|
| C | `c/m/multiprobe_lsh_probe_sequence.c` |
| C3 | `c3/m/multiprobe_lsh_probe_sequence.c3` |
| C++ | `cpp/m/multiprobe_lsh_probe_sequence.cpp` |
| Elisa | `elisa/m/multiprobe_lsh_probe_sequence.elisa` |
| Mojo | `mojo/m/multiprobe_lsh_probe_sequence.mojo` |
| Nim | `nim/m/multiprobe_lsh_probe_sequence.nim` |
| Odin | `odin/m/multiprobe_lsh_probe_sequence.odin` |
| Rust | `rust/m/multiprobe_lsh_probe_sequence.rs` |
| V | `v/m/multiprobe_lsh_probe_sequence.v` |
| Zig | `zig/m/multiprobe_lsh_probe_sequence.zig` |

## Package and suite files

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`, `workload.json`, and `check_inventory.py`
- Primary oracle: `benchmarks/multiprobe_lsh_probe_sequence_oracle.py`
- Independent oracle: `benchmarks/multiprobe_lsh_probe_sequence_verifier_oracle.py`
- The byte-output runner registers the primary oracle and source/bound checks. The verifier registers the independent oracle, fixed workload fixtures, exhaustive small-distance cases, output-prefix/capacity cases, and null framing.
- Source references: Lv et al., [Multi-Probe LSH](https://www.cs.princeton.edu/cass/papers/mplsh_vldb07.pdf); PARSEC technical report, [Princeton TR-890](https://www.cs.princeton.edu/techreports/2010/890.pdf).

The publications identify and describe the method; no source code, problem text, prose, figures, or fixtures were copied. The inventory and checker are static source artifacts. No programs, scripts, tests, checkers, builds, compilers, profilers, or benchmarks have been run for this review.

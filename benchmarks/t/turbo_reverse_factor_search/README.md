# Turbo Reverse Factor string search

Turbo Reverse Factor (TRF) refines Reverse Factor with a remembered-prefix
rule. Preprocessing builds a suffix automaton for the reversed pattern,
stores displacement weights on its transitions, and computes Morris–Pratt
border lengths for the original pattern. Each candidate window is scanned
from right to left through the automaton. The preceding shift identifies a
prefix already matched in the prior attempt. Once the new right-hand factor
reaches that boundary, TRF either reports a match or re-inspects only the
period-bounded suffix of the remembered prefix. For a periodic prefix it
rechecks at most the smaller of its period and half its length; for a
nonperiodic prefix it scans the remaining right half. All overlapping
occurrences are reported.

## Bounded profile

The exported `turbo_reverse_factor_search` function uses the
`i64_array_scalar` ABI. Its input is `[n,m,text[0..n),pattern[0..m)]`, with
`0 <= n <= 4096`, `1 <= m <= 128`, symbols in `0..3`, and exact length
`2+n+m`. One trailing word is parseable but invalid. Invalid input returns
`-1`. The scalar result packs `(match_count << 36) | (sum_of_offsets << 12) |
xor_of_offsets`; overlapping occurrences are included. The fixed workspace
ceiling is 28,672 bytes.

The algorithm uses the suffix automaton’s terminal states and transition
displacements to compute Reverse Factor shifts, then applies the Turbo
reinspection rule to limit rescans. This differs from base Reverse Factor,
which can take quadratic worst-case search time, and from Turbo Boyer–Moore,
which uses a different skip and remembers a matched pattern suffix. The cited
TRF bound is O(m) preprocessing, O(n) search, and at most 2n text inspections.

The algorithm is described in Chapter 26 of the ESMAJ [Turbo Reverse Factor
page](https://www-igm.univ-mlv.fr/~lecroq/string/node24.html) and the
[reference PDF](https://ligm.univ-eiffel.fr/~lecroq/string/string.pdf). The
chapter cites Crochemore et al., “Speeding up two string-matching
algorithms,” *Algorithmica* 12(4/5), 247–267 (1994),
[doi:10.1007/BF01185427](https://doi.org/10.1007/BF01185427). Only mathematical
algorithm descriptions were consulted; the ports, bounded profile, and
workload are independently written. See [RIGHTS.md](RIGHTS.md).

[`primary_oracle.py`](primary_oracle.py) uses a sparse weighted suffix
automaton and the Turbo Reverse Factor scan. [`independent_oracle.py`](independent_oracle.py)
checks every alignment directly. [`verify_workload.py`](verify_workload.py)
contains static package checks and is not part of benchmark execution.
[`workload.json`](workload.json) covers periodic overlaps, remembered-prefix
fallback, and invalid frames. The ten source paths are listed in
[`INVENTORY.md`](INVENTORY.md).

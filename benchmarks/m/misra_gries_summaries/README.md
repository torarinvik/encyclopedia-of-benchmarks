# Misra–Gries frequent-item summaries

This package implements the bounded Misra–Gries cancellation summary for an
integer stream. The summary retains at most `k` item counters: a matching item
increments its counter, an unseen item occupies a free counter, and an unseen
item arriving to a full summary decrements every counter and removes counters
that reach zero.

## Contract

The `i64_array_bytes_output` input is `[k, item_count, items...]`, with
`1 <= k <= 8`, at most 64 items, and each item in `0..=15`. The array length
must equal `item_count + 2`. The output is a little-endian i64 array containing
`[candidate_count, item, residual_count, ...]`; candidate pairs are sorted by
item ID for a canonical representation. Empty streams return the single value
`[0]`. Invalid input returns `-1`; a null output or insufficient capacity
returns `-2` without writing.

The retained counters are Misra–Gries residual counts, not exact frequencies.
Every item occurring more than `item_count/(k+1)` times is guaranteed to
appear among the candidates. The bound and finite integer alphabet make the
profile deterministic across ports.

## Source and clean-room status

The algorithm family is attributed to Misra and Gries (1982), as summarized in
the supplied *Encyclopedia of Algorithms*, entry “Misra-Gries Summaries,” DOI
[`10.1007/978-1-4939-2864-4_572`](https://doi.org/10.1007/978-1-4939-2864-4_572).
The implementations and oracle here are clean-room implementations of the
algorithm; no book prose or upstream source code is copied.

## Language ports

| Language | Source |
|---|---|
| C | `c/m/misra_gries_summaries.c` |
| C3 | `c3/m/misra_gries_summaries.c3` |
| C++ | `cpp/m/misra_gries_summaries.cpp` |
| Elisa | `elisa/m/misra_gries_summaries.elisa` |
| Nim | `nim/m/misra_gries_summaries.nim` |
| Odin | `odin/m/misra_gries_summaries.odin` |
| Rust | `rust/m/misra_gries_summaries.rs` |
| V | `v/m/misra_gries_summaries.v` |
| Zig | `zig/m/misra_gries_summaries.zig` |

Primary oracle: `benchmarks/misra_gries_summaries_oracle.py`.
Independent verifier oracle: `benchmarks/misra_gries_summaries_verifier_oracle.py`.

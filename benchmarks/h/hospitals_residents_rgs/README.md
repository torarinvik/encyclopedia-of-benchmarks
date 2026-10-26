# Hospitals/Residents resident-oriented Gale–Shapley

This bounded profile implements the chapter's resident-oriented Gale–Shapley
(RGS) algorithm for the many-to-one Hospitals/Residents problem. Residents
propose in preference order. Each hospital retains up to its capacity among
its current assignees and new proposers, according to its strict preference
list; a rejected or displaced resident continues with the next acceptable
hospital. The output is the resident-optimal stable assignment.

Input uses fixed-width padded preference rows:

`[resident_count, hospital_count, capacities[H], resident_lengths[R], resident_preferences[R][H], hospital_lengths[H], hospital_preferences[H][R]]`.

Counts are in `1..8`; hospital capacities are in `1..R`. Preference lengths
may be zero. Each prefix is a strict list of distinct IDs, remaining row cells
must be `-1`, and resident and hospital lists must describe exactly the same
mutually acceptable pairs. Output is one little-endian signed-i64 hospital ID
per resident, or `-1` for an unassigned resident. Invalid input returns `-1`;
null output or capacity below `8*R` returns `-2` without writing.

The exported symbol is `hospitals_residents_rgs`; the ABI is
`i64_array_bytes_output`. The [workload](workload.json) includes displacement,
capacities above one, incomplete lists, an empty acceptable-pair set, the
maximum profile, and malformed-input/output-capacity probes.

Source: “Hospitals/Residents Problem,” David F. Manlove, *Encyclopedia of
Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_180`](https://doi.org/10.1007/978-1-4939-2864-4_180).
The profile preserves capacities, incomplete acceptable lists, strict
preferences, and resident-proposing deferred acceptance. The chapter's
hospital-oriented variant, ties, couples, and many-to-many extensions are
outside this profile. Ports are clean-room implementations.

The [primary oracle](../../hospitals_residents_rgs_oracle.py) follows a
resident-oriented free-proposer loop. The [independent verifier](../../hospitals_residents_rgs_verifier_oracle.py)
resolves each round's proposals by hospital ranking.

| Language | Port |
|---|---|
| C | [`hospitals_residents_rgs.c`](../../../c/h/hospitals_residents_rgs.c) |
| C3 | [`hospitals_residents_rgs.c3`](../../../c3/h/hospitals_residents_rgs.c3) |
| C++ | [`hospitals_residents_rgs.cpp`](../../../cpp/h/hospitals_residents_rgs.cpp) |
| Elisa | [`hospitals_residents_rgs.elisa`](../../../elisa/h/hospitals_residents_rgs.elisa) |
| Nim | [`hospitals_residents_rgs.nim`](../../../nim/h/hospitals_residents_rgs.nim) |
| Odin | [`hospitals_residents_rgs.odin`](../../../odin/h/hospitals_residents_rgs.odin) |
| Rust | [`hospitals_residents_rgs.rs`](../../../rust/h/hospitals_residents_rgs.rs) |
| V | [`hospitals_residents_rgs.v`](../../../v/hospitals_residents_rgs.v) |
| Zig | [`hospitals_residents_rgs.zig`](../../../zig/h/hospitals_residents_rgs.zig) |

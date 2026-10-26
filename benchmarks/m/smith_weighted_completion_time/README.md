# Smith-rule weighted completion time

This profile covers the one-machine, no-release-date case `1 || Σ w_j C_j`.
Jobs are ordered by decreasing `weight / processing_time`, compared with exact
integer cross-products; equal ratios are ordered by job ID. The result is the
optimal weighted completion-time sum and the job order.

Input is `[n, (processing_time, weight)...]`, with `1 <= n <= 12` and positive
processing times and weights at most 10,000. Output is a little-endian signed
i64 vector `[weighted_sum, job_ids...]`. Invalid input returns `-1`; null
output or insufficient capacity returns `-2` without writing.

Source: “Minimum Weighted Completion Time,” DOI
[`10.1007/978-1-4939-2864-4_240`](https://doi.org/10.1007/978-1-4939-2864-4_240).
The bounded profile implements the chapter's Smith-rule special case and is
clean-room.

| Language | Port |
|---|---|
| C | `c/m/smith_weighted_completion_time.c` |
| C3 | `c3/m/smith_weighted_completion_time.c3` |
| C++ | `cpp/m/smith_weighted_completion_time.cpp` |
| Elisa | `elisa/m/smith_weighted_completion_time.elisa` |
| Nim | `nim/m/smith_weighted_completion_time.nim` |
| Odin | `odin/m/smith_weighted_completion_time.odin` |
| Rust | `rust/m/smith_weighted_completion_time.rs` |
| V | `v/m/smith_weighted_completion_time.v` |
| Zig | `zig/m/smith_weighted_completion_time.zig` |

# Two-phase commit coordinator

This benchmark models the coordinator state machine from the pinned Zig source. It runs one prepare phase, records the supplied participant votes, observes the timeout flag while still preparing, and decides only when every participant has voted.

## Contract

- Input is `[participant_count, timeout_ms, start_time_ms, current_time_ms, vote_0, ..., vote_(n-1)]`. Participant count is 1..64, timeout is a positive signed 64-bit value, timestamps are nonnegative signed 64-bit values, and current time must be at least start time. The transaction ID is fixed to 1. These bounds keep elapsed-time subtraction nonnegative and within signed 64-bit range while preserving every representable ABI timeout.
- Vote 0 records `vote_commit`, vote 1 records `vote_abort`, and vote 2 means that the participant has not responded. Vote 2 does not call `recordVote`: in the source `no_response` is also the initial unvoted sentinel, so recording it would not increment `votes_received`.
- The coordinator is initialized and prepared at `start_time_ms`. It records each 0/1 vote once, then queries `isTimedOut(current_time_ms)` while still preparing. The source uses strict `elapsed > timeout_ms`; timeout observation does not change state or force abort.
- `decide` runs only when all participants supplied vote 0 or 1. Any abort vote yields `aborted`; otherwise the state becomes `committed`. If any vote is 2, the state remains `preparing` and `votes_received` counts only the 0/1 votes.
- The result uniquely encodes `(state, votes_received, commit_votes, timed_out)` as `(((state * 65 + votes_received) * 65 + commit_votes) * 2 + timed_out)`. State codes are 0 init, 1 preparing, 2 committed, 3 aborted. The maximum encoding is 33,799; invalid inputs return -1.
- Assertion-triggering transitions and the separate `Participant` helper are outside this coordinator benchmark. The bounded input exercises normal valid state transitions and the source's incomplete-vote behavior.

The independent oracle is [`benchmarks/two_phase_commit_oracle.py`](../../two_phase_commit_oracle.py). The workload covers commit, abort, no response, strict timeout boundary, timeout without automatic abort, maximum participant count, and malformed inputs.

Pinned source: [TheAlgorithms/Zig `two_phase_commit.zig`](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/tiger_style/two_phase_commit.zig), commit `86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3`.

Build and record with the `i64_array_scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm two_phase_commit --language c
python3 benchmarks/run_i64_array_scalar.py --algorithm two_phase_commit
```

| Language | Port |
| --- | --- |
| C | [`c/t/two_phase_commit.c`](../../../c/t/two_phase_commit.c) |
| C3 | [`c3/t/two_phase_commit.c3`](../../../c3/t/two_phase_commit.c3) |
| C++ | [`cpp/t/two_phase_commit.cpp`](../../../cpp/t/two_phase_commit.cpp) |
| Elisa | [`elisa/t/two_phase_commit.elisa`](../../../elisa/t/two_phase_commit.elisa) |
| Nim | [`nim/t/two_phase_commit.nim`](../../../nim/t/two_phase_commit.nim) |
| Odin | [`odin/t/two_phase_commit.odin`](../../../odin/t/two_phase_commit.odin) |
| Rust | [`rust/t/two_phase_commit.rs`](../../../rust/t/two_phase_commit.rs) |
| V | [`v/t/two_phase_commit.v`](../../../v/t/two_phase_commit.v) |
| Zig | [`zig/t/two_phase_commit.zig`](../../../zig/t/two_phase_commit.zig) |

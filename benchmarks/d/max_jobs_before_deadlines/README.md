# Maximum number of jobs before deadlines

Given jobs with processing durations and deadlines on one machine, return the
largest number that can finish by their deadlines. A feasible selected set is
scheduled in earliest-deadline order; all jobs are nonpreemptive in the final
schedule.

## Contract

The scalar ABI symbol is `max_jobs_before_deadlines`. Input is a signed 64-bit
array `[N,(deadline_i,duration_i)*N]`, with `0<=N<=12`, deadlines in `0..1000`,
and positive durations in `1..1000`. The exact length is `1+2N`; the maximum
input length is 25 words. Invalid or out-of-profile input returns `-1`. A valid
call returns the maximum feasible job count, from zero through N.

The primary ports sort jobs by deadline and sweep deadline intervals in reverse.
A min-heap holds remaining durations. Each interval completes the shortest
available jobs first, returning one partly processed duration to the heap when
the interval ends mid-job. The independent oracle enumerates subsets and checks
each subset in earliest-deadline order. Bounded insertion sort takes `O(N^2)`;
heap operations take `O(N log N)`, with `O(N)` storage. The independent oracle
takes `O(2^N N log N)` time and `O(N)` space.

## Distinctness and provenance

[`minimizing_lateness`](../../m/minimizing_lateness/README.md) schedules every
job and minimizes lateness; [`job_scheduling_with_deadline`](../../j/job_scheduling_with_deadline/README.md)
uses unit durations and profits; [`weighted_interval_scheduling`](../../w/weighted_interval_scheduling/README.md)
selects among fixed intervals. This benchmark instead selects as many arbitrary-
duration jobs as possible under completion deadlines.

The algorithm description comes from [CP-Algorithms, “Optimal schedule of jobs given their deadlines and durations”](https://cp-algorithms.com/schedules/schedule-with-completion-duration.html),
licensed under CC BY-SA 4.0. Only the high-level algorithm description is used;
the bounded contract, fixtures, oracles, and ports are clean-room work. See
[`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the [primary oracle](../../max_jobs_before_deadlines_oracle.py),
the [independent verifier](../../max_jobs_before_deadlines_verifier_oracle.py),
and the package-local [static inventory checker](../../check_max_jobs_before_deadlines_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/d/max_jobs_before_deadlines.c`](../../../c/d/max_jobs_before_deadlines.c) |
| C3 | [`c3/d/max_jobs_before_deadlines.c3`](../../../c3/d/max_jobs_before_deadlines.c3) |
| C++ | [`cpp/d/max_jobs_before_deadlines.cpp`](../../../cpp/d/max_jobs_before_deadlines.cpp) |
| Elisa | [`elisa/d/max_jobs_before_deadlines.elisa`](../../../elisa/d/max_jobs_before_deadlines.elisa) |
| Mojo | [`mojo/d/max_jobs_before_deadlines.mojo`](../../../mojo/d/max_jobs_before_deadlines.mojo) |
| Nim | [`nim/d/max_jobs_before_deadlines.nim`](../../../nim/d/max_jobs_before_deadlines.nim) |
| Odin | [`odin/d/max_jobs_before_deadlines.odin`](../../../odin/d/max_jobs_before_deadlines.odin) |
| Rust | [`rust/d/max_jobs_before_deadlines.rs`](../../../rust/d/max_jobs_before_deadlines.rs) |
| V | [`v/d/max_jobs_before_deadlines.v`](../../../v/d/max_jobs_before_deadlines.v) |
| Zig | [`zig/d/max_jobs_before_deadlines.zig`](../../../zig/d/max_jobs_before_deadlines.zig) |

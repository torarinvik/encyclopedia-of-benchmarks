# Time-batched secret sharing

Process meetings in chronological order. Every connected group of meetings at
one timestamp shares the secret transitively before the next timestamp. A
person who is not connected to someone already informed during a time batch
does not retain those temporary meeting links into later batches.

## Contract

The exported `secret_sharing_time_batched_dsu` function uses
`i64_array_scalar`. Input is `[n,first_person,m,(u,v,time)*m]`, with
`2<=n<=16`, `1<=first_person<n`, `0<=m<=20`, distinct meeting endpoints in
`[0,n)`, timestamps in `[1,20]`, and exact length `3+3*m`. Duplicate meetings
are allowed. The output is an integer bitmask whose bit `i` is set exactly
when person `i` knows the secret after all meetings. Null, malformed,
out-of-range, or trailing input returns `-1`. The maximum valid frame is 63
words and the maximum parseable frame is 64 words.

For each timestamp from 1 through 20, union all meeting endpoints in that
batch. Keep the components connected to person 0; reset every other person
involved in the batch to a singleton before moving to the next time. The
bounded scan takes `O(T(m+n) + m alpha(n))` time for `T<=20`, and `O(n+m)`
space.

The independent reference creates the graph of one timestamp at a time and
propagates the current informed set through it with BFS. It does not use
disjoint sets or rollback state.

## Sources and rights

The [official LeetCode 2092 title and method hints](https://leetcode.com/problems/find-all-people-with-secret/)
were consulted for discovery and the same-time graph/DSU framing. The DSU
operations follow [CP-Algorithms' disjoint-set description](https://cp-algorithms.com/data_structures/disjoint_set_union.html).
No problem wording, examples, tests, editorial, submission, or code is reused.
See [`RIGHTS.md`](RIGHTS.md).

## Artifacts

- [`workload.json`](workload.json): bounded scalar fixtures.
- [`primary_oracle.py`](primary_oracle.py): timestamp-batched DSU reference.
- [`independent_oracle.py`](independent_oracle.py): per-time graph BFS reference.
- [`verify_workload.py`](verify_workload.py): static metadata, fixture, oracle, and port review.
- [`INVENTORY.md`](INVENTORY.md): source inventory.

Shared runner and catalog integration is maintained separately.

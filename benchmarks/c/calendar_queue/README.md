# Brown's Calendar Queue

This package implements Brown's adaptive calendar queue for a bounded discrete
event stream. The queue is a circular array of time buckets, with each bucket
kept in ascending `(priority, insertion_id)` order. Its periodic resizing and
full-calendar fallback distinguish it from the heap and comparison-list
priority queues already in the repository.

## Contract

The `i64_array_bytes_output` ABI accepts:

```text
[operation_count, (opcode, priority_or_zero)*operation_count]
```

Opcode `1` enqueues an event at the specified nonnegative integer tick.
Opcode `2` dequeues the earliest event and requires its second word to be zero.
An event ID is its zero-based enqueue ordinal. Equal priorities are removed in
insertion order. Priorities may not precede the last dequeued priority. A
dequeue from an empty queue, more than 64 live events, an unknown opcode, or a
priority outside `0..=1_000_000` makes the call invalid.

The call is capped at 128 operations. The maximum valid and parseable frames are
257 and 258 signed 64-bit words. Successful output is
`[dequeue_count, (event_id, priority)*dequeue_count]`; the maximum is 1,032
bytes. Invalid input returns `-1`. A null output pointer or insufficient
capacity returns `-2` without writes. Validation order is pinned in
`workload.json`. The conservative workspace cap is 8,192 bytes, excluding
caller-owned input and output buffers; the accounting includes event storage,
bucket heads, resize sorting scratch, trace storage, and alignment.

## Pinned calendar behavior

Brown's 1988 paper uses `floor(priority / width) mod bucket_count` for the
bucket index. Each bucket is sorted by priority. Dequeue scans circularly from
the last bucket, advancing a bucket-top boundary by one width; an event is due
when its priority is below that boundary. The boundary starts one and a half
bucket widths above the current virtual bucket. If a full calendar has no due
event, the algorithm scans bucket heads for the global minimum, resets its
cursor, and resumes.

The initial calendar has two buckets and width 1.0. It doubles when the queue
size exceeds twice the bucket count and halves when the queue size drops below
`bucket_count / 2 - 2`. Width is recalculated during resize: use 1.0 when fewer
than two events remain; otherwise sample all events when there are at most
five, or `min(25, 5 + floor(queue_size / 10))` earliest events. Compute the
mean adjacent gap, discard gaps greater than twice that mean, recompute the
mean from the retained gaps, and multiply it by three.

This profile uses exact rational widths over integer ticks. That preserves the
paper's bucket and boundary comparisons without cross-language floating point
rounding. If the retained sampled gaps are all zero, the profile uses width
one tick. The paper leaves equal-priority ordering unspecified; this contract
pins insertion order. When calculating a resize width, the earliest events are
selected by priority and insertion ID, matching the order the queue would
dequeue.

The “Calendar Queue” entry in the [NIST Dictionary of Algorithms and Data
Structures](https://xlinux.nist.gov/dads/HTML/calendarQueue.html) identifies
the bucketed priority queue and Brown's article. The pinned primary source is
Randy Brown, “Calendar Queues: A Fast O(1) Priority Queue Implementation for
the Simulation Event Set Problem,” *Communications of the ACM* 31(10),
1220–1227 (1988), [DOI 10.1145/63039.63045](https://doi.org/10.1145/63039.63045),
Sections 2–4. No O(1) worst-case claim is made: Brown describes and measures
average behavior for the priority distributions considered in the paper.

## References and inventory

[`primary_oracle.py`](primary_oracle.py) uses the bounded calendar operations.
[`independent_oracle.py`](independent_oracle.py) uses a binary min-heap to
check the abstract priority-queue trace independently. The workload includes
a 65-operation trace that enqueues 64 events before its first dequeue,
reaching the live-event cap and the largest growth permitted by this profile. See [`RIGHTS.md`](RIGHTS.md),
[`INVENTORY.md`](INVENTORY.md), [`INVENTORY.json`](INVENTORY.json),
[`workload.json`](workload.json), and [`check_inventory.py`](check_inventory.py).

Ten language ports, the bounded workload, independent references, and the
`i64_array_bytes_output` runner and verifier registrations are included. No
port or suite has been executed.

# Activity Selection

This benchmark returns the maximum number of mutually compatible activities. Each activity occupies the half-open interval from its start time through its finish time; activities may touch at an endpoint.

## Contract

- The input is a signed 64-bit array encoded as `[activity_count, start_0, finish_0, ...]`.
- There are at most 64 activities. A valid activity has `start <= finish`; zero-duration activities are allowed.
- An empty activity list returns 0. A malformed layout, too many activities, or any reversed interval returns `-1`.
- The result is the maximum number of activities that can be selected without overlap. Each port sorts a bounded local copy by finish time and greedily selects the next compatible interval.

The source methods return selected activities or print their indices. This contract records the size of a maximum selection, so equivalent selections with different tie ordering have the same result.

## Inspected upstream sources

- [TheAlgorithms/Java `ActivitySelection.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/greedyalgorithms/ActivitySelection.java)
- [TheAlgorithms/Python `greedy_methods/activity_selection.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/greedy_methods/activity_selection.py)
- [TheAlgorithms/Python `other/activity_selection.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/activity_selection.py)

Java and the `greedy_methods` Python source sort by finish time and accept a next activity when its start is at least the previous finish. The Python `other` source assumes finish-time ordering is already supplied and prints selected indices. The shared contract handles an empty input consistently and validates interval pairs.

## Workload and verification

[`workload.json`](workload.json) covers empty and maximum-length schedules, touching and duplicate intervals, negative and extreme signed times, malformed layouts, and reversed intervals. [`benchmarks/verify_activity_selection.py`](../../verify_activity_selection.py) compares all ports against an independent weighted-interval dynamic-programming oracle on exhaustive small schedules, deterministic random schedules, and the published workload.

```sh
python3 benchmarks/verify_activity_selection.py --elisa-compiler /absolute/path/to/elisac
```

Build and record with the `i64_array_scalar` ABI family. Source ports are in `a/` in all nine language directories.

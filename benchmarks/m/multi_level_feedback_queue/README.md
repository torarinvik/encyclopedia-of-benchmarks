# Multilevel feedback queue

This benchmark follows the pinned Python MLFQ implementation with all process arrivals fixed at time zero. It records each process's timing metrics in the source's finish-queue order.

## Contract

- The ABI is `i32_array_bytes_output`. Input is `[queue_count, process_count, time_slices..., burst_times...]` as signed-i32 values. `queue_count` is 1–4, `process_count` is 0–8, there are exactly `queue_count - 1` time slices followed by exactly `process_count` burst times, and every slice and burst is in 1–16. The packed input has exactly `2 + (queue_count - 1) + process_count` words.
- Processes arrive at time zero and receive implicit names `P0`, `P1`, and so on in burst-input order. For each of the first `queue_count - 1` queues, the source makes one round-robin pass over the ready deque: each process runs for the smaller of its remaining burst and that queue's time slice; unfinished processes return to the deque, while finished processes join the finish queue in visit order. The last queue runs the remaining deque in FIFO order until all processes finish.
- Output is `[finished_count, (process_id, waiting_time, turnaround_time, stop_time)...]` in finish-queue order, serialized as little-endian signed-i32 values. The implicit name `P0` maps to ID `0`, `P1` to `1`, and so on. An empty process list returns `[0]` in 4 bytes. At most 8 records are emitted, so output is bounded at 132 bytes.
- Invalid or null input returns `-1` before output-buffer checks. A null output pointer or insufficient capacity returns `-2` without writes. The bounded contract fixes arrivals at zero, so the source's unusual nonzero-arrival current-time update is not observable.

The fixtures in [workload.json](workload.json) cover empty schedules, all round-robin levels, FIFO completion, per-process timing metrics, malformed input, and output capacity boundaries. The independent oracle is [multi_level_feedback_queue_oracle.py](../../multi_level_feedback_queue_oracle.py).

Pinned source: [TheAlgorithms/Python `multi_level_feedback_queue.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/scheduling/multi_level_feedback_queue.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i32_array_bytes_output --algorithm multi_level_feedback_queue --language rust
python3 benchmarks/run_i32_array_bytes_output.py --build-manifest build/i32_array_bytes_output/m/multi_level_feedback_queue/rust/build.json
python3 benchmarks/verify_i32_array_bytes_output.py --algorithm multi_level_feedback_queue --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/m/multi_level_feedback_queue.c](../../../c/m/multi_level_feedback_queue.c) |
| C3 | [c3/m/multi_level_feedback_queue.c3](../../../c3/m/multi_level_feedback_queue.c3) |
| C++ | [cpp/m/multi_level_feedback_queue.cpp](../../../cpp/m/multi_level_feedback_queue.cpp) |
| Elisa | [elisa/m/multi_level_feedback_queue.elisa](../../../elisa/m/multi_level_feedback_queue.elisa) |
| Nim | [nim/m/multi_level_feedback_queue.nim](../../../nim/m/multi_level_feedback_queue.nim) |
| Odin | [odin/m/multi_level_feedback_queue.odin](../../../odin/m/multi_level_feedback_queue.odin) |
| Rust | [rust/m/multi_level_feedback_queue.rs](../../../rust/m/multi_level_feedback_queue.rs) |
| V | [v/m/multi_level_feedback_queue.v](../../../v/m/multi_level_feedback_queue.v) |
| Zig | [zig/m/multi_level_feedback_queue.zig](../../../zig/m/multi_level_feedback_queue.zig) |

# Non-preemptive priority scheduling

The benchmark follows the pinned Java implementation: lower numeric priority values run first; only processes that have arrived are eligible, and a running process completes before the next selection. If no process is ready, the clock advances to the next arrival. Input bounds priorities to unique values so Java's priority-queue tie behavior is outside the contract. Process IDs are their zero-based input positions.

Input is `[count, (arrival_time, burst_time, priority)*]`, with 1–10 processes, arrival times 0–20, positive burst times 1–10, and unique priorities 0–10. Output is the execution order as little-endian signed i32 IDs. The pinned C filename match is a FIFO completion-time calculator and does not implement priority scheduling; this benchmark follows Java semantics and records that source divergence.

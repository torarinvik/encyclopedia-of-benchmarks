# Package inventory

[`inventory.json`](inventory.json) lists the ten native language ports and package files. `check_inventory.py` is a static inventory checker; `verify_workload.py` compares the two Python references with the pinned workload. Both are included as source only and have not been run.

The primary implementation uses a fixed FIFO queue and recolors on enqueue. Its maximum image is 1024 signed 64-bit words and its maximum queue is 1024 indices; the declared 16,384-byte workspace covers both 64-bit arrays. The output bound is 1024 little-endian i64 words (8192 bytes). Caller-owned input and output are excluded.

No programs, tests, scripts, helpers, checkers, builds, compilers, profilers, or benchmarks were run.

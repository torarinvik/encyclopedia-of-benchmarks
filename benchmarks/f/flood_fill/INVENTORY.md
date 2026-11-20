# Package inventory

[`inventory.json`](inventory.json) lists all ten language ports and package artifacts. `check_inventory.py` checks paths, package metadata, exported symbols, and README links statically. `verify_workload.py` compares the LIFO primary oracle and independent grid-wide fixed-point reference against the fixture data.

The stack uses at most 1024 indices; the local image and index stack together require at most 16,384 bytes. The caller-owned input and output buffers are excluded. The output bound is 8192 bytes.

No project programs, tests, scripts, checkers, builds, compilers, profilers, or benchmarks have been run.

# Static inventory

- Algorithm: fixed-table hopscotch hashing with H=4 neighborhood bitmaps.
- ABI: i64_array_bytes_output; input is an exact signed-i64 operation trace, output is a bounded byte record.
- Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig.
- References: bitmap-based insertion/lookup model and a direct-resident-scan model with independently reconstructed hop information.
- Workload: direct lookup, duplicate key, backward displacement, circular wraparound, unmovable neighborhood, full-table failure, malformed frames, null pointers, and capacity boundaries.
- Limits: 16 slots, 4 bitmap bits per home, 32 operations, 97 input words, 64 output bytes, 1,024 workspace bytes.
- Provenance: Herlihy, Shavit, and Tzafrir, DISC 2008, §2/Figure 1; NIST DADS hashing pages are discovery-only.
- Rights: clean-room implementation; see [RIGHTS.md](RIGHTS.md).
- Validation: static files are inventoried by [check_inventory.py](check_inventory.py). No programs, tests, checkers, scripts, compilers, or benchmarks have been run.

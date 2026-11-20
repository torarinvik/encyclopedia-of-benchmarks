# Static package inventory

The exported ABI is `packet_switching_random_schedule(input, length, output,
capacity)`. Its bounded frame and output contract are documented in
[`README.md`](README.md) and [`workload.json`](workload.json). The package-local
references are [`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py). The static inventory checker
is [`check_inventory.py`](check_inventory.py); it has not been run.

| Language | Source |
| --- | --- |
| C | [`c/p/packet_switching_random_schedule.c`](../../../c/p/packet_switching_random_schedule.c) |
| C3 | [`c3/p/packet_switching_random_schedule.c3`](../../../c3/p/packet_switching_random_schedule.c3) |
| C++ | [`cpp/p/packet_switching_random_schedule.cpp`](../../../cpp/p/packet_switching_random_schedule.cpp) |
| Elisa | [`elisa/p/packet_switching_random_schedule.elisa`](../../../elisa/p/packet_switching_random_schedule.elisa) |
| Mojo | [`mojo/p/packet_switching_random_schedule.mojo`](../../../mojo/p/packet_switching_random_schedule.mojo) |
| Nim | [`nim/p/packet_switching_random_schedule.nim`](../../../nim/p/packet_switching_random_schedule.nim) |
| Odin | [`odin/p/packet_switching_random_schedule.odin`](../../../odin/p/packet_switching_random_schedule.odin) |
| Rust | [`rust/p/packet_switching_random_schedule.rs`](../../../rust/p/packet_switching_random_schedule.rs) |
| V | [`v/p/packet_switching_random_schedule.v`](../../../v/p/packet_switching_random_schedule.v) |
| Zig | [`zig/p/packet_switching_random_schedule.zig`](../../../zig/p/packet_switching_random_schedule.zig) |

The source inventory covers all ten current language directories. Central suite
registration is present in the shared `i64_array_bytes_output` runner and
verifier; the root CATALOG and Chapter 274 crosswalk include this profile. No
programs, tests, scripts, checkers, builds, compilers, profilers, or benchmarks
were run.

# Package inventory

| Artifact | Purpose |
|---|---|
| `README.md` | Bounded schedule contract, bounds, and duplicate rationale |
| `RIGHTS.md` | Source attribution, timing convention, and clean-room provenance |
| `workload.json` | Bounded inputs and expected byte outputs |
| `primary_oracle.py` | Direct active-sender phase simulation |
| `independent_oracle.py` | Sender/receiver bitmask simulation |
| `check_inventory.py` | Static metadata and ten-port inventory checker |
| `c/r/radio_network_bgi_broadcast.c` | C port |
| `c3/r/radio_network_bgi_broadcast.c3` | C3 port |
| `cpp/r/radio_network_bgi_broadcast.cpp` | Independent C++ port |
| `elisa/r/radio_network_bgi_broadcast.elisa` | Elisa port with fixed bounded arrays |
| `mojo/r/radio_network_bgi_broadcast.mojo` | Mojo port |
| `nim/r/radio_network_bgi_broadcast.nim` | Nim port |
| `odin/r/radio_network_bgi_broadcast.odin` | Odin port |
| `rust/r/radio_network_bgi_broadcast.rs` | Rust port |
| `v/r/radio_network_bgi_broadcast.v` | V port |
| `zig/r/radio_network_bgi_broadcast.zig` | Zig port |

The shared suite runner, verifier, and catalog registration are maintained
separately.

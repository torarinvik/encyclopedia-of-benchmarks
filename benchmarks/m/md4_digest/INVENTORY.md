# MD4 package inventory

| Artifact | Role |
|---|---|
| `primary_oracle.py` | Bounded streaming-word reference with on-demand padding. |
| `independent_oracle.py` | Independent whole-message padding and cyclic-register reference. |
| `verify_workload.py` | Static metadata checks and primary/independent fixture agreement. |
| `check_inventory.py` | Pins required language paths and provenance artifacts. |
| `workload.json` | Compact deterministic boundary, maximum-size, and ABI fixtures. |
| `README.md` / `RIGHTS.md` | Contract, source provenance, and rights notes. |
| `INVENTORY.json` | Machine-readable source and metadata inventory. |

The native input is `[n, bytes...]`. The maximum valid input length is 4,097
signed 64-bit words and maximum parseable length is 4,098 words. The digest is
16 raw bytes and native workspace is bounded at 512 bytes. The ten source
paths are C, C++, Rust, Elisa, C3, Nim, Odin, V, Zig, and Mojo under their
respective `m/` directories.

RosettaCodeData supplied only the MD4 title discovery. RFC 1320 supplies the
algorithm definition, and RFC 6150 documents its historic security status.

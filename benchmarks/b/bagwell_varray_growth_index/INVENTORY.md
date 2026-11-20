# Package inventory

This package contains a bounded implementation of Bagwell's append-only
VArray profile, a block-layout primary oracle, a flat-list independent oracle,
and a fixed workload. Source and provenance are documented in `README.md` and
`RIGHTS.md`.

Ten source paths are listed in `INVENTORY.json`. The primary/independent
reference pair and workload use the `i64_array_bytes_output` contract. The
package-local inventory and workload helpers are static metadata tools; they
are not part of the measured benchmark.

The native workspace reserves 352 signed 64-bit data entries (2,816 bytes),
56 signed 64-bit child-pointer/base entries (448 bytes), and three signed
64-bit header-prev slots (a root sentinel and two predecessor links; 24
bytes), for 3,288 bytes of fixed table storage. The 4,096-byte cap leaves 808
bytes for the current-header scalar and
bounded index/local values. The maximum input is 579 words (580 parseable),
and the maximum output is 2,056 bytes.

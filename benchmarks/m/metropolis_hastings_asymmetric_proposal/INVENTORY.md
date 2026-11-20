# Static language-port inventory

The package uses the `i64_array_bytes_output` ABI and exports
`metropolis_hastings_asymmetric_proposal` from each listed language path.
The inventory metadata pins the ten paths and the valid workload fixtures,
including input values, null flags, capacities, result lengths, and exact byte
traces. The maximum valid frame is 267 i64 values (`N=8`, `T=64`); one extra
word is within the parseable bound and is rejected as a trailing value. Each
port stages the trace in exactly 65 bytes before it writes caller output. The
static reviewer checks source presence/symbols, provenance, and workload
metadata; it does not run or compile the ports.

| Language | Source | Status |
| --- | --- | --- |
| C | `c/m/metropolis_hastings_asymmetric_proposal.c` | Draft present; static review only |
| C3 | `c3/m/metropolis_hastings_asymmetric_proposal.c3` | Draft present; static review only |
| C++ | `cpp/m/metropolis_hastings_asymmetric_proposal.cpp` | Draft present; static review only |
| Elisa | `elisa/m/metropolis_hastings_asymmetric_proposal.elisa` | Draft present; bounded input view behind FFI boundary |
| Mojo | `mojo/m/metropolis_hastings_asymmetric_proposal.mojo` | Draft present; static review only |
| Nim | `nim/m/metropolis_hastings_asymmetric_proposal.nim` | Draft present; static review only |
| Odin | `odin/m/metropolis_hastings_asymmetric_proposal.odin` | Draft present; static review only |
| Rust | `rust/m/metropolis_hastings_asymmetric_proposal.rs` | Draft present; static review only |
| V | `v/m/metropolis_hastings_asymmetric_proposal.v` | Draft present; static review only |
| Zig | `zig/m/metropolis_hastings_asymmetric_proposal.zig` | Draft present; static review only |
